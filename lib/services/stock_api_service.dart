import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/stock_quote.dart';
import '../models/company_profile.dart';
import '../models/news_article.dart';
import 'database_service.dart';
import 'local_stocks_database.dart';
import 'indian_stock_api_service.dart';
import 'indian_news_service.dart';
import '../utils/market_detector.dart';

class StockApiService {
  // Direct Finnhub API calls - NO BACKEND NEEDED
  static const String _baseUrl = 'https://finnhub.io/api/v1';
  static const String _corsProxy = 'https://api.allorigins.win/raw?url=';
  static const String _corsProxyAlt = 'https://corsproxy.io/?';
  static const List<String> _corsProxyFallbacks = [
    'https://api.allorigins.win/raw?url=',
    'https://corsproxy.io/?',
    'https://cors-anywhere.herokuapp.com/',
    'https://api.codetabs.com/v1/proxy?quest=',
    'https://r.jina.ai/http://',
  ];
  static String? _apiKey;
  
  // Simple in-memory cache (TTL: 60 seconds for quotes, 5 minutes for profiles/metrics)
  static final Map<String, _CachedData> _cache = {};
  
  // Rate limiting: Track API calls per minute
  static final List<DateTime> _apiCallHistory = [];
  static const int _maxCallsPerMinute = 50; // Stay under 60/min limit with buffer
  static const int _maxCallsPerSecond = 2; // Max 2 calls per second
  
  // Extended cache TTLs to save API credits (60/day limit)
  static const _quoteCacheTTL = Duration(minutes: 5); // Extended from 60 seconds to 5 minutes
  static const _profileCacheTTL = Duration(minutes: 30); // Extended from 5 to 30 minutes
  static const _metricsCacheTTL = Duration(minutes: 30); // Extended from 5 to 30 minutes
  
  /// Check if we can make an API call (rate limiting)
  static Future<void> _waitForRateLimit() async {
    final now = DateTime.now();
    
    // Remove old entries (older than 1 minute)
    _apiCallHistory.removeWhere((time) => now.difference(time).inMinutes >= 1);
    
    // Check per-minute limit
    if (_apiCallHistory.length >= _maxCallsPerMinute) {
      final oldestCall = _apiCallHistory.first;
      final waitTime = Duration(seconds: 60 - now.difference(oldestCall).inSeconds + 1);
      print('⏳ Rate limit: ${_apiCallHistory.length}/$_maxCallsPerMinute calls in last minute. Waiting ${waitTime.inSeconds}s...');
      await Future.delayed(waitTime);
      _apiCallHistory.removeWhere((time) => now.difference(time).inMinutes >= 1);
    }
    
    // Check per-second limit (max 2 calls per second)
    final recentCalls = _apiCallHistory.where((time) => now.difference(time).inSeconds < 1).length;
    if (recentCalls >= _maxCallsPerSecond) {
      final waitTime = Duration(milliseconds: 500);
      print('⏳ Rate limit: $recentCalls calls in last second. Waiting 500ms...');
      await Future.delayed(waitTime);
    }
    
    // Record this API call
    _apiCallHistory.add(DateTime.now());
  }

  static Future<void> init() async {
    try {
      await dotenv.load(fileName: ".env");
      _apiKey = dotenv.env['FINNHUB_API_KEY'];
      
      if (_apiKey == null || _apiKey!.isEmpty) {
        _apiKey = 'd2imrl9r01qhm15b6ufgd2imrl9r01qhm15b6ug0';
      }
      
      print('🔑 Using Finnhub API key: ${_apiKey!.substring(0, 8)}...');
    } catch (e) {
      print('Could not load .env file: $e');
      _apiKey = 'd2imrl9r01qhm15b6ufgd2imrl9r01qhm15b6ug0';
      print('🔑 Using hardcoded API key: ${_apiKey!.substring(0, 8)}...');
    }
  }

  static Future<http.Response> _makeRequest(String url) async {
    // On web, ALWAYS use CORS proxy for Yahoo Finance to avoid CORS blocking
    // Check for any Yahoo Finance domain
    final isYahooFinance = url.contains('yahoo.com') || 
                          url.contains('finance.yahoo.com') ||
                          url.contains('query1.finance.yahoo.com') ||
                          url.contains('query2.finance.yahoo.com');
    
    if (kIsWeb && isYahooFinance) {
      print('🌐 [WEB] Using CORS proxy for Yahoo Finance API: $url');
      for (int i = 0; i < _corsProxyFallbacks.length; i++) {
        final proxyBase = _corsProxyFallbacks[i];
        String proxyUrl;
        
        // Handle different proxy URL formats
        if (proxyBase.contains('jina.ai')) {
          proxyUrl = '${proxyBase}${url.replaceFirst('https://', '')}';
        } else if (proxyBase.contains('codetabs.com')) {
          proxyUrl = '$proxyBase$url';
        } else if (proxyBase.contains('herokuapp.com')) {
          proxyUrl = '$proxyBase$url';
        } else {
          proxyUrl = '$proxyBase${Uri.encodeComponent(url)}';
        }
        
        print('🌐 [WEB] Trying proxy ${i + 1}/${_corsProxyFallbacks.length}: ${proxyBase.split('/')[2]}');
        try {
          final response = await http.get(
            Uri.parse(proxyUrl),
            headers: {
              'Accept': 'application/json',
              'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
            },
          ).timeout(const Duration(seconds: 30));
          print('🌐 [WEB] Proxy response: ${response.statusCode}, body length: ${response.body.length}');
          
          if (response.statusCode == 200 && response.body.isNotEmpty) {
            final trimmedBody = response.body.trim();
            // Check if it's JSON (starts with { or [)
            if (trimmedBody.startsWith('{') || trimmedBody.startsWith('[')) {
              print('✅ [WEB] Proxy succeeded: ${proxyBase.split('/')[2]}');
              // Handle different proxy response formats
              try {
                // Parse the response to check structure
                final parsedResponse = jsonDecode(trimmedBody);
                
                if (parsedResponse is Map) {
                  // Handle r.jina.ai JSON API format: {"code":200,"data":{"content":"{...json string...}"}}
                  if (parsedResponse.containsKey('data') && parsedResponse['data'] is Map) {
                    final dataMap = parsedResponse['data'] as Map;
                    if (dataMap.containsKey('content') && dataMap['content'] is String) {
                      print('   🔄 Detected r.jina.ai JSON API format - extracting from data.content...');
                      // The content field contains the actual Yahoo Finance JSON as an escaped string
                      final contentJson = dataMap['content'] as String;
                      // Validate it's valid JSON by parsing
                      jsonDecode(contentJson); // Will throw if invalid
                      print('   ✅ Successfully extracted JSON from data.content');
                      // Return just the content JSON (the actual Yahoo Finance response)
                      return http.Response(
                        contentJson,
                        response.statusCode,
                        headers: response.headers,
                      );
                    }
                  }
                  
                  // Handle r.jina.ai Markdown format (legacy, if still used)
                  if (proxyBase.contains('jina.ai') && trimmedBody.contains('Markdown Content:')) {
                    print('   🔄 Detected r.jina.ai Markdown format, extracting JSON...');
                    final markdownIndex = trimmedBody.indexOf('Markdown Content:');
                    if (markdownIndex != -1) {
                      final jsonStart = trimmedBody.indexOf('{', markdownIndex);
                      if (jsonStart != -1) {
                        final extractedJson = trimmedBody.substring(jsonStart);
                        jsonDecode(extractedJson); // Validate
                        print('   ✅ Successfully extracted JSON from Markdown');
                        return http.Response(
                          extractedJson,
                          response.statusCode,
                          headers: response.headers,
                        );
                      }
                    }
                  }
                  
                  // AllOrigins.win format: {"contents": "{...actual json...}"}
                  if (parsedResponse.containsKey('contents') && parsedResponse['contents'] is String) {
                    print('   🔄 Unwrapping AllOrigins.win format from "contents" field...');
                    final contents = jsonDecode(parsedResponse['contents'] as String);
                    return http.Response(
                      jsonEncode(contents),
                      response.statusCode,
                      headers: response.headers,
                    );
                  }
                  
                  // If it already has "chart" key, it's the correct format
                  if (parsedResponse.containsKey('chart')) {
                    print('   ✅ Response already has "chart" key, using as-is');
                    return response;
                  }
                }
              } catch (e) {
                print('   ⚠️ Could not pre-parse response: $e');
              }
              return response;
            } else {
              print('⚠️ [WEB] Proxy responded but body not JSON (showing first 200 chars): ${response.body.substring(0, response.body.length > 200 ? 200 : response.body.length)}');
            }
          } else {
            print('❌ [WEB] Proxy error: status ${response.statusCode}. Body preview: ${response.body.length > 120 ? response.body.substring(0, 120) : response.body}');
          }
        } catch (e, stack) {
          print('❌ [WEB] Proxy request ${i + 1} failed for ${proxyBase.split('/')[2]}: $e');
          // Don't print full stack for timeout to reduce noise
          if (!e.toString().contains('timeout')) {
            print('Stack: $stack');
          }
        }
      }
      print('❌ [WEB] All ${_corsProxyFallbacks.length} CORS proxies failed for Yahoo Finance');
      print('   Attempted proxies: ${_corsProxyFallbacks.map((p) => p.split('/')[2]).join(", ")}');
      print('   This is likely a network/firewall issue or all proxies are down');
      throw Exception('CORS proxy failure for Yahoo Finance: All ${_corsProxyFallbacks.length} proxies failed');
    }
    
    try {
      // Try direct request first with shorter timeout
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Accept': 'application/json',
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
          'Origin': 'http://localhost:8080',
          'Referer': 'http://localhost:8080',
        },
      ).timeout(const Duration(seconds: 8));
      
