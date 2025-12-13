# Price Drop Alert

🎯 **"Never overpay again."**

미국 온라인 쇼핑몰 가격 추적 & 알림 서비스

## 🚀 Features

- **URL 등록** - 상품 URL만 붙여넣으면 자동으로 상품명, 가격, 이미지 추출
- **가격 추적** - 12시간마다 자동 크롤링으로 가격 변동 감지
- **스마트 알림** - 목표가 도달 or 가격 하락 시 Push/Email 알림
- **가격 히스토리** - 가격 변동 그래프로 구매 타이밍 파악

## 💰 Pricing

| Plan | Price | Features |
|------|-------|----------|
| Free | $0 | 3 products |
| Pro | $4.99/mo | Unlimited products |
| Annual | $39.99/yr | Best value |

## 🛠 Tech Stack

### Backend
- **FastAPI** - Modern Python web framework
- **PostgreSQL** - Database
- **Redis** - Cache & Message queue
- **Celery** - Background task processing
- **Playwright** - Web scraping (JS rendering)

### App (Coming Soon)
- **Flutter** - iOS & Android
- **Firebase** - Push notifications

## 📦 Getting Started

### Prerequisites
- Docker & Docker Compose
- Python 3.11+

### Quick Start

```bash
# 1. Clone repository
cd "가격변동 크롤링 앱"

# 2. Start all services
docker-compose up -d

# 3. API is now running at http://localhost:8000
# - Docs: http://localhost:8000/docs
```

### Local Development

```bash
# 1. Create virtual environment
cd backend
python -m venv venv
source venv/bin/activate  # Windows: venv\Scripts\activate

# 2. Install dependencies
pip install -r requirements.txt

# 3. Install Playwright browsers
playwright install chromium

# 4. Copy environment file
cp .env.example .env
# Edit .env with your settings

# 5. Start PostgreSQL & Redis (via Docker)
docker-compose up -d db redis

# 6. Run API server
uvicorn app.main:app --reload

# 7. Run Celery worker (separate terminal)
celery -A app.celery_app worker --loglevel=info

# 8. Run Celery beat (separate terminal)
celery -A app.celery_app beat --loglevel=info
```

## 📡 API Endpoints

### Authentication
- `POST /api/v1/auth/register` - Create account
- `POST /api/v1/auth/login` - Login
- `GET /api/v1/auth/me` - Get profile

### Products
- `POST /api/v1/products/preview` - Preview product before adding
- `POST /api/v1/products` - Add product to track
- `GET /api/v1/products` - List tracked products
- `GET /api/v1/products/{id}` - Get product details
- `GET /api/v1/products/{id}/history` - Get price history
- `POST /api/v1/products/{id}/refresh` - Refresh price now
- `DELETE /api/v1/products/{id}` - Stop tracking

### Alerts
- `GET /api/v1/alerts` - List alerts
- `POST /api/v1/alerts/{id}/read` - Mark as read
- `POST /api/v1/alerts/read-all` - Mark all as read

### Stats
- `GET /api/v1/stats` - Dashboard statistics

## 🌐 Supported Sites

✅ Currently Supporting:
- Target.com
- BestBuy.com
- Walmart.com
- Nike.com
- Shopify-based stores (thousands of DTC brands)
- Any site with standard product schema

❌ Not Supported (ToS restrictions):
- Amazon (requires PA API)
- Sites requiring login

## 🔒 Legal Compliance

- Only crawls publicly accessible product pages
- Respects robots.txt
- No login bypass
- No cart/checkout page access
- Rate limiting implemented

## 📱 Mobile App (Coming Soon)

Flutter app for iOS & Android with:
- Push notifications
- Home screen widgets
- Apple/Google Pay for subscriptions

## 🚀 Deployment

### Production Checklist
- [ ] Change all secret keys in `.env`
- [ ] Configure SendGrid for email
- [ ] Configure Firebase for push notifications
- [ ] Set up Stripe for payments
- [ ] Configure Sentry for error tracking
- [ ] Use managed PostgreSQL (AWS RDS, etc.)
- [ ] Use managed Redis (AWS ElastiCache, etc.)
- [ ] Set up SSL/TLS
- [ ] Configure proper CORS origins

## 📄 License

MIT License

---

**Never overpay again.** 💰
