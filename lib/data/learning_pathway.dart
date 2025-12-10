import '../data/interactive_lessons.dart';

class LearningPathway {
  // Maps day number (1-30) to lesson ID in perfect beginner-to-advanced order
  static const Map<int, String> dayToLessonId = {
    1: 'what_is_stock',                    // Day 1: What is a Stock? (Beginner)
    2: 'how_stock_prices_work',            // Day 2: How Stock Prices Work (Beginner)
    3: 'market_cap',                       // Day 3: Market Cap Explained (Beginner)
    4: 'building_portfolio',               // Day 4: Building Your Portfolio (Beginner)
    5: 'candlestick_patterns',             // Day 5: Candlestick Patterns (Beginner)
    6: 'market_orders',                    // Day 6: Market vs Limit Orders (Intermediate)
    7: 'etfs_mutual_funds',                // Day 7: ETFs vs Mutual Funds (Intermediate)
    8: 'pe_ratio',                         // Day 8: P/E Ratio (Intermediate)
    9: 'moving_averages',                  // Day 9: Moving Averages (Intermediate)
    10: 'support_resistance',              // Day 10: Support & Resistance (Intermediate)
    11: 'rsi_basics',                      // Day 11: RSI Basics (Intermediate)
    12: 'volume_analysis',                 // Day 12: Volume Analysis (Intermediate)
    13: 'risk_management',                 // Day 13: Risk Management (Intermediate)
    14: 'position_sizing',                 // Day 14: Position Sizing (Intermediate)
    15: 'risk_reward_ratios',              // Day 15: Risk/Reward Ratios (Intermediate)
    16: 'portfolio_rebalancing',           // Day 16: Portfolio Rebalancing (Intermediate)
    17: 'macd_indicator',                  // Day 17: MACD Indicator (Intermediate)
    18: 'bollinger_bands',                 // Day 18: Bollinger Bands (Intermediate)
    19: 'chart_patterns',                  // Day 19: Chart Patterns (Intermediate)
    20: 'breakout_trading',                // Day 20: Breakout Trading (Intermediate)
    21: 'gap_trading',                     // Day 21: Gap Trading (Intermediate)
    22: 'financial_statements',            // Day 22: Financial Statements (Advanced)
    23: 'earnings_reports',                // Day 23: Earnings Reports (Advanced)
    24: 'sector_investing',                // Day 24: Sector Investing (Intermediate)
    25: 'market_sentiment',                // Day 25: Market Sentiment (Intermediate)
    26: 'market_cycles',                   // Day 26: Market Cycles (Advanced)
    27: 'swing_trading',                   // Day 27: Swing Trading (Intermediate)
    28: 'day_trading_basics',              // Day 28: Day Trading Basics (Advanced)
    29: 'dividend_investing',              // Day 29: Dividend Investing (Intermediate)
    30: 'growth_vs_value',                 // Day 30: Growth vs Value (Intermediate)
  };

  // Bonus lessons (available after day 30)
  static const List<String> bonusLessons = [
    'trading_psychology',
    'options_basics',
    'backtesting',
    'ipo_basics',
    'stock_splits',
    'short_selling',
  ];

  /// Get lesson ID for a specific day (1-30)
  static String? getLessonIdForDay(int day) {
    return dayToLessonId[day];
  }

  /// Get day number for a specific lesson ID
  static int? getDayForLessonId(String lessonId) {
    for (final entry in dayToLessonId.entries) {
      if (entry.value == lessonId) {
        return entry.key;
      }
    }
    return null;
  }

