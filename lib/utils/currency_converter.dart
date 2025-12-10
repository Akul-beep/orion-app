import 'package:http/http.dart' as http;
import 'dart:convert';
import '../utils/market_detector.dart';

/// Currency conversion utility for handling USD/INR conversion
class CurrencyConverter {
  // Cache for exchange rate (update every hour)
  static double? _cachedUsdToInrRate;
  static DateTime? _cacheTimestamp;
  static const Duration _cacheTTL = Duration(hours: 1);
  
  // Fallback rate if API fails (approximate)
  static const double _fallbackUsdToInrRate = 83.0;
  
  /// Get USD to INR exchange rate
  /// Uses free API: exchangerate-api.com or fallback to cached/fallback rate
  static Future<double> getUsdToInrRate() async {
    // Check cache first
    if (_cachedUsdToInrRate != null && 
        _cacheTimestamp != null &&
        DateTime.now().difference(_cacheTimestamp!) < _cacheTTL) {
      print('💰 Using cached USD/INR rate: $_cachedUsdToInrRate');
      return _cachedUsdToInrRate!;
    }
    
    try {
      // Try free exchange rate API (no key required)
      final url = Uri.parse('https://api.exchangerate-api.com/v4/latest/USD');
      final response = await http.get(url).timeout(const Duration(seconds: 5));
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final rates = data['rates'] as Map<String, dynamic>;
        final inrRate = (rates['INR'] as num).toDouble();
        
        // Cache the rate
        _cachedUsdToInrRate = inrRate;
        _cacheTimestamp = DateTime.now();
        
        print('✅ Fetched USD/INR rate: $inrRate');
        return inrRate;
      }
    } catch (e) {
      print('⚠️ Error fetching exchange rate: $e');
    }
    
    // Fallback to cached rate if available
    if (_cachedUsdToInrRate != null) {
      print('💰 Using stale cached USD/INR rate: $_cachedUsdToInrRate');
      return _cachedUsdToInrRate!;
    }
    
    // Final fallback
    print('⚠️ Using fallback USD/INR rate: $_fallbackUsdToInrRate');
    return _fallbackUsdToInrRate;
  }
  
  /// Convert INR to USD
  static Future<double> inrToUsd(double inrAmount) async {
    final rate = await getUsdToInrRate();
    return inrAmount / rate;
  }
  
  /// Convert USD to INR
  static Future<double> usdToInr(double usdAmount) async {
    final rate = await getUsdToInrRate();
    return usdAmount * rate;
  }
  
  /// Check if a currency is INR
  static bool isInr(String? currency) {
    return currency?.toUpperCase() == 'INR';
  }
  
  /// Check if a currency is USD
  static bool isUsd(String? currency) {
    return currency == null || currency.toUpperCase() == 'USD';
  }
  
  /// Format currency symbol based on stock symbol
  /// Returns '₹' for Indian stocks, '$' for US stocks
  static String getCurrencySymbol(String symbol) {
    if (MarketDetector.isIndianStock(symbol)) {
      return '₹';
    }
    return '\$';
  }
  
  /// Format price with currency symbol based on stock symbol
  /// Returns formatted string like "₹1547.30" or "$150.25"
  static String formatPrice(double price, String symbol) {
    final symbolStr = getCurrencySymbol(symbol);
    return '$symbolStr${price.toStringAsFixed(2)}';
  }
  
  /// Format price change with currency symbol based on stock symbol
  /// Returns formatted string like "+₹10.50" or "+$5.25"
  static String formatPriceChange(double change, String symbol) {
    final symbolStr = getCurrencySymbol(symbol);
    final sign = change >= 0 ? '+' : '';
    return '$sign$symbolStr${change.abs().toStringAsFixed(2)}';
  }
}

