import 'package:flutter/material.dart';
import 'push_notification_service.dart';
import '../models/orion_character.dart';
import 'gamification_service.dart';

/// TEST MODE: Send all notification types on app launch
/// This allows testing all Ory moods and notification styles
/// Set TEST_NOTIFICATIONS_ENABLED to false to disable
class TestNotificationService {
  static const bool TEST_NOTIFICATIONS_ENABLED = false; // Set to false to disable test notifications
  
  /// Send all test notifications immediately
  /// This shows all Ory moods and notification types
  static Future<void> sendAllTestNotifications(BuildContext? context) async {
    if (!TEST_NOTIFICATIONS_ENABLED) {
      print('🧪 Test notifications disabled');
      return;
    }
    
    print('🧪 TEST MODE: Sending all notification types with Ory characters...');
    
    final pushService = PushNotificationService();
    
    // Force check and request permissions
    print('🧪 Checking notification permissions...');
    final permissionsGranted = await pushService.arePermissionsGranted();
    print('🧪 Permissions granted: $permissionsGranted');
    
    if (!permissionsGranted) {
      print('⚠️ Test notifications: Permissions not granted - requesting...');
      final requested = await pushService.requestPermissions();
      print('🧪 Permission request result: $requested');
      // Wait a bit for permission dialog
      await Future.delayed(const Duration(seconds: 3));
      
      // Check again after request
      final finalCheck = await pushService.arePermissionsGranted();
      print('🧪 Final permission check: $finalCheck');
      
      if (!finalCheck) {
        print('⚠️ Test notifications: Permissions still not granted - skipping tests');
        print('💡 Try going to Settings > Orion > Notifications and enable them manually');
        return;
      }
    }
    
    print('✅ Permissions granted - proceeding with test notifications');
    
    // Make sure notifications are enabled in settings
    final notificationsEnabled = await pushService.areNotificationsEnabled();
    print('🧪 Notifications enabled in settings: $notificationsEnabled');
    
    if (!notificationsEnabled) {
      print('⚠️ Notifications are disabled in settings - enabling for test...');
      await pushService.setNotificationsEnabled(true);
    }
    
    // Get user info for personalization
    final gamification = GamificationService();
    await gamification.loadFromDatabase();
    final streak = gamification.streak;
    print('🧪 User streak: $streak');
    
    // Wait 3 seconds after app launch before sending first notification
    print('🧪 Waiting 3 seconds before sending first notification...');
    await Future.delayed(const Duration(seconds: 3));
    
    // 1. FRIENDLY ORY - Morning Streak Reminder
    print('🧪 TEST: Sending notification #1 - Friendly Ory - Morning Streak Reminder');
    await pushService.showNotification(
      id: 99991,
      title: await OrionCharacter.getNotificationTitle(CharacterMood.friendly, streak),
      body: await OrionCharacter.getNotificationMessage(
        mood: CharacterMood.friendly,
        context: 'morning_streak',
        streak: streak,
        userName: null,
      ),
      payload: 'test:friendly_morning',
      channelId: 'orion_streak',
      characterMood: CharacterMood.friendly,
    );
    
    await Future.delayed(const Duration(seconds: 3));
    
    // 2. CONCERNED ORY - Aggressive Streak at Risk (Duolingo-style!)
    print('🧪 TEST: Sending notification #2 - Concerned Ory - Aggressive Streak at Risk');
    await pushService.showNotification(
      id: 99992,
      title: await OrionCharacter.getNotificationTitle(CharacterMood.concerned, streak),
      body: await OrionCharacter.getNotificationMessage(
        mood: CharacterMood.concerned,
        context: 'streak_at_risk',
        streak: streak ?? 5,
        userName: null,
      ),
      payload: 'test:concerned_streak',
      channelId: 'orion_streak',
      characterMood: CharacterMood.concerned, // Aggressive Ory!
    );
    
    await Future.delayed(const Duration(seconds: 3));
    
    // 3. EXCITED ORY - Achievement Unlocked
    print('🧪 Sending: Excited Ory - Achievement Unlocked');
    await pushService.showAchievementUnlocked(
      'First Trade',
      'You made your first trade! Keep learning!',
    );
    
    await Future.delayed(const Duration(seconds: 3));
    
    // 4. EXCITED ORY - Level Up
    print('🧪 Sending: Excited Ory - Level Up');
    await pushService.showLevelUp(5);
    
    await Future.delayed(const Duration(seconds: 3));
    
    // 5. PROUD ORY - Streak Milestone
    print('🧪 Sending: Proud Ory - Streak Milestone');
    await pushService.showStreakMilestone(7);
    
    await Future.delayed(const Duration(seconds: 3));
    
    // 6. FRIENDLY ORY - Learning Reminder
    print('🧪 Sending: Friendly Ory - Learning Reminder');
    await pushService.showNotification(
      id: 99993,
      title: await OrionCharacter.getNotificationTitle(CharacterMood.friendly, null),
      body: await OrionCharacter.getNotificationMessage(
        mood: CharacterMood.friendly,
        context: 'afternoon_learning',
        streak: null,
        userName: null,
      ),
      payload: 'test:friendly_learning',
      channelId: 'orion_learning',
      characterMood: CharacterMood.friendly,
    );
    
    await Future.delayed(const Duration(seconds: 3));
    
    // 7. FRIENDLY ORY - Market Open
    print('🧪 Sending: Friendly Ory - Market Open');
    await pushService.showNotification(
      id: 99994,
      title: 'Hey. It\'s Ory.',
      body: 'Market is open! Check your portfolio and see how your stocks are performing today.',
      payload: 'test:market_open',
      channelId: 'orion_market',
      characterMood: CharacterMood.friendly,
    );
    
    await Future.delayed(const Duration(seconds: 3));
    
    // 8. CONCERNED ORY - Another Aggressive Streak Reminder (High Streak)
    print('🧪 Sending: Concerned Ory - High Streak at Risk (Very Aggressive!)');
    await pushService.showNotification(
      id: 99995,
      title: await OrionCharacter.getNotificationTitle(CharacterMood.concerned, 30),
      body: await OrionCharacter.getNotificationMessage(
        mood: CharacterMood.concerned,
        context: 'streak_at_risk',
        streak: 30, // High streak for more aggressive message
        userName: null,
      ),
      payload: 'test:concerned_high_streak',
      channelId: 'orion_streak',
      characterMood: CharacterMood.concerned, // Very aggressive!
    );
    
    print('✅ TEST MODE: All 8 test notifications sent!');
    print('📱 Check your notification center (swipe down from top) to see all Ory moods!');
    print('🦉 You should see: Friendly, Concerned (Aggressive!), Excited, and Proud Ory');
    print('💡 If you don\'t see notifications, check Settings > Orion > Notifications');
  }
}

