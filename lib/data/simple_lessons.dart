// Super Simple Lessons for Gen-Z High Schoolers
// 30-second max, immediately actionable

class SimpleLesson {
  final String id;
  final String title;
  final String description;
  final String type; // 'swipe', 'tap', 'quiz'
  final Map<String, dynamic> content;
  final int xpReward;
  final String? tradingSymbol; // For immediate trading practice

  SimpleLesson({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.content,
    required this.xpReward,
    this.tradingSymbol,
  });
}

class SimpleLessonData {
  static List<SimpleLesson> getDay1Lessons() {
    return [
      // Swipe Cards - Stock Symbol Recognition
      SimpleLesson(
        id: 'swipe_aapl',
        title: 'Stock Symbol Recognition',
        description: 'Swipe right if you know what AAPL stands for',
        type: 'swipe',
        content: {
          'question': 'Do you know what AAPL stands for?',
          'answer': 'Apple Inc.',
          'explanation': 'AAPL is the stock symbol for Apple Inc., the company that makes iPhones and MacBooks.',
          'swipe_right': 'Yes, I know it',
          'swipe_left': 'No, I don\'t know',
        },
        xpReward: 10,
        tradingSymbol: 'AAPL',
      ),
      SimpleLesson(
        id: 'swipe_tsla',
        title: 'Stock Symbol Recognition',
        description: 'Swipe right if you know what TSLA stands for',
        type: 'swipe',
        content: {
          'question': 'Do you know what TSLA stands for?',
          'answer': 'Tesla Inc.',
          'explanation': 'TSLA is the stock symbol for Tesla Inc., the electric car company led by Elon Musk.',
          'swipe_right': 'Yes, I know it',
          'swipe_left': 'No, I don\'t know',
        },
        xpReward: 10,
        tradingSymbol: 'TSLA',
      ),
      SimpleLesson(
        id: 'swipe_googl',
        title: 'Stock Symbol Recognition',
        description: 'Swipe right if you know what GOOGL stands for',
        type: 'swipe',
        content: {
          'question': 'Do you know what GOOGL stands for?',
          'answer': 'Google Inc.',
          'explanation': 'GOOGL is the stock symbol for Google Inc., the company that owns YouTube and Google Search.',
          'swipe_right': 'Yes, I know it',
          'swipe_left': 'No, I don\'t know',
        },
        xpReward: 10,
        tradingSymbol: 'GOOGL',
      ),
      SimpleLesson(
        id: 'swipe_msft',
        title: 'Stock Symbol Recognition',
        description: 'Swipe right if you know what MSFT stands for',
        type: 'swipe',
        content: {
          'question': 'Do you know what MSFT stands for?',
          'answer': 'Microsoft Corp.',
          'explanation': 'MSFT is the stock symbol for Microsoft Corp., the company that makes Windows and Xbox.',
          'swipe_right': 'Yes, I know it',
          'swipe_left': 'No, I don\'t know',
        },
        xpReward: 10,
        tradingSymbol: 'MSFT',
      ),
      SimpleLesson(
        id: 'swipe_amzn',
        title: 'Stock Symbol Recognition',
        description: 'Swipe right if you know what AMZN stands for',
        type: 'swipe',
        content: {
          'question': 'Do you know what AMZN stands for?',
          'answer': 'Amazon Inc.',
          'explanation': 'AMZN is the stock symbol for Amazon Inc., the company that owns Amazon.com and AWS.',
          'swipe_right': 'Yes, I know it',
          'swipe_left': 'No, I don\'t know',
        },
        xpReward: 10,
        tradingSymbol: 'AMZN',
      ),
    ];
  }

  static List<SimpleLesson> getDay2Lessons() {
    return [
      // Tap Lessons - Portfolio Building
      SimpleLesson(
        id: 'tap_portfolio',
        title: 'Build Your Portfolio',
        description: 'Tap 3 stocks to add to your \$10,000 portfolio',
        type: 'tap',
        content: {
          'instruction': 'Choose 3 stocks to add to your portfolio',
          'budget': 10000,
          'stocks': [
            {'symbol': 'AAPL', 'name': 'Apple Inc.', 'price': 150.00},
            {'symbol': 'TSLA', 'name': 'Tesla Inc.', 'price': 200.00},
            {'symbol': 'GOOGL', 'name': 'Google Inc.', 'price': 120.00},
            {'symbol': 'MSFT', 'name': 'Microsoft Corp.', 'price': 300.00},
            {'symbol': 'AMZN', 'name': 'Amazon Inc.', 'price': 100.00},
          ],
          'explanation': 'Great! You\'ve built your first portfolio. Now let\'s see how it performs!',
        },
        xpReward: 25,
      ),
      // Swipe Cards - Price Movements
      SimpleLesson(
        id: 'swipe_green',
        title: 'Price Movement',
        description: 'Swipe right if you think green means the stock went up',
        type: 'swipe',
        content: {
          'question': 'When you see green, does that mean the stock price went up or down?',
          'answer': 'Up',
          'explanation': 'Green means the stock price went up (positive change). Red means it went down (negative change).',
          'swipe_right': 'Yes, green means up',
          'swipe_left': 'No, green means down',
        },
        xpReward: 10,
      ),
      SimpleLesson(
        id: 'swipe_red',
        title: 'Price Movement',
        description: 'Swipe right if you think red means the stock went down',
        type: 'swipe',
        content: {
          'question': 'When you see red, does that mean the stock price went up or down?',
          'answer': 'Down',
          'explanation': 'Red means the stock price went down (negative change). Green means it went up (positive change).',
          'swipe_right': 'Yes, red means down',
          'swipe_left': 'No, red means up',
        },
        xpReward: 10,
      ),
    ];
  }

