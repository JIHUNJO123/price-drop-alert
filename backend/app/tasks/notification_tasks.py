"""
Notification Background Tasks
Email and Push notification sending
"""
import asyncio
from datetime import datetime
from uuid import UUID
from typing import Optional

from celery import shared_task
from sqlalchemy import select
import structlog

from app.celery_app import celery_app
from app.database import async_session_maker
from app.models import Alert, User, AlertStatus
from app.config import settings

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
def send_alert_notification(self, alert_id: str):
    """
    Send notification for an alert (email + push)
    """
    return run_async(_send_alert_notification(alert_id))


async def _send_alert_notification(alert_id: str):
    """Async implementation of send notification"""
    async with async_session_maker() as db:
        try:
            # Get alert with user
            result = await db.execute(
                select(Alert).where(Alert.id == UUID(alert_id))
            )
            alert = result.scalar_one_or_none()
            
            if not alert:
                logger.warning("Alert not found", alert_id=alert_id)
                return {"status": "not_found"}
            
            # Get user
            user_result = await db.execute(
                select(User).where(User.id == alert.user_id)
            )
            user = user_result.scalar_one_or_none()
            
            if not user:
                logger.warning("User not found for alert", alert_id=alert_id)
                return {"status": "user_not_found"}
            
            sent_push = False
            sent_email = False
            
            # Send push notification
            if user.push_enabled and user.fcm_token:
                try:
                    await send_push_notification(
                        fcm_token=user.fcm_token,
                        title=alert.title,
                        body=alert.message,
                        data={
                            "alert_id": str(alert.id),
                            "product_id": str(alert.product_id),
                            "type": alert.alert_type.value
                        }
                    )
                    sent_push = True
                    logger.info("Push notification sent", alert_id=alert_id)
                except Exception as e:
                    logger.error("Failed to send push", alert_id=alert_id, error=str(e))
            
            # Send email
            if user.email_enabled:
                try:
                    await send_email_notification(
                        to_email=user.email,
                        subject=alert.title,
                        body=alert.message,
                        product_id=str(alert.product_id)
                    )
                    sent_email = True
                    logger.info("Email notification sent", alert_id=alert_id)
                except Exception as e:
                    logger.error("Failed to send email", alert_id=alert_id, error=str(e))
            
            # Update alert status
            alert.sent_via_push = sent_push
            alert.sent_via_email = sent_email
            alert.status = AlertStatus.SENT if (sent_push or sent_email) else AlertStatus.FAILED
            alert.sent_at = datetime.utcnow()
            
            await db.commit()
            
            return {
                "status": "success",
                "sent_push": sent_push,
                "sent_email": sent_email
            }
            
        except Exception as e:
            logger.error("Error sending notification", alert_id=alert_id, error=str(e))
            await db.rollback()
            raise


async def send_push_notification(
    fcm_token: str,
    title: str,
    body: str,
    data: Optional[dict] = None
):
    """
    Send Firebase Cloud Messaging push notification
    """
    if not settings.FIREBASE_CREDENTIALS_PATH:
        logger.warning("Firebase credentials not configured, skipping push")
        return
    
    try:
        import firebase_admin
        from firebase_admin import credentials, messaging
        
        # Initialize Firebase if not already done
        if not firebase_admin._apps:
            cred = credentials.Certificate(settings.FIREBASE_CREDENTIALS_PATH)
            firebase_admin.initialize_app(cred)
        
        message = messaging.Message(
            notification=messaging.Notification(
                title=title,
                body=body,
            ),
            data=data or {},
            token=fcm_token,
            android=messaging.AndroidConfig(
                priority="high",
                notification=messaging.AndroidNotification(
                    icon="notification_icon",
                    color="#4CAF50",
                    sound="default",
                )
            ),
            apns=messaging.APNSConfig(
                payload=messaging.APNSPayload(
                    aps=messaging.Aps(
                        sound="default",
                        badge=1,
                    )
                )
            )
        )
        
        response = messaging.send(message)
        logger.info("FCM message sent", response=response)
        
    except Exception as e:
        logger.error("FCM send error", error=str(e))
        raise


async def send_email_notification(
    to_email: str,
    subject: str,
    body: str,
    product_id: str
):
    """
    Send email notification via SendGrid
    """
    if not settings.SENDGRID_API_KEY:
        logger.warning("SendGrid API key not configured, skipping email")
        return
    
    try:
        from sendgrid import SendGridAPIClient
        from sendgrid.helpers.mail import Mail, Email, To, Content
        
        # Create HTML email
        html_content = f"""
        <!DOCTYPE html>
        <html>
        <head>
            <style>
                body {{ font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; }}
                .container {{ max-width: 600px; margin: 0 auto; padding: 20px; }}
                .header {{ background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; padding: 30px; text-align: center; border-radius: 10px 10px 0 0; }}
                .content {{ background: #f8f9fa; padding: 30px; border-radius: 0 0 10px 10px; }}
                .price-box {{ background: white; padding: 20px; border-radius: 8px; margin: 20px 0; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }}
                .btn {{ display: inline-block; background: #667eea; color: white; padding: 12px 30px; text-decoration: none; border-radius: 6px; margin-top: 20px; }}
                .footer {{ text-align: center; padding: 20px; color: #666; font-size: 12px; }}
            </style>
        </head>
        <body>
            <div class="container">
                <div class="header">
                    <h1>💰 Price Drop Alert</h1>
                </div>
                <div class="content">
                    <div class="price-box">
                        <p>{body}</p>
                    </div>
                    <center>
                        <a href="https://pricedropalert.com/products/{product_id}" class="btn">View Product</a>
                    </center>
                </div>
                <div class="footer">
                    <p>You're receiving this because you set up a price alert.</p>
                    <p>© 2024 Price Drop Alert. Never overpay again.</p>
                </div>
            </div>
        </body>
        </html>
        """
        
        message = Mail(
            from_email=Email(settings.FROM_EMAIL, "Price Drop Alert"),
            to_emails=To(to_email),
            subject=subject,
            html_content=Content("text/html", html_content)
        )
        
        sg = SendGridAPIClient(settings.SENDGRID_API_KEY)
        response = sg.send(message)
        
        logger.info("Email sent", status_code=response.status_code)
        
    except Exception as e:
        logger.error("SendGrid send error", error=str(e))
        raise


@celery_app.task
def send_weekly_digest():
    """
    Send weekly price summary email to users
    """
    return run_async(_send_weekly_digest())


async def _send_weekly_digest():
    """Async implementation of weekly digest"""
    async with async_session_maker() as db:
        try:
            # Get all active users with email enabled
            result = await db.execute(
                select(User).where(
                    User.is_active == True,
                    User.email_enabled == True
                )
            )
            users = result.scalars().all()
            
            sent_count = 0
            for user in users:
                try:
                    # Get user's product stats for the week
                    # ... implementation would go here
                    pass
                except Exception as e:
                    logger.error("Failed to send digest", user_id=str(user.id), error=str(e))
            
            return {"sent": sent_count}
            
        except Exception as e:
            logger.error("Error sending weekly digest", error=str(e))
            raise
