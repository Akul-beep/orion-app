import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:html' as html;
import 'dart:async';
import '../services/database_service.dart';
import '../services/gamification_service.dart';
import '../services/daily_goals_service.dart';

/// Web Browser Notification Service
/// Implements push notifications for web platform using browser Notification API
class WebNotificationService {
  static final WebNotificationService _instance = WebNotificationService._internal();
  factory WebNotificationService() => _instance;
  WebNotificationService._internal();

  bool _permissionRequested = false;
  bool _permissionGranted = false;

  /// Request notification permission for web
  Future<bool> requestPermission() async {
    if (!kIsWeb) return false;
    
    try {
      // Check if browser supports notifications
      if (!html.Notification.supported) {
        print('⚠️ Browser does not support notifications');
        return false;
      }
      
      // Check current permission status
      final currentPermission = html.Notification.permission;
      if (currentPermission == 'granted') {
        _permissionGranted = true;
        _permissionRequested = true;
        await DatabaseService.saveUserProfileData({
          'webNotificationsEnabled': true,
        });
        return true;
      }
      
      if (currentPermission == 'denied') {
        _permissionGranted = false;
        _permissionRequested = true;
        return false;
      }
      
      // Permission is 'default' - request it
      // Note: This must be called from a user interaction (button click)
      // Use the Notification.requestPermission() method directly
      try {
        final permissionResult = await html.Notification.requestPermission();
        _permissionRequested = true;
        _permissionGranted = permissionResult == 'granted';
        
        print('Permission request result: $permissionResult');
      } catch (e) {
        print('Error requesting permission: $e');
        _permissionRequested = true;
        _permissionGranted = false;
      }
      
      // Double-check permission status
      final finalPermission = html.Notification.permission;
      if (finalPermission == 'granted') {
        _permissionGranted = true;
      }
      
      if (_permissionGranted) {
        await DatabaseService.saveUserProfileData({
          'webNotificationsEnabled': true,
        });
      }
      
      return _permissionGranted;
    } catch (e) {
      print('Error requesting notification permission: $e');
      return false;
    }
  }

  /// Show a browser notification
  Future<void> showNotification({
    required String title,
    required String body,
    String? imageUrl,
    Map<String, dynamic>? data,
    String? tag,
  }) async {
    if (!kIsWeb) return;
    
    // Check permission
    if (html.Notification.permission != 'granted') {
      if (!await requestPermission()) {
        print('⚠️ Cannot show notification: Permission denied');
        return;
      }
    }

    try {
      // Save notification to database for tracking
      await DatabaseService.saveUserProgress({
        'lastNotification': {
          'title': title,
          'body': body,
          'timestamp': DateTime.now().toIso8601String(),
          'data': data,
        },
      });

      // Create notification using dart:html Notification API
      // The Notification constructor only accepts title as positional parameter
      // Additional options must be set via JS interop or by creating the notification differently
      html.Notification notification;
      
      try {
        // Create notification with just title first
        notification = html.Notification(title);
        
        // Set body and other properties using reflection or direct property access
        // Unfortunately dart:html Notification doesn't support named parameters in constructor
        // We'll use a simple notification with just title for now
        // Body can be set if the API supports it, but many browsers only show title
        
        // Note: Some browsers require body to be set during construction via JS interop
        // For now, create minimal notification that works across browsers
        notification = html.Notification(title);
        
        // Try to set body via dynamic access (browser-dependent)
        try {
          (notification as dynamic).body = body;
        } catch (e) {
          // Body setting not supported, continue with title only
        }
        
        // Try to set icon
        if (imageUrl != null) {
          try {
            (notification as dynamic).icon = imageUrl;
          } catch (e) {
            // Icon setting not supported
          }
        }
      } catch (e) {
        print('Error creating notification: $e');
        // Last resort: create basic notification
        notification = html.Notification(title);
      }
      
      // Handle click
      notification.onClick.listen((event) {
        print('Notification clicked: $tag');
        notification.close();
      });
      
      // Auto-close after 5 seconds
      Future.delayed(const Duration(seconds: 5), () {
        notification.close();
      });
      
      print('📢 Web Notification sent: $title - $body');
    } catch (e) {
      print('Error showing notification: $e');
    }
  }

