import 'package:flutter/material.dart';
import 'database_service.dart';
import 'gamification_service.dart';
import 'daily_goals_service.dart';
import 'notification_service.dart';

class SmartReminderService {
  static final SmartReminderService _instance = SmartReminderService._internal();
  factory SmartReminderService() => _instance;
  SmartReminderService._internal();

  DateTime? _lastReminderTime;
  Map<String, DateTime> _reminderHistory = {};

  /// Initialize and schedule smart reminders
  Future<void> initialize() async {
    await _scheduleOptimalReminders();
  }

  Future<void> _scheduleOptimalReminders() async {
    final notificationService = NotificationService();
    await notificationService.initialize();

    // Get user's typical activity times from database
    final userData = await DatabaseService.loadUserProfile();
    final preferredTime = userData?['preferredReminderTime'] as String? ?? '18:00';

    // Parse preferred time
    final timeParts = preferredTime.split(':');
    final hour = int.tryParse(timeParts[0]) ?? 18;
    final minute = int.tryParse(timeParts[1]) ?? 0;

    // Schedule daily reminder
    await _scheduleDailyReminder(hour, minute);

    // Schedule streak reminder if applicable
    final gamification = GamificationService();
    if (gamification.streak > 0) {
      await notificationService.scheduleStreakReminder(gamification);
    }
  }

  Future<void> _scheduleDailyReminder(int hour, int minute) async {
    final notificationService = NotificationService();
    
    // Schedule for today if time hasn't passed, otherwise tomorrow
    final now = DateTime.now();
    var reminderTime = DateTime(now.year, now.month, now.day, hour, minute);
    
    if (reminderTime.isBefore(now)) {
      reminderTime = reminderTime.add(const Duration(days: 1));
    }

    // Note: Actual scheduling requires timezone package
    // For now, this is a placeholder that will be implemented with proper scheduling
    print('📅 Daily reminder scheduled for ${reminderTime.toString()}');
  }

  /// Check if user needs a reminder based on activity patterns
  Future<bool> shouldSendReminder() async {
    final dailyGoals = await DatabaseService.loadDailyGoals();
    if (dailyGoals == null) return true;

    final today = DateTime.now().toIso8601String().split('T')[0];
    final todayXP = dailyGoals['todayXP'] ?? 0;
    final todayTrades = dailyGoals['todayTrades'] ?? 0;
    final todayLessons = dailyGoals['todayLessons'] ?? 0;

    // Don't remind if goals are already complete
    if (todayXP >= 100 && todayTrades >= 1 && todayLessons >= 1) {
      return false;
    }

    // Check if we've already sent a reminder today
    final lastReminder = _reminderHistory[today];
    if (lastReminder != null) {
      final hoursSince = DateTime.now().difference(lastReminder).inHours;
      // Don't send another reminder within 4 hours
      if (hoursSince < 4) {
        return false;
      }
    }

    return true;
  }

  /// Send a smart reminder based on context
  Future<void> sendSmartReminder() async {
    if (!await shouldSendReminder()) return;

    final notificationService = NotificationService();
    final dailyGoals = await DatabaseService.loadDailyGoals();
    final gamification = GamificationService();

    if (dailyGoals == null) {
      await notificationService.scheduleDailyGoalsReminder();
      return;
    }

    final today = DateTime.now().toIso8601String().split('T')[0];
    final todayXP = dailyGoals['todayXP'] ?? 0;
    final todayTrades = dailyGoals['todayTrades'] ?? 0;
    final todayLessons = dailyGoals['todayLessons'] ?? 0;

    // Personalized reminder based on what's missing
    String title = 'Complete Your Daily Goals!';
    String body = '';

    if (todayXP < 100 && todayTrades < 1 && todayLessons < 1) {
      body = 'You haven\'t started your daily goals yet! Earn XP, make a trade, and complete a lesson.';
    } else if (todayXP < 100) {
      body = 'You\'re ${100 - todayXP} XP away from your daily goal! Keep learning!';
    } else if (todayTrades < 1) {
      body = 'Make a trade to complete your daily trading goal!';
    } else if (todayLessons < 1) {
      body = 'Complete a lesson to finish your daily goals!';
    }

    // Add streak context if applicable
    if (gamification.streak > 0) {
      body += ' Your ${gamification.streak}-day streak is waiting!';
    }

    await notificationService.show(1, title, body);
    _reminderHistory[today] = DateTime.now();
  }

  /// Update user's preferred reminder time
  Future<void> updatePreferredTime(int hour, int minute) async {
    // Only update the preferredReminderTime field
    // saveUserProfileData will merge this with existing profile
    final profileUpdate = {
      'preferredReminderTime': '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}',
    };
    await DatabaseService.saveUserProfileData(profileUpdate);
    await _scheduleOptimalReminders();
  }
}






