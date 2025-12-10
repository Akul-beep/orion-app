import 'package:flutter/material.dart';
import 'dart:async';
import 'database_service.dart';

/// Service to track all user interactions, screen visits, and navigation
class UserProgressService {
  static final UserProgressService _instance = UserProgressService._internal();
  factory UserProgressService() => _instance;
  UserProgressService._internal();

  // Current session tracking
  String? _currentSessionId;
  DateTime? _sessionStartTime;
  String? _currentScreen;
  DateTime? _currentScreenStartTime;
  int _sessionScreenCount = 0;
  int _sessionInteractionCount = 0;
  final Map<String, int> _screenTimeSpent = {};

  // Navigation stack tracking
  final List<String> _navigationStack = [];

  /// Initialize a new session
  Future<void> startSession() async {
    _sessionStartTime = DateTime.now();
    _sessionScreenCount = 0;
    _sessionInteractionCount = 0;
    _screenTimeSpent.clear();
    _navigationStack.clear();

    try {
      final userId = await DatabaseService.getOrCreateLocalUserId();
      final sessionData = {
        'user_id': userId,
        'session_start': _sessionStartTime!.toIso8601String(),
        'total_screens_visited': 0,
        'total_interactions': 0,
        'session_data': {},
        'device_info': {
          'platform': 'mobile', // Could be enhanced with actual device info
        },
      };

      if (DatabaseService.isSupabaseAvailable) {
        final supabase = DatabaseService.getSupabaseClient();
        if (supabase != null) {
          try {
            final response = await supabase.from('user_sessions').insert(sessionData).select().single();
            _currentSessionId = response['id'] as String?;
          } catch (e) {
            print('Error creating session in Supabase: $e');
          }
        }
      }
    } catch (e) {
      print('Error starting session: $e');
    }
  }

  /// End current session
  Future<void> endSession() async {
    if (_sessionStartTime == null) return;

    try {
      final sessionEnd = DateTime.now();
      final sessionDuration = sessionEnd.difference(_sessionStartTime!).inSeconds;

      if (_currentSessionId != null && DatabaseService.isSupabaseAvailable) {
        final supabase = DatabaseService.getSupabaseClient();
        if (supabase != null && _currentSessionId != null) {
          await supabase.from('user_sessions').update({
            'session_end': sessionEnd.toIso8601String(),
            'total_screens_visited': _sessionScreenCount,
            'total_interactions': _sessionInteractionCount,
          }).eq('id', _currentSessionId!);
        }
      }

      // Update user progress
      await updateUserProgress(
        lastScreen: _currentScreen,
        lastScreenVisitedAt: sessionEnd,
      );
    } catch (e) {
      print('Error ending session: $e');
    }

    _currentSessionId = null;
    _sessionStartTime = null;
    _currentScreen = null;
    _currentScreenStartTime = null;
  }

  /// Track screen visit
  Future<void> trackScreenVisit({
    required String screenName,
    String? screenType,
    Map<String, dynamic>? metadata,
  }) async {
    final now = DateTime.now();
    
    // End previous screen timing
    if (_currentScreen != null && _currentScreenStartTime != null) {
      final timeSpent = now.difference(_currentScreenStartTime!).inSeconds;
      _screenTimeSpent[_currentScreen!] = 
          (_screenTimeSpent[_currentScreen!] ?? 0) + timeSpent;
      
      // Update previous screen visit with time spent
      await _updateScreenVisitTime(_currentScreen!, timeSpent);
    }

    // Start new screen timing
    _currentScreen = screenName;
    _currentScreenStartTime = now;
    _sessionScreenCount++;

    try {
      final userId = await DatabaseService.getOrCreateLocalUserId();
      final visitData = {
        'user_id': userId,
        'screen_name': screenName,
        'screen_type': screenType ?? 'main',
        'visited_at': now.toIso8601String(),
        'time_spent_seconds': 0, // Will be updated when leaving
        'metadata': metadata ?? {},
      };

      if (DatabaseService.isSupabaseAvailable) {
        final supabase = DatabaseService.getSupabaseClient();
        if (supabase != null) {
          await supabase.from('user_screen_visits').insert(visitData);
        }
      }

      // Update user progress
      await updateUserProgress(
        lastScreen: screenName,
        lastScreenVisitedAt: now,
      );
    } catch (e) {
      print('Error tracking screen visit: $e');
    }
  }

