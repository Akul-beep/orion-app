#!/usr/bin/env dart
/// Comprehensive Test for Indian Stock Market Data - TCS.NS
/// Run with: dart run test_tcs_comprehensive.dart

import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;

void main(List<String> args) async {
  final symbol = args.isNotEmpty ? args[0] : 'TCS';
  
  print('\n🇮🇳 ============================================');
  print('   COMPREHENSIVE INDIAN STOCK DATA TEST');
  print('   Testing: $symbol (Tata Consultancy Services)');
  print('============================================\n');
  
  try {
    final tester = IndianStockDataFetcher();
    
    print('📊 Fetching ALL financial metrics for $symbol...\n');
    
    // Fetch comprehensive data
    final data = await tester.fetchAllData(symbol);
    
    // Display results
    printResults(data);
    
    print('\n✅ ============================================');
    print('   TEST COMPLETED SUCCESSFULLY!');
    print('============================================\n');
    
  } catch (e, stackTrace) {
    print('\n❌ ERROR: $e');
    print('Stack: $stackTrace');
    exit(1);
  }
}

void printResults(Map<String, dynamic> data) {
  print('\n📈 ========== STOCK DATA FOR ${data['symbol']} ==========\n');
  
  print('🏢 COMPANY INFORMATION:');
  print('   Name: ${data['name'] ?? 'N/A'}');
  print('   Industry: ${data['industry'] ?? 'N/A'}');
  print('   Exchange: ${data['exchange'] ?? 'N/A'}\n');
  
  print('💰 PRICE DATA:');
  print('   Current Price: ₹${formatPrice(data['currentPrice'])}');
  print('   Previous Close: ₹${formatPrice(data['previousClose'])}');
  print('   Change: ${formatChange(data['change'], data['changePercent'])}');
  print('   High: ₹${formatPrice(data['high'])}');
  print('   Low: ₹${formatPrice(data['low'])}');
  print('   Open: ₹${formatPrice(data['open'])}');
  print('   Volume: ${formatNumber(data['volume'])}\n');
  
  print('📊 FINANCIAL METRICS:');
  print('   ┌─────────────────────────────────────────┐');
  print('   │ Market Cap: ${formatMarketCap(data['marketCap'])}');
  print('   │ P/E Ratio: ${formatMetric(data['pe'] ?? data['peRatio'])}');
  print('   │ Dividend Yield: ${formatPercent(data['dividendYield'])}');
  print('   │ Beta: ${formatMetric(data['beta'])}');
  print('   │ EPS: ₹${formatPrice(data['eps'])}');
  print('   │ Price to Book: ${formatMetric(data['priceToBook'])}');
  print('   │ Revenue: ${formatRevenue(data['revenue'])}');
  print('   │ Profit Margin: ${formatPercent(data['profitMargin'])}');
  print('   │ ROE: ${formatPercent(data['returnOnEquity'])}');
  print('   │ Debt/Equity: ${formatMetric(data['debtToEquity'])}');
  print('   └─────────────────────────────────────────┘\n');
  
  print('📋 ADDITIONAL DATA:');
  print('   Shares Outstanding: ${formatNumber(data['sharesOutstanding'])}');
  print('   Face Value: ₹${formatPrice(data['faceValue'])}');
  if (data['yearHigh'] != null) {
    print('   52W High: ₹${formatPrice(data['yearHigh'])}');
  }
  if (data['yearLow'] != null) {
    print('   52W Low: ₹${formatPrice(data['yearLow'])}');
  }
  print('');
}

String formatPrice(dynamic value) {
  if (value == null) return 'N/A';
  final num = value is num ? value.toDouble() : double.tryParse(value.toString());
  return num?.toStringAsFixed(2) ?? 'N/A';
}

String formatChange(dynamic change, dynamic percent) {
  if (change == null || percent == null) return 'N/A';
  final c = change is num ? change.toDouble() : double.tryParse(change.toString());
  final p = percent is num ? percent.toDouble() : double.tryParse(percent.toString());
  if (c == null || p == null) return 'N/A';
  final sign = c >= 0 ? '+' : '';
  return '$sign₹${c.toStringAsFixed(2)} ($sign${p.toStringAsFixed(2)}%)';
}

