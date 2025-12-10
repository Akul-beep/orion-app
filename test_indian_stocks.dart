#!/usr/bin/env dart
/// Test script for Indian Stock Market Data
/// Run with: dart run test_indian_stocks.dart TCS.NS

import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main(List<String> args) async {
  final symbol = args.isNotEmpty ? args[0] : 'TCS.NS';
  
  print('\n🇮🇳 ============================================');
  print('   INDIAN STOCK MARKET DATA TEST');
  print('   Symbol: $symbol');
  print('============================================\n');
  
  try {
    // Test the Indian Stock API Service
    final service = IndianStockTester();
    
    print('📊 Fetching comprehensive data for $symbol...\n');
    
    // Get Quote
    print('1️⃣  Fetching Quote...');
    final quote = await service.getQuote(symbol);
    printQuote(quote);
    
    // Get Financial Metrics
    print('\n2️⃣  Fetching Financial Metrics...');
    final metrics = await service.getFinancialMetrics(symbol);
    printMetrics(metrics);
    
    // Get Company Profile
    print('\n3️⃣  Fetching Company Profile...');
    final profile = await service.getCompanyProfile(symbol);
    printProfile(profile);
    
    print('\n✅ ============================================');
    print('   ALL DATA FETCHED SUCCESSFULLY!');
    print('============================================\n');
    
  } catch (e, stackTrace) {
    print('\n❌ ERROR: $e');
    print('Stack: $stackTrace');
    exit(1);
  }
}

void printQuote(Map<String, dynamic> quote) {
  print('   ┌─────────────────────────────────────┐');
  print('   │ Current Price: ₹${quote['currentPrice']?.toStringAsFixed(2) ?? 'N/A'}');
  print('   │ Change: ${quote['change'] != null ? (quote['change'] >= 0 ? '+' : '') : ''}${quote['change']?.toStringAsFixed(2) ?? 'N/A'} (${quote['changePercent']?.toStringAsFixed(2) ?? 'N/A'}%)');
  print('   │ High: ₹${quote['high']?.toStringAsFixed(2) ?? 'N/A'}');
  print('   │ Low: ₹${quote['low']?.toStringAsFixed(2) ?? 'N/A'}');
  print('   │ Volume: ${formatNumber(quote['volume'])}');
  print('   └─────────────────────────────────────┘');
}

void printMetrics(Map<String, dynamic> metrics) {
  print('   ┌─────────────────────────────────────┐');
  print('   │ MARKET CAP: ${formatMarketCap(metrics['marketCap'])}');
  print('   │ P/E RATIO: ${metrics['pe']?.toStringAsFixed(2) ?? metrics['peRatio']?.toStringAsFixed(2) ?? 'N/A'}');
  print('   │ DIVIDEND YIELD: ${formatPercent(metrics['dividendYield'])}');
  print('   │ BETA: ${metrics['beta']?.toStringAsFixed(2) ?? 'N/A'}');
  print('   │ EPS: ₹${metrics['eps']?.toStringAsFixed(2) ?? 'N/A'}');
  print('   │ PRICE TO BOOK: ${metrics['priceToBook']?.toStringAsFixed(2) ?? 'N/A'}');
  print('   │ REVENUE: ${formatRevenue(metrics['revenue'])}');
  print('   │ PROFIT MARGIN: ${formatPercent(metrics['profitMargin'])}');
  print('   │ ROE: ${formatPercent(metrics['returnOnEquity'])}');
  print('   │ DEBT/EQUITY: ${metrics['debtToEquity']?.toStringAsFixed(2) ?? 'N/A'}');
  print('   └─────────────────────────────────────┘');
}

void printProfile(Map<String, dynamic> profile) {
  print('   ┌─────────────────────────────────────┐');
  print('   │ Company: ${profile['name'] ?? 'N/A'}');
  print('   │ Industry: ${profile['industry'] ?? 'N/A'}');
  print('   │ Exchange: ${profile['exchange'] ?? 'N/A'}');
  print('   │ Market Cap: ${formatMarketCap(profile['marketCapitalization'])}');
  print('   │ Shares Outstanding: ${formatNumber(profile['shareOutstanding'])}');
  print('   └─────────────────────────────────────┘');
}

String formatMarketCap(dynamic value) {
  if (value == null) return 'N/A';
  final num = value is num ? value.toDouble() : double.tryParse(value.toString());
  if (num == null) return 'N/A';
  
  if (num >= 1e12) return '₹${(num / 1e12).toStringAsFixed(2)}T';
  if (num >= 1e9) return '₹${(num / 1e9).toStringAsFixed(2)}B';
  if (num >= 1e6) return '₹${(num / 1e6).toStringAsFixed(2)}M';
  return '₹${num.toStringAsFixed(2)}';
}

