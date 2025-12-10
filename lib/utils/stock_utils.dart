import '../models/company_profile.dart';

class StockUtils {
  /// Detects if a stock is an ETF based on company profile data
  /// This uses multiple heuristics similar to how professional stock apps detect ETFs
  static bool isETF(CompanyProfile? profile) {
    if (profile == null) return false;
    
    // Check exchange - ETFs typically trade on ARCA, AMEX, or BATS
    final exchange = profile.exchange.toUpperCase();
    if (exchange.contains('ARCA') || 
        exchange.contains('AMEX') || 
        exchange == 'BATS' ||
        exchange.contains('NYSE ARCA') ||
        exchange == 'NYSEARCA') {
      return true;
    }
    
    // Check industry/name for ETF indicators
    final name = profile.name.toUpperCase();
    final industry = profile.industry.toUpperCase();
    final description = (profile.description ?? '').toUpperCase();
    
    // Common ETF indicators in name
    if (name.contains('ETF') || 
        name.contains('TRUST') ||
        name.contains('FUND') ||
        name.contains('SPDR') ||
        name.contains('ISHARES') ||
        name.contains('VANGUARD') ||
        name.contains('INVESCO')) {
      return true;
    }
    
    // Check industry
    if (industry.contains('ETF') || industry.contains('EXCHANGE TRADED')) {
      return true;
    }
    
    // Check description
    if (description.contains('EXCHANGE TRADED FUND') || 
        description.contains('ETF')) {
      return true;
    }
    
    return false;
  }
  
  /// Maps Finnhub exchange names to TradingView exchange prefixes
  /// This is how professional apps handle any stock dynamically
  /// Supports both US and Indian stocks
  static String _mapFinnhubExchangeToTradingView(String finnhubExchange, String symbol) {
    final exchange = finnhubExchange.toUpperCase().trim();
    
    // Handle Indian stocks first (NSE/BSE)
    if (exchange == 'NSE' || symbol.toUpperCase().endsWith('.NS')) {
      return 'NSE';
    }
    if (exchange == 'BSE' || symbol.toUpperCase().endsWith('.BO')) {
      return 'BSE';
    }
    
    // Handle NASDAQ variations
    if (exchange.contains('NASDAQ')) {
      return 'NASDAQ';
    }
    
    // Handle NYSE Arca (for ETFs) - Maps to AMEX in TradingView
    // NYSE Arca is operated by AMEX, so TradingView uses AMEX prefix
    if (exchange.contains('ARCA') || 
        exchange == 'NYSEARCA' || 
        exchange == 'NYSE ARCA') {
      return 'AMEX';  // Changed from 'ARCA' to 'AMEX'
    }
    
    // Handle AMEX
    if (exchange.contains('AMEX') || 
        exchange == 'AMERICAN STOCK EXCHANGE') {
      return 'AMEX';
    }
    
    // Handle regular NYSE (but not ARCA)
    if (exchange == 'NYSE' || 
        exchange == 'NEW YORK STOCK EXCHANGE') {
      return 'NYSE';
    }
    
    // Handle BATS
    if (exchange.contains('BATS')) {
      return 'BATS';
    }
    
    // Handle OTC markets
    if (exchange.contains('OTC')) {
      return 'OTC';
    }
    
    // Default to NASDAQ for US stocks if unknown
    return 'NASDAQ';
  }
  
  /// Gets the appropriate TradingView exchange prefix for a symbol
  /// Returns the prefix (e.g., "AMEX:", "NASDAQ:", "NYSE:", "NSE:", "BSE:")
  /// This is fully dynamic and works for ANY stock (US and Indian)
  static String getTradingViewExchangePrefix(String symbol, CompanyProfile? profile) {
    // Check if it's an Indian stock by symbol suffix
    final upperSymbol = symbol.toUpperCase();
    if (upperSymbol.endsWith('.NS')) {
      print('📍 [TradingView] $symbol: Detected NSE stock from symbol suffix');
      return 'NSE:';
    }
    if (upperSymbol.endsWith('.BO')) {
      print('📍 [TradingView] $symbol: Detected BSE stock from symbol suffix');
      return 'BSE:';
    }
    
    if (profile == null) {
      print('⚠️ [TradingView] No profile for $symbol, using NASDAQ as fallback');
      return 'NASDAQ:';
    }
    
    final exchange = profile.exchange;
    if (exchange.isEmpty) {
      print('⚠️ [TradingView] Empty exchange for $symbol, using NASDAQ as fallback');
      return 'NASDAQ:';
    }
    
    // Map Finnhub's exchange format to TradingView's format
    final tradingViewExchange = _mapFinnhubExchangeToTradingView(exchange, symbol);
    print('📍 [TradingView] $symbol: Exchange="${exchange}" → TradingView="${tradingViewExchange}"');
    
    return '$tradingViewExchange:';
  }
  
  /// Gets the full TradingView symbol with exchange prefix
  /// For Indian stocks, removes .NS/.BO suffix before adding exchange prefix
  static String getTradingViewSymbol(String symbol, CompanyProfile? profile) {
    final prefix = getTradingViewExchangePrefix(symbol, profile);
    
    // For Indian stocks, remove .NS/.BO suffix before adding exchange prefix
    // TradingView expects: NSE:RELIANCE (not NSE:RELIANCE.NS)
    String cleanSymbol = symbol.toUpperCase();
    if (cleanSymbol.endsWith('.NS') || cleanSymbol.endsWith('.BO')) {
      cleanSymbol = cleanSymbol.replaceAll('.NS', '').replaceAll('.BO', '');
    }
    
    final result = '$prefix$cleanSymbol';
    print('✅ [TradingView] Final symbol: $symbol → $result');
    return result;
  }
}

