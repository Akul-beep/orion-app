#!/usr/bin/env python3
"""Test script for Technical Indicators Calculation
Run with: python3 test_indicators.py AAPL
Or for Indian stocks: python3 test_indicators.py TCS.NS"""

import sys
import requests
import json
import urllib3
from datetime import datetime, timedelta
from typing import List, Dict

# Disable SSL warnings for testing
urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)

def fetch_historical_data(symbol: str) -> List[Dict]:
    """Fetch historical data from Yahoo Finance"""
    try:
        now = datetime.now()
        start_date = now - timedelta(days=365)
        period1 = int(start_date.timestamp())
        period2 = int(now.timestamp())
        
        encoded_symbol = symbol.upper()
        yahoo_url = f'https://query1.finance.yahoo.com/v8/finance/chart/{encoded_symbol}?period1={period1}&period2={period2}&interval=1d'
        
        print(f'   📡 URL: {yahoo_url}')
        
        response = requests.get(
            yahoo_url,
            headers={
                'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
                'Accept': 'application/json',
                'Accept-Language': 'en-US,en;q=0.9',
            },
            timeout=15,
            verify=False  # Disable SSL verification for testing
        )
        
        if response.status_code != 200:
            print(f'   ❌ Yahoo Finance returned status {response.status_code}')
            return []
        
        data = response.json()
        
        if data.get('chart', {}).get('error'):
            print(f"   ❌ Yahoo Finance error: {data['chart']['error']}")
            return []
        
        result = data.get('chart', {}).get('result', [])
        if not result:
            print('   ⚠️  No result data in Yahoo response')
            return []
        
        result = result[0]
        timestamps = result.get('timestamp', [])
        quotes = result.get('indicators', {}).get('quote', [{}])[0]
        
        if not quotes:
            print('   ❌ No quote data from Yahoo')
            return []
        
        closes = quotes.get('close', [])
        highs = quotes.get('high', [])
        lows = quotes.get('low', [])
        opens = quotes.get('open', [])
        volumes = quotes.get('volume', [])
        
        if not closes:
            print('   ⚠️  Empty price data from Yahoo')
            return []
        
        ohlc_data = []
        for i in range(len(closes)):
            if closes[i] is not None:
                ohlc_data.append({
                    'c': float(closes[i]),
                    'h': float(highs[i]) if highs[i] is not None else float(closes[i]),
                    'l': float(lows[i]) if lows[i] is not None else float(closes[i]),
                    'o': float(opens[i]) if opens[i] is not None else float(closes[i]),
                    't': int(timestamps[i]),
                    'v': int(volumes[i]) if volumes[i] is not None else 0,
                })
        
        return ohlc_data
    except Exception as e:
        print(f'   ❌ Error fetching historical data: {e}')
        return []

