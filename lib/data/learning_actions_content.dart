import '../models/learning_action.dart';

class LearningActionsContent {
  // PERFECT LEARNING ACTIONS - All 30 Days
  // Simple, clear instructions that work with Trading screen from navigation bar
  // Every action is achievable in the paper trading simulator
  
  static Map<String, List<LearningAction>> _lessonActions = {
    // DAY 1: What is a Stock?
    'what_is_stock': [
      LearningAction(
        id: 'watch_aapl_price',
        title: '👀 Watch Apple Stock Price',
        description: 'Open Trading from the bottom menu. Search "AAPL". Tap on Apple. Watch the price for 30 seconds.',
        type: ActionType.watch,
        symbol: 'AAPL',
        xpReward: 25,
        timeRequired: 1,
        guidance: 'Tap the Trading icon at the bottom, search "AAPL", tap on the Apple stock card. Watch the big price number change!',
        followUpQuestion: 'Did you see the price move? Was it going up or down?',
        metadata: {
          'redirectTo': 'trading_screen',
          'symbol': 'AAPL',
          'focusOn': 'price',
          'minWatchTime': 30,
        },
      ),
      LearningAction(
        id: 'buy_first_stock',
        title: '💰 Buy Your First Stock',
        description: 'In Trading, search "AAPL". Tap Apple. Tap the green "Buy" button. Enter 1 share. Tap "Place Trade".',
        type: ActionType.trade,
        symbol: 'AAPL',
        xpReward: 50,
        timeRequired: 2,
        guidance: 'Tap Trading → Search "AAPL" → Tap Apple → Tap green "Buy" → Enter "1" → Tap "Place Trade". Done!',
        followUpQuestion: 'How much did your Apple stock cost? Check the Portfolio tab!',
        metadata: {
          'redirectTo': 'trading_screen',
          'symbol': 'AAPL',
          'action': 'buy',
          'quantity': 1,
        },
      ),
    ],
    
    // DAY 2: How Stock Prices Work
    'how_stock_prices_work': [
      LearningAction(
        id: 'watch_price_change',
        title: '📊 Watch Price Change',
        description: 'Open Trading. Search "TSLA". Tap Tesla. Look for the green or red percentage. Green = up, Red = down.',
        type: ActionType.analyze,
        symbol: 'TSLA',
        xpReward: 30,
        timeRequired: 1,
        guidance: 'In Trading, search "TSLA", tap Tesla. See the price change percentage next to the price. Green means it went up today!',
        followUpQuestion: 'Is Tesla up or down today? What percentage did it move?',
        metadata: {
          'redirectTo': 'trading_screen',
          'symbol': 'TSLA',
          'focusOn': 'price_change',
        },
      ),
      LearningAction(
        id: 'buy_tsla_if_up',
        title: '💰 Buy If Price Is Up',
        description: 'In Trading, search "TSLA". If Tesla is green (up), tap "Buy", enter 1 share, tap "Place Trade".',
        type: ActionType.trade,
        symbol: 'TSLA',
        xpReward: 45,
        timeRequired: 2,
        guidance: 'Check if TSLA is green. If it is, tap Buy → 1 share → Place Trade. If red, just watch it for now!',
        followUpQuestion: 'Was Tesla green or red? What did you decide to do?',
        metadata: {
          'redirectTo': 'trading_screen',
          'symbol': 'TSLA',
          'action': 'buy',
          'quantity': 1,
        },
      ),
    ],
    
    // DAY 3: Market Cap Explained
    'market_cap': [
      LearningAction(
        id: 'check_market_cap',
        title: '📊 Check Market Cap',
        description: 'In Trading, search "AAPL". Tap Apple. Scroll down to company info. Find the Market Cap number.',
        type: ActionType.analyze,
        symbol: 'AAPL',
        xpReward: 35,
        timeRequired: 2,
        guidance: 'Tap Trading → Search "AAPL" → Tap Apple → Scroll down to see company info. Market Cap shows company size!',
        followUpQuestion: 'What is Apple\'s market cap? Is it a large company or small?',
        metadata: {
          'redirectTo': 'trading_screen',
          'symbol': 'AAPL',
          'focusOn': 'market_cap',
        },
      ),
      LearningAction(
        id: 'compare_company_sizes',
        title: '🔍 Compare Company Sizes',
        description: 'In Trading, search "AAPL" and "NVDA". Check their market caps. Which company is bigger?',
        type: ActionType.analyze,
        symbol: null,
        xpReward: 40,
        timeRequired: 3,
        guidance: 'Search "AAPL", check market cap. Then search "NVDA", check market cap. Compare the numbers!',
        followUpQuestion: 'Which company has a bigger market cap? AAPL or NVDA?',
        metadata: {
          'redirectTo': 'trading_screen',
          'focusOn': 'market_cap_comparison',
        },
      ),
    ],
    
    // DAY 4: Building Your Portfolio
    'building_portfolio': [
      LearningAction(
        id: 'check_portfolio',
        title: '📈 Check Your Portfolio',
        description: 'In Trading, tap the "Portfolio" tab at the top. See your total value and all your stocks.',
        type: ActionType.analyze,
        symbol: null,
        xpReward: 30,
        timeRequired: 1,
        guidance: 'Tap Trading → Tap "Portfolio" tab. See your total value at the top. Green = profit, Red = loss!',
        followUpQuestion: 'What\'s your total portfolio value? Are you making money?',
        metadata: {
          'redirectTo': 'trading_screen',
          'tab': 'portfolio',
          'focusOn': 'total_value',
        },
      ),
      LearningAction(
        id: 'buy_different_stock',
        title: '🎯 Diversify Your Portfolio',
        description: 'In Trading, search "JNJ". Tap Johnson & Johnson. Tap "Buy", enter 1 share, tap "Place Trade".',
        type: ActionType.trade,
        symbol: 'JNJ',
        xpReward: 55,
        timeRequired: 2,
        guidance: 'Diversification means owning different types of stocks! JNJ is healthcare, different from tech stocks like AAPL.',
        followUpQuestion: 'Why is it good to own stocks from different industries?',
        metadata: {
          'redirectTo': 'trading_screen',
          'symbol': 'JNJ',
          'action': 'buy',
          'quantity': 1,
        },
      ),
    ],
    
    // DAY 5: Candlestick Patterns
    'candlestick_patterns': [
      LearningAction(
        id: 'look_at_chart',
        title: '🕯️ Look at Stock Chart',
        description: 'In Trading, search "AAPL". Tap Apple. Scroll to see the chart (TradingView widget). Look at the candlesticks. Green bars = price went up, Red bars = price went down.',
        type: ActionType.analyze,
        symbol: 'AAPL',
        xpReward: 35,
        timeRequired: 2,
        guidance: 'Tap Trading → Search "AAPL" → Tap Apple → Scroll down to see the chart. Green candles mean price went up that day! Red candles mean price went down.',
        followUpQuestion: 'Are there more green candles or red candles on Apple\'s chart?',
        metadata: {
          'redirectTo': 'trading_screen',
          'symbol': 'AAPL',
          'focusOn': 'chart',
        },
      ),
      LearningAction(
        id: 'buy_based_on_chart',
        title: '💰 Trade Based on Chart',
        description: 'In Trading, search any stock. Tap it. Scroll to see the chart. If you see mostly green candles (going up), tap "Buy", enter 1 share, tap "Place Trade".',
        type: ActionType.trade,
        symbol: null,
        xpReward: 50,
        timeRequired: 3,
        guidance: 'Tap Trading → Search any stock → Tap it → Scroll to see the chart. Look for stocks with green candles on the chart. These are going up! Buy one if it looks good.',
        followUpQuestion: 'What stock did you buy? Why did you pick it based on the chart?',
        metadata: {
          'redirectTo': 'trading_screen',
          'action': 'buy',
          'quantity': 1,
        },
      ),
    ],
    
    // DAY 6: Market vs Limit Orders
    'market_orders': [
      LearningAction(
        id: 'place_market_order',
        title: '📋 Place Market Order',
        description: 'In Trading, search any stock. Tap it. Tap "Buy". Enter 1 share. Tap "Place Trade". This is a market order - it buys immediately!',
        type: ActionType.trade,
        symbol: null,
        xpReward: 45,
        timeRequired: 2,
        guidance: 'Market order = buys right away at current price! Tap Buy → 1 share → Place Trade. Done instantly!',
        followUpQuestion: 'Did your order execute immediately? That\'s a market order!',
        metadata: {
          'redirectTo': 'trading_screen',
          'action': 'buy',
          'orderType': 'market',
          'quantity': 1,
        },
      ),
    ],
    
    // DAY 7: ETFs vs Mutual Funds
    'etfs_mutual_funds': [
      LearningAction(
        id: 'find_etf',
        title: '📊 Find an ETF',
        description: 'In Trading, search "SPY". Tap it. This is an ETF - it holds many stocks! It trades just like a regular stock.',
        type: ActionType.research,
        symbol: 'SPY',
        xpReward: 40,
        timeRequired: 2,
        guidance: 'ETF = Exchange Traded Fund. SPY holds 500 companies! Search "SPY" in Trading to see it.',
        followUpQuestion: 'What is SPY? How is it different from a regular stock like AAPL?',
        metadata: {
          'redirectTo': 'trading_screen',
          'symbol': 'SPY',
          'focusOn': 'etf_info',
        },
      ),
      LearningAction(
        id: 'buy_etf',
        title: '💰 Buy an ETF',
        description: 'In Trading, search "SPY" or "QQQ". Tap it. Tap "Buy", enter 1 share, tap "Place Trade".',
        type: ActionType.trade,
        symbol: null,
        xpReward: 50,
        timeRequired: 2,
        guidance: 'ETFs give you instant diversification! One share of SPY = owning 500 companies at once!',
        followUpQuestion: 'Why is buying an ETF a good way to diversify?',
        metadata: {
          'redirectTo': 'trading_screen',
          'action': 'buy',
          'quantity': 1,
        },
      ),
    ],
    
    // DAY 8: P/E Ratio
    'pe_ratio': [
      LearningAction(
        id: 'check_pe_ratio',
        title: '💰 Check P/E Ratio',
        description: 'In Trading, search "AAPL". Tap Apple. Scroll to company info. Find the P/E ratio number.',
        type: ActionType.analyze,
        symbol: 'AAPL',
        xpReward: 40,
        timeRequired: 2,
        guidance: 'P/E ratio shows if stock is expensive or cheap. Under 15 = cheap, Over 30 = expensive!',
        followUpQuestion: 'What is Apple\'s P/E ratio? Is it expensive or cheap?',
        metadata: {
          'redirectTo': 'trading_screen',
          'symbol': 'AAPL',
          'focusOn': 'pe_ratio',
        },
      ),
      LearningAction(
        id: 'compare_pe_ratios',
        title: '🔍 Compare P/E Ratios',
        description: 'In Trading, search "AAPL" and "JPM". Check both P/E ratios. Which one is cheaper?',
        type: ActionType.analyze,
        symbol: null,
        xpReward: 45,
        timeRequired: 3,
        guidance: 'Lower P/E = better value! Check AAPL\'s P/E, then JPM\'s P/E. Compare them!',
        followUpQuestion: 'Which stock has a lower P/E ratio? AAPL or JPM?',
        metadata: {
          'redirectTo': 'trading_screen',
          'focusOn': 'pe_comparison',
        },
      ),
    ],
    
    // DAY 9: Moving Averages
    'moving_averages': [
      LearningAction(
        id: 'find_moving_average',
        title: '📈 Find Moving Average',
        description: 'In Trading, search "AAPL". Tap Apple. Scroll to see the chart. Tap the chart to open TradingView. Tap "Indicators" button, choose "Moving Average" (SMA). See the line on the chart!',
        type: ActionType.analyze,
        symbol: 'AAPL',
        xpReward: 40,
        timeRequired: 2,
        guidance: 'Tap Trading → Search "AAPL" → Tap Apple → Scroll to chart → Tap chart to open TradingView → Tap "Indicators" → Choose "Moving Average" (SMA). Moving Average shows the trend! If price is above MA = uptrend. If below = downtrend.',
        followUpQuestion: 'Is Apple\'s price above or below its moving average? What does that mean?',
        metadata: {
          'redirectTo': 'trading_screen',
          'symbol': 'AAPL',
          'focusOn': 'moving_average',
        },
      ),
      LearningAction(
        id: 'buy_uptrend',
        title: '💰 Buy Stock in Uptrend',
        description: 'In Trading, search any stock. Tap it. Scroll to chart. Tap chart, tap "Indicators", choose "Moving Average". If price is above the MA line (uptrend), tap "Buy", enter 1 share, tap "Place Trade".',
        type: ActionType.trade,
        symbol: null,
        xpReward: 55,
        timeRequired: 3,
        guidance: 'Tap Trading → Search any stock → Tap it → Scroll to chart → Tap chart → Tap "Indicators" → Choose "Moving Average" → Check if price is above MA line. Price above moving average = uptrend = good to buy! Buy 1 share.',
        followUpQuestion: 'What stock did you buy? Why did you pick it based on moving average?',
        metadata: {
          'redirectTo': 'trading_screen',
          'action': 'buy',
          'quantity': 1,
        },
      ),
    ],
    
    // DAY 10: Support & Resistance
    'support_resistance': [
      LearningAction(
        id: 'find_support_level',
        title: '📊 Find Support Level',
        description: 'In Trading, search "TSLA". Tap Tesla. Scroll to see the chart. Look at the price history. Find where price bounced up 2+ times from the same level - that\'s support!',
        type: ActionType.analyze,
        symbol: 'TSLA',
        xpReward: 45,
        timeRequired: 3,
        guidance: 'Tap Trading → Search "TSLA" → Tap Tesla → Scroll to see the chart. Support = price level where stock bounces up (like a floor). Look at the chart to find where price touched the same level multiple times and bounced up!',
        followUpQuestion: 'Did you find a support level? What price was it at?',
        metadata: {
          'redirectTo': 'trading_screen',
          'symbol': 'TSLA',
          'focusOn': 'chart_support',
        },
      ),
      LearningAction(
        id: 'buy_at_support',
        title: '💰 Buy Near Support',
        description: 'In Trading, find a stock near its support level. If price bounces up from support, buy 1 share!',
        type: ActionType.trade,
        symbol: null,
        xpReward: 60,
        timeRequired: 3,
        guidance: 'Buying at support is smart! Price often bounces up from there. Find one and buy!',
        followUpQuestion: 'What stock did you buy? Why did support level help you decide?',
        metadata: {
          'redirectTo': 'trading_screen',
          'action': 'buy',
          'quantity': 1,
        },
      ),
    ],
    
    // DAY 11: RSI Basics
    'rsi_basics': [
      LearningAction(
        id: 'check_rsi',
        title: '📊 Check RSI Indicator',
        description: 'In Trading, search "AAPL". Tap Apple. Scroll to see the chart. Tap the chart to open TradingView. Tap "Indicators" button, choose "RSI". See the RSI number at bottom! Under 30 = oversold, Over 70 = overbought.',
        type: ActionType.analyze,
        symbol: 'AAPL',
        xpReward: 40,
        timeRequired: 2,
        guidance: 'Tap Trading → Search "AAPL" → Tap Apple → Scroll to chart → Tap chart to open TradingView → Tap "Indicators" → Choose "RSI". RSI shows if stock is oversold or overbought. Under 30 = might bounce up, Over 70 = might drop!',
        followUpQuestion: 'What is Apple\'s RSI? Is it oversold, overbought, or normal?',
        metadata: {
          'redirectTo': 'trading_screen',
          'symbol': 'AAPL',
          'focusOn': 'rsi',
        },
      ),
      LearningAction(
        id: 'buy_oversold',
        title: '💰 Buy Oversold Stock',
        description: 'In Trading, search any stock. Tap it. Scroll to chart. Tap chart, tap "Indicators", choose "RSI". If RSI is under 30 (oversold), tap "Buy", enter 1 share, tap "Place Trade".',
        type: ActionType.trade,
        symbol: null,
        xpReward: 55,
        timeRequired: 3,
        guidance: 'Tap Trading → Search any stock → Tap it → Scroll to chart → Tap chart → Tap "Indicators" → Choose "RSI" → Check RSI number. RSI under 30 = oversold = might bounce up soon! Buy 1 share and watch it recover.',
        followUpQuestion: 'What stock did you buy? What was its RSI?',
        metadata: {
          'redirectTo': 'trading_screen',
          'action': 'buy',
          'quantity': 1,
        },
      ),
    ],
    
    // DAY 12: Volume Analysis
    'volume_analysis': [
      LearningAction(
        id: 'check_volume',
        title: '📊 Check Trading Volume',
        description: 'In Trading, search "TSLA". Tap Tesla. Look at the volume number. High volume = lots of trading happening!',
        type: ActionType.analyze,
        symbol: 'TSLA',
        xpReward: 35,
        timeRequired: 2,
        guidance: 'Volume shows how many shares traded. High volume = strong move! Check TSLA\'s volume.',
        followUpQuestion: 'What is Tesla\'s trading volume? Is it high or low?',
        metadata: {
          'redirectTo': 'trading_screen',
          'symbol': 'TSLA',
          'focusOn': 'volume',
        },
      ),
      LearningAction(
        id: 'trade_high_volume',
        title: '💰 Trade High Volume Move',
        description: 'In Trading, find a stock up 3%+ with high volume. Buy 1 share - volume confirms the move!',
        type: ActionType.trade,
        symbol: null,
        xpReward: 55,
        timeRequired: 3,
        guidance: 'High volume + price up = strong move! Buy 1 share of a stock with both.',
        followUpQuestion: 'What stock did you buy? What was its volume like?',
        metadata: {
          'redirectTo': 'trading_screen',
          'action': 'buy',
          'quantity': 1,
        },
      ),
    ],
    
    // DAY 13: Risk Management
    'risk_management': [
      LearningAction(
        id: 'check_portfolio_value',
        title: '🧮 Check Portfolio Value',
        description: 'In Trading, tap "Portfolio" tab. See your total value at the top. Write down: 1% of that = your max risk per trade.',
        type: ActionType.analyze,
        symbol: null,
        xpReward: 40,
        timeRequired: 2,
        guidance: 'Risk management = protect your money! If you have \$10,000, 1% = \$100 max risk per trade.',
        followUpQuestion: 'What\'s your portfolio value? How much should you risk per trade (1%)?',
        metadata: {
          'redirectTo': 'trading_screen',
          'tab': 'portfolio',
          'focusOn': 'calculate_risk',
        },
      ),
      LearningAction(
        id: 'set_stop_loss',
        title: '🛡️ Set Stop Loss',
        description: 'In Trading, buy any stock. When buying, tap "Advanced Options". Enter stop loss 5% below current price. This protects all your shares!',
        type: ActionType.analyze,
        symbol: null,
        xpReward: 50,
        timeRequired: 3,
        guidance: 'Stop loss protects you! When buying, tap "Advanced Options", enter stop loss 5% below price. If price drops there, it sells automatically.',
        followUpQuestion: 'Did you set a stop loss? At what price will it sell?',
        metadata: {
          'redirectTo': 'trading_screen',
          'action': 'buy_with_stop_loss',
          'setStopLoss': true,
        },
      ),
    ],
    
    // DAY 14: Position Sizing
    'position_sizing': [
      LearningAction(
        id: 'calculate_position',
        title: '📏 Calculate Position Size',
        description: 'You have \$10,000. Stock costs \$50, stop loss at \$45 (\$5 risk per share). Risk 2% = \$200. Buy 40 shares max (40 × \$5 = \$200).',
        type: ActionType.analyze,
        symbol: null,
        xpReward: 45,
        timeRequired: 3,
        guidance: 'Position sizing = how many shares to buy based on your risk. Calculate before every trade!',
        followUpQuestion: 'If you risk 2% of \$10,000, and each share risks \$5, how many shares should you buy?',
        metadata: {
          'redirectTo': 'trading_screen',
          'focusOn': 'position_calculation',
        },
      ),
      LearningAction(
        id: 'size_your_trade',
        title: '💰 Size Your Next Trade',
        description: 'In Trading, pick any stock. Calculate: Entry price - stop loss = risk per share. Risk 2% of portfolio. Buy that many shares.',
        type: ActionType.trade,
        symbol: null,
        xpReward: 60,
        timeRequired: 4,
        guidance: 'Always size positions based on risk! Calculate before buying, then place the trade with proper size.',
        followUpQuestion: 'What stock did you buy? How did you calculate the position size?',
        metadata: {
          'redirectTo': 'trading_screen',
          'action': 'buy',
        },
      ),
    ],
    
    // DAY 15: Risk/Reward Ratios
    'risk_reward_ratios': [
      LearningAction(
        id: 'calculate_rr_ratio',
        title: '🧮 Calculate Risk/Reward',
        description: 'Plan: Buy at \$50, stop loss at \$45 (\$5 risk), target at \$60 (\$10 reward). Risk/Reward = 5:10 = 1:2. Good!',
        type: ActionType.analyze,
        symbol: null,
        xpReward: 45,
        timeRequired: 3,
        guidance: 'Risk/Reward = Risk amount : Reward amount. 1:2 or better is good! Risk \$5 to make \$10 = 1:2.',
        followUpQuestion: 'If you risk \$5 to make \$10, what is your risk/reward ratio?',
        metadata: {
          'redirectTo': 'trading_screen',
          'focusOn': 'rr_calculation',
        },
      ),
      LearningAction(
        id: 'trade_2to1_rr',
        title: '💰 Trade 2:1 Risk/Reward',
        description: 'In Trading, buy any stock. Set stop loss 5% below entry. Set take profit 10% above entry. That\'s 2:1 risk/reward!',
        type: ActionType.trade,
        symbol: null,
        xpReward: 60,
        timeRequired: 4,
        guidance: '2:1 risk/reward = risk \$1 to make \$2. Set stop loss and take profit to achieve this!',
        followUpQuestion: 'What stock did you trade? What was your risk/reward ratio?',
        metadata: {
          'redirectTo': 'trading_screen',
          'action': 'buy',
          'setStopLoss': true,
          'setTakeProfit': true,
        },
      ),
    ],
    
    // DAY 16: Portfolio Rebalancing
    'portfolio_rebalancing': [
      LearningAction(
        id: 'check_allocation',
        title: '⚖️ Check Portfolio Allocation',
        description: 'In Trading, tap "Portfolio" tab. Look at all your stocks. Is one stock 40%+ of your portfolio?',
        type: ActionType.analyze,
        symbol: null,
        xpReward: 40,
        timeRequired: 2,
        guidance: 'Rebalancing = keep your portfolio balanced! No single stock should be more than 30-40% of portfolio.',
        followUpQuestion: 'Is any single stock too big in your portfolio? Which one?',
        metadata: {
          'redirectTo': 'trading_screen',
          'tab': 'portfolio',
          'focusOn': 'allocation',
        },
      ),
      LearningAction(
        id: 'rebalance_portfolio',
        title: '⚖️ Rebalance Your Portfolio',
        description: 'In Trading Portfolio, if one stock is 40%+, tap it, tap "Sell", sell 25% of it. Buy more of other stocks.',
        type: ActionType.trade,
        symbol: null,
        xpReward: 55,
        timeRequired: 4,
        guidance: 'Rebalancing = selling some winners, buying more of others. Keeps portfolio balanced!',
        followUpQuestion: 'What did you sell? What did you buy? Why?',
        metadata: {
          'redirectTo': 'trading_screen',
          'tab': 'portfolio',
          'action': 'rebalance',
        },
      ),
    ],
    
    // DAY 17: MACD Indicator
    'macd_indicator': [
      LearningAction(
        id: 'check_macd',
        title: '📊 Check MACD Indicator',
        description: 'In Trading, search "AAPL". Tap Apple. Scroll to see the chart. Tap the chart to open TradingView. Tap "Indicators" button, choose "MACD". See the MACD lines! If MACD line crosses above signal = buy signal!',
        type: ActionType.analyze,
        symbol: 'AAPL',
        xpReward: 40,
        timeRequired: 2,
        guidance: 'Tap Trading → Search "AAPL" → Tap Apple → Scroll to chart → Tap chart to open TradingView → Tap "Indicators" → Choose "MACD". MACD shows momentum! When MACD crosses above signal line = bullish = good time to buy!',
        followUpQuestion: 'What does Apple\'s MACD show? Is it bullish or bearish?',
        metadata: {
          'redirectTo': 'trading_screen',
          'symbol': 'AAPL',
          'focusOn': 'macd',
        },
      ),
      LearningAction(
        id: 'trade_macd_signal',
        title: '💰 Trade MACD Signal',
        description: 'In Trading, search any stock. Tap it. Scroll to chart. Tap chart, tap "Indicators", choose "MACD". If MACD line just crossed above signal (bullish), tap "Buy", enter 1 share, tap "Place Trade".',
        type: ActionType.trade,
        symbol: null,
        xpReward: 55,
        timeRequired: 3,
        guidance: 'Tap Trading → Search any stock → Tap it → Scroll to chart → Tap chart → Tap "Indicators" → Choose "MACD" → Check if MACD line crossed above signal. MACD crossover = momentum change! Find one with bullish crossover and buy 1 share.',
        followUpQuestion: 'What stock did you buy? What did the MACD show?',
        metadata: {
          'redirectTo': 'trading_screen',
          'action': 'buy',
          'quantity': 1,
        },
      ),
    ],
    
    // DAY 18: Bollinger Bands
    'bollinger_bands': [
      LearningAction(
        id: 'find_bollinger_bands',
        title: '📈 Find Bollinger Bands',
        description: 'In Trading, search any stock. Tap it. Scroll to see the chart. Tap the chart to open TradingView. Tap "Indicators" button, choose "Bollinger Bands". See the bands around the price!',
        type: ActionType.analyze,
        symbol: null,
        xpReward: 35,
        timeRequired: 2,
        guidance: 'Tap Trading → Search any stock → Tap it → Scroll to chart → Tap chart to open TradingView → Tap "Indicators" → Choose "Bollinger Bands". Bollinger Bands show volatility! Price touching lower band = oversold, upper band = overbought.',
        followUpQuestion: 'Where is the price relative to the Bollinger Bands?',
        metadata: {
          'redirectTo': 'trading_screen',
          'focusOn': 'bollinger_bands',
        },
      ),
      LearningAction(
        id: 'buy_at_lower_band',
        title: '💰 Buy at Lower Band',
        description: 'In Trading, search any stock. Tap it. Scroll to chart. Tap chart, tap "Indicators", choose "Bollinger Bands". If price is touching the lower band (oversold), tap "Buy", enter 1 share, tap "Place Trade".',
        type: ActionType.trade,
        symbol: null,
        xpReward: 55,
        timeRequired: 3,
        guidance: 'Tap Trading → Search any stock → Tap it → Scroll to chart → Tap chart → Tap "Indicators" → Choose "Bollinger Bands" → Check if price touches lower band. Lower Bollinger Band = oversold = might bounce up! Buy 1 share when price touches it.',
        followUpQuestion: 'What stock did you buy? Was it at the lower Bollinger Band?',
        metadata: {
          'redirectTo': 'trading_screen',
          'action': 'buy',
          'quantity': 1,
        },
      ),
    ],
    
    // DAY 19: Chart Patterns
    'chart_patterns': [
      LearningAction(
        id: 'identify_chart_pattern',
        title: '📐 Identify Chart Pattern',
        description: 'In Trading, search "AAPL". Tap Apple. Scroll to see the chart. Look at the price pattern. Try to find triangles (price getting squeezed), head & shoulders (3 peaks), or double tops (2 peaks at same level).',
        type: ActionType.analyze,
        symbol: 'AAPL',
        xpReward: 40,
        timeRequired: 3,
        guidance: 'Tap Trading → Search "AAPL" → Tap Apple → Scroll to see the chart. Chart patterns help predict price moves! Look for triangles (price getting squeezed), double tops (two peaks at same resistance level), head & shoulders (3 peaks with middle highest).',
        followUpQuestion: 'What chart pattern did you see on Apple\'s chart?',
        metadata: {
          'redirectTo': 'trading_screen',
          'symbol': 'AAPL',
          'focusOn': 'chart_patterns',
        },
      ),
      LearningAction(
        id: 'trade_pattern',
        title: '💰 Trade a Pattern',
        description: 'In Trading, find a stock with a clear chart pattern (triangle, double bottom, etc.). Buy 1 share when it breaks out!',
        type: ActionType.trade,
        symbol: null,
        xpReward: 60,
        timeRequired: 4,
        guidance: 'Patterns = opportunity! When price breaks out of a pattern, it often moves strongly. Buy on breakout!',
        followUpQuestion: 'What pattern did you see? What happened when it broke out?',
        metadata: {
          'redirectTo': 'trading_screen',
          'action': 'buy',
          'quantity': 1,
        },
      ),
    ],
    
    // DAY 20: Breakout Trading
    'breakout_trading': [
      LearningAction(
        id: 'find_breakout',
        title: '🚀 Find a Breakout',
        description: 'In Trading, search any stock. Tap it. Scroll to see the chart. Look for price breaking above its previous high (resistance level). That\'s a breakout!',
        type: ActionType.analyze,
        symbol: null,
        xpReward: 45,
        timeRequired: 3,
        guidance: 'Tap Trading → Search any stock → Tap it → Scroll to see the chart. Breakout = price breaks above resistance with volume = strong move coming! Look for price breaking above a previous high on the chart.',
        followUpQuestion: 'Did you find a breakout? Which stock?',
        metadata: {
          'redirectTo': 'trading_screen',
          'focusOn': 'breakout',
        },
      ),
      LearningAction(
        id: 'trade_breakout',
        title: '💰 Trade the Breakout',
        description: 'In Trading, find a stock breaking above resistance with volume. Buy 1 share. Set stop loss 5% below entry.',
        type: ActionType.trade,
        symbol: null,
        xpReward: 60,
        timeRequired: 4,
        guidance: 'Breakout = momentum! Buy when price breaks above resistance. Set stop loss to protect yourself!',
        followUpQuestion: 'What stock broke out? What was the breakout price?',
        metadata: {
          'redirectTo': 'trading_screen',
          'action': 'buy',
          'quantity': 1,
          'setStopLoss': true,
        },
      ),
    ],
    
    // DAY 21: Gap Trading
    'gap_trading': [
      LearningAction(
        id: 'watch_for_gaps',
        title: '📈 Watch for Gaps',
        description: 'In Trading, check stocks up/down 5%+ today. These likely gapped (jumped) at market open. Watch if they fill the gap!',
        type: ActionType.watch,
        symbol: null,
        xpReward: 35,
        timeRequired: 3,
        guidance: 'Gap = price jumps from yesterday\'s close. Big moves at open often gap. Watch if they fill back!',
        followUpQuestion: 'Did you see any stocks with big gaps today? Which ones?',
        metadata: {
          'redirectTo': 'trading_screen',
          'focusOn': 'gaps',
        },
      ),
      LearningAction(
        id: 'trade_gap_fill',
        title: '💰 Trade Gap Fill',
        description: 'In Trading, find a stock that gapped down today. If it starts filling the gap (going back up), buy 1 share!',
        type: ActionType.trade,
        symbol: null,
        xpReward: 55,
        timeRequired: 4,
        guidance: 'Gap fill = price goes back to fill the gap. Buy when gap starts filling for potential profit!',
        followUpQuestion: 'What stock had a gap? Did you buy when it started filling?',
        metadata: {
          'redirectTo': 'trading_screen',
          'action': 'buy',
          'quantity': 1,
        },
      ),
    ],
    
    // DAY 22: Financial Statements
    'financial_statements': [
      LearningAction(
        id: 'check_earnings',
        title: '📄 Check Company Earnings',
        description: 'In Trading, search "AAPL". Tap Apple. Scroll to company info. Check if revenue and earnings are growing.',
        type: ActionType.research,
        symbol: 'AAPL',
        xpReward: 45,
        timeRequired: 3,
        guidance: 'Financial statements show company health! Growing revenue and earnings = healthy company = good investment!',
        followUpQuestion: 'Is Apple\'s revenue growing? What about earnings?',
        metadata: {
          'redirectTo': 'trading_screen',
          'symbol': 'AAPL',
          'focusOn': 'earnings',
        },
      ),
      LearningAction(
        id: 'buy_growing_company',
        title: '💰 Buy Growing Company',
        description: 'In Trading, find a company with growing revenue and earnings. Buy 1 share - growing companies are good investments!',
        type: ActionType.trade,
        symbol: null,
        xpReward: 55,
        timeRequired: 4,
        guidance: 'Growing revenue + growing earnings = strong company! Buy 1 share of a growing company.',
        followUpQuestion: 'What company did you buy? Why did you pick it based on financials?',
        metadata: {
          'redirectTo': 'trading_screen',
          'action': 'buy',
          'quantity': 1,
        },
      ),
    ],
    
    // DAY 23: Earnings Reports
    'earnings_reports': [
      LearningAction(
        id: 'watch_earnings_trade',
        title: '📈 Watch Earnings Trade',
        description: 'In Trading, find a stock that reported earnings today. Watch the price - earnings often cause big moves!',
        type: ActionType.watch,
        symbol: null,
        xpReward: 40,
        timeRequired: 3,
        guidance: 'Earnings reports = company profit results! Beating expectations = price up, missing = price down!',
        followUpQuestion: 'Did you see any earnings reports today? How did the stock react?',
        metadata: {
          'redirectTo': 'trading_screen',
          'focusOn': 'earnings_reaction',
        },
      ),
      LearningAction(
        id: 'trade_earnings_reaction',
        title: '💰 Trade Earnings Reaction',
        description: 'In Trading, find a stock that beat earnings and gapped up. Wait for pullback, then buy 1 share if it bounces.',
        type: ActionType.trade,
        symbol: null,
        xpReward: 60,
        timeRequired: 4,
        guidance: 'Beat earnings + gap up = good sign! But wait for pullback before buying - don\'t chase!',
        followUpQuestion: 'What stock beat earnings? Did you buy after the pullback?',
        metadata: {
          'redirectTo': 'trading_screen',
          'action': 'buy',
          'quantity': 1,
        },
      ),
    ],
    
    // DAY 24: Sector Investing
    'sector_investing': [
      LearningAction(
        id: 'check_sectors',
        title: '🏭 Check Different Sectors',
        description: 'In Trading, check your portfolio. Do you have tech (AAPL, NVDA), healthcare (JNJ), finance (JPM), and other sectors?',
        type: ActionType.analyze,
        symbol: null,
        xpReward: 35,
        timeRequired: 2,
        guidance: 'Sector diversification = owning stocks from different industries. Tech, healthcare, finance, energy, etc.',
        followUpQuestion: 'What sectors do you have in your portfolio? Are you diversified?',
        metadata: {
          'redirectTo': 'trading_screen',
          'tab': 'portfolio',
          'focusOn': 'sectors',
        },
      ),
      LearningAction(
        id: 'add_missing_sector',
        title: '💰 Add Missing Sector',
        description: 'In Trading Portfolio, if you\'re missing a sector (healthcare, finance, energy), buy 1 stock from that sector!',
        type: ActionType.trade,
        symbol: null,
        xpReward: 50,
        timeRequired: 3,
        guidance: 'Diversify across sectors! If you only have tech, add healthcare (JNJ) or finance (JPM).',
        followUpQuestion: 'What sector did you add? Why is sector diversification important?',
        metadata: {
          'redirectTo': 'trading_screen',
          'action': 'buy',
          'quantity': 1,
        },
      ),
    ],
    
    // DAY 25: Market Sentiment
    'market_sentiment': [
      LearningAction(
        id: 'check_market_mood',
        title: '😊 Check Market Mood',
        description: 'In Trading, look at all stocks. Are most green (happy/bullish) or red (scared/bearish)? This shows market sentiment!',
        type: ActionType.analyze,
        symbol: null,
        xpReward: 35,
        timeRequired: 2,
        guidance: 'Market sentiment = overall mood! All green = greedy (might top), all red = fearful (might bottom).',
        followUpQuestion: 'What is the market sentiment today? Are people greedy or fearful?',
        metadata: {
          'redirectTo': 'trading_screen',
          'focusOn': 'market_sentiment',
        },
      ),
      LearningAction(
        id: 'contrarian_trade',
        title: '🔄 Make Contrarian Trade',
        description: 'In Trading, if most stocks are red (fearful), find one good stock and buy 1 share. Be contrarian - buy when others sell!',
        type: ActionType.trade,
        symbol: null,
        xpReward: 60,
        timeRequired: 3,
        guidance: 'Contrarian = go against the crowd! When everyone is scared (red), good stocks get cheap. Buy them!',
        followUpQuestion: 'What stock did you buy? Why did you go against the crowd?',
        metadata: {
          'redirectTo': 'trading_screen',
          'action': 'buy',
          'quantity': 1,
        },
      ),
    ],
    
    // DAY 26: Market Cycles
    'market_cycles': [
      LearningAction(
        id: 'identify_cycle',
        title: '🔄 Identify Market Cycle',
        description: 'In Trading, check overall market. Up 20%+ from lows? Bull market. Down 20%+? Bear market. Recovering? Recovery phase!',
        type: ActionType.analyze,
        symbol: null,
        xpReward: 40,
        timeRequired: 3,
        guidance: 'Market cycles: Bull = going up, Bear = going down, Recovery = bouncing back. Know which phase you\'re in!',
        followUpQuestion: 'What market cycle phase are we in? Bull, bear, or recovery?',
        metadata: {
          'redirectTo': 'trading_screen',
          'focusOn': 'market_cycle',
        },
      ),
      LearningAction(
        id: 'trade_cycle_phase',
        title: '💰 Trade Cycle Phase',
        description: 'Based on market cycle: Bull market? Buy growth stocks. Bear market? Be defensive. Recovery? Buy quality stocks cheap.',
        type: ActionType.trade,
        symbol: null,
        xpReward: 55,
        timeRequired: 3,
        guidance: 'Different cycles need different strategies! Bull = aggressive, Bear = defensive, Recovery = selective buying.',
        followUpQuestion: 'What did you buy based on the market cycle? Why?',
        metadata: {
          'redirectTo': 'trading_screen',
          'action': 'buy',
          'quantity': 1,
        },
      ),
    ],
    
    // DAY 27: Swing Trading
    'swing_trading': [
      LearningAction(
        id: 'plan_swing_trade',
        title: '🎯 Plan Swing Trade',
        description: 'Pick a stock. Plan to hold for 7 days. Set take profit 10% above entry. Set stop loss 5% below entry. That\'s swing trading!',
        type: ActionType.analyze,
        symbol: null,
        xpReward: 45,
        timeRequired: 3,
        guidance: 'Swing trading = hold for days/weeks, not hours. Set clear targets: 10% profit, 5% stop loss.',
        followUpQuestion: 'What stock did you plan to swing trade? What were your targets?',
        metadata: {
          'redirectTo': 'trading_screen',
          'focusOn': 'swing_plan',
        },
      ),
      LearningAction(
        id: 'place_swing_trade',
        title: '💰 Place Swing Trade',
        description: 'In Trading, buy 1 share. Set take profit 10% above. Set stop loss 5% below. Hold for 7 days. This is swing trading!',
        type: ActionType.trade,
        symbol: null,
        xpReward: 60,
        timeRequired: 4,
        guidance: 'Swing trade = longer hold time! Set take profit and stop loss, then hold for several days.',
        followUpQuestion: 'What stock did you swing trade? When will you check it again?',
        metadata: {
          'redirectTo': 'trading_screen',
          'action': 'buy',
          'quantity': 1,
          'setTakeProfit': true,
          'setStopLoss': true,
        },
      ),
    ],
    
    // DAY 28: Day Trading Basics
    'day_trading_basics': [
      LearningAction(
        id: 'practice_day_trade',
        title: '⚡ Practice Day Trade',
        description: 'In Trading, buy 1 share of a volatile stock (TSLA, NVDA). Watch it for 1 hour. Sell if up 3% OR down 3%. Same day trade!',
        type: ActionType.trade,
        symbol: null,
        xpReward: 60,
        timeRequired: 5,
        guidance: 'Day trading = buy and sell same day! Watch closely, sell quickly if profit (3%) or loss (3%).',
        followUpQuestion: 'What stock did you day trade? Did you make profit or cut loss quickly?',
        metadata: {
          'redirectTo': 'trading_screen',
          'action': 'buy',
          'quantity': 1,
          'dayTrade': true,
        },
      ),
    ],
    
    // DAY 29: Dividend Investing
    'dividend_investing': [
      LearningAction(
        id: 'find_dividend_stock',
        title: '💰 Find Dividend Stock',
        description: 'In Trading, search "JNJ" or "KO". Tap it. Check dividend yield. If 3%+, the company pays you regular income!',
        type: ActionType.research,
        symbol: null,
        xpReward: 40,
        timeRequired: 2,
        guidance: 'Dividend stocks pay you money! JNJ and KO pay 3%+ dividends. Check their yields.',
        followUpQuestion: 'What is the dividend yield on JNJ or KO?',
        metadata: {
          'redirectTo': 'trading_screen',
          'focusOn': 'dividend_yield',
        },
      ),
      LearningAction(
        id: 'buy_dividend_stock',
        title: '💰 Buy Dividend Stock',
        description: 'In Trading, search "JNJ" or "KO". Tap it. Tap "Buy", enter 1 share, tap "Place Trade". You\'ll earn regular income!',
        type: ActionType.trade,
        symbol: null,
        xpReward: 50,
        timeRequired: 2,
        guidance: 'Dividend stocks = passive income! Buy JNJ or KO and they pay you money every quarter.',
        followUpQuestion: 'What dividend stock did you buy? How much will it pay you?',
        metadata: {
          'redirectTo': 'trading_screen',
          'symbol': 'JNJ',
          'action': 'buy',
          'quantity': 1,
        },
      ),
    ],
    
    // DAY 30: Growth vs Value
    'growth_vs_value': [
      LearningAction(
        id: 'compare_growth_value',
        title: '⚖️ Compare Growth vs Value',
        description: 'In Trading, compare NVDA (growth, high P/E ~50) vs JPM (value, low P/E ~12). Both have pros and cons!',
        type: ActionType.analyze,
        symbol: null,
        xpReward: 45,
        timeRequired: 3,
        guidance: 'Growth = fast growing, expensive. Value = slow growing, cheap. Both are valid strategies!',
        followUpQuestion: 'What\'s the difference between NVDA (growth) and JPM (value)?',
        metadata: {
          'redirectTo': 'trading_screen',
          'focusOn': 'growth_vs_value',
        },
      ),
      LearningAction(
        id: 'balance_growth_value',
        title: '⚖️ Balance Portfolio Styles',
        description: 'In Trading Portfolio, if you have 3+ growth stocks, add 1 value stock (JPM, KO). Balance your portfolio!',
        type: ActionType.trade,
        symbol: null,
        xpReward: 55,
        timeRequired: 3,
        guidance: 'Balance = don\'t put all eggs in one basket! Have both growth and value stocks.',
        followUpQuestion: 'What value stock did you add? Why is balance important?',
        metadata: {
          'redirectTo': 'trading_screen',
          'action': 'buy',
          'quantity': 1,
        },
      ),
    ],
  };

