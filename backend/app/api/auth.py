"""
Authentication API Routes
User registration, login, profile management
"""
from datetime import datetime, timedelta
from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select

from app.database import get_db
from app.models import User, SubscriptionTier, SubscriptionStatus
from app.schemas import (
    UserCreate, UserLogin, Token, UserResponse, UserUpdate
)
from app.auth import (
    hash_password, verify_password, create_access_token, 
    get_current_user
)
from app.config import settings

router = APIRouter(prefix="/auth", tags=["Authentication"])


@router.post("/register", response_model=Token, status_code=status.HTTP_201_CREATED)
async def register(
    user_data: UserCreate,
    db: AsyncSession = Depends(get_db)
):
    """
    Register a new user account
    """
    # Check if email already exists
    result = await db.execute(
        select(User).where(User.email == user_data.email.lower())
    )
    if result.scalar_one_or_none():
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Email already registered"
        )
    
    # Create new user with trial
    user = User(
        email=user_data.email.lower(),
        hashed_password=hash_password(user_data.password),
        name=user_data.name,
        subscription_tier=SubscriptionTier.FREE,
        subscription_status=SubscriptionStatus.TRIAL,
        trial_ends_at=datetime.utcnow() + timedelta(days=settings.TRIAL_DAYS),
    )
    
    db.add(user)
    await db.flush()
    await db.refresh(user)
    
    # Generate token
    access_token = create_access_token(user.id)
    
    return Token(
        access_token=access_token,
        token_type="bearer",
        expires_in=settings.ACCESS_TOKEN_EXPIRE_MINUTES * 60
    )


@router.post("/login", response_model=Token)
async def login(
    credentials: UserLogin,
    db: AsyncSession = Depends(get_db)
):
    """
    Login with email and password
    """
    # Find user
    result = await db.execute(
        select(User).where(User.email == credentials.email.lower())
    )
    user = result.scalar_one_or_none()
    
    if not user or not verify_password(credentials.password, user.hashed_password):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect email or password"
        )
    
    if not user.is_active:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Account is disabled"
        )
    
    # Update last login
    user.last_login_at = datetime.utcnow()
    
    # Generate token
    access_token = create_access_token(user.id)
    
    return Token(
        access_token=access_token,
        token_type="bearer",
        expires_in=settings.ACCESS_TOKEN_EXPIRE_MINUTES * 60
    )


@router.get("/me", response_model=UserResponse)
async def get_me(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """
    Get current user profile
    """
    # Count products
    from app.models import Product
    from sqlalchemy import func
    
    result = await db.execute(
        select(func.count(Product.id)).where(
            Product.user_id == current_user.id,
            Product.is_active == True
        )
    )
    product_count = result.scalar() or 0
    
    # Determine max products based on subscription
    max_products = settings.MAX_PRODUCTS_FREE
    if current_user.subscription_tier != SubscriptionTier.FREE:
        max_products = settings.MAX_PRODUCTS_PRO
    
    return UserResponse(
        id=current_user.id,
        email=current_user.email,
        name=current_user.name,
        subscription_tier=current_user.subscription_tier.value,
        subscription_status=current_user.subscription_status.value,
        trial_ends_at=current_user.trial_ends_at,
        product_count=product_count,
        max_products=max_products,
        created_at=current_user.created_at
    )


@router.patch("/me", response_model=UserResponse)
async def update_me(
    update_data: UserUpdate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """
    Update current user profile
    """
    if update_data.name is not None:
        current_user.name = update_data.name
    if update_data.timezone is not None:
        current_user.timezone = update_data.timezone
    if update_data.push_enabled is not None:
        current_user.push_enabled = update_data.push_enabled
    if update_data.email_enabled is not None:
        current_user.email_enabled = update_data.email_enabled
    if update_data.fcm_token is not None:
        current_user.fcm_token = update_data.fcm_token
    
    current_user.updated_at = datetime.utcnow()
    
    return await get_me(current_user, db)


@router.post("/logout")
async def logout():
    """
    Logout current user (client should discard token)
    """
    return {"message": "Successfully logged out"}