class TechnicalIndicatorsCalculator:
    def calculate_rsi(self, prices: List[Dict], period: int = 14) -> float:
        """Calculate RSI using Wilder's smoothing method"""
        if len(prices) < period + 1:
            return 50.0
        
        recent_prices = prices[-(period + 1):]
        closes = [p['c'] for p in recent_prices]
        
        gains = []
        losses = []
        
        for i in range(1, len(closes)):
            change = closes[i] - closes[i - 1]
            gains.append(change if change > 0 else 0.0)
            losses.append(-change if change < 0 else 0.0)
        
        avg_gain = sum(gains[:period]) / period
        avg_loss = sum(losses[:period]) / period
        
        for i in range(period, len(gains)):
            avg_gain = (avg_gain * (period - 1) + gains[i]) / period
            avg_loss = (avg_loss * (period - 1) + losses[i]) / period
        
        if avg_loss == 0:
            return 100.0
        
        rs = avg_gain / avg_loss
        rsi = 100 - (100 / (1 + rs))
        
        return rsi
    
    def calculate_sma(self, prices: List[Dict], period: int = 20) -> float:
        """Calculate Simple Moving Average"""
        if len(prices) < period:
            if len(prices) == 0:
                return 0.0
            return sum(p['c'] for p in prices) / len(prices)
        
        recent_prices = prices[-period:]
        return sum(p['c'] for p in recent_prices) / period
    
    def calculate_ema(self, prices: List[Dict], period: int = 12) -> float:
        """Calculate Exponential Moving Average"""
        if len(prices) < period:
            return self.calculate_sma(prices, period=len(prices))
        
        closes = [p['c'] for p in prices]
        multiplier = 2.0 / (period + 1)
        
        ema = self.calculate_sma(prices[:period], period=period)
        
        for i in range(period, len(closes)):
            ema = (closes[i] * multiplier) + (ema * (1 - multiplier))
        
        return ema
    
    def calculate_macd(self, prices: List[Dict], fast_period: int = 12, 
                      slow_period: int = 26, signal_period: int = 9) -> Dict[str, float]:
        """Calculate MACD with signal line"""
        if len(prices) < slow_period:
            return {'macd': 0.0, 'signal': 0.0, 'histogram': 0.0}
        
        macd_values = []
        
        for i in range(slow_period, len(prices) + 1):
            sub_prices = prices[:i]
            fast = self.calculate_ema(sub_prices, period=fast_period)
            slow = self.calculate_ema(sub_prices, period=slow_period)
            macd_values.append(fast - slow)
        
        if not macd_values:
            return {'macd': 0.0, 'signal': 0.0, 'histogram': 0.0}
        
        macd_line = macd_values[-1]
        
        signal_line = macd_line
        if len(macd_values) >= signal_period:
            signal_multiplier = 2.0 / (signal_period + 1)
            signal_line = sum(macd_values[:signal_period]) / signal_period
            
            for i in range(signal_period, len(macd_values)):
                signal_line = (macd_values[i] * signal_multiplier) + (signal_line * (1 - signal_multiplier))
        elif len(macd_values) > 1:
            signal_line = sum(macd_values) / len(macd_values)
        
        histogram = macd_line - signal_line
        
        return {
            'macd': macd_line,
            'signal': signal_line,
            'histogram': histogram,
        }
    
    def calculate_all_indicators(self, historical_data: List[Dict]) -> Dict:
        """Calculate all technical indicators"""
        if not historical_data:
            return {'error': 'Insufficient historical data'}
        
        try:
            rsi = self.calculate_rsi(historical_data, period=14)
            sma20 = self.calculate_sma(historical_data, period=20)
            sma50 = self.calculate_sma(historical_data, period=50) if len(historical_data) >= 50 else None
            sma200 = self.calculate_sma(historical_data, period=200) if len(historical_data) >= 200 else None
            
            ema12 = self.calculate_ema(historical_data, period=12)
            ema26 = self.calculate_ema(historical_data, period=26)
            macd_data = self.calculate_macd(historical_data)
            
            current_price = historical_data[-1]['c']
            
            return {
                'rsi': rsi,
                'sma20': sma20,
                'sma50': sma50,
                'sma200': sma200,
                'ema12': ema12,
                'ema26': ema26,
                'macd': macd_data['macd'],
                'macdSignal': macd_data['signal'],
                'macdHistogram': macd_data['histogram'],
                'currentPrice': current_price,
            }
        except Exception as e:
            return {'error': f'Error calculating indicators: {e}'}

def format_date(timestamp: int) -> str:
    """Format timestamp to date string"""
    date = datetime.fromtimestamp(timestamp)
    return date.strftime('%Y-%m-%d')

