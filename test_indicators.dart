#!/usr/bin/env dart
/// Test script for Technical Indicators Calculation
/// Run with: dart run test_indicators.dart AAPL
/// Or for Indian stocks: dart run test_indicators.dart TCS.NS

import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math' as math;

void main(List<String> args) async {
  final symbol = args.isNotEmpty ? args[0] : 'AAPL';
  
  print('\n📈 ============================================');
  print('   TECHNICAL INDICATORS CALCULATION TEST');
  print('   Symbol: $symbol');
  print('============================================\n');
  
  try {
    print('1️⃣  Fetching historical data from Yahoo Finance...');
    final historicalData = await fetchHistoricalData(symbol);
    
    if (historicalData.isEmpty) {
      print('❌ No historical data retrieved. Please check:');
      print('   - Symbol format (e.g., AAPL for US, TCS.NS for Indian)');
      print('   - Internet connection');
      print('   - Yahoo Finance API availability');
      exit(1);
    }
    
    print('✅ Fetched ${historicalData.length} days of historical data\n');
    
    print('2️⃣  Calculating Technical Indicators...\n');
    final calculator = TechnicalIndicatorsCalculator();
    final indicators = calculator.calculateAllIndicators(historicalData);
    
    printIndicators(indicators, historicalData);
    
    print('\n✅ ============================================');
    print('   INDICATORS CALCULATED SUCCESSFULLY!');
    print('============================================\n');
    
  } catch (e, stackTrace) {
    print('\n❌ ERROR: $e');
    print('Stack: $stackTrace');
    exit(1);
  }
}

Future<List<Map<String, dynamic>>> fetchHistoricalData(String symbol) async {
  try {
    final now = DateTime.now();
    final startDate = now.subtract(Duration(days: 365));
    final period1 = (startDate.millisecondsSinceEpoch / 1000).floor();
    final period2 = (now.millisecondsSinceEpoch / 1000).floor();
    
    final encodedSymbol = Uri.encodeComponent(symbol.toUpperCase());
    final yahooUrl = 'https://query1.finance.yahoo.com/v8/finance/chart/$encodedSymbol?period1=$period1&period2=$period2&interval=1d';
    
    print('   📡 URL: $yahooUrl');
    
    final response = await http.get(
      Uri.parse(yahooUrl),
      headers: {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
        'Accept': 'application/json',
        'Accept-Language': 'en-US,en;q=0.9',
      },
    ).timeout(const Duration(seconds: 15));
    
    if (response.statusCode != 200) {
      print('   ❌ Yahoo Finance returned status ${response.statusCode}');
      return [];
    }
    
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    
    if (data['chart']?['error'] != null) {
      print('   ❌ Yahoo Finance error: ${data['chart']['error']}');
      return [];
    }
    
    if (data['chart']?['result'] != null && (data['chart']['result'] as List).isNotEmpty) {
      final result = data['chart']['result'][0];
      final timestamps = result['timestamp'] as List? ?? [];
      final quotes = result['indicators']?['quote']?[0];
      
      if (quotes == null) {
        print('   ❌ No quote data from Yahoo');
        return [];
      }
      
      final closes = quotes['close'] as List? ?? [];
      final highs = quotes['high'] as List? ?? [];
      final lows = quotes['low'] as List? ?? [];
      final opens = quotes['open'] as List? ?? [];
      final volumes = quotes['volume'] as List? ?? [];
      
      if (closes.isEmpty) {
        print('   ⚠️  Empty price data from Yahoo');
        return [];
      }
      
      final List<Map<String, dynamic>> ohlcData = [];
      for (int i = 0; i < closes.length; i++) {
        if (closes[i] != null) {
          ohlcData.add({
            'c': (closes[i] as num).toDouble(),
            'h': (highs[i] as num?)?.toDouble() ?? (closes[i] as num).toDouble(),
            'l': (lows[i] as num?)?.toDouble() ?? (closes[i] as num).toDouble(),
            'o': (opens[i] as num?)?.toDouble() ?? (closes[i] as num).toDouble(),
            't': timestamps[i] as int,
            'v': (volumes[i] as num?)?.toInt() ?? 0,
          });
        }
      }
      
      return ohlcData;
    }
    
    return [];
  } catch (e) {
    print('   ❌ Error fetching historical data: $e');
    return [];
  }
}

