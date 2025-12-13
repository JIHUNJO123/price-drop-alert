"""
Alerts API Routes
Notification management
"""
from datetime import datetime
from typing import Optional
from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, func, desc, update

from app.database import get_db
from app.models import User, Alert, Product, AlertStatus
from app.schemas import AlertResponse, AlertListResponse, MarkAlertsRead
from app.auth import get_current_user

router = APIRouter(prefix="/alerts", tags=["Alerts"])


@router.get("", response_model=AlertListResponse)
async def list_alerts(
    skip: int = Query(0, ge=0),
    limit: int = Query(20, ge=1, le=100),
    unread_only: bool = Query(False),
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """
    List all alerts for current user
    """
    # Base query
    base_query = select(Alert).where(Alert.user_id == current_user.id)
    
    if unread_only:
        base_query = base_query.where(Alert.read_at == None)
    
    # Get total count
    count_query = select(func.count(Alert.id)).where(Alert.user_id == current_user.id)
    if unread_only:
        count_query = count_query.where(Alert.read_at == None)
    
    count_result = await db.execute(count_query)
    total = count_result.scalar() or 0
    
    # Get unread count
    unread_result = await db.execute(
        select(func.count(Alert.id)).where(
            Alert.user_id == current_user.id,
            Alert.read_at == None
        )
    )
    unread_count = unread_result.scalar() or 0
    
    # Get alerts with product info
    result = await db.execute(
        base_query
        .order_by(desc(Alert.created_at))
        .offset(skip)
        .limit(limit)
    )
    alerts = result.scalars().all()
    
    # Get product info for each alert
    alert_responses = []
    for alert in alerts:
        product_result = await db.execute(
            select(Product).where(Product.id == alert.product_id)
        )
        product = product_result.scalar_one_or_none()
        
        alert_responses.append(AlertResponse(
            id=alert.id,
            product_id=alert.product_id,
            product_name=product.name if product else "Unknown",
            product_image=product.image_url if product else None,
            alert_type=alert.alert_type.value,
            old_price=alert.old_price,
            new_price=alert.new_price,
            title=alert.title,
            message=alert.message,
            status=alert.status.value,
            created_at=alert.created_at,
            read_at=alert.read_at
        ))
    
    return AlertListResponse(
        alerts=alert_responses,
        total=total,
        unread_count=unread_count
    )


@router.get("/{alert_id}", response_model=AlertResponse)
async def get_alert(
    alert_id: UUID,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """
    Get a specific alert
    """
    result = await db.execute(
        select(Alert).where(
            Alert.id == alert_id,
            Alert.user_id == current_user.id
        )
    )
    alert = result.scalar_one_or_none()
    
    if not alert:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Alert not found"
        )
    
    # Get product info
    product_result = await db.execute(
        select(Product).where(Product.id == alert.product_id)
    )
    product = product_result.scalar_one_or_none()
    
    return AlertResponse(
        id=alert.id,
        product_id=alert.product_id,
        product_name=product.name if product else "Unknown",
        product_image=product.image_url if product else None,
        alert_type=alert.alert_type.value,
        old_price=alert.old_price,
        new_price=alert.new_price,
        title=alert.title,
        message=alert.message,
        status=alert.status.value,
        created_at=alert.created_at,
        read_at=alert.read_at
    )


@router.post("/{alert_id}/read", response_model=AlertResponse)
async def mark_alert_read(
    alert_id: UUID,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """
    Mark a single alert as read
    """
    result = await db.execute(
        select(Alert).where(
            Alert.id == alert_id,
            Alert.user_id == current_user.id
        )
    )
    alert = result.scalar_one_or_none()
    
    if not alert:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Alert not found"
        )
    
    alert.read_at = datetime.utcnow()
    alert.status = AlertStatus.READ
    
    return await get_alert(alert_id, current_user, db)


@router.post("/read-all")
async def mark_all_read(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """
    Mark all alerts as read
    """
    await db.execute(
        update(Alert)
        .where(
            Alert.user_id == current_user.id,
            Alert.read_at == None
        )
        .values(
            read_at=datetime.utcnow(),
            status=AlertStatus.READ
        )
    )
    
    return {"message": "All alerts marked as read"}


@router.post("/read-bulk")
async def mark_bulk_read(
    data: MarkAlertsRead,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """
    Mark multiple alerts as read
    """
    await db.execute(
        update(Alert)
        .where(
            Alert.user_id == current_user.id,
            Alert.id.in_(data.alert_ids)
        )
        .values(
            read_at=datetime.utcnow(),
            status=AlertStatus.READ
        )
    )
    
    return {"message": f"Marked {len(data.alert_ids)} alerts as read"}


@router.delete("/{alert_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_alert(
    alert_id: UUID,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """
    Delete an alert
    """
    result = await db.execute(
        select(Alert).where(
            Alert.id == alert_id,
            Alert.user_id == current_user.id
        )
    )
    alert = result.scalar_one_or_none()
    
    if not alert:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Alert not found"
        )
    
    await db.delete(alert)
