enum ActionType {
  watch,    // Watch stock prices, market data
  analyze,  // Analyze charts, trends, patterns
  trade,    // Make actual trades
  research, // Research companies, news
  reflect,  // Journal, think about decisions
}

class LearningAction {
  final String id;
  final String title;
  final String description;
  final ActionType type;
  final String? symbol; // Stock symbol if applicable
  final int xpReward;
  final int timeRequired; // Minutes required
  final String? guidance; // Specific guidance for the action
  final String? followUpQuestion; // Question after action completion
  final DateTime? completedAt;
  final Map<String, dynamic>? metadata;

  LearningAction({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    this.symbol,
    required this.xpReward,
    required this.timeRequired,
    this.guidance,
    this.followUpQuestion,
    this.completedAt,
    this.metadata,
  });

  LearningAction copyWith({
    String? id,
    String? title,
    String? description,
    ActionType? type,
    String? symbol,
    int? xpReward,
    int? timeRequired,
    String? guidance,
    String? followUpQuestion,
    DateTime? completedAt,
    Map<String, dynamic>? metadata,
  }) {
    return LearningAction(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      symbol: symbol ?? this.symbol,
      xpReward: xpReward ?? this.xpReward,
      timeRequired: timeRequired ?? this.timeRequired,
      guidance: guidance ?? this.guidance,
      followUpQuestion: followUpQuestion ?? this.followUpQuestion,
      completedAt: completedAt ?? this.completedAt,
      metadata: metadata ?? this.metadata,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'type': type.toString(),
      'symbol': symbol,
      'xpReward': xpReward,
      'timeRequired': timeRequired,
      'guidance': guidance,
      'followUpQuestion': followUpQuestion,
      'completedAt': completedAt?.toIso8601String(),
      'metadata': metadata,
    };
  }

  factory LearningAction.fromJson(Map<String, dynamic> json) {
    return LearningAction(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      type: ActionType.values.firstWhere(
        (e) => e.toString() == json['type'],
        orElse: () => ActionType.watch,
      ),
      symbol: json['symbol'],
      xpReward: json['xpReward'],
      timeRequired: json['timeRequired'],
      guidance: json['guidance'],
      followUpQuestion: json['followUpQuestion'],
      completedAt: json['completedAt'] != null 
          ? DateTime.parse(json['completedAt'])
          : null,
      metadata: json['metadata'],
    );
  }

  bool get isCompleted => completedAt != null;
  
  String get typeEmoji {
    switch (type) {
      case ActionType.watch:
        return '👀';
      case ActionType.analyze:
        return '📊';
      case ActionType.trade:
        return '💰';
      case ActionType.research:
        return '🔍';
      case ActionType.reflect:
        return '🤔';
    }
  }

  String get typeDescription {
    switch (type) {
      case ActionType.watch:
        return 'Watch & Observe';
      case ActionType.analyze:
        return 'Analyze & Study';
      case ActionType.trade:
        return 'Trade & Invest';
      case ActionType.research:
        return 'Research & Learn';
      case ActionType.reflect:
        return 'Reflect & Think';
    }
  }
}