  // Get actions for a specific lesson
  static List<LearningAction> getActionsForLesson(String lessonId) {
    return _lessonActions[lessonId] ?? _getDefaultActions();
  }

  // Default actions if lesson not found
  static List<LearningAction> _getDefaultActions() {
    return [
      LearningAction(
        id: 'watch_market',
        title: '👀 Watch the Market',
        description: 'In Trading, pick any stock and watch its price move for 30 seconds',
        type: ActionType.watch,
        symbol: null,
        xpReward: 25,
        timeRequired: 1,
        guidance: 'Tap Trading from bottom menu, pick any stock (try AAPL), watch the price change!',
        followUpQuestion: 'What stock did you watch? Did you see the price change?',
        metadata: {
          'redirectTo': 'trading_screen',
          'minWatchTime': 30,
        },
      ),
      LearningAction(
        id: 'make_trade',
        title: '💰 Make a Trade',
        description: 'In Trading, buy or sell any stock with your virtual money',
        type: ActionType.trade,
        symbol: null,
        xpReward: 40,
        timeRequired: 2,
        guidance: 'Tap Trading → Search any stock → Tap it → Tap Buy → Enter quantity → Tap Place Trade',
        followUpQuestion: 'What trade did you make? Why did you choose that stock?',
        metadata: {
          'redirectTo': 'trading_screen',
        },
      ),
    ];
  }

