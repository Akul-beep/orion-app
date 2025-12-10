import 'package:supabase_flutter/supabase_flutter.dart';
import 'database_service.dart';
import 'analytics_service.dart';

/// Email Sequence Service for automated email campaigns
/// Uses Supabase Edge Functions to trigger Resend API emails
/// Free tier: Resend offers 100 emails/day, 3,000/month
class EmailSequenceService {
  static SupabaseClient? _supabase;
  static bool _initialized = false;

  /// Initialize email service
  static Future<void> init() async {
    if (_initialized) return;
    try {
      _supabase = Supabase.instance.client;
      _initialized = true;
      print('✅ Email sequence service initialized');
    } catch (e) {
      _supabase = null;
      print('⚠️ Email service: Supabase not available');
    }
  }

  /// Trigger welcome email after signup
  static Future<void> sendWelcomeEmail({
    required String userId,
    required String email,
    String? displayName,
  }) async {
    try {
      if (_supabase == null) {
        print('⚠️ Cannot send email: Supabase not available');
        return;
      }

      // Call Supabase Edge Function to send email
      await _supabase!.functions.invoke(
        'send-email',
        body: {
          'type': 'welcome',
          'user_id': userId,
          'email': email,
          'display_name': displayName,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );

      print('✅ Welcome email triggered for: $email');
      
      // Track analytics
      await AnalyticsService.trackEvent('email_sent', properties: {
        'email_type': 'welcome',
        'user_id': userId,
      });
    } catch (e) {
      print('⚠️ Error sending welcome email: $e');
    }
  }

  /// Send email when user hasn't used app for X days (retention)
  static Future<void> sendRetentionEmail({
    required String userId,
    required String email,
    required int daysSinceLastActive,
  }) async {
    try {
      if (_supabase == null) return;

      await _supabase!.functions.invoke(
        'send-email',
        body: {
          'type': 'retention',
          'user_id': userId,
          'email': email,
          'days_since_last_active': daysSinceLastActive,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );

      print('✅ Retention email triggered for: $email ($daysSinceLastActive days)');
      
      await AnalyticsService.trackEvent('email_sent', properties: {
        'email_type': 'retention',
        'days_since_last_active': daysSinceLastActive,
      });
    } catch (e) {
      print('⚠️ Error sending retention email: $e');
    }
  }

  /// Send email sequence for onboarding (feature discovery)
  /// Sends emails over 2 weeks introducing features
  static Future<void> sendOnboardingSequence({
    required String userId,
    required String email,
    required int dayNumber, // Day 1, 2, 3, etc. of onboarding
  }) async {
    try {
      if (_supabase == null) return;

      await _supabase!.functions.invoke(
        'send-email',
        body: {
          'type': 'onboarding',
          'user_id': userId,
          'email': email,
          'day_number': dayNumber,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );

      print('✅ Onboarding email #$dayNumber triggered for: $email');
      
      await AnalyticsService.trackEvent('email_sent', properties: {
        'email_type': 'onboarding',
        'day_number': dayNumber,
      });
    } catch (e) {
      print('⚠️ Error sending onboarding email: $e');
    }
  }

  /// Send feedback request email
  static Future<void> sendFeedbackRequest({
    required String userId,
    required String email,
  }) async {
    try {
      if (_supabase == null) return;

      await _supabase!.functions.invoke(
        'send-email',
        body: {
          'type': 'feedback_request',
          'user_id': userId,
          'email': email,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );

      print('✅ Feedback request email triggered for: $email');
      
      await AnalyticsService.trackEvent('email_sent', properties: {
        'email_type': 'feedback_request',
      });
    } catch (e) {
      print('⚠️ Error sending feedback request email: $e');
    }
  }

  /// Send portfolio update email (for inactive users)
  static Future<void> sendPortfolioUpdateEmail({
    required String userId,
    required String email,
    required double portfolioValue,
    double? portfolioChange,
    double? portfolioChangePercent,
    int? streak,
  }) async {
    try {
      if (_supabase == null) return;

      // Check if we should send (respect daily limits)
      if (!await _shouldSendEmail(userId, 'portfolio_update')) return;

      await _supabase!.functions.invoke(
        'send-email',
        body: {
          'type': 'portfolio_update',
          'user_id': userId,
          'email': email,
          'portfolio_value': portfolioValue,
          'portfolio_change': portfolioChange,
          'portfolio_change_percent': portfolioChangePercent,
          'streak': streak,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );

      print('✅ Portfolio update email triggered for: $email');
      await _recordEmailSent(userId, 'portfolio_update', {
        'portfolio_value': portfolioValue,
        'portfolio_change_percent': portfolioChangePercent,
      });
    } catch (e) {
      print('⚠️ Error sending portfolio update email: $e');
    }
  }

  /// Send leaderboard update email
  static Future<void> sendLeaderboardUpdateEmail({
    required String userId,
    required String email,
    required int leaderboardRank,
    int? rankChange,
    double? portfolioValue,
    int? level,
    int? streak,
  }) async {
    try {
      if (_supabase == null) return;

      // Only send for significant rank changes or top 10
      if (leaderboardRank > 10 && (rankChange == null || rankChange == 0)) {
        return;
      }

      if (!await _shouldSendEmail(userId, 'leaderboard_update')) return;

      await _supabase!.functions.invoke(
        'send-email',
        body: {
          'type': 'leaderboard_update',
          'user_id': userId,
          'email': email,
          'leaderboard_rank': leaderboardRank,
          'leaderboard_change': rankChange,
          'portfolio_value': portfolioValue,
          'level': level,
          'streak': streak,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );

      print('✅ Leaderboard update email triggered for: $email (Rank #$leaderboardRank)');
      await _recordEmailSent(userId, 'leaderboard_update', {
        'rank': leaderboardRank,
        'rank_change': rankChange,
      });
    } catch (e) {
      print('⚠️ Error sending leaderboard update email: $e');
    }
  }

  /// Send weekly summary email
  static Future<void> sendWeeklySummaryEmail({
    required String userId,
    required String email,
    Map<String, dynamic>? weeklyStats,
    double? portfolioValue,
    int? streak,
    int? level,
  }) async {
    try {
      if (_supabase == null) return;

      // Only send once per week
      if (!await _shouldSendEmail(userId, 'weekly_summary', daysSinceLast: 7)) return;

      await _supabase!.functions.invoke(
        'send-email',
        body: {
          'type': 'weekly_summary',
          'user_id': userId,
          'email': email,
          'weekly_stats': weeklyStats,
          'portfolio_value': portfolioValue,
          'streak': streak,
          'level': level,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );

      print('✅ Weekly summary email triggered for: $email');
      await _recordEmailSent(userId, 'weekly_summary', weeklyStats);
    } catch (e) {
      print('⚠️ Error sending weekly summary email: $e');
    }
  }

  /// Send streak at risk email (Duolingo-style)
  static Future<void> sendStreakAtRiskEmail({
    required String userId,
    required String email,
    required int streak,
    int? hoursSinceActivity,
  }) async {
    try {
      if (_supabase == null) return;

      // Only send once per day for streak at risk
      if (!await _shouldSendEmail(userId, 'streak_at_risk')) return;

      await _supabase!.functions.invoke(
        'send-email',
        body: {
          'type': 'streak_at_risk',
          'user_id': userId,
          'email': email,
          'streak': streak,
          'hours_since_activity': hoursSinceActivity,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );

      print('✅ Streak at risk email triggered for: $email (${streak}-day streak)');
      await _recordEmailSent(userId, 'streak_at_risk', {
        'streak': streak,
        'hours_since_activity': hoursSinceActivity,
      });
    } catch (e) {
      print('⚠️ Error sending streak at risk email: $e');
    }
  }

  /// Send streak lost email
  static Future<void> sendStreakLostEmail({
    required String userId,
    required String email,
    required int previousStreak,
  }) async {
    try {
      if (_supabase == null) return;

      await _supabase!.functions.invoke(
        'send-email',
        body: {
          'type': 'streak_lost',
          'user_id': userId,
          'email': email,
          'previous_streak': previousStreak,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );

      print('✅ Streak lost email triggered for: $email (was ${previousStreak} days)');
      await _recordEmailSent(userId, 'streak_lost', {
        'previous_streak': previousStreak,
      });
    } catch (e) {
      print('⚠️ Error sending streak lost email: $e');
    }
  }

  /// Send streak milestone email
  static Future<void> sendStreakMilestoneEmail({
    required String userId,
    required String email,
    required int streak,
  }) async {
    try {
      if (_supabase == null) return;

      // Only send for milestone streaks (7, 14, 30, 100)
      if (![7, 14, 30, 100].contains(streak)) return;

      await _supabase!.functions.invoke(
        'send-email',
        body: {
          'type': 'streak_milestone',
          'user_id': userId,
          'email': email,
          'streak': streak,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );

      print('✅ Streak milestone email triggered for: $email (${streak}-day streak)');
      await _recordEmailSent(userId, 'streak_milestone', {
        'streak': streak,
      });
    } catch (e) {
      print('⚠️ Error sending streak milestone email: $e');
    }
  }

  /// Send achievement unlocked email
  static Future<void> sendAchievementUnlockedEmail({
    required String userId,
    required String email,
    required String achievementName,
    String? achievementDescription,
  }) async {
    try {
      if (_supabase == null) return;

      await _supabase!.functions.invoke(
        'send-email',
        body: {
          'type': 'achievement_unlocked',
          'user_id': userId,
          'email': email,
          'achievement_name': achievementName,
          'achievement_description': achievementDescription,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );

      print('✅ Achievement unlocked email triggered for: $email ($achievementName)');
      await _recordEmailSent(userId, 'achievement_unlocked', {
        'achievement_name': achievementName,
      });
    } catch (e) {
      print('⚠️ Error sending achievement unlocked email: $e');
    }
  }

  /// Send level up email
  static Future<void> sendLevelUpEmail({
    required String userId,
    required String email,
    required int level,
    required int previousLevel,
    int? xp,
  }) async {
    try {
      if (_supabase == null) return;

      await _supabase!.functions.invoke(
        'send-email',
        body: {
          'type': 'level_up',
          'user_id': userId,
          'email': email,
          'level': level,
          'previous_level': previousLevel,
          'xp': xp,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );

      print('✅ Level up email triggered for: $email (Level $previousLevel → $level)');
      await _recordEmailSent(userId, 'level_up', {
        'level': level,
        'previous_level': previousLevel,
      });
    } catch (e) {
      print('⚠️ Error sending level up email: $e');
    }
  }

  /// Send market update email
  static Future<void> sendMarketUpdateEmail({
    required String userId,
    required String email,
    String? newsTitle,
    String? newsSummary,
  }) async {
    try {
      if (_supabase == null) return;

      // Only send once per day
      if (!await _shouldSendEmail(userId, 'market_update')) return;

      await _supabase!.functions.invoke(
        'send-email',
        body: {
          'type': 'market_update',
          'user_id': userId,
          'email': email,
          'market_news_title': newsTitle,
          'market_news_summary': newsSummary,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );

      print('✅ Market update email triggered for: $email');
      await _recordEmailSent(userId, 'market_update', {
        'news_title': newsTitle,
      });
    } catch (e) {
      print('⚠️ Error sending market update email: $e');
    }
  }

  /// Send daily reminder email
  static Future<void> sendDailyReminderEmail({
    required String userId,
    required String email,
    int? streak,
    double? portfolioValue,
  }) async {
    try {
      if (_supabase == null) return;

      // Only send once per day, and only if user hasn't been active today
      if (!await _shouldSendEmail(userId, 'daily_reminder')) return;

      await _supabase!.functions.invoke(
        'send-email',
        body: {
          'type': 'daily_reminder',
          'user_id': userId,
          'email': email,
          'streak': streak,
          'portfolio_value': portfolioValue,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );

      print('✅ Daily reminder email triggered for: $email');
      await _recordEmailSent(userId, 'daily_reminder', {
        'streak': streak,
      });
    } catch (e) {
      print('⚠️ Error sending daily reminder email: $e');
    }
  }

  /// Send friend activity email
  static Future<void> sendFriendActivityEmail({
    required String userId,
    required String email,
  }) async {
    try {
      if (_supabase == null) return;

      // Only send once per day
      if (!await _shouldSendEmail(userId, 'friend_activity')) return;

      await _supabase!.functions.invoke(
        'send-email',
        body: {
          'type': 'friend_activity',
          'user_id': userId,
          'email': email,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );

      print('✅ Friend activity email triggered for: $email');
      await _recordEmailSent(userId, 'friend_activity', {});
    } catch (e) {
      print('⚠️ Error sending friend activity email: $e');
    }
  }

  /// Smart email scheduling - respects free tier limits (100 emails/day)
  /// Only sends if:
  /// 1. Haven't sent this email type to this user recently (based on daysSinceLast)
  /// 2. Daily email count is under limit
  static Future<bool> _shouldSendEmail(
    String userId,
    String emailType, {
    int daysSinceLast = 1,
  }) async {
    try {
      if (_supabase == null) return false;

      // Check if we've sent this email type recently
      final cutoffDate = DateTime.now().subtract(Duration(days: daysSinceLast));
      final recentEmails = await _supabase!
          .from('email_logs')
          .select('sent_at')
          .eq('user_id', userId)
          .eq('email_type', emailType)
          .gte('sent_at', cutoffDate.toIso8601String())
          .limit(1);

      if (recentEmails.isNotEmpty && recentEmails.length > 0) {
        print('⚠️ Skipping $emailType email for $userId - sent recently');
        return false;
      }

      // Check daily email count (approximate - for free tier protection)
      final today = DateTime.now();
      final todayStart = DateTime(today.year, today.month, today.day);
      final todayEmails = await _supabase!
          .from('email_logs')
          .select('id')
          .gte('sent_at', todayStart.toIso8601String())
          .limit(100);

      // If we're approaching the limit, only send high-priority emails
      if (todayEmails.length >= 90) {
        final highPriorityTypes = [
          'streak_at_risk',
          'streak_lost',
          'welcome',
          'retention',
        ];
        if (!highPriorityTypes.contains(emailType)) {
          print('⚠️ Skipping $emailType email - daily limit approaching');
          return false;
        }
      }

      return true;
    } catch (e) {
      print('⚠️ Error checking if should send email: $e');
      // On error, allow sending (fail open)
      return true;
    }
  }

  /// Record email sent (for tracking and rate limiting)
  static Future<void> _recordEmailSent(
    String userId,
    String emailType,
    Map<String, dynamic>? metadata,
  ) async {
    try {
      if (_supabase == null) return;

      await _supabase!.from('email_logs').insert({
        'user_id': userId,
        'email_type': emailType,
        'metadata': metadata,
        'sent_at': DateTime.now().toIso8601String(),
      });

      // Track analytics
      await AnalyticsService.trackEvent('email_sent', properties: {
        'email_type': emailType,
        'user_id': userId,
      });
    } catch (e) {
      print('⚠️ Error recording email: $e');
    }
  }

  /// Record email sent (for tracking) - public method for backward compatibility
  static Future<void> recordEmailSent({
    required String userId,
    required String emailType,
    Map<String, dynamic>? metadata,
  }) async {
    await _recordEmailSent(userId, emailType, metadata);
  }

  /// Check and send retention emails for inactive users
  /// Sends different emails based on inactivity period
  static Future<void> checkAndSendRetentionEmails() async {
    try {
      if (_supabase == null) return;

      final now = DateTime.now();
      
      // Get users who haven't been active
      final users = await _supabase!
          .from('users')
          .select('id, email, last_active_at, display_name')
          .not('last_active_at', 'is', null);

      for (final user in users) {
        if (user['last_active_at'] == null) continue;
        
        final lastActive = DateTime.parse(user['last_active_at']);
        final daysSince = now.difference(lastActive).inDays;
        
        // Send retention email for 3+ days inactive
        if (daysSince >= 3 && daysSince < 7) {
          await sendRetentionEmail(
            userId: user['id'],
            email: user['email'],
            daysSinceLastActive: daysSince,
          );
        }
        // Send urgent retention for 7+ days
        else if (daysSince >= 7) {
          await sendRetentionEmail(
            userId: user['id'],
            email: user['email'],
            daysSinceLastActive: daysSince,
          );
        }
      }
    } catch (e) {
      print('⚠️ Error checking retention emails: $e');
    }
  }

  /// Send weekly portfolio updates to inactive users
  static Future<void> sendWeeklyPortfolioUpdates() async {
    try {
      if (_supabase == null) return;

      final now = DateTime.now();
      final weekAgo = now.subtract(const Duration(days: 7));
      
      // Get inactive users (haven't logged in for 3+ days)
      final inactiveUsers = await _supabase!
          .from('users')
          .select('id, email, last_active_at')
          .lt('last_active_at', weekAgo.toIso8601String());

      for (final user in inactiveUsers) {
        // Get user's portfolio value from database
        try {
          final portfolio = await _supabase!
              .from('portfolios')
              .select('total_value')
              .eq('user_id', user['id'])
              .single();

          if (portfolio != null && portfolio['total_value'] != null) {
            await sendPortfolioUpdateEmail(
              userId: user['id'],
              email: user['email'],
              portfolioValue: (portfolio['total_value'] as num).toDouble(),
            );
          }
        } catch (e) {
          print('⚠️ Could not get portfolio for user ${user['id']}: $e');
        }
      }
    } catch (e) {
      print('⚠️ Error sending weekly portfolio updates: $e');
    }
  }
}