      if (response.statusCode == 200 || response.statusCode == 401 || response.statusCode == 429) {
        return response;
      }
      
      // If CORS error, try with proxy
      if (response.statusCode == 403 || response.statusCode == 0) {
        print('🔄 CORS error detected (status ${response.statusCode}), trying with proxy...');
        final proxyUrl = '$_corsProxy${Uri.encodeComponent(url)}';
        return await http.get(
          Uri.parse(proxyUrl),
          headers: {
            'Accept': 'application/json',
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
          },
        ).timeout(const Duration(seconds: 30));
      }
      
      return response;
    } catch (e) {
      print('❌ Direct request failed: $e, trying with proxy...');
      if (kIsWeb) {
        final proxyUrl = '$_corsProxy${Uri.encodeComponent(url)}';
        return await http.get(
          Uri.parse(proxyUrl),
          headers: {
            'Accept': 'application/json',
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
          },
        ).timeout(const Duration(seconds: 30));
      }
      rethrow;
    }
  }

  static Future<StockQuote> getQuote(String symbol) async {
    if (symbol.isEmpty) {
      print('❌ Empty symbol provided');
      throw Exception('Empty symbol provided');
    }
    
    // Normalize Indian symbol if needed
    final normalizedSymbol = MarketDetector.isIndianStock(symbol) 
        ? MarketDetector.normalizeIndianSymbol(symbol)
        : symbol.toUpperCase();
    
    // Check in-memory cache first
    final cacheKey = 'quote_$normalizedSymbol';
    final cached = _cache[cacheKey];
    if (cached != null && cached.isValid(_quoteCacheTTL)) {
      print('✅ Using in-memory cached quote for $normalizedSymbol');
      return cached.data as StockQuote;
    }
    
    // Check database cache (1 minute TTL)
    try {
      final dbCached = await DatabaseService.getCachedQuote(normalizedSymbol);
      if (dbCached != null) {
        print('✅ Using database cached quote for $normalizedSymbol');
        final quote = StockQuote.fromJson(dbCached);
        // Also update in-memory cache
        _cache[cacheKey] = _CachedData(quote, DateTime.now());
        return quote;
      }
    } catch (e) {
      print('⚠️ Database cache check failed: $e');
    }
    
    // Route to appropriate API based on market
    if (MarketDetector.isIndianStock(normalizedSymbol)) {
      print('🇮🇳 Fetching REAL quote for $normalizedSymbol (Indian stock)...');
      return await _getQuoteFromIndianAPI(normalizedSymbol, cacheKey);
    } else {
      print('🇺🇸 Fetching REAL quote for $normalizedSymbol from Finnhub (US stock)...');
      return await _getQuoteFromFinnhub(normalizedSymbol, cacheKey);
    }
  }
  
  /// Get quote from Alpha Vantage API (Indian stocks)
  static Future<StockQuote> _getQuoteFromIndianAPI(String symbol, String cacheKey) async {
    try {
      print('📡 [AlphaVantage] Fetching quote for Indian stock...');
      final quote = await IndianStockApiService.getQuote(symbol);
      
      // Cache in memory
      _cache[cacheKey] = _CachedData(quote, DateTime.now());
      
      // Cache in database
      try {
        await DatabaseService.saveCachedQuote(symbol, quote.toJson());
      } catch (e) {
        print('⚠️ Failed to save to database cache: $e');
      }
      
      print('✅ [AlphaVantage] Successfully got quote');
      return quote;
    } catch (e) {
      print('❌ [AlphaVantage] API failed: $e');
      // Try stale cache as fallback
      final staleCache = await _getStaleCache(symbol);
      if (staleCache != null) {
        print('✅ [STALE CACHE FALLBACK] Using stale data for $symbol');
        return staleCache;
      }
      rethrow;
    }
  }
  
  /// Get quote from Finnhub (for US stocks)
  static Future<StockQuote> _getQuoteFromFinnhub(String symbol, String cacheKey) async {
    
    try {
      // Rate limiting: Wait if needed
      await _waitForRateLimit();
      
      // Direct Finnhub API call
      final finnhubUrl = '$_baseUrl/quote?symbol=$symbol&token=$_apiKey';
      print('📡 Direct Finnhub API call: $finnhubUrl (${_apiCallHistory.length}/$_maxCallsPerMinute calls this minute)');
    
      final response = await _makeRequest(finnhubUrl);

      print('📊 Finnhub Response status: ${response.statusCode}');
    
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('📈 Finnhub API response for $symbol: $data');
        
        // Check if we got valid data (not all zeros or null)
        if (data['c'] != null && data['c'] != 0) {
          print('✅ Got REAL data for $symbol: \$${data['c']}');
          // Add the symbol to the data before creating StockQuote
          data['symbol'] = symbol;
          final quote = StockQuote.fromJson(data);
          
          // Cache in memory
          _cache[cacheKey] = _CachedData(quote, DateTime.now());
          
          // Cache in database (1 minute TTL)
          try {
            await DatabaseService.saveCachedQuote(symbol, data);
          } catch (e) {
            print('⚠️ Failed to save to database cache: $e');
          }
          
          return quote;
        } else {
          print('⚠️ Invalid data from Finnhub (c=${data['c']})');
          throw Exception('Invalid data from Finnhub API');
        }
      } else if (response.statusCode == 429) {
        print('⚠️ Rate limit exceeded - trying stale cache as fallback...');
        // Try to get stale cache as fallback
        final staleCache = await _getStaleCache(symbol);
        if (staleCache != null) {
          print('✅ [STALE CACHE FALLBACK] Using stale data for $symbol: \$${staleCache.currentPrice}');
          return staleCache;
        }
        throw Exception('Rate limit exceeded and no stale cache available');
      } else if (response.statusCode == 401) {
        print('❌ API key invalid');
        throw Exception('API key invalid');
      } else if (response.statusCode == 403) {
        print('❌ Access forbidden - CORS or API restrictions');
        throw Exception('Access forbidden - CORS or API restrictions');
      } else {
        print('❌ Finnhub API failed with status ${response.statusCode}');
        // Try stale cache as fallback
        final staleCache = await _getStaleCache(symbol);
        if (staleCache != null) {
          print('✅ [STALE CACHE FALLBACK] Using stale data for $symbol after API error');
          return staleCache;
        }
        throw Exception('Finnhub API failed with status ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Finnhub API failed: $e');
      // Last resort: try stale cache
      if (e.toString().contains('Rate limit') || e.toString().contains('429')) {
        try {
          final staleCache = await _getStaleCache(symbol);
          if (staleCache != null) {
            print('✅ [STALE CACHE FALLBACK] Using stale data for $symbol after exception');
            return staleCache;
          }
        } catch (cacheError) {
          print('❌ Stale cache also failed: $cacheError');
        }
      }
      rethrow;
    }
  }

  static Future<CompanyProfile> getCompanyProfile(String symbol) async {
    if (symbol.isEmpty) {
      print('❌ Empty symbol provided');
      throw Exception('Empty symbol provided');
    }
    
    // Normalize Indian symbol if needed
    final normalizedSymbol = MarketDetector.isIndianStock(symbol) 
        ? MarketDetector.normalizeIndianSymbol(symbol)
        : symbol.toUpperCase();
    
    // Check in-memory cache first
    final cacheKey = 'profile_$normalizedSymbol';
    final cached = _cache[cacheKey];
    if (cached != null && cached.isValid(_profileCacheTTL)) {
      print('✅ Using in-memory cached profile for $normalizedSymbol');
      return cached.data as CompanyProfile;
    }
    
    // Check database cache (5 minute TTL)
    try {
      final dbCached = await DatabaseService.getCachedProfile(normalizedSymbol);
      if (dbCached != null) {
        print('✅ Using database cached profile for $normalizedSymbol');
        final profile = CompanyProfile.fromJson(dbCached);
        // Also update in-memory cache
        _cache[cacheKey] = _CachedData(profile, DateTime.now());
        return profile;
      }
    } catch (e) {
      print('⚠️ Database cache check failed: $e');
    }
    
    // Route to appropriate API based on market
    if (MarketDetector.isIndianStock(normalizedSymbol)) {
      print('🇮🇳 Fetching REAL profile for $normalizedSymbol (Indian stock)...');
      return await _getProfileFromIndianAPI(normalizedSymbol, cacheKey);
    } else {
      print('🇺🇸 Fetching REAL profile for $normalizedSymbol from Finnhub (US stock)...');
      return await _getProfileFromFinnhub(normalizedSymbol, cacheKey);
    }
  }
  
  /// Get profile from Breeze API (Indian stocks)
  static Future<CompanyProfile> _getProfileFromIndianAPI(String symbol, String cacheKey) async {
    try {
      print('📡 [Breeze] Fetching profile...');
      final profile = await IndianStockApiService.getCompanyProfile(symbol);
      
      // Cache in memory
      _cache[cacheKey] = _CachedData(profile, DateTime.now());
      
      // Cache in database
      try {
        await DatabaseService.saveCachedProfile(symbol, {
          'name': profile.name,
          'ticker': profile.ticker,
          'country': profile.country,
          'currency': profile.currency,
          'industry': profile.industry,
          'weburl': profile.weburl,
          'logo': profile.logo,
          'phone': profile.phone,
          'marketCapitalization': profile.marketCapitalization,
          'shareOutstanding': profile.shareOutstanding,
          'description': profile.description,
          'exchange': profile.exchange,
        });
      } catch (e) {
        print('⚠️ Failed to save profile to database cache: $e');
      }
      
      return profile;
    } catch (e) {
      print('❌ [Breeze] Profile API failed: $e');
      // Try stale cache as fallback
      try {
        final dbCached = await DatabaseService.getCachedProfile(symbol);
        if (dbCached != null) {
          print('✅ [STALE CACHE FALLBACK] Using stale profile');
          return CompanyProfile.fromJson(dbCached);
        }
      } catch (cacheError) {
        print('❌ Stale profile cache also failed: $cacheError');
      }
      rethrow;
    }
  }
  
  /// Get profile from Finnhub (for US stocks)
  static Future<CompanyProfile> _getProfileFromFinnhub(String symbol, String cacheKey) async {
    
    try {
      // Rate limiting: Wait if needed
      await _waitForRateLimit();
      
      // Direct Finnhub API call
      final finnhubUrl = '$_baseUrl/stock/profile2?symbol=$symbol&token=$_apiKey';
      print('📡 Direct Finnhub API call: $finnhubUrl (${_apiCallHistory.length}/$_maxCallsPerMinute calls this minute)');
    
      final response = await _makeRequest(finnhubUrl);

      print('📊 Finnhub Profile Response status: ${response.statusCode}');
    
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('🏢 Finnhub Profile API response for $symbol: $data');
        
        if (data['name'] != null && data['name'].isNotEmpty) {
          print('✅ Got REAL profile for $symbol: ${data['name']}');
          final profile = CompanyProfile.fromJson(data);
          
          // Cache in memory
          _cache[cacheKey] = _CachedData(profile, DateTime.now());
          
          // Cache in database (5 minute TTL)
          try {
            await DatabaseService.saveCachedProfile(symbol, data);
          } catch (e) {
            print('⚠️ Failed to save profile to database cache: $e');
          }
          
          return profile;
        } else {
          print('⚠️ Invalid profile data from Finnhub');
          throw Exception('Invalid profile data from Finnhub API');
        }
      } else if (response.statusCode == 429) {
        print('⚠️ Rate limit exceeded for profile - returning cached if available');
        // Profile cache is longer (30 min), so stale data is more acceptable
        final dbCached = await DatabaseService.getCachedProfile(symbol);
        if (dbCached != null) {
          print('✅ [STALE CACHE FALLBACK] Using stale profile for $symbol');
          return CompanyProfile.fromJson(dbCached);
        }
        throw Exception('Rate limit exceeded and no cached profile available');
      } else if (response.statusCode == 401) {
        print('❌ API key invalid');
        throw Exception('API key invalid');
      } else {
        print('❌ Finnhub Profile API failed with status ${response.statusCode}');
        // Try stale cache as fallback
        final dbCached = await DatabaseService.getCachedProfile(symbol);
        if (dbCached != null) {
          print('✅ [STALE CACHE FALLBACK] Using stale profile after API error');
          return CompanyProfile.fromJson(dbCached);
        }
        throw Exception('Finnhub Profile API failed with status ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Finnhub Profile API failed: $e');
      // Last resort: try stale cache
      try {
        final dbCached = await DatabaseService.getCachedProfile(symbol);
        if (dbCached != null) {
          print('✅ [STALE CACHE FALLBACK] Using stale profile after exception');
          return CompanyProfile.fromJson(dbCached);
        }
      } catch (cacheError) {
        print('❌ Stale profile cache also failed: $cacheError');
      }
      rethrow;
    }
  }

  static Future<List<NewsArticle>> getCompanyNews(String symbol) async {
    if (symbol.isEmpty) {
      print('❌ Empty symbol provided');
      throw Exception('Empty symbol provided');
    }
    
    // Normalize Indian symbol if needed
    final normalizedSymbol = MarketDetector.isIndianStock(symbol) 
        ? MarketDetector.normalizeIndianSymbol(symbol)
        : symbol.toUpperCase();
    
    // Route to appropriate API based on market
    if (MarketDetector.isIndianStock(normalizedSymbol)) {
      print('🇮🇳 Fetching news for Indian stock $normalizedSymbol...');
      return await IndianNewsService.getCompanyNews(normalizedSymbol);
    } else {
      print('🇺🇸 Fetching REAL news for $normalizedSymbol from Finnhub...');
      return await _getNewsFromFinnhub(normalizedSymbol);
    }
  }
  
  /// Get news from Finnhub (for US stocks)
  static Future<List<NewsArticle>> _getNewsFromFinnhub(String symbol) async {
    try {
      // Get date range for last 7 days
      final now = DateTime.now();
      final weekAgo = now.subtract(const Duration(days: 7));
      final from = weekAgo.toIso8601String().split('T')[0];
      final to = now.toIso8601String().split('T')[0];
      
      // Direct Finnhub API call
      final finnhubUrl = '$_baseUrl/company-news?symbol=$symbol&from=$from&to=$to&token=$_apiKey';
      print('📡 Direct Finnhub API call: $finnhubUrl');
    
      final response = await _makeRequest(finnhubUrl);

      print('📊 Finnhub News Response status: ${response.statusCode}');
    
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        print('📰 Finnhub News API response for $symbol: ${data.length} articles');
        
        if (data.isNotEmpty) {
          print('✅ Got ${data.length} REAL news articles for $symbol');
          return data.take(10).map((item) => NewsArticle.fromJson(item)).toList();
        } else {
          print('⚠️ No news data from Finnhub');
          return []; // Return empty list instead of throwing
        }
      } else if (response.statusCode == 429) {
        print('⚠️ Rate limit exceeded');
        return []; // Return empty list instead of throwing
      } else if (response.statusCode == 401) {
        print('❌ API key invalid');
        return []; // Return empty list instead of throwing
      } else {
        print('❌ Finnhub News API failed with status ${response.statusCode}');
        return []; // Return empty list instead of throwing
      }
    } catch (e) {
      print('❌ Finnhub News API failed: $e');
      return []; // Return empty list instead of throwing
    }
  }

  static Future<List<NewsArticle>> getMarketNews({bool isIndianMarket = false}) async {
    // If user is viewing Indian stocks, get Indian market news
    if (isIndianMarket) {
      print('📰 Fetching Indian market news...');
      try {
        return await IndianNewsService.getMarketNews();
      } catch (e) {
        print('❌ Indian market news failed: $e');
        // Fallback to US news
        return await _getUSMarketNews();
      }
    }
    
    // Default to US market news
    return await _getUSMarketNews();
  }
  
  /// Get US market news from Finnhub
  static Future<List<NewsArticle>> _getUSMarketNews() async {
    print('📰 Fetching REAL market news from Finnhub...');
    
    try {
      // Get date range for last 7 days
      final now = DateTime.now();
      final weekAgo = now.subtract(const Duration(days: 7));
      final from = weekAgo.toIso8601String().split('T')[0];
      final to = now.toIso8601String().split('T')[0];
      
      // Use AAPL news as general market news
      final finnhubUrl = '$_baseUrl/company-news?symbol=AAPL&from=$from&to=$to&token=$_apiKey';
      print('📡 Direct Finnhub API call: $finnhubUrl');
    
      final response = await _makeRequest(finnhubUrl);

      print('📊 Finnhub Market News Response status: ${response.statusCode}');
    
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        print('📰 Finnhub Market News API response: ${data.length} articles');
        
        if (data.isNotEmpty) {
          print('✅ Got ${data.length} REAL market news articles');
          return data.take(20).map((item) => NewsArticle.fromJson(item)).toList();
        } else {
          print('⚠️ No market news data from Finnhub');
          throw Exception('No market news data from Finnhub API');
        }
      } else if (response.statusCode == 429) {
        print('⚠️ Rate limit exceeded');
        throw Exception('Rate limit exceeded');
      } else if (response.statusCode == 401) {
        print('❌ API key invalid');
        throw Exception('API key invalid');
      } else {
        print('❌ Finnhub Market News API failed with status ${response.statusCode}');
        throw Exception('Finnhub Market News API failed with status ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Finnhub Market News API failed: $e');
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> getFinancialMetrics(String symbol) async {
    if (symbol.isEmpty) {
      print('❌ Empty symbol provided');
      throw Exception('Empty symbol provided');
    }
    
    // Normalize Indian symbol if needed
    final normalizedSymbol = MarketDetector.isIndianStock(symbol) 
        ? MarketDetector.normalizeIndianSymbol(symbol)
        : symbol.toUpperCase();
    
    // Check cache first
    final cacheKey = 'metrics_$normalizedSymbol';
    final cached = _cache[cacheKey];
    if (cached != null && cached.isValid(_metricsCacheTTL)) {
      print('✅ Using cached metrics for $normalizedSymbol');
      return cached.data as Map<String, dynamic>;
    }
    
    // Route to appropriate API based on market
    if (MarketDetector.isIndianStock(normalizedSymbol)) {
      print('🇮🇳 Fetching REAL financial metrics for $normalizedSymbol (Indian stock)...');
      return await _getMetricsFromIndianAPI(normalizedSymbol, cacheKey);
    } else {
      print('🇺🇸 Fetching REAL financial metrics for $normalizedSymbol from Finnhub (US stock)...');
      return await _getMetricsFromFinnhub(normalizedSymbol, cacheKey);
    }
  }
  
  /// Get metrics from Breeze API (Indian stocks)
  static Future<Map<String, dynamic>> _getMetricsFromIndianAPI(String symbol, String cacheKey) async {
    try {
      print('📡 [Breeze] Fetching metrics...');
      final metrics = await IndianStockApiService.getFinancialMetrics(symbol);
      
      if (metrics.isNotEmpty) {
        // Cache the result
        _cache[cacheKey] = _CachedData(metrics, DateTime.now());
        print('✅ [Breeze] Successfully got metrics');
        return metrics;
      } else {
        print('⚠️ [Breeze] Returned empty metrics');
        return {};
      }
    } catch (e) {
      print('❌ [Breeze] Metrics API failed: $e');
      return {};
    }
  }
  
  /// Get metrics from Finnhub (for US stocks)
  static Future<Map<String, dynamic>> _getMetricsFromFinnhub(String symbol, String cacheKey) async {
    
    try {
      // Direct Finnhub API call for financial metrics
      final finnhubUrl = '$_baseUrl/stock/metric?symbol=$symbol&metric=all&token=$_apiKey';
      print('📡 Direct Finnhub API call: $finnhubUrl');
    
      final response = await _makeRequest(finnhubUrl);

      print('📊 Finnhub Metrics Response status: ${response.statusCode}');
    
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('📊 Finnhub Metrics API response for $symbol: ${data.keys.length} metrics');
        
        if (data.isNotEmpty && data['metric'] != null) {
          // Extract key financial metrics from the nested metric object
          final metricData = data['metric'] as Map<String, dynamic>;
          final metrics = <String, dynamic>{};
          
          // The API returns data in data['metric'] - extract from there
          if (metricData['peTTM'] != null) {
            metrics['pe'] = (metricData['peTTM'] as num).toDouble();
          }
          
          if (metricData['dividendYieldIndicatedAnnual'] != null) {
            // Finnhub returns dividend yield as a decimal (0.007121 = 0.7121%)
            // Dividend yields are typically 0-0.1 (0-10%) as decimals
            // If value is > 1, it's likely already a percentage, divide by 100
            final rawValue = (metricData['dividendYieldIndicatedAnnual'] as num).toDouble();
            // If value > 1, it's likely a percentage (e.g., 2.5 means 2.5%), convert to decimal
            // If value <= 1, it's already a decimal (e.g., 0.025 means 2.5%)
            metrics['dividendYield'] = rawValue > 1 ? rawValue / 100 : rawValue;
            print('✅ [Finnhub] Dividend Yield: $rawValue -> ${metrics['dividendYield']}');
          }
          
          if (metricData['beta'] != null) {
            metrics['beta'] = (metricData['beta'] as num).toDouble();
          }
          
          if (metricData['epsTTM'] != null) {
            metrics['eps'] = (metricData['epsTTM'] as num).toDouble();
          }
          
          if (metricData['pbQuarterly'] != null) {
            metrics['priceToBook'] = (metricData['pbQuarterly'] as num).toDouble();
          }
          
          if (metricData['psTTM'] != null) {
            metrics['priceToSales'] = (metricData['psTTM'] as num).toDouble();
          }
          
          // Use total revenue - try multiple fields from Finnhub API
          if (metricData['revenueTTM'] != null) {
            // Total revenue in millions, convert to billions
            final revenueMillions = (metricData['revenueTTM'] as num).toDouble();
            metrics['revenue'] = revenueMillions / 1e3; // Convert millions to billions
            print('📊 Revenue from revenueTTM: ${metrics['revenue']}B');
          } else if (metricData['revenuePerShareTTM'] != null && metricData['shareOutstanding'] != null) {
            // Calculate from revenue per share * shares outstanding
            final revenuePerShare = (metricData['revenuePerShareTTM'] as num).toDouble();
            final sharesOutstanding = (metricData['shareOutstanding'] as num).toDouble();
            // Shares outstanding might be in millions, so check scale
            final totalRevenue = revenuePerShare * sharesOutstanding;
            // If total revenue is > 1e12, shares were in millions, divide by 1e9 to get billions
            // If total revenue is < 1e12, shares were in actual count, divide by 1e9 to get billions
            metrics['revenue'] = totalRevenue / 1e9; // Convert to billions
            print('📊 Revenue calculated from revenuePerShare: ${metrics['revenue']}B');
          } else if (metricData['revenuePerShareTTM'] != null) {
            // Store revenue per share for later calculation with profile data
            metrics['revenuePerShare'] = (metricData['revenuePerShareTTM'] as num).toDouble();
            print('📊 Stored revenuePerShare for later calculation: ${metrics['revenuePerShare']}');
          }
          
          if (metricData['operatingMarginTTM'] != null) {
            // Operating margin is returned as a decimal (0.4594 = 45.94%)
            // But validate if it's already a percentage
            final rawValue = (metricData['operatingMarginTTM'] as num).toDouble();
            // If value is > 1, it's likely already a percentage, divide by 100
            metrics['profitMargin'] = rawValue > 1 ? rawValue / 100 : rawValue;
          }
          
          if (metricData['roeTTM'] != null) {
            // ROE is returned as a decimal (0.3153 = 31.53%)
            // But validate if it's already a percentage
            final rawValue = (metricData['roeTTM'] as num).toDouble();
            // If value is > 2 (200%), it's likely already a percentage, divide by 100
            // ROE can legitimately be > 100% for some companies, so use 2 as threshold
            metrics['returnOnEquity'] = rawValue > 2 ? rawValue / 100 : rawValue;
          }
          
          if (metricData['debtToEquity'] != null) {
            metrics['debtToEquity'] = (metricData['debtToEquity'] as num).toDouble();
          }
          
          print('✅ Extracted ${metrics.length} financial metrics for $symbol');
          print('📊 Metrics: $metrics');
          // Cache the result
          _cache[cacheKey] = _CachedData(metrics, DateTime.now());
          return metrics;
        } else {
          print('⚠️ No metrics data from Finnhub');
          throw Exception('No metrics data from Finnhub API');
        }
      } else if (response.statusCode == 429) {
        print('⚠️ Rate limit exceeded');
        throw Exception('Rate limit exceeded');
      } else if (response.statusCode == 401) {
        print('❌ API key invalid');
        throw Exception('API key invalid');
      } else {
        print('❌ Finnhub Metrics API failed with status ${response.statusCode}');
        throw Exception('Finnhub Metrics API failed with status ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Finnhub Metrics API failed: $e');
      rethrow;
    }
  }

  /// Get historical candle data - uses Yahoo Finance (FREE, no key needed)
  /// Works for both US and Indian stocks
  /// Get historical data for charting (public method)
  /// Works for both US and Indian stocks via Yahoo Finance
  static Future<List<Map<String, dynamic>>> getHistoricalDataForChart(String symbol, {int days = 365}) async {
    return await _getHistoricalData(symbol, days: days);
  }

  static Future<List<Map<String, dynamic>>> _getHistoricalData(String symbol, {int days = 365}) async {
    // Normalize Indian symbol if needed - Yahoo Finance needs .NS or .BO suffix
    final normalizedSymbol = MarketDetector.isIndianStock(symbol) 
        ? MarketDetector.normalizeIndianSymbol(symbol)
        : symbol.toUpperCase();
    
    print('📊 [HISTORICAL] Fetching $days days for $normalizedSymbol from Yahoo Finance (platform=${kIsWeb ? "web" : "native"})...');
    
    try {
      // Yahoo Finance v8 API - completely free, no key needed
      final now = DateTime.now();
      final startDate = now.subtract(Duration(days: days));
      final period1 = (startDate.millisecondsSinceEpoch / 1000).floor();
      final period2 = (now.millisecondsSinceEpoch / 1000).floor();
      
      // URL encode the symbol to handle special characters
      final encodedSymbol = Uri.encodeComponent(normalizedSymbol);
      final yahooUrl = 'https://query1.finance.yahoo.com/v8/finance/chart/$encodedSymbol?period1=$period1&period2=$period2&interval=1d';
      print('📡 [HISTORICAL] Yahoo URL: $yahooUrl');
      
      // Use _makeRequest which handles CORS proxy automatically
      print('📡 [HISTORICAL] Making request to Yahoo Finance...');
      final response = await _makeRequest(yahooUrl);
      
      print('📊 [HISTORICAL] Yahoo response: ${response.statusCode}');
      print('📊 [HISTORICAL] Response body length: ${response.body.length}');
      
      if (response.statusCode != 200) {
        print('❌ [HISTORICAL] Yahoo Finance returned status ${response.statusCode}');
        print('   Response body preview: ${response.body.length > 500 ? response.body.substring(0, 500) : response.body}');
        return [];
      }
      
      if (response.body.isEmpty) {
        print('❌ [HISTORICAL] Empty response body from Yahoo Finance');
        return [];
      }
      
      Map<String, dynamic> data;
      try {
        data = jsonDecode(response.body) as Map<String, dynamic>;
        print('✅ [HISTORICAL] Successfully parsed JSON response');
      } catch (e) {
        print('❌ [HISTORICAL] Failed to parse JSON: $e');
        print('   Response body: ${response.body.length > 500 ? response.body.substring(0, 500) : response.body}');
        return [];
      }
      
      // Debug: Print actual response structure
      print('🔍 [HISTORICAL] Response structure check:');
      print('   Top-level keys: ${data.keys.toList()}');
      if (data.containsKey('chart')) {
        final chart = data['chart'] as Map;
        print('   chart keys: ${chart.keys.toList()}');
        
        // Check for actual errors (ignore null errors - error key can exist but be null)
        final errorValue = chart['error'];
        if (errorValue != null && errorValue is String && errorValue.isNotEmpty) {
          print('❌ [HISTORICAL] Yahoo Finance error: $errorValue');
          return [];
        }
        
        // Check if result exists and has data
        if (chart.containsKey('result')) {
          final resultList = chart['result'] as List?;
          print('   result is List: ${resultList != null}, length: ${resultList?.length ?? 0}');
          if (resultList == null || resultList.isEmpty) {
            print('⚠️ [HISTORICAL] Result list is null or empty');
            // Check if there's a reason in meta or error
            if (errorValue != null && errorValue is String && errorValue.isNotEmpty) {
              print('❌ [HISTORICAL] Error in response: $errorValue');
            } else {
              print('   Error field exists but is null - this is normal, continuing...');
            }
          }
        }
      } else {
        // Proxy might wrap the response differently - try to unwrap
        print('⚠️ [HISTORICAL] No "chart" key in response, checking for wrapped response...');
        
        // Handle r.jina.ai format: {"code":200,"data":{"content":"{\"chart\":{...}}"}}
        if (data.containsKey('data') && data['data'] is Map) {
          final dataMap = data['data'] as Map<String, dynamic>;
          if (dataMap.containsKey('content') && dataMap['content'] is String) {
            print('   🔄 Found r.jina.ai format - JSON in data.content as escaped string');
            try {
              final contentString = dataMap['content'] as String;
              final unwrapped = jsonDecode(contentString) as Map<String, dynamic>;
              data = unwrapped;
              print('   ✅ Successfully extracted JSON from data.content');
            } catch (e) {
              print('   ❌ Failed to parse data.content: $e');
            }
          }
        }
        
        // Handle AllOrigins.win format: {"contents": "{...json...}"}
        if (!data.containsKey('chart') && data.containsKey('contents')) {
          print('   Found "contents" key, trying to parse as JSON...');
          try {
            final contents = data['contents'];
            if (contents is String) {
              final unwrapped = jsonDecode(contents) as Map<String, dynamic>;
              data = unwrapped;
              print('   ✅ Successfully unwrapped JSON from contents');
            }
          } catch (e) {
            print('   ❌ Failed to unwrap contents: $e');
          }
        }
        
        // Re-check after unwrapping
        if (!data.containsKey('chart')) {
          print('❌ [HISTORICAL] Still no "chart" key after unwrapping. Response keys: ${data.keys.toList()}');
          
          // Some proxies might return the data directly without "chart" wrapper
          if (data.containsKey('result') && data['result'] is List) {
            print('   🔄 Found "result" at top level, wrapping in chart structure...');
            data = {'chart': {'result': data['result']}};
            print('   ✅ Restructured response');
          } else {
            // Last resort: print what we got for debugging
            final responseStr = jsonEncode(data);
            print('   Response preview (first 800 chars): ${responseStr.length > 800 ? responseStr.substring(0, 800) : responseStr}');
            return [];
          }
        }
      }
      
      // Final check - verify chart.result exists and has data
      final chartData = data['chart'];
      if (chartData == null) {
        print('❌ [HISTORICAL] chart is null after all unwrapping attempts');
        return [];
      }
      
      final chartMap = chartData as Map<String, dynamic>;
      
      // Check for actual errors (not null)
      final chartError = chartMap['error'];
      if (chartError != null && chartError is String && chartError.isNotEmpty) {
        print('❌ [HISTORICAL] Yahoo Finance error: $chartError');
        return [];
      }
      
      final resultList = chartMap['result'];
      if (resultList == null || (resultList is List && resultList.isEmpty)) {
        print('❌ [HISTORICAL] chart.result is null or empty');
        print('   chart keys: ${chartMap.keys.toList()}');
        if (resultList != null) {
          print('   result type: ${resultList.runtimeType}, is List: ${resultList is List}');
          if (resultList is List) {
            print('   result length: ${resultList.length}');
          }
        }
        // Check if there's error info
        if (chartError != null && chartError is String && chartError.isNotEmpty) {
          print('   Error message: $chartError');
        } else {
          print('   No error message provided - symbol might not exist in Yahoo Finance');
        }
        return [];
      }
      
      if (resultList is List && resultList.isNotEmpty) {
        print('✅ [HISTORICAL] Found chart result data with ${resultList.length} items');
        final result = resultList[0] as Map<String, dynamic>;
        
        // Debug: Check result structure
        print('   Result keys: ${result.keys.toList()}');
        
        final timestamps = result['timestamp'] as List? ?? [];
        print('   Timestamps count: ${timestamps.length}');
        
        final indicatorsMap = result['indicators'] as Map?;
        if (indicatorsMap == null) {
          print('❌ [HISTORICAL] No indicators object in result');
          print('   Available keys in result: ${result.keys.toList()}');
          return [];
        }
        
        final quotesList = indicatorsMap['quote'] as List?;
        if (quotesList == null || quotesList.isEmpty) {
          print('❌ [HISTORICAL] No quote array in indicators');
          print('   Indicators keys: ${indicatorsMap.keys.toList()}');
          return [];
        }
        
        final quotes = quotesList[0] as Map<String, dynamic>?;
        if (quotes == null) {
          print('❌ [HISTORICAL] No quote data from Yahoo (quotes array is empty)');
          return [];
        }
        
        print('   Quote keys: ${quotes.keys.toList()}');
        
        final closes = quotes['close'] as List? ?? [];
        final highs = quotes['high'] as List? ?? [];
        final lows = quotes['low'] as List? ?? [];
        final opens = quotes['open'] as List? ?? [];
        final volumes = quotes['volume'] as List? ?? [];
        
        print('   Data arrays length - closes: ${closes.length}, highs: ${highs.length}, lows: ${lows.length}');
        
        if (closes.isEmpty) {
          print('⚠️ [HISTORICAL] Empty price data from Yahoo (closes array is empty)');
          print('   This might mean the symbol has no trading history or is invalid');
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
        
        print('✅ [HISTORICAL] Got ${ohlcData.length} data points from Yahoo Finance');
        return ohlcData;
      } else {
        print('⚠️ [HISTORICAL] No result data in Yahoo response');
        return [];
      }
    } catch (e, stack) {
      print('❌ [HISTORICAL] Yahoo Finance error: $e');
      print('Stack: $stack');
      return [];
    }
  }

  /// Calculate technical indicators from historical data
  /// This is FREE - no premium API needed!
  /// Works for both US and Indian stocks
  static Future<Map<String, dynamic>> getTechnicalIndicators(String symbol) async {
    if (symbol.isEmpty) {
      print('❌ Empty symbol provided');
      return {};
    }
    
    // Normalize Indian symbol if needed
    final normalizedSymbol = MarketDetector.isIndianStock(symbol) 
        ? MarketDetector.normalizeIndianSymbol(symbol)
        : symbol.toUpperCase();
    
      print('📈 [INDICATORS] Calculating for $normalizedSymbol...');
    
    try {
      // Get historical data (FREE endpoint - works for both markets)
      // Increased timeout to 60 seconds for web CORS proxy
      print('📡 [INDICATORS] Starting historical data fetch for $normalizedSymbol...');
      final historicalData = await _getHistoricalData(normalizedSymbol, days: 365).timeout(
        const Duration(seconds: 60),
        onTimeout: () {
          print('⏱️ [INDICATORS] Historical data fetch timed out after 60 seconds');
          print('   This is likely a CORS or network issue');
          return <Map<String, dynamic>>[];
        },
      );
      
      print('📊 [INDICATORS] Got ${historicalData.length} days of historical data');
      
      if (historicalData.isEmpty) {
        print('❌ [INDICATORS] No historical data available for $normalizedSymbol');
        print('   This might be because:');
        print('   1. Symbol not found in Yahoo Finance');
        print('   2. Network timeout');
        print('   3. Invalid symbol format');
        print('   4. CORS blocking (web only)');
        print('   ⚠️ Returning empty indicators map');
        return {};
      }
      
      print('✅ [INDICATORS] Successfully fetched ${historicalData.length} data points');
      
      // Use the proper TechnicalIndicatorsCalculator class for accurate calculations
      final calculator = _TechnicalIndicatorsCalculator();
      
      // Calculate indicators using proper formulas
      final closes = historicalData.map((d) => (d['c'] as num).toDouble()).toList();
      final highs = historicalData.map((d) => (d['h'] as num?)?.toDouble() ?? (d['c'] as num).toDouble()).toList();
      final lows = historicalData.map((d) => (d['l'] as num?)?.toDouble() ?? (d['c'] as num).toDouble()).toList();
      
      final indicators = <String, dynamic>{};
      
      // ========== MOMENTUM INDICATORS ==========
      
      // RSI (Relative Strength Index) - 14 period using Wilder's smoothing method
      final rsi = calculator.calculateRSI(historicalData, period: 14);
      indicators['rsi'] = rsi;
      indicators['RSI'] = {
        'value': rsi.toStringAsFixed(2), 
        'signal': rsi > 70 ? 'Overbought' : (rsi < 30 ? 'Oversold' : 'Neutral')
      };
      
      // ========== TREND INDICATORS ==========
      
      // SMA (Simple Moving Average) - 20-day
      final sma20 = calculator.calculateSMA(historicalData, period: 20);
      indicators['sma'] = sma20;
      indicators['sma20'] = sma20;
      indicators['SMA'] = {'value': sma20.toStringAsFixed(2)};
      indicators['SMA20'] = {'value': sma20.toStringAsFixed(2)};
      
      // SMA 50-day
      final sma50 = closes.length >= 50 
          ? calculator.calculateSMA(historicalData, period: 50)
          : closes.last;
      indicators['sma50'] = sma50;
      indicators['SMA50'] = {'value': sma50.toStringAsFixed(2)};
      
      // SMA 200-day
      final sma200 = closes.length >= 200
          ? calculator.calculateSMA(historicalData, period: 200)
          : closes.last;
      indicators['sma200'] = sma200;
      indicators['SMA200'] = {'value': sma200.toStringAsFixed(2)};
      
      // EMA (Exponential Moving Average) - 12 and 26 (proper exponential calculation)
      final ema12 = calculator.calculateEMA(historicalData, period: 12);
      final ema26 = calculator.calculateEMA(historicalData, period: 26);
      indicators['ema12'] = ema12;
      indicators['ema26'] = ema26;
      
      // ========== OSCILLATORS ==========
      
      // MACD (Moving Average Convergence Divergence) with proper signal line
      final macdData = calculator.calculateMACD(historicalData);
      final macd = macdData['macd']!;
      final macdSignal = macdData['signal']!;
      final macdHistogram = macdData['histogram']!;
      
      // Store both lowercase and uppercase keys for compatibility
      indicators['macd'] = macd;
      indicators['MACD'] = {
        'value': macd.toStringAsFixed(2),
        'signal': macdSignal.toStringAsFixed(2),
        'histogram': macdHistogram.toStringAsFixed(2),
      };
      // Also store as a map for easier access
      indicators['macdValue'] = macd;
      indicators['macdSignal'] = macdSignal;
      indicators['macdHistogram'] = macdHistogram;
      
      // Stochastic Oscillator (14, 3, 3)
      double stochK = 50.0;
      double stochD = 50.0;
      if (closes.length >= 14 && highs.length >= 14 && lows.length >= 14) {
        final recent14Highs = highs.sublist(highs.length - 14);
        final recent14Lows = lows.sublist(lows.length - 14);
        final highestHigh = recent14Highs.reduce((a, b) => a > b ? a : b);
        final lowestLow = recent14Lows.reduce((a, b) => a < b ? a : b);
        final currentClose = closes.last;
        
        if (highestHigh != lowestLow) {
          stochK = ((currentClose - lowestLow) / (highestHigh - lowestLow)) * 100;
          // StochD is 3-period SMA of StochK (simplified)
          stochD = stochK;
        }
      }
      indicators['stochastic'] = stochK;
      indicators['Stochastic'] = {
        'value': stochK.toStringAsFixed(2),
        'signal': stochK > 80 ? 'Overbought' : (stochK < 20 ? 'Oversold' : 'Neutral'),
      };
      
      // ========== VOLATILITY INDICATORS ==========
      
      // Bollinger Bands (20-day, 2 std dev)
      double bbUpper = closes.last;
      double bbMiddle = sma20;
      double bbLower = closes.last;
      if (closes.length >= 20) {
        final recent20 = closes.sublist(closes.length - 20);
        final mean = sma20;
        double variance = 0;
        for (var price in recent20) {
          variance += (price - mean) * (price - mean);
        }
        final stdDev = math.sqrt(variance / 20);
        bbUpper = mean + (2 * stdDev);
        bbLower = mean - (2 * stdDev);
      }
      indicators['bollingerBands'] = {
        'upper': bbUpper.toStringAsFixed(2),
        'middle': bbMiddle.toStringAsFixed(2),
        'lower': bbLower.toStringAsFixed(2),
      };
      
      // ========== VOLUME INDICATORS ==========
      
      // Average Volume
      final volumes = historicalData.map((d) => (d['v'] as num?)?.toInt() ?? 0).toList();
      if (volumes.isNotEmpty) {
        int avgVolume = 0;
        if (volumes.length >= 20) {
          final recent20Vol = volumes.sublist(volumes.length - 20);
          avgVolume = (recent20Vol.reduce((a, b) => a + b) / 20).round();
        } else {
          avgVolume = (volumes.reduce((a, b) => a + b) / volumes.length).round();
        }
        indicators['averageVolume'] = avgVolume;
        indicators['currentVolume'] = volumes.last;
      }
      
      // ========== PRICE ACTION ==========
      
      // Support and Resistance levels (simplified)
      if (highs.length >= 20 && lows.length >= 20) {
        final recent20Highs = highs.sublist(highs.length - 20);
        final recent20Lows = lows.sublist(lows.length - 20);
        final resistance = recent20Highs.reduce((a, b) => a > b ? a : b);
        final support = recent20Lows.reduce((a, b) => a < b ? a : b);
        indicators['resistance'] = resistance;
        indicators['support'] = support;
      }
      
      print('✅ [INDICATORS] Calculated ${indicators.length} indicators');
      print('   RSI: ${rsi.toStringAsFixed(2)}, SMA20: ${sma20.toStringAsFixed(2)}, MACD: ${macd.toStringAsFixed(2)}');
      print('   Indicator keys: ${indicators.keys.toList()}');
      print('   RSI key exists: ${indicators.containsKey('rsi')}, value: ${indicators['rsi']}');
      print('   SMA key exists: ${indicators.containsKey('sma')}, value: ${indicators['sma']}');
      print('   MACD key exists: ${indicators.containsKey('macd')}, value: ${indicators['macd']}');
      
      // Ensure we always return indicators with the expected keys
      if (indicators.isEmpty) {
        print('⚠️ [INDICATORS] WARNING: Returning empty indicators map!');
        print('   This should NOT happen if historical data was fetched successfully!');
      } else {
        print('✅ [INDICATORS] Returning ${indicators.length} indicators with keys: ${indicators.keys.toList()}');
        // Double-check critical keys exist
        final criticalKeys = ['rsi', 'sma', 'macd', 'RSI', 'SMA', 'MACD'];
        final missingKeys = criticalKeys.where((key) => !indicators.containsKey(key)).toList();
        if (missingKeys.isNotEmpty) {
          print('⚠️ [INDICATORS] Missing expected keys: $missingKeys');
        } else {
          print('✅ [INDICATORS] All critical keys present!');
        }
      }
      
      return indicators;
    } catch (e, stack) {
      print('❌ [INDICATORS] Error calculating indicators: $e');
      print('❌ [INDICATORS] Error type: ${e.runtimeType}');
      print('Stack: $stack');
      
      // Try to provide helpful error message
      if (e.toString().contains('CORS') || e.toString().contains('proxy')) {
        print('⚠️ [INDICATORS] CORS/Proxy issue detected on web platform');
        print('   This is a known issue with Yahoo Finance on web browsers');
      } else if (e.toString().contains('timeout')) {
        print('⚠️ [INDICATORS] Request timeout - Yahoo Finance API may be slow');
      } else if (e.toString().contains('network')) {
        print('⚠️ [INDICATORS] Network error - check internet connection');
      }
      
      return {};
    }
  }

  // Search result cache (TTL: 5 minutes)
  static final Map<String, _CachedSearchResult> _searchCache = {};
  static const _searchCacheTTL = Duration(minutes: 5);

  // Search for stocks by symbol or name
  // Uses local database first (no API calls), then falls back to Finnhub API if needed
  // Supports both US and Indian stocks
  // OPTIMIZED: Added search result caching and parallel quote fetching
  static Future<List<StockQuote>> searchStocks(String query, {bool useApiFallback = true}) async {
    if (query.isEmpty || query.length < 1) {
      return [];
    }
    
    final searchQuery = query.trim().toLowerCase();
    
    // Check search cache first
    final cachedSearch = _searchCache[searchQuery];
    if (cachedSearch != null && cachedSearch.isValid(_searchCacheTTL)) {
      print('✅ Using cached search results for: $query');
      return cachedSearch.results;
    }
    
    print('🔍 Searching for stocks matching: $query');
    
    // Step 1: Try local database first (instant, no API calls)
    // Search for both exact query and with .NS suffix for Indian stocks
    var localResults = LocalStocksDatabase.searchLocal(query);
    
    // ALWAYS also search with .NS suffix for Indian stocks (even if we got results)
    // This ensures we find Indian stocks when user types "TCS" instead of "TCS.NS"
    if (!query.toUpperCase().endsWith('.NS') && !query.toUpperCase().endsWith('.BO')) {
      final indianQuery = MarketDetector.normalizeIndianSymbol(query);
      final indianResults = LocalStocksDatabase.searchLocal(indianQuery);
      if (indianResults.isNotEmpty) {
        print('📚 Found ${indianResults.length} Indian stock matches with .NS suffix');
        // Merge results, avoiding duplicates
        for (final indianResult in indianResults) {
          if (!localResults.any((r) => r['symbol'] == indianResult['symbol'])) {
            localResults.add(indianResult);
          }
        }
      }
    }
    
    print('📚 Found ${localResults.length} local matches');
    
    if (localResults.isNotEmpty) {
      final List<StockQuote> stocks = [];
      final limitedResults = localResults.take(20).toList();
      
      // Fetch quotes in parallel batches (2 at a time to respect rate limits)
      for (int i = 0; i < limitedResults.length; i += 2) {
        final batch = limitedResults.skip(i).take(2).toList();
        
        final batchQuotes = await Future.wait(
          batch.map((localStock) async {
            try {
              var symbol = localStock['symbol']!;
              final name = localStock['name']!;
              
              // Normalize symbol if it's an Indian stock
              if (MarketDetector.isIndianStock(symbol)) {
                symbol = MarketDetector.normalizeIndianSymbol(symbol);
              } else {
                symbol = symbol.toUpperCase();
              }
              
              // Get quote for this symbol (will use cache if available)
              final quote = await getQuote(symbol);
              
              // Create StockQuote with name from local database
              return StockQuote(
                symbol: quote.symbol,
                name: name,
                currentPrice: quote.currentPrice,
                change: quote.change,
                changePercent: quote.changePercent,
                high: quote.high,
                low: quote.low,
                open: quote.open,
                previousClose: quote.previousClose,
                volume: quote.volume,
                marketCap: quote.marketCap,
                pe: quote.pe,
                eps: quote.eps,
                currency: quote.currency,
                timestamp: quote.timestamp,
              );
            } catch (e) {
              print('❌ Failed to get quote for ${localStock['symbol']}: $e');
              return null;
            }
          }),
        );
        
        // Add successful quotes
        for (final quote in batchQuotes) {
          if (quote != null) {
            stocks.add(quote);
          }
        }
        
        // Small delay between batches
        if (i + 2 < limitedResults.length) {
          await Future.delayed(const Duration(milliseconds: 200));
        }
      }
      
      if (stocks.isNotEmpty) {
        // Cache the results
        _searchCache[searchQuery] = _CachedSearchResult(stocks, DateTime.now());
        print('✅ Returning ${stocks.length} stocks from local database');
        return stocks;
      }
    }
    
    // Step 2: Fall back to Finnhub API only if local search didn't find enough results
    // and useApiFallback is true
    if (!useApiFallback) {
      print('⚠️ No local matches found, API fallback disabled');
      return [];
    }
    
    print('🌐 No local matches, trying Finnhub API...');
    
    try {
      // Use Finnhub search API - URL encode the query
      final encodedQuery = Uri.encodeComponent(query);
      final finnhubUrl = '$_baseUrl/search?q=$encodedQuery&token=$_apiKey';
      print('📡 Direct Finnhub API call: $finnhubUrl');
    
      final response = await _makeRequest(finnhubUrl);

      print('📊 Finnhub Search Response status: ${response.statusCode}');
    
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('🔍 Finnhub Search API response: $data');
        
        if (data['result'] != null && (data['result'] as List).isNotEmpty) {
          final List<dynamic> results = data['result'];
          print('✅ Found ${results.length} search results from API');
          
          // Limit to first 10 results to save API credits
          final limitedResults = results.take(10).toList();
          final List<StockQuote> stocks = [];
          
          // Fetch quotes in parallel batches (2 at a time)
          for (int i = 0; i < limitedResults.length; i += 2) {
            final batch = limitedResults.skip(i).take(2).toList();
            
            final batchQuotes = await Future.wait(
              batch.map((result) async {
                try {
                  final symbol = result['symbol'] as String?;
                  if (symbol != null && symbol.isNotEmpty) {
                    // Get quote for this symbol
                    final quote = await getQuote(symbol);
                    // Update the name from search result if available
                    if (result['description'] != null) {
                      // Create a new StockQuote with the name from search
                      return StockQuote(
                        symbol: quote.symbol,
                        name: result['description'] as String,
                        currentPrice: quote.currentPrice,
                        change: quote.change,
                        changePercent: quote.changePercent,
                        high: quote.high,
                        low: quote.low,
                        open: quote.open,
                        previousClose: quote.previousClose,
                        volume: quote.volume,
                        marketCap: quote.marketCap,
                        pe: quote.pe,
                        eps: quote.eps,
                        currency: quote.currency,
                        timestamp: quote.timestamp,
                      );
                    } else {
                      return quote;
                    }
                  }
                  return null;
                } catch (e) {
                  print('❌ Failed to get quote for ${result['symbol']}: $e');
                  return null;
                }
              }),
            );
            
            // Add successful quotes
            for (final quote in batchQuotes) {
              if (quote != null) {
                stocks.add(quote);
              }
            }
            
            // Small delay between batches
            if (i + 2 < limitedResults.length) {
              await Future.delayed(const Duration(milliseconds: 200));
            }
          }
          
          // Cache the results
          if (stocks.isNotEmpty) {
            _searchCache[searchQuery] = _CachedSearchResult(stocks, DateTime.now());
          }
          
          print('✅ Returning ${stocks.length} stocks from API search');
          return stocks;
        } else {
          print('⚠️ No search results from Finnhub');
          return [];
        }
      } else if (response.statusCode == 429) {
        print('⚠️ Rate limit exceeded - returning empty results');
        return [];
      } else if (response.statusCode == 401) {
        print('❌ API key invalid - returning empty results');
        return [];
      } else {
        print('❌ Finnhub Search API failed with status ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('❌ Finnhub Search API failed: $e');
      return [];
    }
  }

  /// Get popular stocks with real data - OPTIMIZED with parallel batch fetching and smart caching
  static Future<List<StockQuote>> getPopularStocks({MarketType? marketType}) async {
    // Default to US stocks if no market specified
    final List<String> symbols;
    if (marketType == MarketType.indian) {
      // Top 10 Indian stocks by market cap
      symbols = ['RELIANCE.NS', 'TCS.NS', 'HDFCBANK.NS', 'INFY.NS', 'ICICIBANK.NS', 
                 'HINDUNILVR.NS', 'SBIN.NS', 'BHARTIARTL.NS', 'ITC.NS', 'KOTAKBANK.NS'];
    } else {
      // Top 10 US stocks by market cap
      symbols = ['AAPL', 'GOOGL', 'MSFT', 'TSLA', 'AMZN', 'META', 'NVDA', 'NFLX', 'JPM', 'V'];
    }
    
    print('📊 Fetching popular ${marketType == MarketType.indian ? "Indian" : "US"} stocks (${symbols.length} stocks)...');
    
    // Step 1: Check cache for ALL symbols first (parallel check)
    final cacheChecks = await Future.wait(
      symbols.map((symbol) => _checkCacheForSymbol(symbol)),
    );
    
    final List<StockQuote> cachedStocks = [];
    final List<String> symbolsNeedingFetch = [];
    
    for (int i = 0; i < symbols.length; i++) {
      final symbol = symbols[i];
      final cachedQuote = cacheChecks[i];
      
      if (cachedQuote != null) {
        cachedStocks.add(cachedQuote);
      } else {
        symbolsNeedingFetch.add(symbol);
      }
    }
    
    // Step 2: Fetch missing stocks in parallel batches (2 at a time to respect rate limits)
    final List<StockQuote> fetchedStocks = [];
    if (symbolsNeedingFetch.isNotEmpty) {
      print('📡 Fetching ${symbolsNeedingFetch.length} stocks from API (${cachedStocks.length} from cache)...');
      
      // Fetch in batches of 2 to respect rate limits (2 calls per second)
      for (int i = 0; i < symbolsNeedingFetch.length; i += 2) {
        final batch = symbolsNeedingFetch.skip(i).take(2).toList();
        
        // Fetch batch in parallel
        final batchResults = await Future.wait(
          batch.map((symbol) async {
            try {
              return await getQuote(symbol);
            } catch (e) {
              print('❌ Failed to get $symbol: $e');
              // Try stale cache as fallback
              return await _getStaleCache(symbol);
            }
          }),
        );
        
        // Add successful fetches
        for (final quote in batchResults) {
          if (quote != null) {
            fetchedStocks.add(quote);
          }
        }
        
        // Small delay between batches (except for last batch)
        if (i + 2 < symbolsNeedingFetch.length) {
          await Future.delayed(const Duration(milliseconds: 300));
        }
      }
    }
    
    // Combine cached and fetched stocks
    final allStocks = <StockQuote>[...cachedStocks, ...fetchedStocks];
    
    // Sort stocks to match original symbol order
    final sortedStocks = <StockQuote>[];
    for (final symbol in symbols) {
      final stock = allStocks.firstWhere(
        (s) => s.symbol == symbol,
        orElse: () => allStocks.isNotEmpty ? allStocks.first : throw Exception('No stocks found'),
      );
      if (!sortedStocks.any((s) => s.symbol == symbol)) {
        sortedStocks.add(stock);
      }
    }
    
    print('📈 Fetched ${sortedStocks.length} stocks (${symbolsNeedingFetch.length} API calls, ${cachedStocks.length} cache hits)');
    return sortedStocks;
  }
  
  /// Check cache for a symbol (returns cached quote if available)
  static Future<StockQuote?> _checkCacheForSymbol(String symbol) async {
    final cacheKey = 'quote_$symbol';
    
    // Check in-memory cache first
    final cached = _cache[cacheKey];
    if (cached != null && cached.isValid(_quoteCacheTTL)) {
      return cached.data as StockQuote;
    }
    
    // Check database cache
    try {
      final dbCached = await DatabaseService.getCachedQuote(symbol);
      if (dbCached != null) {
        final quote = StockQuote.fromJson(dbCached);
        // Update in-memory cache
        _cache[cacheKey] = _CachedData(quote, DateTime.now());
        return quote;
      }
    } catch (e) {
      // Cache check failed, continue to API
    }
    
    return null;
  }
  
  /// Get stale cache as fallback (even if expired)
  static Future<StockQuote?> _getStaleCache(String symbol) async {
    try {
      // Try to get stale cache (even if expired)
      final dbCached = await DatabaseService.getStaleCachedQuote(symbol);
      if (dbCached != null) {
        // Even if expired, return it as fallback
        return StockQuote.fromJson(dbCached);
      }
    } catch (e) {
      print('⚠️ Stale cache retrieval failed: $e');
    }
    return null;
  }
  
  // Clear cache (useful for testing or forced refresh)
  static void clearCache() {
    _cache.clear();
    print('🗑️ Cache cleared');
  }
}

/// Technical Indicators Calculator (inline implementation)
/// This calculates RSI, MACD, SMA from historical OHLC data
class _TechnicalIndicatorsCalculator {
  double calculateRSI(List<Map<String, dynamic>> prices, {int period = 14}) {
    if (prices.length < period + 1) {
      return 50.0; // Neutral value if not enough data
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
    
    // Build MACD line by calculating EMA progressively
    final List<double> macdValues = [];
    
    // Calculate MACD for each point from slowPeriod onwards
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

    // Current MACD line value (most recent)
    final macdLine = macdValues.last;

    // Calculate signal line as EMA(9) of MACD values
    double signalLine = macdLine;
    if (macdValues.length >= signalPeriod) {
      final signalMultiplier = 2.0 / (signalPeriod + 1);
      // Start with SMA of first signalPeriod MACD values
      signalLine = macdValues.take(signalPeriod).reduce((a, b) => a + b) / signalPeriod;
      
      // Apply EMA smoothing for remaining MACD values
      for (int i = signalPeriod; i < macdValues.length; i++) {
        signalLine = (macdValues[i] * signalMultiplier) + (signalLine * (1 - signalMultiplier));
      }
    } else if (macdValues.length > 1) {
      // If we don't have enough for full EMA, use simple average
      signalLine = macdValues.reduce((a, b) => a + b) / macdValues.length;
    }

    final histogram = macdLine - signalLine;

    return {
      'macd': macdLine,
      'signal': signalLine,
      'histogram': histogram,
    };
  }

  String _getRSISignal(double rsi) {
    if (rsi >= 70) return 'Overbought';
    if (rsi <= 30) return 'Oversold';
    return 'Neutral';
  }

  String _getSMASignal(double currentPrice, double sma) {
    if (currentPrice > sma * 1.02) return 'Bullish';
    if (currentPrice < sma * 0.98) return 'Bearish';
    return 'Neutral';
  }

  Map<String, dynamic> calculateAllIndicators(List<Map<String, dynamic>> historicalData) {
    if (historicalData.isEmpty) {
      return {
        'rsi': null,
        'sma_20': null,
        'sma_50': null,
        'macd': null,
        'error': 'Insufficient historical data',
      };
    }

    try {
      final rsi = calculateRSI(historicalData, period: 14);
      final sma20 = calculateSMA(historicalData, period: 20);
      final sma50 = historicalData.length >= 50
          ? calculateSMA(historicalData, period: 50)
          : null;

      final macd = calculateMACD(historicalData);

      final currentPrice = (historicalData.last['c'] as num).toDouble();

      return {
        'rsi': {
          'value': rsi,
          'signal': _getRSISignal(rsi),
        },
        'sma_20': {
          'value': sma20,
          'current_price': currentPrice,
          'signal': _getSMASignal(currentPrice, sma20),
        },
        'sma_50': sma50 != null
            ? {
                'value': sma50,
                'current_price': currentPrice,
                'signal': _getSMASignal(currentPrice, sma50),
              }
            : null,
        'macd': macd,
      };
    } catch (e) {
      return {
        'rsi': null,
        'sma_20': null,
        'sma_50': null,
        'macd': null,
        'error': 'Error calculating indicators: $e',
      };
    }
  }
}

// Cache helper class
class _CachedData {
  final dynamic data;
  final DateTime timestamp;
  
  _CachedData(this.data, this.timestamp);
  
  bool isValid(Duration ttl) {
    return DateTime.now().difference(timestamp) < ttl;
  }
}

// Search result cache helper class
class _CachedSearchResult {
  final List<StockQuote> results;
  final DateTime timestamp;
  
  _CachedSearchResult(this.results, this.timestamp);
  
  bool isValid(Duration ttl) {
    return DateTime.now().difference(timestamp) < ttl;
  }
}