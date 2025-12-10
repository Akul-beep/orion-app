import 'package:flutter/material.dart';
import 'database_service.dart';
import 'gamification_service.dart';
import 'paper_trading_service.dart';

class DailyGoalsService extends ChangeNotifier {
  static final DailyGoalsService _instance = DailyGoalsService._internal();
  factory DailyGoalsService() => _instance;
  DailyGoalsService._internal();

  // Daily Goals (will be calculated dynamically based on user level)
  int _dailyXPGoal = 100;
  int _dailyTradeGoal = 1;
  int _dailyLessonGoal = 1;
  
  /// Calculate dynamic daily XP goal based on user level
  /// Formula: Base (100) + (Level * 10) - more reasonable scaling
  /// This scales with user progress but stays achievable
  int calculateDynamicXPGoal(GamificationService gamification) {
    final level = gamification.level;
    
    // Base goal for new users
    int baseGoal = 100;
    
    // Scale with level (each level adds 10 XP to goal - more reasonable)
    // Level 1: 100, Level 5: 140, Level 10: 190, Level 15: 240, Level 20: 290
    int levelBonus = (level - 1) * 10;
    
    // Final goal calculation
    int dynamicGoal = baseGoal + levelBonus;
    
    // Cap the goal (max 300 XP per day - achievable with: lesson + trades + bonus)
    // This is more reasonable:
    // - 1 lesson (150-250 XP)
    // - 2-3 trades (50-100 XP each at level 12 = 100-300 XP)
    // - Daily login bonus (10-50 XP)
    // Total: ~260-600 XP possible, so 300 goal is achievable
    dynamicGoal = dynamicGoal.clamp(100, 300);
    
    return dynamicGoal;
  }
  
  /// Update daily XP goal based on user progress
  void updateDailyXPGoal(GamificationService gamification) {
    _dailyXPGoal = calculateDynamicXPGoal(gamification);
    _saveToDatabase();
    notifyListeners();
  }
  
  // Today's Progress
  int _todayXP = 0;
  int _todayTrades = 0;
  int _todayLessons = 0;
  
  DateTime? _lastCheckedDate;

  // Getters
  int get dailyXPGoal => _dailyXPGoal;
  int get dailyTradeGoal => _dailyTradeGoal;
  int get dailyLessonGoal => _dailyLessonGoal;
  int get todayXP => _todayXP;
  int get todayTrades => _todayTrades;
  int get todayLessons => _todayLessons;
  
  bool get isXPGoalComplete => _todayXP >= _dailyXPGoal;
  bool get isTradeGoalComplete => _todayTrades >= _dailyTradeGoal;
  bool get isLessonGoalComplete => _todayLessons >= _dailyLessonGoal;
  bool get areAllGoalsComplete => isXPGoalComplete && isTradeGoalComplete && isLessonGoalComplete;
  
  double get xpProgress => (_todayXP / _dailyXPGoal).clamp(0.0, 1.0);
  double get tradeProgress => (_todayTrades / _dailyTradeGoal).clamp(0.0, 1.0);
  double get lessonProgress => (_todayLessons / _dailyLessonGoal).clamp(0.0, 1.0);

  // Initialize and load from database
  Future<void> initialize() async {
    await _loadFromDatabase();
    await _updateTodayProgress();
    
    // Update daily XP goal based on current user level
    // Wait a bit for gamification service to be ready
    await Future.delayed(const Duration(milliseconds: 500));
    await _refreshDailyXPGoal();
  }
  
  /// Refresh daily XP goal (call this after gamification service is initialized)
  Future<void> _refreshDailyXPGoal() async {
    try {
      final gamification = GamificationService.instance ?? GamificationService();
      // Make sure gamification is initialized
      await gamification.initialize();
      updateDailyXPGoal(gamification);
      print('📊 Updated daily XP goal to ${_dailyXPGoal} (Level ${gamification.level})');
    } catch (e) {
      print('Error updating daily XP goal: $e');
    }
  }
  
  /// Public method to force refresh the daily XP goal
  Future<void> refreshDailyXPGoal() async {
    await _refreshDailyXPGoal();
  }
  
  // Public method to refresh today's progress (call this when lessons are completed)
  Future<void> refreshTodayProgress() async {
    await _updateTodayProgress();
  }

  // Update today's progress
  Future<void> _updateTodayProgress() async {
    final today = DateTime.now();
    final todayKey = today.toIso8601String().split('T')[0];
    
    // Reset if it's a new day
    if (_lastCheckedDate == null || !_isSameDay(_lastCheckedDate!, today)) {
      _todayXP = 0;
      _todayTrades = 0;
      _todayLessons = 0;
      _lastCheckedDate = today;
    }
    
    // Load from gamification service
    try {
      final gamification = GamificationService();
      final dailyXP = gamification.dailyXP;
      _todayXP = dailyXP[todayKey] ?? 0;
    } catch (e) {
      print('Error loading daily XP: $e');
    }
    
    // Load today's trades from paper trading
    try {
      final trading = PaperTradingService();
      final todayTrades = trading.tradeHistory.where((trade) => 
        _isSameDay(trade.timestamp, today)
      ).length;
      _todayTrades = todayTrades;
    } catch (e) {
      print('Error loading today\'s trades: $e');
    }
    
    // Load today's completed lessons from database
    try {
      final completedActions = await DatabaseService.getCompletedActions();
      final today = DateTime.now();
      final Set<String> uniqueLessonIds = {};
      
      // Count unique lessons completed today (ignore duplicates like lesson_xxx_completed)
      for (final actionId in completedActions) {
        if (actionId.startsWith('lesson_')) {
          // Extract lesson ID (remove _completed, _skipped suffixes)
          String lessonId = actionId;
          if (lessonId.endsWith('_completed') || lessonId.endsWith('_skipped')) {
            lessonId = lessonId.substring(0, lessonId.lastIndexOf('_'));
          }
          
          // Check if this lesson was completed today (check the main lesson ID)
          final isCompletedToday = await DatabaseService.isActionCompletedToday(lessonId);
          if (isCompletedToday && !uniqueLessonIds.contains(lessonId)) {
            uniqueLessonIds.add(lessonId);
          }
        }
      }
      
      // Update lesson count from database (source of truth)
      _todayLessons = uniqueLessonIds.length;
    } catch (e) {
      print('Error loading today\'s lessons: $e');
    }
    
    notifyListeners();
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
           date1.month == date2.month &&
           date1.day == date2.day;
  }

