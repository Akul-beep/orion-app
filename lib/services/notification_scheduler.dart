import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'gamification_service.dart';
import 'paper_trading_service.dart';
import 'push_notification_service.dart';
import 'market_news_notification_service.dart';

/// Central scheduler that coordinates all notification types
/// Duolingo-style retention strategy: multiple touchpoints throughout the day
/// 
/// HOW DUOLINGO DOES IT:
/// 1. Schedules notifications 30 days in advance
/// 2. Reschedules daily at midnight to update content
/// 3. Checks for streak at risk periodically
/// 4. Reschedules when app comes to foreground
/// 5. Cancels and reschedules when user activity changes
class NotificationScheduler {
  static final NotificationScheduler _instance = NotificationScheduler._internal();
  factory NotificationScheduler() => _instance;
  NotificationScheduler._internal();

  bool _isScheduled = false;
  bool _isInitialized = false;
  Timer? _rescheduleTimer;
  Timer? _streakAtRiskCheckTimer;
  DateTime? _lastRescheduleTime;
  BuildContext? _context;

  /// Initialize and schedule all notifications
  /// Call this when app starts or user logs in
  Future<void> initialize(BuildContext? context) async {
    if (_isInitialized && _isScheduled) {
      print('📅 Notification Scheduler already initialized - rescheduling to update content');
      // Reschedule to update content with latest data
      await rescheduleAllNotifications(context);
      return;
    }

    _context = context;
    
    print('🚀 Initializing Notification Scheduler (Duolingo-style)...');
    
    // Initialize services
    await PushNotificationService().initialize();
    await MarketNewsNotificationService().initialize();

    // Schedule all notifications (30 days in advance)
    await scheduleAllNotifications(context);

    // Reschedule daily at midnight (like Duolingo)
    _scheduleDailyReschedule();

    // Check for streak at risk every 4 hours
    await _startStreakAtRiskChecks(context);

    // Set up app lifecycle hooks
    _setupAppLifecycleHooks();

    _isScheduled = true;
    _isInitialized = true;
    _lastRescheduleTime = DateTime.now();
    
    print('✅ Notification Scheduler initialized and scheduled');
    print('   📅 Notifications scheduled for next 30 days');
    print('   🔄 Will reschedule daily at midnight');
    print('   ⏰ Will check streak at risk every 4 hours');
  }

  /// Schedule all notification types
  /// Duolingo schedules 30 days in advance and reschedules daily
  Future<void> scheduleAllNotifications(BuildContext? context) async {
    print('📅 ========== SCHEDULING ALL NOTIFICATIONS ==========');
    final pushService = PushNotificationService();
    
    // Get services from context if available, or use static instances
    GamificationService? gamification;
    PaperTradingService? tradingService;
    
    if (context != null && context.mounted) {
      try {
        gamification = Provider.of<GamificationService>(context, listen: false);
        tradingService = Provider.of<PaperTradingService>(context, listen: false);
      } catch (e) {
        print('⚠️ Could not get services from context: $e');
      }
    }
    
    // Fallback to static instances if context not available
    if (gamification == null) {
      gamification = GamificationService.instance;
    }

    // CRITICAL: Update last app open time (for streak at risk detection)
    await pushService.updateLastAppOpen();
    print('   ✅ Updated last app open time');

    // 1. Streak reminders (Duolingo's most important retention tool - 2x per day)
    //    Scheduled for next 30 days
    if (gamification != null) {
      print('   📅 Scheduling streak reminders (30 days)...');
      await pushService.scheduleStreakReminders(gamification);
      print('   ✅ Streak reminders scheduled');
      
      // Check for streak at risk and schedule urgent reminder
      print('   🔍 Checking for streak at risk...');
      await pushService.checkAndScheduleStreakAtRisk(gamification);
      print('   ✅ Streak at risk check complete');
    } else {
      print('   ⚠️ GamificationService not available - skipping streak reminders');
    }

    // 2. Learning reminders (afternoon reminder)
    //    Scheduled for next 30 days
    print('   📅 Scheduling learning reminders (30 days)...');
    await pushService.scheduleLearningReminders();
    print('   ✅ Learning reminders scheduled');

    // 3. Market open notification (weekdays only)
    //    Scheduled for next 30 days
    print('   📅 Scheduling market open notifications (30 days, weekdays only)...');
    await pushService.scheduleMarketOpenNotification();
    print('   ✅ Market open notifications scheduled');

    // 4. Start market news checks (will check for positions when needed)
    if (tradingService != null) {
      print('   📰 Starting market news notification checks...');
      MarketNewsNotificationService().startPeriodicChecks(tradingService);
      print('   ✅ Market news checks started');
    } else {
      print('   ⚠️ PaperTradingService not available - skipping market news checks');
    }

    _lastRescheduleTime = DateTime.now();
    print('✅ ========== ALL NOTIFICATIONS SCHEDULED ==========');
    print('   📅 Next 30 days scheduled');
    print('   🔄 Will reschedule daily at midnight');
    print('   ⏰ Notifications will fire at scheduled times');
  }