class TechnicalIndicatorsCalculator {
  double calculateRSI(List<Map<String, dynamic>> prices, {int period = 14}) {
    if (prices.length < period + 1) {
      return 50.0;
    }

    final recentPrices = prices.sublist(prices.length - period - 1);
    final closes = recentPrices.map((p) => (p['c'] as num).toDouble()).toList();

    final List<double> gains = [];
    final List<double> losses = [];

    for (int i = 1; i < closes.length; i++) {
      final change = closes[i] - closes[i - 1];
      if (change > 0) {
        gains.add(change);
        losses.add(0.0);
      } else {
        gains.add(0.0);
        losses.add(-change);
      }
    }

    double avgGain = gains.take(period).reduce((a, b) => a + b) / period;
    double avgLoss = losses.take(period).reduce((a, b) => a + b) / period;

    for (int i = period; i < gains.length; i++) {
      avgGain = (avgGain * (period - 1) + gains[i]) / period;
      avgLoss = (avgLoss * (period - 1) + losses[i]) / period;
    }

    if (avgLoss == 0) {
      return 100.0;
    }

    final rs = avgGain / avgLoss;
    final rsi = 100 - (100 / (1 + rs));

    return rsi;
  }

  double calculateSMA(List<Map<String, dynamic>> prices, {int period = 20}) {
    if (prices.length < period) {
      final availablePeriod = prices.length;
      if (availablePeriod == 0) return 0.0;
      final sum = prices.map((p) => (p['c'] as num).toDouble()).reduce((a, b) => a + b);
      return sum / availablePeriod;
    }

    final recentPrices = prices.sublist(prices.length - period);
    final sum = recentPrices.map((p) => (p['c'] as num).toDouble()).reduce((a, b) => a + b);
    return sum / period;
  }

  double calculateEMA(List<Map<String, dynamic>> prices, {int period = 12}) {
    if (prices.length < period) {
      return calculateSMA(prices, period: prices.length);
    }

    final closes = prices.map((p) => (p['c'] as num).toDouble()).toList();
    final multiplier = 2.0 / (period + 1);

    double ema = calculateSMA(prices.sublist(0, period), period: period);

    for (int i = period; i < closes.length; i++) {
      ema = (closes[i] * multiplier) + (ema * (1 - multiplier));
    }

    return ema;
  }

  Map<String, double> calculateMACD(
    List<Map<String, dynamic>> prices, {
    int fastPeriod = 12,
    int slowPeriod = 26,
    int signalPeriod = 9,
  }) {
    if (prices.length < slowPeriod) {
      return {
        'macd': 0.0,
        'signal': 0.0,
        'histogram': 0.0,
      };
    }

    final closes = prices.map((p) => (p['c'] as num).toDouble()).toList();
    
    final List<double> macdValues = [];
    
    for (int i = slowPeriod; i <= prices.length; i++) {
      final subPrices = prices.sublist(0, i);
      final fast = calculateEMA(subPrices, period: fastPeriod);
      final slow = calculateEMA(subPrices, period: slowPeriod);
      macdValues.add(fast - slow);
    }

    if (macdValues.isEmpty) {
      return {
        'macd': 0.0,
        'signal': 0.0,
        'histogram': 0.0,
      };
    }

    final macdLine = macdValues.last;

    double signalLine = macdLine;
    if (macdValues.length >= signalPeriod) {
      final signalMultiplier = 2.0 / (signalPeriod + 1);
      signalLine = macdValues.take(signalPeriod).reduce((a, b) => a + b) / signalPeriod;
      
      for (int i = signalPeriod; i < macdValues.length; i++) {
        signalLine = (macdValues[i] * signalMultiplier) + (signalLine * (1 - signalMultiplier));
      }
    } else if (macdValues.length > 1) {
      signalLine = macdValues.reduce((a, b) => a + b) / macdValues.length;
    }

    final histogram = macdLine - signalLine;

    return {
      'macd': macdLine,
      'signal': signalLine,
      'histogram': histogram,
    };
  }

  Map<String, dynamic> calculateAllIndicators(List<Map<String, dynamic>> historicalData) {
    if (historicalData.isEmpty) {
      return {
        'error': 'Insufficient historical data',
      };
    }

    try {
      final rsi = calculateRSI(historicalData, period: 14);
      final sma20 = calculateSMA(historicalData, period: 20);
      final sma50 = historicalData.length >= 50
          ? calculateSMA(historicalData, period: 50)
          : null;
      final sma200 = historicalData.length >= 200
          ? calculateSMA(historicalData, period: 200)
          : null;

      final ema12 = calculateEMA(historicalData, period: 12);
      final ema26 = calculateEMA(historicalData, period: 26);
      final macdData = calculateMACD(historicalData);

      final currentPrice = (historicalData.last['c'] as num).toDouble();

      return {
        'rsi': rsi,
        'sma20': sma20,
        'sma50': sma50,
        'sma200': sma200,
        'ema12': ema12,
        'ema26': ema26,
        'macd': macdData['macd']!,
        'macdSignal': macdData['signal']!,
        'macdHistogram': macdData['histogram']!,
        'currentPrice': currentPrice,
      };
    } catch (e) {
      return {
        'error': 'Error calculating indicators: $e',
      };
    }
  }
}