def print_indicators(indicators: Dict, historical_data: List[Dict]):
    """Print indicators in a formatted way"""
    if 'error' in indicators:
        print(f"❌ {indicators['error']}")
        return
    
    current_price = indicators['currentPrice']
    rsi = indicators['rsi']
    sma20 = indicators['sma20']
    sma50 = indicators['sma50']
    sma200 = indicators['sma200']
    ema12 = indicators['ema12']
    ema26 = indicators['ema26']
    macd = indicators['macd']
    macd_signal = indicators['macdSignal']
    macd_histogram = indicators['macdHistogram']
    
    print('   ┌─────────────────────────────────────────────────────┐')
    print('   │  CURRENT PRICE                                      │')
    print('   ├─────────────────────────────────────────────────────┤')
    print(f'   │  Price: ${current_price:.2f}')
    print('   └─────────────────────────────────────────────────────┘\n')
    
    print('   ┌─────────────────────────────────────────────────────┐')
    print('   │  MOMENTUM INDICATORS                                │')
    print('   ├─────────────────────────────────────────────────────┤')
    print(f'   │  RSI (14-period):  {rsi:.2f}')
    rsi_signal = '🔴 Overbought' if rsi > 70 else ('🟢 Oversold' if rsi < 30 else '🟡 Neutral')
    print(f'   │  Signal:          {rsi_signal}')
    print('   └─────────────────────────────────────────────────────┘\n')
    
    print('   ┌─────────────────────────────────────────────────────┐')
    print('   │  TREND INDICATORS                                   │')
    print('   ├─────────────────────────────────────────────────────┤')
    print(f'   │  SMA 20-day:      ${sma20:.2f}')
    sma20_signal = '🟢 Above (Bullish)' if current_price > sma20 else '🔴 Below (Bearish)'
    print(f'   │  vs Current:      {sma20_signal}')
    
    if sma50 is not None:
        print(f'   │  SMA 50-day:      ${sma50:.2f}')
        sma50_signal = '🟢 Above (Bullish)' if current_price > sma50 else '🔴 Below (Bearish)'
        print(f'   │  vs Current:      {sma50_signal}')
    
    if sma200 is not None:
        print(f'   │  SMA 200-day:     ${sma200:.2f}')
        sma200_signal = '🟢 Above (Bullish)' if current_price > sma200 else '🔴 Below (Bearish)'
        print(f'   │  vs Current:      {sma200_signal}')
    
    print('   │                                                    │')
    print(f'   │  EMA 12-day:      ${ema12:.2f}')
    print(f'   │  EMA 26-day:      ${ema26:.2f}')
    print('   └─────────────────────────────────────────────────────┘\n')
    
    print('   ┌─────────────────────────────────────────────────────┐')
    print('   │  OSCILLATORS                                       │')
    print('   ├─────────────────────────────────────────────────────┤')
    print(f'   │  MACD Line:       {macd:.4f}')
    print(f'   │  Signal Line:     {macd_signal:.4f}')
    print(f'   │  Histogram:       {macd_histogram:.4f}')
    macd_signal_text = '🟢 Bullish' if macd > macd_signal else '🔴 Bearish'
    print(f'   │  Signal:          {macd_signal_text}')
    print('   └─────────────────────────────────────────────────────┘\n')
    
    print('   📊 Data Summary:')
    print(f'      • Historical Data Points: {len(historical_data)}')
    print(f'      • Date Range: {format_date(historical_data[0]["t"])} to {format_date(historical_data[-1]["t"])}')

def main():
    symbol = sys.argv[1] if len(sys.argv) > 1 else 'AAPL'
    
    print('\n📈 ============================================')
    print('   TECHNICAL INDICATORS CALCULATION TEST')
    print(f'   Symbol: {symbol}')
    print('============================================\n')
    
    try:
        print('1️⃣  Fetching historical data from Yahoo Finance...')
        historical_data = fetch_historical_data(symbol)
        
        if not historical_data:
            print('❌ No historical data retrieved. Please check:')
            print('   - Symbol format (e.g., AAPL for US, TCS.NS for Indian)')
            print('   - Internet connection')
            print('   - Yahoo Finance API availability')
            sys.exit(1)
        
        print(f'✅ Fetched {len(historical_data)} days of historical data\n')
        
        print('2️⃣  Calculating Technical Indicators...\n')
        calculator = TechnicalIndicatorsCalculator()
        indicators = calculator.calculate_all_indicators(historical_data)
        
        print_indicators(indicators, historical_data)
        
        print('\n✅ ============================================')
        print('   INDICATORS CALCULATED SUCCESSFULLY!')
        print('============================================\n')
        
    except Exception as e:
        print(f'\n❌ ERROR: {e}')
        import traceback
        traceback.print_exc()
        sys.exit(1)

if __name__ == '__main__':
    main()


