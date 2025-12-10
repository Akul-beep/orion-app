class TradingLessons {
  static List<Map<String, dynamic>> getAllLessons() {
    return [
      {
        'id': 'basics_1',
        'title': 'What is a Stock?',
        'description': 'Learn the fundamentals of stock ownership',
        'duration': '5 minutes',
        'difficulty': 'Beginner',
        'steps': [
          {
            'title': 'Understanding Stocks',
            'content': 'A stock represents ownership in a company. When you buy a stock, you become a shareholder and own a small piece of that company. The more shares you own, the bigger your ownership stake.',
            'type': 'basic',
            'iconText': 'Stock Ownership',
            'example': 'If Apple has 1 billion shares and you own 100 shares, you own 0.00001% of Apple!'
          },
          {
            'title': 'Why Companies Sell Stocks',
            'content': 'Companies sell stocks to raise money for growth, research, expansion, or paying off debt. This is called an IPO (Initial Public Offering).',
            'type': 'basic',
            'iconText': 'Company Growth',
            'example': 'Tesla went public in 2010 at \$17 per share to fund electric vehicle development.'
          },
          {
            'title': 'How You Make Money',
            'content': 'You make money from stocks in two ways: 1) Price appreciation (stock price goes up) and 2) Dividends (company pays you cash).',
            'type': 'trading',
            'iconText': 'Making Money',
            'example': 'Buy Apple at \$150, sell at \$200 = \$50 profit per share!'
          }
        ],
        'quiz': [
          {
            'question': 'What does owning a stock mean?',
            'options': [
              'You lend money to the company',
              'You own a piece of the company',
              'You work for the company',
              'You are the company\'s customer'
            ],
            'correct': 1
          },
          {
            'question': 'How do you make money from stocks?',
            'options': [
              'Only through dividends',
              'Only through price increases',
              'Through price increases and dividends',
              'You don\'t make money from stocks'
            ],
            'correct': 2
          },
          {
            'question': 'What is an IPO?',
            'options': [
              'A type of stock',
              'When a company first sells stocks to the public',
              'A stock market crash',
              'A trading strategy'
            ],
            'correct': 1
          }
        ]
      },
      {
        'id': 'basics_2',
        'title': 'Stock Market Basics',
        'description': 'Understanding how the stock market works',
        'duration': '8 minutes',
        'difficulty': 'Beginner',
        'steps': [
          {
            'title': 'What is the Stock Market?',
            'content': 'The stock market is where buyers and sellers trade stocks. It\'s like a giant marketplace where people buy and sell ownership in companies.',
            'type': 'basic',
            'iconText': 'Market Place',
            'example': 'Think of it like eBay, but for company ownership instead of products.'
          },
          {
            'title': 'Major Stock Exchanges',
            'content': 'NYSE (New York Stock Exchange) and NASDAQ are the biggest. Companies list their stocks on these exchanges for trading.',
            'type': 'basic',
            'iconText': 'Exchanges',
            'example': 'Apple trades on NASDAQ, Coca-Cola trades on NYSE.'
          },
          {
            'title': 'Market Hours',
            'content': 'Regular trading hours are 9:30 AM to 4:00 PM EST, Monday through Friday. Pre-market (4:00-9:30 AM) and after-hours (4:00-8:00 PM) also exist.',
            'type': 'trading',
            'iconText': 'Trading Hours',
            'example': 'Most active trading happens during regular hours when most people are awake.'
          }
        ],
        'quiz': [
          {
            'question': 'What are the two major US stock exchanges?',
            'options': [
              'NYSE and London Stock Exchange',
              'NYSE and NASDAQ',
              'NASDAQ and Tokyo Stock Exchange',
              'NYSE and Shanghai Stock Exchange'
            ],
            'correct': 1
          },
          {
            'question': 'What are regular trading hours?',
            'options': [
              '8:00 AM to 5:00 PM',
              '9:30 AM to 4:00 PM',
              '10:00 AM to 3:00 PM',
              '24 hours a day'
            ],
            'correct': 1
          }
        ]
      },
      {
        'id': 'risk_1',
        'title': 'Risk Management',
        'description': 'Protecting your money while trading',
        'duration': '10 minutes',
        'difficulty': 'Intermediate',
        'steps': [
          {
            'title': 'The 1% Rule',
            'content': 'Never risk more than 1% of your account on a single trade. This protects you from big losses that could wipe out your account.',
            'type': 'risk',
            'iconText': 'Protect Money',
            'example': 'If you have \$1,000, never risk more than \$10 on one trade.'
          },
          {
            'title': 'Stop Losses',
            'content': 'A stop loss automatically sells your stock if it drops to a certain price. This limits your losses and protects your capital.',
            'type': 'risk',
            'iconText': 'Safety Net',
            'example': 'Buy Apple at \$150, set stop loss at \$140. If it drops to \$140, you automatically sell and only lose \$10 per share.'
          },
          {
            'title': 'Position Sizing',
            'content': 'Only invest what you can afford to lose. Never use money you need for rent, food, or emergencies.',
            'type': 'risk',
            'iconText': 'Smart Sizing',
            'example': 'If you have \$5,000 savings, maybe only invest \$500-1,000 to start.'
          }
        ],
        'quiz': [
          {
            'question': 'What is the 1% rule?',
            'options': [
              'Make 1% profit on every trade',
              'Risk only 1% of your account per trade',
              'Trade only 1% of the time',
              'Buy only 1% of a company'
            ],
            'correct': 1
          },
          {
            'question': 'What does a stop loss do?',
            'options': [
              'Guarantees profits',
              'Automatically sells if price drops',
              'Buys more shares',
              'Shows you the stock price'
            ],
            'correct': 1
          }
        ]
      },
      {
        'id': 'analysis_1',
        'title': 'Reading Stock Charts',
        'description': 'Understanding price movements and patterns',
        'duration': '12 minutes',
        'difficulty': 'Intermediate',
        'steps': [
          {
            'title': 'Price and Volume',
            'content': 'Stock price shows what people are willing to pay. Volume shows how many shares are being traded. High volume often means big moves.',
            'type': 'analysis',
            'iconText': 'Chart Reading',
            'example': 'If Tesla jumps 5% on high volume, it means lots of people are buying and the move is strong.'
          },
          {
            'title': 'Support and Resistance',
            'content': 'Support is where prices tend to bounce up (like a floor). Resistance is where prices tend to bounce down (like a ceiling).',
            'type': 'analysis',
            'iconText': 'Price Levels',
            'example': 'If Apple keeps bouncing off \$150, that\'s support. If it keeps falling from \$160, that\'s resistance.'
          },
          {
            'title': 'Moving Averages',
            'content': 'Moving averages smooth out price data to show trends. If price is above the 50-day average, it\'s generally going up.',
            'type': 'analysis',
            'iconText': 'Trend Lines',
            'example': 'When Apple\'s price crosses above its 50-day moving average, it often continues higher.'
          }
        ],
        'quiz': [
          {
            'question': 'What does high volume usually indicate?',
            'options': [
              'The stock is cheap',
              'Strong interest and potential big moves',
              'The stock is expensive',
              'Nothing important'
            ],
            'correct': 1
          },
          {
            'question': 'What is support?',
            'options': [
              'A price level where stocks tend to bounce up',
              'A price level where stocks tend to fall',
              'The highest price ever reached',
              'The lowest price ever reached'
            ],
            'correct': 0
          }
        ]
      },
      {
        'id': 'news_1',
        'title': 'Trading the News',
        'description': 'Using news and events to make trading decisions',
        'duration': '8 minutes',
        'difficulty': 'Intermediate',
        'steps': [
          {
            'title': 'News Moves Markets',
            'content': 'Good news usually makes stock prices go up. Bad news makes them go down. The key is getting the news before everyone else.',
            'type': 'news',
            'iconText': 'News Impact',
            'example': 'When Apple announces record iPhone sales, the stock usually jumps 2-5% the next day.'
          },
          {
            'title': 'Earnings Reports',
            'content': 'Companies report earnings every quarter. If they beat expectations, stocks usually go up. If they miss, stocks usually go down.',
            'type': 'news',
            'iconText': 'Earnings',
            'example': 'Tesla beats earnings expectations → stock jumps 10% in after-hours trading.'
          },
          {
            'title': 'Economic Events',
            'content': 'Interest rate changes, unemployment reports, and GDP growth all affect the entire market. Learn to watch these events.',
            'type': 'news',
            'iconText': 'Economy',
            'example': 'When the Fed raises interest rates, tech stocks often fall because borrowing costs increase.'
          }
        ],
        'quiz': [
          {
            'question': 'How does good news typically affect stock prices?',
            'options': [
              'Prices go down',
              'Prices go up',
              'No effect',
              'Prices stay the same'
            ],
            'correct': 1
          },
          {
            'question': 'What happens when a company beats earnings expectations?',
            'options': [
              'Stock price usually goes down',
              'Stock price usually goes up',
              'Nothing happens',
              'The company goes bankrupt'
            ],
            'correct': 1
          }
        ]
      },
      {
        'id': 'strategy_1',
        'title': 'Day Trading Basics',
        'description': 'Buying and selling stocks within the same day',
        'duration': '15 minutes',
        'difficulty': 'Advanced',
        'steps': [
          {
            'title': 'What is Day Trading?',
            'content': 'Day trading means buying and selling stocks within the same day. You never hold positions overnight. The goal is to profit from short-term price movements.',
            'type': 'trading',
            'iconText': 'Same Day',
            'example': 'Buy Tesla at 9:30 AM for \$200, sell at 2:00 PM for \$205 = \$5 profit per share.'
          },
          {
            'title': 'Best Times to Trade',
            'content': 'The first hour (9:30-10:30 AM) and last hour (3:00-4:00 PM) are usually the most volatile and profitable for day trading.',
            'type': 'trading',
            'iconText': 'Timing',
            'example': 'Most day traders make 80% of their profits during these two hours.'
          },
          {
            'title': 'Day Trading Rules',
            'content': '1) Have a plan before you trade 2) Use stop losses 3) Don\'t trade with money you can\'t afford to lose 4) Keep emotions out of it.',
            'type': 'trading',
            'iconText': 'Rules',
            'example': 'Set a daily loss limit of \$50. Once you hit it, stop trading for the day.'
          }
        ],
        'quiz': [
          {
            'question': 'What is day trading?',
            'options': [
              'Holding stocks for months',
              'Buying and selling within the same day',
              'Only trading on weekends',
              'Trading only blue-chip stocks'
            ],
            'correct': 1
          },
          {
            'question': 'When are the best times to day trade?',
            'options': [
              'Only at market open',
              'First and last hour of trading',
              'Only at market close',
              'Random times throughout the day'
            ],
            'correct': 1
          }
        ]
      }
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
}
