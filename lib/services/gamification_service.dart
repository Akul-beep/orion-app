import 'dart:math' show sqrt;
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'database_service.dart';
import 'daily_goals_service.dart';
import 'weekly_challenge_service.dart';
import 'monthly_challenge_service.dart';
import 'friend_quest_service.dart';
import 'push_notification_service.dart';
import 'email_sequence_service.dart';
import '../models/badge_definition.dart';

class GamificationService extends ChangeNotifier {
  // Static instance for service-to-service access (when Provider context not available)
  static GamificationService? _instance;
  static GamificationService? get instance => _instance;
  
  int _totalXP = 0;
  int _streak = 0;
  List<String> _badges = []; // Store badge IDs, not names
  int _level = 1;
  Map<String, int> _dailyXP = {};
  DateTime? _lastActivityDate;
  int _consecutiveLoginDays = 0;
  DateTime? _lastLoginDate;
  int _totalTrades = 0;
  int _lessonsCompleted = 0;
  int _perfectLessons = 0;
  int _consecutiveLearningDays = 0;
  DateTime? _lastLearningDate;
  DateTime? _accountCreatedDate;
  bool _isInitialized = false;
  
  GamificationService() {
    _instance = this;
  }
  
  // Initialize and load data from database
  // This should be called early in app lifecycle
  Future<void> initialize() async {
    if (_isInitialized) return;
    await loadFromDatabase();
    _isInitialized = true;
  }

  // Getters
  int get totalXP => _totalXP;
  int get xp => _totalXP; // Alias for UI compatibility
  int get streak => _streak;
  List<String> get badges => _badges;
  int get level => _level;
  Map<String, int> get dailyXP => _dailyXP;
  int get consecutiveLoginDays => _consecutiveLoginDays;
  int get totalTrades => _totalTrades;
  DateTime? get lastActivityDate => _lastActivityDate; // For notification service
  
  // Daily Login Bonus
  bool _hasReceivedTodayBonus = false;
  bool get hasReceivedTodayBonus => _hasReceivedTodayBonus;
  
  // Milestone tracking
  int get milestoneLevel => (_level / 10).floor() * 10;
  int get milestoneTrades => (_totalTrades / 50).floor() * 50;
  int get lessonsCompleted => _lessonsCompleted;
  int get perfectLessons => _perfectLessons;
  
  /// Calculate level from XP using Duolingo-style exponential progression
  /// Formula: Level = floor(sqrt(XP / 10)) + 1
  /// This makes it harder to level up as you progress
  /// Example: 0-9 XP = Level 1, 10-39 XP = Level 2, 40-89 XP = Level 3, etc.
  static int calculateLevelFromXP(int xp) {
    if (xp <= 0) return 1;
    // Duolingo-style: exponential curve using square root
    // Each level requires more XP than the previous
    final level = (sqrt(xp / 10.0) + 1).floor();
    return level.clamp(1, 999);
  }
  
  /// Calculate XP required for a specific level
  /// Reverse of calculateLevelFromXP: XP = 10 * (level - 1)^2
  static int calculateXPForLevel(int level) {
    if (level <= 1) return 0;
    return (10 * (level - 1) * (level - 1)).round();
  }

  // XP Management
  void addXP(int amount, String source) {
    _totalXP += amount;
    
    // Track daily XP
    final today = DateTime.now().toIso8601String().split('T')[0];
    _dailyXP[today] = (_dailyXP[today] ?? 0) + amount;
    
    // Track in daily goals service
    try {
      DailyGoalsService().trackXP(amount);
    } catch (e) {
      print('Error tracking XP in daily goals: $e');
    }
    
        // Track in weekly challenge service
        try {
          WeeklyChallengeService().trackProgress('xp', amount);
        } catch (e) {
          print('⚠️ Error tracking XP in weekly challenge: $e');
        }
        
        // Track in monthly challenge service
        try {
          MonthlyChallengeService().trackProgress('xp', amount);
        } catch (e) {
          print('⚠️ Error tracking XP in monthly challenge: $e');
        }
        
        // Track in friend quest service
        try {
          FriendQuestService().trackProgress('xp', amount);
        } catch (e) {
          print('⚠️ Error tracking XP in friend quest: $e');
        }
    
    // Check for level up
    _checkLevelUp();
    
    // Update streak
    _updateStreak();
    
    // Check for badge achievements (XP-based badges)
    _checkBadgeAchievements();
    
    // Save to database
    _saveToDatabase();
    
    // Update leaderboard
    updateLeaderboard();
    
    // Update daily goals XP target if level changed
    if (_previousLevel != null && _level > _previousLevel!) {
      try {
        final dailyGoals = DailyGoalsService();
        dailyGoals.updateDailyXPGoal(this);
        print('📊 Daily XP goal updated after level up: ${dailyGoals.dailyXPGoal} XP (Level $_level)');
      } catch (e) {
        print('Error updating daily XP goal: $e');
      }
    }
    
    notifyListeners();
  }
  
