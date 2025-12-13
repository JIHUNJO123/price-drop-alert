"""
Stripe Payment Integration
Handles Pro subscription payments
"""
import stripe
from fastapi import APIRouter, HTTPException, Request, Depends
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from datetime import datetime, timezone, timedelta

from app.config import settings
from app.database import get_db
from app.models import User, SubscriptionTier, SubscriptionStatus
from app.auth import get_current_user

router = APIRouter(prefix="/payments", tags=["Payments"])

# Initialize Stripe
stripe.api_key = settings.STRIPE_SECRET_KEY


@router.post("/create-checkout-session")
async def create_checkout_session(
    plan: str,  # "monthly" or "annual"
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Create Stripe Checkout session for Pro subscription"""
    
    if plan == "monthly":
        price_id = settings.STRIPE_PRICE_PRO_MONTHLY
        amount = 499  # $4.99
    elif plan == "annual":
        price_id = settings.STRIPE_PRICE_PRO_ANNUAL
        amount = 3999  # $39.99
    else:
        raise HTTPException(status_code=400, detail="Invalid plan")
    
    try:
        # Create or get Stripe customer
        if not current_user.stripe_customer_id:
            customer = stripe.Customer.create(
                email=current_user.email,
                name=current_user.name,
                metadata={"user_id": str(current_user.id)}
            )
            current_user.stripe_customer_id = customer.id
            await db.commit()
        
        # Create checkout session
        session = stripe.checkout.Session.create(
            customer=current_user.stripe_customer_id,
            payment_method_types=["card"],
            line_items=[{
                "price": price_id,
                "quantity": 1,
            }],
            mode="subscription",
            success_url=f"{settings.FRONTEND_URL}/payment/success?session_id={{CHECKOUT_SESSION_ID}}",
            cancel_url=f"{settings.FRONTEND_URL}/payment/cancel",
            metadata={
                "user_id": str(current_user.id),
                "plan": plan,
            }
        )
        
        return {"checkout_url": session.url, "session_id": session.id}
        
    except stripe.error.StripeError as e:
        raise HTTPException(status_code=400, detail=str(e))


@router.post("/webhook")
async def stripe_webhook(request: Request, db: AsyncSession = Depends(get_db)):
    """Handle Stripe webhook events"""
    
    payload = await request.body()
    sig_header = request.headers.get("stripe-signature")
    
    try:
        event = stripe.Webhook.construct_event(
            payload, sig_header, settings.STRIPE_WEBHOOK_SECRET
        )
    except ValueError:
        raise HTTPException(status_code=400, detail="Invalid payload")
    except stripe.error.SignatureVerificationError:
        raise HTTPException(status_code=400, detail="Invalid signature")
    
    # Handle events
    if event["type"] == "checkout.session.completed":
        session = event["data"]["object"]
        await handle_successful_payment(session, db)
        
    elif event["type"] == "customer.subscription.updated":
        subscription = event["data"]["object"]
        await handle_subscription_update(subscription, db)
        
    elif event["type"] == "customer.subscription.deleted":
        subscription = event["data"]["object"]
        await handle_subscription_cancelled(subscription, db)
        
    elif event["type"] == "invoice.payment_failed":
        invoice = event["data"]["object"]
        await handle_payment_failed(invoice, db)
    
    return {"status": "success"}


async def handle_successful_payment(session: dict, db: AsyncSession):
    """Process successful payment"""
    user_id = session["metadata"]["user_id"]
    plan = session["metadata"]["plan"]
    subscription_id = session["subscription"]
    
    result = await db.execute(select(User).where(User.id == user_id))
    user = result.scalar_one_or_none()
    
    if user:
        user.subscription_tier = SubscriptionTier.PRO
        user.subscription_status = SubscriptionStatus.ACTIVE
        user.stripe_subscription_id = subscription_id
        
        if plan == "monthly":
            user.subscription_ends_at = datetime.now(timezone.utc) + timedelta(days=30)
        else:
            user.subscription_ends_at = datetime.now(timezone.utc) + timedelta(days=365)
        
        await db.commit()


async def handle_subscription_update(subscription: dict, db: AsyncSession):
    """Handle subscription status changes"""
    customer_id = subscription["customer"]
    
    result = await db.execute(
        select(User).where(User.stripe_customer_id == customer_id)
    )
    user = result.scalar_one_or_none()
    
    if user:
        if subscription["status"] == "active":
            user.subscription_status = SubscriptionStatus.ACTIVE
        elif subscription["status"] == "past_due":
            user.subscription_status = SubscriptionStatus.PAST_DUE
        elif subscription["status"] == "canceled":
            user.subscription_status = SubscriptionStatus.CANCELLED
            user.subscription_tier = SubscriptionTier.FREE
        
        await db.commit()


async def handle_subscription_cancelled(subscription: dict, db: AsyncSession):
    """Handle subscription cancellation"""
    customer_id = subscription["customer"]
    
    result = await db.execute(
        select(User).where(User.stripe_customer_id == customer_id)
    )
    user = result.scalar_one_or_none()
    
    if user:
        user.subscription_tier = SubscriptionTier.FREE
        user.subscription_status = SubscriptionStatus.CANCELLED
        user.stripe_subscription_id = None
        await db.commit()


async def handle_payment_failed(invoice: dict, db: AsyncSession):
    """Handle failed payment"""
    customer_id = invoice["customer"]
    
    result = await db.execute(
        select(User).where(User.stripe_customer_id == customer_id)
    )
    user = result.scalar_one_or_none()
    
    if user:
        user.subscription_status = SubscriptionStatus.PAST_DUE
        await db.commit()
        
        # TODO: Send email notification about failed payment


@router.post("/cancel-subscription")
async def cancel_subscription(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Cancel user's subscription"""
    
    if not current_user.stripe_subscription_id:
        raise HTTPException(status_code=400, detail="No active subscription")
    
    try:
        # Cancel at period end (user keeps access until subscription ends)
        stripe.Subscription.modify(
            current_user.stripe_subscription_id,
            cancel_at_period_end=True
        )
        
        current_user.subscription_status = SubscriptionStatus.CANCELLED
        await db.commit()
        
        return {"message": "Subscription will be cancelled at the end of the billing period"}
        
    except stripe.error.StripeError as e:
        raise HTTPException(status_code=400, detail=str(e))


@router.get("/subscription-status")
async def get_subscription_status(
    current_user: User = Depends(get_current_user),
):
    """Get current subscription status"""
    
    return {
        "tier": current_user.subscription_tier.value,
        "status": current_user.subscription_status.value if current_user.subscription_status else None,
        "ends_at": current_user.subscription_ends_at.isoformat() if current_user.subscription_ends_at else None,
        "limits": {
            "max_products": 3 if current_user.subscription_tier == SubscriptionTier.FREE else 100,
            "crawl_frequency": "daily" if current_user.subscription_tier == SubscriptionTier.FREE else "hourly",
        }
    }
