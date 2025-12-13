"""
Database Models
SQLAlchemy ORM models for Price Drop Alert
"""
from datetime import datetime
from decimal import Decimal
from typing import Optional, List
from enum import Enum as PyEnum

from sqlalchemy import (
    Column, String, Integer, Float, Boolean, DateTime, 
    ForeignKey, Text, Enum, Index, Numeric
)
from sqlalchemy.orm import DeclarativeBase, relationship, Mapped, mapped_column
from sqlalchemy.dialects.postgresql import UUID, JSONB
import uuid


class Base(DeclarativeBase):
    pass


class SubscriptionTier(str, PyEnum):
    FREE = "free"
    PRO = "pro"
    ANNUAL = "annual"


class SubscriptionStatus(str, PyEnum):
    ACTIVE = "active"
    TRIAL = "trial"
    CANCELLED = "cancelled"
    EXPIRED = "expired"


class CrawlStatus(str, PyEnum):
    PENDING = "pending"
    SUCCESS = "success"
    FAILED = "failed"


class User(Base):
    """User account model"""
    __tablename__ = "users"
    
    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    email: Mapped[str] = mapped_column(String(255), unique=True, nullable=False, index=True)
    hashed_password: Mapped[str] = mapped_column(String(255), nullable=False)
    
    # Profile
    name: Mapped[Optional[str]] = mapped_column(String(100))
    timezone: Mapped[str] = mapped_column(String(50), default="America/New_York")
    
    # Subscription
    subscription_tier: Mapped[SubscriptionTier] = mapped_column(
        Enum(SubscriptionTier), default=SubscriptionTier.FREE
    )
    subscription_status: Mapped[SubscriptionStatus] = mapped_column(
        Enum(SubscriptionStatus), default=SubscriptionStatus.ACTIVE
    )
    trial_ends_at: Mapped[Optional[datetime]] = mapped_column(DateTime(timezone=True))
    subscription_ends_at: Mapped[Optional[datetime]] = mapped_column(DateTime(timezone=True))
    
    # Stripe
    stripe_customer_id: Mapped[Optional[str]] = mapped_column(String(100))
    stripe_subscription_id: Mapped[Optional[str]] = mapped_column(String(100))
    
    # Push Notifications
    fcm_token: Mapped[Optional[str]] = mapped_column(String(500))
    push_enabled: Mapped[bool] = mapped_column(Boolean, default=True)
    email_enabled: Mapped[bool] = mapped_column(Boolean, default=True)
    
    # Status
    is_active: Mapped[bool] = mapped_column(Boolean, default=True)
    is_verified: Mapped[bool] = mapped_column(Boolean, default=False)
    
    # Timestamps
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=datetime.utcnow)
    updated_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=datetime.utcnow, onupdate=datetime.utcnow)
    last_login_at: Mapped[Optional[datetime]] = mapped_column(DateTime(timezone=True))
    
    # Relationships
    products: Mapped[List["Product"]] = relationship("Product", back_populates="user", cascade="all, delete-orphan")
    alerts: Mapped[List["Alert"]] = relationship("Alert", back_populates="user", cascade="all, delete-orphan")
    
    def __repr__(self):
        return f"<User {self.email}>"
    
    @property
    def can_add_product(self) -> bool:
        """Check if user can add more products based on subscription"""
        from app.config import settings
        if self.subscription_tier == SubscriptionTier.FREE:
            return len(self.products) < settings.MAX_PRODUCTS_FREE
        return len(self.products) < settings.MAX_PRODUCTS_PRO


class Product(Base):
    """Tracked product model"""
    __tablename__ = "products"
    
    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=False)
    
    # Product Info
    url: Mapped[str] = mapped_column(Text, nullable=False)
    name: Mapped[str] = mapped_column(String(500), nullable=False)
    image_url: Mapped[Optional[str]] = mapped_column(Text)
    
    # Price
    current_price: Mapped[Decimal] = mapped_column(Numeric(10, 2), nullable=False)
    original_price: Mapped[Optional[Decimal]] = mapped_column(Numeric(10, 2))
    lowest_price: Mapped[Decimal] = mapped_column(Numeric(10, 2), nullable=False)
    highest_price: Mapped[Decimal] = mapped_column(Numeric(10, 2), nullable=False)
    currency: Mapped[str] = mapped_column(String(3), default="USD")
    
    # Target
    target_price: Mapped[Optional[Decimal]] = mapped_column(Numeric(10, 2))
    notify_any_drop: Mapped[bool] = mapped_column(Boolean, default=False)
    
    # Crawl Info
    domain: Mapped[str] = mapped_column(String(255), nullable=False, index=True)
    last_crawled_at: Mapped[Optional[datetime]] = mapped_column(DateTime(timezone=True))
    last_crawl_status: Mapped[CrawlStatus] = mapped_column(
        Enum(CrawlStatus), default=CrawlStatus.PENDING
    )
    crawl_error: Mapped[Optional[str]] = mapped_column(Text)
    
    # Metadata
    extra_data: Mapped[Optional[dict]] = mapped_column(JSONB)
    
    # Status
    is_active: Mapped[bool] = mapped_column(Boolean, default=True)
    is_available: Mapped[bool] = mapped_column(Boolean, default=True)
    
    # Timestamps
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=datetime.utcnow)
    updated_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=datetime.utcnow, onupdate=datetime.utcnow)
    
    # Relationships
    user: Mapped["User"] = relationship("User", back_populates="products")
    price_history: Mapped[List["PriceHistory"]] = relationship(
        "PriceHistory", back_populates="product", cascade="all, delete-orphan"
    )
    alerts: Mapped[List["Alert"]] = relationship(
        "Alert", back_populates="product", cascade="all, delete-orphan"
    )
    
    # Indexes
    __table_args__ = (
        Index("ix_products_user_active", "user_id", "is_active"),
        Index("ix_products_last_crawled", "last_crawled_at"),
    )
    
    def __repr__(self):
        return f"<Product {self.name[:30]}>"


