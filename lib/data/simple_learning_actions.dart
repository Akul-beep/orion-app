import '../models/learning_action.dart';

class SimpleLearningActions {
  // MAX 2 ACTIONS PER LESSON - Quick and simple like Duolingo
  static Map<String, List<LearningAction>> _lessonActions = {
    '1': [ // What is a Stock?
      LearningAction(
        id: 'watch_first_stock',
        title: '👀 Watch AAPL',
        description: 'Watch Apple stock for 30 seconds',
        type: ActionType.watch,
        symbol: 'AAPL',
        xpReward: 25,
        timeRequired: 1,
      ),
      LearningAction(
        id: 'buy_first_stock',
        title: '💰 Buy AAPL',
        description: 'Buy 1 share of Apple stock',
        type: ActionType.trade,
        symbol: 'AAPL',
        xpReward: 50,
        timeRequired: 1,
      ),
    ],
    
    '2': [ // How to Make Money
      LearningAction(
        id: 'check_profit',
        title: '📈 Check Profit',
        description: 'See if your AAPL trade is profitable',
        type: ActionType.analyze,
        symbol: 'AAPL',
        xpReward: 30,
        timeRequired: 1,
      ),
      LearningAction(
        id: 'sell_profit',
        title: '💰 Sell for Profit',
        description: 'Sell your AAPL shares if profitable',
        type: ActionType.trade,
        symbol: 'AAPL',
        xpReward: 40,
        timeRequired: 1,
      ),
    ],
    
    '3': [ // Reading Charts
      LearningAction(
        id: 'watch_chart',
        title: '📊 Watch Chart',
        description: 'Look at AAPL chart for 30 seconds',
        type: ActionType.watch,
        symbol: 'AAPL',
        xpReward: 25,
        timeRequired: 1,
      ),
      LearningAction(
        id: 'trade_chart',
        title: '📈 Trade on Chart',
        description: 'Make a trade based on the chart',
        type: ActionType.trade,
        symbol: 'AAPL',
        xpReward: 45,
        timeRequired: 1,
      ),
    ],
    
    '4': [ // Market Trends
      LearningAction(
        id: 'watch_market',
        title: '📊 Watch Market',
        description: 'Check if market is up or down',
        type: ActionType.watch,
        symbol: null,
        xpReward: 20,
        timeRequired: 1,
      ),
      LearningAction(
        id: 'trade_trend',
        title: '📈 Trade Trend',
        description: 'Buy if market is up, sell if down',
        type: ActionType.trade,
        symbol: null,
        xpReward: 35,
        timeRequired: 1,
      ),
    ],
    
    '5': [ // Risk Management
      LearningAction(
        id: 'check_risk',
        title: '🛡️ Check Risk',
        description: 'See how much you could lose',
        type: ActionType.analyze,
        symbol: null,
        xpReward: 25,
        timeRequired: 1,
      ),
      LearningAction(
        id: 'reduce_risk',
        title: '📉 Reduce Risk',
        description: 'Sell some shares to reduce risk',
        type: ActionType.trade,
        symbol: null,
        xpReward: 30,
        timeRequired: 1,
      ),
    ],
  };

  // Get actions for a specific lesson (MAX 2)
  static List<LearningAction> getActionsForLesson(String lessonId) {
    final actions = _lessonActions[lessonId] ?? _getDefaultActions();
    return actions.take(2).toList(); // Always max 2 actions
  }

  // Default actions if lesson not found
  static List<LearningAction> _getDefaultActions() {
    return [
      LearningAction(
        id: 'watch_stock',
        title: '👀 Watch Stock',
        description: 'Watch any stock for 30 seconds',
        type: ActionType.watch,
        symbol: null,
        xpReward: 20,
        timeRequired: 1,
      ),
      LearningAction(
        id: 'make_trade',
        title: '💰 Make Trade',
        description: 'Buy or sell any stock',
        type: ActionType.trade,
        symbol: null,
        xpReward: 30,
        timeRequired: 1,
      ),
    ];
  }

  // SIMPLE reflection - just 1 question like Duolingo
  static List<String> getSimpleReflectionPrompts() {
    return [
      'How did you feel about your trading?',
      'What did you learn today?',
      'Ready for the next lesson?',
    ];
  }
}
