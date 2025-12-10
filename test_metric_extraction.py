#!/usr/bin/env python3
"""
Detailed test to verify all metrics are being extracted correctly
"""

import requests
import json
import re

def test_nse_metrics_extraction(symbol):
    """Test detailed NSE metrics extraction"""
    print(f"\n📊 Detailed NSE Metrics Extraction for {symbol}")
    print("=" * 60)
    
    clean_symbol = symbol.replace('.NS', '').replace('.BO', '').upper()
    
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
            
            print("\n✅ NSE API Response Structure:")
            print(f"   Top-level keys: {list(data.keys())}")
            
            # Check metadata
            metadata = data.get('metadata', {})
            print(f"\n📋 Metadata keys: {list(metadata.keys())}")
            print(f"   pdSymbolPe (PE): {metadata.get('pdSymbolPe')}")
            print(f"   pdSectorPe: {metadata.get('pdSectorPe')}")
            print(f"   marketCap: {metadata.get('marketCap')}")
            print(f"   issuedSize: {metadata.get('issuedSize')}")
            
            # Check priceInfo
            price_info = data.get('priceInfo', {})
            print(f"\n💰 PriceInfo keys: {list(price_info.keys())}")
            print(f"   lastPrice: {price_info.get('lastPrice')}")
            print(f"   previousClose: {price_info.get('previousClose')}")
            print(f"   open: {price_info.get('open')}")
            
            # Check securityInfo
            security_info = data.get('securityInfo', {})
            print(f"\n🔒 SecurityInfo keys: {list(security_info.keys())}")
            print(f"   issuedSize: {security_info.get('issuedSize')}")
            print(f"   faceValue: {security_info.get('faceValue')}")
            
            # Check info
            info = data.get('info', {})
            print(f"\nℹ️  Info keys: {list(info.keys())}")
            print(f"   companyName: {info.get('companyName')}")
            print(f"   industry: {info.get('industry')}")
            
            # Calculate metrics
            current_price = price_info.get('lastPrice', 0)
            shares_outstanding = security_info.get('issuedSize', 0) or metadata.get('issuedSize', 0)
            pe = metadata.get('pdSymbolPe')
            
            print(f"\n📊 Calculated Metrics:")
            if current_price and shares_outstanding:
                market_cap = (current_price * shares_outstanding) / 1e6  # Convert to millions
                print(f"   Market Cap (calculated): {market_cap:.2f}M")
            
            if pe and current_price:
                eps = current_price / pe
                print(f"   EPS (calculated): {eps:.2f}")
            
            return True
        else:
            print(f"❌ Failed: {response.status_code}")
            return False
            
    except Exception as e:
        print(f"❌ Error: {e}")
        import traceback
        traceback.print_exc()
        return False

def test_screener_metrics(symbol):
    """Test Screener.in metrics extraction"""
    print(f"\n📊 Testing Screener.in Metrics Extraction for {symbol}")
    print("=" * 60)
    
    clean_symbol = symbol.replace('.NS', '').replace('.BO', '').upper()
    
    try:
        # Search for company
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
                if company_url and not company_url.startswith('http'):
                    company_url = f'https://www.screener.in{company_url}'
                
                # Fetch page
                page_response = requests.get(company_url, headers=headers, timeout=20)
                
                if page_response.status_code == 200:
                    html = page_response.text
                    
                    print("\n✅ Screener.in Page Loaded")
                    print(f"   URL: {company_url}")
                    print(f"   Page size: {len(html)} characters")
                    
                    # Extract metrics using regex patterns
                    metrics = {}
                    
                    # PE Ratio
                    pe_pattern = r'P[/\s]*E[:\s]+([\d.]+)'
                    pe_match = re.search(pe_pattern, html, re.IGNORECASE)
                    if pe_match:
                        metrics['pe'] = pe_match.group(1)
                        print(f"   ✅ PE Ratio found: {metrics['pe']}")
                    
                    # Dividend Yield
                    div_pattern = r'Dividend.*Yield[:\s]+([\d.]+)'
                    div_match = re.search(div_pattern, html, re.IGNORECASE)
                    if div_match:
                        metrics['dividendYield'] = div_match.group(1)
                        print(f"   ✅ Dividend Yield found: {metrics['dividendYield']}%")
                    
                    # ROE
                    roe_pattern = r'ROE[:\s]+([\d.]+)'
                    roe_match = re.search(roe_pattern, html, re.IGNORECASE)
                    if roe_match:
                        metrics['roe'] = roe_match.group(1)
                        print(f"   ✅ ROE found: {metrics['roe']}%")
                    
                    # Market Cap
                    mcap_pattern = r'Market Cap[:\s]+₹?\s*([\d,.]+)\s*(Cr|L|M|B)?'
                    mcap_match = re.search(mcap_pattern, html, re.IGNORECASE)
                    if mcap_match:
                        metrics['marketCap'] = mcap_match.group(1)
                        print(f"   ✅ Market Cap found: ₹{metrics['marketCap']} {mcap_match.group(2) or ''}")
                    
                    # Price to Book
                    pb_pattern = r'Price.*Book[:\s]+([\d.]+)'
                    pb_match = re.search(pb_pattern, html, re.IGNORECASE)
                    if pb_match:
                        metrics['priceToBook'] = pb_match.group(1)
                        print(f"   ✅ Price to Book found: {metrics['priceToBook']}")
                    
                    # Beta
                    beta_pattern = r'Beta[:\s]+([\d.]+)'
                    beta_match = re.search(beta_pattern, html, re.IGNORECASE)
                    if beta_match:
                        metrics['beta'] = beta_match.group(1)
                        print(f"   ✅ Beta found: {metrics['beta']}")
                    
                    print(f"\n   Total metrics extracted: {len(metrics)}")
                    return True
                else:
                    print(f"❌ Failed to load page: {page_response.status_code}")
                    return False
            else:
                print("❌ No search results")
                return False
        else:
            print(f"❌ Search failed: {response.status_code}")
            return False
            
    except Exception as e:
        print(f"❌ Error: {e}")
        import traceback
        traceback.print_exc()
        return False

def main():
    print("🧪 Detailed Metric Extraction Test")
    print("=" * 60)
    
    test_symbol = 'RELIANCE.NS'
    
    # Test NSE
    test_nse_metrics_extraction(test_symbol)
    
    # Test Screener.in
    test_screener_metrics(test_symbol)
    
    print("\n" + "=" * 60)
    print("✅ Detailed testing completed!")

if __name__ == '__main__':
    main()