  static List<SimpleLesson> getDay3Lessons() {
    return [
      // Quiz Games - Simple Questions
      SimpleLesson(
        id: 'quiz_basics',
        title: 'Stock Basics Quiz',
        description: 'Answer 5 simple questions about stocks in 60 seconds',
        type: 'quiz',
        content: {
          'timeLimit': 60,
          'questions': [
            {
              'question': 'Which is Apple\'s stock symbol?',
              'answers': ['AAPL', 'APPL', 'APLE'],
              'correct': 0,
              'explanation': 'AAPL is the correct stock symbol for Apple Inc.',
            },
            {
              'question': 'What does TSLA stand for?',
              'answers': ['Tesla Inc.', 'Toyota Inc.', 'Tesla Corp.'],
              'correct': 0,
              'explanation': 'TSLA stands for Tesla Inc., the electric car company.',
            },
            {
              'question': 'Which color means a stock went up?',
              'answers': ['Green', 'Red', 'Blue'],
              'correct': 0,
              'explanation': 'Green means the stock price went up (positive change).',
            },
            {
              'question': 'What does GOOGL stand for?',
              'answers': ['Google Inc.', 'Goggle Inc.', 'Googol Inc.'],
              'correct': 0,
              'explanation': 'GOOGL stands for Google Inc., the search engine company.',
            },
            {
              'question': 'Which color means a stock went down?',
              'answers': ['Red', 'Green', 'Yellow'],
              'correct': 0,
              'explanation': 'Red means the stock price went down (negative change).',
            },
          ],
        },
        xpReward: 50,
      ),
    ];
  }

  static List<SimpleLesson> getTradingLessons() {
    return [
      // Immediate Trading Practice
      SimpleLesson(
        id: 'trade_aapl',
        title: 'Trade AAPL',
        description: 'Buy 10 shares of AAPL at \$150 per share',
        type: 'trade',
        content: {
          'symbol': 'AAPL',
          'name': 'Apple Inc.',
          'price': 150.00,
          'shares': 10,
          'totalCost': 1500.00,
          'instruction': 'Buy 10 shares of AAPL at \$150 per share',
          'explanation': 'You just bought 10 shares of Apple for \$1,500. If the price goes up, you make money!',
        },
        xpReward: 50,
        tradingSymbol: 'AAPL',
      ),
      SimpleLesson(
        id: 'trade_tsla',
        title: 'Trade TSLA',
        description: 'Buy 5 shares of TSLA at \$200 per share',
        type: 'trade',
        content: {
          'symbol': 'TSLA',
          'name': 'Tesla Inc.',
          'price': 200.00,
          'shares': 5,
          'totalCost': 1000.00,
          'instruction': 'Buy 5 shares of TSLA at \$200 per share',
          'explanation': 'You just bought 5 shares of Tesla for \$1,000. Electric cars are the future!',
        },
        xpReward: 50,
        tradingSymbol: 'TSLA',
      ),
      SimpleLesson(
        id: 'trade_googl',
        title: 'Trade GOOGL',
        description: 'Buy 8 shares of GOOGL at \$120 per share',
        type: 'trade',
        content: {
          'symbol': 'GOOGL',
          'name': 'Google Inc.',
          'price': 120.00,
          'shares': 8,
          'totalCost': 960.00,
          'instruction': 'Buy 8 shares of GOOGL at \$120 per share',
          'explanation': 'You just bought 8 shares of Google for \$960. They own YouTube!',
        },
        xpReward: 50,
        tradingSymbol: 'GOOGL',
      ),
    ];
  }

  static List<SimpleLesson> getDailyChallenge() {
    return [
      SimpleLesson(
        id: 'daily_challenge',
        title: 'Daily Challenge',
        description: 'Complete 5 swipe cards in 2 minutes',
        type: 'challenge',
        content: {
          'timeLimit': 120,
          'cards': [
            'AAPL = Apple Inc.',
            'TSLA = Tesla Inc.',
            'GOOGL = Google Inc.',
            'MSFT = Microsoft Corp.',
            'AMZN = Amazon Inc.',
          ],
          'reward': 'Speed Demon Achievement',
        },
        xpReward: 100,
      ),
    ];
  }

  // Get lessons for a specific day
  static List<SimpleLesson> getLessonsForDay(int day) {
    switch (day) {
      case 1:
        return getDay1Lessons();
      case 2:
        return getDay2Lessons();
      case 3:
        return getDay3Lessons();
      default:
        return getDay1Lessons(); // Default to day 1
    }
  }

  // Get all trading lessons
  static List<SimpleLesson> getAllTradingLessons() {
    return getTradingLessons();
  }

  // Get daily challenge
  static List<SimpleLesson> getDailyChallengeLessons() {
    return getDailyChallenge();
  }
}
