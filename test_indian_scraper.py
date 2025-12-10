#!/usr/bin/env python3
"""
Test script for Indian Stock Scraper
Tests NSE API, Screener.in, and Moneycontrol scraping
"""

import requests
import json
import time
from html.parser import HTMLParser
import re

class MetricExtractor(HTMLParser):
    def __init__(self):
        super().__init__()
        self.metrics = {}
        self.current_label = None
        self.in_table = False
        
    def handle_data(self, data):
        if self.in_table and data.strip():
            # Look for metric patterns
            data = data.strip()
            if 'P/E' in data or 'PE' in data:
                # Extract PE value
                pe_match = re.search(r'(\d+\.?\d*)', data)
                if pe_match:
                    try:
                        self.metrics['pe'] = float(pe_match.group(1))
                    except:
                        pass

def test_nse_api(symbol):
    """Test NSE India API"""
    print(f"\n📊 Testing NSE API for {symbol}")
    print("-" * 60)
    
    clean_symbol = symbol.replace('.NS', '').replace('.BO', '').upper()
    
    # First get session cookie
    try:
        session = requests.Session()
        session.get('https://www.nseindia.com', headers={
            'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36'
        })
        
        url = f'https://www.nseindia.com/api/quote-equity?symbol={clean_symbol}'
        headers = {
            'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36',
            'Accept': 'application/json',
            'Referer': 'https://www.nseindia.com/',
        }
        
        response = session.get(url, headers=headers, timeout=15)
        
        if response.status_code == 200:
            data = response.json()
            
            print("✅ NSE API Response:")
            print(f"   Status: {response.status_code}")
            
            # Extract key data
            price_info = data.get('priceInfo', {})
            metadata = data.get('metadata', {})
            info = data.get('info', {})
            
            if price_info:
                print(f"   Current Price: ₹{price_info.get('lastPrice', 'N/A')}")
                print(f"   Change: ₹{price_info.get('change', 'N/A')}")
                print(f"   High: ₹{price_info.get('intraDayHighLow', {}).get('max', 'N/A')}")
                print(f"   Low: ₹{price_info.get('intraDayHighLow', {}).get('min', 'N/A')}")
                print(f"   Volume: {price_info.get('totalTradedVolume', 'N/A')}")
            
            if metadata:
                print(f"   PE Ratio: {metadata.get('pdSymbolPe', 'N/A')}")
                print(f"   Market Cap: {metadata.get('marketCap', 'N/A')}")
                print(f"   Sector PE: {metadata.get('pdSectorPe', 'N/A')}")
            
            if info:
                print(f"   Company Name: {info.get('companyName', 'N/A')}")
                print(f"   Industry: {info.get('industry', 'N/A')}")
            
            return True
        else:
            print(f"❌ NSE API failed with status {response.status_code}")
            print(f"   Response: {response.text[:200]}")
            return False
            
    except Exception as e:
        print(f"❌ NSE API error: {e}")
        return False

def test_screener_in(symbol):
    """Test Screener.in scraping"""
    print(f"\n📊 Testing Screener.in for {symbol}")
    print("-" * 60)
    
    clean_symbol = symbol.replace('.NS', '').replace('.BO', '').upper()
    
    try:
        # First try search API
        search_url = f'https://www.screener.in/api/company/search/?q={clean_symbol}'
        headers = {
            'User-Agent': 'Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15',
            'Accept': 'application/json',
        }
        
        response = requests.get(search_url, headers=headers, timeout=15)
        
        if response.status_code == 200:
            search_results = response.json()
            if search_results:
                company_url = search_results[0].get('url', '')
                if company_url:
                    if not company_url.startswith('http'):
                        company_url = f'https://www.screener.in{company_url}'
                    
                    print(f"✅ Found company URL: {company_url}")
                    
                    # Fetch the company page
                    page_response = requests.get(company_url, headers=headers, timeout=20)
                    
                    if page_response.status_code == 200:
                        print(f"✅ Screener.in page loaded successfully")
                        print(f"   Page length: {len(page_response.text)} characters")
                        
                        # Check for key metrics in HTML
                        html = page_response.text
                        metrics_found = []
                        
                        # Look for common metric patterns
                        if 'P/E' in html or 'PE' in html:
                            metrics_found.append('PE')
                        if 'Dividend Yield' in html or 'dividend yield' in html:
                            metrics_found.append('Dividend Yield')
                        if 'Beta' in html:
                            metrics_found.append('Beta')
                        if 'ROE' in html or 'Return on Equity' in html:
                            metrics_found.append('ROE')
                        if 'Debt to Equity' in html or 'D/E' in html:
                            metrics_found.append('Debt/Equity')
                        if 'Market Cap' in html or 'Market Cap' in html:
                            metrics_found.append('Market Cap')
                        if 'Price to Book' in html or 'P/B' in html:
                            metrics_found.append('Price to Book')
                        
                        print(f"   Metrics found in HTML: {', '.join(metrics_found) if metrics_found else 'None detected'}")
                        return True
                    else:
                        print(f"❌ Failed to load company page: {page_response.status_code}")
                        return False
                else:
                    print("❌ No company URL found in search results")
                    return False
            else:
                print("❌ No search results found")
                return False
        else:
            print(f"❌ Screener.in search failed: {response.status_code}")
            return False
            
    except Exception as e:
        print(f"❌ Screener.in error: {e}")
        import traceback
        traceback.print_exc()
        return False

