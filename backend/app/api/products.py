"""
Products API Routes
Track, update, and manage price-tracked products
"""
from datetime import datetime
from decimal import Decimal
from typing import Optional
from uuid import UUID
from urllib.parse import urlparse

from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, func, desc

from app.database import get_db
from app.models import User, Product, PriceHistory, SubscriptionTier, CrawlStatus
from app.schemas import (
    ProductCreate, ProductResponse, ProductUpdate, 
    ProductListResponse, ProductPreview,
    PriceHistoryResponse, PricePoint
)
from app.auth import get_current_user
from app.crawler import crawl_product
from app.config import settings

router = APIRouter(prefix="/products", tags=["Products"])


@router.post("/preview", response_model=ProductPreview)
async def preview_product(
    data: ProductCreate,
    current_user: User = Depends(get_current_user)
):
    """
    Preview product info before adding to track list
    Crawls the URL and returns extracted product data
    """
    url = str(data.url)
    
    # Crawl the product page
    result = await crawl_product(url)
    
    if not result.success:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Could not fetch product: {result.error}"
        )
    
    return ProductPreview(
        url=url,
        name=result.name or "Unknown Product",
        price=result.price,
        currency=result.currency,
        image_url=result.image_url,
        domain=result.domain,
        is_available=result.is_available
    )


@router.post("", response_model=ProductResponse, status_code=status.HTTP_201_CREATED)
async def add_product(
    data: ProductCreate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """
    Add a new product to track
    """
    # Check product limit
    result = await db.execute(
        select(func.count(Product.id)).where(
            Product.user_id == current_user.id,
            Product.is_active == True
        )
    )
    current_count = result.scalar() or 0
    
    max_products = settings.MAX_PRODUCTS_FREE
    if current_user.subscription_tier != SubscriptionTier.FREE:
        max_products = settings.MAX_PRODUCTS_PRO
    
    if current_count >= max_products:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail=f"Product limit reached ({max_products}). Upgrade to Pro for more."
        )
    
    url = str(data.url)
    
    # Check if already tracking this URL
    result = await db.execute(
        select(Product).where(
            Product.user_id == current_user.id,
            Product.url == url,
            Product.is_active == True
        )
    )
    if result.scalar_one_or_none():
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Already tracking this product"
        )
    
    # Crawl the product
    crawl_result = await crawl_product(url)
    
    if not crawl_result.success:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Could not fetch product: {crawl_result.error}"
        )
    
    # Create product
    product = Product(
        user_id=current_user.id,
        url=url,
        name=crawl_result.name or "Unknown Product",
        image_url=crawl_result.image_url,
        current_price=crawl_result.price,
        original_price=crawl_result.price,
        lowest_price=crawl_result.price,
        highest_price=crawl_result.price,
        currency=crawl_result.currency,
        target_price=data.target_price,
        notify_any_drop=data.notify_any_drop,
        domain=crawl_result.domain,
        last_crawled_at=datetime.utcnow(),
        last_crawl_status=CrawlStatus.SUCCESS,
        is_available=crawl_result.is_available,
    )
    
    db.add(product)
    await db.flush()
    
    # Add initial price history
    price_history = PriceHistory(
        product_id=product.id,
        price=crawl_result.price,
        currency=crawl_result.currency,
        is_available=crawl_result.is_available,
    )
    db.add(price_history)
    
    await db.refresh(product)
    
    return ProductResponse(
        id=product.id,
        url=product.url,
        name=product.name,
        image_url=product.image_url,
        current_price=product.current_price,
        original_price=product.original_price,
        lowest_price=product.lowest_price,
        highest_price=product.highest_price,
        currency=product.currency,
        target_price=product.target_price,
        notify_any_drop=product.notify_any_drop,
        domain=product.domain,
        last_crawled_at=product.last_crawled_at,
        last_crawl_status=product.last_crawl_status.value,
        is_available=product.is_available,
        created_at=product.created_at
    )


