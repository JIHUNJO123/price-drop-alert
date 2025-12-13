import asyncio
from playwright.async_api import async_playwright

async def test():
    p = await async_playwright().start()
    browser = await p.chromium.launch(
        headless=True,
        args=[
            "--disable-blink-features=AutomationControlled",
            "--disable-dev-shm-usage",
            "--no-sandbox",
            "--disable-web-security",
            "--window-size=1920,1080",
        ]
    )
    context = await browser.new_context(
        viewport={"width": 1920, "height": 1080},
        user_agent='Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/121.0.0.0 Safari/537.36',
        locale='en-US',
        extra_http_headers={
            "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,*/*;q=0.8",
            "Accept-Language": "en-US,en;q=0.9",
            "Sec-Ch-Ua": '"Not A(Brand";v="99", "Google Chrome";v="121", "Chromium";v="121"',
            "Sec-Ch-Ua-Mobile": "?0",
            "Sec-Ch-Ua-Platform": '"Windows"',
        }
    )
    
    # Stealth mode
    await context.add_init_script("""
        Object.defineProperty(navigator, 'webdriver', { get: () => undefined });
        Object.defineProperty(navigator, 'plugins', { get: () => [1, 2, 3, 4, 5] });
        window.chrome = { runtime: {} };
    """)
    
    page = await context.new_page()
    
    print("Loading page...")
    await page.goto('https://www.walmart.com/ip/Apple-AirPods-4-with-Active-Noise-Cancellation/11384707978', wait_until='networkidle', timeout=60000)
    await page.wait_for_timeout(5000)
    
    # Get page title
    title = await page.title()
    print(f'Title: {title}')
    
    # Try various selectors
    selectors = [
        '[itemprop="price"]',
        '[data-testid="price-wrap"]',
        'span.inline-flex',
        '[data-automation="buybox-price"]',
        '.price-characteristic',
        'span[aria-hidden="true"]',
        '.f1',
        '.f2',
        'span.w_iUH7',
    ]
    
    print("\nTrying selectors:")
    for sel in selectors:
        try:
            els = await page.query_selector_all(sel)
            if els:
                for el in els[:3]:
                    txt = await el.text_content()
                    if txt and ('$' in txt or any(c.isdigit() for c in (txt or ''))):
                        print(f'{sel}: {txt[:100]}')
        except Exception as e:
            print(f'{sel}: Error - {e}')
    
    # Try to find any price-like text
    print("\nSearching for price patterns...")
    content = await page.content()
    import re
    prices = re.findall(r'\$[\d,]+\.?\d*', content)
    if prices:
        print(f"Found prices: {prices[:10]}")
    
    # Get structured data
    print("\nLooking for JSON-LD:")
    scripts = await page.query_selector_all('script[type="application/ld+json"]')
    for script in scripts[:2]:
        txt = await script.text_content()
        if 'price' in txt.lower():
            print(f"Found price in JSON-LD: {txt[:500]}")
    
    await browser.close()
    await p.stop()

if __name__ == "__main__":
    asyncio.run(test())
