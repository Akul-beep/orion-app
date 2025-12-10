import '../services/database_service.dart';
import '../services/gamification_service.dart';
import '../services/user_progress_service.dart';
import '../services/daily_goals_service.dart';
import '../services/paper_trading_service.dart';
import 'web_notification_service.dart';
import 'email_sequence_service.dart';

/// User Engagement & Retention Service
/// Implements strategies from AppsFlyer video:
/// 1. Audience segmentation
/// 2. Personalized UX
/// 3. Timely notifications
/// 4. Re-engagement campaigns
class UserEngagementService {
  static final UserEngagementService _instance = UserEngagementService._internal();
  factory UserEngagementService() => _instance;
  UserEngagementService._internal();

  /// Track user session start
  Future<void> trackSessionStart() async {
    final userId = await DatabaseService.getOrCreateLocalUserId();
    final now = DateTime.now();
    
    await DatabaseService.saveUserProgress({
      'lastSessionStart': now.toIso8601String(),
      'totalSessions': await _getTotalSessions() + 1,
    });

    // Check if user is returning after being inactive
    await _checkAndHandleReEngagement(userId, now);
  }

  /// Track user activity
  Future<void> trackActivity(String activityType, {Map<String, dynamic>? metadata}) async {
    final userId = await DatabaseService.getOrCreateLocalUserId();
    final now = DateTime.now();
    
    await DatabaseService.saveUserProgress({
      'lastActivity': now.toIso8601String(),
      'lastActivityType': activityType,
      'activityHistory': {
        'timestamp': now.toIso8601String(),
        'type': activityType,
        'metadata': metadata ?? {},
      },
    });
  }

  /// Segment users based on behavior
  Future<UserSegment> getUserSegment() async {
    final profile = await DatabaseService.loadUserProfile();
    final progress = await DatabaseService.loadUserProgress();
    
    final daysSinceInstall = await _getDaysSinceInstall();
    final totalSessions = await _getTotalSessions();
    final lastActivity = progress?['lastActivity'];
    
    // Calculate inactivity
    int daysInactive = 0;
    if (lastActivity != null) {
      final lastActivityDate = DateTime.parse(lastActivity);
      daysInactive = DateTime.now().difference(lastActivityDate).inDays;
    }

    // Segment logic
    if (daysSinceInstall < 1) {
      return UserSegment.newUser;
    } else if (daysSinceInstall < 7) {
      return UserSegment.beginner;
    } else if (daysInactive > 30) {
      return UserSegment.churned;
    } else if (daysInactive > 7) {
      return UserSegment.atRisk;
    } else if (totalSessions >= 30 && daysSinceInstall >= 30) {
      return UserSegment.loyal;
    } else if (totalSessions >= 14) {
      return UserSegment.engaged;
    } else {
      return UserSegment.active;
    }
  }

  /// Get personalized message based on user segment
  Future<String> getPersonalizedMessage({
    GamificationService? gamification,
    DailyGoalsService? dailyGoals,
  }) async {
    final segment = await getUserSegment();
    
    switch (segment) {
      case UserSegment.newUser:
        return 'Welcome! Complete your first lesson to get started.';
      case UserSegment.beginner:
        return 'Keep up the momentum! Complete today\'s lesson.';
      case UserSegment.active:
        final streak = gamification?.streak ?? 0;
        if (streak > 0) {
          return 'Protect your $streak-day streak! Complete your daily goals.';
        }
        return 'Time to build a streak! Complete your daily goals.';
      case UserSegment.engaged:
        return 'You\'re doing great! Keep learning to unlock new content.';
      case UserSegment.loyal:
        return 'Thanks for being a loyal trader! Ready for today\'s challenge?';
      case UserSegment.atRisk:
        return 'We miss you! Come back and complete a lesson.';
      case UserSegment.churned:
        return 'Welcome back! We have new lessons waiting for you.';
    }
  }

  /// Check and handle re-engagement
  Future<void> _checkAndHandleReEngagement(String userId, DateTime now) async {
    final progress = await DatabaseService.loadUserProgress();
    final lastActivity = progress?['lastActivity'];
    
    if (lastActivity == null) return;
    
    final lastActivityDate = DateTime.parse(lastActivity);
    final daysInactive = now.difference(lastActivityDate).inDays;
    
    // Re-engagement campaigns based on inactivity
    if (daysInactive >= 30) {
      await _sendReEngagementCampaign('churned');
    } else if (daysInactive >= 7) {
      await _sendReEngagementCampaign('at_risk');
    } else if (daysInactive >= 3) {
      await _sendReEngagementCampaign('casual');
    }
  }