String formatMarketCap(dynamic value) {
  if (value == null) return 'N/A';
  final num = value is num ? value.toDouble() : double.tryParse(value.toString());
  if (num == null) return 'N/A';
  
  // If already in millions, format accordingly
  if (num >= 1e6) {
    if (num >= 1e9) return '₹${(num / 1e9).toStringAsFixed(2)}B';
    return '₹${(num / 1e6).toStringAsFixed(2)}M';
  }
  
  // If in actual value (not millions), convert
  if (num >= 1e12) return '₹${(num / 1e12).toStringAsFixed(2)}T';
  if (num >= 1e9) return '₹${(num / 1e9).toStringAsFixed(2)}B';
  if (num >= 1e6) return '₹${(num / 1e6).toStringAsFixed(2)}M';
  return '₹${num.toStringAsFixed(2)}';
}

String formatRevenue(dynamic value) {
  if (value == null) return 'N/A';
  final num = value is num ? value.toDouble() : double.tryParse(value.toString());
  if (num == null) return 'N/A';
  
  // Revenue might be in billions or millions
  if (num >= 1e9) return '₹${(num / 1e9).toStringAsFixed(2)}B';
  if (num >= 1e6) return '₹${(num / 1e6).toStringAsFixed(2)}M';
  return '₹${num.toStringAsFixed(2)}';
}

String formatPercent(dynamic value) {
  if (value == null) return 'N/A';
  final num = value is num ? value.toDouble() : double.tryParse(value.toString());
  if (num == null) return 'N/A';
  
  // If value is already a percentage (0-100), use as is
  // If value is a decimal (0-1), convert to percentage
  final percent = num > 1 ? num : num * 100;
  return '${percent.toStringAsFixed(2)}%';
}

String formatMetric(dynamic value) {
  if (value == null) return 'N/A';
  final num = value is num ? value.toDouble() : double.tryParse(value.toString());
  return num?.toStringAsFixed(2) ?? 'N/A';
}

String formatNumber(dynamic value) {
  if (value == null) return 'N/A';
  final num = value is num ? value.toDouble() : double.tryParse(value.toString());
  if (num == null) return 'N/A';
  
  if (num >= 1e9) return '${(num / 1e9).toStringAsFixed(2)}B';
  if (num >= 1e6) return '${(num / 1e6).toStringAsFixed(2)}M';
  if (num >= 1e3) return '${(num / 1e3).toStringAsFixed(2)}K';
  return num.toStringAsFixed(0);
}

/// Comprehensive Indian Stock Data Fetcher
/// Uses NSE India API + Yahoo Finance + Screener.in
class IndianStockDataFetcher {
  static String? _sessionCookie;
  static DateTime? _cookieExpiry;
  
  Future<String?> _getSessionCookie() async {
    if (_sessionCookie != null && 
        _cookieExpiry != null && 
        DateTime.now().isBefore(_cookieExpiry!)) {
      return _sessionCookie;
    }
    
    try {
      print('🍪 Getting NSE session cookie...');
      final response = await http.get(
        Uri.parse('https://www.nseindia.com'),
        headers: {
          'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36',
        },
      ).timeout(const Duration(seconds: 10));
      
      final cookies = response.headers['set-cookie'];
      if (cookies != null) {
        _sessionCookie = cookies;
        _cookieExpiry = DateTime.now().add(const Duration(minutes: 30));
        print('✅ Got session cookie');
        return _sessionCookie;
      }
    } catch (e) {
      print('⚠️  Cookie error: $e');
    }
    return null;
  }
  
  Future<Map<String, String>> _getNSEHeaders() async {
    final cookie = await _getSessionCookie();
    return {
      'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36',
      'Accept': 'application/json',
      'Referer': 'https://www.nseindia.com/',
      'Origin': 'https://www.nseindia.com',
      if (cookie != null) 'Cookie': cookie,
    };
  }
  