void printIndicators(Map<String, dynamic> indicators, List<Map<String, dynamic>> historicalData) {
  if (indicators.containsKey('error')) {
    print('❌ ${indicators['error']}');
    return;
  }

  final currentPrice = indicators['currentPrice'] as double;
  final rsi = indicators['rsi'] as double;
  final sma20 = indicators['sma20'] as double;
  final sma50 = indicators['sma50'];
  final sma200 = indicators['sma200'];
  final ema12 = indicators['ema12'] as double;
  final ema26 = indicators['ema26'] as double;
  final macd = indicators['macd'] as double;
  final macdSignal = indicators['macdSignal'] as double;
  final macdHistogram = indicators['macdHistogram'] as double;

  print('   ┌─────────────────────────────────────────────────────┐');
  print('   │  CURRENT PRICE                                      │');
  print('   ├─────────────────────────────────────────────────────┤');
  print('   │  Price: \$${currentPrice.toStringAsFixed(2)}');
  print('   └─────────────────────────────────────────────────────┘\n');

  print('   ┌─────────────────────────────────────────────────────┐');
  print('   │  MOMENTUM INDICATORS                                │');
  print('   ├─────────────────────────────────────────────────────┤');
  print('   │  RSI (14-period):  ${rsi.toStringAsFixed(2)}');
  final rsiSignal = rsi > 70 ? '🔴 Overbought' : (rsi < 30 ? '🟢 Oversold' : '🟡 Neutral');
  print('   │  Signal:          $rsiSignal');
  print('   └─────────────────────────────────────────────────────┘\n');

  print('   ┌─────────────────────────────────────────────────────┐');
  print('   │  TREND INDICATORS                                   │');
  print('   ├─────────────────────────────────────────────────────┤');
  print('   │  SMA 20-day:      \$${sma20.toStringAsFixed(2)}');
  final sma20Signal = currentPrice > sma20 ? '🟢 Above (Bullish)' : '🔴 Below (Bearish)';
  print('   │  vs Current:      $sma20Signal');
  
  if (sma50 != null) {
    print('   │  SMA 50-day:      \$${(sma50 as double).toStringAsFixed(2)}');
    final sma50Signal = currentPrice > sma50 ? '🟢 Above (Bullish)' : '🔴 Below (Bearish)';
    print('   │  vs Current:      $sma50Signal');
  }
  
  if (sma200 != null) {
    print('   │  SMA 200-day:     \$${(sma200 as double).toStringAsFixed(2)}');
    final sma200Signal = currentPrice > sma200 ? '🟢 Above (Bullish)' : '🔴 Below (Bearish)';
    print('   │  vs Current:      $sma200Signal');
  }
  
  print('   │                                                    │');
  print('   │  EMA 12-day:      \$${ema12.toStringAsFixed(2)}');
  print('   │  EMA 26-day:      \$${ema26.toStringAsFixed(2)}');
  print('   └─────────────────────────────────────────────────────┘\n');

  print('   ┌─────────────────────────────────────────────────────┐');
  print('   │  OSCILLATORS                                       │');
  print('   ├─────────────────────────────────────────────────────┤');
  print('   │  MACD Line:       ${macd.toStringAsFixed(4)}');
  print('   │  Signal Line:     ${macdSignal.toStringAsFixed(4)}');
  print('   │  Histogram:       ${macdHistogram.toStringAsFixed(4)}');
  final macdSignalText = macd > macdSignal ? '🟢 Bullish' : '🔴 Bearish';
  print('   │  Signal:          $macdSignalText');
  print('   └─────────────────────────────────────────────────────┘\n');

  print('   📊 Data Summary:');
  print('      • Historical Data Points: ${historicalData.length}');
  print('      • Date Range: ${_formatDate(historicalData.first['t'] as int)} to ${_formatDate(historicalData.last['t'] as int)}');
}

String _formatDate(int timestamp) {
  final date = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
  return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}