  Future<void> _saveToDatabase() async {
    try {
      print('💾 Saving gamification data to database: ${_totalXP} XP, ${_streak} streak, ${_totalTrades} trades');
      await DatabaseService.saveGamificationData(toJson());
      print('✅ Gamification data saved successfully to Supabase');
    } catch (e) {
      print('❌ Error saving gamification data: $e');
    }
  }
  
  /// Update leaderboard entry with current stats (public method)
  /// [portfolioValue] - Optional portfolio value to use (if not provided, will try to get from database)
  Future<void> updateLeaderboard({double? portfolioValue}) async {
    try {
      // Use authenticated user ID if available
      final supabase = DatabaseService.getSupabaseClient();
      String userId;
      
      if (supabase != null && supabase.auth.currentUser != null) {
        userId = supabase.auth.currentUser!.id;
        print('📊 Updating leaderboard for authenticated user: $userId');
      } else {
        userId = await DatabaseService.getOrCreateLocalUserId();
        print('📊 Updating leaderboard for local user: $userId');
        // Don't update if not authenticated (local users won't show in leaderboard)
        if (userId.startsWith('local_')) {
          print('⚠️ User not authenticated - skipping leaderboard update');
          return;
        }
      }
      
      // Get user's display name from profile
      final profile = await DatabaseService.loadUserProfile();
      String displayName = 'User';
      
      // Try to get name from profile
      if (profile != null) {
        displayName = profile['displayName'] ?? 
                     profile['name'] ?? 
                     profile['display_name'] ?? 
                     'User';
      }
      
      // Try to get name from auth if profile doesn't have it
      if (displayName == 'User' && supabase != null && supabase.auth.currentUser != null) {
        final user = supabase.auth.currentUser;
        displayName = user?.userMetadata?['display_name'] ?? 
                     user?.userMetadata?['name'] ??
                     (user?.email != null ? user!.email!.split('@')[0] : 'User');
      }
      
      // Get portfolio value - use provided value first, otherwise try database
      // Always ensure it's at least $10,000 (starting balance) to prevent $0 display
      double finalPortfolioValue = 10000.0; // Default starting balance
      
      if (portfolioValue != null && portfolioValue > 0) {
        finalPortfolioValue = portfolioValue;
      } else {
        // Try to get from database
        try {
          final portfolio = await DatabaseService.loadPortfolio();
          if (portfolio != null && portfolio['totalValue'] != null) {
            final dbValue = (portfolio['totalValue'] as num).toDouble();
            if (dbValue > 0) {
              finalPortfolioValue = dbValue;
            }
          }
        } catch (e) {
          print('⚠️ Could not get portfolio value for leaderboard: $e');
        }
      }
      
      print('📊 Updating leaderboard: $displayName - XP: $_totalXP, Level: $_level, Streak: $_streak, Portfolio: \$${finalPortfolioValue.toStringAsFixed(2)}');
      
      await DatabaseService.updateLeaderboardEntry(
        userId: userId,
        displayName: displayName,
        xp: _totalXP,
        streak: _streak,
        level: _level,
        badges: _badges.length,
        portfolioValue: finalPortfolioValue,
      );
      
      print('✅ Leaderboard updated successfully with portfolio: \$${finalPortfolioValue.toStringAsFixed(2)}');
    } catch (e, stackTrace) {
      print('❌ Error updating leaderboard: $e');
      print('Stack trace: $stackTrace');
    }
  }
  
  // Load from database
  Future<void> loadFromDatabase() async {
    try {
      final data = await DatabaseService.loadGamificationData();
      if (data != null) {
        fromJson(data);
        // Recalculate level from XP (in case formula changed)
        _level = calculateLevelFromXP(_totalXP);
        // Validate streak after loading - check if we need to update it
        _validateStreakOnLoad();
        // Validate learning streak after loading - reset if days were missed
        _validateLearningStreakOnLoad();
        // Load lesson completion count from database
        await _loadLessonStats();
      } else {
        // First time - set account creation date
        _accountCreatedDate = DateTime.now();
      }
      // Check for daily login bonus
      _checkDailyLoginBonus();
      // Check for badges after loading
      _checkBadgeAchievements();
    } catch (e) {
      print('Error loading gamification data: $e');
    }
  }
  
