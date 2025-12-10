class TradingLessonsData {
  static List<Map<String, dynamic>> getAllLessons() {
    return [
      {
        'id': 1,
        'title': 'What is a Stock?',
        'description': 'Learn the basics of stock ownership',
        'content': 'A stock is a piece of a company you can buy! When you buy Apple stock (AAPL), you own a tiny piece of Apple Inc. The more shares you buy, the bigger your piece becomes. Stocks can go up (you make money) or down (you lose money). It\'s like owning a slice of pizza - the bigger your slice, the more pizza you own!',
        'xp': 100,
        'icon': '📈',
        'color': 0xFF58CC02,
        'difficulty': 'Beginner',
        'duration': '3 min',
        'badge': 'Stock Basics Master',
        'questions': [
          {
            'type': 'multiple_choice',
            'question': 'What is a stock?',
            'options': [
              'A piece of a company you can buy',
              'A type of currency',
              'A bank account',
              'A credit card',
            ],
            'correct': 0,
            'explanation': 'A stock represents ownership in a company! When you buy a stock, you become a part-owner (shareholder) of that company.',
          },
          {
            'type': 'true_false',
            'question': 'When you buy a stock, you become a part-owner of that company.',
            'correct': true,
            'explanation': 'Exactly! Buying a stock makes you a shareholder, which means you own a small piece of that company.',
          },
          {
            'type': 'fill_blank',
            'question': 'A stock represents _____ in a company.',
            'options': ['ownership', 'debt', 'friendship', 'employment'],
            'correct': 0,
            'explanation': 'Stocks represent ownership! You own a small piece of the company when you buy their stock.',
          },
          {
            'type': 'speak',
            'question': 'Say this trading tip out loud:',
            'text': 'When you buy a stock, you become a part-owner of that company!',
          },
        ],
      },
      {
        'id': 2,
        'title': 'How to Make Money Trading',
        'description': 'Learn the golden rule of trading',
        'content': 'The golden rule of trading: Buy low, sell high! If you buy Apple stock at \$150 and sell it at \$200, you made \$50 profit per share! But if you buy at \$200 and sell at \$150, you lost \$50. The key is timing - buy when prices are low, sell when they\'re high. Warren Buffett says: "Be fearful when others are greedy, and greedy when others are fearful."',
        'xp': 150,
        'icon': '💰',
        'color': 0xFF1CB0F6,
        'difficulty': 'Beginner',
        'duration': '4 min',
        'badge': 'Trading Fundamentals',
        'questions': [
          {
            'type': 'multiple_choice',
            'question': 'What is the golden rule of trading?',
            'options': [
              'Buy high, sell low',
              'Buy low, sell high',
              'Never trade',
              'Always buy expensive stocks',
            ],
            'correct': 1,
            'explanation': 'Buy low, sell high! You want to buy stocks when they\'re cheap and sell when they\'re expensive to make a profit.',
          },
          {
            'type': 'true_false',
            'question': 'You make money by buying stocks at a low price and selling them at a higher price.',
            'correct': true,
            'explanation': 'Exactly! The profit comes from the difference between what you paid and what you sold for.',
          },
          {
            'type': 'fill_blank',
            'question': 'To make money trading, you should buy _____ and sell _____.',
            'options': ['low, high', 'high, low', 'expensive, cheap', 'cheap, expensive'],
            'correct': 0,
            'explanation': 'Buy low, sell high! This is the fundamental principle of profitable trading.',
          },
          {
            'type': 'match',
            'question': 'Match the trading concepts:',
            'pairs': [
              {'term': 'Buy Low', 'definition': 'Purchase stocks when price is low'},
              {'term': 'Sell High', 'definition': 'Sell stocks when price is high'},
              {'term': 'Profit', 'definition': 'Money you make from trading'},
              {'term': 'Loss', 'definition': 'Money you lose from trading'},
            ],
          },
          {
            'type': 'speak',
            'question': 'Say this trading mantra out loud:',
            'text': 'Buy low, sell high to make profit!',
          },
        ],
      },
      {
        'id': 3,
        'title': 'Reading Stock Charts',
        'description': 'Understand price movements and trends',
        'content': 'Stock charts show you the story of a stock! Green candles mean the price went up, red candles mean it went down. Look for patterns: if a stock keeps going up, it might keep going up (uptrend). If it keeps going down, it might keep going down (downtrend). The key is to buy when the trend is up and sell when it turns down!',
        'xp': 200,
        'icon': '📊',
        'color': 0xFFFF6B35,
        'difficulty': 'Intermediate',
        'duration': '5 min',
        'badge': 'Chart Reader',
        'questions': [
          {
            'type': 'multiple_choice',
            'question': 'What does a green candle on a stock chart mean?',
            'options': [
              'The stock price went down',
              'The stock price went up',
              'The stock price stayed the same',
              'The stock is not trading',
            ],
            'correct': 1,
            'explanation': 'Green candles mean the stock price went up! Red candles mean the price went down.',
          },
          {
            'type': 'true_false',
            'question': 'An upward trend on a chart means the stock price is generally increasing.',
            'correct': true,
            'explanation': 'Exactly! An upward trend shows that the stock price is generally moving higher over time.',
          },
          {
            'type': 'fill_blank',
            'question': 'A _____ trend means the stock price is going up over time.',
            'options': ['bullish', 'bearish', 'sideways', 'volatile'],
            'correct': 0,
            'explanation': 'A bullish trend means the stock price is going up! Bearish means it\'s going down.',
          },
          {
            'type': 'match',
            'question': 'Match the chart patterns:',
            'pairs': [
              {'term': 'Bullish Trend', 'definition': 'Stock price going up over time'},
              {'term': 'Bearish Trend', 'definition': 'Stock price going down over time'},
              {'term': 'Support Level', 'definition': 'Price level where stock tends to bounce up'},
              {'term': 'Resistance Level', 'definition': 'Price level where stock tends to bounce down'},
            ],
          },
          {
            'type': 'speak',
            'question': 'Say this chart reading tip out loud:',
            'text': 'Green candles mean the price went up, red candles mean the price went down!',
          },
        ],
      },
      {
        'id': 4,
        'title': 'Risk Management',
        'description': 'Protect your money from big losses',
        'content': 'Risk management is the most important skill in trading! Never risk more than 1% of your account on one trade. Use stop-loss orders to automatically sell if a stock drops too much. Diversify your portfolio - don\'t put all your money in one stock. Remember: it\'s better to make small, consistent profits than to risk everything on one big trade!',
        'xp': 175,
        'icon': '🛡️',
        'color': 0xFFE74C3C,
        'difficulty': 'Intermediate',
        'duration': '4 min',
        'badge': 'Risk Manager',
        'questions': [
          {
            'type': 'multiple_choice',
            'question': 'What is the 1% rule in trading?',
            'options': [
              'Never risk more than 1% of your account on one trade',
              'Always aim for 1% profit',
              'Only trade 1% of the time',
              'Only invest 1% of your money',
            ],
            'correct': 0,
            'explanation': 'The 1% rule means never risk more than 1% of your total account on a single trade. This protects you from big losses.',
          },
          {
            'type': 'true_false',
            'question': 'A stop-loss order automatically sells your stock if the price drops too much.',
            'correct': true,
            'explanation': 'Exactly! Stop-loss orders protect you by automatically selling if the price falls below your set level.',
          },
          {
            'type': 'fill_blank',
            'question': 'Never risk more than _____% of your account on one trade.',
            'options': ['1', '10', '50', '100'],
            'correct': 0,
            'explanation': 'Never risk more than 1%! This rule helps protect your capital from big losses.',
          },
          {
            'type': 'match',
            'question': 'Match the risk management tools:',
            'pairs': [
              {'term': 'Stop Loss', 'definition': 'Automatically sells if price drops'},
              {'term': 'Position Size', 'definition': 'How much money you invest'},
              {'term': 'Diversification', 'definition': 'Spreading risk across many stocks'},
              {'term': 'Risk/Reward', 'definition': 'Comparing potential loss to potential gain'},
            ],
          },
          {
            'type': 'speak',
            'question': 'Say this risk management rule out loud:',
            'text': 'Never risk more than 1% of your account on one trade!',
          },
        ],
      },
      {
        'id': 5,
        'title': 'Trading Psychology',
        'description': 'Control your emotions while trading',
        'content': 'Trading psychology is 80% of success! Fear makes you sell too early, greed makes you hold too long. FOMO (Fear of Missing Out) makes you buy stocks just because others are buying. The best traders stay calm, stick to their plan, and never let emotions control their decisions. Remember: the market doesn\'t care about your feelings - it only cares about facts!',
        'xp': 250,
        'icon': '🧠',
        'color': 0xFF9B59B6,
        'difficulty': 'Advanced',
        'duration': '6 min',
        'badge': 'Emotion Master',
        'questions': [
          {
            'type': 'multiple_choice',
            'question': 'What is FOMO in trading?',
            'options': [
              'Fear of Missing Out - buying stocks because everyone else is',
              'Fear of Making Orders',
              'Fear of Market Opportunities',
              'Fear of Money Operations',
            ],
            'correct': 0,
            'explanation': 'FOMO (Fear of Missing Out) makes you buy stocks just because others are buying, often leading to bad decisions.',
          },
          {
            'type': 'true_false',
            'question': 'Emotions like fear and greed can lead to bad trading decisions.',
            'correct': true,
            'explanation': 'Exactly! Fear and greed are the biggest enemies of successful trading. Stay calm and stick to your plan.',
          },
          {
            'type': 'fill_blank',
            'question': 'The two biggest emotions that hurt traders are _____ and _____.',
            'options': ['fear, greed', 'love, hate', 'joy, sadness', 'anger, calm'],
            'correct': 0,
            'explanation': 'Fear and greed! Fear makes you sell too early, greed makes you hold too long.',
          },
          {
            'type': 'match',
            'question': 'Match the trading emotions:',
            'pairs': [
              {'term': 'Fear', 'definition': 'Makes you sell too early'},
              {'term': 'Greed', 'definition': 'Makes you hold too long'},
              {'term': 'FOMO', 'definition': 'Fear of missing out on gains'},
              {'term': 'Patience', 'definition': 'Key to successful trading'},
            ],
          },
          {
            'type': 'speak',
            'question': 'Say this trading psychology tip out loud:',
            'text': 'Stay calm, stick to your plan, and don\'t let emotions control your trading!',
          },
        ],
      },
      {
        'id': 6,
        'title': 'Real Trading Practice',
        'description': 'Make your first real trade',
        'content': 'You\'ve learned the basics! Now it\'s time to practice with paper trading before risking real money. Start with small amounts you can afford to lose. Always research companies before buying. Use stop-loss orders to protect your capital. Track your trades and learn from your mistakes. Remember: every professional trader started as a beginner. Practice makes perfect!',
        'xp': 500,
        'icon': '🚀',
        'color': 0xFF2ECC71,
        'difficulty': 'Advanced',
        'duration': '10 min',
        'badge': 'Trading Master',
        'questions': [
          {
            'type': 'multiple_choice',
            'question': 'What should you do before making your first real trade?',
            'options': [
              'Start with paper trading to practice',
              'Invest all your money immediately',
              'Follow random tips from social media',
              'Buy the most expensive stocks',
            ],
            'correct': 0,
            'explanation': 'Always start with paper trading! Practice with fake money first to learn without risking real money.',
          },
          {
            'type': 'true_false',
            'question': 'You should start with small amounts of real money when you begin trading.',
            'correct': true,
            'explanation': 'Exactly! Start small with real money you can afford to lose while you\'re still learning.',
          },
          {
            'type': 'fill_blank',
            'question': 'Before trading with real money, you should practice with _____ trading.',
            'options': ['paper', 'digital', 'virtual', 'fake'],
            'correct': 0,
            'explanation': 'Paper trading! Practice with fake money first to learn the ropes without real risk.',
          },
          {
            'type': 'match',
            'question': 'Match the trading steps:',
            'pairs': [
              {'term': 'Paper Trading', 'definition': 'Practice with fake money first'},
              {'term': 'Small Amounts', 'definition': 'Start with money you can afford to lose'},
              {'term': 'Research', 'definition': 'Study companies before buying'},
              {'term': 'Risk Management', 'definition': 'Never risk more than you can lose'},
            ],
          },
          {
            'type': 'speak',
            'question': 'Say this trading practice tip out loud:',
            'text': 'Start with paper trading, then small amounts of real money!',
          },
        ],
      },
    ];
  }

  static Map<String, dynamic>? getLessonById(int id) {
    final lessons = getAllLessons();
    try {
      return lessons.firstWhere((lesson) => lesson['id'] == id);
    } catch (e) {
      return null;
    }
  }
}


