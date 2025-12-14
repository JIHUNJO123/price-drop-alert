"""
Price Crawler Engine
Playwright-based web scraping for global e-commerce sites
"""
import re
import asyncio
from decimal import Decimal
from typing import Optional, Dict, Any, List
from dataclasses import dataclass
from urllib.parse import urlparse

from playwright.async_api import async_playwright, Page, Browser, TimeoutError as PlaywrightTimeout
from bs4 import BeautifulSoup
import structlog

from app.config import settings

logger = structlog.get_logger()


@dataclass
class CrawlResult:
    """Result from crawling a product page"""
    success: bool
    url: str
    name: Optional[str] = None
    price: Optional[Decimal] = None
    original_price: Optional[Decimal] = None
    currency: str = "USD"
    image_url: Optional[str] = None
    is_available: bool = True
    error: Optional[str] = None
    domain: Optional[str] = None


class PriceCrawler:
    """
    Playwright-based crawler for extracting product prices from global e-commerce sites
    """
    
    # Currency mapping for different Amazon domains
    AMAZON_CURRENCY_MAP: Dict[str, str] = {
        "amazon.com": "USD",
        "amazon.co.uk": "GBP",
        "amazon.de": "EUR",
        "amazon.fr": "EUR",
        "amazon.es": "EUR",
        "amazon.it": "EUR",
        "amazon.co.jp": "JPY",
        "amazon.ca": "CAD",
        "amazon.com.au": "AUD",
        "amazon.com.br": "BRL",
        "amazon.com.mx": "MXN",
        "amazon.nl": "EUR",
        "amazon.pl": "PLN",
        "amazon.se": "SEK",
        "amazon.sg": "SGD",
        "amazon.ae": "AED",
        "amazon.sa": "SAR",
        "amazon.in": "INR",
    }
    
    # Amazon global domains (all share similar HTML structure)
    AMAZON_DOMAINS: List[str] = [
        "amazon.com", "amazon.co.uk", "amazon.de", "amazon.fr", "amazon.es",
        "amazon.it", "amazon.co.jp", "amazon.ca", "amazon.com.au", "amazon.com.br",
        "amazon.com.mx", "amazon.nl", "amazon.pl", "amazon.se", "amazon.sg",
        "amazon.ae", "amazon.sa", "amazon.in",
    ]
    
    # Site-specific selectors for common stores
    SITE_CONFIGS: Dict[str, Dict[str, Any]] = {
        # Shopify-based stores (common pattern)
        "shopify": {
            "price_selectors": [
                ".price__current .money",
                ".product__price .money",
                ".price-item--regular",
                "[data-product-price]",
                ".product-single__price",
            ],
            "name_selectors": [
                ".product__title h1",
                ".product-single__title",
                "h1.product-title",
                "[data-product-title]",
            ],
            "image_selectors": [
                ".product__media img",
                ".product-single__photo img",
                "[data-product-image]",
            ],
        },
        
        # Target
        "target.com": {
            "price_selectors": [
                "[data-test='product-price']",
                ".styles__CurrentPriceFontSize-sc",
                "span[data-test='product-price']",
            ],
            "name_selectors": [
                "[data-test='product-title']",
                "h1[data-test='product-title']",
            ],
            "image_selectors": [
                "[data-test='product-image'] img",
            ],
        },
        
        # Best Buy
        "bestbuy.com": {
            "price_selectors": [
                ".priceView-customer-price span",
                "[data-testid='customer-price'] span",
                ".pricing-price__regular-price",
            ],
            "name_selectors": [
                ".sku-title h1",
                "[data-testid='heading-product-title']",
            ],
            "image_selectors": [
                ".primary-image img",
                "[data-testid='product-image'] img",
            ],
        },
        
        # Walmart
        "walmart.com": {
            "price_selectors": [
                "[data-testid='price-wrap'] span.inline-flex span",
                "[itemprop='price']",
                "[data-testid='price-wrap'] span",
                ".price-characteristic",
                "span[data-automation='buybox-price']",
                "[data-testid='add-to-cart-section'] span.inline-flex",
                ".sans-serif span.inline-flex",
            ],
            "name_selectors": [
                "h1[itemprop='name']",
                "[data-testid='product-title']",
                "h1.dark-gray",
                "h1.f3",
            ],
            "image_selectors": [
                "[data-testid='hero-image-container'] img",
                "[data-testid='hero-image'] img",
                "img.db.w-100",
            ],
            "wait_time": 5000,  # Walmart needs more time to load
        },
        
        # Nike
        "nike.com": {
            "price_selectors": [
                "[data-test='product-price']",
                ".product-price",
                "[data-testid='currentPrice-container']",
            ],
            "name_selectors": [
                "[data-test='product-title']",
                "h1#pdp_product_title",
            ],
            "image_selectors": [
                "[data-testid='HeroImg'] img",
            ],
        },
        
        # Amazon (requires special handling due to bot protection)
        "amazon.com": {
            "price_selectors": [
                "#corePriceDisplay_desktop_feature_div .a-price .a-offscreen",
                "#corePrice_feature_div .a-price .a-offscreen",
                ".a-price[data-a-size='xl'] .a-offscreen",
                ".a-price[data-a-size='l'] .a-offscreen",
                ".a-price[data-a-size='b'] .a-offscreen",
                "span.a-price span.a-offscreen",
                ".a-price .a-offscreen",
                "#priceblock_ourprice",
                "#priceblock_dealprice",
                "#priceblock_saleprice",
                ".apexPriceToPay span.a-offscreen",
                ".priceToPay span.a-offscreen",
                "#price_inside_buybox",
                "#newBuyBoxPrice",
            ],
            "name_selectors": [
                "#productTitle",
                "#title span",
                "h1#title span",
            ],
            "image_selectors": [
                "#landingImage",
                "#imgBlkFront",
                "#main-image",
                "#imgTagWrapperId img",
            ],
            "wait_time": 5000,
        },
        
        # Amazon UK
        "amazon.co.uk": {
            "price_selectors": [
                "#corePriceDisplay_desktop_feature_div .a-price .a-offscreen",
                "#corePrice_feature_div .a-price .a-offscreen",
                ".a-price[data-a-size='xl'] .a-offscreen",
                ".a-price[data-a-size='l'] .a-offscreen",
                ".a-price[data-a-size='b'] .a-offscreen",
                "span.a-price span.a-offscreen",
                ".a-price .a-offscreen",
                "#priceblock_ourprice",
                "#priceblock_dealprice",
                ".apexPriceToPay span.a-offscreen",
                ".priceToPay span.a-offscreen",
            ],
            "name_selectors": [
                "#productTitle",
                "#title span",
            ],
            "image_selectors": [
                "#landingImage",
                "#imgBlkFront",
                "#imgTagWrapperId img",
            ],
            "wait_time": 5000,
            "currency": "GBP",
        },
        
        # Amazon Germany
        "amazon.de": {
            "price_selectors": [
                "#corePriceDisplay_desktop_feature_div .a-price .a-offscreen",
                "#corePrice_feature_div .a-price .a-offscreen",
                ".a-price[data-a-size='xl'] .a-offscreen",
                ".a-price[data-a-size='l'] .a-offscreen",
                ".a-price[data-a-size='b'] .a-offscreen",
                "span.a-price span.a-offscreen",
                ".a-price .a-offscreen",
                "#priceblock_ourprice",
                "#priceblock_dealprice",
                ".apexPriceToPay span.a-offscreen",
                ".priceToPay span.a-offscreen",
            ],
            "name_selectors": [
                "#productTitle",
                "#title span",
            ],
            "image_selectors": [
                "#landingImage",
                "#imgBlkFront",
                "#imgTagWrapperId img",
            ],
            "wait_time": 5000,
            "currency": "EUR",
        },
        
        # Amazon France
        "amazon.fr": {
            "price_selectors": [
                "#corePriceDisplay_desktop_feature_div .a-price .a-offscreen",
                "#corePrice_feature_div .a-price .a-offscreen",
                ".a-price[data-a-size='xl'] .a-offscreen",
                ".a-price[data-a-size='l'] .a-offscreen",
                ".a-price[data-a-size='b'] .a-offscreen",
                "span.a-price span.a-offscreen",
                ".a-price .a-offscreen",
                "#priceblock_ourprice",
                "#priceblock_dealprice",
                ".apexPriceToPay span.a-offscreen",
                ".priceToPay span.a-offscreen",
            ],
            "name_selectors": [
                "#productTitle",
                "#title span",
            ],
            "image_selectors": [
                "#landingImage",
                "#imgBlkFront",
                "#imgTagWrapperId img",
            ],
            "wait_time": 5000,
            "currency": "EUR",
        },
        
        # Amazon Spain
        "amazon.es": {
            "price_selectors": [
                "#corePriceDisplay_desktop_feature_div .a-price .a-offscreen",
                "#corePrice_feature_div .a-price .a-offscreen",
                ".a-price[data-a-size='xl'] .a-offscreen",
                ".a-price[data-a-size='l'] .a-offscreen",
                ".a-price[data-a-size='b'] .a-offscreen",
                "span.a-price span.a-offscreen",
                ".a-price .a-offscreen",
                "#priceblock_ourprice",
                "#priceblock_dealprice",
                ".apexPriceToPay span.a-offscreen",
                ".priceToPay span.a-offscreen",
            ],
            "name_selectors": [
                "#productTitle",
                "#title span",
            ],
            "image_selectors": [
                "#landingImage",
                "#imgBlkFront",
                "#imgTagWrapperId img",
            ],
            "wait_time": 5000,
            "currency": "EUR",
        },
        
        # Amazon Italy
        "amazon.it": {
            "price_selectors": [
                "#corePriceDisplay_desktop_feature_div .a-price .a-offscreen",
                "#corePrice_feature_div .a-price .a-offscreen",
                ".a-price[data-a-size='xl'] .a-offscreen",
                ".a-price[data-a-size='l'] .a-offscreen",
                ".a-price[data-a-size='b'] .a-offscreen",
                "span.a-price span.a-offscreen",
                ".a-price .a-offscreen",
                "#priceblock_ourprice",
                "#priceblock_dealprice",
                ".apexPriceToPay span.a-offscreen",
                ".priceToPay span.a-offscreen",
            ],
            "name_selectors": [
                "#productTitle",
                "#title span",
            ],
            "image_selectors": [
                "#landingImage",
                "#imgBlkFront",
                "#imgTagWrapperId img",
            ],
            "wait_time": 5000,
            "currency": "EUR",
        },
        
        # Amazon Japan
        "amazon.co.jp": {
            "price_selectors": [
                "#corePriceDisplay_desktop_feature_div .a-price .a-offscreen",
                "#corePrice_feature_div .a-price .a-offscreen",
                ".a-price[data-a-size='xl'] .a-offscreen",
                ".a-price[data-a-size='l'] .a-offscreen",
                ".a-price[data-a-size='b'] .a-offscreen",
                "span.a-price span.a-offscreen",
                ".a-price .a-offscreen",
                "#priceblock_ourprice",
                "#priceblock_dealprice",
                ".apexPriceToPay span.a-offscreen",
                ".priceToPay span.a-offscreen",
            ],
            "name_selectors": [
                "#productTitle",
                "#title span",
            ],
            "image_selectors": [
                "#landingImage",
                "#imgBlkFront",
                "#imgTagWrapperId img",
            ],
            "wait_time": 5000,
            "currency": "JPY",
        },
        
        # Amazon Canada
        "amazon.ca": {
            "price_selectors": [
                "#corePriceDisplay_desktop_feature_div .a-price .a-offscreen",
                "#corePrice_feature_div .a-price .a-offscreen",
                ".a-price[data-a-size='xl'] .a-offscreen",
                ".a-price[data-a-size='l'] .a-offscreen",
                ".a-price[data-a-size='b'] .a-offscreen",
                "span.a-price span.a-offscreen",
                ".a-price .a-offscreen",
                "#priceblock_ourprice",
                "#priceblock_dealprice",
                ".apexPriceToPay span.a-offscreen",
                ".priceToPay span.a-offscreen",
            ],
            "name_selectors": [
                "#productTitle",
                "#title span",
            ],
            "image_selectors": [
                "#landingImage",
                "#imgBlkFront",
                "#imgTagWrapperId img",
            ],
            "wait_time": 5000,
            "currency": "CAD",
        },
        
        # Amazon Australia
        "amazon.com.au": {
            "price_selectors": [
                "#corePriceDisplay_desktop_feature_div .a-price .a-offscreen",
                "#corePrice_feature_div .a-price .a-offscreen",
                ".a-price[data-a-size='xl'] .a-offscreen",
                ".a-price[data-a-size='l'] .a-offscreen",
                ".a-price[data-a-size='b'] .a-offscreen",
                "span.a-price span.a-offscreen",
                ".a-price .a-offscreen",
                "#priceblock_ourprice",
                "#priceblock_dealprice",
                ".apexPriceToPay span.a-offscreen",
                ".priceToPay span.a-offscreen",
            ],
            "name_selectors": [
                "#productTitle",
                "#title span",
            ],
            "image_selectors": [
                "#landingImage",
                "#imgBlkFront",
                "#imgTagWrapperId img",
            ],
            "wait_time": 5000,
            "currency": "AUD",
        },
        
        # Amazon Brazil
        "amazon.com.br": {
            "price_selectors": [
                "#corePriceDisplay_desktop_feature_div .a-price .a-offscreen",
                "#corePrice_feature_div .a-price .a-offscreen",
                ".a-price[data-a-size='xl'] .a-offscreen",
                ".a-price[data-a-size='l'] .a-offscreen",
                ".a-price[data-a-size='b'] .a-offscreen",
                "span.a-price span.a-offscreen",
                ".a-price .a-offscreen",
                "#priceblock_ourprice",
                "#priceblock_dealprice",
                ".apexPriceToPay span.a-offscreen",
                ".priceToPay span.a-offscreen",
            ],
            "name_selectors": [
                "#productTitle",
                "#title span",
            ],
            "image_selectors": [
                "#landingImage",
                "#imgBlkFront",
                "#imgTagWrapperId img",
            ],
            "wait_time": 5000,
            "currency": "BRL",
        },
        
        # Amazon Mexico
        "amazon.com.mx": {
            "price_selectors": [
                "#corePriceDisplay_desktop_feature_div .a-price .a-offscreen",
                "#corePrice_feature_div .a-price .a-offscreen",
                ".a-price[data-a-size='xl'] .a-offscreen",
                ".a-price[data-a-size='l'] .a-offscreen",
                ".a-price[data-a-size='b'] .a-offscreen",
                "span.a-price span.a-offscreen",
                ".a-price .a-offscreen",
                "#priceblock_ourprice",
                "#priceblock_dealprice",
                ".apexPriceToPay span.a-offscreen",
                ".priceToPay span.a-offscreen",
            ],
            "name_selectors": [
                "#productTitle",
                "#title span",
            ],
            "image_selectors": [
                "#landingImage",
                "#imgBlkFront",
                "#imgTagWrapperId img",
            ],
            "wait_time": 5000,
            "currency": "MXN",
        },
        
        # Amazon India
        "amazon.in": {
            "price_selectors": [
                "#corePriceDisplay_desktop_feature_div .a-price .a-offscreen",
                "#corePrice_feature_div .a-price .a-offscreen",
                ".a-price[data-a-size='xl'] .a-offscreen",
                ".a-price[data-a-size='l'] .a-offscreen",
                ".a-price[data-a-size='b'] .a-offscreen",
                "span.a-price span.a-offscreen",
                ".a-price .a-offscreen",
                "#priceblock_ourprice",
                "#priceblock_dealprice",
                ".apexPriceToPay span.a-offscreen",
                ".priceToPay span.a-offscreen",
            ],
            "name_selectors": [
                "#productTitle",
                "#title span",
            ],
            "image_selectors": [
                "#landingImage",
                "#imgBlkFront",
                "#imgTagWrapperId img",
            ],
            "wait_time": 5000,
            "currency": "INR",
        },
        
        # Home Depot
        "homedepot.com": {
            "price_selectors": [
                ".price-format__main-price",
                "[data-testid='price-format']",
                ".price__dollars",
            ],
            "name_selectors": [
                ".product-title__title",
                "h1.product-title",
            ],
            "image_selectors": [
                ".mediagallery__mainimage img",
            ],
        },
        
        # Costco
        "costco.com": {
            "price_selectors": [
                ".price",
                "#pull-right-price span",
                ".your-price span",
            ],
            "name_selectors": [
                "h1[itemprop='name']",
                ".product-title",
            ],
            "image_selectors": [
                "#RICHFXViewerContainer img",
                ".product-img-main img",
            ],
        },
        
        # Macy's
        "macys.com": {
            "price_selectors": [
                "[data-auto='product-price']",
                ".price .lowest-sale-price",
                ".c-product-price__value",
            ],
            "name_selectors": [
                "[data-auto='product-name']",
                ".product-name h1",
            ],
            "image_selectors": [
                ".c-product-image img",
            ],
        },
        
        # Nordstrom
        "nordstrom.com": {
            "price_selectors": [
                "[data-test='product-price']",
                ".price-label__price",
            ],
            "name_selectors": [
                "[data-test='product-title']",
                "h1.product-title",
            ],
            "image_selectors": [
                "[data-test='product-image'] img",
            ],
        },
        
        # Adidas
        "adidas.com": {
            "price_selectors": [
                "[data-testid='product-price']",
                ".gl-price-item",
                ".product-price",
            ],
            "name_selectors": [
                "[data-testid='product-title']",
                "h1.product-title",
            ],
            "image_selectors": [
                "[data-testid='product-image'] img",
            ],
        },
        
        # Sephora
        "sephora.com": {
            "price_selectors": [
                "[data-at='price']",
                ".css-0 span",
            ],
            "name_selectors": [
                "[data-at='product_name']",
                "h1 span",
            ],
            "image_selectors": [
                "[data-at='product_image'] img",
            ],
        },
        
        # Ulta
        "ulta.com": {
            "price_selectors": [
                ".ProductPricing__price",
                "[data-test='product-price']",
            ],
            "name_selectors": [
                ".ProductMainSection__productName",
                "h1[data-test='product-title']",
            ],
            "image_selectors": [
                ".ProductHero__image img",
            ],
        },
        
        # eBay
        "ebay.com": {
            "price_selectors": [
                ".x-price-primary span",
                "[data-testid='x-price-primary']",
                ".x-bin-price__content span",
                "#prcIsum",
            ],
            "name_selectors": [
                ".x-item-title__mainTitle span",
                "h1.x-item-title__mainTitle",
                "#itemTitle",
            ],
            "image_selectors": [
                ".ux-image-carousel-item img",
                "#icImg",
            ],
        },
        
        # Newegg
        "newegg.com": {
            "price_selectors": [
                ".price-current",
                "[data-price]",
                ".price-was-data",
            ],
            "name_selectors": [
                ".product-title",
                "h1.product-title",
            ],
            "image_selectors": [
                ".product-view-img-original",
                ".swiper-slide img",
            ],
        },
        
        # B&H Photo
        "bhphotovideo.com": {
            "price_selectors": [
                "[data-selenium='pricingPrice']",
                ".price_1DPoGOkMdRii4aKWlzHsx9",
            ],
            "name_selectors": [
                "[data-selenium='productTitle']",
                "h1[data-selenium='productTitle']",
            ],
            "image_selectors": [
                "[data-selenium='mainImage'] img",
            ],
        },
        
        # Apple Store
        "apple.com": {
            "price_selectors": [
                ".rc-prices-currentprice",
                "[data-autom='full-price']",
                ".as-price-currentprice",
            ],
            "name_selectors": [
                ".rf-pdp-title",
                "h1.rf-pdp-title",
                "[data-autom='product-title']",
            ],
            "image_selectors": [
                ".rf-pdp-hero-gallery img",
                ".as-productinfosection-mainimage img",
            ],
        },
        
        # Samsung
        "samsung.com": {
            "price_selectors": [
                ".price-info__price",
                "[data-testid='product-price']",
                ".pd-price__price",
            ],
            "name_selectors": [
                ".product-info__title",
                "h1.product-info__title",
            ],
            "image_selectors": [
                ".slick-slide img",
                ".product-info__image img",
            ],
        },
        
        # REI
        "rei.com": {
            "price_selectors": [
                "#buy-box-product-price",
                "[data-ui='buybox-price']",
                ".price-value",
            ],
            "name_selectors": [
                "#product-page-title",
                "h1#product-page-title",
            ],
            "image_selectors": [
                ".product-image__image img",
            ],
        },
        
        # Zappos
        "zappos.com": {
            "price_selectors": [
                "[data-track-value='product-price']",
                ".price",
                "[itemprop='price']",
            ],
            "name_selectors": [
                "[data-track-value='product-name']",
                "h1[itemprop='name']",
            ],
            "image_selectors": [
                "[data-track-value='product-image'] img",
            ],
        },
        
        # Wayfair
        "wayfair.com": {
            "price_selectors": [
                "[data-cypress-id='PriceBlock']",
                ".BasePriceBlock",
                "[data-enzyme-id='PriceBlock']",
            ],
            "name_selectors": [
                "[data-cypress-id='ProductDetailTitle']",
                "h1.ProductDetailInfoBlock-header",
            ],
            "image_selectors": [
                ".ProductDetailImageCarousel img",
            ],
        },
        
        # Lowe's
        "lowes.com": {
            "price_selectors": [
                "[data-selector='product-price']",
                ".main-price",
                ".acsPrice",
            ],
            "name_selectors": [
                "h1.main-header",
                "[data-selector='product-title']",
            ],
            "image_selectors": [
                ".met-product-image img",
            ],
        },
        
        # Gap
        "gap.com": {
            "price_selectors": [
                ".product-price__highlight",
                ".product-price span",
            ],
            "name_selectors": [
                ".product-title",
                "h1.product-title",
            ],
            "image_selectors": [
                ".product-image img",
            ],
        },
        
        # Old Navy
        "oldnavy.com": {
            "price_selectors": [
                ".product-price__highlight",
                ".product-price span",
            ],
            "name_selectors": [
                ".product-title",
                "h1.product-title",
            ],
            "image_selectors": [
                ".product-image img",
            ],
        },
        
        # Banana Republic
        "bananarepublic.com": {
            "price_selectors": [
                ".product-price__highlight",
                ".product-price span",
            ],
            "name_selectors": [
                ".product-title",
                "h1.product-title",
            ],
            "image_selectors": [
                ".product-image img",
            ],
        },
        
        # H&M
        "hm.com": {
            "price_selectors": [
                ".ProductPrice-module--productItemPrice__",
                "[data-testid='product-price']",
                ".price-value",
            ],
            "name_selectors": [
                ".ProductName-module--productName__",
                "h1.ProductName",
            ],
            "image_selectors": [
                ".product-detail-main-image img",
            ],
        },
        
        # Zara
        "zara.com": {
            "price_selectors": [
                ".price__amount-current",
                ".money-amount__main",
                "[data-qa-qualifier='price-amount-current']",
            ],
            "name_selectors": [
                ".product-detail-info__name",
                "h1.product-detail-info__header-name",
            ],
            "image_selectors": [
                ".media-image__image img",
            ],
        },
        
        # Uniqlo
        "uniqlo.com": {
            "price_selectors": [
                ".price-sales",
                "[data-test='product-price']",
            ],
            "name_selectors": [
                ".productName",
                "h1.productName",
            ],
            "image_selectors": [
                ".pdp-product-image img",
            ],
        },
        
        # Lululemon
        "lululemon.com": {
            "price_selectors": [
                "[data-lulu-id='price']",
                ".price-1SDQy",
            ],
            "name_selectors": [
                ".pdp-title",
                "h1.pdp-title",
            ],
            "image_selectors": [
                ".image-interactive-image img",
            ],
        },
        
        # Under Armour
        "underarmour.com": {
            "price_selectors": [
                "[data-testid='price']",
                ".price",
            ],
            "name_selectors": [
                "[data-testid='product-title']",
                "h1.product-title",
            ],
            "image_selectors": [
                ".product-image img",
            ],
        },
        
        # New Balance
        "newbalance.com": {
            "price_selectors": [
                ".product-price",
                "[data-auto-id='product-price']",
            ],
            "name_selectors": [
                ".product-name",
                "h1.product-name",
            ],
            "image_selectors": [
                ".product-image img",
            ],
        },
        
        # Puma
        "puma.com": {
            "price_selectors": [
                "[data-test-id='product-price']",
                ".product-price",
            ],
            "name_selectors": [
                "[data-test-id='product-name']",
                "h1.product-name",
            ],
            "image_selectors": [
                ".product-image img",
            ],
        },
        
        # Reebok
        "reebok.com": {
            "price_selectors": [
                "[data-auto-id='gl-price-item']",
                ".gl-price-item",
            ],
            "name_selectors": [
                "[data-auto-id='product-title']",
                "h1.product-title",
            ],
            "image_selectors": [
                ".product-image img",
            ],
        },
        
        # Foot Locker
        "footlocker.com": {
            "price_selectors": [
                ".ProductPrice",
                "[data-auto-id='product-price']",
            ],
            "name_selectors": [
                ".ProductName",
                "h1.ProductName",
            ],
            "image_selectors": [
                ".ProductImage img",
            ],
        },
        
        # Finish Line
        "finishline.com": {
            "price_selectors": [
                ".productPrice",
                "[data-talos='price']",
            ],
            "name_selectors": [
                ".productName",
                "h1.productName",
            ],
            "image_selectors": [
                ".productImage img",
            ],
        },
        
        # Dick's Sporting Goods
        "dickssportinggoods.com": {
            "price_selectors": [
                "[data-testid='product-price']",
                ".product-price",
            ],
            "name_selectors": [
                "[data-testid='product-title']",
                "h1.product-title",
            ],
            "image_selectors": [
                ".product-image img",
            ],
        },
        
        # Academy Sports
        "academy.com": {
            "price_selectors": [
                ".product-price",
                "[data-test='product-price']",
            ],
            "name_selectors": [
                ".product-title",
                "h1.product-title",
            ],
            "image_selectors": [
                ".product-image img",
            ],
        },
        
        # Bass Pro Shops
        "basspro.com": {
            "price_selectors": [
                ".product-price",
                "[itemprop='price']",
            ],
            "name_selectors": [
                ".product-title",
                "h1[itemprop='name']",
            ],
            "image_selectors": [
                ".product-image img",
            ],
        },
        
        # Cabela's
        "cabelas.com": {
            "price_selectors": [
                ".product-price",
                "[itemprop='price']",
            ],
            "name_selectors": [
                ".product-title",
                "h1[itemprop='name']",
            ],
            "image_selectors": [
                ".product-image img",
            ],
        },
        
        # GameStop
        "gamestop.com": {
            "price_selectors": [
                ".primary-price",
                "[data-testid='price']",
            ],
            "name_selectors": [
                ".product-name",
                "h1.product-name",
            ],
            "image_selectors": [
                ".product-image img",
            ],
        },
        
        # Office Depot
        "officedepot.com": {
            "price_selectors": [
                ".price_column",
                "[data-testid='price']",
            ],
            "name_selectors": [
                ".product_title",
                "h1.product_title",
            ],
            "image_selectors": [
                ".od_mainImg img",
            ],
        },
        
        # Staples
        "staples.com": {
            "price_selectors": [
                ".price-info__final_price",
                "[data-product-price]",
            ],
            "name_selectors": [
                ".product-title",
                "h1.product-title",
            ],
            "image_selectors": [
                ".product-image img",
            ],
        },
        
        # Michaels
        "michaels.com": {
            "price_selectors": [
                ".price-sales",
                "[data-testid='product-price']",
            ],
            "name_selectors": [
                ".product-name",
                "h1.product-name",
            ],
            "image_selectors": [
                ".product-primary-image img",
            ],
        },
        
        # JoAnn
        "joann.com": {
            "price_selectors": [
                ".product-sales-price",
                "[data-testid='product-price']",
            ],
            "name_selectors": [
                ".product-name",
                "h1.product-name",
            ],
            "image_selectors": [
                ".product-primary-image img",
            ],
        },
        
        # Hobby Lobby
        "hobbylobby.com": {
            "price_selectors": [
                ".product-price",
                "[itemprop='price']",
            ],
            "name_selectors": [
                ".product-name",
                "h1[itemprop='name']",
            ],
            "image_selectors": [
                ".product-image img",
            ],
        },
        
        # Petco
        "petco.com": {
            "price_selectors": [
                "[data-testid='price']",
                ".product-price",
            ],
            "name_selectors": [
                "[data-testid='product-name']",
                "h1.product-name",
            ],
            "image_selectors": [
                ".product-image img",
            ],
        },
        
        # PetSmart
        "petsmart.com": {
            "price_selectors": [
                ".product-price",
                "[data-testid='product-price']",
            ],
            "name_selectors": [
                ".product-name",
                "h1.product-name",
            ],
            "image_selectors": [
                ".product-image img",
            ],
        },
        
        # Chewy
        "chewy.com": {
            "price_selectors": [
                "[data-testid='price']",
                ".price",
            ],
            "name_selectors": [
                "[data-testid='product-title']",
                "h1.product-title",
            ],
            "image_selectors": [
                ".product-image img",
            ],
        },
        
        # CVS
        "cvs.com": {
            "price_selectors": [
                ".price-field",
                "[data-testid='price']",
            ],
            "name_selectors": [
                ".product-name",
                "h1.product-name",
            ],
            "image_selectors": [
                ".product-image img",
            ],
        },
        
        # Walgreens
        "walgreens.com": {
            "price_selectors": [
                "#regular-price-wag-hn-lt-bold",
                "[data-testid='product-price']",
            ],
            "name_selectors": [
                "#productTitle",
                "h1#productTitle",
            ],
            "image_selectors": [
                ".product-image img",
            ],
        },
        
        # Williams Sonoma
        "williams-sonoma.com": {
            "price_selectors": [
                ".product-price",
                "[data-testid='product-price']",
            ],
            "name_selectors": [
                ".product-name",
                "h1.product-name",
            ],
            "image_selectors": [
                ".product-image img",
            ],
        },
        
        # Pottery Barn
        "potterybarn.com": {
            "price_selectors": [
                ".product-price",
                "[data-testid='product-price']",
            ],
            "name_selectors": [
                ".product-name",
                "h1.product-name",
            ],
            "image_selectors": [
                ".product-image img",
            ],
        },
        
        # Crate & Barrel
        "crateandbarrel.com": {
            "price_selectors": [
                ".price-state",
                "[data-testid='product-price']",
            ],
            "name_selectors": [
                ".product-name",
                "h1.product-name",
            ],
            "image_selectors": [
                ".product-image img",
            ],
        },
        
        # IKEA
        "ikea.com": {
            "price_selectors": [
                ".pip-temp-price__integer",
                "[data-testid='price']",
                ".pip-price__integer",
            ],
            "name_selectors": [
                ".pip-header-section__title--big",
                "h1.pip-header-section__title",
            ],
            "image_selectors": [
                ".pip-product__image img",
            ],
        },
        
        # Etsy
        "etsy.com": {
            "price_selectors": [
                "[data-buy-box-listing-price]",
                ".wt-text-title-03",
                "[data-selector='price-only']",
            ],
            "name_selectors": [
                "[data-buy-box-listing-title]",
                "h1.wt-text-body-01",
            ],
            "image_selectors": [
                ".listing-page-image img",
            ],
        },
        
        # Kohl's
        "kohls.com": {
            "price_selectors": [
                ".price-wrapper .value",
                "[data-testid='product-price']",
            ],
            "name_selectors": [
                ".pdp-product-title",
                "h1.pdp-product-title",
            ],
            "image_selectors": [
                ".prod-image img",
            ],
        },
        
        # JCPenney
        "jcpenney.com": {
            "price_selectors": [
                ".price_amount",
                "[data-automation-id='at-price']",
            ],
            "name_selectors": [
                ".pdp-title",
                "h1.pdp-title",
            ],
            "image_selectors": [
                ".gallery-image img",
            ],
        },
        
        # Overstock
        "overstock.com": {
            "price_selectors": [
                ".price-box .monetary-price-value",
                "[data-testid='product-price']",
            ],
            "name_selectors": [
                ".product-title",
                "h1.product-title",
            ],
            "image_selectors": [
                ".product-image img",
            ],
        },
        
        # Bed Bath & Beyond (now overstock but still has separate domain)
        "bedbathandbeyond.com": {
            "price_selectors": [
                ".price",
                "[data-testid='product-price']",
            ],
            "name_selectors": [
                ".product-title",
                "h1.product-title",
            ],
            "image_selectors": [
                ".product-image img",
            ],
        },
        
        # Patagonia
        "patagonia.com": {
            "price_selectors": [
                ".product-price",
                "[data-testid='price']",
            ],
            "name_selectors": [
                ".product-name",
                "h1.product-name",
            ],
            "image_selectors": [
                ".product-image img",
            ],
        },
        
        # The North Face
        "thenorthface.com": {
            "price_selectors": [
                ".product-price",
                "[data-testid='product-price']",
            ],
            "name_selectors": [
                ".product-name",
                "h1.product-name",
            ],
            "image_selectors": [
                ".product-image img",
            ],
        },
        
        # Columbia
        "columbia.com": {
            "price_selectors": [
                ".price-sales",
                "[data-testid='product-price']",
            ],
            "name_selectors": [
                ".product-name",
                "h1.product-name",
            ],
            "image_selectors": [
                ".product-image img",
            ],
        },
        
        # Converse
        "converse.com": {
            "price_selectors": [
                "[data-testid='product-price']",
                ".product-price",
            ],
            "name_selectors": [
                "[data-testid='product-title']",
                "h1.product-title",
            ],
            "image_selectors": [
                ".product-image img",
            ],
        },
        
        # Vans
        "vans.com": {
            "price_selectors": [
                ".product-price",
                "[data-testid='product-price']",
            ],
            "name_selectors": [
                ".product-title",
                "h1.product-title",
            ],
            "image_selectors": [
                ".product-image img",
            ],
        },
        
        # ASOS
        "asos.com": {
            "price_selectors": [
                "[data-testid='current-price']",
                ".product-price",
            ],
            "name_selectors": [
                "[data-testid='product-name']",
                "h1.product-name",
            ],
            "image_selectors": [
                ".product-image img",
            ],
        },
        
        # Anthropologie
        "anthropologie.com": {
            "price_selectors": [
                ".c-pwa-product-price__current",
                "[data-testid='product-price']",
            ],
            "name_selectors": [
                ".c-pwa-product-info__name",
                "h1.product-name",
            ],
            "image_selectors": [
                ".c-pwa-image img",
            ],
        },
        
        # Urban Outfitters
        "urbanoutfitters.com": {
            "price_selectors": [
                ".c-pwa-product-price__current",
                "[data-testid='product-price']",
            ],
            "name_selectors": [
                ".c-pwa-product-info__name",
                "h1.product-name",
            ],
            "image_selectors": [
                ".c-pwa-image img",
            ],
        },
        
        # Free People
        "freepeople.com": {
            "price_selectors": [
                ".c-pwa-product-price__current",
                "[data-testid='product-price']",
            ],
            "name_selectors": [
                ".c-pwa-product-info__name",
                "h1.product-name",
            ],
            "image_selectors": [
                ".c-pwa-image img",
            ],
        },
        
        # Express
        "express.com": {
            "price_selectors": [
                ".product-price",
                "[data-testid='product-price']",
            ],
            "name_selectors": [
                ".product-name",
                "h1.product-name",
            ],
            "image_selectors": [
                ".product-image img",
            ],
        },
        
        # Abercrombie & Fitch
        "abercrombie.com": {
            "price_selectors": [
                ".product-price",
                "[data-testid='product-price']",
            ],
            "name_selectors": [
                ".product-name",
                "h1.product-name",
            ],
            "image_selectors": [
                ".product-image img",
            ],
        },
        
        # Hollister
        "hollisterco.com": {
            "price_selectors": [
                ".product-price",
                "[data-testid='product-price']",
            ],
            "name_selectors": [
                ".product-name",
                "h1.product-name",
            ],
            "image_selectors": [
                ".product-image img",
            ],
        },
        
        # American Eagle
        "ae.com": {
            "price_selectors": [
                ".product-price",
                "[data-testid='product-price']",
            ],
            "name_selectors": [
                ".product-name",
                "h1.product-name",
            ],
            "image_selectors": [
                ".product-image img",
            ],
        },
        
        # Aerie
        "aerie.com": {
            "price_selectors": [
                ".product-price",
                "[data-testid='product-price']",
            ],
            "name_selectors": [
                ".product-name",
                "h1.product-name",
            ],
            "image_selectors": [
                ".product-image img",
            ],
        },
        
        # Victoria's Secret
        "victoriassecret.com": {
            "price_selectors": [
                ".product-price",
                "[data-testid='product-price']",
            ],
            "name_selectors": [
                ".product-name",
                "h1.product-name",
            ],
            "image_selectors": [
                ".product-image img",
            ],
        },
        
        # Bath & Body Works
        "bathandbodyworks.com": {
            "price_selectors": [
                ".product-price",
                "[data-testid='product-price']",
            ],
            "name_selectors": [
                ".product-name",
                "h1.product-name",
            ],
            "image_selectors": [
                ".product-image img",
            ],
        },
        
        # Generic fallback patterns
        "default": {
            "price_selectors": [
                "[itemprop='price']",
                ".price",
                ".product-price",
                ".current-price",
                "[data-price]",
                ".sale-price",
                ".regular-price",
                "#priceblock_ourprice",
                ".a-price .a-offscreen",
            ],
            "name_selectors": [
                "[itemprop='name']",
                "h1.product-title",
                "h1.product-name",
                ".product-title h1",
                "h1",
            ],
            "image_selectors": [
                "[itemprop='image']",
                ".product-image img",
                ".gallery-image img",
                "img.primary-image",
            ],
        },
    }
    
    def __init__(self):
        self.browser: Optional[Browser] = None
        self.playwright = None
    
    async def __aenter__(self):
        await self.start()
        return self
    
    async def __aexit__(self, exc_type, exc_val, exc_tb):
        await self.close()
    
    async def start(self):
        """Initialize Playwright browser"""
        self.playwright = await async_playwright().start()
        self.browser = await self.playwright.chromium.launch(
            headless=True,
            args=[
                "--disable-blink-features=AutomationControlled",
                "--disable-dev-shm-usage",
                "--no-sandbox",
                "--disable-web-security",
                "--disable-features=IsolateOrigins,site-per-process",
                "--window-size=1920,1080",
            ]
        )
        logger.info("Browser started")
    
    async def close(self):
        """Close browser and cleanup"""
        if self.browser:
            await self.browser.close()
        if self.playwright:
            await self.playwright.stop()
        logger.info("Browser closed")
    
    def _get_domain(self, url: str) -> str:
        """Extract domain from URL"""
        parsed = urlparse(url)
        domain = parsed.netloc.replace("www.", "")
        return domain
    
    def _get_site_config(self, domain: str) -> Dict[str, Any]:
        """Get site-specific selectors or use defaults"""
        # Check for exact domain match
        if domain in self.SITE_CONFIGS:
            return self.SITE_CONFIGS[domain]
        
        # Check if it's a Shopify store (common pattern)
        # Many US DTC brands use Shopify
        return self.SITE_CONFIGS["default"]
    
    def _parse_price(self, price_text: str) -> Optional[Decimal]:
        """
        Parse price string to Decimal
        Handles formats like: $99.99, $1,299.00, USD 99.99, etc.
        """
        if not price_text:
            return None
        
        # Remove currency symbols and whitespace
        cleaned = re.sub(r'[^\d.,]', '', price_text.strip())
        
        if not cleaned:
            return None
        
        # Handle comma as thousands separator (US format)
        # e.g., 1,299.99 -> 1299.99
        if ',' in cleaned and '.' in cleaned:
            cleaned = cleaned.replace(',', '')
        elif ',' in cleaned:
            # Could be either thousands separator or decimal
            parts = cleaned.split(',')
            if len(parts[-1]) == 2:
                # Likely decimal separator
                cleaned = cleaned.replace(',', '.')
            else:
                # Thousands separator
                cleaned = cleaned.replace(',', '')
        
        try:
            return Decimal(cleaned).quantize(Decimal("0.01"))
        except Exception:
            return None
    
    async def _extract_text(self, page: Page, selectors: list) -> Optional[str]:
        """Try multiple selectors and return first match"""
        for selector in selectors:
            try:
                element = await page.query_selector(selector)
                if element:
                    text = await element.text_content()
                    if text and text.strip():
                        return text.strip()
            except Exception:
                continue
        return None
    
    async def _extract_image(self, page: Page, selectors: list) -> Optional[str]:
        """Extract product image URL"""
        for selector in selectors:
            try:
                element = await page.query_selector(selector)
                if element:
                    src = await element.get_attribute("src")
                    if src:
                        # Handle relative URLs
                        if src.startswith("//"):
                            src = "https:" + src
                        elif src.startswith("/"):
                            base_url = page.url.split("/")[0:3]
                            src = "/".join(base_url) + src
                        return src
            except Exception:
                continue
        return None
    
    async def crawl(self, url: str) -> CrawlResult:
        """
        Crawl a product page and extract price information
        """
        domain = self._get_domain(url)
        config = self._get_site_config(domain)
        
        if not self.browser:
            await self.start()
        
        # More realistic browser fingerprint
        context = await self.browser.new_context(
            viewport={"width": 1920, "height": 1080},
            user_agent="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/121.0.0.0 Safari/537.36",
            locale="en-US",
            timezone_id="America/New_York",
            geolocation={"latitude": 40.7128, "longitude": -74.0060},  # New York
            permissions=["geolocation"],
            extra_http_headers={
                "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8",
                "Accept-Language": "en-US,en;q=0.9",
                "Accept-Encoding": "gzip, deflate, br",
                "Cache-Control": "no-cache",
                "Pragma": "no-cache",
                "Sec-Ch-Ua": '"Not A(Brand";v="99", "Google Chrome";v="121", "Chromium";v="121"',
                "Sec-Ch-Ua-Mobile": "?0",
                "Sec-Ch-Ua-Platform": '"Windows"',
                "Sec-Fetch-Dest": "document",
                "Sec-Fetch-Mode": "navigate",
                "Sec-Fetch-Site": "none",
                "Sec-Fetch-User": "?1",
                "Upgrade-Insecure-Requests": "1",
            }
        )
        
        # Stealth mode: override webdriver detection
        await context.add_init_script("""
            Object.defineProperty(navigator, 'webdriver', { get: () => undefined });
            Object.defineProperty(navigator, 'plugins', { get: () => [1, 2, 3, 4, 5] });
            Object.defineProperty(navigator, 'languages', { get: () => ['en-US', 'en'] });
            window.chrome = { runtime: {} };
        """)
        
        # Set cookies for US region (Best Buy, Target, etc.)
        await context.add_cookies([
            {"name": "intl_splash", "value": "false", "domain": ".bestbuy.com", "path": "/"},
            {"name": "UID", "value": "us", "domain": ".bestbuy.com", "path": "/"},
        ])
        
        page = await context.new_page()
        
        try:
            # Navigate to page
            await page.goto(url, wait_until="networkidle", timeout=settings.REQUEST_TIMEOUT * 1000)
            
            # Check for bot detection / CAPTCHA pages
            page_title = await page.title()
            page_content = await page.content()
            
            bot_indicators = [
                "robot or human",
                "access denied",
                "blocked",
                "captcha",
                "verify you are human",
                "unusual traffic",
            ]
            
            is_blocked = any(indicator in page_title.lower() or indicator in page_content.lower()[:2000] 
                           for indicator in bot_indicators)
            
            if is_blocked:
                logger.warning("Bot detection triggered", url=url, title=page_title)
                return CrawlResult(
                    success=False,
                    url=url,
                    domain=domain,
                    error=f"Access blocked by {domain}. This store has strong bot protection."
                )
            
            # Wait for dynamic content (longer for Amazon)
            wait_time = config.get("wait_time", 2000)
            await page.wait_for_timeout(wait_time)
            
            # For Amazon, scroll to trigger lazy loading
            if "amazon" in domain:
                await page.evaluate("window.scrollTo(0, 500)")
                await page.wait_for_timeout(1000)
            
            # Try to close any popups/modals
            await self._close_popups(page)
            
            # Extract price
            price_text = await self._extract_text(page, config["price_selectors"])
            price = self._parse_price(price_text) if price_text else None
            
            if not price:
                # Try getting from structured data
                price = await self._extract_structured_price(page)
            
            if not price:
                # Fallback: extract price from page HTML using regex (for Amazon, etc.)
                price = await self._extract_price_regex(page)
            
            # Extract product name
            name = await self._extract_text(page, config["name_selectors"])
            if not name:
                name = await self._extract_structured_name(page)
            
            # Extract image
            image_url = await self._extract_image(page, config["image_selectors"])
            
            # Check availability
            is_available = await self._check_availability(page)
            
            if not price:
                return CrawlResult(
                    success=False,
                    url=url,
                    domain=domain,
                    name=name,
                    error="Could not extract price from page"
                )
            
            logger.info(
                "Crawl successful",
                url=url,
                price=str(price),
                name=name[:50] if name else None
            )
            
            # Determine currency from site config or domain
            currency = config.get("currency", "USD")
            if "amazon" in domain and domain in self.AMAZON_CURRENCY_MAP:
                currency = self.AMAZON_CURRENCY_MAP[domain]
            
            return CrawlResult(
                success=True,
                url=url,
                domain=domain,
                name=name or "Unknown Product",
                price=price,
                currency=currency,
                image_url=image_url,
                is_available=is_available,
            )
            
        except PlaywrightTimeout:
            logger.error("Timeout crawling page", url=url)
            return CrawlResult(
                success=False,
                url=url,
                domain=domain,
                error="Page load timeout"
            )
        except Exception as e:
            logger.error("Error crawling page", url=url, error=str(e))
            return CrawlResult(
                success=False,
                url=url,
                domain=domain,
                error=str(e)
            )
        finally:
            await context.close()
    
    async def _close_popups(self, page: Page):
        """Try to close common popup/modal patterns"""
        popup_selectors = [
            "[aria-label='Close']",
            ".modal-close",
            ".popup-close",
            "button.close",
            "[data-testid='close-button']",
            ".newsletter-close",
        ]
        
        for selector in popup_selectors:
            try:
                btn = await page.query_selector(selector)
                if btn and await btn.is_visible():
                    await btn.click()
                    await page.wait_for_timeout(500)
            except Exception:
                pass
    
    async def _extract_structured_price(self, page: Page) -> Optional[Decimal]:
        """Extract price from JSON-LD structured data"""
        try:
            scripts = await page.query_selector_all('script[type="application/ld+json"]')
            for script in scripts:
                content = await script.text_content()
                if content:
                    import json
                    data = json.loads(content)
                    
                    # Handle array of structured data
                    if isinstance(data, list):
                        for item in data:
                            price = self._extract_price_from_json(item)
                            if price:
                                return price
                    else:
                        price = self._extract_price_from_json(data)
                        if price:
                            return price
        except Exception:
            pass
        return None
    
    def _extract_price_from_json(self, data: dict) -> Optional[Decimal]:
        """Extract price from structured data JSON"""
        try:
            # Product schema
            if data.get("@type") == "Product":
                offers = data.get("offers", {})
                if isinstance(offers, list):
                    offers = offers[0] if offers else {}
                price = offers.get("price") or offers.get("lowPrice")
                if price:
                    return Decimal(str(price)).quantize(Decimal("0.01"))
        except Exception:
            pass
        return None
    
    async def _extract_price_regex(self, page: Page) -> Optional[Decimal]:
        """Fallback: extract price from rendered page text using regex patterns"""
        try:
            # Get rendered body text (not HTML) - this includes JS-rendered content
            body_text = await page.inner_text("body")
            
            # Pattern for US prices: $X,XXX.XX or $X,XXX or $XXX.XX or $XXX
            pattern = r'\$(\d{1,3}(?:,\d{3})*(?:\.\d{2})?)'
            matches = re.findall(pattern, body_text)
            
            prices_found = []
            for match in matches:
                try:
                    # Remove commas and convert to Decimal
                    clean_price = match.replace(',', '')
                    price = Decimal(clean_price)
                    # Filter reasonable prices ($5 - $100,000)
                    if 5 <= price <= 100000:
                        prices_found.append(price)
                except Exception:
                    continue
            
            if prices_found:
                # Return the first reasonable price (usually the main product price)
                return prices_found[0].quantize(Decimal("0.01"))
        except Exception:
            pass
        return None
    
    async def _extract_structured_name(self, page: Page) -> Optional[str]:
        """Extract product name from structured data"""
        try:
            scripts = await page.query_selector_all('script[type="application/ld+json"]')
            for script in scripts:
                content = await script.text_content()
                if content:
                    import json
                    data = json.loads(content)
                    if isinstance(data, list):
                        data = data[0]
                    if data.get("@type") == "Product":
                        return data.get("name")
        except Exception:
            pass
        return None
    
    async def _check_availability(self, page: Page) -> bool:
        """Check if product is in stock"""
        out_of_stock_patterns = [
            "out of stock",
            "sold out",
            "currently unavailable",
            "not available",
            "notify me when available",
        ]
        
        try:
            page_text = await page.text_content("body")
            if page_text:
                page_text_lower = page_text.lower()
                for pattern in out_of_stock_patterns:
                    if pattern in page_text_lower:
                        return False
        except Exception:
            pass
        
        return True


# Singleton instance for reuse
_crawler: Optional[PriceCrawler] = None


async def get_crawler() -> PriceCrawler:
    """Get or create crawler instance"""
    global _crawler
    if _crawler is None:
        _crawler = PriceCrawler()
        await _crawler.start()
    return _crawler


async def crawl_product(url: str) -> CrawlResult:
    """Convenience function to crawl a single product"""
    crawler = await get_crawler()
    return await crawler.crawl(url)