  /// Schedule daily engagement notifications
  Future<void> scheduleDailyNotifications({
    required GamificationService gamification,
    required DailyGoalsService dailyGoals,
  }) async {
    if (!kIsWeb) return;
    if (!_permissionGranted && !await requestPermission()) return;

    final now = DateTime.now();
    final userProfile = await DatabaseService.loadUserProfile();
    final userName = userProfile?['displayName'] ?? 'there';

    // Morning notification (8 AM)
    final morningTime = DateTime(now.year, now.month, now.day, 8, 0);
    if (morningTime.isAfter(now)) {
      _scheduleNotification(
        time: morningTime,
        title: 'Good morning, $userName! 🌅',
        body: _getMorningMessage(gamification, dailyGoals),
        tag: 'morning_streak',
      );
    }

    // Afternoon notification (2 PM) - Learning reminder
    final afternoonTime = DateTime(now.year, now.month, now.day, 14, 0);
    if (afternoonTime.isAfter(now)) {
      _scheduleNotification(
        time: afternoonTime,
        title: 'Time to learn! 📚',
        body: _getAfternoonMessage(gamification, dailyGoals),
        tag: 'afternoon_learning',
      );
    }

    // Evening notification (8 PM) - Streak reminder
    final eveningTime = DateTime(now.year, now.month, now.day, 20, 0);
    if (eveningTime.isAfter(now)) {
      _scheduleNotification(
        time: eveningTime,
        title: 'Don\'t break your streak! 🔥',
        body: _getEveningMessage(gamification, dailyGoals),
        tag: 'evening_streak',
      );
    }

    // Market open notification (9:30 AM weekdays)
    if (now.weekday >= 1 && now.weekday <= 5) {
      final marketOpenTime = DateTime(now.year, now.month, now.day, 9, 30);
      if (marketOpenTime.isAfter(now)) {
        _scheduleNotification(
          time: marketOpenTime,
          title: 'Market is open! 📈',
          body: 'Time to check your portfolio and make some trades!',
          tag: 'market_open',
        );
      }
    }
  }

  void _scheduleNotification({
    required DateTime time,
    required String title,
    required String body,
    required String tag,
  }) {
    // For web, we use Timer to schedule notifications
    // Note: This only works while the tab is open
    // For true background notifications, you'd need a Service Worker
    final duration = time.difference(DateTime.now());
    if (duration.isNegative) return;

    // Save scheduled notification to database
    DatabaseService.saveUserProgress({
      'scheduledNotifications': {
        tag: {
          'title': title,
          'body': body,
          'scheduledFor': time.toIso8601String(),
        },
      },
    });
    
    // Schedule using Timer (only works while tab is open)
    Timer(duration, () {
      showNotification(
        title: title,
        body: body,
        tag: tag,
      );
    });
    
    print('📅 Scheduled notification "$tag" for ${time.toString()}');
  }

  String _getMorningMessage(GamificationService gamification, DailyGoalsService dailyGoals) {
    final streak = gamification.streak;
    
    if (streak == 0) {
      return 'Start your trading journey today! Complete your first lesson.';
    } else if (streak < 7) {
      return 'Your $streak-day streak is growing! Complete your daily goals to keep it going.';
    } else if (streak < 30) {
      return 'Amazing $streak-day streak! Let\'s make it even longer today.';
    } else {
      return 'Incredible $streak-day streak! You\'re a trading master! 🏆';
    }
  }

  String _getAfternoonMessage(GamificationService gamification, DailyGoalsService dailyGoals) {
    if (!dailyGoals.isLessonGoalComplete) {
      return 'Complete a quick 5-minute lesson to earn XP and unlock new content!';
    } else if (!dailyGoals.isTradeGoalComplete) {
      return 'Time to practice! Make a trade to complete your daily goals.';
    } else if (!dailyGoals.isXPGoalComplete) {
      final xpNeeded = dailyGoals.dailyXPGoal - dailyGoals.todayXP;
      return 'Just $xpNeeded more XP to complete your daily goals!';
    } else {
      return 'Great progress! Keep learning to unlock tomorrow\'s lesson.';
    }
  }

