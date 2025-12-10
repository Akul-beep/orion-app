import '../services/dynamic_lesson_service.dart';

class InteractiveLessons {
  // PERFECT LEARNING MODULE SYSTEM - Exactly 4 questions per lesson
  // Duolingo-style structure with perfect progression from beginner to advanced
  // 
  // NOW USES DYNAMIC LESSON SERVICE - Lessons can be updated via Supabase!
  // Falls back to hardcoded lessons if Supabase is unavailable
  
  static DynamicLessonService? _dynamicService;
  static DynamicLessonService get _service {
    _dynamicService ??= DynamicLessonService();
    return _dynamicService!;
  }
  
  /// Get all lessons (from Supabase or fallback to hardcoded)
  static Future<List<Map<String, dynamic>>> getAllLessons() async {
    try {
      // Try dynamic service first
      return await _service.getAllLessons();
    } catch (e) {
      print('⚠️ Error loading dynamic lessons, using fallback: $e');
      return getHardcodedLessons();
    }
  }
  
  /// Get lesson by ID (from Supabase or fallback)
  static Future<Map<String, dynamic>?> getLessonById(String id) async {
    try {
      return await _service.getLessonById(id);
    } catch (e) {
      print('⚠️ Error loading dynamic lesson, using fallback: $e');
      final hardcoded = getHardcodedLessons();
      try {
        return hardcoded.firstWhere((lesson) => lesson['id'] == id);
      } catch (e) {
        return null;
      }
    }
  }
  
  /// Get lessons by difficulty (from Supabase or fallback)
  static Future<List<Map<String, dynamic>>> getLessonsByDifficulty(String difficulty) async {
    try {
      return await _service.getLessonsByDifficulty(difficulty);
    } catch (e) {
      print('⚠️ Error loading dynamic lessons by difficulty, using fallback: $e');
      final hardcoded = getHardcodedLessons();
      return hardcoded.where((lesson) => lesson['difficulty'] == difficulty).toList();
    }
  }
  
