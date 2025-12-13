import asyncio
from playwright.async_api import async_playwright
import re

async def test():
    p = await async_playwright().start()
    browser = await p.chromium.launch(headless=True)
    context = await browser.new_context(
        viewport={"width": 1920, "height": 1080},
        user_agent="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"
    )
    page = await context.new_page()
    
    # Wait for networkidle
    await page.goto("https://www.amazon.com/dp/B0BSHF7WHW", wait_until="networkidle", timeout=60000)
    await page.wait_for_timeout(3000)
    
    # Check inner text (rendered content)
    body_text = await page.inner_text("body")
    
    # Find dollar amounts in rendered text
    pattern = r'\$[\d,]+\.?\d*'
    matches = re.findall(pattern, body_text)
    print(f"Prices in body text: {matches[:20]}")
    
    # Try to find specific price elements
    price_el = await page.query_selector(".a-price-whole")
    if price_el:
        whole = await price_el.text_content()
        print(f"Price whole: {whole}")
    
    await browser.close()
    await p.stop()

asyncio.run(test())
