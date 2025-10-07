import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/stock_quote.dart';
import '../models/company_profile.dart';
import '../models/news_article.dart';

class StockApiService {
  static const String _baseUrl = 'https://finnhub.io/api/v1';
  static String? _apiKey;

  static Future<void> init() async {
    try {
      await dotenv.load(fileName: ".env");
      _apiKey = dotenv.env['FINNHUB_API_KEY'];
      
      if (_apiKey == null || _apiKey!.isEmpty) {
        _apiKey = 'd2imrl9r01qhm15b6ufgd2imrl9r01qhm15b6ug0'; // Fallback API key
      }
    } catch (e) {
      print('Could not load .env file: $e');
      _apiKey = 'd2imrl9r01qhm15b6ufgd2imrl9r01qhm15b6ug0'; // Fallback API key
    }
  }

  static Future<StockQuote> getQuote(String symbol) async {
    if (_apiKey == null) await init();
    
    final response = await http.get(
      Uri.parse('$_baseUrl/quote?symbol=$symbol&token=$_apiKey'),
    );
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return StockQuote.fromJson(data);
    } else {
      throw Exception('Failed to load quote for $symbol');
    }
  }

  static Future<CompanyProfile> getCompanyProfile(String symbol) async {
    if (_apiKey == null) await init();
    
    final response = await http.get(
      Uri.parse('$_baseUrl/stock/profile2?symbol=$symbol&token=$_apiKey'),
    );
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      print('API Response for $symbol: $data'); // Debug print
      return CompanyProfile.fromJson(data);
    } else {
      print('API Error for $symbol: ${response.statusCode} - ${response.body}'); // Debug print
      throw Exception('Failed to load company profile for $symbol');
    }
  }

  static Future<List<NewsArticle>> getCompanyNews(String symbol) async {
    if (_apiKey == null) await init();
    
    final now = DateTime.now();
    final yesterday = now.subtract(const Duration(days: 1));
    final from = yesterday.toIso8601String().split('T')[0];
    final to = now.toIso8601String().split('T')[0];
    
    final response = await http.get(
      Uri.parse('$_baseUrl/company-news?symbol=$symbol&from=$from&to=$to&token=$_apiKey'),
    );
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as List;
      return data.map((item) => NewsArticle.fromJson(item)).toList();
    } else {
      throw Exception('Failed to load news for $symbol');
    }
  }

  static Future<Map<String, dynamic>> getTechnicalIndicators(String symbol) async {
    if (_apiKey == null) await init();
    
    try {
      // Try to get RSI
      final rsiResponse = await http.get(
        Uri.parse('$_baseUrl/indicator?symbol=$symbol&resolution=D&indicator=rsi&token=$_apiKey'),
      );
      
      // Try to get SMA
      final smaResponse = await http.get(
        Uri.parse('$_baseUrl/indicator?symbol=$symbol&resolution=D&indicator=sma&timeperiod=20&token=$_apiKey'),
      );
      
      // Try to get MACD
      final macdResponse = await http.get(
        Uri.parse('$_baseUrl/indicator?symbol=$symbol&resolution=D&indicator=macd&token=$_apiKey'),
      );
      
      return {
        'rsi': rsiResponse.statusCode == 200 ? jsonDecode(rsiResponse.body) : _getMockRSI(),
        'sma': smaResponse.statusCode == 200 ? jsonDecode(smaResponse.body) : _getMockSMA(),
        'macd': macdResponse.statusCode == 200 ? jsonDecode(macdResponse.body) : _getMockMACD(),
      };
    } catch (e) {
      // Return mock data if indicators fail
      return {
        'rsi': _getMockRSI(),
        'sma': _getMockSMA(),
        'macd': _getMockMACD(),
      };
    }
  }

  // Fetch additional financial metrics
  static Future<Map<String, dynamic>> getFinancialMetrics(String symbol) async {
    if (_apiKey == null) await init();
    
    try {
      // Try to get metrics from Finnhub - using the correct endpoint
      final response = await http.get(
        Uri.parse('$_baseUrl/stock/metric?symbol=$symbol&metric=all&token=$_apiKey'),
      );
      
      if (response.statusCode == 200) {
        // Check if response is HTML (error page) instead of JSON
        if (response.body.startsWith('<!DOCTYPE') || response.body.startsWith('<html')) {
          print('Metrics API returned HTML for $symbol, using mock data');
          return _getMockFinancialMetrics(symbol);
        }
        
        final data = jsonDecode(response.body);
        print('Financial metrics for $symbol: ${data.keys}'); // Debug print
        
        // Extract the most recent values from the time series data
        final metrics = <String, dynamic>{};
        
        // Get the most recent P/E ratio
        if (data['peTTM'] != null && (data['peTTM'] as List).isNotEmpty) {
          final peData = (data['peTTM'] as List).first;
          metrics['pe'] = peData['v'];
        }
        
        // Get the most recent Price-to-Book ratio
        if (data['pb'] != null && (data['pb'] as List).isNotEmpty) {
          final pbData = (data['pb'] as List).first;
          metrics['priceToBook'] = pbData['v'];
        }
        
        // Get the most recent Beta
        if (data['beta'] != null && (data['beta'] as List).isNotEmpty) {
          final betaData = (data['beta'] as List).first;
          metrics['beta'] = betaData['v'];
        }
        
        // Get the most recent EPS
        if (data['epsTTM'] != null && (data['epsTTM'] as List).isNotEmpty) {
          final epsData = (data['epsTTM'] as List).first;
          metrics['eps'] = epsData['v'];
        }
        
        // Get the most recent Dividend Yield
        if (data['dividendYieldTTM'] != null && (data['dividendYieldTTM'] as List).isNotEmpty) {
          final divData = (data['dividendYieldTTM'] as List).first;
          metrics['dividendYield'] = divData['v'];
        }
        
        // Get the most recent ROE
        if (data['roeTTM'] != null && (data['roeTTM'] as List).isNotEmpty) {
          final roeData = (data['roeTTM'] as List).first;
          metrics['returnOnEquity'] = roeData['v'];
        }
        
        // Get the most recent Debt-to-Equity
        if (data['totalDebtToEquity'] != null && (data['totalDebtToEquity'] as List).isNotEmpty) {
          final debtData = (data['totalDebtToEquity'] as List).first;
          metrics['debtToEquity'] = debtData['v'];
        }
        
        // Get the most recent Profit Margin
        if (data['netMargin'] != null && (data['netMargin'] as List).isNotEmpty) {
          final marginData = (data['netMargin'] as List).first;
          metrics['profitMargin'] = marginData['v'];
        }
        
        // If no metrics were extracted, use mock data
        if (metrics.isEmpty) {
          print('No metrics extracted for $symbol, using mock data');
          return _getMockFinancialMetrics(symbol);
        }
        
        print('Extracted metrics: $metrics');
        return metrics;
      } else {
        print('Metrics API Error for $symbol: ${response.statusCode} - ${response.body}');
        return _getMockFinancialMetrics(symbol);
      }
    } catch (e) {
      print('Error fetching metrics for $symbol: $e');
      return _getMockFinancialMetrics(symbol);
    }
  }

  static Map<String, dynamic> _getMockFinancialMetrics(String symbol) {
    final mockMetrics = {
      'AAPL': {
        'pe': 28.5,
        'dividendYield': 0.0044,
        'beta': 1.2,
        'eps': 6.13,
        'bookValue': 4.44,
        'priceToBook': 39.4,
        'revenue': 394.3e9,
        'profitMargin': 0.25,
        'returnOnEquity': 1.47,
        'debtToEquity': 1.73,
      },
      'GOOGL': {
        'pe': 25.8,
        'dividendYield': 0.0,
        'beta': 1.1,
        'eps': 5.61,
        'bookValue': 12.3,
        'priceToBook': 4.6,
        'revenue': 282.8e9,
        'profitMargin': 0.21,
        'returnOnEquity': 0.18,
        'debtToEquity': 0.12,
      },
      'MSFT': {
        'pe': 32.1,
        'dividendYield': 0.007,
        'beta': 0.9,
        'eps': 11.06,
        'bookValue': 8.9,
        'priceToBook': 12.4,
        'revenue': 211.9e9,
        'profitMargin': 0.36,
        'returnOnEquity': 0.45,
        'debtToEquity': 0.31,
      },
      'AMZN': {
        'pe': 45.2,
        'dividendYield': 0.0,
        'beta': 1.3,
        'eps': 3.24,
        'bookValue': 15.2,
        'priceToBook': 10.2,
        'revenue': 574.8e9,
        'profitMargin': 0.05,
        'returnOnEquity': 0.21,
        'debtToEquity': 0.45,
      },
      'TSLA': {
        'pe': 65.8,
        'dividendYield': 0.0,
        'beta': 2.1,
        'eps': 3.62,
        'bookValue': 8.2,
        'priceToBook': 30.5,
        'revenue': 96.8e9,
        'profitMargin': 0.15,
        'returnOnEquity': 0.44,
        'debtToEquity': 0.17,
      },
      'META': {
        'pe': 22.4,
        'dividendYield': 0.0,
        'beta': 1.4,
        'eps': 20.8,
        'bookValue': 45.2,
        'priceToBook': 4.6,
        'revenue': 134.9e9,
        'profitMargin': 0.20,
        'returnOnEquity': 0.46,
        'debtToEquity': 0.23,
      },
      'NVDA': {
        'pe': 68.5,
        'dividendYield': 0.0003,
        'beta': 1.6,
        'eps': 4.44,
        'bookValue': 8.9,
        'priceToBook': 34.2,
        'revenue': 60.9e9,
        'profitMargin': 0.49,
        'returnOnEquity': 0.50,
        'debtToEquity': 0.15,
      },
      'NFLX': {
        'pe': 35.2,
        'dividendYield': 0.0,
        'beta': 1.2,
        'eps': 12.44,
        'bookValue': 15.6,
        'priceToBook': 8.9,
        'revenue': 33.7e9,
        'profitMargin': 0.18,
        'returnOnEquity': 0.80,
        'debtToEquity': 0.67,
      },
    };
    
    return mockMetrics[symbol] ?? mockMetrics['AAPL']!;
  }

  // Mock data for educational purposes when indicators fail
  static Map<String, dynamic> _getMockRSI() {
    return {
      'value': 65.2,
      'explanation': 'RSI (Relative Strength Index) measures if a stock is overbought (>70) or oversold (<30). Current: 65.2 - Neutral zone, good for learning!'
    };
  }

  static Map<String, dynamic> _getMockSMA() {
    return {
      'value': 150.5,
      'explanation': 'SMA (Simple Moving Average) shows the average price over 20 days. Helps identify trends - if price is above SMA, it might be trending up!'
    };
  }

  static Map<String, dynamic> _getMockMACD() {
    return {
      'value': {'macd': 2.5, 'signal': 2.0},
      'explanation': 'MACD shows momentum changes. When MACD line crosses above signal line, it might indicate a buy signal for learning!'
    };
  }

  // Get popular stocks for the stock list screen
  static Future<List<Map<String, dynamic>>> getPopularStocks() async {
    if (_apiKey == null) await init();
    
    final symbols = ['AAPL', 'GOOGL', 'MSFT', 'AMZN', 'TSLA', 'META', 'NVDA', 'NFLX'];
    
    try {
      final results = <Map<String, dynamic>>[];
      
      for (final symbol in symbols) {
        try {
          final quote = await getQuote(symbol);
          final profile = await getCompanyProfile(symbol);
          
          results.add({
            'symbol': symbol,
            'quote': quote,
            'profile': profile,
          });
        } catch (e) {
          print('Failed to load data for $symbol: $e');
          // Add mock data for failed stocks
          results.add({
            'symbol': symbol,
            'quote': _getMockQuote(symbol),
            'profile': _getMockProfile(symbol),
          });
        }
      }
      
      return results;
    } catch (e) {
      // Return mock data if everything fails
      return symbols.map((symbol) => {
        'symbol': symbol,
        'quote': _getMockQuote(symbol),
        'profile': _getMockProfile(symbol),
      }).toList();
    }
  }

  static StockQuote _getMockQuote(String symbol) {
    final mockPrices = {
      'AAPL': 175.20,
      'GOOGL': 142.50,
      'MSFT': 378.85,
      'AMZN': 155.30,
      'TSLA': 248.50,
      'META': 485.20,
      'NVDA': 875.30,
      'NFLX': 485.60,
    };
    
    final price = mockPrices[symbol] ?? 100.0;
    final change = (price * 0.02 * (symbol.hashCode % 2 == 0 ? 1 : -1));
    
    return StockQuote(
      currentPrice: price,
      change: change,
      changePercent: (change / price) * 100,
      high: price * 1.05,
      low: price * 0.95,
      open: price * 0.98,
      previousClose: price - change,
    );
  }

  static CompanyProfile _getMockProfile(String symbol) {
    final mockNames = {
      'AAPL': 'Apple Inc.',
      'GOOGL': 'Alphabet Inc.',
      'MSFT': 'Microsoft Corporation',
      'AMZN': 'Amazon.com Inc.',
      'TSLA': 'Tesla Inc.',
      'META': 'Meta Platforms Inc.',
      'NVDA': 'NVIDIA Corporation',
      'NFLX': 'Netflix Inc.',
    };

    final mockFinancials = {
      'AAPL': {
        'marketCap': 2.8e12,
        'peRatio': 28.5,
        'dividendYield': 0.0044,
        'beta': 1.2,
        'eps': 6.13,
        'bookValue': 4.44,
        'priceToBook': 39.4,
        'revenue': 394.3e9,
        'profitMargin': 0.25,
        'roe': 1.47,
        'debtToEquity': 1.73,
      },
      'GOOGL': {
        'marketCap': 1.7e12,
        'peRatio': 25.8,
        'dividendYield': 0.0,
        'beta': 1.1,
        'eps': 5.61,
        'bookValue': 12.3,
        'priceToBook': 4.6,
        'revenue': 282.8e9,
        'profitMargin': 0.21,
        'roe': 0.18,
        'debtToEquity': 0.12,
      },
      'MSFT': {
        'marketCap': 2.9e12,
        'peRatio': 32.1,
        'dividendYield': 0.007,
        'beta': 0.9,
        'eps': 11.06,
        'bookValue': 8.9,
        'priceToBook': 12.4,
        'revenue': 211.9e9,
        'profitMargin': 0.36,
        'roe': 0.45,
        'debtToEquity': 0.31,
      },
      'AMZN': {
        'marketCap': 1.6e12,
        'peRatio': 45.2,
        'dividendYield': 0.0,
        'beta': 1.3,
        'eps': 3.24,
        'bookValue': 15.2,
        'priceToBook': 10.2,
        'revenue': 574.8e9,
        'profitMargin': 0.05,
        'roe': 0.21,
        'debtToEquity': 0.45,
      },
      'TSLA': {
        'marketCap': 800e9,
        'peRatio': 65.8,
        'dividendYield': 0.0,
        'beta': 2.1,
        'eps': 3.62,
        'bookValue': 8.2,
        'priceToBook': 30.5,
        'revenue': 96.8e9,
        'profitMargin': 0.15,
        'roe': 0.44,
        'debtToEquity': 0.17,
      },
      'META': {
        'marketCap': 1.2e12,
        'peRatio': 22.4,
        'dividendYield': 0.0,
        'beta': 1.4,
        'eps': 20.8,
        'bookValue': 45.2,
        'priceToBook': 4.6,
        'revenue': 134.9e9,
        'profitMargin': 0.20,
        'roe': 0.46,
        'debtToEquity': 0.23,
      },
      'NVDA': {
        'marketCap': 2.1e12,
        'peRatio': 68.5,
        'dividendYield': 0.0003,
        'beta': 1.6,
        'eps': 4.44,
        'bookValue': 8.9,
        'priceToBook': 34.2,
        'revenue': 60.9e9,
        'profitMargin': 0.49,
        'roe': 0.50,
        'debtToEquity': 0.15,
      },
      'NFLX': {
        'marketCap': 200e9,
        'peRatio': 35.2,
        'dividendYield': 0.0,
        'beta': 1.2,
        'eps': 12.44,
        'bookValue': 15.6,
        'priceToBook': 8.9,
        'revenue': 33.7e9,
        'profitMargin': 0.18,
        'roe': 0.80,
        'debtToEquity': 0.67,
      },
    };

    final financials = mockFinancials[symbol] ?? mockFinancials['AAPL']!;
    
    return CompanyProfile(
      name: mockNames[symbol] ?? 'Company Inc.',
      ticker: symbol,
      country: 'US',
      industry: 'Technology',
      weburl: 'https://example.com',
      logo: '',
      marketCapitalization: financials['marketCap']!,
      shareOutstanding: 1000000000.0,
      description: 'A leading technology company focused on innovation and growth.',
      exchange: 'NASDAQ',
      peRatio: financials['peRatio'],
      dividendYield: financials['dividendYield'],
      beta: financials['beta'],
      eps: financials['eps'],
      bookValue: financials['bookValue'],
      priceToBook: financials['priceToBook'],
      revenue: financials['revenue'],
      profitMargin: financials['profitMargin'],
      returnOnEquity: financials['roe'],
      debtToEquity: financials['debtToEquity'],
    );
  }
}

