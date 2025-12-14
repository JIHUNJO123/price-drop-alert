"""
Pydantic Schemas for API
Request/Response models
"""
from datetime import datetime
from decimal import Decimal
from typing import Optional, List
from uuid import UUID
from pydantic import BaseModel, EmailStr, HttpUrl, Field, validator


# ============ Auth Schemas ============

class UserCreate(BaseModel):
    email: EmailStr
    password: str = Field(..., min_length=8, max_length=128)
    name: Optional[str] = Field(None, min_length=2, max_length=50)
    
    @validator('password')
    def password_strength(cls, v):
        if len(v) < 8:
            raise ValueError('Password must be at least 8 characters')
        if len(v) > 128:
            raise ValueError('Password must be less than 128 characters')
        if not any(c.isupper() for c in v):
            raise ValueError('Password must contain at least one uppercase letter')
        if not any(c.islower() for c in v):
            raise ValueError('Password must contain at least one lowercase letter')
        if not any(c.isdigit() for c in v):
            raise ValueError('Password must contain at least one number')
        return v
    
    @validator('name')
    def name_valid(cls, v):
        if v is not None:
            v = v.strip()
            if len(v) < 2:
                raise ValueError('Name must be at least 2 characters')
            if len(v) > 50:
                raise ValueError('Name must be less than 50 characters')
            # Only allow letters, numbers, spaces, and common punctuation
            import re
            if not re.match(r'^[a-zA-Z0-9\s\-_.]+$', v):
                raise ValueError('Name can only contain letters, numbers, spaces, hyphens, underscores, and periods')
        return v if v else None


class UserLogin(BaseModel):
    email: EmailStr
    password: str


class Token(BaseModel):
    access_token: str
    token_type: str = "bearer"
    expires_in: int


class UserResponse(BaseModel):
    id: UUID
    email: str
    name: Optional[str]
    subscription_tier: str
    subscription_status: str
    trial_ends_at: Optional[datetime]
    product_count: int = 0
    max_products: int = 3
    created_at: datetime

    class Config:
        from_attributes = True


class UserUpdate(BaseModel):
    name: Optional[str] = None
    timezone: Optional[str] = None
    push_enabled: Optional[bool] = None
    email_enabled: Optional[bool] = None
    fcm_token: Optional[str] = None


class ForgotPasswordRequest(BaseModel):
    email: EmailStr


class ForgotPasswordResponse(BaseModel):
    message: str


# ============ Product Schemas ============

class ProductCreate(BaseModel):
    url: HttpUrl
    target_price: Optional[Decimal] = Field(None, ge=0)
    notify_any_drop: bool = False


class ProductPreview(BaseModel):
    """Preview product info before adding"""
    url: str
    name: str
    price: Decimal
    currency: str = "USD"
    image_url: Optional[str]
    domain: str
    is_available: bool


class ProductResponse(BaseModel):
    id: UUID
    url: str
    name: str
    image_url: Optional[str]
    current_price: Decimal
    original_price: Optional[Decimal]
    lowest_price: Decimal
    highest_price: Decimal
    currency: str
    target_price: Optional[Decimal]
    notify_any_drop: bool
    domain: str
    last_crawled_at: Optional[datetime]
    last_crawl_status: str
    is_available: bool
    created_at: datetime
    
    # Computed fields
    price_change_percent: Optional[float] = None
    
    class Config:
        from_attributes = True
    
    @validator("price_change_percent", always=True)
    def compute_price_change(cls, v, values):
        current = values.get("current_price")
        original = values.get("original_price")
        if current and original and original > 0:
            change = ((current - original) / original) * 100
            return round(float(change), 2)
        return None


class ProductUpdate(BaseModel):
    target_price: Optional[Decimal] = Field(None, ge=0)
    notify_any_drop: Optional[bool] = None


class ProductListResponse(BaseModel):
    products: List[ProductResponse]
    total: int
    has_more: bool


# ============ Price History Schemas ============

class PricePoint(BaseModel):
    price: Decimal
    recorded_at: datetime
    is_available: bool

    class Config:
        from_attributes = True


class PriceHistoryResponse(BaseModel):
    product_id: UUID
    history: List[PricePoint]
    lowest_price: Decimal
    highest_price: Decimal
    average_price: Optional[Decimal]
    price_trend: str  # "up", "down", "stable"


# ============ Alert Schemas ============

class AlertResponse(BaseModel):
    id: UUID
    product_id: UUID
    product_name: str
    product_image: Optional[str]
    alert_type: str
    old_price: Decimal
    new_price: Decimal
    currency: str = "USD"
    title: str
    message: str
    status: str
    created_at: datetime
    read_at: Optional[datetime]

    class Config:
        from_attributes = True


class AlertListResponse(BaseModel):
    alerts: List[AlertResponse]
    total: int
    unread_count: int


class MarkAlertsRead(BaseModel):
    alert_ids: List[UUID]


# ============ Subscription Schemas ============

class SubscriptionInfo(BaseModel):
    tier: str
    status: str
    trial_ends_at: Optional[datetime]
    subscription_ends_at: Optional[datetime]
    can_upgrade: bool
    product_limit: int
    current_product_count: int


class CreateCheckoutSession(BaseModel):
    price_id: str  # Stripe price ID
    success_url: str
    cancel_url: str


class CheckoutSessionResponse(BaseModel):
    checkout_url: str
    session_id: str


# ============ Stats Schemas ============

class UserStats(BaseModel):
    total_products: int
    total_alerts: int
    total_savings: Decimal  # Sum of price drops
    products_below_target: int
    average_price_drop_percent: Optional[float]


# ============ Common Schemas ============

class HealthCheck(BaseModel):
    status: str
    version: str
    database: str
    redis: str


class ErrorResponse(BaseModel):
    detail: str
    code: Optional[str] = None
