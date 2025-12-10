import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html_parser;
import '../models/company_profile.dart';

/// Moneycontrol.com Web Scraper Service for Indian Stock Market Data
/// ONE source for ALL financial metrics - replaces Screener.in
class MoneycontrolService {
  static const String baseUrl = 'https://www.moneycontrol.com';
  
  /// Rate limiting
  static final List<DateTime> _apiCallHistory = [];
  static const int _maxCallsPerMinute = 10;
  static const Duration _minDelayBetweenCalls = Duration(seconds: 2);
  
  static Future<void> _waitForRateLimit() async {
    final now = DateTime.now();
    _apiCallHistory.removeWhere((time) => now.difference(time).inMinutes >= 1);
    
    if (_apiCallHistory.length >= _maxCallsPerMinute) {
      final oldestCall = _apiCallHistory.first;
      final waitTime = Duration(seconds: 60 - now.difference(oldestCall).inSeconds + 1);
      await Future.delayed(waitTime);
    }
    
    if (_apiCallHistory.isNotEmpty) {
      final lastCall = _apiCallHistory.last;
      final timeSinceLastCall = now.difference(lastCall);
      if (timeSinceLastCall < _minDelayBetweenCalls) {
        await Future.delayed(_minDelayBetweenCalls - timeSinceLastCall);
      }
    }
    
    _apiCallHistory.add(DateTime.now());
  }
  
  static Map<String, String> _getHeaders() {
    return {
      'User-Agent': 'Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1',
      'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
      'Accept-Language': 'en-US,en;q=0.9',
    };
  }
  
  static String _normalizeSymbol(String symbol) {
    return symbol.replaceAll('.NS', '').replaceAll('.BO', '').trim().toUpperCase();
  }
  
  /// Get Moneycontrol URL for a stock
  static String? _getCompanyUrl(String symbol) {
    final normalizedSymbol = _normalizeSymbol(symbol);
    
    // Direct URL mappings for common stocks
    final urlMap = {
      'TCS': '$baseUrl/india/stockpricequote/computers-software/tataconsultancyservices/TCS',
      'INFY': '$baseUrl/india/stockpricequote/computers-software/infosys/INFY',
      'INFOSYS': '$baseUrl/india/stockpricequote/computers-software/infosys/INFY',
      'RELIANCE': '$baseUrl/india/stockpricequote/refineries/relianceindustries/RI',
      'HDFCBANK': '$baseUrl/india/stockpricequote/banks-private-sector/hdfcbank/HDF01',
      'HDFC': '$baseUrl/india/stockpricequote/housing-finance/hdfc/HDF',
      'ICICIBANK': '$baseUrl/india/stockpricequote/banks-private-sector/icicibank/ICI02',
      'ICICI': '$baseUrl/india/stockpricequote/banks-private-sector/icicibank/ICI02',
      'SBIN': '$baseUrl/india/stockpricequote/banks-public-sector/statebankofindia/SBI',
      'WIPRO': '$baseUrl/india/stockpricequote/computers-software/wipro/W',
      'BHARTIARTL': '$baseUrl/india/stockpricequote/telecommunications/bhartiairtel/BA08',
      'HINDUNILVR': '$baseUrl/india/stockpricequote/personal-care/hindustanunilever/HU',
      'ITC': '$baseUrl/india/stockpricequote/cigarettes/itc/ITC',
      'KOTAKBANK': '$baseUrl/india/stockpricequote/banks-private-sector/kotakmahindrabank/KMB',
      'LT': '$baseUrl/india/stockpricequote/construction-contracting/larsentoubro/LT',
      'AXISBANK': '$baseUrl/india/stockpricequote/banks-private-sector/axisbank/AB16',
    };
    
    if (urlMap.containsKey(normalizedSymbol)) {
      return urlMap[normalizedSymbol];
    }
    
    // For unknown stocks, try search (would need search API or URL pattern)
    return null;
  }
  