  /// Update screen visit with time spent
  Future<void> _updateScreenVisitTime(String screenName, int timeSpent) async {
    try {
      if (DatabaseService.isSupabaseAvailable) {
        final supabase = DatabaseService.getSupabaseClient();
        if (supabase != null) {
          final userId = await DatabaseService.getOrCreateLocalUserId();
          // Update the most recent visit for this screen
          await supabase
              .from('user_screen_visits')
              .update({'time_spent_seconds': timeSpent})
              .eq('user_id', userId)
              .eq('screen_name', screenName)
              .order('visited_at', ascending: false)
              .limit(1);
        }
      }
    } catch (e) {
      print('Error updating screen visit time: $e');
    }
  }

  /// Track widget interaction
  Future<void> trackWidgetInteraction({
    required String screenName,
    required String widgetType,
    required String actionType,
    String? widgetId,
    Map<String, dynamic>? interactionData,
  }) async {
    _sessionInteractionCount++;

    try {
      final userId = await DatabaseService.getOrCreateLocalUserId();
      final interactionRecord = {
        'user_id': userId,
        'screen_name': screenName,
        'widget_type': widgetType,
        'widget_id': widgetId,
        'action_type': actionType,
        'interaction_data': interactionData ?? {},
        'created_at': DateTime.now().toIso8601String(),
      };

      if (DatabaseService.isSupabaseAvailable) {
        final supabase = DatabaseService.getSupabaseClient();
        if (supabase != null) {
          await supabase.from('user_widget_interactions').insert(interactionRecord);
        }
      }
    } catch (e) {
      print('Error tracking widget interaction: $e');
    }
  }

  /// Track navigation flow
  Future<void> trackNavigation({
    String? fromScreen,
    required String toScreen,
    String? navigationMethod,
    Map<String, dynamic>? navigationData,
  }) async {
    // Update navigation stack
    if (fromScreen != null) {
      _navigationStack.add(fromScreen);
    }
    _navigationStack.add(toScreen);

    // Keep stack size reasonable
    if (_navigationStack.length > 20) {
      _navigationStack.removeAt(0);
    }

    try {
      final userId = await DatabaseService.getOrCreateLocalUserId();
      final navigationRecord = {
        'user_id': userId,
        'from_screen': fromScreen,
        'to_screen': toScreen,
        'navigation_method': navigationMethod ?? 'push',
        'navigation_data': navigationData ?? {},
        'created_at': DateTime.now().toIso8601String(),
      };

      if (DatabaseService.isSupabaseAvailable) {
        final supabase = DatabaseService.getSupabaseClient();
        if (supabase != null) {
          await supabase.from('user_navigation_flows').insert(navigationRecord);
        }
      }
    } catch (e) {
      print('Error tracking navigation: $e');
    }
  }

