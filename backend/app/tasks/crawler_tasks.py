"""
Crawler Background Tasks
Periodic price checking and history recording
"""
import asyncio
from datetime import datetime, timedelta
from decimal import Decimal
from uuid import UUID
from typing import Optional

from celery import shared_task
from sqlalchemy import select, and_
from sqlalchemy.ext.asyncio import AsyncSession
import structlog

from app.celery_app import celery_app
from app.database import async_session_maker
from app.models import Product, PriceHistory, Alert, AlertType, AlertStatus, CrawlStatus
from app.crawler import crawl_product

logger = structlog.get_logger()


def run_async(coro):
    """Run async function in sync context"""
    loop = asyncio.new_event_loop()
    asyncio.set_event_loop(loop)
    try:
        return loop.run_until_complete(coro)
    finally:
        loop.close()


@celery_app.task(bind=True, max_retries=3)
def crawl_single_product(self, product_id: str):
    """
    Crawl a single product and update its price
    """
    return run_async(_crawl_single_product(product_id))


async def _crawl_single_product(product_id: str):
    """Async implementation of single product crawl"""
    async with async_session_maker() as db:
        try:
            # Get product
            result = await db.execute(
                select(Product).where(
                    Product.id == UUID(product_id),
                    Product.is_active == True
                )
            )
            product = result.scalar_one_or_none()
            
            if not product:
                logger.warning("Product not found", product_id=product_id)
                return {"status": "not_found"}
            
            # Crawl
            logger.info("Crawling product", product_id=product_id, url=product.url)
            crawl_result = await crawl_product(product.url)
            
            if crawl_result.success:
                old_price = product.current_price
                new_price = crawl_result.price
                
                # Update product
                product.current_price = new_price
                product.is_available = crawl_result.is_available
                product.last_crawl_status = CrawlStatus.SUCCESS
                product.crawl_error = None
                product.last_crawled_at = datetime.utcnow()
                product.updated_at = datetime.utcnow()
                
                # Update price bounds
                if new_price < product.lowest_price:
                    product.lowest_price = new_price
                if new_price > product.highest_price:
                    product.highest_price = new_price
                
                # Add to history
                price_history = PriceHistory(
                    product_id=product.id,
                    price=new_price,
                    currency=product.currency,
                    is_available=crawl_result.is_available,
                )
                db.add(price_history)
                
                # Check if we need to create alert
                await _check_and_create_alert(db, product, old_price, new_price)
                
                await db.commit()
                
                logger.info(
                    "Product crawled successfully",
                    product_id=product_id,
                    old_price=str(old_price),
                    new_price=str(new_price)
                )
                
                return {
                    "status": "success",
                    "old_price": str(old_price),
                    "new_price": str(new_price)
                }
            else:
                product.last_crawl_status = CrawlStatus.FAILED
                product.crawl_error = crawl_result.error
                product.last_crawled_at = datetime.utcnow()
                
                await db.commit()
                
                logger.warning(
                    "Product crawl failed",
                    product_id=product_id,
                    error=crawl_result.error
                )
                
                return {"status": "failed", "error": crawl_result.error}
                
        except Exception as e:
            logger.error("Error crawling product", product_id=product_id, error=str(e))
            await db.rollback()
            raise


async def _check_and_create_alert(
    db: AsyncSession, 
    product: Product, 
    old_price: Decimal, 
    new_price: Decimal
):
    """Check if alert should be created and create it"""
    should_alert = False
    alert_type = AlertType.PRICE_DROP
    
    # Check if price dropped
    if new_price < old_price:
        # Check if target price reached
        if product.target_price and new_price <= product.target_price:
            should_alert = True
            alert_type = AlertType.TARGET_REACHED
        # Check if notify on any drop
        elif product.notify_any_drop:
            should_alert = True
            alert_type = AlertType.PRICE_DROP
    
    if should_alert:
        # Calculate savings
        savings = old_price - new_price
        percent_drop = ((old_price - new_price) / old_price) * 100
        
        if alert_type == AlertType.TARGET_REACHED:
            title = "🎯 Target Price Reached!"
            message = f"{product.name[:50]} dropped to ${new_price}! (Your target: ${product.target_price})"
        else:
            title = "💰 Price Drop Alert!"
            message = f"{product.name[:50]} dropped from ${old_price} to ${new_price} ({percent_drop:.1f}% off)"
        
        alert = Alert(
            user_id=product.user_id,
            product_id=product.id,
            alert_type=alert_type,
            old_price=old_price,
            new_price=new_price,
            title=title,
            message=message,
            status=AlertStatus.PENDING,
        )
        db.add(alert)
        
        # Trigger notification task
        from app.tasks.notification_tasks import send_alert_notification
        send_alert_notification.delay(str(alert.id))


@celery_app.task
def crawl_all_products():
    """
    Crawl all active products
    Called periodically by Celery Beat
    """
    return run_async(_crawl_all_products())


async def _crawl_all_products():
    """Async implementation of crawl all products"""
    async with async_session_maker() as db:
        try:
            # Get all active products that need crawling
            cutoff = datetime.utcnow() - timedelta(hours=6)  # Don't re-crawl too soon
            
            result = await db.execute(
                select(Product.id).where(
                    Product.is_active == True,
                    (Product.last_crawled_at == None) | (Product.last_crawled_at < cutoff)
                )
            )
            product_ids = [str(row[0]) for row in result.fetchall()]
            
            logger.info("Starting bulk crawl", product_count=len(product_ids))
            
            # Queue individual crawl tasks
            for product_id in product_ids:
                crawl_single_product.delay(product_id)
            
            return {"queued": len(product_ids)}
            
        except Exception as e:
            logger.error("Error in bulk crawl", error=str(e))
            raise


@celery_app.task
def cleanup_old_history():
    """
    Remove price history older than 1 year
    """
    return run_async(_cleanup_old_history())


async def _cleanup_old_history():
    """Async implementation of cleanup"""
    async with async_session_maker() as db:
        try:
            cutoff = datetime.utcnow() - timedelta(days=365)
            
            result = await db.execute(
                select(PriceHistory).where(PriceHistory.recorded_at < cutoff)
            )
            old_records = result.scalars().all()
            
            count = len(old_records)
            for record in old_records:
                await db.delete(record)
            
            await db.commit()
            
            logger.info("Cleaned up old history", deleted_count=count)
            return {"deleted": count}
            
        except Exception as e:
            logger.error("Error cleaning up history", error=str(e))
            await db.rollback()
            raise
