import '../models/learning_action.dart';

class SmartLearningActions {
  // SMART ACTIONS that guide users to specific places and metrics
  // ALL ACTIONS WORK WITH PAPER TRADING SIMULATOR
  static Map<String, List<LearningAction>> _lessonActions = {
    'what_is_stock': [ // What is a Stock?
      LearningAction(
        id: 'watch_aapl_live',
        title: '👀 Watch AAPL Live',
        description: 'In Paper Trading, search AAPL and watch its price move for 30 seconds',
        type: ActionType.watch,
        symbol: 'AAPL',
        xpReward: 25,
        timeRequired: 1,
        guidance: 'Open Paper Trading, search "AAPL", and watch the price change in real-time. Notice how it moves up and down!',
        followUpQuestion: 'Did you see the price move? Was it going up or down?',
        metadata: {
          'redirectTo': 'trading_screen',
          'symbol': 'AAPL',
          'focusOn': 'price_widget',
          'minWatchTime': 30,
        },
      ),
      LearningAction(
        id: 'buy_aapl_shares',
        title: '💰 Buy AAPL Shares',
        description: 'In Paper Trading, buy 1 share of Apple stock with your virtual money',
        type: ActionType.trade,
        symbol: 'AAPL',
        xpReward: 50,
        timeRequired: 1,
        guidance: 'In Paper Trading, search "AAPL", click "Buy", enter "1" share, then "Place Trade". Congratulations - your first stock!',
        followUpQuestion: 'How did it feel to buy your first stock? How much did it cost?',
        metadata: {
          'redirectTo': 'trading_screen',
          'symbol': 'AAPL',
          'action': 'buy',
          'quantity': 1,
          'verifyTrade': true,
        },
      ),
    ],
    
    'how_stock_prices_work': [ // How Stock Prices Work
      LearningAction(
        id: 'check_aapl_profit',
        title: '📈 Check Your AAPL Profit',
        description: 'In Paper Trading > Portfolio, check if your AAPL trade is profitable',
        type: ActionType.analyze,
        symbol: 'AAPL',
        xpReward: 30,
        timeRequired: 1,
        guidance: 'In Paper Trading, click "Portfolio" tab. Find your AAPL position. Green = profit, Red = loss. What do you see?',
        followUpQuestion: 'Is your AAPL trade profitable? How much did you make or lose?',
        metadata: {
          'redirectTo': 'trading_screen',
          'tab': 'portfolio',
          'focusOn': 'aapl_position',
          'checkProfit': true,
        },
      ),
      LearningAction(
        id: 'sell_if_profitable',
        title: '💰 Sell if Profitable',
        description: 'In Paper Trading, if your AAPL is profitable (green), sell it to lock in your profit!',
        type: ActionType.trade,
        symbol: 'AAPL',
        xpReward: 40,
        timeRequired: 1,
        guidance: 'If your AAPL shows green (profit), click on it in Portfolio, then "Sell" to lock in your gains. Profit secured!',
        followUpQuestion: 'Did you sell? How much profit did you make?',
        metadata: {
          'redirectTo': 'trading_screen',
          'symbol': 'AAPL',
          'action': 'sell',
          'condition': 'if_profitable',
          'verifyTrade': true,
        },
      ),
    ],
    
    'candlestick_patterns': [ // Reading Charts
      LearningAction(
        id: 'analyze_aapl_chart',
        title: '📊 Analyze AAPL Chart',
        description: 'In Paper Trading, search AAPL and look at the chart. Is it in an uptrend or downtrend?',
        type: ActionType.analyze,
        symbol: 'AAPL',
        xpReward: 35,
        timeRequired: 2,
        guidance: 'In Paper Trading, search "AAPL" and click it. View the chart. Is the line going up (uptrend) or down (downtrend)? Green candlesticks = up, Red = down!',
        followUpQuestion: 'What direction is the AAPL chart moving? Up or down?',
        metadata: {
          'redirectTo': 'trading_screen',
          'symbol': 'AAPL',
          'focusOn': 'chart',
          'pattern': 'trend_direction',
        },
      ),
      LearningAction(
        id: 'trade_on_trend',
        title: '📈 Trade Based on Trend',
        description: 'In Paper Trading, if AAPL is in an uptrend (going up), buy more. If downtrend (going down), sell your shares',
        type: ActionType.trade,
        symbol: 'AAPL',
        xpReward: 45,
        timeRequired: 1,
        guidance: 'Based on the chart: If uptrend (line going up), buy more in Paper Trading. If downtrend (line going down), sell to protect yourself!',
        followUpQuestion: 'What did you decide to do based on the chart? Why?',
        metadata: {
          'redirectTo': 'trading_screen',
          'symbol': 'AAPL',
          'action': 'conditional_trade',
          'strategy': 'trend_following',
        },
      ),
    ],
    
    '4': [ // Market Trends
      LearningAction(
        id: 'watch_market_overview',
        title: '📊 Watch Market Overview',
        description: 'Check if the overall market (S&P 500) is up or down today',
        type: ActionType.watch,
        symbol: null,
        xpReward: 25,
        timeRequired: 1,
        metadata: {
          'redirectTo': 'trading_screen',
          'focusOn': 'market_overview',
          'instruction': 'Look at the market overview. Are most stocks green (up) or red (down)?',
          'followUpQuestion': 'Is the market up or down today? How does this affect your stocks?',
        },
      ),
      LearningAction(
        id: 'trade_with_market',
        title: '📈 Trade With Market',
        description: 'If market is up, buy more stocks. If down, sell some shares',
        type: ActionType.trade,
        symbol: null,
        xpReward: 35,
        timeRequired: 1,
        metadata: {
          'redirectTo': 'paper_trading',
          'action': 'market_based_trade',
          'instruction': 'If market is up: buy more stocks. If down: sell some to protect yourself',
          'followUpQuestion': 'How did you adjust your portfolio based on the market?',
        },
      ),
    ],
    
    'risk_management': [ // Risk Management
      LearningAction(
        id: 'check_portfolio_risk',
        title: '🛡️ Check Portfolio Risk',
        description: 'In Paper Trading > Portfolio, see how much you could lose if stocks drop 10%',
        type: ActionType.analyze,
        symbol: null,
        xpReward: 30,
        timeRequired: 2,
        guidance: 'In Paper Trading, click "Portfolio". See your total value. Calculate: If stocks drop 10%, how much would you lose? This helps you understand your risk!',
        followUpQuestion: 'How much could you lose if stocks drop 10%? Is this too risky?',
        metadata: {
          'redirectTo': 'trading_screen',
          'tab': 'portfolio',
          'focusOn': 'risk_calculation',
          'scenario': '10_percent_drop',
        },
      ),
      LearningAction(
        id: 'reduce_risk',
        title: '📉 Reduce Risk',
        description: 'In Paper Trading, sell some shares to reduce your risk exposure',
        type: ActionType.trade,
        symbol: null,
        xpReward: 35,
        timeRequired: 1,
        guidance: 'In Paper Trading Portfolio, if you have too much in one stock, sell some shares. Diversification = don\'t put all eggs in one basket!',
        followUpQuestion: 'Which stocks did you sell to reduce risk?',
        metadata: {
          'redirectTo': 'trading_screen',
          'action': 'reduce_position',
          'strategy': 'risk_reduction',
          'verifyTrade': true,
        },
      ),
    ],
    
    '6': [ // Company Analysis
      LearningAction(
        id: 'read_aapl_news',
        title: '📰 Read AAPL News',
        description: 'Go to Apple\'s stock page and read the latest news about the company',
        type: ActionType.research,
        symbol: 'AAPL',
        xpReward: 35,
        timeRequired: 2,
        metadata: {
          'redirectTo': 'stock_detail',
          'symbol': 'AAPL',
          'focusOn': 'news_section',
          'instruction': 'Scroll down to the news section and read 2 recent articles about Apple',
          'followUpQuestion': 'What did you learn from the Apple news? Is it good or bad for the stock?',
        },
      ),
      LearningAction(
        id: 'trade_on_news',
        title: '⚡ Trade on News',
        description: 'Based on the news, decide if you should buy more AAPL or sell',
        type: ActionType.trade,
        symbol: 'AAPL',
        xpReward: 45,
        timeRequired: 1,
        metadata: {
          'redirectTo': 'paper_trading',
          'symbol': 'AAPL',
          'action': 'news_based_trade',
          'instruction': 'Based on the news you read: Buy more if good news, sell if bad news',
          'followUpQuestion': 'What did you decide based on the news?',
        },
      ),
    ],
    
    '7': [ // Technical Analysis
      LearningAction(
        id: 'check_aapl_rsi',
        title: '📊 Check AAPL RSI',
        description: 'Look at Apple\'s RSI indicator to see if it\'s overbought or oversold',
        type: ActionType.analyze,
        symbol: 'AAPL',
        xpReward: 40,
        timeRequired: 2,
        metadata: {
          'redirectTo': 'stock_detail',
          'symbol': 'AAPL',
          'focusOn': 'rsi_indicator',
          'instruction': 'Look at the RSI indicator on the chart. Is it above 70 (overbought) or below 30 (oversold)?',
          'followUpQuestion': 'What does the RSI tell you about AAPL? Is it overbought or oversold?',
        },
      ),
      LearningAction(
        id: 'trade_on_rsi',
        title: '📈 Trade on RSI',
        description: 'If RSI is oversold (below 30), buy. If overbought (above 70), sell',
        type: ActionType.trade,
        symbol: 'AAPL',
        xpReward: 50,
        timeRequired: 1,
        metadata: {
          'redirectTo': 'paper_trading',
          'symbol': 'AAPL',
          'action': 'rsi_based_trade',
          'instruction': 'Based on RSI: Buy if oversold (below 30), sell if overbought (above 70)',
          'followUpQuestion': 'What did you do based on the RSI signal?',
        },
      ),
    ],
    
    '8': [ // Market Psychology
      LearningAction(
        id: 'check_fear_greed',
        title: '😨 Check Fear vs Greed',
        description: 'Look at market sentiment - are people fearful or greedy today?',
        type: ActionType.analyze,
        symbol: null,
        xpReward: 30,
        timeRequired: 1,
        metadata: {
          'redirectTo': 'trading_screen',
          'focusOn': 'market_sentiment',
          'instruction': 'Look at the market colors. Lots of red = fear, lots of green = greed',
          'followUpQuestion': 'Is the market showing fear (red) or greed (green) today?',
        },
      ),
      LearningAction(
        id: 'contrarian_trade',
        title: '🔄 Make Contrarian Trade',
        description: 'When everyone is fearful (red), buy. When greedy (green), sell',
        type: ActionType.trade,
        symbol: null,
        xpReward: 50,
        timeRequired: 1,
        metadata: {
          'redirectTo': 'paper_trading',
          'action': 'contrarian_trade',
          'instruction': 'Be contrarian: Buy when others are fearful (red), sell when greedy (green)',
          'followUpQuestion': 'Did you go against the crowd? What did you do?',
        },
      ),
    ],
  };

