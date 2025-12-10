class PaperTrade {
  final String id;
  final String symbol;
  final String action; // 'buy' or 'sell'
  final double price;
  final int quantity;
  final DateTime timestamp;
  final String status; // 'pending', 'filled', 'cancelled'
  final double? stopLoss;
  final double? takeProfit;
  final String? notes;

  PaperTrade({
    required this.id,
    required this.symbol,
    required this.action,
    required this.price,
    required this.quantity,
    required this.timestamp,
    required this.status,
    this.stopLoss,
    this.takeProfit,
    this.notes,
  });

  factory PaperTrade.fromJson(Map<String, dynamic> json) {
    return PaperTrade(
      id: json['id'] ?? '',
      symbol: json['symbol'] ?? '',
      action: json['action'] ?? '',
      price: (json['price'] ?? 0.0).toDouble(),
      quantity: json['quantity'] ?? 0,
      timestamp: DateTime.parse(json['timestamp'] ?? DateTime.now().toIso8601String()),
      status: json['status'] ?? 'pending',
      stopLoss: json['stopLoss']?.toDouble(),
      takeProfit: json['takeProfit']?.toDouble(),
      notes: json['notes'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'symbol': symbol,
      'action': action,
      'price': price,
      'quantity': quantity,
      'timestamp': timestamp.toIso8601String(),
      'status': status,
      'stopLoss': stopLoss,
      'takeProfit': takeProfit,
      'notes': notes,
    };
  }

  double get totalValue => price * quantity;
  
  bool get isBuy => action == 'buy';
  bool get isSell => action == 'sell';
  bool get isFilled => status == 'filled';
  bool get isPending => status == 'pending';
}

class PaperPosition {
  final String symbol;
  final int quantity;
  final double averagePrice;
  final double currentPrice;
  final DateTime firstBought;
  final DateTime lastUpdated;
  final double unrealizedPnL;
  final double unrealizedPnLPercent;
  final double totalInvested;
  final double currentValue;
  final double? stopLoss; // Stop loss price for this position
  final double? takeProfit; // Take profit price for this position

  PaperPosition({
    required this.symbol,
    required this.quantity,
    required this.averagePrice,
    required this.currentPrice,
    required this.firstBought,
    required this.lastUpdated,
    required this.unrealizedPnL,
    required this.unrealizedPnLPercent,
    required this.totalInvested,
    required this.currentValue,
    this.stopLoss,
    this.takeProfit,
  });

  factory PaperPosition.fromJson(Map<String, dynamic> json) {
    return PaperPosition(
      symbol: json['symbol'] ?? '',
      quantity: json['quantity'] ?? 0,
      averagePrice: (json['averagePrice'] ?? 0.0).toDouble(),
      currentPrice: (json['currentPrice'] ?? 0.0).toDouble(),
      firstBought: DateTime.parse(json['firstBought'] ?? DateTime.now().toIso8601String()),
      lastUpdated: DateTime.parse(json['lastUpdated'] ?? DateTime.now().toIso8601String()),
      unrealizedPnL: (json['unrealizedPnL'] ?? 0.0).toDouble(),
      unrealizedPnLPercent: (json['unrealizedPnLPercent'] ?? 0.0).toDouble(),
      totalInvested: (json['totalInvested'] ?? 0.0).toDouble(),
      currentValue: (json['currentValue'] ?? 0.0).toDouble(),
      stopLoss: json['stopLoss']?.toDouble(),
      takeProfit: json['takeProfit']?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'symbol': symbol,
      'quantity': quantity,
      'averagePrice': averagePrice,
      'currentPrice': currentPrice,
      'firstBought': firstBought.toIso8601String(),
      'lastUpdated': lastUpdated.toIso8601String(),
      'unrealizedPnL': unrealizedPnL,
      'unrealizedPnLPercent': unrealizedPnLPercent,
      'totalInvested': totalInvested,
      'currentValue': currentValue,
      'stopLoss': stopLoss,
      'takeProfit': takeProfit,
    };
  }

  bool get isProfit => unrealizedPnL > 0;
  bool get isLoss => unrealizedPnL < 0;
  bool get isBreakEven => unrealizedPnL == 0;
}

class PaperPortfolio {
  final double totalValue;
  final double cashBalance;
  final double investedValue;
  final double totalPnL;
  final double totalPnLPercent;
  final List<PaperPosition> positions;
  final List<PaperTrade> recentTrades;
  final DateTime lastUpdated;
  final double dayChange;
  final double dayChangePercent;

  PaperPortfolio({
    required this.totalValue,
    required this.cashBalance,
    required this.investedValue,
    required this.totalPnL,
    required this.totalPnLPercent,
    required this.positions,
    required this.recentTrades,
    required this.lastUpdated,
    required this.dayChange,
    required this.dayChangePercent,
  });

  factory PaperPortfolio.fromJson(Map<String, dynamic> json) {
    return PaperPortfolio(
      totalValue: (json['totalValue'] ?? 0.0).toDouble(),
      cashBalance: (json['cashBalance'] ?? 0.0).toDouble(),
      investedValue: (json['investedValue'] ?? 0.0).toDouble(),
      totalPnL: (json['totalPnL'] ?? 0.0).toDouble(),
      totalPnLPercent: (json['totalPnLPercent'] ?? 0.0).toDouble(),
      positions: (json['positions'] as List<dynamic>? ?? [])
          .map((p) => PaperPosition.fromJson(p))
          .toList(),
      recentTrades: (json['recentTrades'] as List<dynamic>? ?? [])
          .map((t) => PaperTrade.fromJson(t))
          .toList(),
      lastUpdated: DateTime.parse(json['lastUpdated'] ?? DateTime.now().toIso8601String()),
      dayChange: (json['dayChange'] ?? 0.0).toDouble(),
      dayChangePercent: (json['dayChangePercent'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalValue': totalValue,
      'cashBalance': cashBalance,
      'investedValue': investedValue,
      'totalPnL': totalPnL,
      'totalPnLPercent': totalPnLPercent,
      'positions': positions.map((p) => p.toJson()).toList(),
      'recentTrades': recentTrades.map((t) => t.toJson()).toList(),
      'lastUpdated': lastUpdated.toIso8601String(),
      'dayChange': dayChange,
      'dayChangePercent': dayChangePercent,
    };
  }

  bool get isProfit => totalPnL > 0;
  bool get isLoss => totalPnL < 0;
  bool get isBreakEven => totalPnL == 0;
}


