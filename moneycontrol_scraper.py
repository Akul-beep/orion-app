#!/usr/bin/env python3
"""
Moneycontrol.com Web Scraper for Indian Stock Market Data
Simple, direct scraper that gets ALL metrics
"""

import requests
from bs4 import BeautifulSoup
import re
import json
from typing import Dict, Optional
import time

class MoneycontrolScraper:
    """Scraper for Moneycontrol.com"""
    
    BASE_URL = "https://www.moneycontrol.com"
    
    def __init__(self):
        self.session = requests.Session()
        self.session.headers.update({
            'User-Agent': 'Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1',
            'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
            'Accept-Language': 'en-US,en;q=0.9',
        })
    
    def normalize_symbol(self, symbol: str) -> str:
        return symbol.replace('.NS', '').replace('.BO', '').strip().upper()
    
    def get_company_url(self, symbol: str) -> str:
        """Get Moneycontrol URL - they use specific URL patterns"""
        symbol = self.normalize_symbol(symbol)
        
        # Common mappings
        url_map = {
            'TCS': 'https://www.moneycontrol.com/india/stockpricequote/computers-software/tataconsultancyservices/TCS',
            'INFY': 'https://www.moneycontrol.com/india/stockpricequote/computers-software/infosys/INFY',
            'INFOSYS': 'https://www.moneycontrol.com/india/stockpricequote/computers-software/infosys/INFY',
            'RELIANCE': 'https://www.moneycontrol.com/india/stockpricequote/refineries/relianceindustries/RI',
            'HDFCBANK': 'https://www.moneycontrol.com/india/stockpricequote/banks-private-sector/hdfcbank/HDF01',
            'ICICIBANK': 'https://www.moneycontrol.com/india/stockpricequote/banks-private-sector/icicibank/ICI02',
        }
        
        if symbol in url_map:
            return url_map[symbol]
        
        # Try search API
        try:
            search_url = f"{self.BASE_URL}/stocks/cptmarket/compsearchnew.php?search_data={symbol}&searchtype=1"
            response = self.session.get(search_url, timeout=10)
            if response.status_code == 200:
                soup = BeautifulSoup(response.content, 'html.parser')
                link = soup.find('a', href=re.compile('/india/stockpricequote/'))
                if link:
                    href = link.get('href')
                    if href.startswith('http'):
                        return href
                    return f"{self.BASE_URL}{href}"
        except:
            pass
        
        return None
    
    def _convert_market_cap(self, value: float, unit: Optional[str] = None) -> Optional[float]:
        """Convert market cap to millions"""
        if unit and unit.upper() == 'CR':
            return value * 1e7 / 1e6
        elif unit and unit.upper() == 'L':
            return value * 1e5 / 1e6
        elif unit and unit.upper() == 'B':
            return value * 1e9 / 1e6
        elif unit and unit.upper() == 'M':
            return value
        elif value > 1000:
            return value * 1e7 / 1e6  # Assume crores
        else:
            return value * 1e9 / 1e6
    
    def parse_number(self, text: str) -> Optional[float]:
        if not text or text in ['—', '-', 'N/A', '']:
            return None
        
        text = text.replace(',', '').replace(' ', '').strip()
        
        if '%' in text:
            text = text.replace('%', '')
            try:
                return float(text) / 100
            except:
                return None
        
        multiplier = 1
        if 'Cr' in text or 'CR' in text:
            text = text.replace('Cr', '').replace('CR', '')
            multiplier = 1e7
        elif 'L' in text:
            text = text.replace('L', '')
            multiplier = 1e5
        elif 'B' in text:
            text = text.replace('B', '')
            multiplier = 1e9
        elif 'M' in text:
            text = text.replace('M', '')
            multiplier = 1e6
        
        text = re.sub(r'[^\d.\-]', '', text)
        
        try:
            if text:
                value = float(text) * multiplier
                if -1e15 < value < 1e15:
                    return value
        except:
            pass
        
        return None
    
    def scrape_company(self, symbol: str) -> Dict:
        symbol = self.normalize_symbol(symbol)
        print(f"\n🔍 Scraping {symbol} from Moneycontrol...")
        
        url = self.get_company_url(symbol)
        if not url:
            print(f"❌ Could not find URL for {symbol}")
            return {}
        
        print(f"✅ URL: {url}")
        
        try:
            response = self.session.get(url, timeout=15)
            if response.status_code != 200:
                print(f"❌ Failed: {response.status_code}")
                return {}
            
            soup = BeautifulSoup(response.content, 'html.parser')
            metrics = {}
            
            # Extract company name
            name_elem = soup.find('h1', class_=re.compile('company|b_42', re.I))
            if name_elem:
                metrics['name'] = name_elem.get_text(strip=True)
            
            # Extract from ALL tables on page (Moneycontrol uses tabs but data is in HTML)
            # Check ratios tab specifically
            ratios_div = soup.find('div', {'id': 'ratios'}) or \
                        soup.find('div', {'id': 'stand_ratios'}) or \
                        soup.find('div', class_=re.compile('ratio', re.I))
            
            # Get all tables from page
            all_tables = soup.find_all('table')
            
            # Also check ratios div if it exists
            if ratios_div:
                ratios_tables = ratios_div.find_all('table')
                all_tables.extend(ratios_tables)
            
            for table in all_tables:
                rows = table.find_all('tr')
                for row in rows:
                    cells = row.find_all(['td', 'th'])
                    if len(cells) >= 2:
                        label = cells[0].get_text(strip=True).lower()
                        value_text = cells[-1].get_text(strip=True) if len(cells) > 1 else ''
                        value = self.parse_number(value_text)
                        
                        if value is None:
                            continue
                        
                        # Map all metrics - check all possible labels
                        if ('market cap' in label or 'mcap' in label) and 'marketCap' not in metrics:
                            if value > 1e12:
                                metrics['marketCap'] = value / 1e6
                            elif value > 1e9:
                                metrics['marketCap'] = value / 1e6
                            else:
                                metrics['marketCap'] = value / 1e6
                        
                        elif ('pe' in label or 'p/e' in label) and ('ratio' in label or 'multiple' in label) and 'peRatio' not in metrics:
                            if 0 < value < 1000:
                                metrics['peRatio'] = value
                        
                        elif ('price to book' in label or 'p/b' in label or 'pb' in label) and 'priceToBook' not in metrics:
                            if 0 < value < 1000:
                                metrics['priceToBook'] = value
                        
                        elif 'dividend yield' in label and 'dividendYield' not in metrics:
                            metrics['dividendYield'] = value / 100 if value > 1 else value
                        
                        elif 'beta' in label and 'beta' not in metrics:
                            if 0 <= value <= 10:
                                metrics['beta'] = value
                        
                        elif ('eps' in label or 'earnings per share' in label) and 'eps' not in metrics:
                            metrics['eps'] = value
                        
                        elif ('roe' in label or 'return on equity' in label) and 'returnOnEquity' not in metrics:
                            metrics['returnOnEquity'] = value / 100 if value > 1 else value
                        
                        elif ('debt to equity' in label or 'd/e' in label or 'debt/equity' in label) and 'debtToEquity' not in metrics:
                            if 0 <= value <= 100:
                                metrics['debtToEquity'] = value
                        
                        elif ('book value' in label or 'bv' in label) and 'bookValue' not in metrics:
                            metrics['bookValue'] = value
                        
                        elif ('roce' in label or 'return on capital' in label) and 'returnOnCapitalEmployed' not in metrics:
                            metrics['returnOnCapitalEmployed'] = value / 100 if value > 1 else value
            
            # Extract from financials section for revenue and profit
            financials_div = soup.find('div', {'id': 'financials'}) or \
                            soup.find('div', {'id': 'consolidated'}) or \
                            soup.find('div', {'id': 'standalone'})
            
            pl_section = financials_div if financials_div else soup
            
            if pl_section:
                tables = pl_section.find_all('table')
                for table in tables:
                    rows = table.find_all('tr')
                    for row in rows:
                        cells = row.find_all(['td', 'th'])
                        if len(cells) >= 2:
                            label = cells[0].get_text(strip=True).lower()
                            value_text = cells[-1].get_text(strip=True)
                            value = self.parse_number(value_text)
                            
                            if value is None:
                                continue
                            
                            if 'sales' in label or 'revenue' in label or 'total income' in label:
                                if 'revenue' not in metrics:
                                    metrics['revenue'] = value / 1e9 if value > 1e9 else value / 100
                            elif 'net profit' in label or 'pat' in label:
                                if 'revenue' in metrics:
                                    rev_base = metrics['revenue'] * 1e9 if metrics['revenue'] < 1 else metrics['revenue'] * 100
                                    if rev_base > 0:
                                        metrics['profitMargin'] = value / rev_base
            
            # Extract from JSON data in script tags (Moneycontrol loads data via JS)
            scripts = soup.find_all('script')
            for script in scripts:
                if script.string:
                    content = script.string
                    # Look for JSON data with financial metrics
                    if 'pe' in content.lower() or 'beta' in content.lower() or 'roe' in content.lower():
                        # Try to extract JSON
                        json_matches = re.findall(r'\{[^{]*"(?:pe|beta|roe|debt|eps|priceToBook)"[^}]*\}', content, re.IGNORECASE)
                        for json_str in json_matches:
                            try:
                                data = json.loads(json_str)
                                for key, val in data.items():
                                    if key.lower() in ['pe', 'peratio', 'p/e'] and 'peRatio' not in metrics:
                                        v = self.parse_number(str(val))
                                        if v and 0 < v < 1000:
                                            metrics['peRatio'] = v
                                    elif key.lower() == 'beta' and 'beta' not in metrics:
                                        v = self.parse_number(str(val))
                                        if v and 0 <= v <= 10:
                                            metrics['beta'] = v
                                    elif key.lower() in ['roe', 'returnonequity'] and 'returnOnEquity' not in metrics:
                                        v = self.parse_number(str(val))
                                        if v:
                                            metrics['returnOnEquity'] = v / 100 if v > 1 else v
                                    elif key.lower() in ['debttoequity', 'd/e'] and 'debtToEquity' not in metrics:
                                        v = self.parse_number(str(val))
                                        if v and 0 <= v <= 100:
                                            metrics['debtToEquity'] = v
                                    elif key.lower() == 'eps' and 'eps' not in metrics:
                                        v = self.parse_number(str(val))
                                        if v:
                                            metrics['eps'] = v
                                    elif key.lower() in ['pricetobook', 'pb', 'p/b'] and 'priceToBook' not in metrics:
                                        v = self.parse_number(str(val))
                                        if v and 0 < v < 1000:
                                            metrics['priceToBook'] = v
                            except:
                                pass
            
            # Extract from page text - Moneycontrol has metrics in various places
            page_text = soup.get_text()
            
            patterns = {
                'peRatio': (r'P[/\s]*E[:\s]+([\d.]+)', lambda v: v if 0 < v < 1000 else None),
                'beta': (r'Beta[:\s]+([\d.]+)', lambda v: v if 0 <= v <= 10 else None),
                'dividendYield': (r'Dividend.*Yield[:\s]+([\d.]+)', lambda v: v / 100 if v > 1 else v),
                'eps': (r'EPS[:\s]+([\d.]+)', lambda v: v if v > 0 else None),
                'priceToBook': (r'Price.*Book[:\s]+([\d.]+)', lambda v: v if 0 < v < 1000 else None),
                'returnOnEquity': (r'ROE[:\s]+([\d.]+)', lambda v: v / 100 if v > 1 else v),
                'debtToEquity': (r'Debt.*Equity[:\s]+([\d.]+)', lambda v: v if 0 <= v <= 100 else None),
                'marketCap': (r'Market Cap[:\s]+₹?\s*([\d,.]+)\s*(Cr|L|B|M)?', lambda v, unit: self._convert_market_cap(v, unit)),
            }
            
            for key, (pattern, validator) in patterns.items():
                if key not in metrics:
                    match = re.search(pattern, page_text, re.IGNORECASE)
                    if match:
                        if key == 'marketCap':
                            val_str = match.group(1).replace(',', '') if match.group(1) else '0'
                            unit = match.group(2) if len(match.groups()) > 1 else None
                            val = self.parse_number(val_str)
                            if val:
                                result = validator(val, unit)
                                if result is not None:
                                    metrics[key] = result
                        else:
                            val = self.parse_number(match.group(1))
                            if val:
                                result = validator(val)
                                if result is not None:
                                    metrics[key] = result
            
            # Final cleanup and validation
            cleaned_metrics = {}
            for k, v in metrics.items():
                if v is not None:
                    cleaned_metrics[k] = v
            
            # Calculate Price to Book if we have Book Value and Current Price
            if 'priceToBook' not in cleaned_metrics and 'bookValue' in cleaned_metrics:
                # Try to get current price from page
                price_pattern = r'Current Price[:\s]+₹?\s*([\d,.]+)'
                price_match = re.search(price_pattern, page_text, re.IGNORECASE)
                if price_match:
                    current_price = self.parse_number(price_match.group(1))
                    if current_price and cleaned_metrics.get('bookValue'):
                        cleaned_metrics['priceToBook'] = current_price / cleaned_metrics['bookValue']
            
            # Calculate EPS from P/E and Price if not found
            if 'eps' not in cleaned_metrics and 'peRatio' in cleaned_metrics:
                price_pattern = r'Current Price[:\s]+₹?\s*([\d,.]+)'
                price_match = re.search(price_pattern, page_text, re.IGNORECASE)
                if price_match:
                    current_price = self.parse_number(price_match.group(1))
                    if current_price and cleaned_metrics.get('peRatio'):
                        cleaned_metrics['eps'] = current_price / cleaned_metrics['peRatio']
            
            print(f"✅ Extracted {len(cleaned_metrics)} metrics")
            return cleaned_metrics
            
        except Exception as e:
            print(f"❌ Error: {e}")
            import traceback
            traceback.print_exc()
            return {}


def main():
    scraper = MoneycontrolScraper()
    
    for symbol in ['TCS', 'INFY', 'RELIANCE']:
        print(f"\n{'='*60}")
        data = scraper.scrape_company(symbol)
        if data:
            print("\n✅ Metrics:")
            for k, v in data.items():
                print(f"  {k:20s}: {v}")
        time.sleep(2)


if __name__ == '__main__':
    main()