  // Get reflection prompts based on completed actions
  static List<String> getReflectionPrompts(List<LearningAction> completedActions) {
    final prompts = <String>[];
    
    for (final action in completedActions) {
      switch (action.type) {
        case ActionType.watch:
          prompts.add('What patterns did you notice while watching ${action.symbol ?? 'the market'}?');
          break;
        case ActionType.analyze:
          prompts.add('What insights did you gain from analyzing ${action.symbol ?? 'your data'}?');
          break;
        case ActionType.trade:
          prompts.add('How did you feel about your ${action.symbol ?? 'trading'} decision? What would you do differently?');
          break;
        case ActionType.research:
          prompts.add('What surprised you most during your research about ${action.symbol ?? 'this topic'}?');
          break;
        case ActionType.reflect:
          prompts.add('What did you learn about yourself from reflecting on ${action.symbol ?? 'this experience'}?');
          break;
      }
    }
    
    prompts.addAll([
      'What was your biggest "aha!" moment today?',
      'What mistake did you make that taught you something valuable?',
      'If you could go back 1 hour, what would you do differently?',
      'What pattern do you notice in your trading behavior?',
      'How confident do you feel about your next trade?',
      'What\'s one thing you want to research more about?',
    ]);
    
    return prompts;
  }

  // Get motivational messages based on performance
  static String getMotivationalMessage(int xpEarned, int actionsCompleted) {
    if (actionsCompleted >= 3 && xpEarned >= 150) {
      return '🔥 You\'re on fire! Keep this momentum going!';
    } else if (actionsCompleted >= 2) {
      return 'Great progress! You\'re building real skills!';
    } else {
      return 'Every expert was once a beginner. Keep going!';
    }
  }

  // Get next recommended action based on user progress
  static LearningAction? getNextRecommendedAction(List<LearningAction> availableActions) {
    if (availableActions.isEmpty) return null;
    
    availableActions.sort((a, b) {
      final aScore = a.xpReward / a.timeRequired;
      final bScore = b.xpReward / b.timeRequired;
      return bScore.compareTo(aScore);
    });
    
    return availableActions.first;
  }
}