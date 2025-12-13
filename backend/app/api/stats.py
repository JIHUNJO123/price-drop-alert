"""
Stats API Routes
User statistics and dashboard data
"""
from decimal import Decimal
from uuid import UUID

from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, func

from app.database import get_db
from app.models import User, Product, Alert
from app.schemas import UserStats
from app.auth import get_current_user

router = APIRouter(prefix="/stats", tags=["Statistics"])


@router.get("", response_model=UserStats)
async def get_user_stats(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """
    Get user statistics for dashboard
    """
    # Total products
    products_result = await db.execute(
        select(func.count(Product.id)).where(
            Product.user_id == current_user.id,
            Product.is_active == True
        )
    )
    total_products = products_result.scalar() or 0
    
    # Total alerts
    alerts_result = await db.execute(
        select(func.count(Alert.id)).where(
            Alert.user_id == current_user.id
        )
    )
    total_alerts = alerts_result.scalar() or 0
    
    # Calculate savings (sum of all price drops)
    products_result = await db.execute(
        select(Product).where(
            Product.user_id == current_user.id,
            Product.is_active == True
        )
    )
    products = products_result.scalars().all()
    
    total_savings = Decimal("0.00")
    products_below_target = 0
    price_drops = []
    
    for product in products:
        if product.original_price and product.current_price < product.original_price:
            savings = product.original_price - product.current_price
            total_savings += savings
            
            drop_percent = ((product.original_price - product.current_price) / product.original_price) * 100
            price_drops.append(float(drop_percent))
        
        if product.target_price and product.current_price <= product.target_price:
            products_below_target += 1
    
    avg_drop = sum(price_drops) / len(price_drops) if price_drops else None
    
    return UserStats(
        total_products=total_products,
        total_alerts=total_alerts,
        total_savings=total_savings,
        products_below_target=products_below_target,
        average_price_drop_percent=round(avg_drop, 2) if avg_drop else None
    )