  // Track XP earned
  void trackXP(int amount) {
    _todayXP += amount;
    
    // Update daily XP goal periodically (every 50 XP earned) to keep it challenging
    if (_todayXP % 50 == 0) {
      try {
        final gamification = GamificationService();
        updateDailyXPGoal(gamification);
      } catch (e) {
        print('Error updating daily XP goal: $e');
      }
    }
    
    _saveToDatabase();
    notifyListeners();
  }

  // Track trade made
  void trackTrade() {
    _todayTrades++;
    _saveToDatabase();
    notifyListeners();
  }

  // Track lesson completed
  void trackLesson() {
    _todayLessons++;
    _saveToDatabase();
    notifyListeners();
  }

  // Check if streak is at risk
  bool isStreakAtRisk(GamificationService gamification) {
    final today = DateTime.now();
    
    // If all goals are complete today, streak is NOT at risk
    if (areAllGoalsComplete) {
      return false;
    }
    
    // Check if there's any activity today (XP, trades, or lessons)
    final hasActivityToday = _todayXP > 0 || _todayTrades > 0 || _todayLessons > 0;
    
    // If no activity today and it's past 6 PM, streak is at risk
    if (!hasActivityToday && today.hour >= 18) {
      return true;
    }
    
    // Check last activity date from gamification service
    final dailyXPKeys = gamification.dailyXP.keys.toList();
    if (dailyXPKeys.isEmpty) {
      // No activity ever - streak is at risk if no goals completed today
      return !hasActivityToday;
    }
    
    final lastActivity = dailyXPKeys.last;
    final lastActivityDate = DateTime.parse(lastActivity);
    final daysSince = today.difference(lastActivityDate).inDays;
    
    // Streak is at risk if no activity for more than a day
    if (daysSince >= 1) {
      return true;
    }
    
    // If it's today but no goals complete and it's past 6 PM, streak is at risk
    if (daysSince == 0 && today.hour >= 18 && !areAllGoalsComplete) {
      return true;
    }
    
    return false;
  }

  // Get streak reminder message
  String getStreakReminderMessage(GamificationService gamification) {
    if (isStreakAtRisk(gamification)) {
      if (gamification.streak > 0) {
        return '🔥 Your ${gamification.streak}-day streak is at risk! Complete your daily goals to keep it alive!';
      } else {
        return '🎯 Start your streak today! Complete your daily goals!';
      }
    }
    return 'Great job! Keep up the momentum!';
  }

  // Get daily goals summary
  Map<String, dynamic> getDailyGoalsSummary() {
    return {
      'xp': {
        'current': _todayXP,
        'goal': _dailyXPGoal,
        'progress': xpProgress,
        'complete': isXPGoalComplete,
      },
      'trades': {
        'current': _todayTrades,
        'goal': _dailyTradeGoal,
        'progress': tradeProgress,
        'complete': isTradeGoalComplete,
      },
      'lessons': {
        'current': _todayLessons,
        'goal': _dailyLessonGoal,
        'progress': lessonProgress,
        'complete': isLessonGoalComplete,
      },
      'allComplete': areAllGoalsComplete,
    };
  }

  // Save to database
  Future<void> _saveToDatabase() async {
    try {
      await DatabaseService.saveDailyGoals({
        'dailyXPGoal': _dailyXPGoal,
        'dailyTradeGoal': _dailyTradeGoal,
        'dailyLessonGoal': _dailyLessonGoal,
        'todayXP': _todayXP,
        'todayTrades': _todayTrades,
        'todayLessons': _todayLessons,
        'lastCheckedDate': _lastCheckedDate?.toIso8601String(),
      });
    } catch (e) {
      print('Error saving daily goals: $e');
    }
  }

  // Load from database
  Future<void> _loadFromDatabase() async {
    try {
      final data = await DatabaseService.loadDailyGoals();
      if (data != null) {
        _dailyXPGoal = data['dailyXPGoal'] ?? 100;
        _dailyTradeGoal = data['dailyTradeGoal'] ?? 1;
        _dailyLessonGoal = data['dailyLessonGoal'] ?? 1;
        _lastCheckedDate = data['lastCheckedDate'] != null
            ? DateTime.parse(data['lastCheckedDate'])
            : null;
      }
    } catch (e) {
      print('Error loading daily goals: $e');
    }
    
    // Update progress after loading
    await _updateTodayProgress();
  }

  // Reset daily goals (for testing)
  void resetDailyGoals() {
    _todayXP = 0;
    _todayTrades = 0;
    _todayLessons = 0;
    _lastCheckedDate = DateTime.now();
    _saveToDatabase();
    notifyListeners();
  }
}