  static double? _parseNumber(String? text) {
    if (text == null || text.isEmpty || text == '—' || text == '-' || text == 'N/A') {
      return null;
    }
    
    text = text.replaceAll(',', '').replaceAll(' ', '').trim();
    
    if (text.contains('%')) {
      text = text.replaceAll('%', '');
      try {
        return double.tryParse(text) != null ? double.parse(text) / 100 : null;
      } catch (e) {
        return null;
      }
    }
    
    double multiplier = 1;
    if (text.toUpperCase().contains('CR') || text.toLowerCase().contains('crore')) {
      text = text.replaceAll(RegExp(r'[CcRr]'), '').replaceAll('crore', '');
      multiplier = 1e7;
    } else if (text.toUpperCase().contains('L') || text.toLowerCase().contains('lakh')) {
      text = text.replaceAll(RegExp(r'[Ll]'), '').replaceAll('lakh', '');
      multiplier = 1e5;
    } else if (text.toUpperCase().contains('B') && !text.toUpperCase().contains('BR')) {
      text = text.replaceAll(RegExp(r'[Bb]'), '').replaceAll('billion', '');
      multiplier = 1e9;
    } else if (text.toUpperCase().contains('M')) {
      text = text.replaceAll(RegExp(r'[Mm]'), '').replaceAll('million', '');
      multiplier = 1e6;
    }
    
    text = text.replaceAll(RegExp(r'[^\d.\-]'), '');
    
    try {
      if (text.isNotEmpty) {
        final value = double.parse(text) * multiplier;
        if (value.isInfinite || value.isNaN || value.abs() > 1e15) return null;
        return value;
      }
    } catch (e) {
      // Parsing failed
    }
    
    return null;
  }
  
  /// Extract metrics from HTML
  static Map<String, dynamic> _extractMetrics(String htmlContent) {
    final metrics = <String, dynamic>{};
    final document = html_parser.parse(htmlContent);
    
    if (document == null) return metrics;
    
    // Extract company name
    final nameElement = document.querySelector('h1.b_42, h1.company_name');
    if (nameElement != null) {
      metrics['name'] = nameElement.text.trim();
    }
    
    // Extract from all tables
    final tables = document.querySelectorAll('table');
    for (final table in tables) {
      final rows = table.querySelectorAll('tr');
      for (final row in rows) {
        final cells = row.querySelectorAll('td, th');
        if (cells.length >= 2) {
          final label = cells[0].text.trim().toLowerCase();
          final valueText = cells.length > 1 ? cells[cells.length - 1].text.trim() : '';
          final value = _parseNumber(valueText);
          
          if (value == null) continue;
          
          // Map all metrics
          if ((label.contains('market cap') || label.contains('mcap')) && !metrics.containsKey('marketCap')) {
            metrics['marketCap'] = value / 1e6; // Convert to millions
          } else if ((label.contains('pe') || label.contains('p/e')) && label.contains('ratio') && !metrics.containsKey('peRatio')) {
            if (value > 0 && value < 1000) metrics['peRatio'] = value;
          } else if ((label.contains('price to book') || label.contains('p/b') || label.contains('pb')) && !metrics.containsKey('priceToBook')) {
            if (value > 0 && value < 1000) metrics['priceToBook'] = value;
          } else if ((label.contains('price to sales') || label.contains('p/s') || label.contains('ps') || label.contains('price/sales')) && !metrics.containsKey('priceToSales')) {
            if (value > 0 && value < 1000) metrics['priceToSales'] = value;
          } else if (label.contains('dividend yield') && !metrics.containsKey('dividendYield')) {
            metrics['dividendYield'] = value > 1 ? value / 100 : value;
          } else if (label.contains('beta') && !metrics.containsKey('beta')) {
            if (value >= 0 && value <= 10) metrics['beta'] = value;
          } else if ((label.contains('eps') || label.contains('earnings per share')) && !metrics.containsKey('eps')) {
            metrics['eps'] = value;
          } else if ((label.contains('roe') || label.contains('return on equity')) && !metrics.containsKey('returnOnEquity')) {
            metrics['returnOnEquity'] = value > 1 ? value / 100 : value;
          } else if ((label.contains('debt to equity') || label.contains('d/e') || label.contains('debt/equity')) && !metrics.containsKey('debtToEquity')) {
            if (value >= 0 && value <= 100) metrics['debtToEquity'] = value;
          } else if ((label.contains('book value') || label.contains('bv')) && !metrics.containsKey('bookValue')) {
            metrics['bookValue'] = value;
          } else if (label.contains('sales') || label.contains('revenue') || label.contains('total income')) {
            if (!metrics.containsKey('revenue')) {
              metrics['revenue'] = value / 100; // Convert crores to billions
            }
          } else if ((label.contains('net profit') || label.contains('pat')) && metrics.containsKey('revenue')) {
            final revenueInCrores = (metrics['revenue'] as double) * 100;
            if (revenueInCrores > 0) {
              metrics['profitMargin'] = value / revenueInCrores;
            }
          }
        }
      }
    }
    
    // Extract from page text patterns
    final pageText = document.body?.text ?? '';
    
    final patterns = {
      'peRatio': (RegExp(r'P[/\s]*E[:\s]+([\d.]+)', caseSensitive: false), (v) => v > 0 && v < 1000 ? v : null),
      'beta': (RegExp(r'Beta[:\s]+([\d.]+)', caseSensitive: false), (v) => v >= 0 && v <= 10 ? v : null),
      'priceToBook': (RegExp(r'Price.*Book[:\s]+([\d.]+)', caseSensitive: false), (v) => v > 0 && v < 1000 ? v : null),
      'priceToSales': (RegExp(r'Price.*Sales[:\s]+([\d.]+)', caseSensitive: false), (v) => v > 0 && v < 1000 ? v : null),
      'returnOnEquity': (RegExp(r'ROE[:\s]+([\d.]+)', caseSensitive: false), (v) => v > 1 ? v / 100 : v),
      'debtToEquity': (RegExp(r'Debt.*Equity[:\s]+([\d.]+)', caseSensitive: false), (v) => v >= 0 && v <= 100 ? v : null),
      'eps': (RegExp(r'EPS[:\s]+([\d.]+)', caseSensitive: false), (v) => v > 0 ? v : null),
    };
    
    for (final entry in patterns.entries) {
      final key = entry.key;
      final pattern = entry.value.$1;
      final validator = entry.value.$2;
      
      if (!metrics.containsKey(key)) {
        final match = pattern.firstMatch(pageText);
        if (match != null) {
          final val = _parseNumber(match.group(1));
          if (val != null) {
            final result = validator(val);
            if (result != null) {
              metrics[key] = result;
            }
          }
        }
      }
    }
    
    return metrics;
  }
  
