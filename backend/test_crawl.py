"""Test crawler on Best Buy"""
import asyncio
from playwright.async_api import async_playwright

async def test():
    p = await async_playwright().start()
    browser = await p.chromium.launch(headless=True)
    context = await browser.new_context(
        user_agent='Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
        viewport={'width': 1920, 'height': 1080},
        locale='en-US',
        timezone_id='America/New_York',
        geolocation={'latitude': 40.7128, 'longitude': -74.0060},
        permissions=['geolocation'],
        extra_http_headers={
            'Accept-Language': 'en-US,en;q=0.9',
        }
    )
    
    # Set US cookies
    await context.add_cookies([
        {'name': 'intl_splash', 'value': 'false', 'domain': '.bestbuy.com', 'path': '/'},
        {'name': 'UID', 'value': 'us', 'domain': '.bestbuy.com', 'path': '/'},
    ])
    
    page = await context.new_page()
    
    # Test with Shopify store (most reliable)
    url = 'https://www.allbirds.com/products/mens-tree-runners'
    
    print(f"Loading: {url}")
    await page.goto(url, timeout=30000)
    await page.wait_for_timeout(5000)
    
    html = await page.content()
    print(f"Page length: {len(html)}")
    
    title = await page.title()
    print(f"Title: {title}")
    
    # Check if blocked
    if 'Access Denied' in html or 'robot' in html.lower() or 'captcha' in html.lower():
        print("WARNING: Page may be blocked!")
    
    # Try various price selectors
    selectors = [
        '.priceView-customer-price span',
        '[data-testid="customer-price"]',
        '.pricing-price__regular-price',
        'div[class*="price"] span',
        '[class*="Price"]',
    ]
    
    for sel in selectors:
        try:
            el = await page.query_selector(sel)
            if el:
                text = await el.text_content()
                print(f"Found {sel}: {text}")
        except Exception as e:
            pass
    
    # Try structured data
    scripts = await page.query_selector_all('script[type="application/ld+json"]')
    print(f"Found {len(scripts)} JSON-LD scripts")
    
    for i, script in enumerate(scripts):
        content = await script.text_content()
        if 'price' in content.lower():
            print(f"Script {i} has price data: {content[:300]}...")
    
    await browser.close()
    await p.stop()

if __name__ == "__main__":
    asyncio.run(test())
