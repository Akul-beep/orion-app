#!/usr/bin/env python3
import http.server
import socketserver
import json
import urllib.request
import urllib.parse
from urllib.error import URLError
import threading
import time

# Finnhub API configuration
FINNHUB_API_KEY = "d2imrl9r01qhm15b6ufgd2imrl9r01qhm15b6ug0"
FINNHUB_BASE_URL = "https://finnhub.io/api/v1"

class CORSHTTPRequestHandler(http.server.SimpleHTTPRequestHandler):
    def end_headers(self):
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Access-Control-Allow-Methods', 'GET, POST, OPTIONS')
        self.send_header('Access-Control-Allow-Headers', 'Content-Type, Authorization')
        super().end_headers()

    def do_OPTIONS(self):
        self.send_response(200)
        self.end_headers()

    def do_GET(self):
        if self.path.startswith('/api/'):
            self.handle_api_request()
        else:
            super().do_GET()

    def handle_api_request(self):
        try:
            if self.path.startswith('/api/stock/') and '/quote' in self.path:
                self.handle_quote_request()
            elif self.path.startswith('/api/stock/') and '/profile' in self.path:
                self.handle_profile_request()
            elif self.path.startswith('/api/stock/') and '/news' in self.path:
                self.handle_news_request()
            elif self.path.startswith('/api/stock/') and '/indicators' in self.path:
                self.handle_indicators_request()
            elif self.path == '/api/health':
                self.handle_health_request()
            else:
                self.send_error(404, "Endpoint not found")
        except Exception as e:
            print(f"Error handling request: {e}")
            self.send_error(500, f"Internal server error: {str(e)}")

    def handle_quote_request(self):
        # Extract symbol from path like /api/stock/AAPL/quote
        path_parts = self.path.split('/')
        if len(path_parts) >= 4:
            symbol = path_parts[3]
            print(f"📈 Fetching quote for {symbol}")
            
            url = f"{FINNHUB_BASE_URL}/quote?symbol={symbol}&token={FINNHUB_API_KEY}"
            try:
                # Create SSL context to ignore certificate verification
                import ssl
                ssl_context = ssl.create_default_context()
                ssl_context.check_hostname = False
                ssl_context.verify_mode = ssl.CERT_NONE
                
                with urllib.request.urlopen(url, timeout=10, context=ssl_context) as response:
                    data = json.loads(response.read().decode())
                    print(f"✅ Got REAL quote for {symbol}: ${data.get('c', 'N/A')}")
                    
                    self.send_response(200)
                    self.send_header('Content-type', 'application/json')
                    self.end_headers()
                    self.wfile.write(json.dumps(data).encode())
            except URLError as e:
                print(f"❌ API error for {symbol}: {e}")
                # Return mock data
                mock_data = {
                    "c": 175.20 + (hash(symbol) % 100) / 10,
                    "d": -2.50 + (hash(symbol) % 50) / 10,
                    "dp": -1.5 + (hash(symbol) % 30) / 10,
                    "h": 180.0 + (hash(symbol) % 50) / 10,
                    "l": 170.0 + (hash(symbol) % 30) / 10,
                    "o": 175.0 + (hash(symbol) % 20) / 10,
                    "pc": 177.0 + (hash(symbol) % 40) / 10,
                    "t": int(time.time())
                }
                self.send_response(200)
                self.send_header('Content-type', 'application/json')
                self.end_headers()
                self.wfile.write(json.dumps(mock_data).encode())
        else:
            self.send_error(400, "Invalid symbol")

    def handle_profile_request(self):
        # Extract symbol from path like /api/stock/AAPL/profile
        path_parts = self.path.split('/')
        if len(path_parts) >= 4:
            symbol = path_parts[3]
            print(f"🏢 Fetching profile for {symbol}")
            
            url = f"{FINNHUB_BASE_URL}/stock/profile2?symbol={symbol}&token={FINNHUB_API_KEY}"
            try:
                with urllib.request.urlopen(url, timeout=10) as response:
                    data = json.loads(response.read().decode())
                    print(f"✅ Got profile for {symbol}")
                    
                    self.send_response(200)
                    self.send_header('Content-type', 'application/json')
                    self.end_headers()
                    self.wfile.write(json.dumps(data).encode())
            except URLError as e:
                print(f"❌ API error for {symbol}: {e}")
                # Return mock data
                mock_data = {
                    "name": f"{symbol} Corporation",
                    "ticker": symbol,
                    "country": "US",
                    "industry": "Technology",
                    "weburl": f"https://{symbol.lower()}.com",
                    "logo": "",
                    "marketCapitalization": 1000000000 + (hash(symbol) % 1000000000),
                    "shareOutstanding": 1000000 + (hash(symbol) % 1000000),
                    "description": f"{symbol} is a leading technology company."
                }
                self.send_response(200)
                self.send_header('Content-type', 'application/json')
                self.end_headers()
                self.wfile.write(json.dumps(mock_data).encode())
        else:
            self.send_error(400, "Invalid symbol")

    def handle_news_request(self):
        # Extract symbol from path like /api/stock/AAPL/news
        path_parts = self.path.split('/')
        if len(path_parts) >= 4:
            symbol = path_parts[3]
            print(f"📰 Fetching news for {symbol}")
            
            # Get date range - use proper date format (YYYY-MM-DD)
            import datetime
            to_date = datetime.datetime.now()
            from_date = to_date - datetime.timedelta(days=7)
            
            url = f"{FINNHUB_BASE_URL}/company-news?symbol={symbol}&from={from_date.strftime('%Y-%m-%d')}&to={to_date.strftime('%Y-%m-%d')}&token={FINNHUB_API_KEY}"
            try:
                with urllib.request.urlopen(url, timeout=10) as response:
                    data = json.loads(response.read().decode())
                    print(f"✅ Got {len(data)} news articles for {symbol}")
                    
                    self.send_response(200)
                    self.send_header('Content-type', 'application/json')
                    self.end_headers()
                    self.wfile.write(json.dumps(data).encode())
            except URLError as e:
                print(f"❌ API error for {symbol}: {e}")
                # Return mock data
                mock_data = [
                    {
                        "id": 1,
                        "headline": f"{symbol} reports strong quarterly earnings",
                        "summary": f"{symbol} exceeded expectations with robust growth.",
                        "url": f"https://news.example.com/{symbol.lower()}-earnings",
                        "datetime": int(time.time() * 1000),
                        "source": "Financial News"
                    }
                ]
                self.send_response(200)
                self.send_header('Content-type', 'application/json')
                self.end_headers()
                self.wfile.write(json.dumps(mock_data).encode())
        else:
            self.send_error(400, "Invalid symbol")

    def handle_indicators_request(self):
        # Extract symbol from path like /api/stock/AAPL/indicators
        path_parts = self.path.split('/')
        if len(path_parts) >= 4:
            symbol = path_parts[3]
            print(f"📊 Fetching indicators for {symbol}")
            
            url = f"{FINNHUB_BASE_URL}/indicator?symbol={symbol}&indicator=rsi&resolution=D&timeperiod=14&token={FINNHUB_API_KEY}"
            try:
                with urllib.request.urlopen(url, timeout=10) as response:
                    data = json.loads(response.read().decode())
                    print(f"✅ Got indicators for {symbol}")
                    
                    self.send_response(200)
                    self.send_header('Content-type', 'application/json')
                    self.end_headers()
                    self.wfile.write(json.dumps(data).encode())
            except URLError as e:
                print(f"❌ API error for {symbol}: {e}")
                # Return mock data
                mock_data = {
                    "rsi": 50 + (hash(symbol) % 30),
                    "macd": 1.2,
                    "sma_50": 170.5,
                    "sma_200": 165.8,
                    "volume": 1500000,
                    "volatility": 0.25
                }
                self.send_response(200)
                self.send_header('Content-type', 'application/json')
                self.end_headers()
                self.wfile.write(json.dumps(mock_data).encode())
        else:
            self.send_error(400, "Invalid symbol")

    def handle_health_request(self):
        print("🏥 Health check requested")
        data = {"status": "OK", "message": "Orion Backend is running!"}
        self.send_response(200)
        self.send_header('Content-type', 'application/json')
        self.end_headers()
        self.wfile.write(json.dumps(data).encode())

def start_backend():
    PORT = 3001
    with socketserver.TCPServer(("", PORT), CORSHTTPRequestHandler) as httpd:
        print(f"🚀 Orion Backend running on http://localhost:{PORT}")
        print(f"📈 Stock API endpoints available at /api/stock/:symbol/*")
        print(f"🏥 Health check at /api/health")
        httpd.serve_forever()

if __name__ == "__main__":
    start_backend()
