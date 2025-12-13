"""
Celery Application Configuration
Background task processing for price crawling
"""
from celery import Celery
from app.config import settings

# Create Celery app
celery_app = Celery(
    "price_drop_alert",
    broker=settings.CELERY_BROKER_URL,
    backend=settings.CELERY_RESULT_BACKEND,
    include=["app.tasks.crawler_tasks", "app.tasks.notification_tasks"]
)

# Celery configuration
celery_app.conf.update(
    # Task settings
    task_serializer="json",
    accept_content=["json"],
    result_serializer="json",
    timezone="UTC",
    enable_utc=True,
    
    # Task execution
    task_acks_late=True,
    task_reject_on_worker_lost=True,
    worker_prefetch_multiplier=1,
    
    # Results
    result_expires=3600,  # 1 hour
    
    # Beat schedule (periodic tasks)
    beat_schedule={
        # Crawl all products every 12 hours
        "crawl-all-products": {
            "task": "app.tasks.crawler_tasks.crawl_all_products",
            "schedule": settings.CRAWL_INTERVAL_HOURS * 3600,  # Convert to seconds
        },
        # Cleanup old price history (keep 1 year)
        "cleanup-old-history": {
            "task": "app.tasks.crawler_tasks.cleanup_old_history",
            "schedule": 86400,  # Daily
        },
    },
    
    # Rate limiting
    task_annotations={
        "app.tasks.crawler_tasks.crawl_single_product": {
            "rate_limit": "10/m"  # 10 per minute to avoid overloading
        }
    },
)
