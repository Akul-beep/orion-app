import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html_parser;
import '../models/company_profile.dart';

/// Screener.in Web Scraper Service for Indian Stock Market Data
/// Extracts comprehensive financial metrics for NSE/BSE stocks
/// 
/// This service gets all metrics that FinHub provides for US stocks:
/// - Market Cap, P/E Ratio, Dividend Yield, Beta
/// - EPS, Price to Book, Revenue, Profit Margin
/// - ROE, Debt/Equity, and more
class ScreenerInService {
  static const String baseUrl = 'https://www.screener.in';
  
  // Cache for session cookies
  static String? _sessionCookie;
  static DateTime? _cookieExpiry;
  
  // Rate limiting: Track API calls to be respectful
  static final List<DateTime> _apiCallHistory = [];
  static const int _maxCallsPerMinute = 10; // Be conservative
  static const Duration _minDelayBetweenCalls = Duration(seconds: 2); // Minimum 2 seconds between calls
  
  /// Get or refresh screener.in session cookie
  static Future<String?> _getSessionCookie() async {
    // Use cached cookie if still valid (refresh every 30 minutes)
    if (_sessionCookie != null && 
        _cookieExpiry != null && 
        DateTime.now().isBefore(_cookieExpiry!)) {
      return _sessionCookie;
    }
    
    try {
      print('🍪 [Screener.in] Getting session cookie...');
      
      final response = await http.get(
        Uri.parse(baseUrl),
        headers: {
          // Use mobile user agent for App Store compliance
          'User-Agent': 'Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1',
          'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
          'Accept-Language': 'en-US,en;q=0.9',
          'Connection': 'keep-alive',
        },
      ).timeout(const Duration(seconds: 10));
      
      // Extract all cookies
      final cookies = response.headers['set-cookie'];
      if (cookies != null) {
        _sessionCookie = cookies;
        _cookieExpiry = DateTime.now().add(const Duration(minutes: 30));
        print('✅ [Screener.in] Got session cookie');
        return _sessionCookie;
      }
    } catch (e) {
      print('⚠️ [Screener.in] Failed to get cookie: $e');
    }
    
    return null;
  }
  
  /// Get headers with session cookie (mobile-friendly for App Store)
  static Future<Map<String, String>> _getHeaders() async {
    final cookie = await _getSessionCookie();
    
    // Use mobile user agent for App Store compliance
    return {
      'User-Agent': 'Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1',
      'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
      'Accept-Language': 'en-US,en;q=0.9',
      'Accept-Encoding': 'gzip, deflate, br',
      'Referer': '$baseUrl/',
      'Origin': baseUrl,
      'Connection': 'keep-alive',
      'Upgrade-Insecure-Requests': '1',
      'Sec-Fetch-Dest': 'document',
      'Sec-Fetch-Mode': 'navigate',
      'Sec-Fetch-Site': 'same-origin',
      'Cache-Control': 'max-age=0',
      if (cookie != null) 'Cookie': cookie,
    };
  }
  
  /// Rate limiting to be respectful to the server
  static Future<void> _waitForRateLimit() async {
    final now = DateTime.now();
    
    // Remove old entries (older than 1 minute)
    _apiCallHistory.removeWhere((time) => now.difference(time).inMinutes >= 1);
    
    // Check per-minute limit
    if (_apiCallHistory.length >= _maxCallsPerMinute) {
      final oldestCall = _apiCallHistory.first;
      final waitTime = Duration(seconds: 60 - now.difference(oldestCall).inSeconds + 1);
      print('⏳ [Screener.in] Rate limit: ${_apiCallHistory.length}/$_maxCallsPerMinute calls. Waiting ${waitTime.inSeconds}s...');
      await Future.delayed(waitTime);
    }
    
    // Ensure minimum delay between calls
    if (_apiCallHistory.isNotEmpty) {
      final lastCall = _apiCallHistory.last;
      final timeSinceLastCall = now.difference(lastCall);
      if (timeSinceLastCall < _minDelayBetweenCalls) {
        final waitTime = _minDelayBetweenCalls - timeSinceLastCall;
        await Future.delayed(waitTime);
      }
    }
    
    // Record this API call
    _apiCallHistory.add(DateTime.now());
  }
  