@router.get("", response_model=ProductListResponse)
async def list_products(
    skip: int = Query(0, ge=0),
    limit: int = Query(20, ge=1, le=100),
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """
    List all tracked products for current user
    """
    # Get total count
    count_result = await db.execute(
        select(func.count(Product.id)).where(
            Product.user_id == current_user.id,
            Product.is_active == True
        )
    )
    total = count_result.scalar() or 0
    
    # Get products
    result = await db.execute(
        select(Product)
        .where(
            Product.user_id == current_user.id,
            Product.is_active == True
        )
        .order_by(desc(Product.created_at))
        .offset(skip)
        .limit(limit)
    )
    products = result.scalars().all()
    
    return ProductListResponse(
        products=[
            ProductResponse(
                id=p.id,
                url=p.url,
                name=p.name,
                image_url=p.image_url,
                current_price=p.current_price,
                original_price=p.original_price,
                lowest_price=p.lowest_price,
                highest_price=p.highest_price,
                currency=p.currency,
                target_price=p.target_price,
                notify_any_drop=p.notify_any_drop,
                domain=p.domain,
                last_crawled_at=p.last_crawled_at,
                last_crawl_status=p.last_crawl_status.value,
                is_available=p.is_available,
                created_at=p.created_at
            )
            for p in products
        ],
        total=total,
        has_more=(skip + limit) < total
    )


@router.get("/{product_id}", response_model=ProductResponse)
async def get_product(
    product_id: UUID,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """
    Get a specific product
    """
    result = await db.execute(
        select(Product).where(
            Product.id == product_id,
            Product.user_id == current_user.id,
            Product.is_active == True
        )
    )
    product = result.scalar_one_or_none()
    
    if not product:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Product not found"
        )
    
    return ProductResponse(
        id=product.id,
        url=product.url,
        name=product.name,
        image_url=product.image_url,
        current_price=product.current_price,
        original_price=product.original_price,
        lowest_price=product.lowest_price,
        highest_price=product.highest_price,
        currency=product.currency,
        target_price=product.target_price,
        notify_any_drop=product.notify_any_drop,
        domain=product.domain,
        last_crawled_at=product.last_crawled_at,
        last_crawl_status=product.last_crawl_status.value,
        is_available=product.is_available,
        created_at=product.created_at
    )


@router.patch("/{product_id}", response_model=ProductResponse)
async def update_product(
    product_id: UUID,
    data: ProductUpdate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """
    Update product tracking settings
    """
    result = await db.execute(
        select(Product).where(
            Product.id == product_id,
            Product.user_id == current_user.id,
            Product.is_active == True
        )
    )
    product = result.scalar_one_or_none()
    
    if not product:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Product not found"
        )
    
    if data.target_price is not None:
        product.target_price = data.target_price
    if data.notify_any_drop is not None:
        product.notify_any_drop = data.notify_any_drop
    
    product.updated_at = datetime.utcnow()
    
    return await get_product(product_id, current_user, db)


@router.delete("/{product_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_product(
    product_id: UUID,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """
    Stop tracking a product (soft delete)
    """
    result = await db.execute(
        select(Product).where(
            Product.id == product_id,
            Product.user_id == current_user.id,
            Product.is_active == True
        )
    )
    product = result.scalar_one_or_none()
    
    if not product:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Product not found"
        )
    
    product.is_active = False
    product.updated_at = datetime.utcnow()


@router.get("/{product_id}/history", response_model=PriceHistoryResponse)
async def get_price_history(
    product_id: UUID,
    days: int = Query(30, ge=1, le=365),
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """
    Get price history for a product
    """
    # Verify product ownership
    result = await db.execute(
        select(Product).where(
            Product.id == product_id,
            Product.user_id == current_user.id,
            Product.is_active == True
        )
    )
    product = result.scalar_one_or_none()
    
    if not product:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Product not found"
        )
    
    # Get history
    from datetime import timedelta
    cutoff = datetime.utcnow() - timedelta(days=days)
    
    result = await db.execute(
        select(PriceHistory)
        .where(
            PriceHistory.product_id == product_id,
            PriceHistory.recorded_at >= cutoff
        )
        .order_by(PriceHistory.recorded_at)
    )
    history = result.scalars().all()
    
    # Calculate stats
    prices = [h.price for h in history]
    avg_price = sum(prices) / len(prices) if prices else None
    
    # Determine trend
    if len(prices) >= 2:
        if prices[-1] < prices[0]:
            trend = "down"
        elif prices[-1] > prices[0]:
            trend = "up"
        else:
            trend = "stable"
    else:
        trend = "stable"
    
    return PriceHistoryResponse(
        product_id=product_id,
        history=[
            PricePoint(
                price=h.price,
                recorded_at=h.recorded_at,
                is_available=h.is_available
            )
            for h in history
        ],
        lowest_price=product.lowest_price,
        highest_price=product.highest_price,
        average_price=Decimal(str(round(avg_price, 2))) if avg_price else None,
        price_trend=trend
    )


@router.post("/{product_id}/refresh", response_model=ProductResponse)
async def refresh_product(
    product_id: UUID,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """
    Manually refresh product price (crawl now)
    """
    result = await db.execute(
        select(Product).where(
            Product.id == product_id,
            Product.user_id == current_user.id,
            Product.is_active == True
        )
    )
    product = result.scalar_one_or_none()
    
    if not product:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Product not found"
        )
    
    # Crawl
    crawl_result = await crawl_product(product.url)
    
    if crawl_result.success:
        old_price = product.current_price
        product.current_price = crawl_result.price
        product.is_available = crawl_result.is_available
        product.last_crawl_status = CrawlStatus.SUCCESS
        product.crawl_error = None
        
        # Update price bounds
        if crawl_result.price < product.lowest_price:
            product.lowest_price = crawl_result.price
        if crawl_result.price > product.highest_price:
            product.highest_price = crawl_result.price
        
        # Add to history
        price_history = PriceHistory(
            product_id=product.id,
            price=crawl_result.price,
            currency=crawl_result.currency,
            is_available=crawl_result.is_available,
        )
        db.add(price_history)
    else:
        product.last_crawl_status = CrawlStatus.FAILED
        product.crawl_error = crawl_result.error
    
    product.last_crawled_at = datetime.utcnow()
    product.updated_at = datetime.utcnow()
    
    await db.refresh(product)
    
    return await get_product(product_id, current_user, db)