  Future<Map<String, dynamic>> fetchAllData(String symbol) async {
    final cleanSymbol = symbol.replaceAll('.NS', '').replaceAll('.BO', '').toUpperCase();
    final data = <String, dynamic>{
      'symbol': '$cleanSymbol.NS',
      'name': cleanSymbol,
    };
    
    print('📡 Fetching from NSE India...');
    final nseData = await _fetchFromNSE(cleanSymbol);
    data.addAll(nseData);
    
    print('📡 Fetching from Yahoo Finance...');
    final yahooData = await _fetchFromYahoo('$cleanSymbol.NS');
    // Merge Yahoo data (only add if not already present or if Yahoo has better data)
    yahooData.forEach((key, value) {
      if (value != null && (!data.containsKey(key) || data[key] == null)) {
        data[key] = value;
      }
    });
    
    print('📡 Fetching from Screener.in...');
    try {
      final screenerData = await _fetchFromScreener(cleanSymbol);
      // Screener.in has priority for certain metrics
      screenerData.forEach((key, value) {
        if (value != null) {
          if (key == 'dividendYield' || 
              key == 'returnOnEquity' || 
              key == 'profitMargin' || 
              key == 'revenue' ||
              key == 'priceToSales' ||
              key == 'debtToEquity' ||
              key == 'priceToBook') {
            data[key] = value;
          } else if (!data.containsKey(key) || data[key] == null) {
            data[key] = value;
          }
        }
      });
    } catch (e) {
      print('⚠️  Screener.in failed: $e (continuing...)');
    }
    
    return data;
  }
  
  Future<Map<String, dynamic>> _fetchFromNSE(String symbol) async {
    final url = 'https://www.nseindia.com/api/quote-equity?symbol=$symbol';
    final headers = await _getNSEHeaders();
    
    final response = await http.get(Uri.parse(url), headers: headers)
        .timeout(const Duration(seconds: 15));
    
    if (response.statusCode != 200) {
      throw Exception('NSE API failed: ${response.statusCode}');
    }
    
    final data = jsonDecode(utf8.decode(response.bodyBytes));
    final info = data['info'] ?? {};
    final metadata = data['metadata'] ?? {};
    final priceInfo = data['priceInfo'] ?? {};
    final securityInfo = data['securityInfo'] ?? {};
    
    final currentPrice = (priceInfo['lastPrice'] ?? 0).toDouble();
    final previousClose = (priceInfo['previousClose'] ?? currentPrice).toDouble();
    final change = currentPrice - previousClose;
    final changePercent = previousClose > 0 ? (change / previousClose) * 100 : 0.0;
    final sharesOutstanding = (securityInfo['issuedSize'] ?? metadata['issuedSize'] ?? 0).toDouble();
    
    // Market Cap
    double marketCap = 0.0;
    if (metadata['marketCap'] != null) {
      marketCap = (metadata['marketCap'] as num).toDouble();
      if (marketCap > 1e12) marketCap /= 1e6;
      else if (marketCap > 1e9) marketCap /= 1e6;
    } else if (currentPrice > 0 && sharesOutstanding > 0) {
      marketCap = (currentPrice * sharesOutstanding) / 1e6;
    }
    
    // P/E Ratio
    double? pe;
    if (metadata['pdSymbolPe'] != null) {
      final peValue = (metadata['pdSymbolPe'] as num).toDouble();
      if (peValue > 0 && peValue < 10000) {
        pe = peValue;
      }
    }
    
    // EPS
    double? eps;
    if (pe != null && pe > 0 && currentPrice > 0) {
      eps = currentPrice / pe;
    }
    
    // Price to Book
    double? priceToBook;
    final faceValue = (securityInfo['faceValue'] ?? 1.0).toDouble();
    if (currentPrice > 0 && faceValue > 0) {
      final pb = currentPrice / faceValue;
      if (pb > 0 && pb < 1000) {
        priceToBook = pb;
      }
    }
    
    return {
      'name': info['companyName'] ?? symbol,
      'industry': info['industry'] ?? '',
      'exchange': 'NSE',
      'currentPrice': currentPrice,
      'previousClose': previousClose,
      'change': change,
      'changePercent': changePercent,
      'high': (priceInfo['intraDayHighLow']?['max'] ?? currentPrice).toDouble(),
      'low': (priceInfo['intraDayHighLow']?['min'] ?? currentPrice).toDouble(),
      'open': (priceInfo['open'] ?? currentPrice).toDouble(),
      'volume': (priceInfo['totalTradedVolume'] ?? 0).toInt(),
      'marketCap': marketCap > 0 ? marketCap : null,
      'pe': pe,
      'peRatio': pe,
      'eps': eps,
      'priceToBook': priceToBook,
      'sharesOutstanding': sharesOutstanding > 0 ? sharesOutstanding : null,
      'faceValue': faceValue,
      'yearHigh': (priceInfo['weekHighLow']?['max'] as num?)?.toDouble(),
      'yearLow': (priceInfo['weekHighLow']?['min'] as num?)?.toDouble(),
    };
  }
  