  /// Load lesson completion stats from database
  Future<void> _loadLessonStats() async {
    try {
      final completedActions = await DatabaseService.getCompletedActions();
      // Count lesson completions
      _lessonsCompleted = completedActions.where((action) => 
        action.startsWith('lesson_') && action.endsWith('_completed')
      ).length;
      
      // TODO: Track perfect lessons separately if needed
      // For now, we'll need to add this tracking when lessons are completed
    } catch (e) {
      print('Error loading lesson stats: $e');
    }
  }
  
  // Validate streak when loading from database
  // This ensures the streak is correct based on the last activity date
  // BUT don't reset streak - just validate it's correct
  void _validateStreakOnLoad() {
    final today = DateTime.now();
    final todayDay = DateTime(today.year, today.month, today.day);
    
    if (_lastActivityDate == null) {
      // No previous activity - if streak exists, it might be from before
      // Don't reset it - just leave it as is (might be valid)
      return;
    }
    
    // Normalize last activity date to just the day
    final lastActivityDay = DateTime(_lastActivityDate!.year, _lastActivityDate!.month, _lastActivityDate!.day);
    final difference = todayDay.difference(lastActivityDay).inDays;
    
    if (difference == 0) {
      // Last activity was today - streak is correct, no change needed
      return;
    } else if (difference == 1) {
      // Last activity was yesterday - streak should be current value (correct)
      // When user does activity today, it will increment
      return;
    } else if (difference > 1) {
      // Streak broken - but DON'T reset here, let _updateStreak handle it when user does activity
      // This prevents data loss on app load
      return;
    }
  }
  