  /// Update user progress
  Future<void> updateUserProgress({
    String? lastScreen,
    DateTime? lastScreenVisitedAt,
    Map<String, dynamic>? learningProgress,
    Map<String, dynamic>? tradingProgress,
    Map<String, dynamic>? preferences,
  }) async {
    try {
      final userId = await DatabaseService.getOrCreateLocalUserId();
      
      // Get current progress
      final currentProgress = await DatabaseService.getUserProgress();
      
      // Update screen visit counts
      Map<String, dynamic> screensVisitedCount = 
          Map<String, dynamic>.from(currentProgress?['screens_visited_count'] ?? {});
      if (lastScreen != null) {
        screensVisitedCount[lastScreen] = (screensVisitedCount[lastScreen] ?? 0) + 1;
      }

      // Update time spent
      Map<String, dynamic> totalTimeSpent = 
          Map<String, dynamic>.from(currentProgress?['total_time_spent'] ?? {});
      _screenTimeSpent.forEach((screen, seconds) {
        totalTimeSpent[screen] = (totalTimeSpent[screen] ?? 0) + seconds;
      });

      final progressData = {
        'user_id': userId,
        'last_screen_visited': lastScreen ?? currentProgress?['last_screen_visited'],
        'last_screen_visited_at': lastScreenVisitedAt?.toIso8601String() ?? 
            currentProgress?['last_screen_visited_at'],
        'screens_visited_count': screensVisitedCount,
        'total_time_spent': totalTimeSpent,
        'learning_progress': learningProgress ?? currentProgress?['learning_progress'] ?? {},
        'trading_progress': tradingProgress ?? currentProgress?['trading_progress'] ?? {},
        'preferences': preferences ?? currentProgress?['preferences'] ?? {},
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (DatabaseService.isSupabaseAvailable) {
        final supabase = DatabaseService.getSupabaseClient();
        if (supabase != null) {
          await supabase.from('user_progress').upsert(progressData);
        }
      }
    } catch (e) {
      print('Error updating user progress: $e');
    }
  }

  /// Save state snapshot for a screen
  Future<void> saveStateSnapshot({
    required String screenName,
    required Map<String, dynamic> stateData,
  }) async {
    try {
      final userId = await DatabaseService.getOrCreateLocalUserId();
      final snapshotData = {
        'user_id': userId,
        'screen_name': screenName,
        'state_data': stateData,
        'created_at': DateTime.now().toIso8601String(),
      };

      if (DatabaseService.isSupabaseAvailable) {
        final supabase = DatabaseService.getSupabaseClient();
        if (supabase != null) {
          await supabase.from('user_state_snapshots').insert(snapshotData);
        }
      }
    } catch (e) {
      print('Error saving state snapshot: $e');
    }
  }

  /// Track learning progress
  Future<void> trackLearningProgress({
    required String lessonId,
    String? lessonName,
    String? moduleId,
    int? progressPercentage,
    int? timeSpentSeconds,
    bool? completed,
    Map<String, dynamic>? quizScores,
  }) async {
    try {
      final userId = await DatabaseService.getOrCreateLocalUserId();
      final progressData = {
        'user_id': userId,
        'lesson_id': lessonId,
        'lesson_name': lessonName,
        'module_id': moduleId,
        'progress_percentage': progressPercentage ?? 0,
        'time_spent_seconds': timeSpentSeconds ?? 0,
        'completed': completed ?? false,
        'completed_at': completed == true ? DateTime.now().toIso8601String() : null,
        'quiz_scores': quizScores ?? {},
        'last_accessed_at': DateTime.now().toIso8601String(),
      };

      if (DatabaseService.isSupabaseAvailable) {
        final supabase = DatabaseService.getSupabaseClient();
        if (supabase != null) {
          await supabase.from('learning_progress').upsert(
            progressData,
            onConflict: 'user_id,lesson_id',
          );
        }
      }
    } catch (e) {
      print('Error tracking learning progress: $e');
    }
  }

  /// Track trading activity
  Future<void> trackTradingActivity({
    required String activityType,
    String? symbol,
    Map<String, dynamic>? activityData,
  }) async {
    try {
      final userId = await DatabaseService.getOrCreateLocalUserId();
      final activityRecord = {
        'user_id': userId,
        'activity_type': activityType,
        'symbol': symbol,
        'activity_data': activityData ?? {},
        'created_at': DateTime.now().toIso8601String(),
      };

      if (DatabaseService.isSupabaseAvailable) {
        final supabase = DatabaseService.getSupabaseClient();
        if (supabase != null) {
          await supabase.from('trading_activity').insert(activityRecord);
        }
      }
    } catch (e) {
      print('Error tracking trading activity: $e');
    }
  }

  /// Get navigation stack
  List<String> getNavigationStack() => List.unmodifiable(_navigationStack);

  /// Get current screen
  String? getCurrentScreen() => _currentScreen;
}