class PriceHistory(Base):
    """Price history tracking"""
    __tablename__ = "price_history"
    
    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    product_id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), ForeignKey("products.id"), nullable=False)
    
    price: Mapped[Decimal] = mapped_column(Numeric(10, 2), nullable=False)
    currency: Mapped[str] = mapped_column(String(3), default="USD")
    
    is_available: Mapped[bool] = mapped_column(Boolean, default=True)
    
    recorded_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=datetime.utcnow, index=True)
    
    # Relationships
    product: Mapped["Product"] = relationship("Product", back_populates="price_history")
    
    # Indexes
    __table_args__ = (
        Index("ix_price_history_product_date", "product_id", "recorded_at"),
    )
    
    def __repr__(self):
        return f"<PriceHistory ${self.price} at {self.recorded_at}>"


class AlertType(str, PyEnum):
    PRICE_DROP = "price_drop"
    TARGET_REACHED = "target_reached"
    BACK_IN_STOCK = "back_in_stock"


class AlertStatus(str, PyEnum):
    PENDING = "pending"
    SENT = "sent"
    FAILED = "failed"
    READ = "read"


class Alert(Base):
    """User alerts/notifications"""
    __tablename__ = "alerts"
    
    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=False)
    product_id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), ForeignKey("products.id"), nullable=False)
    
    alert_type: Mapped[AlertType] = mapped_column(Enum(AlertType), nullable=False)
    
    # Price Info
    old_price: Mapped[Decimal] = mapped_column(Numeric(10, 2), nullable=False)
    new_price: Mapped[Decimal] = mapped_column(Numeric(10, 2), nullable=False)
    
    # Message
    title: Mapped[str] = mapped_column(String(255), nullable=False)
    message: Mapped[str] = mapped_column(Text, nullable=False)
    
    # Status
    status: Mapped[AlertStatus] = mapped_column(Enum(AlertStatus), default=AlertStatus.PENDING)
    sent_via_push: Mapped[bool] = mapped_column(Boolean, default=False)
    sent_via_email: Mapped[bool] = mapped_column(Boolean, default=False)
    
    # Timestamps
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=datetime.utcnow)
    sent_at: Mapped[Optional[datetime]] = mapped_column(DateTime(timezone=True))
    read_at: Mapped[Optional[datetime]] = mapped_column(DateTime(timezone=True))
    
    # Relationships
    user: Mapped["User"] = relationship("User", back_populates="alerts")
    product: Mapped["Product"] = relationship("Product", back_populates="alerts")
    
    # Indexes
    __table_args__ = (
        Index("ix_alerts_user_status", "user_id", "status"),
        Index("ix_alerts_created", "created_at"),
    )
    
    def __repr__(self):
        return f"<Alert {self.alert_type} for {self.product_id}>"


class SupportedSite(Base):
    """Supported e-commerce sites configuration"""
    __tablename__ = "supported_sites"
    
    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    domain: Mapped[str] = mapped_column(String(255), unique=True, nullable=False)
    name: Mapped[str] = mapped_column(String(100), nullable=False)
    
    # Selectors
    price_selector: Mapped[str] = mapped_column(Text, nullable=False)
    name_selector: Mapped[str] = mapped_column(Text, nullable=False)
    image_selector: Mapped[Optional[str]] = mapped_column(Text)
    availability_selector: Mapped[Optional[str]] = mapped_column(Text)
    
    # Config
    requires_js: Mapped[bool] = mapped_column(Boolean, default=True)
    extra_config: Mapped[Optional[dict]] = mapped_column(JSONB)
    
    is_active: Mapped[bool] = mapped_column(Boolean, default=True)
    
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=datetime.utcnow)
    updated_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=datetime.utcnow, onupdate=datetime.utcnow)
    
    def __repr__(self):
        return f"<SupportedSite {self.domain}>"
