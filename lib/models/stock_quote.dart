class StockQuote {
  final String symbol;
  final String name;
  final double currentPrice;
  final double change;
  final double changePercent;
  final double high;
  final double low;
  final double open;
  final double previousClose;
  final int volume;
  final double marketCap;
  final double pe;
  final double eps;
  final String currency;
  final DateTime timestamp;

  StockQuote({
    required this.symbol,
    required this.name,
    required this.currentPrice,
    required this.change,
    required this.changePercent,
    required this.high,
    required this.low,
    required this.open,
    required this.previousClose,
    required this.volume,
    required this.marketCap,
    required this.pe,
    required this.eps,
    required this.currency,
    required this.timestamp,
  });

  factory StockQuote.fromJson(Map<String, dynamic> json) {
    // Handle Finnhub API response format
    return StockQuote(
      symbol: json['symbol'] ?? json['ticker'] ?? '',
      name: json['name'] ?? '',
      currentPrice: (json['c'] ?? json['currentPrice'] ?? 0.0).toDouble(),
      change: (json['d'] ?? json['change'] ?? 0.0).toDouble(),
      changePercent: (json['dp'] ?? json['changePercent'] ?? 0.0).toDouble(),
      high: (json['h'] ?? json['high'] ?? 0.0).toDouble(),
      low: (json['l'] ?? json['low'] ?? 0.0).toDouble(),
      open: (json['o'] ?? json['open'] ?? 0.0).toDouble(),
      previousClose: (json['pc'] ?? json['previousClose'] ?? 0.0).toDouble(),
      volume: json['v'] ?? json['volume'] ?? 0,
      marketCap: (json['marketCap'] ?? 0.0).toDouble(),
      pe: (json['pe'] ?? 0.0).toDouble(),
      eps: (json['eps'] ?? 0.0).toDouble(),
      currency: json['currency'] ?? 'USD',
      timestamp: DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'symbol': symbol,
      'name': name,
      'currentPrice': currentPrice,
      'change': change,
      'changePercent': changePercent,
      'high': high,
      'low': low,
      'open': open,
      'previousClose': previousClose,
      'volume': volume,
      'marketCap': marketCap,
      'pe': pe,
      'eps': eps,
      'currency': currency,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  bool get isPositive => change >= 0;
  bool get isNegative => change < 0;

  String get formattedPrice {
    if (currency == 'INR') {
      return '₹${currentPrice.toStringAsFixed(2)}';
    }
    return '\$${currentPrice.toStringAsFixed(2)}';
  }
  
  String get formattedChange {
    final prefix = change >= 0 ? '+' : '';
    if (currency == 'INR') {
      return '$prefix₹${change.toStringAsFixed(2)}';
    }
    return '$prefix\$${change.toStringAsFixed(2)}';
  }
  
  String get formattedChangePercent => '${changePercent >= 0 ? '+' : ''}${changePercent.toStringAsFixed(2)}%';
}