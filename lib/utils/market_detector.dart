/// Utility to detect stock market (US vs Indian) from symbol
class MarketDetector {
  /// Detect if a symbol is for Indian market
  /// Indian stocks typically have .NS (NSE) or .BO (BSE) suffix
  /// Examples: RELIANCE.NS, TCS.NS, INFY.NS, SBIN.BO
  static bool isIndianStock(String symbol) {
    if (symbol.isEmpty) return false;
    
    final upperSymbol = symbol.toUpperCase();
    return upperSymbol.endsWith('.NS') || upperSymbol.endsWith('.BO');
  }
  
  /// Detect if a symbol is for US market
  /// US stocks typically don't have exchange suffix (or have .US)
  static bool isUSStock(String symbol) {
    if (symbol.isEmpty) return false;
    
    final upperSymbol = symbol.toUpperCase();
    // If it has .NS or .BO, it's not US
    if (upperSymbol.endsWith('.NS') || upperSymbol.endsWith('.BO')) {
      return false;
    }
    
    // If it has .US suffix, it's US
    if (upperSymbol.endsWith('.US')) {
      return true;
    }
    
    // Default: assume US if no exchange suffix (for backward compatibility)
    return true;
  }
  
  /// Get market type from symbol
  static MarketType getMarketType(String symbol) {
    if (isIndianStock(symbol)) {
      return MarketType.indian;
    } else if (isUSStock(symbol)) {
      return MarketType.us;
    }
    // Default to US for backward compatibility
    return MarketType.us;
  }
  
  /// Normalize Indian stock symbol (ensure it has .NS suffix if no suffix)
  /// If user searches "RELIANCE", we'll try "RELIANCE.NS"
  static String normalizeIndianSymbol(String symbol) {
    if (symbol.isEmpty) return symbol;
    
    final upperSymbol = symbol.toUpperCase();
    
    // If already has .NS or .BO, return as is
    if (upperSymbol.endsWith('.NS') || upperSymbol.endsWith('.BO')) {
      return upperSymbol;
    }
    
    // Default to .NS (NSE) if no suffix
    return '$upperSymbol.NS';
  }
  
  /// Get exchange name from symbol
  static String getExchange(String symbol) {
    if (symbol.toUpperCase().endsWith('.NS')) {
      return 'NSE';
    } else if (symbol.toUpperCase().endsWith('.BO')) {
      return 'BSE';
    } else if (symbol.toUpperCase().endsWith('.US')) {
      return 'NYSE/NASDAQ';
    }
    return 'NYSE/NASDAQ'; // Default
  }
}

enum MarketType {
  us,
  indian,
}