  // Get smart actions for a specific lesson
  static List<LearningAction> getActionsForLesson(String lessonId) {
    final actions = _lessonActions[lessonId] ?? _getDefaultActions();
    return actions.take(2).toList(); // Always max 2 actions
  }

  // Default actions if lesson not found - ALL WORK WITH PAPER TRADING
  static List<LearningAction> _getDefaultActions() {
    return [
      LearningAction(
        id: 'watch_stock',
        title: '👀 Watch Stock',
        description: 'In Paper Trading, pick any stock and watch its price move for 30 seconds',
        type: ActionType.watch,
        symbol: null,
        xpReward: 25,
        timeRequired: 1,
        guidance: 'Open Paper Trading and pick any stock (try AAPL, TSLA, or MSFT). Watch the price update in real-time!',
        followUpQuestion: 'What stock did you watch? Did you see the price change?',
        metadata: {
          'redirectTo': 'trading_screen',
          'minWatchTime': 30,
        },
      ),
      LearningAction(
        id: 'make_trade',
        title: '💰 Make Trade',
        description: 'In Paper Trading, buy or sell any stock with your virtual money',
        type: ActionType.trade,
        symbol: null,
        xpReward: 40,
        timeRequired: 2,
        guidance: 'In Paper Trading, search any stock, click Buy or Sell, enter quantity, then Place Trade. Practice makes perfect!',
        followUpQuestion: 'What trade did you make? Why did you choose that stock?',
        metadata: {
          'redirectTo': 'trading_screen',
          'verifyTrade': true,
        },
      ),
    ];
  }

  // Get simple reflection prompts
  static List<String> getSimpleReflectionPrompts() {
    return [
      'How did you feel about your trading decisions?',
      'What did you learn from looking at the data?',
      'Are you ready for the next lesson?',
    ];
  }
}