  String _getEveningMessage(GamificationService gamification, DailyGoalsService dailyGoals) {
    final streak = gamification.streak;
    final allComplete = dailyGoals.isLessonGoalComplete &&
                       dailyGoals.isTradeGoalComplete &&
                       dailyGoals.isXPGoalComplete;

    if (allComplete) {
      return 'All goals complete! Your $streak-day streak is safe. See you tomorrow!';
    } else {
      final remaining = [
        if (!dailyGoals.isLessonGoalComplete) 'a lesson',
        if (!dailyGoals.isTradeGoalComplete) 'a trade',
        if (!dailyGoals.isXPGoalComplete) 'more XP',
      ].join(', ');
      
      return 'Complete $remaining to protect your $streak-day streak! Time is running out.';
    }
  }

  /// Send streak-at-risk notification (if user inactive 20-24 hours)
  Future<void> sendStreakAtRiskNotification(GamificationService gamification) async {
    if (!kIsWeb) return;
    
    final streak = gamification.streak;
    if (streak == 0) return;

    final lastActivity = gamification.lastActivityDate;
    if (lastActivity == null) return;

    final hoursSinceActivity = DateTime.now().difference(lastActivity).inHours;
    
    if (hoursSinceActivity >= 20 && hoursSinceActivity <= 24) {
      String urgencyEmoji = '⚠️';
      String message = '';
      
      if (streak >= 30) {
        urgencyEmoji = '🚨';
        message = 'URGENT: Your incredible $streak-day streak is at risk!';
      } else if (streak >= 7) {
        urgencyEmoji = '⚠️';
        message = 'Your $streak-day streak is about to break!';
      } else {
        urgencyEmoji = '🔥';
        message = 'Don\'t lose your $streak-day streak!';
      }

      await showNotification(
        title: '$urgencyEmoji Streak At Risk!',
        body: message,
        tag: 'streak_at_risk',
        data: {'type': 'streak_at_risk', 'streak': streak},
      );
    }
  }

  /// Send achievement notification
  Future<void> sendAchievementNotification({
    required String title,
    required String body,
    String? badgeName,
  }) async {
    await showNotification(
      title: '🏆 $title',
      body: body,
      tag: 'achievement',
      data: {'type': 'achievement', 'badge': badgeName},
    );
  }

  /// Send personalized learning reminder
  Future<void> sendLearningReminder() async {
    final profile = await DatabaseService.loadUserProfile();
    final userName = profile?['displayName'] ?? 'there';
    
    final messages = [
      'Hey $userName! Ready for today\'s lesson? 📚',
      '$userName, time to level up your trading skills!',
      'Quick 5-minute lesson waiting for you, $userName!',
      'New lesson unlocked just for you, $userName! 🎓',
    ];
    
    final randomMessage = messages[DateTime.now().millisecond % messages.length];
    
    await showNotification(
      title: 'Time to Learn!',
      body: randomMessage,
      tag: 'learning_reminder',
      data: {'type': 'learning_reminder'},
    );
  }

  /// Enable notifications and save preference
  Future<void> enableNotifications() async {
    final granted = await requestPermission();
    if (granted) {
      await DatabaseService.saveUserProfileData({
        'webNotificationsEnabled': true,
      });
      _permissionGranted = true;
    }
  }

  /// Disable notifications
  Future<void> disableNotifications() async {
    await DatabaseService.saveUserProfileData({
      'webNotificationsEnabled': false,
    });
    _permissionGranted = false;
  }

  /// Check if notifications are enabled
  Future<bool> areNotificationsEnabled() async {
    if (!kIsWeb) return false;
    
    // First check browser permission status
    if (html.Notification.supported) {
      final browserPermission = html.Notification.permission;
      if (browserPermission == 'granted') {
        return true;
      }
      if (browserPermission == 'denied') {
        return false;
      }
    }
    
    // Fallback to saved preference
    final profile = await DatabaseService.loadUserProfile();
    return profile?['webNotificationsEnabled'] == true;
  }
  
  /// Get current browser permission status
  String getPermissionStatus() {
    if (!kIsWeb || !html.Notification.supported) {
      return 'unsupported';
    }
    return html.Notification.permission ?? 'default';
  }
  
  /// Check if browser supports notifications
  bool isSupported() {
    if (!kIsWeb) return false;
    return html.Notification.supported;
  }
}


