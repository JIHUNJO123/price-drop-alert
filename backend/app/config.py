"""
Application Configuration
Environment-based settings for the Price Drop Alert app
"""
from pydantic_settings import BaseSettings
from typing import Optional
from functools import lru_cache


class Settings(BaseSettings):
    # App
    APP_NAME: str = "Price Drop Alert"
    APP_VERSION: str = "1.0.0"
    DEBUG: bool = False
    SECRET_KEY: str = "your-super-secret-key-change-in-production"
    
    # Database
    DATABASE_URL: str = "postgresql+asyncpg://postgres:password@localhost:5432/pricedrop"
    DATABASE_POOL_SIZE: int = 20
    
    # Redis
    REDIS_URL: str = "redis://localhost:6379/0"
    
    # Celery
    CELERY_BROKER_URL: str = "redis://localhost:6379/1"
    CELERY_RESULT_BACKEND: str = "redis://localhost:6379/2"
    
    # JWT Auth
    JWT_SECRET_KEY: str = "jwt-secret-key-change-in-production"
    JWT_ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 60 * 24 * 7  # 7 days
    
    # Email (SendGrid)
    SENDGRID_API_KEY: Optional[str] = None
    FROM_EMAIL: str = "alerts@pricedropalert.com"
    
    # Firebase (Push Notifications)
    FIREBASE_CREDENTIALS_PATH: Optional[str] = None
    
    # Crawling
    CRAWL_INTERVAL_HOURS: int = 12
    MAX_PRODUCTS_FREE: int = 10
    MAX_PRODUCTS_PRO: int = 100
    REQUEST_TIMEOUT: int = 90  # 90 seconds for slow sites like Walmart
    
    # Subscription Pricing (USD)
    PRO_MONTHLY_PRICE: float = 4.99
    PRO_ANNUAL_PRICE: float = 39.99
    TRIAL_DAYS: int = 3
    
    # Sentry (Error Tracking)
    SENTRY_DSN: Optional[str] = None
    
    class Config:
        env_file = ".env"
        case_sensitive = True


@lru_cache()
def get_settings() -> Settings:
    return Settings()


settings = get_settings()
