import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'gamification_service.dart';
import 'daily_goals_service.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    _initialized = true;
  }

  void _onNotificationTapped(NotificationResponse response) {
    // Handle notification tap
    print('Notification tapped: ${response.payload}');
  }

  // Streak Reminder
  Future<void> scheduleStreakReminder(GamificationService gamification) async {
    if (gamification.streak == 0) return;
    // Note: Actual scheduling requires timezone package
    // For now, this is a placeholder
  }

  // Daily Goals Reminder
  Future<void> scheduleDailyGoalsReminder() async {
    // Note: Actual scheduling requires timezone package
    // For now, this is a placeholder
  }

  // Achievement Unlocked
  Future<void> showAchievementUnlocked(String badgeName, String description) async {
    await _notifications.show(
      3,
      'Achievement Unlocked! 🏆',
      'You earned: $badgeName\n$description',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'achievements',
          'Achievements',
          channelDescription: 'Notifications for unlocked achievements',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );
  }

  // Level Up
  Future<void> showLevelUp(int newLevel) async {
    await _notifications.show(
      4,
      'Level Up! ⭐',
      'Congratulations! You reached Level $newLevel!',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'level_up',
          'Level Up',
          channelDescription: 'Notifications for leveling up',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );
  }

  // Friend Challenge
  Future<void> showFriendChallenge(String friendName, String challengeType) async {
    await _notifications.show(
      5,
      'Challenge from $friendName! 🎯',
      '$friendName challenged you to a $challengeType challenge!',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'friend_challenges',
          'Friend Challenges',
          channelDescription: 'Notifications for friend challenges',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );
  }

  // Streak at Risk
  Future<void> showStreakAtRisk(int streak) async {
    await _notifications.show(
      6,
      'Streak at Risk! ⚠️',
      'Your $streak-day streak is about to end! Complete your daily goals now.',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'streak_risk',
          'Streak Warnings',
          channelDescription: 'Warnings when streak is at risk',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );
  }

  // Weekly Challenge Available
  Future<void> showWeeklyChallengeAvailable() async {
    await _notifications.show(
      7,
      'New Weekly Challenge! 🎮',
      'A new weekly challenge is available! Complete it for bonus XP.',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'weekly_challenges',
          'Weekly Challenges',
          channelDescription: 'Notifications for weekly challenges',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );
  }

  // Simplified scheduling - in production, use timezone package
  Future<void> scheduleNotification(int id, String title, String body, DateTime scheduledDate) async {
    // For now, use simple show - in production implement proper scheduling
    // This is a placeholder - actual scheduling requires timezone package
    await show(id, title, body);
  }

  Future<void> show(int id, String title, String body) async {
    await _notifications.show(
      id,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'general',
          'General Notifications',
          channelDescription: 'General app notifications',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );
  }

  Future<void> cancelAll() async {
    await _notifications.cancelAll();
  }
}

