"""
Firebase Push Notification Service
Sends push notifications for price drops and alerts
"""
import json
import firebase_admin
from firebase_admin import credentials, messaging
from typing import Optional, List
import structlog

from app.config import settings

logger = structlog.get_logger()

# Initialize Firebase Admin
_firebase_app = None


def get_firebase_app():
    """Get or initialize Firebase app"""
    global _firebase_app
    
    if _firebase_app is None:
        try:
            if settings.FIREBASE_CREDENTIALS:
                cred_dict = json.loads(settings.FIREBASE_CREDENTIALS)
                cred = credentials.Certificate(cred_dict)
                _firebase_app = firebase_admin.initialize_app(cred)
                logger.info("Firebase initialized successfully")
            else:
                logger.warning("Firebase credentials not configured")
        except Exception as e:
            logger.error("Failed to initialize Firebase", error=str(e))
    
    return _firebase_app


async def send_push_notification(
    fcm_token: str,
    title: str,
    body: str,
    data: Optional[dict] = None,
    image_url: Optional[str] = None,
) -> bool:
    """
    Send push notification to a single device
    
    Args:
        fcm_token: Firebase Cloud Messaging token
        title: Notification title
        body: Notification body
        data: Additional data payload
        image_url: Optional image URL for rich notification
    
    Returns:
        True if sent successfully, False otherwise
    """
    if not get_firebase_app():
        logger.warning("Firebase not initialized, skipping push notification")
        return False
    
    try:
        message = messaging.Message(
            notification=messaging.Notification(
                title=title,
                body=body,
                image=image_url,
            ),
            data=data or {},
            token=fcm_token,
            android=messaging.AndroidConfig(
                priority="high",
                notification=messaging.AndroidNotification(
                    icon="notification_icon",
                    color="#667EEA",
                    sound="default",
                    click_action="FLUTTER_NOTIFICATION_CLICK",
                ),
            ),
            apns=messaging.APNSConfig(
                payload=messaging.APNSPayload(
                    aps=messaging.Aps(
                        alert=messaging.ApsAlert(
                            title=title,
                            body=body,
                        ),
                        sound="default",
                        badge=1,
                    ),
                ),
            ),
        )
        
        response = messaging.send(message)
        logger.info("Push notification sent", message_id=response, token=fcm_token[:20])
        return True
        
    except messaging.UnregisteredError:
        logger.warning("FCM token is unregistered", token=fcm_token[:20])
        return False
    except Exception as e:
        logger.error("Failed to send push notification", error=str(e))
        return False


async def send_push_to_multiple(
    fcm_tokens: List[str],
    title: str,
    body: str,
    data: Optional[dict] = None,
) -> dict:
    """
    Send push notification to multiple devices
    
    Returns:
        Dict with success_count and failure_count
    """
    if not get_firebase_app():
        return {"success_count": 0, "failure_count": len(fcm_tokens)}
    
    if not fcm_tokens:
        return {"success_count": 0, "failure_count": 0}
    
    try:
        message = messaging.MulticastMessage(
            notification=messaging.Notification(
                title=title,
                body=body,
            ),
            data=data or {},
            tokens=fcm_tokens,
        )
        
        response = messaging.send_multicast(message)
        
        logger.info(
            "Multicast push notification sent",
            success_count=response.success_count,
            failure_count=response.failure_count,
        )
        
        return {
            "success_count": response.success_count,
            "failure_count": response.failure_count,
        }
        
    except Exception as e:
        logger.error("Failed to send multicast notification", error=str(e))
        return {"success_count": 0, "failure_count": len(fcm_tokens)}


async def send_price_drop_notification(
    fcm_token: str,
    product_name: str,
    old_price: str,
    new_price: str,
    product_url: str,
    product_id: str,
    image_url: Optional[str] = None,
) -> bool:
    """Send price drop notification"""
    
    title = "🎉 Price Drop Alert!"
    body = f"{product_name} dropped from ${old_price} to ${new_price}!"
    
    data = {
        "type": "price_drop",
        "product_id": product_id,
        "product_url": product_url,
        "old_price": old_price,
        "new_price": new_price,
    }
    
    return await send_push_notification(
        fcm_token=fcm_token,
        title=title,
        body=body,
        data=data,
        image_url=image_url,
    )


async def send_target_reached_notification(
    fcm_token: str,
    product_name: str,
    current_price: str,
    target_price: str,
    product_id: str,
    image_url: Optional[str] = None,
) -> bool:
    """Send target price reached notification"""
    
    title = "🎯 Target Price Reached!"
    body = f"{product_name} is now ${current_price} - below your target of ${target_price}!"
    
    data = {
        "type": "target_reached",
        "product_id": product_id,
        "current_price": current_price,
        "target_price": target_price,
    }
    
    return await send_push_notification(
        fcm_token=fcm_token,
        title=title,
        body=body,
        data=data,
        image_url=image_url,
    )


async def send_back_in_stock_notification(
    fcm_token: str,
    product_name: str,
    current_price: str,
    product_id: str,
    image_url: Optional[str] = None,
) -> bool:
    """Send back in stock notification"""
    
    title = "📦 Back in Stock!"
    body = f"{product_name} is back in stock at ${current_price}!"
    
    data = {
        "type": "back_in_stock",
        "product_id": product_id,
        "current_price": current_price,
    }
    
    return await send_push_notification(
        fcm_token=fcm_token,
        title=title,
        body=body,
        data=data,
        image_url=image_url,
    )