  /// Get financial metrics from Moneycontrol
  static Future<Map<String, dynamic>> getFinancialMetrics(String symbol) async {
    final normalizedSymbol = _normalizeSymbol(symbol);
    print('📊 [Moneycontrol] Fetching metrics for $normalizedSymbol...');
    
    try {
      await _waitForRateLimit();
      
      final companyUrl = _getCompanyUrl(normalizedSymbol);
      if (companyUrl == null) {
        print('❌ [Moneycontrol] Could not find URL for $normalizedSymbol');
        return {};
      }
      
      print('✅ [Moneycontrol] URL: $companyUrl');
      
      final response = await http.get(
        Uri.parse(companyUrl),
        headers: _getHeaders(),
      ).timeout(const Duration(seconds: 20));
      
      if (response.statusCode != 200) {
        print('❌ [Moneycontrol] Failed: ${response.statusCode}');
        return {};
      }
      
      final html = utf8.decode(response.bodyBytes, allowMalformed: true);
      final metrics = _extractMetrics(html);
      
      metrics['symbol'] = symbol;
      metrics['currency'] = 'INR';
      metrics['country'] = 'IN';
      
      print('✅ [Moneycontrol] Extracted ${metrics.length} metrics');
      return metrics;
      
    } catch (e) {
      print('❌ [Moneycontrol] Error: $e');
      return {};
    }
  }
  
  /// Get company profile with all metrics
  static Future<CompanyProfile> getCompanyProfile(String symbol) async {
    final metrics = await getFinancialMetrics(symbol);
    
    return CompanyProfile(
      name: metrics['name'] ?? _normalizeSymbol(symbol),
      ticker: symbol,
      symbol: symbol,
      country: 'IN',
      currency: 'INR',
      industry: metrics['industry'] ?? '',
      finnhubIndustry: metrics['industry'] ?? '',
      weburl: '',
      logo: '',
      phone: '',
      ipo: '',
      marketCapitalization: (metrics['marketCap'] ?? 0.0) as double,
      shareOutstanding: 0.0,
      description: '',
      exchange: 'NSE',
      peRatio: metrics['peRatio'] as double?,
      dividendYield: metrics['dividendYield'] as double?,
      beta: metrics['beta'] as double?,
      eps: metrics['eps'] as double?,
      bookValue: metrics['bookValue'] as double?,
      priceToBook: metrics['priceToBook'] as double?,
      priceToSales: metrics['priceToSales'] as double?,
      revenue: metrics['revenue'] as double?,
      profitMargin: metrics['profitMargin'] as double?,
      returnOnEquity: metrics['returnOnEquity'] as double?,
      debtToEquity: metrics['debtToEquity'] as double?,
    );
  }
}

