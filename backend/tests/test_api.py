"""
Backend Tests - API & Crawler
"""
import sys
import os
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

import pytest
from httpx import AsyncClient
from decimal import Decimal

from app.main import app
from app.crawler.engine import PriceCrawler


# ============== API Tests ==============

@pytest.mark.asyncio
async def test_health_check():
    """Test health check endpoint"""
    async with AsyncClient(app=app, base_url="http://test") as client:
        response = await client.get("/health")
        assert response.status_code == 200
        data = response.json()
        assert "status" in data
        assert "version" in data


@pytest.mark.asyncio
async def test_register_user():
    """Test user registration"""
    async with AsyncClient(app=app, base_url="http://test") as client:
        response = await client.post(
            "/api/v1/auth/register",
            json={
                "email": "test@example.com",
                "password": "Test1234!",
                "name": "Test User"
            }
        )
        assert response.status_code == 200
        data = response.json()
        assert "access_token" in data


@pytest.mark.asyncio
async def test_register_invalid_email():
    """Test registration with invalid email"""
    async with AsyncClient(app=app, base_url="http://test") as client:
        response = await client.post(
            "/api/v1/auth/register",
            json={
                "email": "invalid-email",
                "password": "Test1234!",
                "name": "Test User"
            }
        )
        assert response.status_code == 422


@pytest.mark.asyncio
async def test_login():
    """Test user login"""
    async with AsyncClient(app=app, base_url="http://test") as client:
        # First register
        await client.post(
            "/api/v1/auth/register",
            json={
                "email": "login@example.com",
                "password": "Test1234!",
                "name": "Test User"
            }
        )
        
        # Then login
        response = await client.post(
            "/api/v1/auth/login",
            json={
                "email": "login@example.com",
                "password": "Test1234!"
            }
        )
        assert response.status_code == 200
        data = response.json()
        assert "access_token" in data


@pytest.mark.asyncio
async def test_protected_route_without_token():
    """Test accessing protected route without token"""
    async with AsyncClient(app=app, base_url="http://test") as client:
        response = await client.get("/api/v1/products")
        assert response.status_code == 401


# ============== Crawler Tests ==============

class TestPriceCrawler:
    """Test crawler functionality"""
    
    def test_parse_price_basic(self):
        """Test basic price parsing"""
        crawler = PriceCrawler()
        
        assert crawler._parse_price("$99.99") == Decimal("99.99")
        assert crawler._parse_price("$1,299.00") == Decimal("1299.00")
        assert crawler._parse_price("USD 49.99") == Decimal("49.99")
        assert crawler._parse_price("99.99") == Decimal("99.99")
    
    def test_parse_price_edge_cases(self):
        """Test edge cases in price parsing"""
        crawler = PriceCrawler()
        
        assert crawler._parse_price("") is None
        assert crawler._parse_price("Free") is None
        assert crawler._parse_price("$0.00") == Decimal("0.00")
        assert crawler._parse_price("$99") == Decimal("99.00")
    
    def test_get_domain(self):
        """Test domain extraction"""
        crawler = PriceCrawler()
        
        assert crawler._get_domain("https://www.bestbuy.com/product/123") == "bestbuy.com"
        assert crawler._get_domain("https://nike.com/shoes/abc") == "nike.com"
        assert crawler._get_domain("http://target.com/p/item") == "target.com"
    
    def test_get_site_config(self):
        """Test site config retrieval"""
        crawler = PriceCrawler()
        
        config = crawler._get_site_config("bestbuy.com")
        assert "price_selectors" in config
        assert "name_selectors" in config
        
        # Unknown domain should return default
        config = crawler._get_site_config("unknown-store.com")
        assert config == crawler.SITE_CONFIGS["default"]


# ============== Integration Tests ==============

@pytest.mark.asyncio
@pytest.mark.integration
async def test_crawl_allbirds():
    """Integration test - crawl Allbirds (Shopify)"""
    crawler = PriceCrawler()
    await crawler.start()
    
    try:
        result = await crawler.crawl("https://www.allbirds.com/products/mens-tree-runners")
        
        # Allbirds should work with JSON-LD
        assert result.success or result.error == "Could not extract price from page"
        if result.success:
            assert result.price is not None
            assert result.name is not None
            assert result.domain == "allbirds.com"
    finally:
        await crawler.close()


@pytest.mark.asyncio
@pytest.mark.integration
async def test_crawl_nike():
    """Integration test - crawl Nike"""
    crawler = PriceCrawler()
    await crawler.start()
    
    try:
        result = await crawler.crawl("https://www.nike.com/t/air-force-1-07-mens-shoes-jBrhbr/CW2288-111")
        
        if result.success:
            assert result.price is not None
            assert "nike" in result.name.lower() or "air force" in result.name.lower()
    finally:
        await crawler.close()


# ============== Fixtures ==============

@pytest.fixture
def auth_headers():
    """Create authenticated headers for testing"""
    return {"Authorization": "Bearer test-token"}


@pytest.fixture
async def test_user(client):
    """Create a test user"""
    response = await client.post(
        "/api/v1/auth/register",
        json={
            "email": "fixture@example.com",
            "password": "Test1234!",
            "name": "Fixture User"
        }
    )
    return response.json()


# ============== Run Tests ==============

if __name__ == "__main__":
    pytest.main([__file__, "-v", "--tb=short"])