  /// Normalize stock symbol (remove .NS, .BO, convert to uppercase)
  static String _normalizeSymbol(String symbol) {
    return symbol.replaceAll('.NS', '').replaceAll('.BO', '').trim().toUpperCase();
  }
  
  /// Search for company and get its screener.in URL
  static Future<String?> _searchCompany(String symbol) async {
    // Rate limiting
    await _waitForRateLimit();
    
    final normalizedSymbol = _normalizeSymbol(symbol);
    final searchUrl = '$baseUrl/api/company/search/?q=${Uri.encodeComponent(normalizedSymbol)}';
    
    try {
      final response = await http.get(
        Uri.parse(searchUrl),
        headers: await _getHeaders(),
      ).timeout(const Duration(seconds: 15));
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List;
        if (data.isNotEmpty) {
          // Find exact match or first result
          for (var company in data) {
            final name = (company['name'] ?? '').toString().toUpperCase();
            final url = company['url'] ?? '';
            if (normalizedSymbol == name || 
                name.contains(normalizedSymbol) || 
                url.toUpperCase().contains(normalizedSymbol)) {
              final companyUrl = url.toString();
              if (companyUrl.isNotEmpty) {
                return companyUrl.startsWith('/') ? '$baseUrl$companyUrl' : companyUrl;
              }
            }
          }
          // If no exact match, use first result
          final firstUrl = data[0]['url']?.toString();
          if (firstUrl != null && firstUrl.isNotEmpty) {
            return firstUrl.startsWith('/') ? '$baseUrl$firstUrl' : firstUrl;
          }
        }
      }
    } catch (e) {
      print('⚠️ [Screener.in] Search error for $symbol: $e');
    }
    