  /// Hardcoded lessons (fallback when Supabase unavailable)
  /// Also used for migration script
  static List<Map<String, dynamic>> getHardcodedLessons() {
    return [
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
        'steps': [
          {
            'type': 'intro',
            'content': 'Ready to learn about stocks?',
            'subtitle': 'Discover what stocks are and how they work!',
            'icon': '📈',
          },
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
          {
            'type': 'summary',
            'title': '🎉 You earned +150 XP!',
            'subtitle': 'You\'re now a Stock Basics Master 📈',
            'concepts_learned': [
              'Stocks = ownership in companies',
              'Buy stocks = become a shareholder',
              'Make money when price rises',
              'Or receive dividend payments'
            ],
            'next_lesson': 'How Stock Prices Work',
            'badge_unlocked': 'Stock Basics Master',
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
        'steps': [
          {
            'type': 'intro',
            'content': 'Ready to understand prices?',
            'subtitle': 'Learn why stocks go up and down!',
            'icon': '💰',
          },
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
          {
            'type': 'summary',
            'title': '🎉 You earned +170 XP!',
            'subtitle': 'You\'re now a Price Master 💰',
            'concepts_learned': [
              'Prices move from supply & demand',
              'More buyers = price up',
              'More sellers = price down',
              'News affects supply and demand'
            ],
            'next_lesson': 'Market Cap Explained',
            'badge_unlocked': 'Price Master',
          },
        ],
      },
      {
        'id': 'rsi_basics',
        'title': 'RSI: The Momentum Indicator',
        'description': 'Master the Relative Strength Index in 5 minutes',
        'duration': 5,
        'difficulty': 'Intermediate',
        'xp_reward': 200,
        'badge': 'RSI Rookie',
        'badge_emoji': '📊',
        'category': 'Analysis',
        'steps': [
          {
            'type': 'intro',
            'content': 'Ready to master RSI?',
            'subtitle': 'Learn how to spot overbought and oversold stocks!',
            'icon': '📈',
          },
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
            'xp': 10,
          },
          {
            'type': 'multiple_choice',
            'question': 'At what level is RSI considered overbought?',
            'options': ['70', '50', '30', '90'],
            'correct': 0,
            'explanation': 'RSI above 70 indicates overbought conditions - time to sell!',
            'xp': 10,
          },
          {
            'type': 'true_false',
            'question': 'RSI below 30 means the stock is oversold (potential buy).',
            'correct': true,
            'explanation': 'RSI below 30 = oversold = potential buying opportunity!',
            'xp': 10,
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
          {
            'type': 'summary',
            'title': '🎉 You earned +200 XP!',
            'subtitle': 'You\'re now an RSI Rookie 🏅',
            'concepts_learned': [
              'RSI measures momentum (0-100)',
              'Above 70 = Overbought (sell)',
              'Below 30 = Oversold (buy)',
              'Use RSI with other indicators'
            ],
            'next_lesson': 'Moving Averages',
            'badge_unlocked': 'RSI Rookie',
          },
        ],
      },
      {
        'id': 'pe_ratio',
        'title': 'P/E Ratio: Value Detective',
        'description': 'Learn to spot undervalued stocks',
        'duration': 6,
        'difficulty': 'Intermediate',
        'xp_reward': 250,
        'badge': 'Value Hunter',
        'badge_emoji': '🔍',
        'category': 'Analysis',
        'steps': [
          {
            'type': 'intro',
            'content': 'Ready to become a value detective?',
            'subtitle': 'Learn how P/E ratio reveals stock value!',
            'icon': '🔍',
          },
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
          {
            'type': 'summary',
            'title': '🎉 You earned +250 XP!',
            'subtitle': 'You\'re now a Value Hunter 🔍',
            'concepts_learned': [
              'P/E = Price ÷ Earnings',
              'Lower P/E = Better value',
              'P/E 15 = Fair value',
              'Compare P/E within same industry'
            ],
            'next_lesson': 'Moving Averages: Trend Following',
            'badge_unlocked': 'Value Hunter',
          },
        ],
      },
      {
        'id': 'risk_management',
        'title': 'Risk Management: Protect Your Money',
        'description': 'Learn the 1% rule and stop losses',
        'duration': 7,
        'difficulty': 'Intermediate',
        'xp_reward': 300,
        'badge': 'Risk Manager',
        'badge_emoji': '🛡️',
        'category': 'Trading',
        'steps': [
          {
            'type': 'intro',
            'content': 'Ready to protect your money?',
            'subtitle': 'Learn the golden rules of risk management!',
            'icon': '🛡️',
          },
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
            'question': 'You have \$10,000. What\'s your max risk per trade?',
            'options': ['\$100', '\$1,000', '\$10', '\$50'],
            'correct': 0,
            'explanation': '1% of \$10,000 = \$100 maximum risk per trade!',
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
          {
            'type': 'summary',
            'title': '🎉 You earned +300 XP!',
            'subtitle': 'You\'re now a Risk Manager 🛡️',
            'concepts_learned': [
              'Never risk more than 1% per trade',
              'Always use stop losses',
              'Calculate risk before trading',
              'Protect your capital first'
            ],
            'next_lesson': 'Position Sizing Strategy',
            'badge_unlocked': 'Risk Manager',
          },
        ],
      },
      {
        'id': 'support_resistance',
        'title': 'Support & Resistance',
        'description': 'Learn to spot key price levels',
        'duration': 6,
        'difficulty': 'Intermediate',
        'xp_reward': 275,
        'badge': 'Level Master',
        'badge_emoji': '📊',
        'category': 'Analysis',
        'steps': [
          {
            'type': 'intro',
            'content': 'Ready to read price levels?',
            'subtitle': 'Learn support and resistance like a pro!',
            'icon': '📊',
          },
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
          {
            'type': 'summary',
            'title': '🎉 You earned +275 XP!',
            'subtitle': 'You\'re now a Level Master 📊',
            'concepts_learned': [
              'Support = Floor (prices bounce up)',
              'Resistance = Ceiling (prices bounce down)',
              'Buy at support, sell at resistance',
              'Levels get stronger with more touches'
            ],
            'next_lesson': 'Moving Averages',
            'badge_unlocked': 'Level Master',
          },
        ],
      },
      {
        'id': 'moving_averages',
        'title': 'Moving Averages',
        'description': 'Learn to spot trends with moving averages',
        'duration': 8,
        'difficulty': 'Intermediate',
        'xp_reward': 325,
        'badge': 'Trend Tracker',
        'badge_emoji': '📈',
        'category': 'Analysis',
        'steps': [
          {
            'type': 'intro',
            'content': 'Ready to track trends?',
            'subtitle': 'Learn how moving averages reveal market direction!',
            'icon': '📈',
          },
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
            'xp': 20,
          },
          {
            'type': 'multiple_choice',
            'question': 'Apple price: \$175, 50-day MA: \$170, 200-day MA: \$165. What\'s the trend?',
            'options': [
              'Strong uptrend (price above both MAs)',
              'Downtrend',
              'Sideways',
              'No trend'
            ],
            'correct': 0,
            'explanation': 'Price above both MAs = strong uptrend!',
            'xp': 25,
          },
          {
            'type': 'summary',
            'title': '🎉 You earned +325 XP!',
            'subtitle': 'You\'re now a Trend Tracker 📈',
            'concepts_learned': [
              'MA smooths price data',
              'Price above MA = uptrend',
              'Golden cross = strong buy signal',
              'Use multiple timeframes'
            ],
            'next_lesson': 'Support & Resistance',
            'badge_unlocked': 'Trend Tracker',
          },
        ],
      },
      {
        'id': 'trading_psychology',
        'title': 'Trading Psychology',
        'description': 'Master fear and greed in trading',
        'duration': 9,
        'difficulty': 'Advanced',
        'xp_reward': 400,
        'badge': 'Mind Master',
        'badge_emoji': '🧠',
        'category': 'Advanced',
        'steps': [
          {
            'type': 'intro',
            'content': 'Ready to master your mind?',
            'subtitle': 'Learn to control fear and greed in trading!',
            'icon': '🧠',
          },
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
          {
            'type': 'summary',
            'title': '🎉 You earned +400 XP!',
            'subtitle': 'You\'re now a Mind Master 🧠',
            'concepts_learned': [
              'Fear and greed drive markets',
              'Stick to your trading plan',
              'Avoid FOMO and revenge trading',
              'Patience is your superpower'
            ],
            'next_lesson': 'Day Trading Basics',
            'badge_unlocked': 'Mind Master',
          },
        ],
      },
      {
        'id': 'market_orders',
        'title': 'Market vs Limit Orders',
        'description': 'Learn when to use market orders vs limit orders',
        'duration': 6,
        'difficulty': 'Intermediate',
        'xp_reward': 300,
        'badge': 'Order Master',
        'badge_emoji': '📋',
        'category': 'Trading',
        'steps': [
          {
            'type': 'intro',
            'content': 'Ready to master order types?',
            'subtitle': 'Learn the difference between market and limit orders!',
            'icon': '📋',
          },
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
            'xp': 25,
          },
          {
            'type': 'summary',
            'title': '🎉 You earned +300 XP!',
            'subtitle': 'You\'re now an Order Master 📋',
            'concepts_learned': [
              'Market order = immediate execution',
              'Limit order = specific price',
              'Use market for speed',
              'Use limit for price control'
            ],
            'next_lesson': 'ETFs vs Mutual Funds',
            'badge_unlocked': 'Order Master',
          },
        ],
      },
      {
        'id': 'etfs_mutual_funds',
        'title': 'ETFs vs Mutual Funds',
        'description': 'Understand the difference between ETFs and mutual funds',
        'duration': 7,
        'difficulty': 'Intermediate',
        'xp_reward': 300,
        'badge': 'Fund Expert',
        'badge_emoji': '📊',
        'category': 'Basics',
        'steps': [
          {
            'type': 'intro',
            'content': 'Ready to learn about funds?',
            'subtitle': 'ETFs and mutual funds are powerful investment tools!',
            'icon': '📊',
          },
          {
            'type': 'multiple_choice',
            'question': 'What does ETF stand for?',
            'options': [
              'Exchange-Traded Fund',
              'Electronic Trading Fund',
              'Enhanced Trading Fund',
              'Easy Trading Fund'
            ],
            'correct': 0,
            'explanation': 'ETFs are funds that trade on exchanges like stocks!',
            'xp': 15,
          },
          {
            'type': 'multiple_choice',
            'question': 'What\'s the main advantage of ETFs?',
            'options': [
              'Lower fees and trade like stocks',
              'Higher fees but more diversified',
              'Only available to institutions',
              'Guaranteed returns'
            ],
            'correct': 0,
            'explanation': 'ETFs have low fees and you can trade them all day like stocks!',
            'xp': 15,
          },
          {
            'type': 'true_false',
            'question': 'ETFs trade throughout the day like stocks, while mutual funds only trade once per day.',
            'correct': true,
            'explanation': 'Yes! ETFs trade like stocks all day, mutual funds trade once at end of day.',
            'xp': 15,
          },
          {
            'type': 'multiple_choice',
            'question': 'Which is better for beginners: ETFs or mutual funds?',
            'options': [
              'ETFs (lower fees, more flexible)',
              'Mutual funds (easier to understand)',
              'Both are equal',
              'Neither is good'
            ],
            'correct': 0,
            'explanation': 'ETFs are great for beginners - low fees and easy to trade!',
            'xp': 20,
          },
          {
            'type': 'summary',
            'title': '🎉 You earned +300 XP!',
            'subtitle': 'You\'re now a Fund Expert 📊',
            'concepts_learned': [
              'ETFs trade like stocks',
              'Lower fees than mutual funds',
              'Both offer diversification',
              'ETFs = more flexible'
            ],
            'next_lesson': 'Technical Indicators',
            'badge_unlocked': 'Fund Expert',
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
        'steps': [
          {
            'type': 'intro',
            'content': 'Ready to read charts?',
            'subtitle': 'Master the language of candlesticks!',
            'icon': '🕯️',
          },
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
          {
            'type': 'summary',
            'title': '🎉 You earned +220 XP!',
            'subtitle': 'You\'re now a Chart Reader 🕯️',
            'concepts_learned': [
              'Green = price up',
              'Red = price down',
              'Charts show trends',
              'Practice reading charts'
            ],
            'next_lesson': 'P/E Ratio: Value Detective',
            'badge_unlocked': 'Chart Reader',
          },
        ],
      },
      {
        'id': 'portfolio_rebalancing',
        'title': 'Portfolio Rebalancing',
        'description': 'Learn when and how to rebalance your portfolio',
        'duration': 7,
        'difficulty': 'Intermediate',
        'xp_reward': 320,
        'badge': 'Portfolio Manager',
        'badge_emoji': '⚖️',
        'category': 'Trading',
        'steps': [
          {
            'type': 'intro',
            'content': 'Ready to manage your portfolio?',
            'subtitle': 'Keep your portfolio balanced for success!',
            'icon': '⚖️',
          },
          {
            'type': 'multiple_choice',
            'question': 'What is portfolio rebalancing?',
            'options': [
              'Adjusting your holdings to match your target allocation',
              'Buying more of everything',
              'Selling everything',
              'Only buying new stocks'
            ],
            'correct': 0,
            'explanation': 'Rebalancing keeps your portfolio aligned with your goals!',
            'xp': 15,
          },
          {
            'type': 'multiple_choice',
            'question': 'How often should you rebalance?',
            'options': [
              'Quarterly or yearly',
              'Every day',
              'Once every 5 years',
              'Never'
            ],
            'correct': 0,
            'explanation': 'Rebalance quarterly or yearly to maintain your target allocation!',
            'xp': 15,
          },
          {
            'type': 'true_false',
            'question': 'Rebalancing means selling winners and buying losers to maintain balance.',
            'correct': true,
            'explanation': 'Yes! Rebalancing involves selling what\'s done well and buying what hasn\'t to stay balanced.',
            'xp': 15,
          },
          {
            'type': 'multiple_choice',
            'question': 'Your target is 50% stocks, 50% bonds. Stocks grow to 70%. You should:',
            'options': [
              'Sell some stocks, buy bonds to rebalance',
              'Buy more stocks',
              'Sell all bonds',
              'Do nothing'
            ],
            'correct': 0,
            'explanation': 'Rebalance by selling stocks (winners) and buying bonds to return to 50/50!',
            'xp': 20,
          },
          {
            'type': 'summary',
            'title': '🎉 You earned +320 XP!',
            'subtitle': 'You\'re now a Portfolio Manager ⚖️',
            'concepts_learned': [
              'Rebalance quarterly or yearly',
              'Maintain target allocation',
              'Sell winners, buy losers',
              'Keep risk in check'
            ],
            'next_lesson': 'Risk/Reward Ratios',
            'badge_unlocked': 'Portfolio Manager',
          },
        ],
      },
      {
        'id': 'risk_reward_ratios',
        'title': 'Risk/Reward Ratios',
        'description': 'Learn to calculate risk vs reward before trading',
        'duration': 6,
        'difficulty': 'Intermediate',
        'xp_reward': 310,
        'badge': 'Risk Calculator',
        'badge_emoji': '🧮',
        'category': 'Trading',
        'steps': [
          {
            'type': 'intro',
            'content': 'Ready to calculate risk/reward?',
            'subtitle': 'Learn the 2:1 rule for profitable trading!',
            'icon': '🧮',
          },
          {
            'type': 'multiple_choice',
            'question': 'What is a good risk/reward ratio?',
            'options': ['1:1', '2:1', '1:2', 'Any ratio'],
            'correct': 1,
            'explanation': '2:1 means you risk \$1 to make \$2 - profitable long term!',
            'xp': 15,
          },
          {
            'type': 'multiple_choice',
            'question': 'You risk \$10. Your profit target is \$30. What\'s your ratio?',
            'options': ['3:1 (risk \$10, reward \$30)', '2:1', '1:3', '30:10'],
            'correct': 0,
            'explanation': 'Risk \$10, reward \$30 = 3:1 ratio! Excellent!',
            'xp': 15,
          },
          {
            'type': 'true_false',
            'question': 'A higher risk/reward ratio (like 3:1) is better than a lower one (like 1:1).',
            'correct': true,
            'explanation': 'Yes! Higher ratios mean more profit per dollar risked!',
            'xp': 15,
          },
          {
            'type': 'multiple_choice',
            'question': 'You buy at \$100, stop loss at \$95, profit target at \$110. Your ratio is:',
            'options': [
              '2:1 (risk \$5, reward \$10)',
              '1:1',
              '1:2',
              '10:1'
            ],
            'correct': 0,
            'explanation': 'Risk \$5 (100-95), reward \$10 (110-100) = 2:1 ratio! Perfect!',
            'xp': 20,
          },
          {
            'type': 'summary',
            'title': '🎉 You earned +310 XP!',
            'subtitle': 'You\'re now a Risk Calculator 🧮',
            'concepts_learned': [
              'Always aim for 2:1 or better',
              'Risk less, reward more',
              'Calculate before trading',
              'Higher ratio = better trade'
            ],
            'next_lesson': 'Position Sizing',
            'badge_unlocked': 'Risk Calculator',
          },
        ],
      },
      {
        'id': 'position_sizing',
        'title': 'Position Sizing Strategy',
        'description': 'Learn how much to buy or sell',
        'duration': 6,
        'difficulty': 'Intermediate',
        'xp_reward': 310,
        'badge': 'Size Master',
        'badge_emoji': '📏',
        'category': 'Trading',
        'steps': [
          {
            'type': 'intro',
            'content': 'Ready to size positions?',
            'subtitle': 'Learn how much to risk per trade!',
            'icon': '📏',
          },
          {
            'type': 'multiple_choice',
            'question': 'If you have \$10,000 and risk 2%, how much can you risk?',
            'options': ['\$200', '\$100', '\$500', '\$1000'],
            'correct': 0,
            'explanation': '2% of \$10,000 = \$200 maximum risk!',
            'xp': 15,
          },
          {
            'type': 'multiple_choice',
            'question': 'Stock costs \$50. You can risk \$100. Stop loss at \$45. How many shares?',
            'options': ['20 shares (\$5 risk per share)', '10 shares', '5 shares', '2 shares'],
            'correct': 0,
            'explanation': '\$5 risk per share × 20 shares = \$100 total risk!',
            'xp': 15,
          },
          {
            'type': 'true_false',
            'question': 'Position sizing helps you control how much you risk per trade.',
            'correct': true,
            'explanation': 'Exactly! Position sizing determines how many shares to buy based on your risk limit.',
            'xp': 15,
          },
          {
            'type': 'multiple_choice',
            'question': 'Account: \$20,000. Risk 1%. Stock: \$100. Stop: \$95. Position size?',
            'options': [
              '40 shares (risk \$200, \$5 per share)',
              '20 shares',
              '100 shares',
              '4 shares'
            ],
            'correct': 0,
            'explanation': 'Risk \$200 (1%), \$5 per share → 40 shares!',
            'xp': 20,
          },
          {
            'type': 'summary',
            'title': '🎉 You earned +310 XP!',
            'subtitle': 'You\'re now a Size Master 📏',
            'concepts_learned': [
              'Risk 1-2% per trade',
              'Calculate position size',
              'Never risk too much',
              'Protect your capital'
            ],
            'next_lesson': 'MACD Indicator',
            'badge_unlocked': 'Size Master',
          },
        ],
      },
      {
        'id': 'macd_indicator',
        'title': 'MACD: Trend & Momentum',
        'description': 'Learn to use MACD for trading signals',
        'duration': 7,
        'difficulty': 'Intermediate',
        'xp_reward': 340,
        'badge': 'MACD Master',
        'badge_emoji': '📊',
        'category': 'Analysis',
        'steps': [
          {
            'type': 'intro',
            'content': 'Ready to learn MACD?',
            'subtitle': 'Master Moving Average Convergence Divergence!',
            'icon': '📊',
          },
          {
            'type': 'multiple_choice',
            'question': 'What does MACD stand for?',
            'options': [
              'Moving Average Convergence Divergence',
              'Market Analysis Chart Data',
              'Maximum Average Chart Display',
              'Market Average Calculation Data'
            ],
            'correct': 0,
            'explanation': 'MACD shows the relationship between two moving averages!',
            'xp': 15,
          },
          {
            'type': 'multiple_choice',
            'question': 'What is a bullish MACD crossover?',
            'options': [
              'MACD line crosses above signal line',
              'MACD line crosses below signal line',
              'Both lines go up',
              'Both lines go down'
            ],
            'correct': 0,
            'explanation': 'MACD crossing above signal = buy signal!',
            'xp': 20,
          },
          {
            'type': 'true_false',
            'question': 'A bearish MACD crossover (MACD below signal) is a sell signal.',
            'correct': true,
            'explanation': 'Yes! MACD crossing below signal = bearish = sell signal!',
            'xp': 15,
          },
          {
            'type': 'multiple_choice',
            'question': 'MACD crosses above signal line. Price is rising. What should you do?',
            'options': [
              'Buy (bullish crossover = buy signal)',
              'Sell',
              'Wait',
              'Ignore it'
            ],
            'correct': 0,
            'explanation': 'MACD bullish crossover = strong buy signal!',
            'xp': 25,
          },
          {
            'type': 'summary',
            'title': '🎉 You earned +340 XP!',
            'subtitle': 'You\'re now a MACD Master 📊',
            'concepts_learned': [
              'MACD measures momentum',
              'Bullish crossover = buy',
              'Bearish crossover = sell',
              'Use with price action'
            ],
            'next_lesson': 'Bollinger Bands',
            'badge_unlocked': 'MACD Master',
          },
        ],
      },
      {
        'id': 'bollinger_bands',
        'title': 'Bollinger Bands',
        'description': 'Learn to spot volatility and price extremes',
        'duration': 6,
        'difficulty': 'Intermediate',
        'xp_reward': 330,
        'badge': 'Band Master',
        'badge_emoji': '📈',
        'category': 'Analysis',
        'steps': [
          {
            'type': 'intro',
            'content': 'Ready to read Bollinger Bands?',
            'subtitle': 'Learn to spot volatility and extremes!',
            'icon': '📈',
          },
          {
            'type': 'multiple_choice',
            'question': 'What do Bollinger Bands show?',
            'options': [
              'Volatility and price extremes',
              'Volume only',
              'Support levels only',
              'Profit margins'
            ],
            'correct': 0,
            'explanation': 'Bands widen when volatile, narrow when calm!',
            'xp': 15,
          },
          {
            'type': 'multiple_choice',
            'question': 'Price touches the lower band. What does this mean?',
            'options': [
              'Potentially oversold - consider buying',
              'Definitely time to sell',
              'Price will keep falling',
              'No signal'
            ],
            'correct': 0,
            'explanation': 'Lower band = oversold, potential bounce up!',
            'xp': 20,
          },
          {
            'type': 'true_false',
            'question': 'When Bollinger Bands widen, it means volatility is increasing.',
            'correct': true,
            'explanation': 'Yes! Wider bands = more volatility, narrower bands = less volatility.',
            'xp': 15,
          },
          {
            'type': 'multiple_choice',
            'question': 'Price touches the upper Bollinger Band. What should you consider?',
            'options': [
              'Potentially overbought - consider selling',
              'Definitely time to buy',
              'Price will keep rising',
              'No signal'
            ],
            'correct': 0,
            'explanation': 'Upper band = overbought, potential sell opportunity!',
            'xp': 25,
          },
          {
            'type': 'summary',
            'title': '🎉 You earned +330 XP!',
            'subtitle': 'You\'re now a Band Master 📈',
            'concepts_learned': [
              'Bands show volatility',
              'Lower band = oversold',
              'Upper band = overbought',
              'Use with other indicators'
            ],
            'next_lesson': 'Options Basics',
            'badge_unlocked': 'Band Master',
          },
        ],
      },
      {
        'id': 'options_basics',
        'title': 'Options: Calls & Puts',
        'description': 'Learn the basics of stock options',
        'duration': 8,
        'difficulty': 'Advanced',
        'xp_reward': 400,
        'badge': 'Options Trader',
        'badge_emoji': '📜',
        'category': 'Advanced',
        'steps': [
          {
            'type': 'intro',
            'content': 'Ready to learn options?',
            'subtitle': 'Understand calls, puts, and leverage!',
            'icon': '📜',
          },
          {
            'type': 'multiple_choice',
            'question': 'What is a call option?',
            'options': [
              'Right to buy stock at a set price',
              'Right to sell stock at a set price',
              'Guaranteed profit',
              'A type of stock'
            ],
            'correct': 0,
            'explanation': 'Call = right to BUY, Put = right to SELL!',
            'xp': 20,
          },
          {
            'type': 'multiple_choice',
            'question': 'What is a put option?',
            'options': [
              'Right to sell stock at a set price',
              'Right to buy stock at a set price',
              'Guaranteed profit',
              'A type of stock'
            ],
            'correct': 0,
            'explanation': 'Put = right to SELL at strike price!',
            'xp': 20,
          },
          {
            'type': 'true_false',
            'question': 'Options have expiration dates and expire worthless if not used.',
            'correct': true,
            'explanation': 'Yes! Options expire - use them or lose them!',
            'xp': 20,
          },
          {
            'type': 'multiple_choice',
            'question': 'You buy a call option. This gives you:',
            'options': [
              'Right to buy stock (but not obligation)',
              'Obligation to buy stock',
              'Guaranteed profit',
              'Ownership of stock'
            ],
            'correct': 0,
            'explanation': 'Call option = RIGHT (not obligation) to buy at strike price!',
            'xp': 25,
          },
          {
            'type': 'summary',
            'title': '🎉 You earned +400 XP!',
            'subtitle': 'You\'re now an Options Trader 📜',
            'concepts_learned': [
              'Call = right to buy',
              'Put = right to sell',
              'Options expire',
              'Higher risk, higher reward'
            ],
            'next_lesson': 'Sector Investing',
            'badge_unlocked': 'Options Trader',
          },
        ],
      },
      {
        'id': 'sector_investing',
        'title': 'Sector Investing',
        'description': 'Learn to invest by industry sectors',
        'duration': 6,
        'difficulty': 'Intermediate',
        'xp_reward': 310,
        'badge': 'Sector Expert',
        'badge_emoji': '🏭',
        'category': 'Analysis',
        'steps': [
          {
            'type': 'intro',
            'content': 'Ready to learn sectors?',
            'subtitle': 'Understand how industries move together!',
            'icon': '🏭',
          },
          {
            'type': 'multiple_choice',
            'question': 'What is a sector?',
            'options': [
              'A group of related industries',
              'A single stock',
              'A type of order',
              'A chart pattern'
            ],
            'correct': 0,
            'explanation': 'Tech, healthcare, finance - these are sectors!',
            'xp': 15,
          },
          {
            'type': 'multiple_choice',
            'question': 'Why diversify across sectors?',
            'options': [
              'Reduce risk - sectors move differently',
              'Guarantee profits',
              'Make trading easier',
              'Avoid taxes'
            ],
            'correct': 0,
            'explanation': 'Diversification protects you from sector crashes!',
            'xp': 15,
          },
          {
            'type': 'true_false',
            'question': 'Stocks in the same sector often move together.',
            'correct': true,
            'explanation': 'Yes! Sector stocks move together because they face similar conditions.',
            'xp': 15,
          },
          {
            'type': 'multiple_choice',
            'question': 'Which portfolio is better diversified?',
            'options': [
              '5 tech stocks, 3 healthcare, 2 finance (multiple sectors)',
              '10 tech stocks only',
              '10 different companies, all tech',
              '5 stocks all same company'
            ],
            'correct': 0,
            'explanation': 'Diversifying across multiple sectors reduces risk!',
            'xp': 20,
          },
          {
            'type': 'summary',
            'title': '🎉 You earned +310 XP!',
            'subtitle': 'You\'re now a Sector Expert 🏭',
            'concepts_learned': [
              'Sectors = related industries',
              'Diversify across sectors',
              'Tech, healthcare, finance',
              'Sectors rotate in cycles'
            ],
            'next_lesson': 'Financial Statements',
            'badge_unlocked': 'Sector Expert',
          },
        ],
      },
      {
        'id': 'financial_statements',
        'title': 'Reading Financial Statements',
        'description': 'Learn to read company earnings reports',
        'duration': 9,
        'difficulty': 'Advanced',
        'xp_reward': 400,
        'badge': 'Statement Reader',
        'badge_emoji': '📄',
        'category': 'Advanced',
        'steps': [
          {
            'type': 'intro',
            'content': 'Ready to read financials?',
            'subtitle': 'Understand company financial statements!',
            'icon': '📄',
          },
          {
            'type': 'multiple_choice',
            'question': 'What shows a company\'s revenue and expenses?',
            'options': [
              'Income Statement',
              'Balance Sheet',
              'Cash Flow Statement',
              'All of the above'
            ],
            'correct': 0,
            'explanation': 'Income statement shows profit/loss!',
            'xp': 20,
          },
          {
            'type': 'multiple_choice',
            'question': 'What shows what a company owns and owes?',
            'options': [
              'Balance Sheet',
              'Income Statement',
              'Cash Flow',
              'Annual Report'
            ],
            'correct': 0,
            'explanation': 'Balance sheet = assets minus liabilities!',
            'xp': 20,
          },
          {
            'type': 'true_false',
            'question': 'The income statement shows if a company is profitable.',
            'correct': true,
            'explanation': 'Yes! Income statement shows revenue minus expenses = profit or loss.',
            'xp': 20,
          },
          {
            'type': 'multiple_choice',
            'question': 'You want to know if a company can pay its bills. Check:',
            'options': [
              'Cash Flow Statement',
              'Income Statement only',
              'Balance Sheet only',
              'Stock price'
            ],
            'correct': 0,
            'explanation': 'Cash flow shows if company has cash to pay bills!',
            'xp': 25,
          },
          {
            'type': 'summary',
            'title': '🎉 You earned +400 XP!',
            'subtitle': 'You\'re now a Statement Reader 📄',
            'concepts_learned': [
              'Income statement = revenue/expenses',
              'Balance sheet = assets/liabilities',
              'Cash flow = money movement',
              'Read before investing'
            ],
            'next_lesson': 'Market Sentiment',
            'badge_unlocked': 'Statement Reader',
          },
        ],
      },
      {
        'id': 'market_sentiment',
        'title': 'Market Sentiment',
        'description': 'Understand how emotions move markets',
        'duration': 7,
        'difficulty': 'Intermediate',
        'xp_reward': 340,
        'badge': 'Sentiment Tracker',
        'badge_emoji': '😊',
        'category': 'Analysis',
        'steps': [
          {
            'type': 'intro',
            'content': 'Ready to track sentiment?',
            'subtitle': 'Learn how emotions drive markets!',
            'icon': '😊',
          },
          {
            'type': 'multiple_choice',
            'question': 'What is market sentiment?',
            'options': [
              'Overall mood of investors',
              'Stock price',
              'Company earnings',
              'Trading volume'
            ],
            'correct': 0,
            'explanation': 'Sentiment = how investors FEEL about the market!',
            'xp': 15,
          },
          {
            'type': 'multiple_choice',
            'question': 'When everyone is extremely bullish (greedy), what often happens?',
            'options': [
              'Market might be ready to fall',
              'Market will keep rising forever',
              'Nothing changes',
              'Only good things happen'
            ],
            'correct': 0,
            'explanation': 'Extreme greed = potential top. Be cautious!',
            'xp': 20,
          },
          {
            'type': 'true_false',
            'question': 'When everyone is fearful, it can be a buying opportunity.',
            'correct': true,
            'explanation': 'Yes! When fear is extreme, prices may be low - buying opportunity!',
            'xp': 15,
          },
          {
            'type': 'multiple_choice',
            'question': 'The market is in extreme fear. You should:',
            'options': [
              'Consider buying (fear = potential bottom)',
              'Definitely sell everything',
              'Do nothing',
              'Buy more of everything'
            ],
            'correct': 0,
            'explanation': 'Extreme fear often marks bottoms - time to buy!',
            'xp': 25,
          },
          {
            'type': 'summary',
            'title': '🎉 You earned +340 XP!',
            'subtitle': 'You\'re now a Sentiment Tracker 😊',
            'concepts_learned': [
              'Sentiment = market mood',
              'Extreme greed = be careful',
              'Extreme fear = opportunity',
              'Be contrarian at extremes'
            ],
            'next_lesson': 'Tax Implications',
            'badge_unlocked': 'Sentiment Tracker',
          },
        ],
      },
      {
        'id': 'tax_implications',
        'title': 'Trading & Taxes',
        'description': 'Learn tax basics for traders',
        'duration': 6,
        'difficulty': 'Intermediate',
        'xp_reward': 320,
        'badge': 'Tax Smart',
        'badge_emoji': '💼',
        'category': 'Advanced',
        'steps': [
          {
            'type': 'intro',
            'content': 'Ready to learn about taxes?',
            'subtitle': 'Understand how trading affects your taxes!',
            'icon': '💼',
          },
          {
            'type': 'multiple_choice',
            'question': 'Short-term capital gains (held <1 year) are taxed at...',
            'options': [
              'Your regular income tax rate',
              '0%',
              '15% flat rate',
              '30% flat rate'
            ],
            'correct': 0,
            'explanation': 'Short-term gains taxed as ordinary income!',
            'xp': 15,
          },
          {
            'type': 'multiple_choice',
            'question': 'What is a tax loss harvest?',
            'options': [
              'Selling losers to offset gains',
              'Avoiding all taxes',
              'Only trading winners',
              'Hiding losses'
            ],
            'correct': 0,
            'explanation': 'Use losses to reduce taxable gains!',
            'xp': 15,
          },
          {
            'type': 'true_false',
            'question': 'Long-term capital gains (held >1 year) are taxed at a lower rate than short-term.',
            'correct': true,
            'explanation': 'Yes! Long-term gains get favorable tax rates - hold over 1 year!',
            'xp': 15,
          },
          {
            'type': 'multiple_choice',
            'question': 'You made \$5,000 profit, \$2,000 loss this year. Taxable gain is:',
            'options': [
              '\$3,000 (offset losses against gains)',
              '\$5,000',
              '\$7,000',
              '\$0'
            ],
            'correct': 0,
            'explanation': 'Losses offset gains! \$5,000 - \$2,000 = \$3,000 taxable.',
            'xp': 20,
          },
          {
            'type': 'summary',
            'title': '🎉 You earned +320 XP!',
            'subtitle': 'You\'re now Tax Smart 💼',
            'concepts_learned': [
              'Short-term = income tax rate',
              'Long-term = lower rate',
              'Tax loss harvesting',
              'Keep records of all trades'
            ],
            'next_lesson': 'Backtesting',
            'badge_unlocked': 'Tax Smart',
          },
        ],
      },
      {
        'id': 'backtesting',
        'title': 'Backtesting Strategies',
        'description': 'Learn to test trading strategies',
        'duration': 7,
        'difficulty': 'Advanced',
        'xp_reward': 360,
        'badge': 'Strategy Tester',
        'badge_emoji': '🧪',
        'category': 'Advanced',
        'steps': [
          {
            'type': 'intro',
            'content': 'Ready to test strategies?',
            'subtitle': 'Learn to backtest before risking money!',
            'icon': '🧪',
          },
          {
            'type': 'multiple_choice',
            'question': 'What is backtesting?',
            'options': [
              'Testing a strategy on historical data',
              'Testing on future data',
              'Guessing what will work',
              'Only using paper trading'
            ],
            'correct': 0,
            'explanation': 'Backtest = see how strategy worked in the past!',
            'xp': 15,
          },
          {
            'type': 'multiple_choice',
            'question': 'Why is backtesting important?',
            'options': [
              'Test strategy without risking money',
              'Guarantee future profits',
              'Avoid all losses',
              'Make trading automatic'
            ],
            'correct': 0,
            'explanation': 'Test on historical data before using real money!',
            'xp': 15,
          },
          {
            'type': 'true_false',
            'question': 'Past performance in backtesting does not guarantee future results.',
            'correct': true,
            'explanation': 'Yes! Markets change - backtest helps but doesn\'t guarantee future success.',
            'xp': 15,
          },
          {
            'type': 'multiple_choice',
            'question': 'Before using a strategy with real money, you should:',
            'options': [
              'Backtest and paper trade first',
              'Use it immediately',
              'Only backtest',
              'Only paper trade'
            ],
            'correct': 0,
            'explanation': 'Backtest on historical data, then paper trade before risking real money!',
            'xp': 20,
          },
          {
            'type': 'summary',
            'title': '🎉 You earned +360 XP!',
            'subtitle': 'You\'re now a Strategy Tester 🧪',
            'concepts_learned': [
              'Backtest on historical data',
              'Test before risking money',
              'Past performance ≠ future',
              'Use paper trading too'
            ],
            'next_lesson': 'Market Cycles',
            'badge_unlocked': 'Strategy Tester',
          },
        ],
      },
      {
        'id': 'market_cycles',
        'title': 'Understanding Market Cycles',
        'description': 'Learn how markets move in cycles',
        'duration': 8,
        'difficulty': 'Advanced',
        'xp_reward': 380,
        'badge': 'Cycle Master',
        'badge_emoji': '🔄',
        'category': 'Advanced',
        'steps': [
          {
            'type': 'intro',
            'content': 'Ready to understand cycles?',
            'subtitle': 'Markets move in predictable patterns!',
            'icon': '🔄',
          },
          {
            'type': 'multiple_choice',
            'question': 'What are the four market cycle phases?',
            'options': [
              'Bull, Bear, Correction, Recovery',
              'Buy, Sell, Hold, Wait',
              'Up, Down, Left, Right',
              'Hot, Cold, Warm, Cool'
            ],
            'correct': 0,
            'explanation': 'Markets cycle through these phases repeatedly!',
            'xp': 20,
          },
          {
            'type': 'multiple_choice',
            'question': 'Market dropped 20%, now recovering slowly. What phase?',
            'options': [
              'Recovery phase (time to accumulate)',
              'Bull market',
              'Bear market',
              'Correction'
            ],
            'correct': 0,
            'explanation': 'Recovery after drop = time to accumulate!',
            'xp': 20,
          },
          {
            'type': 'true_false',
            'question': 'Bull markets are followed by bear markets in cycles.',
            'correct': true,
            'explanation': 'Yes! Markets cycle through bull and bear phases repeatedly.',
            'xp': 15,
          },
          {
            'type': 'multiple_choice',
            'question': 'Best time to buy stocks is usually during:',
            'options': [
              'Recovery phase (after drop)',
              'Bull market peak',
              'Bear market crash',
              'Never buy'
            ],
            'correct': 0,
            'explanation': 'Recovery phase = stocks are cheaper, good buying opportunity!',
            'xp': 20,
          },
          {
            'type': 'summary',
            'title': '🎉 You earned +380 XP!',
            'subtitle': 'You\'re now a Cycle Master 🔄',
            'concepts_learned': [
              'Markets move in cycles',
              'Bull, Bear, Correction, Recovery',
              'Buy in recovery',
              'Sell in bull markets'
            ],
            'next_lesson': 'Day Trading Basics',
            'badge_unlocked': 'Cycle Master',
          },
        ],
      },
      {
        'id': 'day_trading_basics',
        'title': 'Day Trading Basics',
        'description': 'Learn intraday trading strategies',
        'duration': 9,
        'difficulty': 'Advanced',
        'xp_reward': 400,
        'badge': 'Day Trader',
        'badge_emoji': '⚡',
        'category': 'Advanced',
        'steps': [
          {
            'type': 'intro',
            'content': 'Ready for day trading?',
            'subtitle': 'Learn to trade within a single day!',
            'icon': '⚡',
          },
          {
            'type': 'multiple_choice',
            'question': 'What is day trading?',
            'options': [
              'Buying and selling same day',
              'Trading only on Mondays',
              'Trading for one hour',
              'Buying and holding forever'
            ],
            'correct': 0,
            'explanation': 'Day trading = open and close positions same day!',
            'xp': 15,
          },
          {
            'type': 'multiple_choice',
            'question': 'Why is day trading risky?',
            'options': [
              'Requires quick decisions and can lose fast',
              'It\'s always profitable',
              'No risk at all',
              'Only for professionals'
            ],
            'correct': 0,
            'explanation': 'Fast pace = high risk. Practice first!',
            'xp': 20,
          },
          {
            'type': 'true_false',
            'question': 'You should practice day trading with paper trading before using real money.',
            'correct': true,
            'explanation': 'Absolutely! Practice extensively with paper trading first!',
            'xp': 20,
          },
          {
            'type': 'multiple_choice',
            'question': 'Day trading requires:',
            'options': [
              'Strict rules, discipline, and risk management',
              'No rules, just trade',
              'Always trade on emotions',
              'Only trade winners'
            ],
            'correct': 0,
            'explanation': 'Day trading needs strict rules, discipline, and solid risk management!',
            'xp': 20,
          },
          {
            'type': 'summary',
            'title': '🎉 You earned +400 XP!',
            'subtitle': 'You\'re now a Day Trader ⚡',
            'concepts_learned': [
              'Day trading = same day trades',
              'Very risky - practice first',
              'Need strict rules',
              'Start with paper trading'
            ],
            'next_lesson': 'Swing Trading',
            'badge_unlocked': 'Day Trader',
          },
        ],
      },
      {
        'id': 'swing_trading',
        'title': 'Swing Trading',
        'description': 'Hold positions for days to weeks',
        'duration': 7,
        'difficulty': 'Intermediate',
        'xp_reward': 350,
        'badge': 'Swing Trader',
        'badge_emoji': '🎯',
        'category': 'Trading',
        'steps': [
          {
            'type': 'intro',
            'content': 'Ready to swing trade?',
            'subtitle': 'Hold positions for several days to weeks!',
            'icon': '🎯',
          },
          {
            'type': 'multiple_choice',
            'question': 'What is swing trading?',
            'options': [
              'Holding trades for days to weeks',
              'Trading only on swings',
              'One trade per day',
              'Never selling'
            ],
            'correct': 0,
            'explanation': 'Swing trading = capture short-term price swings!',
            'xp': 15,
          },
          {
            'type': 'true_false',
            'question': 'Swing trading is less stressful than day trading.',
            'correct': true,
            'explanation': 'Yes! Less time pressure = less stress!',
            'xp': 15,
          },
          {
            'type': 'multiple_choice',
            'question': 'Swing trading is good for:',
            'options': [
              'Part-time traders who can\'t watch all day',
              'Only full-time traders',
              'Only beginners',
              'Only professionals'
            ],
            'correct': 0,
            'explanation': 'Swing trading fits part-time traders perfectly!',
            'xp': 15,
          },
          {
            'type': 'multiple_choice',
            'question': 'Swing trading typically uses:',
            'options': [
              'Technical analysis (charts, indicators)',
              'Only fundamental analysis',
              'Guessing',
              'Only news'
            ],
            'correct': 0,
            'explanation': 'Swing trading uses technical analysis to spot price swings!',
            'xp': 20,
          },
          {
            'type': 'summary',
            'title': '🎉 You earned +350 XP!',
            'subtitle': 'You\'re now a Swing Trader 🎯',
            'concepts_learned': [
              'Hold for days to weeks',
              'Less stressful than day trading',
              'Good for part-time traders',
              'Use technical analysis'
            ],
            'next_lesson': 'Dividend Investing',
            'badge_unlocked': 'Swing Trader',
          },
        ],
      },
      {
        'id': 'dividend_investing',
        'title': 'Dividend Investing',
        'description': 'Learn to invest for regular income',
        'duration': 6,
        'difficulty': 'Intermediate',
        'xp_reward': 330,
        'badge': 'Dividend Collector',
        'badge_emoji': '💰',
        'category': 'Trading',
        'steps': [
          {
            'type': 'intro',
            'content': 'Ready for dividends?',
            'subtitle': 'Learn to earn regular income from stocks!',
            'icon': '💰',
          },
          {
            'type': 'multiple_choice',
            'question': 'What is a dividend?',
            'options': [
              'Company pays shareholders cash',
              'Stock price increase',
              'Free stock shares',
              'A type of order'
            ],
            'correct': 0,
            'explanation': 'Dividends = companies pay you money for owning their stock!',
            'xp': 15,
          },
          {
            'type': 'multiple_choice',
            'question': 'What is dividend yield?',
            'options': [
              'Annual dividend ÷ stock price',
              'Total dividends paid',
              'Dividend frequency',
              'Number of dividends'
            ],
            'correct': 0,
            'explanation': 'Yield shows your return from dividends!',
            'xp': 15,
          },
          {
            'type': 'true_false',
            'question': 'Dividend stocks provide regular income payments.',
            'correct': true,
            'explanation': 'Yes! Dividend stocks pay you cash regularly (quarterly usually).',
            'xp': 15,
          },
          {
            'type': 'multiple_choice',
            'question': 'Stock price \$100, annual dividend \$4. Yield is:',
            'options': [
              '4% (4/100 = 0.04)',
              '10%',
              '25%',
              '1%'
            ],
            'correct': 0,
            'explanation': 'Dividend yield = \$4 ÷ \$100 = 4%!',
            'xp': 20,
          },
          {
            'type': 'summary',
            'title': '🎉 You earned +330 XP!',
            'subtitle': 'You\'re now a Dividend Collector 💰',
            'concepts_learned': [
              'Dividends = regular income',
              'Yield = dividend ÷ price',
              'Reinvest for compounding',
              'Look for stable companies'
            ],
            'next_lesson': 'Growth vs Value',
            'badge_unlocked': 'Dividend Collector',
          },
        ],
      },
      {
        'id': 'growth_vs_value',
        'title': 'Growth vs Value Stocks',
        'description': 'Understand two investing styles',
        'duration': 7,
        'difficulty': 'Intermediate',
        'xp_reward': 350,
        'badge': 'Style Master',
        'badge_emoji': '⚖️',
        'category': 'Analysis',
        'steps': [
          {
            'type': 'intro',
            'content': 'Ready to compare styles?',
            'subtitle': 'Growth vs Value - which is better?',
            'icon': '⚖️',
          },
          {
            'type': 'multiple_choice',
            'question': 'What are growth stocks?',
            'options': [
              'Companies growing revenue fast',
              'Cheap companies',
              'Old companies',
              'All stocks'
            ],
            'correct': 0,
            'explanation': 'Growth = fast-growing companies (often expensive)!',
            'xp': 15,
          },
          {
            'type': 'multiple_choice',
            'question': 'What are value stocks?',
            'options': [
              'Cheap relative to earnings/assets',
              'Expensive stocks',
              'Only tech stocks',
              'New companies'
            ],
            'correct': 0,
            'explanation': 'Value = undervalued companies (often cheap)!',
            'xp': 15,
          },
          {
            'type': 'true_false',
            'question': 'Both growth and value stocks can be profitable.',
            'correct': true,
            'explanation': 'Yes! Both styles work - diversify across both for best results!',
            'xp': 15,
          },
          {
            'type': 'multiple_choice',
            'question': 'Tech startup growing 50%/year (expensive) vs Bank trading below book value (cheap). Better to:',
            'options': [
              'Diversify - own both (best of both worlds)',
              'Only growth (too risky alone)',
              'Only value (missing growth)',
              'Avoid both'
            ],
            'correct': 0,
            'explanation': 'Diversify across both styles for balanced portfolio!',
            'xp': 20,
          },
          {
            'type': 'summary',
            'title': '🎉 You earned +350 XP!',
            'subtitle': 'You\'re now a Style Master ⚖️',
            'concepts_learned': [
              'Growth = fast growing',
              'Value = undervalued',
              'Both have pros and cons',
              'Diversify your style'
            ],
            'next_lesson': 'Market Cap Explained',
            'badge_unlocked': 'Style Master',
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
        'steps': [
          {
            'type': 'intro',
            'content': 'Ready to understand market cap?',
            'subtitle': 'Learn how big companies are measured!',
            'icon': '📊',
          },
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
          {
            'type': 'summary',
            'title': '🎉 You earned +180 XP!',
            'subtitle': 'You\'re now a Cap Expert 📊',
            'concepts_learned': [
              'Market cap = price × shares',
              'Large-cap = \$10B+',
              'Mid-cap = \$2-10B',
              'Small-cap = under \$2B'
            ],
            'next_lesson': 'Building Your Portfolio',
            'badge_unlocked': 'Cap Expert',
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
        'steps': [
          {
            'type': 'intro',
            'content': 'Ready to build your portfolio?',
            'subtitle': 'Learn to diversify and manage your investments!',
            'icon': '🏗️',
          },
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
          {
            'type': 'summary',
            'title': '🎉 You earned +200 XP!',
            'subtitle': 'You\'re now a Portfolio Builder 🏗️',
            'concepts_learned': [
              'Diversify across stocks',
              'Spread across sectors',
              'Don\'t put all eggs in one basket',
              '5-10 stocks is good start'
            ],
            'next_lesson': 'Reading Stock Charts',
            'badge_unlocked': 'Portfolio Builder',
          },
        ],
      },
      {
        'id': 'volume_analysis',
        'title': 'Volume Analysis',
        'description': 'Learn to read trading volume',
        'duration': 6,
        'difficulty': 'Intermediate',
        'xp_reward': 320,
        'badge': 'Volume Tracker',
        'badge_emoji': '📊',
        'category': 'Analysis',
        'steps': [
          {
            'type': 'intro',
            'content': 'Ready to read volume?',
            'subtitle': 'Volume confirms price moves!',
            'icon': '📊',
          },
          {
            'type': 'multiple_choice',
            'question': 'What does high volume indicate?',
            'options': [
              'Strong interest and conviction',
              'No one is trading',
              'Price will definitely drop',
              'The stock is boring'
            ],
            'correct': 0,
            'explanation': 'High volume = lots of interest = stronger moves!',
            'xp': 15,
          },
          {
            'type': 'multiple_choice',
            'question': 'Price rises on low volume. What does this mean?',
            'options': [
              'Weak move - might reverse',
              'Very strong move',
              'Price will keep rising',
              'No meaning'
            ],
            'correct': 0,
            'explanation': 'Low volume moves are weak - be cautious!',
            'xp': 15,
          },
          {
            'type': 'true_false',
            'question': 'Volume confirms price movements - high volume makes moves more reliable.',
            'correct': true,
            'explanation': 'Yes! High volume confirms the move is real and has conviction.',
            'xp': 15,
          },
          {
            'type': 'multiple_choice',
            'question': 'Stock breaks above resistance with very high volume. This is:',
            'options': [
              'Strong bullish signal (high volume confirms)',
              'Weak signal (ignore it)',
              'Sell signal',
              'No signal'
            ],
            'correct': 0,
            'explanation': 'High volume breakout = strong bullish signal!',
            'xp': 20,
          },
          {
            'type': 'summary',
            'title': '🎉 You earned +320 XP!',
            'subtitle': 'You\'re now a Volume Tracker 📊',
            'concepts_learned': [
              'High volume = strong moves',
              'Low volume = weak moves',
              'Volume confirms price',
              'Use with price action'
            ],
            'next_lesson': 'Gap Trading',
            'badge_unlocked': 'Volume Tracker',
          },
        ],
      },
      {
        'id': 'gap_trading',
        'title': 'Gap Trading',
        'description': 'Learn to trade price gaps',
        'duration': 7,
        'difficulty': 'Advanced',
        'xp_reward': 380,
        'badge': 'Gap Trader',
        'badge_emoji': '📈',
        'category': 'Advanced',
        'steps': [
          {
            'type': 'intro',
            'content': 'Ready to trade gaps?',
            'subtitle': 'Learn to profit from price gaps!',
            'icon': '📈',
          },
          {
            'type': 'multiple_choice',
            'question': 'What is a gap?',
            'options': [
              'Price jumps over a price level',
              'No trading volume',
              'Stock split',
              'Dividend payment'
            ],
            'correct': 0,
            'explanation': 'Gap = price skips over levels (often from news)!',
            'xp': 15,
          },
          {
            'type': 'multiple_choice',
            'question': 'Gap up on good news. What often happens?',
            'options': [
              'Might fill the gap later',
              'Will keep going up forever',
              'No pattern',
              'Always fills immediately'
            ],
            'correct': 0,
            'explanation': 'Gaps often fill - gap up might come back down!',
            'xp': 20,
          },
          {
            'type': 'true_false',
            'question': 'Price gaps often fill - meaning price returns to fill the gap.',
            'correct': true,
            'explanation': 'Yes! Gaps often fill - gap up usually comes back down to fill.',
            'xp': 15,
          },
          {
            'type': 'multiple_choice',
            'question': 'Stock gaps down from \$100 to \$95. You should:',
            'options': [
              'Watch for gap fill back to \$100 (potential trade)',
              'Definitely buy immediately',
              'Definitely sell immediately',
              'Ignore gaps'
            ],
            'correct': 0,
            'explanation': 'Gap down might fill back up - watch for entry!',
            'xp': 20,
          },
          {
            'type': 'summary',
            'title': '🎉 You earned +380 XP!',
            'subtitle': 'You\'re now a Gap Trader 📈',
            'concepts_learned': [
              'Gaps = price jumps',
              'Gaps often fill',
              'Trade gap fills',
              'Use stop losses'
            ],
            'next_lesson': 'Breakout Trading',
            'badge_unlocked': 'Gap Trader',
          },
        ],
      },
      {
        'id': 'breakout_trading',
        'title': 'Breakout Trading',
        'description': 'Learn to trade breakouts',
        'duration': 7,
        'difficulty': 'Intermediate',
        'xp_reward': 360,
        'badge': 'Breakout Trader',
        'badge_emoji': '🚀',
        'category': 'Trading',
        'steps': [
          {
            'type': 'intro',
            'content': 'Ready to catch breakouts?',
            'subtitle': 'Learn to trade price breakouts!',
            'icon': '🚀',
          },
          {
            'type': 'multiple_choice',
            'question': 'What is a breakout?',
            'options': [
              'Price breaks above resistance',
              'Price breaks below support',
              'Stock splits',
              'Company announces earnings'
            ],
            'correct': 0,
            'explanation': 'Breakout = price breaks through key level!',
            'xp': 15,
          },
          {
            'type': 'multiple_choice',
            'question': 'What confirms a true breakout?',
            'options': [
              'High volume',
              'Low volume',
              'No volume needed',
              'Only price matters'
            ],
            'correct': 0,
            'explanation': 'High volume confirms the breakout is real!',
            'xp': 15,
          },
          {
            'type': 'true_false',
            'question': 'A breakout above resistance is a bullish signal.',
            'correct': true,
            'explanation': 'Yes! Breaking above resistance = buyers winning = bullish!',
            'xp': 15,
          },
          {
            'type': 'multiple_choice',
            'question': 'Stock breaks above \$150 resistance on high volume. What should you do?',
            'options': [
              'Buy on breakout (strong bullish signal)',
              'Sell everything',
              'Wait and see',
              'Ignore it'
            ],
            'correct': 0,
            'explanation': 'High volume breakout = strong buy signal!',
            'xp': 20,
          },
          {
            'type': 'summary',
            'title': '🎉 You earned +360 XP!',
            'subtitle': 'You\'re now a Breakout Trader 🚀',
            'concepts_learned': [
              'Breakouts = price breaks level',
              'High volume confirms',
              'Trade breakouts',
              'Use stop losses'
            ],
            'next_lesson': 'Chart Patterns',
            'badge_unlocked': 'Breakout Trader',
          },
        ],
      },
      {
        'id': 'chart_patterns',
        'title': 'Chart Patterns',
        'description': 'Learn common chart patterns',
        'duration': 8,
        'difficulty': 'Intermediate',
        'xp_reward': 370,
        'badge': 'Pattern Reader',
        'badge_emoji': '📐',
        'category': 'Analysis',
        'steps': [
          {
            'type': 'intro',
            'content': 'Ready to read patterns?',
            'subtitle': 'Learn common chart patterns!',
            'icon': '📐',
          },
          {
            'type': 'multiple_choice',
            'question': 'What is a head and shoulders pattern?',
            'options': [
              'A bearish reversal pattern',
              'A bullish continuation',
              'A type of gap',
              'A volume pattern'
            ],
            'correct': 0,
            'explanation': 'Head & shoulders = bearish signal (price likely to fall)!',
            'xp': 15,
          },
          {
            'type': 'multiple_choice',
            'question': 'What is a triangle pattern?',
            'options': [
              'Price consolidating before breakout',
              'Price going straight up',
              'Price crashing',
              'No pattern at all'
            ],
            'correct': 0,
            'explanation': 'Triangle = consolidation, often followed by breakout!',
            'xp': 15,
          },
          {
            'type': 'true_false',
            'question': 'Chart patterns can help predict future price movements.',
            'correct': true,
            'explanation': 'Yes! Patterns like head & shoulders, triangles help predict moves!',
            'xp': 15,
          },
          {
            'type': 'multiple_choice',
            'question': 'You see a double top pattern. This is:',
            'options': [
              'Bearish reversal signal (price likely to fall)',
              'Bullish continuation',
              'No signal',
              'Always buy signal'
            ],
            'correct': 0,
            'explanation': 'Double top = bearish reversal - price likely to fall!',
            'xp': 20,
          },
          {
            'type': 'summary',
            'title': '🎉 You earned +370 XP!',
            'subtitle': 'You\'re now a Pattern Reader 📐',
            'concepts_learned': [
              'Patterns predict moves',
              'Head & shoulders = bearish',
              'Triangles = consolidation',
              'Double tops = reversal'
            ],
            'next_lesson': 'Earnings Reports',
            'badge_unlocked': 'Pattern Reader',
          },
        ],
      },
      {
        'id': 'earnings_reports',
        'title': 'Earnings Reports',
        'description': 'Learn to trade earnings announcements',
        'duration': 7,
        'difficulty': 'Intermediate',
        'xp_reward': 350,
        'badge': 'Earnings Trader',
        'badge_emoji': '📈',
        'category': 'Advanced',
        'steps': [
          {
            'type': 'intro',
            'content': 'Ready for earnings?',
            'subtitle': 'Learn to trade earnings announcements!',
            'icon': '📈',
          },
          {
            'type': 'multiple_choice',
            'question': 'When companies report earnings, what happens?',
            'options': [
              'Stock price often moves significantly',
              'Nothing changes',
              'Only volume changes',
              'Price always goes up'
            ],
            'correct': 0,
            'explanation': 'Earnings = big price moves (up or down)!',
            'xp': 15,
          },
          {
            'type': 'multiple_choice',
            'question': 'What is "beating expectations"?',
            'options': [
              'Earnings better than analysts predicted',
              'Earnings exactly as predicted',
              'Earnings worse than predicted',
              'No earnings at all'
            ],
            'correct': 0,
            'explanation': 'Beat expectations = usually good for stock price!',
            'xp': 15,
          },
          {
            'type': 'true_false',
            'question': 'When a company misses earnings expectations, the stock price usually falls.',
            'correct': true,
            'explanation': 'Yes! Missing expectations = disappointment = price usually drops.',
            'xp': 15,
          },
          {
            'type': 'multiple_choice',
            'question': 'Apple beats earnings estimates. Stock gaps up 5%. What should you do?',
            'options': [
              'Wait for pullback (gaps often fill)',
              'Buy immediately (might be too late)',
              'Sell everything',
              'Ignore it'
            ],
            'correct': 0,
            'explanation': 'Wait for pullback after earnings gap - don\'t chase!',
            'xp': 20,
          },
          {
            'type': 'summary',
            'title': '🎉 You earned +350 XP!',
            'subtitle': 'You\'re now an Earnings Trader 📈',
            'concepts_learned': [
              'Earnings cause big moves',
              'Beat expectations = usually up',
              'Miss expectations = usually down',
              'Wait for pullback after gap'
            ],
            'next_lesson': 'IPO Basics',
            'badge_unlocked': 'Earnings Trader',
          },
        ],
      },
      {
        'id': 'ipo_basics',
        'title': 'IPO: Initial Public Offerings',
        'description': 'Learn about new stock listings',
        'duration': 6,
        'difficulty': 'Intermediate',
        'xp_reward': 340,
        'badge': 'IPO Expert',
        'badge_emoji': '🎉',
        'category': 'Advanced',
        'steps': [
          {
            'type': 'intro',
            'content': 'Ready to learn about IPOs?',
            'subtitle': 'Understand Initial Public Offerings!',
            'icon': '🎉',
          },
          {
            'type': 'multiple_choice',
            'question': 'What does IPO stand for?',
            'options': [
              'Initial Public Offering',
              'Internal Price Option',
              'Instant Profit Opportunity',
              'Investment Portfolio Option'
            ],
            'correct': 0,
            'explanation': 'IPO = company first sells shares to public!',
            'xp': 15,
          },
          {
            'type': 'multiple_choice',
            'question': 'Why do companies do IPOs?',
            'options': [
              'Raise money for growth',
              'Give away free stock',
              'Lower their value',
              'Make investors rich'
            ],
            'correct': 0,
            'explanation': 'Companies IPO to raise capital!',
            'xp': 15,
          },
          {
            'type': 'true_false',
            'question': 'IPO stocks are often very volatile (prices move a lot) in their first days.',
            'correct': true,
            'explanation': 'Yes! New IPOs are often very volatile - prices swing wildly.',
            'xp': 15,
          },
          {
            'type': 'multiple_choice',
            'question': 'You want to buy an IPO stock. You should:',
            'options': [
              'Research the company thoroughly first',
              'Buy immediately without research',
              'Always avoid IPOs',
              'Buy all IPOs'
            ],
            'correct': 0,
            'explanation': 'Always research IPOs carefully - they can be risky!',
            'xp': 20,
          },
          {
            'type': 'summary',
            'title': '🎉 You earned +340 XP!',
            'subtitle': 'You\'re now an IPO Expert 🎉',
            'concepts_learned': [
              'IPO = first public sale',
              'Companies raise money',
              'Often volatile initially',
              'Research before buying'
            ],
            'next_lesson': 'Stock Splits',
            'badge_unlocked': 'IPO Expert',
          },
        ],
      },
      {
        'id': 'stock_splits',
        'title': 'Stock Splits',
        'description': 'Understand how stock splits work',
        'duration': 5,
        'difficulty': 'Beginner',
        'xp_reward': 260,
        'badge': 'Split Master',
        'badge_emoji': '✂️',
        'category': 'Basics',
        'steps': [
          {
            'type': 'intro',
            'content': 'Ready to understand splits?',
            'subtitle': 'Learn how stock splits work!',
            'icon': '✂️',
          },
          {
            'type': 'multiple_choice',
            'question': 'What is a 2-for-1 stock split?',
            'options': [
              'You get 2 shares for each 1 you own, price halves',
              'Price doubles',
              'You lose half your shares',
              'Nothing changes'
            ],
            'correct': 0,
            'explanation': 'Split = more shares, lower price, same total value!',
            'xp': 10,
          },
          {
            'type': 'multiple_choice',
            'question': 'Why do companies split stocks?',
            'options': [
              'Make shares more affordable',
              'Increase total value',
              'Decrease share price permanently',
              'Punish shareholders'
            ],
            'correct': 0,
            'explanation': 'Lower price = more people can afford to buy!',
            'xp': 10,
          },
          {
            'type': 'true_false',
            'question': 'In a 2-for-1 split, your total investment value stays the same.',
            'correct': true,
            'explanation': 'Yes! You get 2 shares at half price = same total value!',
            'xp': 10,
          },
          {
            'type': 'multiple_choice',
            'question': 'You own 10 shares at \$200 each. 2-for-1 split. After split:',
            'options': [
              '20 shares at \$100 each (same \$2,000 value)',
              '10 shares at \$400',
              '5 shares at \$200',
              '20 shares at \$200'
            ],
            'correct': 0,
            'explanation': '2-for-1 split = 20 shares × \$100 = same \$2,000 total value!',
            'xp': 15,
          },
          {
            'type': 'summary',
            'title': '🎉 You earned +260 XP!',
            'subtitle': 'You\'re now a Split Master ✂️',
            'concepts_learned': [
              'Split = more shares, lower price',
              'Total value stays same',
              'Makes shares affordable',
              'Often bullish signal'
            ],
            'next_lesson': 'Short Selling',
            'badge_unlocked': 'Split Master',
          },
        ],
      },
      {
        'id': 'short_selling',
        'title': 'Short Selling',
        'description': 'Learn to profit from falling prices',
        'duration': 8,
        'difficulty': 'Advanced',
        'xp_reward': 400,
        'badge': 'Short Seller',
        'badge_emoji': '📉',
        'category': 'Advanced',
        'steps': [
          {
            'type': 'intro',
            'content': 'Ready to learn short selling?',
            'subtitle': 'Profit when stocks go down!',
            'icon': '📉',
          },
          {
            'type': 'multiple_choice',
            'question': 'What is short selling?',
            'options': [
              'Borrow stock, sell it, buy back later (hopefully cheaper)',
              'Buy stock and hold forever',
              'Sell your own stock',
              'Buy at low price'
            ],
            'correct': 0,
            'explanation': 'Short = bet price goes DOWN!',
            'xp': 20,
          },
          {
            'type': 'multiple_choice',
            'question': 'What is the maximum loss when shorting?',
            'options': [
              'Unlimited (stock can go up forever)',
              '100% of investment',
              '50% maximum',
              'No risk at all'
            ],
            'correct': 0,
            'explanation': 'Shorting has UNLIMITED risk - stock can keep rising!',
            'xp': 20,
          },
          {
            'type': 'true_false',
            'question': 'Short selling is riskier than buying stocks because losses are unlimited.',
            'correct': true,
            'explanation': 'Yes! When buying, max loss is 100%. When shorting, losses can be unlimited!',
            'xp': 20,
          },
          {
            'type': 'multiple_choice',
            'question': 'You short Apple at \$150. Price rises to \$200. Your loss is:',
            'options': [
              '\$50 per share (unlimited risk)',
              '\$0',
              '\$150 per share',
              'Can\'t lose money shorting'
            ],
            'correct': 0,
            'explanation': 'Short at \$150, price to \$200 = \$50 loss per share (and could go higher)!',
            'xp': 25,
          },
          {
            'type': 'summary',
            'title': '🎉 You earned +400 XP!',
            'subtitle': 'You\'re now a Short Seller 📉',
            'concepts_learned': [
              'Short = profit from falling price',
              'Unlimited risk potential',
              'Use strict stop losses',
              'Only for experienced traders'
            ],
            'next_lesson': null,
            'badge_unlocked': 'Short Seller',
          },
        ],
      },
    ];
  }
}



