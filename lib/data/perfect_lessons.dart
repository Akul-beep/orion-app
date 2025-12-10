class PerfectLessons {
  // PERFECT LEARNING MODULE PLAN - Exactly 4 questions per lesson
  // Duolingo-style structure with perfect progression from beginner to advanced
  
  static List<Map<String, dynamic>> getAllLessons() {
    return [
      // ========== BEGINNER MODULE ==========
      {
        'id': 'what_is_stock',
        'title': 'What is a Stock?',
        'description': 'Learn the basics of stock ownership',
        'duration': 5,
        'difficulty': 'Beginner',
        'xp_reward': 150,
        'badge': 'Stock Basics Master',
        'badge_emoji': '📈',
        'category': 'Basics',
        'questions': [
          {
            'type': 'multiple_choice',
            'question': 'What is a stock?',
            'options': [
              'A piece of a company you can buy',
              'A type of currency',
              'A bank account',
              'A credit card'
            ],
            'correct': 0,
            'explanation': 'A stock represents ownership in a company! When you buy a stock, you become a part-owner (shareholder).',
            'xp': 10,
          },
          {
            'type': 'true_false',
            'question': 'When you buy a stock, you become a part-owner of that company.',
            'correct': true,
            'explanation': 'Exactly! Buying a stock makes you a shareholder, which means you own a small piece of that company.',
            'xp': 10,
          },
          {
            'type': 'multiple_choice',
            'question': 'How do you make money from stocks?',
            'options': [
              'Price goes up, or company pays dividends',
              'Only when price goes up',
              'Only from dividends',
              'You don\'t make money'
            ],
            'correct': 0,
            'explanation': 'You make money when stock price rises (sell for more than you bought), or when companies pay dividends!',
            'xp': 10,
          },
          {
            'type': 'multiple_choice',
            'question': 'If you buy Apple stock at \$175 and sell at \$200, your profit is:',
            'options': [
              '\$25 per share',
              '\$175 per share',
              '\$200 per share',
              'No profit'
            ],
            'correct': 0,
            'explanation': 'Buy at \$175, sell at \$200 = \$25 profit per share! This is how you make money trading.',
            'xp': 15,
          },
        ],
        'action_items': [
          {
            'id': 'watch_aapl',
            'title': '👀 Watch AAPL',
            'description': 'Go to Trading and watch Apple stock price move',
            'redirectTo': 'trading_screen',
            'symbol': 'AAPL',
            'action': 'watch',
          },
          {
            'id': 'buy_aapl',
            'title': '💰 Buy AAPL',
            'description': 'Buy 1 share of Apple stock in Paper Trading',
            'redirectTo': 'trading_screen',
            'symbol': 'AAPL',
            'action': 'buy',
            'quantity': 1,
          },
        ],
      },
      {
        'id': 'how_stock_prices_work',
        'title': 'How Stock Prices Work',
        'description': 'Learn why stock prices go up and down',
        'duration': 5,
        'difficulty': 'Beginner',
        'xp_reward': 170,
        'badge': 'Price Master',
        'badge_emoji': '💰',
        'category': 'Basics',
        'questions': [
          {
            'type': 'multiple_choice',
            'question': 'What makes stock prices move?',
            'options': [
              'Supply and demand - more buyers = price up',
              'Random chance',
              'Company CEO decides',
              'Only company earnings'
            ],
            'correct': 0,
            'explanation': 'Prices move based on supply and demand! More buyers = price goes up. More sellers = price goes down.',
            'xp': 10,
          },
          {
            'type': 'multiple_choice',
            'question': 'If good news comes out about Apple, what happens to the price?',
            'options': [
              'Usually goes up - more people want to buy',
              'Usually goes down',
              'Stays the same',
              'Random movement'
            ],
            'correct': 0,
            'explanation': 'Good news = more buyers = price usually goes up!',
            'xp': 10,
          },
          {
            'type': 'true_false',
            'question': 'Stock prices change every second during trading hours.',
            'correct': true,
            'explanation': 'Yes! Stock prices update constantly as people buy and sell. Watch any stock to see it move in real-time!',
            'xp': 10,
          },
          {
            'type': 'multiple_choice',
            'question': 'Tesla announces record car sales. What happens to TSLA stock price?',
            'options': [
              'Price goes up - good news attracts buyers',
              'Price goes down',
              'Stays the same',
              'Random movement'
            ],
            'correct': 0,
            'explanation': 'Good news attracts buyers, which pushes the price up!',
            'xp': 15,
          },
        ],
        'action_items': [
          {
            'id': 'watch_tsla',
            'title': '📊 Watch TSLA Price',
            'description': 'Go to Trading and watch Tesla stock price change',
            'redirectTo': 'trading_screen',
            'symbol': 'TSLA',
            'action': 'watch',
          },
          {
            'id': 'check_price_change',
            'title': '📈 Check Price Change',
            'description': 'See how much TSLA moved today (green or red)',
            'redirectTo': 'trading_screen',
            'symbol': 'TSLA',
            'action': 'analyze',
          },
        ],
      },
      {
        'id': 'market_cap',
        'title': 'Market Cap Explained',
        'description': 'Understand company size categories',
        'duration': 5,
        'difficulty': 'Beginner',
        'xp_reward': 180,
        'badge': 'Cap Expert',
        'badge_emoji': '📊',
        'category': 'Basics',
        'questions': [
          {
            'type': 'multiple_choice',
            'question': 'How do you calculate market cap?',
            'options': [
              'Stock price × shares outstanding',
              'Stock price × volume',
              'Revenue × profit',
              'Assets ÷ liabilities'
            ],
            'correct': 0,
            'explanation': 'Market cap = price × shares = total company value!',
            'xp': 10,
          },
          {
            'type': 'multiple_choice',
            'question': 'What is a large-cap stock?',
            'options': [
              'Market cap over \$10 billion',
              'Market cap under \$2 billion',
              'Any tech stock',
              'Only Apple'
            ],
            'correct': 0,
            'explanation': 'Large-cap = \$10B+ (Apple, Microsoft, etc.)!',
            'xp': 10,
          },
          {
            'type': 'true_false',
            'question': 'Market cap shows how big a company is.',
            'correct': true,
            'explanation': 'Exactly! Market cap = total company value. Larger cap = bigger company.',
            'xp': 10,
          },
          {
            'type': 'multiple_choice',
            'question': 'Apple has market cap of \$3 trillion. This makes it:',
            'options': [
              'A mega-cap stock',
              'A small-cap stock',
              'A mid-cap stock',
              'Not a stock'
            ],
            'correct': 0,
            'explanation': 'Over \$1 trillion = mega-cap! Apple is one of the biggest companies in the world.',
            'xp': 15,
          },
        ],
        'action_items': [
          {
            'id': 'check_market_cap',
            'title': '📊 Check Market Cap',
            'description': 'Find AAPL market cap in Trading screen',
            'redirectTo': 'trading_screen',
            'symbol': 'AAPL',
            'action': 'analyze',
          },
        ],
      },
      {
        'id': 'building_portfolio',
        'title': 'Building Your Portfolio',
        'description': 'Learn to create a diversified portfolio',
        'duration': 6,
        'difficulty': 'Beginner',
        'xp_reward': 200,
        'badge': 'Portfolio Builder',
        'badge_emoji': '🏗️',
        'category': 'Basics',
        'questions': [
          {
            'type': 'multiple_choice',
            'question': 'What is diversification?',
            'options': [
              'Spreading money across different stocks/sectors',
              'Putting all money in one stock',
              'Only buying tech stocks',
              'Trading every day'
            ],
            'correct': 0,
            'explanation': 'Diversification = don\'t put all eggs in one basket! Spread risk across different investments.',
            'xp': 10,
          },
          {
            'type': 'multiple_choice',
            'question': 'Why diversify your portfolio?',
            'options': [
              'Reduce risk - if one stock fails, others may succeed',
              'Guarantee profits',
              'Make trading easier',
              'Avoid taxes'
            ],
            'correct': 0,
            'explanation': 'Diversification protects you! If one stock crashes, others may still do well.',
            'xp': 10,
          },
          {
            'type': 'true_false',
            'question': 'Owning 5 different stocks is better than owning 1 stock.',
            'correct': true,
            'explanation': 'Yes! Diversifying across multiple stocks reduces your risk.',
            'xp': 10,
          },
          {
            'type': 'multiple_choice',
            'question': 'You have \$10,000. Better to:',
            'options': [
              'Buy 5 different stocks (\$2,000 each)',
              'Buy \$10,000 of one stock',
              'Keep all cash',
              'Buy only tech stocks'
            ],
            'correct': 0,
            'explanation': 'Diversify! Own 5-10 stocks across different sectors to reduce risk!',
            'xp': 15,
          },
        ],
        'action_items': [
          {
            'id': 'check_portfolio',
            'title': '📈 Check Portfolio',
            'description': 'Go to Trading > Portfolio tab and see your holdings',
            'redirectTo': 'trading_screen',
            'tab': 'portfolio',
            'action': 'analyze',
          },
          {
            'id': 'diversify',
            'title': '🎯 Add Different Stock',
            'description': 'Buy 1 share of JNJ (healthcare) to diversify',
            'redirectTo': 'trading_screen',
            'symbol': 'JNJ',
            'action': 'buy',
            'quantity': 1,
          },
        ],
      },
      {
        'id': 'candlestick_patterns',
        'title': 'Reading Stock Charts',
        'description': 'Learn to read candlestick charts',
        'duration': 6,
        'difficulty': 'Beginner',
        'xp_reward': 220,
        'badge': 'Chart Reader',
        'badge_emoji': '🕯️',
        'category': 'Basics',
        'questions': [
          {
            'type': 'multiple_choice',
            'question': 'What does a green candlestick mean?',
            'options': [
              'Price closed higher than it opened',
              'Price closed lower than it opened',
              'Price didn\'t change',
              'Volume was high'
            ],
            'correct': 0,
            'explanation': 'Green candlesticks show price went up (bullish)!',
            'xp': 10,
          },
          {
            'type': 'multiple_choice',
            'question': 'What does a red candlestick mean?',
            'options': [
              'Price closed lower than it opened',
              'Price closed higher than it opened',
              'Price stayed the same',
              'Low volume'
            ],
            'correct': 0,
            'explanation': 'Red candlesticks show price went down (bearish)!',
            'xp': 10,
          },
          {
            'type': 'true_false',
            'question': 'Candlestick charts show price movement over time.',
            'correct': true,
            'explanation': 'Yes! Each candlestick shows price movement for a period (hour, day, etc.).',
            'xp': 10,
          },
          {
            'type': 'multiple_choice',
            'question': 'On a chart, an upward trend means:',
            'options': [
              'Stock price is generally increasing',
              'Stock price is generally decreasing',
              'Stock price is flat',
              'Volume is high'
            ],
            'correct': 0,
            'explanation': 'An upward trend shows that the stock price is generally moving higher over time!',
            'xp': 15,
          },
        ],
        'action_items': [
          {
            'id': 'view_chart',
            'title': '📊 View Chart',
            'description': 'Go to Trading, search AAPL, and view its chart',
            'redirectTo': 'trading_screen',
            'symbol': 'AAPL',
            'action': 'analyze',
            'focus': 'chart',
          },
          {
            'id': 'identify_trend',
            'title': '📈 Identify Trend',
            'description': 'Determine if AAPL chart is going up or down',
            'redirectTo': 'trading_screen',
            'symbol': 'AAPL',
            'action': 'analyze',
          },
        ],
      },
      
      // ========== INTERMEDIATE MODULE ==========
      {
        'id': 'market_orders',
        'title': 'Market vs Limit Orders',
        'description': 'Learn when to use market orders vs limit orders',
        'duration': 6,
        'difficulty': 'Intermediate',
        'xp_reward': 250,
        'badge': 'Order Master',
        'badge_emoji': '📋',
        'category': 'Trading',
        'questions': [
          {
            'type': 'multiple_choice',
            'question': 'What is a market order?',
            'options': [
              'An order to buy/sell at the best available price',
              'An order to buy/sell at a specific price',
              'An order that cancels automatically',
              'A type of stop loss'
            ],
            'correct': 0,
            'explanation': 'Market orders execute immediately at the best available price!',
            'xp': 15,
          },
          {
            'type': 'multiple_choice',
            'question': 'What is a limit order?',
            'options': [
              'An order to buy/sell at a specific price or better',
              'An order that executes immediately',
              'An order that never executes',
              'A type of market order'
            ],
            'correct': 0,
            'explanation': 'Limit orders only execute at your specified price or better!',
            'xp': 15,
          },
          {
            'type': 'true_false',
            'question': 'Market orders execute faster than limit orders.',
            'correct': true,
            'explanation': 'Yes! Market orders execute immediately, while limit orders wait for your price.',
            'xp': 15,
          },
          {
            'type': 'multiple_choice',
            'question': 'Apple is at \$150. You want to buy if it drops to \$145. Which order?',
            'options': [
              'Limit order at \$145',
              'Market order',
              'Stop order',
              'Any order works'
            ],
            'correct': 0,
            'explanation': 'Limit order at \$145 will only buy if price reaches \$145!',
            'xp': 20,
          },
        ],
        'action_items': [
          {
            'id': 'place_market_order',
            'title': '📋 Place Market Order',
            'description': 'In Trading, buy 1 share of AAPL with a market order',
            'redirectTo': 'trading_screen',
            'symbol': 'AAPL',
            'action': 'buy',
            'quantity': 1,
            'orderType': 'market',
          },
        ],
      },
      {
        'id': 'risk_management',
        'title': 'Risk Management',
        'description': 'Learn the 1% rule and stop losses',
        'duration': 7,
        'difficulty': 'Intermediate',
        'xp_reward': 300,
        'badge': 'Risk Manager',
        'badge_emoji': '🛡️',
        'category': 'Trading',
        'questions': [
          {
            'type': 'multiple_choice',
            'question': 'What is the 1% rule?',
            'options': [
              'Risk 1% of your account per trade',
              'Make 1% profit per day',
              'Trade 1% of your time',
              'Buy 1% of a company'
            ],
            'correct': 0,
            'explanation': 'Never risk more than 1% of your account on a single trade!',
            'xp': 15,
          },
          {
            'type': 'multiple_choice',
            'question': 'What is a stop loss?',
            'options': [
              'An automatic sell order at a set price',
              'A guaranteed profit',
              'A way to buy more stock',
              'A type of chart pattern'
            ],
            'correct': 0,
            'explanation': 'Stop loss automatically sells if price drops to your limit!',
            'xp': 15,
          },
          {
            'type': 'true_false',
            'question': 'You have \$10,000. Your max risk per trade is \$100 (1%).',
            'correct': true,
            'explanation': 'Exactly! 1% of \$10,000 = \$100 maximum risk per trade.',
            'xp': 15,
          },
          {
            'type': 'multiple_choice',
            'question': 'You buy Apple at \$150. You set stop loss at \$140. If price hits \$140:',
            'options': [
              'Your shares sell automatically',
              'Nothing happens',
              'You buy more shares',
              'Price stops falling'
            ],
            'correct': 0,
            'explanation': 'Stop loss at \$140 means if price drops to \$140, your shares sell automatically to limit losses!',
            'xp': 20,
          },
        ],
        'action_items': [
          {
            'id': 'calculate_risk',
            'title': '🧮 Calculate Risk',
            'description': 'Check your portfolio value and calculate 1% risk',
            'redirectTo': 'trading_screen',
            'tab': 'portfolio',
            'action': 'analyze',
          },
          {
            'id': 'set_stop_loss',
            'title': '🛡️ Set Stop Loss',
            'description': 'Set stop loss 5% below on a stock you own',
            'redirectTo': 'trading_screen',
            'tab': 'portfolio',
            'action': 'set_stop_loss',
          },
        ],
      },
      {
        'id': 'pe_ratio',
        'title': 'P/E Ratio: Value Detective',
        'description': 'Learn to spot undervalued stocks',
        'duration': 6,
        'difficulty': 'Intermediate',
        'xp_reward': 280,
        'badge': 'Value Hunter',
        'badge_emoji': '🔍',
        'category': 'Analysis',
        'questions': [
          {
            'type': 'multiple_choice',
            'question': 'What does P/E ratio measure?',
            'options': [
              'How expensive a stock is relative to earnings',
              'Price per share',
              'Profit percentage',
              'Market capitalization'
            ],
            'correct': 0,
            'explanation': 'P/E ratio shows how much you pay for each dollar of earnings!',
            'xp': 15,
          },
          {
            'type': 'multiple_choice',
            'question': 'Which stock is more expensive?',
            'options': [
              'Stock B: P/E = 25',
              'Stock A: P/E = 8',
              'Both are equal',
              'Can\'t tell'
            ],
            'correct': 0,
            'explanation': 'Stock B with P/E 25 is more expensive - you pay more for earnings!',
            'xp': 15,
          },
          {
            'type': 'true_false',
            'question': 'A P/E ratio of 15 means the stock is fairly valued.',
            'correct': true,
            'explanation': 'P/E of 15 is considered fair value - not too expensive, not too cheap!',
            'xp': 15,
          },
          {
            'type': 'multiple_choice',
            'question': 'Comparing stocks: Apple P/E=28, JPM P/E=12. Which is better value?',
            'options': [
              'JPM (lower P/E = better value)',
              'Apple (higher P/E = better)',
              'Both are equal',
              'P/E doesn\'t matter'
            ],
            'correct': 0,
            'explanation': 'Lower P/E = better value! JPM is cheaper relative to its earnings.',
            'xp': 20,
          },
        ],
        'action_items': [
          {
            'id': 'compare_pe',
            'title': '🔍 Compare P/E Ratios',
            'description': 'Check P/E ratio for AAPL and JPM in Trading',
            'redirectTo': 'trading_screen',
            'action': 'analyze',
          },
          {
            'id': 'buy_low_pe',
            'title': '💰 Buy Low P/E',
            'description': 'Buy 1 share of stock with P/E under 15',
            'redirectTo': 'trading_screen',
            'action': 'buy',
            'quantity': 1,
          },
        ],
      },
      {
        'id': 'support_resistance',
        'title': 'Support & Resistance',
        'description': 'Learn to spot key price levels',
        'duration': 6,
        'difficulty': 'Intermediate',
        'xp_reward': 290,
        'badge': 'Level Master',
        'badge_emoji': '📊',
        'category': 'Analysis',
        'questions': [
          {
            'type': 'multiple_choice',
            'question': 'What is support?',
            'options': [
              'Where prices tend to bounce up',
              'Where prices tend to fall',
              'The highest price ever',
              'A type of stock'
            ],
            'correct': 0,
            'explanation': 'Support is like a floor - prices bounce up from there!',
            'xp': 15,
          },
          {
            'type': 'multiple_choice',
            'question': 'What is resistance?',
            'options': [
              'Where prices tend to bounce down',
              'Where prices tend to go up',
              'The lowest price ever',
              'A type of indicator'
            ],
            'correct': 0,
            'explanation': 'Resistance is like a ceiling - prices bounce down from there!',
            'xp': 15,
          },
          {
            'type': 'true_false',
            'question': 'Apple keeps bouncing off \$150. \$150 is a support level.',
            'correct': true,
            'explanation': 'If price bounces UP from a level, it\'s support!',
            'xp': 15,
          },
          {
            'type': 'multiple_choice',
            'question': 'Tesla hits resistance at \$250 and bounces down. What should you do?',
            'options': [
              'Sell at \$250 (resistance = sell)',
              'Buy at \$250',
              'Wait for breakout',
              'Do nothing'
            ],
            'correct': 0,
            'explanation': 'At resistance, price bounces down - time to sell!',
            'xp': 20,
          },
        ],
        'action_items': [
          {
            'id': 'find_support',
            'title': '📊 Find Support',
            'description': 'In Trading, search TSLA and find support level on chart',
            'redirectTo': 'trading_screen',
            'symbol': 'TSLA',
            'action': 'analyze',
            'focus': 'chart',
          },
          {
            'id': 'trade_support',
            'title': '💰 Trade at Support',
            'description': 'Buy 1 share when stock bounces from support',
            'redirectTo': 'trading_screen',
            'action': 'buy',
            'quantity': 1,
          },
        ],
      },
      {
        'id': 'moving_averages',
        'title': 'Moving Averages',
        'description': 'Learn to spot trends with moving averages',
        'duration': 7,
        'difficulty': 'Intermediate',
        'xp_reward': 310,
        'badge': 'Trend Tracker',
        'badge_emoji': '📈',
        'category': 'Analysis',
        'questions': [
          {
            'type': 'multiple_choice',
            'question': 'What does a 50-day moving average show?',
            'options': [
              'Average price over 50 days',
              'Total volume for 50 days',
              'Profit over 50 days',
              'Number of trades in 50 days'
            ],
            'correct': 0,
            'explanation': 'Moving average smooths out price data to show the trend!',
            'xp': 15,
          },
          {
            'type': 'true_false',
            'question': 'When price is above the moving average, the trend is up.',
            'correct': true,
            'explanation': 'Price above MA = uptrend, price below MA = downtrend!',
            'xp': 15,
          },
          {
            'type': 'multiple_choice',
            'question': 'Price crosses above 50-day MA. What does this mean?',
            'options': [
              'Buy signal (bullish crossover)',
              'Sell signal',
              'Hold signal',
              'No signal'
            ],
            'correct': 0,
            'explanation': 'Price crossing above MA is a bullish buy signal!',
            'xp': 15,
          },
          {
            'type': 'multiple_choice',
            'question': 'Apple: price \$175, 50-day MA \$170, 200-day MA \$165. What\'s the trend?',
            'options': [
              'Strong uptrend (price above both MAs)',
              'Downtrend',
              'Sideways',
              'No trend'
            ],
            'correct': 0,
            'explanation': 'Price above both MAs = strong uptrend!',
            'xp': 20,
          },
        ],
        'action_items': [
          {
            'id': 'find_ma',
            'title': '📈 Find Moving Average',
            'description': 'In Trading, search AAPL and view MA on chart',
            'redirectTo': 'trading_screen',
            'symbol': 'AAPL',
            'action': 'analyze',
            'focus': 'chart',
          },
          {
            'id': 'trade_trend',
            'title': '💰 Trade With Trend',
            'description': 'Buy stock with price above moving average',
            'redirectTo': 'trading_screen',
            'action': 'buy',
            'quantity': 1,
          },
        ],
      },
      {
        'id': 'rsi_basics',
        'title': 'RSI: Momentum Indicator',
        'description': 'Master the Relative Strength Index',
        'duration': 7,
        'difficulty': 'Intermediate',
        'xp_reward': 320,
        'badge': 'RSI Rookie',
        'badge_emoji': '📊',
        'category': 'Analysis',
        'questions': [
          {
            'type': 'multiple_choice',
            'question': 'What does RSI stand for?',
            'options': [
              'Relative Strength Index',
              'Risk Sentiment Indicator',
              'Revenue Stock Indicator',
              'Real-time Stock Index'
            ],
            'correct': 0,
            'explanation': 'RSI stands for Relative Strength Index - it measures momentum!',
            'xp': 15,
          },
          {
            'type': 'multiple_choice',
            'question': 'At what level is RSI considered overbought?',
            'options': ['70', '50', '30', '90'],
            'correct': 0,
            'explanation': 'RSI above 70 indicates overbought conditions - time to sell!',
            'xp': 15,
          },
          {
            'type': 'true_false',
            'question': 'RSI below 30 means the stock is oversold (potential buy).',
            'correct': true,
            'explanation': 'RSI below 30 = oversold = potential buying opportunity!',
            'xp': 15,
          },
          {
            'type': 'multiple_choice',
            'question': 'Apple stock has RSI of 25 (oversold). What should you do?',
            'options': [
              'Consider buying (oversold = potential bounce)',
              'Sell immediately',
              'Wait',
              'RSI doesn\'t matter'
            ],
            'correct': 0,
            'explanation': 'RSI of 25 is oversold - perfect buying opportunity!',
            'xp': 20,
          },
        ],
        'action_items': [
          {
            'id': 'check_rsi',
            'title': '📊 Check RSI',
            'description': 'In Trading, search AAPL and find RSI indicator',
            'redirectTo': 'trading_screen',
            'symbol': 'AAPL',
            'action': 'analyze',
            'focus': 'chart',
          },
          {
            'id': 'trade_rsi',
            'title': '💰 Trade on RSI',
            'description': 'Buy if RSI under 30, sell if over 70',
            'redirectTo': 'trading_screen',
            'action': 'conditional_trade',
          },
        ],
      },
      
      // ========== ADVANCED MODULE ==========
      {
        'id': 'trading_psychology',
        'title': 'Trading Psychology',
        'description': 'Master fear and greed in trading',
        'duration': 8,
        'difficulty': 'Advanced',
        'xp_reward': 400,
        'badge': 'Mind Master',
        'badge_emoji': '🧠',
        'category': 'Advanced',
        'questions': [
          {
            'type': 'multiple_choice',
            'question': 'What are the two main emotions in trading?',
            'options': [
              'Fear and Greed',
              'Happy and Sad',
              'Angry and Calm',
              'Excited and Bored'
            ],
            'correct': 0,
            'explanation': 'Fear and greed drive most trading decisions - master these!',
            'xp': 20,
          },
          {
            'type': 'multiple_choice',
            'question': 'What is FOMO in trading?',
            'options': [
              'Fear of Missing Out - buying because everyone else is',
              'Fear of Making Orders',
              'Fear of Market Opportunities',
              'Fear of Money Operations'
            ],
            'correct': 0,
            'explanation': 'FOMO makes you chase trades - avoid it!',
            'xp': 20,
          },
          {
            'type': 'true_false',
            'question': 'Emotions like fear and greed can lead to bad trading decisions.',
            'correct': true,
            'explanation': 'Exactly! Fear and greed are the biggest enemies of successful trading.',
            'xp': 20,
          },
          {
            'type': 'multiple_choice',
            'question': 'Your stock drops 5% in one day. You should:',
            'options': [
              'Stay calm and check your plan',
              'Panic and sell everything',
              'Buy more to average down',
              'Ignore it completely'
            ],
            'correct': 0,
            'explanation': 'Stay calm and stick to your trading plan!',
            'xp': 25,
          },
        ],
        'action_items': [
          {
            'id': 'journal_trade',
            'title': '📝 Journal Trade',
            'description': 'Before trading, write why you\'re buying/selling',
            'redirectTo': 'trading_screen',
            'action': 'reflect',
          },
        ],
      },
    ];
  }

  static Map<String, dynamic>? getLessonById(String id) {
    final lessons = getAllLessons();
    try {
      return lessons.firstWhere((lesson) => lesson['id'] == id);
    } catch (e) {
      return null;
    }
  }

  static List<Map<String, dynamic>> getLessonsByDifficulty(String difficulty) {
    final lessons = getAllLessons();
    return lessons.where((lesson) => lesson['difficulty'] == difficulty).toList();
  }

  static List<Map<String, dynamic>> getLessonsByCategory(String category) {
    final lessons = getAllLessons();
    return lessons.where((lesson) => lesson['category'] == category).toList();
  }
}