    // Fallback: try direct URL format
    return '$baseUrl/company/$normalizedSymbol/';
  }
  
  /// Parse number from text (handles Indian number format with Cr, L, etc.)
  static double? _parseNumber(String? text) {
    if (text == null || text.isEmpty || text == '—' || text == '-' || text == 'N/A') {
      return null;
    }
    
    // Remove commas and spaces
    text = text.replaceAll(',', '').replaceAll(' ', '').trim();
    
    // Handle percentage
    if (text.contains('%')) {
      text = text.replaceAll('%', '');
      try {
        final value = double.tryParse(text);
        return value != null ? value / 100 : null; // Convert percentage to decimal
      } catch (e) {
        return null;
      }
    }
    
    // Handle Indian numbering system
    double multiplier = 1;
    if (text.toUpperCase().contains('CR') || text.toLowerCase().contains('crore')) {
      text = text.replaceAll(RegExp(r'[CcRr]'), '').replaceAll('crore', '').replaceAll('Crore', '');
      multiplier = 1e7; // Crores (10 million)
    } else if (text.toUpperCase().contains('L') || text.toLowerCase().contains('lakh')) {
      text = text.replaceAll(RegExp(r'[Ll]'), '').replaceAll('lakh', '').replaceAll('Lakh', '').replaceAll('Lac', '');
      multiplier = 1e5; // Lakhs (100 thousand)
    } else if (text.toUpperCase().contains('T') || text.toLowerCase().contains('thousand')) {
      text = text.replaceAll(RegExp(r'[Tt]'), '').replaceAll('thousand', '').replaceAll(' ', '');
      multiplier = 1e3; // Thousands
    } else if (text.toUpperCase().contains('B') && !text.toUpperCase().contains('BR')) {
      text = text.replaceAll(RegExp(r'[Bb]'), '').replaceAll('billion', '').replaceAll('Billion', '');
      multiplier = 1e9; // Billions
    } else if (text.toUpperCase().contains('M')) {
      text = text.replaceAll(RegExp(r'[Mm]'), '').replaceAll('million', '').replaceAll('Million', '');
      multiplier = 1e6; // Millions
    }
    
    // Remove any remaining non-numeric characters except decimal point and minus sign
    text = text.replaceAll(RegExp(r'[^\d.\-]'), '');
    
    try {
      if (text.isNotEmpty) {
        final value = double.parse(text) * multiplier;
        // Validate reasonable ranges
        if (value == 0 || value.isInfinite || value.isNaN) return null;
        if (value.abs() > 1e15) return null;
        return value;
      }
    } catch (e) {
      // Parsing failed
    }
    
    return null;
  }
  
  /// Extract metrics from HTML using proper HTML parsing
  static Map<String, dynamic> _extractFromTables(String htmlContent) {
    final metrics = <String, dynamic>{};
    
    // Parse HTML using html package
    final document = html_parser.parse(htmlContent);
    if (document == null) {
      print('⚠️ [Screener.in] Failed to parse HTML');
      return metrics;
    }
    
    // Extract company name from h1 tag
    final h1Element = document.querySelector('h1');
    if (h1Element != null) {
      final name = h1Element.text.trim();
      if (name.isNotEmpty) {
        metrics['name'] = name;
      }
    }
    
    // Extract industry/sector
    final industryElements = document.querySelectorAll('a[href*="/screens/industry/"]');
    if (industryElements.isNotEmpty) {
      metrics['industry'] = industryElements.first.text.trim();
    }
    
    // Extract metrics from all tables
    final tables = document.querySelectorAll('table');
    for (final table in tables) {
      final rows = table.querySelectorAll('tr');
      for (final row in rows) {
        final cells = row.querySelectorAll('td, th');
        if (cells.length >= 2) {
          final label = cells[0].text.trim().toLowerCase();
          final valueText = cells.length > 1 ? cells[cells.length - 1].text.trim() : '';
          
          // Get value from last column (most recent data)
          final value = _parseNumber(valueText);
          if (value == null) continue;
          
          // Map labels to metrics
          if (label.contains('market cap') || label.contains('mcap') || label.contains('market capitalization')) {
            // Check if value text contains unit
            if (valueText.toUpperCase().contains('CR') || valueText.toUpperCase().contains('CRORE')) {
              metrics['marketCap'] = value * 1e7 / 1e6; // Crores to millions
            } else if (valueText.toUpperCase().contains('L')) {
              metrics['marketCap'] = value * 1e5 / 1e6; // Lakhs to millions
            } else if (valueText.toUpperCase().contains('B')) {
              metrics['marketCap'] = value * 1e9 / 1e6; // Billions to millions
            } else if (value > 1000) {
              metrics['marketCap'] = value * 1e7 / 1e6; // Assume crores
            } else {
              metrics['marketCap'] = value * 1e9 / 1e6;
            }
          } else if (label.contains('pe') && label.contains('ratio')) {
            if (value > 0 && value < 1000) {
              metrics['peRatio'] = value;
            }
          } else if (label.contains('price to book') || label.contains('p/b') || label.contains('pb')) {
            if (value > 0 && value < 1000) {
              metrics['priceToBook'] = value;
            }
          } else if (label.contains('price to sales') || label.contains('p/s') || label.contains('ps') || label.contains('price/sales')) {
            if (value > 0 && value < 1000) {
              metrics['priceToSales'] = value;
            }
          } else if (label.contains('book value') || label.contains('bv')) {
            metrics['bookValue'] = value;
          } else if (label.contains('dividend yield')) {
            metrics['dividendYield'] = value > 1 ? value / 100 : value;
          } else if (label.contains('roe') || label.contains('return on equity')) {
            metrics['returnOnEquity'] = value > 1 ? value / 100 : value;
          } else if (label.contains('debt to equity') || label.contains('d/e')) {
            if (value >= 0 && value <= 100) {
              metrics['debtToEquity'] = value;
            }
          } else if (label.contains('beta')) {
            if (value >= 0 && value <= 10) {
              metrics['beta'] = value;
            }
          } else if (label.contains('eps') || label.contains('earnings per share')) {
            metrics['eps'] = value;
          } else if (label.contains('sales') || label.contains('revenue') || label.contains('turnover')) {
            // Get most recent revenue (last column)
            // Revenue is typically in crores (Cr), convert to billions
            if (!metrics.containsKey('revenue')) {
              if (valueText.toUpperCase().contains('CR') || valueText.toUpperCase().contains('CRORE')) {
                metrics['revenue'] = value / 100; // Crores to billions
              } else if (valueText.toUpperCase().contains('B')) {
                metrics['revenue'] = value; // Already in billions
              } else if (value > 1000) {
                metrics['revenue'] = value / 100; // Assume crores
              } else {
                metrics['revenue'] = value; // Assume already in billions
              }
              print('✅ [Screener.in] Extracted Revenue: $value -> ${metrics['revenue']}B');
            }
          } else if (label.contains('profit') && (label.contains('after') || label.contains('net') || label.contains('pat'))) {
            // Calculate profit margin if we have revenue
            if (metrics.containsKey('revenue') && metrics['revenue'] != null) {
              final revenueInBillions = metrics['revenue'] as double;
              if (revenueInBillions > 0) {
                // Profit is in crores, revenue is in billions
                // Profit margin = (Profit in crores / Revenue in crores) * 100
                // Revenue in crores = revenueInBillions * 100
                final revenueInCrores = revenueInBillions * 100;
                final profitMargin = value / revenueInCrores;
                if (profitMargin > 0 && profitMargin <= 1) {
                  metrics['profitMargin'] = profitMargin;
                  print('✅ [Screener.in] Calculated Profit Margin: $value / $revenueInCrores = $profitMargin');
                }
              }
            }
          }
        }
      }
    }
    
    // Also extract from page text using patterns (for metrics not in tables)
    final pageText = document.body?.text ?? '';
    
    // Extract P/E Ratio from text
    if (!metrics.containsKey('peRatio')) {
      final pePattern = RegExp(r'P[/\s]*E[:\s]+([\d.]+)', caseSensitive: false);
      final peMatch = pePattern.firstMatch(pageText);
      if (peMatch != null) {
        final pe = _parseNumber(peMatch.group(1));
        if (pe != null && pe > 0 && pe < 1000) {
          metrics['peRatio'] = pe;
        }
      }
    }
    
    // Extract Market Cap from text
    if (!metrics.containsKey('marketCap')) {
      final mcapPattern = RegExp(r'Market Cap[:\s]+₹?\s*([\d,.]+)\s*(Cr|L|M|B)?', caseSensitive: false);
      final mcapMatch = mcapPattern.firstMatch(pageText);
      if (mcapMatch != null) {
        final mcapStr = mcapMatch.group(1)?.replaceAll(',', '') ?? '';
        final unit = mcapMatch.group(2)?.toUpperCase();
        final mcap = _parseNumber(mcapStr);
        if (mcap != null) {
          double mcapValue = mcap;
          if (unit == 'CR') {
            mcapValue = mcap * 1e7 / 1e6;
          } else if (unit == 'L') {
            mcapValue = mcap * 1e5 / 1e6;
          } else if (unit == 'B') {
            mcapValue = mcap * 1e9 / 1e6;
          } else if (mcapValue > 1000) {
            mcapValue = mcapValue * 1e7 / 1e6;
          } else {
            mcapValue = mcapValue * 1e9 / 1e6;
          }
          metrics['marketCap'] = mcapValue;
        }
      }
    }
    
    // Extract Dividend Yield from text
    if (!metrics.containsKey('dividendYield')) {
      final divPattern = RegExp(r'Dividend.*Yield[:\s]+([\d.]+)', caseSensitive: false);
      final divMatch = divPattern.firstMatch(pageText);
      if (divMatch != null) {
        final divYield = _parseNumber(divMatch.group(1));
        if (divYield != null) {
          metrics['dividendYield'] = divYield > 1 ? divYield / 100 : divYield;
        }
      }
    }
    
    // Extract ROE from text
    if (!metrics.containsKey('returnOnEquity')) {
      final roePattern = RegExp(r'ROE[:\s]+([\d.]+)', caseSensitive: false);
      final roeMatch = roePattern.firstMatch(pageText);
      if (roeMatch != null) {
        final roe = _parseNumber(roeMatch.group(1));
        if (roe != null && roe.abs() <= 1000) {
          // ROE is typically in percentage (e.g., 52.4 means 52.4%)
          // But if it's > 1 and < 100, it's likely already in percentage form
          metrics['returnOnEquity'] = roe > 1 && roe <= 100 ? roe / 100 : (roe > 100 ? roe / 100 : roe);
          print('✅ [Screener.in] Extracted ROE: ${metrics['returnOnEquity']} (from $roe)');
        }
      }
    }
    
    // Extract Debt/Equity from text
    if (!metrics.containsKey('debtToEquity')) {
      final dePattern = RegExp(r'Debt.*Equity[:\s]+([\d.]+)', caseSensitive: false);
      final deMatch = dePattern.firstMatch(pageText);
      if (deMatch != null) {
        final de = _parseNumber(deMatch.group(1));
        if (de != null && de >= 0 && de <= 100) {
          metrics['debtToEquity'] = de;
        }
      }
    }
    
    // Extract Current Price from text
    if (!metrics.containsKey('currentPrice')) {
      final pricePattern = RegExp(r'Current Price[:\s]+₹?\s*([\d,.]+)', caseSensitive: false);
      final priceMatch = pricePattern.firstMatch(pageText);
      if (priceMatch != null) {
        final currentPrice = _parseNumber(priceMatch.group(1));
        if (currentPrice != null && currentPrice > 0) {
          metrics['currentPrice'] = currentPrice;
        }
      }
    }
    
    // Extract Book Value from text
    if (!metrics.containsKey('bookValue')) {
      final bookValuePattern = RegExp(r'Book.*Value[:\s]+₹?\s*([\d.]+)', caseSensitive: false);
      final bookValueMatch = bookValuePattern.firstMatch(pageText);
      if (bookValueMatch != null) {
        final bookValue = _parseNumber(bookValueMatch.group(1));
        if (bookValue != null && bookValue > 0) {
          metrics['bookValue'] = bookValue;
        }
      }
    }
    
    // Extract Price to Book from text
    if (!metrics.containsKey('priceToBook')) {
      final pbPattern = RegExp(r'Price.*Book[:\s]+([\d.]+)', caseSensitive: false);
      final pbMatch = pbPattern.firstMatch(pageText);
      if (pbMatch != null) {
        final pb = _parseNumber(pbMatch.group(1));
        if (pb != null && pb > 0 && pb < 1000) {
          metrics['priceToBook'] = pb;
        }
      }
    }
    
    // Extract Price to Sales from text
    if (!metrics.containsKey('priceToSales')) {
      final psPattern = RegExp(r'Price.*Sales[:\s]+([\d.]+)', caseSensitive: false);
      final psMatch = psPattern.firstMatch(pageText);
      if (psMatch != null) {
        final ps = _parseNumber(psMatch.group(1));
        if (ps != null && ps > 0 && ps < 1000) {
          metrics['priceToSales'] = ps;
        }
      }
    }
    
    // Calculate Price to Sales if we have Market Cap and Revenue
    if (!metrics.containsKey('priceToSales') && metrics.containsKey('marketCap') && metrics.containsKey('revenue')) {
      final marketCap = metrics['marketCap'] as double;
      final revenue = metrics['revenue'] as double;
      if (marketCap > 0 && revenue > 0) {
        // Market cap is in millions, revenue is in billions
        // Price to Sales = Market Cap / Revenue
        // Convert both to same units (billions)
        final marketCapBillions = marketCap / 1e3; // Convert millions to billions
        metrics['priceToSales'] = marketCapBillions / revenue;
        print('✅ [Screener.in] Calculated Price to Sales: ${marketCapBillions}B / ${revenue}B = ${metrics['priceToSales']}');
      }
    }
    
    // Extract Beta from text
    if (!metrics.containsKey('beta')) {
      final betaPattern = RegExp(r'Beta[:\s]+([\d.]+)', caseSensitive: false);
      final betaMatch = betaPattern.firstMatch(pageText);
      if (betaMatch != null) {
        final beta = _parseNumber(betaMatch.group(1));
        if (beta != null && beta >= 0 && beta <= 10) {
          metrics['beta'] = beta;
        }
      }
    }
    
    // Calculate EPS from Current Price / P/E Ratio if not found
    if (!metrics.containsKey('eps') && metrics.containsKey('currentPrice') && metrics.containsKey('peRatio')) {
      final currentPrice = metrics['currentPrice'] as double;
      final peRatio = metrics['peRatio'] as double;
      if (currentPrice > 0 && peRatio > 0) {
        metrics['eps'] = currentPrice / peRatio;
        print('✅ [Screener.in] Calculated EPS: ${currentPrice} / ${peRatio} = ${metrics['eps']}');
      }
    }
    
    // Calculate Price to Book if we have Book Value and Current Price
    if (!metrics.containsKey('priceToBook') && metrics.containsKey('bookValue') && metrics.containsKey('currentPrice')) {
      final bookValue = metrics['bookValue'] as double;
      final currentPrice = metrics['currentPrice'] as double;
      if (bookValue > 0 && currentPrice > 0) {
        metrics['priceToBook'] = currentPrice / bookValue;
        print('✅ [Screener.in] Calculated Price to Book: ${currentPrice} / ${bookValue} = ${metrics['priceToBook']}');
      }
    }
    
    return metrics;
  }
  
  /// Get financial metrics for an Indian stock
  /// Returns empty map on failure - never throws to prevent app crashes
  static Future<Map<String, dynamic>> getFinancialMetrics(String symbol) async {
    final normalizedSymbol = _normalizeSymbol(symbol);
    print('📊 [Screener.in] Fetching metrics for $normalizedSymbol...');
    
    try {
      // Rate limiting
      await _waitForRateLimit();
      
      // Step 1: Search for company
      final companyUrl = await _searchCompany(normalizedSymbol);
      if (companyUrl == null) {
        print('❌ [Screener.in] Could not find company URL for $normalizedSymbol');
        return {};
      }
      
      print('✅ [Screener.in] Found company URL: $companyUrl');
      
      // Step 2: Fetch main page (with rate limiting)
      await _waitForRateLimit();
      
      final response = await http.get(
        Uri.parse(companyUrl),
        headers: await _getHeaders(),
      ).timeout(const Duration(seconds: 20));
      
      if (response.statusCode != 200) {
        print('❌ [Screener.in] Failed to fetch page: ${response.statusCode}');
        // Return empty map instead of throwing - let NSE data be used as fallback
        return {};
      }
      
      // Handle 429 (Too Many Requests) gracefully
      if (response.statusCode == 429) {
        print('⚠️ [Screener.in] Rate limited (429). Please try again later.');
        return {};
      }
      
      // Handle 403 (Forbidden) - might be blocked
      if (response.statusCode == 403) {
        print('⚠️ [Screener.in] Access forbidden (403). May be temporarily blocked.');
        return {};
      }
      
      // Step 3: Extract metrics from main page
      print('📊 [Screener.in] Extracting metrics...');
      final html = utf8.decode(response.bodyBytes, allowMalformed: true);
      final metrics = _extractFromTables(html);
      
      // Step 4 & 5: Skip ratios/financials pages (they return 404 and waste time)
      // All needed metrics are available on the main consolidated page
      // This optimization saves ~2-4 seconds per request
      
      // Add basic info
      metrics['symbol'] = symbol;
      metrics['currency'] = 'INR';
      metrics['country'] = 'IN';
      
      print('✅ [Screener.in] Extracted ${metrics.length} metrics');
      print('   Metric keys: ${metrics.keys.toList()}');
      print('   PE: ${metrics['peRatio']}, Div Yield: ${metrics['dividendYield']}');
      print('   Revenue: ${metrics['revenue']}, Profit Margin: ${metrics['profitMargin']}');
      print('   ROE: ${metrics['returnOnEquity']}, Debt/Equity: ${metrics['debtToEquity']}');
      print('   Price to Book: ${metrics['priceToBook']}, Price to Sales: ${metrics['priceToSales']}');
      
      return metrics;
      
    } catch (e, stackTrace) {
      // Log error but never throw - always return empty map to prevent app crashes
      print('❌ [Screener.in] Error fetching metrics: $e');
      print('Stack trace: $stackTrace');
      // Return empty map - app will fall back to NSE data only
      return {};
    }
  }
  
  /// Get company profile with all metrics
  /// Never throws - returns minimal profile on failure
  static Future<CompanyProfile> getCompanyProfile(String symbol) async {
    try {
      final metrics = await getFinancialMetrics(symbol);
      
      print('📊 [Screener.in] Creating profile from ${metrics.length} metrics');
      print('   Metrics keys: ${metrics.keys.toList()}');
      print('   PE: ${metrics['peRatio']}, Div Yield: ${metrics['dividendYield']}');
      print('   Revenue: ${metrics['revenue']}, Profit Margin: ${metrics['profitMargin']}');
      print('   ROE: ${metrics['returnOnEquity']}, Debt/Equity: ${metrics['debtToEquity']}');
      print('   Price to Book: ${metrics['priceToBook']}, Price to Sales: ${metrics['priceToSales']}');
    
      // Convert metrics to CompanyProfile - ensure proper type casting
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
        marketCapitalization: _safeDouble(metrics['marketCap'], 0.0),
        shareOutstanding: 0.0,
        description: '',
        exchange: 'NSE',
        peRatio: _safeDoubleNullable(metrics['peRatio'] ?? metrics['pe']),
        dividendYield: _safeDoubleNullable(metrics['dividendYield']),
        beta: _safeDoubleNullable(metrics['beta']),
        eps: _safeDoubleNullable(metrics['eps']),
        bookValue: _safeDoubleNullable(metrics['bookValue']),
        priceToBook: _safeDoubleNullable(metrics['priceToBook']),
        priceToSales: _safeDoubleNullable(metrics['priceToSales']),
        revenue: _safeDoubleNullable(metrics['revenue']),
        profitMargin: _safeDoubleNullable(metrics['profitMargin']),
        returnOnEquity: _safeDoubleNullable(metrics['returnOnEquity']),
        debtToEquity: _safeDoubleNullable(metrics['debtToEquity']),
      );
    } catch (e, stackTrace) {
      // Return minimal profile on any error
      print('⚠️ [Screener.in] Error in getCompanyProfile: $e');
      print('Stack trace: $stackTrace');
      return CompanyProfile(
        name: _normalizeSymbol(symbol),
        ticker: symbol,
        symbol: symbol,
        country: 'IN',
        currency: 'INR',
        industry: '',
        finnhubIndustry: '',
        weburl: '',
        logo: '',
        phone: '',
        ipo: '',
        marketCapitalization: 0,
        shareOutstanding: 0,
        description: '',
        exchange: 'NSE',
      );
    }
  }
  
  /// Safely convert a value to double, handling null and type issues
  static double _safeDouble(dynamic value, [double? defaultValue]) {
    if (value == null) return defaultValue ?? 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is num) return value.toDouble();
    try {
      return double.parse(value.toString());
    } catch (e) {
      return defaultValue ?? 0.0;
    }
  }
  
  /// Safely convert a value to nullable double, handling null and type issues
  static double? _safeDoubleNullable(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is num) return value.toDouble();
    try {
      return double.parse(value.toString());
    } catch (e) {
      return null;
    }
  }
}