def test_moneycontrol(symbol):
    """Test Moneycontrol scraping"""
    print(f"\n📊 Testing Moneycontrol for {symbol}")
    print("-" * 60)
    
    clean_symbol = symbol.replace('.NS', '').replace('.BO', '').upper()
    
    # URL mapping for common stocks
    url_map = {
        'TCS': 'https://www.moneycontrol.com/india/stockpricequote/computers-software/tataconsultancyservices/TCS',
        'INFY': 'https://www.moneycontrol.com/india/stockpricequote/computers-software/infosys/INFY',
        'RELIANCE': 'https://www.moneycontrol.com/india/stockpricequote/refineries/relianceindustries/RI',
        'HDFCBANK': 'https://www.moneycontrol.com/india/stockpricequote/banks-private-sector/hdfcbank/HDF01',
    }
    
    if clean_symbol not in url_map:
        print(f"⚠️  No URL mapping for {clean_symbol}, skipping Moneycontrol test")
        return False
    
    try:
        url = url_map[clean_symbol]
        headers = {
            'User-Agent': 'Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15',
            'Accept': 'text/html',
        }
        
        response = requests.get(url, headers=headers, timeout=20)
        
        if response.status_code == 200:
            print(f"✅ Moneycontrol page loaded successfully")
            print(f"   Page length: {len(response.text)} characters")
            
            # Check for key metrics
            html = response.text
            metrics_found = []
            
            if 'P/E' in html or 'PE' in html:
                metrics_found.append('PE')
            if 'Beta' in html:
                metrics_found.append('Beta')
            if 'Dividend Yield' in html:
                metrics_found.append('Dividend Yield')
            
            print(f"   Metrics found in HTML: {', '.join(metrics_found) if metrics_found else 'None detected'}")
            return True
        else:
            print(f"❌ Moneycontrol failed: {response.status_code}")
            return False
            
    except Exception as e:
        print(f"❌ Moneycontrol error: {e}")
        return False

def main():
    print("🧪 Testing Indian Stock Scraper")
    print("=" * 60)
    
    test_symbols = ['RELIANCE.NS', 'TCS.NS', 'INFY.NS', 'HDFCBANK.NS']
    
    results = {
        'NSE': [],
        'Screener.in': [],
        'Moneycontrol': []
    }
    
    for symbol in test_symbols:
        print(f"\n{'='*60}")
        print(f"Testing: {symbol}")
        print('='*60)
        
        # Test NSE
        nse_result = test_nse_api(symbol)
        results['NSE'].append((symbol, nse_result))
        
        time.sleep(2)  # Rate limiting
        
        # Test Screener.in
        screener_result = test_screener_in(symbol)
        results['Screener.in'].append((symbol, screener_result))
        
        time.sleep(2)  # Rate limiting
        
        # Test Moneycontrol (if available)
        if symbol.replace('.NS', '').upper() in ['TCS', 'INFY', 'RELIANCE', 'HDFCBANK']:
            mc_result = test_moneycontrol(symbol)
            results['Moneycontrol'].append((symbol, mc_result))
            time.sleep(2)
        
        if symbol != test_symbols[-1]:
            print("\n⏳ Waiting 3 seconds before next symbol...")
            time.sleep(3)
    
    # Summary
    print("\n" + "="*60)
    print("📊 TEST SUMMARY")
    print("="*60)
    
    for service, test_results in results.items():
        passed = sum(1 for _, result in test_results if result)
        total = len(test_results)
        print(f"\n{service}:")
        print(f"   Passed: {passed}/{total}")
        for symbol, result in test_results:
            status = "✅" if result else "❌"
            print(f"   {status} {symbol}")
    
    print("\n" + "="*60)
    print("✅ Testing completed!")

if __name__ == '__main__':
    main()

