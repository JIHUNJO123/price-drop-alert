"""Create test alert"""
import asyncio
from app.database import async_session_maker
from app.models import Alert, Product, User, AlertStatus, AlertType
from sqlalchemy import select
import uuid
from datetime import datetime, timezone

async def create_test_alert():
    async with async_session_maker() as session:
        # Get user
        result = await session.execute(select(User).limit(1))
        user = result.scalar_one_or_none()
        
        # Get product
        result = await session.execute(select(Product).limit(1))
        product = result.scalar_one_or_none()
        
        if user and product:
            from decimal import Decimal
            alert = Alert(
                id=uuid.uuid4(),
                user_id=user.id,
                product_id=product.id,
                alert_type=AlertType.PRICE_DROP,
                old_price=Decimal("85.00"),  # Simulated old price
                new_price=product.current_price,
                title='🎉 Price Drop Alert!',
                message=f'{product.name} dropped to ${product.current_price}! Your target was ${product.target_price}. Go grab it now!',
                status=AlertStatus.PENDING,
                sent_via_push=False,
                sent_via_email=False,
                created_at=datetime.now(timezone.utc)
            )
            session.add(alert)
            await session.commit()
            print(f'✅ Alert created!')
            print(f'Title: {alert.title}')
            print(f'Message: {alert.message}')
        else:
            print('❌ No user or product found')

if __name__ == "__main__":
    asyncio.run(create_test_alert())