  /// Send re-engagement campaign
  Future<void> _sendReEngagementCampaign(String campaignType) async {
    final webNotification = WebNotificationService();
    final profile = await DatabaseService.loadUserProfile();
    final userName = profile?['displayName'] ?? 'there';
    final userId = await DatabaseService.getOrCreateLocalUserId();
    final userEmail = profile?['email'];
    
    switch (campaignType) {
      case 'churned':
        // Send email notification
        if (userEmail != null && userEmail.isNotEmpty) {
          await EmailSequenceService.sendRetentionEmail(
            userId: userId,
            email: userEmail,
            daysSinceLastActive: 30,
          );
        }
        
        // Also send browser notification if enabled
        await webNotification.showNotification(
          title: 'We miss you, $userName! 👋',
          body: 'New lessons are waiting! Come back and continue your trading journey.',
          tag: 'reengagement_churned',
          data: {'type': 'reengagement', 'campaign': 'churned'},
        );
        break;
      case 'at_risk':
        // Send email notification
        if (userEmail != null && userEmail.isNotEmpty) {
          await EmailSequenceService.sendRetentionEmail(
            userId: userId,
            email: userEmail,
            daysSinceLastActive: 7,
          );
        }
        
        // Also send browser notification
        await webNotification.showNotification(
          title: 'Don\'t give up now! 💪',
          body: 'Complete just one lesson to get back on track.',
          tag: 'reengagement_at_risk',
          data: {'type': 'reengagement', 'campaign': 'at_risk'},
        );
        break;
      case 'casual':
        // Send email notification for casual inactive users (3+ days)
        if (userEmail != null && userEmail.isNotEmpty) {
          await EmailSequenceService.sendRetentionEmail(
            userId: userId,
            email: userEmail,
            daysSinceLastActive: 3,
          );
        }
        
        // Also send browser notification
        await webNotification.showNotification(
          title: 'Time to learn, $userName! 📚',
          body: 'A quick 5-minute lesson is waiting for you.',
          tag: 'reengagement_casual',
          data: {'type': 'reengagement', 'campaign': 'casual'},
        );
        break;
    }
  }

  /// Track user inactivity
  Future<void> trackInactivity() async {
    final progress = await DatabaseService.loadUserProgress();
    final lastActivity = progress?['lastActivity'];
    
    if (lastActivity == null) return;
    
    final lastActivityDate = DateTime.parse(lastActivity);
    final hoursInactive = DateTime.now().difference(lastActivityDate).inHours;
    
    // Send streak-at-risk if 20-24 hours inactive
    if (hoursInactive >= 20 && hoursInactive <= 24) {
      final gamification = GamificationService();
      final webNotification = WebNotificationService();
      await webNotification.sendStreakAtRiskNotification(gamification);
    }
  }

  /// Get user behavior insights for personalization
  Future<Map<String, dynamic>> getUserInsights() async {
    final progress = await DatabaseService.loadUserProgress();
    final profile = await DatabaseService.loadUserProfile();
    
    final segment = await getUserSegment();
    final totalSessions = await _getTotalSessions();
    final daysSinceInstall = await _getDaysSinceInstall();
    
    return {
      'segment': segment.name,
      'totalSessions': totalSessions,
      'daysSinceInstall': daysSinceInstall,
      'preferredActivityTime': profile?['preferredActivityTime'],
      'favoriteLessons': profile?['favoriteLessons'] ?? [],
      'completedLessons': await _getCompletedLessonsCount(),
      'totalTrades': await _getTotalTrades(),
    };
  }

  /// Personalize experience based on user segment
  Future<Map<String, dynamic>> getPersonalizedExperience() async {
    final segment = await getUserSegment();
    final insights = await getUserInsights();
    
    return {
      'segment': segment.name,
      'recommendedActions': _getRecommendedActions(segment),
      'showOnboardingHints': segment == UserSegment.newUser || segment == UserSegment.beginner,
      'showAchievements': segment != UserSegment.newUser,
      'showLeaderboard': segment != UserSegment.newUser,
      'notificationFrequency': _getNotificationFrequency(segment),
    };
  }

  List<String> _getRecommendedActions(UserSegment segment) {
    switch (segment) {
      case UserSegment.newUser:
        return ['complete_first_lesson', 'setup_portfolio', 'enable_notifications'];
      case UserSegment.beginner:
        return ['complete_daily_goals', 'build_streak', 'explore_features'];
      case UserSegment.active:
      case UserSegment.engaged:
        return ['complete_daily_goals', 'maintain_streak', 'try_new_features'];
      case UserSegment.loyal:
        return ['complete_daily_goals', 'maintain_streak', 'help_others'];
      case UserSegment.atRisk:
        return ['complete_lesson', 'return_to_streak', 're_engage'];
      case UserSegment.churned:
        return ['welcome_back', 'complete_lesson', 'restart_journey'];
    }
  }

  String _getNotificationFrequency(UserSegment segment) {
    switch (segment) {
      case UserSegment.newUser:
        return 'high'; // 3-4 per day
      case UserSegment.beginner:
      case UserSegment.active:
        return 'medium'; // 2-3 per day
      case UserSegment.engaged:
      case UserSegment.loyal:
        return 'low'; // 1-2 per day
      case UserSegment.atRisk:
        return 'high'; // Re-engagement push
      case UserSegment.churned:
        return 'low'; // Periodic check-ins
    }
  }

  // Helper methods
  Future<int> _getTotalSessions() async {
    final progress = await DatabaseService.loadUserProgress();
    return (progress?['totalSessions'] as int?) ?? 0;
  }

  Future<int> _getDaysSinceInstall() async {
    final progress = await DatabaseService.loadUserProgress();
    final installDate = progress?['installDate'];
    
    if (installDate == null) {
      // Set install date if not exists
      await DatabaseService.saveUserProgress({
        'installDate': DateTime.now().toIso8601String(),
      });
      return 0;
    }
    
    final installDateTime = DateTime.parse(installDate);
    return DateTime.now().difference(installDateTime).inDays;
  }

  Future<int> _getCompletedLessonsCount() async {
    final completed = await DatabaseService.getCompletedActions();
    return completed.where((action) => action.startsWith('lesson_')).length;
  }

  Future<int> _getTotalTrades() async {
    final progress = await DatabaseService.loadUserProgress();
    return (progress?['totalTrades'] as int?) ?? 0;
  }
}

enum UserSegment {
  newUser,      // Just installed (< 1 day)
  beginner,     // 1-7 days active
  active,       // Regular user
  engaged,      // 14+ sessions
  loyal,        // 30+ days, high engagement
  atRisk,       // 7+ days inactive
  churned,      // 30+ days inactive
}