  /// Validate learning streak when loading from database
  /// This ONLY validates and resets if needed - it NEVER increments the streak
  /// The streak will only increment when trackLessonCompletion() is called
  /// CRITICAL: If streak is broken, reset to 0 immediately so user sees it's broken
  void _validateLearningStreakOnLoad() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day); // Normalize to midnight
    
    print('🔍 ========== VALIDATE LEARNING STREAK ON LOAD ==========');
    print('🔍 Current streak: $_consecutiveLearningDays');
    print('🔍 Last learning date: $_lastLearningDate');
    print('🔍 Today: $today');
    
    // Case 1: No previous learning date but streak exists (invalid state)
    if (_lastLearningDate == null) {
      if (_consecutiveLearningDays > 0) {
        print('🔥 FIXING: No learning date but streak exists - resetting streak to 0');
        _consecutiveLearningDays = 0;
        _saveToDatabase();
        notifyListeners();
      }
      print('🔍 ========== VALIDATION DONE ==========');
      return;
    }
    
    // Normalize last learning date to midnight
    final lastDate = DateTime(_lastLearningDate!.year, _lastLearningDate!.month, _lastLearningDate!.day);
    final daysDiff = today.difference(lastDate).inDays;
    
    print('🔍 Days since last learning: $daysDiff');
    
    // Case 2: Last learning was today - streak is valid (they completed a lesson today)
    if (daysDiff == 0) {
      print('✅ Streak valid: Completed lesson today, streak is correct at $_consecutiveLearningDays');
      print('🔍 ========== VALIDATION DONE ==========');
      return;
    }
    
    // Case 3: Last learning was yesterday - streak is valid (will increment when they complete today)
    if (daysDiff == 1) {
      print('✅ Streak valid: Last lesson was yesterday, streak is $_consecutiveLearningDays (will increment when lesson completed today)');
      print('🔍 ========== VALIDATION DONE ==========');
      return;
    }
    
    // Case 4: Streak broken - missed days - RESET TO 0 IMMEDIATELY
    if (daysDiff > 1) {
      if (_consecutiveLearningDays > 0) {
        final oldStreak = _consecutiveLearningDays;
        print('🔥 STREAK BROKEN: Missed ${daysDiff - 1} day(s) - resetting streak from $oldStreak to 0');
        _consecutiveLearningDays = 0;
        // Keep lastLearningDate so we know when they last completed a lesson
        // Don't set to null - we need it to calculate the new streak when they complete
        _saveToDatabase();
        notifyListeners();
      } else {
        print('✅ Streak already at 0 (broken)');
      }
      print('🔍 ========== VALIDATION DONE ==========');
      return;
    }
    
    // Case 5: Future date (shouldn't happen)
    if (daysDiff < 0) {
      print('⚠️ FIXING: Last learning date is in the future - resetting streak to 0');
      _consecutiveLearningDays = 0;
      _lastLearningDate = null;
      _saveToDatabase();
      notifyListeners();
      print('🔍 ========== VALIDATION DONE ==========');
      return;
    }
    
    print('🔍 ========== VALIDATION DONE ==========');
  }

  // Daily Login Bonus System
  void _checkDailyLoginBonus() {
    final today = DateTime.now();
    if (_lastLoginDate == null) {
      // First login ever
      _consecutiveLoginDays = 1;
      _lastLoginDate = today;
      _hasReceivedTodayBonus = false;
    } else {
      final difference = today.difference(_lastLoginDate!).inDays;
      if (difference == 0) {
        // Same day - already received bonus
        _hasReceivedTodayBonus = true;
      } else if (difference == 1) {
        // Consecutive day
        _consecutiveLoginDays++;
        _lastLoginDate = today;
        _hasReceivedTodayBonus = false;
      } else {
        // Broken streak
        _consecutiveLoginDays = 1;
        _lastLoginDate = today;
        _hasReceivedTodayBonus = false;
      }
    }
  }

  // Award daily login bonus
  int? awardDailyLoginBonus() {
    if (_hasReceivedTodayBonus) return null;
    
    _checkDailyLoginBonus();
    if (_hasReceivedTodayBonus) return null;

    // Calculate bonus based on consecutive days
    int bonus = 10; // Base bonus
    if (_consecutiveLoginDays >= 7) bonus = 50;
    else if (_consecutiveLoginDays >= 3) bonus = 30;
    
    addXP(bonus, 'daily_login');
    _hasReceivedTodayBonus = true;
    _saveToDatabase();
    
    return bonus;
  }

  // Track trade count
  void trackTrade() {
    _totalTrades++;
    print('📈 Trade tracked: Total trades = $_totalTrades');
    _checkTradeMilestones();
    // Update streak for trading activity
    _updateStreak();
    
        // Track in weekly challenge service
        try {
          WeeklyChallengeService().trackProgress('trade', 1);
        } catch (e) {
          print('⚠️ Error tracking trade in weekly challenge: $e');
        }
        
        // Track in monthly challenge service
        try {
          MonthlyChallengeService().trackProgress('trade', 1);
        } catch (e) {
          print('⚠️ Error tracking trade in monthly challenge: $e');
        }
        
        // Track in friend quest service
        try {
          FriendQuestService().trackProgress('trade', 1);
        } catch (e) {
          print('⚠️ Error tracking trade in friend quest: $e');
        }
    
    _saveToDatabase();
    notifyListeners();
  }

  void _checkTradeMilestones() {
    // Trade milestones are now handled by the smart badge checking system
    _checkBadgeAchievements();
  }
  
  /// Track lesson completion
  /// CRITICAL: This is the ONLY place where learning streak should be updated
  /// Streak ONLY increments when a lesson is COMPLETED, never when opened
  void trackLessonCompletion({bool isPerfect = false}) {
    print('📚 ========== LESSON COMPLETION ==========');
    print('📚 trackLessonCompletion called - updating learning streak');
    
    _lessonsCompleted++;
    if (isPerfect) {
      _perfectLessons++;
    }
    
    // CRITICAL: First check if streak should be reset (before updating)
    // This ensures we detect broken streaks BEFORE completing the lesson
    _checkAndResetBrokenStreak();
    
    // CRITICAL: Update learning streak ONLY when lesson is completed
    _updateLearningStreak();
    
        // Track in weekly challenge service
        try {
          WeeklyChallengeService().trackProgress('lesson', 1);
        } catch (e) {
          print('⚠️ Error tracking lesson in weekly challenge: $e');
        }
        
        // Track in monthly challenge service
        try {
          MonthlyChallengeService().trackProgress('lesson', 1);
        } catch (e) {
          print('⚠️ Error tracking lesson in monthly challenge: $e');
        }
        
        // Track in friend quest service
        try {
          FriendQuestService().trackProgress('lesson', 1);
        } catch (e) {
          print('⚠️ Error tracking lesson in friend quest: $e');
        }
        
        // Track perfect lessons for Perfect Score Challenge
        if (isPerfect) {
          try {
            WeeklyChallengeService().trackProgress('perfect_lesson', 1);
            print('⭐ Perfect lesson tracked for Perfect Score Challenge');
          } catch (e) {
            print('⚠️ Error tracking perfect lesson: $e');
          }
        }
    
    // Check for badge achievements
    _checkBadgeAchievements();
    
    _saveToDatabase();
    notifyListeners();
    print('📚 ========== LESSON COMPLETION DONE ==========');
  }
  
  /// Check if streak is broken and reset to 0 BEFORE completing lesson
  /// This ensures the streak shows as broken (0) before it becomes 1
  void _checkAndResetBrokenStreak() {
    if (_lastLearningDate == null) {
      // No previous learning - streak should be 0
      if (_consecutiveLearningDays > 0) {
        print('🔥 RESET: No learning date but streak exists - resetting to 0');
        _consecutiveLearningDays = 0;
        _saveToDatabase();
        notifyListeners();
      }
      return;
    }
    
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final lastDate = DateTime(_lastLearningDate!.year, _lastLearningDate!.month, _lastLearningDate!.day);
    final daysDiff = today.difference(lastDate).inDays;
    
    // If more than 1 day has passed, streak is broken - reset to 0
    if (daysDiff > 1) {
      if (_consecutiveLearningDays > 0) {
        print('🔥 STREAK BROKEN: Missed ${daysDiff - 1} day(s) - resetting streak from $_consecutiveLearningDays to 0');
        _consecutiveLearningDays = 0;
        _saveToDatabase();
        notifyListeners();
      }
    }
  }
  
  /// Update learning streak (separate from general activity streak)
  /// CRITICAL: This is ONLY called from trackLessonCompletion() when a lesson is COMPLETED
  /// This function will NEVER be called when just opening a lesson
  void _updateLearningStreak() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day); // Normalize to midnight
    
    print('🔥 ========== UPDATE LEARNING STREAK ==========');
    print('🔥 Current streak: $_consecutiveLearningDays');
    print('🔥 Last learning date: $_lastLearningDate');
    print('🔥 Today: $today');
    
    // Case 1: First lesson ever completed OR streak was reset to 0
    if (_lastLearningDate == null || _consecutiveLearningDays == 0) {
      _consecutiveLearningDays = 1;
      _lastLearningDate = today;
      print('🔥 Learning streak STARTED: 0 → 1 day (lesson completed today)');
      _saveToDatabase();
      notifyListeners();
      _checkBadgeAchievements();
      return;
    }
    
    // Normalize last learning date to midnight for accurate comparison
    final lastDate = DateTime(_lastLearningDate!.year, _lastLearningDate!.month, _lastLearningDate!.day);
    
    // Calculate days difference (positive = days since last learning)
    final daysDiff = today.difference(lastDate).inDays;
    
    print('🔥 Days since last learning: $daysDiff');
    
    // Case 2: Completed lesson on the same day (multiple lessons in one day)
    if (daysDiff == 0) {
      // Already completed a lesson today - don't increment streak again
      // Just ensure date is set correctly
      if (_lastLearningDate != today) {
        _lastLearningDate = today;
        _saveToDatabase();
      }
      print('✅ Multiple lessons today - streak stays at $_consecutiveLearningDays days');
      return;
    }
    
    // Case 3: Consecutive day (completed lesson yesterday, completing today)
    if (daysDiff == 1) {
      final oldStreak = _consecutiveLearningDays;
      _consecutiveLearningDays++;
      _lastLearningDate = today;
      print('🔥 Learning streak INCREMENTED: $oldStreak → $_consecutiveLearningDays days (consecutive day)');
      _saveToDatabase();
      notifyListeners();
      _checkBadgeAchievements();
      return;
    }
    
    // Case 4: Streak broken (missed one or more days)
    // This should have been caught by _checkAndResetBrokenStreak, but handle it here too
    if (daysDiff > 1) {
      final previousStreak = _consecutiveLearningDays;
      _consecutiveLearningDays = 1; // Start new streak at 1 (completed lesson today)
      _lastLearningDate = today;
      print('🔥 Learning streak RESET: Was $previousStreak days, missed ${daysDiff - 1} day(s), starting new streak at 1');
      _saveToDatabase();
      notifyListeners();
      _checkBadgeAchievements();
      return;
    }
    
    // Case 5: Future date (shouldn't happen, but handle it)
    if (daysDiff < 0) {
      print('⚠️ WARNING: Last learning date is in the future! Resetting streak.');
      _consecutiveLearningDays = 1;
      _lastLearningDate = today;
      _saveToDatabase();
      notifyListeners();
      return;
    }
    
    print('🔥 ========== UPDATE LEARNING STREAK DONE ==========');
  }

  int? _previousLevel;
  
  void _checkLevelUp() {
    final newLevel = calculateLevelFromXP(_totalXP);
    if (newLevel > _level) {
      _previousLevel = _level;
      _level = newLevel;
      
      // Send level up notification (fire-and-forget)
      PushNotificationService().showLevelUp(_level).catchError((e) {
        print('⚠️ Error sending level up notification: $e');
      });
      
      // Send level up email
      _sendLevelUpEmail(_level, _previousLevel ?? 1, _totalXP).catchError((e) {
        print('⚠️ Error sending level up email: $e');
      });
      
      // NO automatic badge on level up - badges are earned through achievements only
      // Check for milestone badges (level-based achievements)
      _checkBadgeAchievements();
      
      notifyListeners();
    }
  }
  
  bool get hasLeveledUp {
    return _previousLevel != null && _previousLevel! < _level;
  }
  
  void clearLevelUpFlag() {
    _previousLevel = null;
  }

  void _updateStreak() {
    final today = DateTime.now();
    final todayDay = DateTime(today.year, today.month, today.day);
    
    if (_lastActivityDate == null) {
      // First activity ever - start streak at 1
      _streak = 1;
      _lastActivityDate = todayDay;
      
      // Track in weekly challenge service
      try {
        WeeklyChallengeService().trackProgress('streak', _streak);
      } catch (e) {
        print('⚠️ Error tracking streak in weekly challenge: $e');
      }
      
      _saveToDatabase();
      notifyListeners();
      print('🔥 Streak started: 1 day');
      return;
    }
    
    // Normalize last activity date to just the day (no time)
    final lastActivityDay = DateTime(_lastActivityDate!.year, _lastActivityDate!.month, _lastActivityDate!.day);
    final difference = todayDay.difference(lastActivityDay).inDays;
    
    if (difference == 0) {
      // Same day - don't update streak, just update the time
      // This prevents multiple streak increments on the same day
      _lastActivityDate = todayDay;
      // Don't save or notify - no change needed
      return;
    } else if (difference == 1) {
      // Consecutive day - increment streak
      _streak++;
      _lastActivityDate = todayDay;
      print('🔥 Streak updated: $_streak days (consecutive)');
      
      // Send streak milestone notification for significant milestones
      if (_streak == 7 || _streak == 14 || _streak == 30 || _streak == 100) {
        PushNotificationService().showStreakMilestone(_streak).catchError((e) {
          print('⚠️ Error sending streak milestone notification: $e');
        });
        
        // Send streak milestone email
        _sendStreakMilestoneEmail(_streak).catchError((e) {
          print('⚠️ Error sending streak milestone email: $e');
        });
      }
      
      // Track in weekly challenge service (pass current streak value)
      try {
        WeeklyChallengeService().trackProgress('streak', _streak);
      } catch (e) {
        print('⚠️ Error tracking streak in weekly challenge: $e');
      }
      
      // Check for streak-based badges
      _checkBadgeAchievements();
      _saveToDatabase();
      notifyListeners();
    } else if (difference > 1) {
      // Streak broken - save previous streak for notification
      final previousStreak = _streak;
      
      // Reset to 1 (first activity of new streak)
      _streak = 1;
      _lastActivityDate = todayDay;
      print('🔥 Streak reset: 1 day (broken, gap of $difference days)');
      
      // Send streak lost notification if there was a previous streak
      if (previousStreak > 0) {
        try {
          PushNotificationService().showStreakLostNotification(previousStreak);
        } catch (e) {
          print('⚠️ Error sending streak lost notification: $e');
        }
        
        // Send streak lost email
        _sendStreakLostEmail(previousStreak).catchError((e) {
          print('⚠️ Error sending streak lost email: $e');
        });
      }
      
      // Track in weekly challenge service (pass current streak value)
      try {
        WeeklyChallengeService().trackProgress('streak', _streak);
      } catch (e) {
        print('⚠️ Error tracking streak in weekly challenge: $e');
      }
      
      _saveToDatabase();
      notifyListeners();
    }
    // If difference < 0, something's wrong with dates, don't update
  }

  // Badge Management
  void _addBadgeById(String badgeId) {
    if (!_badges.contains(badgeId)) {
      _badges.add(badgeId);
      notifyListeners();
    }
  }

  String? _lastUnlockedBadgeId;
  
  /// Unlock a badge by ID (from BadgeDefinitions)
  void unlockBadgeById(String badgeId) {
    if (!_badges.contains(badgeId)) {
      final badge = BadgeDefinitions.getBadgeById(badgeId);
      if (badge != null) {
        _lastUnlockedBadgeId = badgeId;
        _addBadgeById(badgeId);
        
        // Send achievement notification (fire-and-forget)
        PushNotificationService().showAchievementUnlocked(badge.name, badge.description).catchError((e) {
          print('⚠️ Error sending achievement notification: $e');
        });
        
        // Send achievement unlocked email
        _sendAchievementUnlockedEmail(badge.name, badge.description).catchError((e) {
          print('⚠️ Error sending achievement unlocked email: $e');
        });
        
        // Award XP reward if badge has one
        if (badge.xpReward > 0) {
          addXP(badge.xpReward, 'badge_reward');
        }
        
        print('🏆 Badge unlocked: ${badge.name} (${badge.emoji})');
        notifyListeners();
      }
    }
  }
  
  /// Legacy method for backward compatibility - converts badge name to ID
  /// This should be phased out in favor of unlockBadgeById
  void unlockBadge(String badgeName) {
    // Try to find badge by name (for legacy code)
    final badge = BadgeDefinitions.allBadges.firstWhere(
      (b) => b.name == badgeName,
      orElse: () => BadgeDefinition(
        id: badgeName.toLowerCase().replaceAll(' ', '_'),
        name: badgeName,
        description: '',
        emoji: '🏆',
        category: BadgeCategory.special,
        rarity: BadgeRarity.common,
        requirements: {},
      ),
    );
    unlockBadgeById(badge.id);
  }
  
  String? get lastUnlockedBadgeId => _lastUnlockedBadgeId;
  
  /// Get the last unlocked badge definition
  BadgeDefinition? get lastUnlockedBadge {
    if (_lastUnlockedBadgeId == null) return null;
    return BadgeDefinitions.getBadgeById(_lastUnlockedBadgeId!);
  }
  
  void clearLastBadge() {
    _lastUnlockedBadgeId = null;
  }
  
  /// Get all unlocked badge definitions
  List<BadgeDefinition> get unlockedBadgeDefinitions {
    return _badges
        .map((id) => BadgeDefinitions.getBadgeById(id))
        .where((badge) => badge != null)
        .cast<BadgeDefinition>()
        .toList();
  }
  
  /// Get badges by category
  List<BadgeDefinition> getBadgesByCategory(BadgeCategory category) {
    return unlockedBadgeDefinitions.where((badge) => badge.category == category).toList();
  }

  // Streak Management
  void resetStreak() {
    _streak = 0;
    notifyListeners();
  }

  // Daily XP Cap
  bool canEarnXP(String source, int amount) {
    final today = DateTime.now().toIso8601String().split('T')[0];
    final todayXP = _dailyXP[today] ?? 0;
    
    // Daily cap for regular activities
    // Note: lesson_repeat has no cap (encourages practice)
    if (source == 'lesson' && todayXP >= 300) return false; // Increased cap for lessons
    if (source == 'lesson_repeat') return true; // No cap for practice mode
    if (source == 'trading' && todayXP >= 200) return false; // Increased cap for trading (was 100)
    if (source == 'streak' && todayXP >= 25) return false;
    
    return true;
  }

  /// Smart badge checking system - checks all badge requirements
  /// This is called whenever stats change (XP, lessons, trades, streaks, etc.)
  void _checkBadgeAchievements() {
    // Get current user stats
    final userStats = _getUserStats();
    
    // Check all badge definitions
    for (final badge in BadgeDefinitions.allBadges) {
      // Skip if already unlocked
      if (_badges.contains(badge.id)) continue;
      
      // Check if user meets requirements
      if (badge.checkRequirements(userStats)) {
        unlockBadgeById(badge.id);
      }
    }
  }
  
  /// Get current user stats for badge checking
  Map<String, dynamic> _getUserStats() {
    final now = DateTime.now();
    final daysSinceJoin = _accountCreatedDate != null
        ? now.difference(_accountCreatedDate!).inDays
        : 0;
    
    return {
      'totalXP': _totalXP,
      'level': _level,
      'streak': _streak,
      'totalTrades': _totalTrades,
      'lessonsCompleted': _lessonsCompleted,
      'perfectLessons': _perfectLessons,
      'consecutiveLearningDays': _consecutiveLearningDays,
      'daysSinceJoin': daysSinceJoin,
    };
  }
  
  /// Legacy method for backward compatibility
  void checkAchievements() {
    _checkBadgeAchievements();
  }

  // Social Features
  Map<String, dynamic> getLeaderboardData() {
    return {
      'totalXP': _totalXP,
      'streak': _streak,
      'level': _level,
      'badges': _badges.length,
      'rank': _calculateRank(),
    };
  }

  int _calculateRank() {
    // Simple ranking based on XP and streak
    return (_totalXP / 100).floor() + (_streak * 10);
  }

  // Progress Tracking
  double getProgressToNextLevel() {
    final currentLevelXP = calculateXPForLevel(_level);
    final nextLevelXP = calculateXPForLevel(_level + 1);
    final progress = (_totalXP - currentLevelXP) / (nextLevelXP - currentLevelXP);
    return progress.clamp(0.0, 1.0);
  }

  int getXPToNextLevel() {
    final nextLevelXP = calculateXPForLevel(_level + 1);
    return (nextLevelXP - _totalXP).clamp(0, double.infinity).toInt();
  }
  
  int getXPForCurrentLevel() {
    return calculateXPForLevel(_level);
  }

  // Reset for testing
  void reset() {
    _totalXP = 0;
    _streak = 0;
    _badges.clear();
    _level = 1;
    _dailyXP.clear();
    _lastActivityDate = null;
    _lessonsCompleted = 0;
    _perfectLessons = 0;
    _consecutiveLearningDays = 0;
    _lastLearningDate = null;
    _totalTrades = 0;
    notifyListeners();
  }

  // Save/Load state
  Map<String, dynamic> toJson() {
    return {
      'totalXP': _totalXP,
      'streak': _streak,
      'badges': _badges,
      'level': _level,
      'dailyXP': _dailyXP,
      'lastActivityDate': _lastActivityDate?.toIso8601String(),
      'consecutiveLoginDays': _consecutiveLoginDays,
      'lastLoginDate': _lastLoginDate?.toIso8601String(),
      'hasReceivedTodayBonus': _hasReceivedTodayBonus,
      'totalTrades': _totalTrades,
      'lessonsCompleted': _lessonsCompleted,
      'perfectLessons': _perfectLessons,
      'consecutiveLearningDays': _consecutiveLearningDays,
      'lastLearningDate': _lastLearningDate?.toIso8601String(),
      'accountCreatedDate': _accountCreatedDate?.toIso8601String(),
    };
  }

  // Email helper methods
  Future<void> _sendLevelUpEmail(int level, int previousLevel, int xp) async {
    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;
      if (user?.email != null) {
        await EmailSequenceService.sendLevelUpEmail(
          userId: user!.id,
          email: user.email!,
          level: level,
          previousLevel: previousLevel,
          xp: xp,
        );
      }
    } catch (e) {
      print('⚠️ Error in _sendLevelUpEmail: $e');
    }
  }

  Future<void> _sendStreakMilestoneEmail(int streak) async {
    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;
      if (user?.email != null) {
        await EmailSequenceService.sendStreakMilestoneEmail(
          userId: user!.id,
          email: user.email!,
          streak: streak,
        );
      }
    } catch (e) {
      print('⚠️ Error in _sendStreakMilestoneEmail: $e');
    }
  }

  Future<void> _sendStreakLostEmail(int previousStreak) async {
    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;
      if (user?.email != null) {
        await EmailSequenceService.sendStreakLostEmail(
          userId: user!.id,
          email: user.email!,
          previousStreak: previousStreak,
        );
      }
    } catch (e) {
      print('⚠️ Error in _sendStreakLostEmail: $e');
    }
  }

  Future<void> _sendAchievementUnlockedEmail(String achievementName, String achievementDescription) async {
    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;
      if (user?.email != null) {
        await EmailSequenceService.sendAchievementUnlockedEmail(
          userId: user!.id,
          email: user.email!,
          achievementName: achievementName,
          achievementDescription: achievementDescription,
        );
      }
    } catch (e) {
      print('⚠️ Error in _sendAchievementUnlockedEmail: $e');
    }
  }

  void fromJson(Map<String, dynamic> json) {
    _totalXP = json['totalXP'] ?? 0;
    _streak = json['streak'] ?? 0;
    _badges = List<String>.from(json['badges'] ?? []);
    _level = json['level'] ?? 1;
    _dailyXP = Map<String, int>.from(json['dailyXP'] ?? {});
    _lastActivityDate = json['lastActivityDate'] != null 
        ? DateTime.parse(json['lastActivityDate']) 
        : null;
    _consecutiveLoginDays = json['consecutiveLoginDays'] ?? 0;
    _lastLoginDate = json['lastLoginDate'] != null
        ? DateTime.parse(json['lastLoginDate'])
        : null;
    _hasReceivedTodayBonus = json['hasReceivedTodayBonus'] ?? false;
    _totalTrades = json['totalTrades'] ?? 0;
    _lessonsCompleted = json['lessonsCompleted'] ?? 0;
    _perfectLessons = json['perfectLessons'] ?? 0;
    _consecutiveLearningDays = json['consecutiveLearningDays'] ?? 0;
    _lastLearningDate = json['lastLearningDate'] != null
        ? DateTime.parse(json['lastLearningDate'])
        : null;
    _accountCreatedDate = json['accountCreatedDate'] != null
        ? DateTime.parse(json['accountCreatedDate'])
        : null;
    notifyListeners();
  }
}