String formatRevenue(dynamic value) {
  if (value == null) return 'N/A';
  final num = value is num ? value.toDouble() : double.tryParse(value.toString());
  if (num == null) return 'N/A';
  
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

String formatNumber(dynamic value) {
  if (value == null) return 'N/A';
  final num = value is num ? value.toDouble() : double.tryParse(value.toString());
  if (num == null) return 'N/A';
  
  if (num >= 1e9) return '${(num / 1e9).toStringAsFixed(2)}B';
  if (num >= 1e6) return '${(num / 1e6).toStringAsFixed(2)}M';
  if (num >= 1e3) return '${(num / 1e3).toStringAsFixed(2)}K';
  return num.toStringAsFixed(0);
}

/// Indian Stock API Tester
class IndianStockTester {
  static String? _sessionCookie;
  static DateTime? _cookieExpiry;
  
  Future<String?> _getSessionCookie() async {
    if (_sessionCookie != null && 
        _cookieExpiry != null && 
        DateTime.now().isBefore(_cookieExpiry!)) {
      return _sessionCookie;
    }
    
    try {
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
        return _sessionCookie;
      }
    } catch (e) {
      print('⚠️  Cookie error: $e');
    }
    return null;
  }
  
  Future<Map<String, String>> _getHeaders() async {
    final cookie = await _getSessionCookie();
    return {
      'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36',
      'Accept': 'application/json',
      'Referer': 'https://www.nseindia.com/',
      'Origin': 'https://www.nseindia.com',
      if (cookie != null) 'Cookie': cookie,
    };
  }
  
  Future<Map<String, dynamic>> getQuote(String symbol) async {
    final cleanSymbol = symbol.replaceAll('.NS', '').replaceAll('.BO', '').toUpperCase();
    final url = 'https://www.nseindia.com/api/quote-equity?symbol=$cleanSymbol';
    final headers = await _getHeaders();
    
    final response = await http.get(Uri.parse(url), headers: headers)
        .timeout(const Duration(seconds: 15));
    
    if (response.statusCode == 200) {
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      final priceInfo = data['priceInfo'] ?? {};
      final metadata = data['metadata'] ?? {};
      
      final currentPrice = (priceInfo['lastPrice'] ?? 0).toDouble();
      final previousClose = (priceInfo['previousClose'] ?? currentPrice).toDouble();
      final change = currentPrice - previousClose;
      final changePercent = previousClose > 0 ? (change / previousClose) * 100 : 0.0;
      
      return {
        'currentPrice': currentPrice,
        'previousClose': previousClose,
        'change': change,
        'changePercent': changePercent,
        'high': (priceInfo['intraDayHighLow']?['max'] ?? currentPrice).toDouble(),
        'low': (priceInfo['intraDayHighLow']?['min'] ?? currentPrice).toDouble(),
        'open': (priceInfo['open'] ?? currentPrice).toDouble(),
        'volume': (priceInfo['totalTradedVolume'] ?? 0).toInt(),
      };
    }
    throw Exception('Failed to get quote: ${response.statusCode}');
  }
  
  Future<Map<String, dynamic>> getFinancialMetrics(String symbol) async {
    final cleanSymbol = symbol.replaceAll('.NS', '').replaceAll('.BO', '').toUpperCase();
    final url = 'https://www.nseindia.com/api/quote-equity?symbol=$cleanSymbol';
    final headers = await _getHeaders();
    
    final response = await http.get(Uri.parse(url), headers: headers)
        .timeout(const Duration(seconds: 15));
    
    if (response.statusCode == 200) {
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      final metadata = data['metadata'] ?? {};
      final priceInfo = data['priceInfo'] ?? {};
      final securityInfo = data['securityInfo'] ?? {};
      
      final currentPrice = (priceInfo['lastPrice'] ?? 0).toDouble();
      final sharesOutstanding = (securityInfo['issuedSize'] ?? metadata['issuedSize'] ?? 0).toDouble();
      
      final metrics = <String, dynamic>{};
      
      // Market Cap
      if (metadata['marketCap'] != null) {
        double mc = (metadata['marketCap'] as num).toDouble();
        if (mc > 1e12) mc /= 1e6;
        else if (mc > 1e9) mc /= 1e6;
        metrics['marketCap'] = mc;
      } else if (currentPrice > 0 && sharesOutstanding > 0) {
        metrics['marketCap'] = (currentPrice * sharesOutstanding) / 1e6;
      }
      
      // P/E Ratio
      if (metadata['pdSymbolPe'] != null) {
        final pe = (metadata['pdSymbolPe'] as num).toDouble();
        if (pe > 0 && pe < 10000) {
          metrics['pe'] = pe;
          metrics['peRatio'] = pe;
        }
      }
      
      // EPS
      if (metrics.containsKey('pe') && currentPrice > 0) {
        final pe = metrics['pe'] as double;
        if (pe > 0) {
          metrics['eps'] = currentPrice / pe;
        }
      }
      
      // Price to Book
      final faceValue = (securityInfo['faceValue'] ?? 1.0).toDouble();
      if (currentPrice > 0 && faceValue > 0) {
        final pb = currentPrice / faceValue;
        if (pb > 0 && pb < 1000) {
          metrics['priceToBook'] = pb;
        }
      }
      
      // Try Screener.in for additional metrics
      try {
        final screenerMetrics = await _getScreenerMetrics(cleanSymbol);
        metrics.addAll(screenerMetrics);
      } catch (e) {
        print('   ⚠️  Screener.in failed: $e');
      }
      
      // Try Yahoo Finance for missing metrics
      try {
        final yahooMetrics = await _getYahooMetrics(symbol);
        yahooMetrics.forEach((key, value) {
          if (value != null && (!metrics.containsKey(key) || metrics[key] == null)) {
            metrics[key] = value;
          }
        });
      } catch (e) {
        print('   ⚠️  Yahoo Finance failed: $e');
      }
      
      return metrics;
    }
    throw Exception('Failed to get metrics: ${response.statusCode}');
  }
  
  Future<Map<String, dynamic>> _getScreenerMetrics(String symbol) async {
    // Screener.in web scraping (simplified - you may need to adjust)
    final url = 'https://www.screener.in/company/$symbol/';
    final response = await http.get(
      Uri.parse(url),
      headers: {'User-Agent': 'Mozilla/5.0'},
    ).timeout(const Duration(seconds: 10));
    
    if (response.statusCode == 200) {
      final html = response.body;
      final metrics = <String, dynamic>{};
      
      // Extract metrics from HTML (simplified regex patterns)
      // In production, use proper HTML parsing
      final patterns = {
        'dividendYield': r'Dividend Yield[^>]*>([\d.]+)%',
        'returnOnEquity': r'Return on Equity[^>]*>([\d.]+)%',
        'profitMargin': r'Net Profit Margin[^>]*>([\d.]+)%',
        'revenue': r'Revenue[^>]*>₹\s*([\d.]+)\s*(Cr|L)',
        'debtToEquity': r'Debt to Equity[^>]*>([\d.]+)',
      };
      
      // This is a simplified version - you'd need proper HTML parsing
      return metrics;
    }
    return {};
  }
  
  Future<Map<String, dynamic>> _getYahooMetrics(String symbol) async {
    final yahooSymbol = symbol.endsWith('.NS') || symbol.endsWith('.BO') 
        ? symbol 
        : '$symbol.NS';
    
    final url = 'https://query1.finance.yahoo.com/v10/finance/quoteSummary/$yahooSymbol?modules=defaultKeyStatistics,financialData,summaryDetail';
    
    final response = await http.get(
      Uri.parse(url),
      headers: {
        'User-Agent': 'Mozilla/5.0',
        'Accept': 'application/json',
      },
    ).timeout(const Duration(seconds: 10));
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final result = data['quoteSummary']?['result']?[0];
      
      if (result != null) {
        final metrics = <String, dynamic>{};
        final keyStats = result['defaultKeyStatistics'] ?? {};
        final financialData = result['financialData'] ?? {};
        final summaryDetail = result['summaryDetail'] ?? {};
        
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
  
  Future<Map<String, dynamic>> getCompanyProfile(String symbol) async {
    final cleanSymbol = symbol.replaceAll('.NS', '').replaceAll('.BO', '').toUpperCase();
    final url = 'https://www.nseindia.com/api/quote-equity?symbol=$cleanSymbol';
    final headers = await _getHeaders();
    
    final response = await http.get(Uri.parse(url), headers: headers)
        .timeout(const Duration(seconds: 15));
    
    if (response.statusCode == 200) {
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      final info = data['info'] ?? {};
      final metadata = data['metadata'] ?? {};
      final priceInfo = data['priceInfo'] ?? {};
      final securityInfo = data['securityInfo'] ?? {};
      
      double marketCap = 0.0;
      if (metadata['marketCap'] != null) {
        marketCap = (metadata['marketCap'] as num).toDouble();
      } else {
        final sharesOutstanding = (securityInfo['issuedSize'] ?? metadata['issuedSize'] ?? 0).toDouble();
        final price = (priceInfo['lastPrice'] ?? 0).toDouble();
        if (price > 0 && sharesOutstanding > 0) {
          marketCap = price * sharesOutstanding;
        }
      }
      
      return {
        'name': info['companyName'] ?? cleanSymbol,
        'industry': info['industry'] ?? '',
        'exchange': 'NSE',
        'marketCapitalization': marketCap,
        'shareOutstanding': (securityInfo['issuedSize'] ?? metadata['issuedSize'] ?? 0).toDouble(),
      };
    }
    throw Exception('Failed to get profile: ${response.statusCode}');
  }
}