  /// Get all lessons in proper beginner-to-advanced order (30 days + Supabase lessons)
  static Future<List<Map<String, dynamic>>> get30DayPathway() async {
    final allLessons = await InteractiveLessons.getAllLessons();
    final orderedLessons = <Map<String, dynamic>>[];
    
    // Add lessons in day order (1-30) - hardcoded lessons
    for (int day = 1; day <= 30; day++) {
      final lessonId = dayToLessonId[day];
      if (lessonId != null) {
        final lesson = allLessons.firstWhere(
          (l) => l['id'] == lessonId,
          orElse: () => <String, dynamic>{},
        );
        if (lesson.isNotEmpty) {
          orderedLessons.add({
            ...lesson,
            'day': day,
            'unlocked': day == 1, // Only day 1 is unlocked initially
            'completed': false,
          });
        }
      }
    }
    
    // Add Supabase lessons (31+) that aren't in the hardcoded list
    final hardcodedIds = dayToLessonId.values.toSet();
    final supabaseLessons = allLessons.where((lesson) {
      final lessonId = lesson['id'] as String?;
      return lessonId != null && !hardcodedIds.contains(lessonId);
    }).toList();
    
    // Add Supabase lessons as days 31+
    int dayCounter = 31;
    for (final lesson in supabaseLessons) {
      orderedLessons.add({
        ...lesson,
        'day': dayCounter,
        'unlocked': false, // Unlock based on completion of day 30
        'completed': false,
        'isSupabaseLesson': true, // Mark as Supabase lesson
      });
      dayCounter++;
    }
    
    return orderedLessons;
  }

  /// Get 30-day pathway grouped by weeks
  static Future<List<Map<String, dynamic>>> get30DayPathwayByWeek() async {
    final lessons = await get30DayPathway();
    final weeks = <Map<String, dynamic>>[];
    
    for (int weekNum = 1; weekNum <= 5; weekNum++) {
      final startDay = (weekNum - 1) * 7 + 1;
      final endDay = weekNum * 7;
      final weekLessons = lessons.where((l) {
        final day = l['day'] as int?;
        if (day == null) return false;
        return day >= startDay && day <= endDay;
      }).toList();
      
      String weekTitle;
      String weekDescription;
      
      if (weekNum == 1) {
        weekTitle = 'Foundation Week';
        weekDescription = 'Learn the absolute basics of stocks and trading';
      } else if (weekNum == 2) {
        weekTitle = 'Order Types & Fundamentals Week';
        weekDescription = 'Master order types, ETFs, and valuation metrics';
      } else if (weekNum == 3) {
        weekTitle = 'Technical Analysis Week';
        weekDescription = 'Learn charts, indicators, and technical strategies';
      } else if (weekNum == 4) {
        weekTitle = 'Advanced Analysis Week';
        weekDescription = 'Dive into fundamentals, sentiment, and cycles';
      } else {
        weekTitle = 'Trading Strategies Week';
        weekDescription = 'Master different trading styles and approaches';
      }
      
      weeks.add({
        'week': weekNum,
        'title': weekTitle,
        'description': weekDescription,
        'days': weekLessons.map((lesson) => {
          'day': lesson['day'] as int? ?? 0,
          'title': lesson['title'] ?? 'Lesson',
          'type': 'lesson',
          'duration': '${lesson['duration'] ?? 5} min',
          'xp': lesson['xp_reward'] as int? ?? 150,
          'difficulty': lesson['difficulty'] ?? 'Beginner',
          'lesson_id': lesson['id'] ?? '',
          'unlocked': lesson['unlocked'] ?? false,
          'completed': lesson['completed'] ?? false,
        }).toList(),
      });
    }
    
    return weeks;
  }