  Future<Map<String, dynamic>> _fetchFromYahoo(String symbol) async {
    final url = 'https://query1.finance.yahoo.com/v10/finance/quoteSummary/$symbol?modules=defaultKeyStatistics,financialData,summaryDetail';
    
    final response = await http.get(
      Uri.parse(url),
      headers: {
        'User-Agent': 'Mozilla/5.0',
        'Accept': 'application/json',
      },
    ).timeout(const Duration(seconds: 10));
    
    if (response.statusCode != 200) {
      return {};
    }
    
    final data = jsonDecode(response.body);
    final result = data['quoteSummary']?['result']?[0];
    if (result == null) return {};
    
    final keyStats = result['defaultKeyStatistics'] ?? {};
    final financialData = result['financialData'] ?? {};
    final summaryDetail = result['summaryDetail'] ?? {};
    
    final metrics = <String, dynamic>{};
    
    // Beta
    final beta = _extractValue(keyStats['beta']);
    if (beta != null && beta >= 0 && beta <= 10) {
      metrics['beta'] = beta;
    }
    
    // Dividend Yield
    var divYield = _extractValue(summaryDetail['dividendYield']) ?? 
                  _extractValue(keyStats['yield']);
    if (divYield != null && divYield >= 0 && divYield <= 1) {
      metrics['dividendYield'] = divYield;
    }
    
    // Revenue
    final revenue = _extractValue(financialData['totalRevenue']);
    if (revenue != null && revenue > 0) {
      metrics['revenue'] = revenue / 1e9; // Convert to billions
    }
    
    // Profit Margin
    final margin = _extractValue(financialData['profitMargins']);
    if (margin != null && margin >= -10 && margin <= 10) {
      metrics['profitMargin'] = margin > 1 ? margin / 100 : margin;
    }
    
    // ROE
    final roe = _extractValue(keyStats['returnOnEquity']);
    if (roe != null && roe >= -10 && roe <= 10) {
      metrics['returnOnEquity'] = roe > 1 ? roe / 100 : roe;
    }
    
    // Debt to Equity
    final debtEq = _extractValue(keyStats['debtToEquity']);
    if (debtEq != null && debtEq >= 0 && debtEq <= 100) {
      metrics['debtToEquity'] = debtEq;
    }
    
    return metrics;
  }
  
  Future<Map<String, dynamic>> _fetchFromScreener(String symbol) async {
    // Screener.in requires web scraping - simplified version
    // In production, use the actual ScreenerInService
    final url = 'https://www.screener.in/company/$symbol/';
    
    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {'User-Agent': 'Mozilla/5.0'},
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        // This is a simplified version - actual implementation would parse HTML
        // For now, return empty - the actual ScreenerInService handles this
        return {};
      }
    } catch (e) {
      // Silently fail - Screener.in is optional
    }
    
    return {};
  }
  
  double? _extractValue(dynamic value) {
    if (value == null) return null;
    try {
      num? numValue;
      if (value is Map) {
        numValue = value['raw'] as num?;
      } else if (value is num) {
        numValue = value;
      } else {
        return null;
      }
      if (numValue != null) {
        final doubleValue = numValue.toDouble();
        if (doubleValue.isFinite && !doubleValue.isNaN) {
          return doubleValue;
        }
      }
    } catch (e) {
      return null;
    }
    return null;
  }
}