  /// Reschedule all notifications (call daily or when preferences change)
  /// Duolingo reschedules daily at midnight to update content
  Future<void> rescheduleAllNotifications(BuildContext? context) async {
    final now = DateTime.now();
    
    // Prevent too frequent rescheduling (at least 1 hour apart)
    if (_lastRescheduleTime != null) {
      final timeSinceLastReschedule = now.difference(_lastRescheduleTime!);
      if (timeSinceLastReschedule.inHours < 1) {
        print('⏸️ Rescheduling skipped - last reschedule was ${timeSinceLastReschedule.inMinutes} minutes ago');
        return;
      }
    }
    
    print('🔄 ========== RESCHEDULING ALL NOTIFICATIONS ==========');
    print('   📅 Current time: ${now.toString()}');
    
    // Cancel all existing notifications
    print('   🗑️ Cancelling existing notifications...');
    await PushNotificationService().cancelAllScheduledNotifications();
    print('   ✅ Existing notifications cancelled');
    
    // Schedule fresh notifications with updated content
    await scheduleAllNotifications(context);
    
    print('✅ ========== RESCHEDULING COMPLETE ==========');
  }

  /// Schedule daily reschedule at midnight (like Duolingo)
  /// This ensures notifications always have fresh, up-to-date content
  void _scheduleDailyReschedule() {
    _rescheduleTimer?.cancel();
    
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1, 0, 0, 0);
    final durationUntilMidnight = tomorrow.difference(now);

    print('⏰ Next reschedule scheduled for: ${tomorrow.toString()} (in ${durationUntilMidnight.inHours}h ${durationUntilMidnight.inMinutes % 60}m)');

    _rescheduleTimer = Timer(durationUntilMidnight, () async {
      print('🔄 Midnight reschedule triggered (Duolingo-style)...');
      
      // Reschedule at midnight with current context
      await rescheduleAllNotifications(_context);
      
      // Schedule next reschedule (for tomorrow midnight)
      _scheduleDailyReschedule();
    });
  }

  /// Start periodic checks for streak at risk
  Future<void> _startStreakAtRiskChecks(BuildContext? context) async {
    _streakAtRiskCheckTimer?.cancel();
    
    // Check every 4 hours
    _streakAtRiskCheckTimer = Timer.periodic(const Duration(hours: 4), (timer) async {
      if (context != null && context.mounted) {
        try {
          final gamification = Provider.of<GamificationService>(context, listen: false);
          await PushNotificationService().checkAndScheduleStreakAtRisk(gamification);
        } catch (e) {
          print('⚠️ Error checking streak at risk: $e');
        }
      } else {
        // Try with static instance
        final gamification = GamificationService.instance;
        if (gamification != null) {
          await PushNotificationService().checkAndScheduleStreakAtRisk(gamification);
        }
      }
    });
    
    // Also check immediately
    if (context != null && context.mounted) {
      try {
        final gamification = Provider.of<GamificationService>(context, listen: false);
        await PushNotificationService().checkAndScheduleStreakAtRisk(gamification);
      } catch (e) {
        print('⚠️ Error checking streak at risk: $e');
      }
    }
  }

  /// Set up app lifecycle hooks
  /// Reschedules notifications when app comes to foreground (like Duolingo)
  void _setupAppLifecycleHooks() {
    // Note: App lifecycle is handled in main.dart or auth_wrapper.dart
    // This method is a placeholder for future lifecycle integration
    print('📱 App lifecycle hooks ready (reschedule on foreground)');
  }

  /// Handle app coming to foreground
  /// Duolingo reschedules when app opens to ensure fresh content
  Future<void> handleAppForeground(BuildContext? context) async {
    print('📱 App came to foreground - checking if reschedule needed...');
    
    final now = DateTime.now();
    
    // Reschedule if it's been more than 12 hours since last reschedule
    // This ensures notifications are fresh when user opens app
    if (_lastRescheduleTime == null) {
      print('   🔄 First time - scheduling notifications...');
      await rescheduleAllNotifications(context);
      return;
    }
    
    final timeSinceLastReschedule = now.difference(_lastRescheduleTime!);
    if (timeSinceLastReschedule.inHours >= 12) {
      print('   🔄 Last reschedule was ${timeSinceLastReschedule.inHours} hours ago - rescheduling...');
      await rescheduleAllNotifications(context);
    } else {
      print('   ✅ Notifications are fresh (last reschedule: ${timeSinceLastReschedule.inHours}h ago)');
    }
    
    // Always update last app open time
    await PushNotificationService().updateLastAppOpen();
    
    // Check for streak at risk immediately
    final gamification = GamificationService.instance;
    if (gamification != null) {
      await PushNotificationService().checkAndScheduleStreakAtRisk(gamification);
    }
  }

  /// Handle app going to background
  /// Update last activity time
  Future<void> handleAppBackground() async {
    print('📱 App went to background - updating activity time...');
    await PushNotificationService().updateLastAppOpen();
  }

  /// Cleanup
  void dispose() {
    _rescheduleTimer?.cancel();
    _streakAtRiskCheckTimer?.cancel();
    MarketNewsNotificationService().stopPeriodicChecks();
    _isScheduled = false;
    _isInitialized = false;
    print('🧹 Notification Scheduler disposed');
  }
}