  /// Get day data for a specific day (1-30+)
  static Future<Map<String, dynamic>?> getDay(int day) async {
    // For days 1-30, use hardcoded mapping
    if (day <= 30) {
      final lessonId = dayToLessonId[day];
      if (lessonId == null) return null;
      
      final allLessons = await InteractiveLessons.getAllLessons();
      final lesson = allLessons.firstWhere(
        (l) => l['id'] == lessonId,
        orElse: () => <String, dynamic>{},
      );
      
      if (lesson.isEmpty) return null;
      
      return {
        ...lesson,
        'day': day,
        'unlocked': day == 1,
        'completed': false,
      };
    }
    
    // For days 31+, get from Supabase lessons
    final allLessons = await InteractiveLessons.getAllLessons();
    final hardcodedIds = dayToLessonId.values.toSet();
    final supabaseLessons = allLessons.where((lesson) {
      final lessonId = lesson['id'] as String?;
      return lessonId != null && !hardcodedIds.contains(lessonId);
    }).toList();
    
    final supabaseIndex = day - 31;
    if (supabaseIndex >= 0 && supabaseIndex < supabaseLessons.length) {
      return {
        ...supabaseLessons[supabaseIndex],
        'day': day,
        'unlocked': false,
        'completed': false,
        'isSupabaseLesson': true,
      };
    }
    
    return null;
  }

  /// Get all days as a flat list (includes Supabase lessons)
  static Future<List<Map<String, dynamic>>> getAllDays() async {
    return await get30DayPathway();
  }
  
  /// Get all lessons including 20 placeholder lessons (total 50)
  /// Real Supabase lessons (31+) replace placeholders when available
  static Future<List<Map<String, dynamic>>> getAllLessonsWithPlaceholders() async {
    final realLessons = await get30DayPathway();
    
    // Ensure all real lessons have lesson_id field for consistency
    final lessonsWithLessonId = realLessons.map((lesson) {
      if (!lesson.containsKey('lesson_id')) {
        lesson['lesson_id'] = lesson['id'];
      }
      return lesson;
    }).toList();
    
    // Find the highest day number in real lessons
    int maxDay = 30;
    for (final lesson in lessonsWithLessonId) {
      final day = lesson['day'] as int?;
      if (day != null && day > maxDay) {
        maxDay = day;
      }
    }
    
    // Add placeholder lessons for days 31-50 that don't have real lessons
    final allLessons = <Map<String, dynamic>>[...lessonsWithLessonId];
    
    for (int day = 31; day <= 50; day++) {
      // Check if we already have a real lesson for this day
      final hasRealLesson = allLessons.any((lesson) => lesson['day'] == day);
      
      if (!hasRealLesson) {
        // Add placeholder only if no real lesson exists
        allLessons.add({
          'day': day,
          'id': 'placeholder_lesson_$day',
          'lesson_id': 'placeholder_lesson_$day',
          'title': _getPlaceholderTitle(day),
          'description': _getPlaceholderDescription(day),
          'type': 'lesson',
          'duration': '5 min',
          'xp': 150,
          'difficulty': _getPlaceholderDifficulty(day),
          'unlocked': false,
          'completed': false,
          'isPlaceholder': true,
        });
      }
    }
    
    // Sort by day to ensure proper order
    allLessons.sort((a, b) {
      final dayA = a['day'] as int? ?? 0;
      final dayB = b['day'] as int? ?? 0;
      return dayA.compareTo(dayB);
    });
    
    return allLessons;
  }
  
  static String _getPlaceholderTitle(int day) {
    final titles = [
      'Advanced Options Trading',
      'Cryptocurrency Fundamentals',
      'Real Estate Investment Trusts',
      'Commodity Trading Basics',
      'Forex Market Introduction',
      'Technical Analysis Advanced',
      'Portfolio Optimization',
      'Risk Management Mastery',
      'Market Psychology',
      'Algorithmic Trading',
      'Fixed Income Securities',
      'Derivatives Trading',
      'Market Making Strategies',
      'High Frequency Trading',
      'Sustainable Investing',
      'International Markets',
      'Alternative Investments',
      'Tax Optimization',
      'Retirement Planning',
      'Wealth Management',
    ];
    return titles[(day - 31) % titles.length];
  }
  
  static String _getPlaceholderDescription(int day) {
    return 'Advanced trading concepts and strategies coming soon!';
  }
  
  static String _getPlaceholderDifficulty(int day) {
    if (day <= 35) return 'Intermediate';
    if (day <= 45) return 'Advanced';
    return 'Expert';
  }
}
