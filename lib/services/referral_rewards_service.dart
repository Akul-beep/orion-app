import 'database_service.dart';
import 'gamification_service.dart';
import 'notification_manager.dart';

/// Referral Rewards Service
/// Handles awarding rewards when users refer friends
class ReferralRewardsService {
  // Reward amounts
  static const int xpRewardForReferrer = 500; // XP for person who referred
  static const int xpRewardForReferee = 250; // XP for person who was referred
  static const double portfolioRewardForReferrer = 100.0; // $100 for referrer
  static const double portfolioRewardForReferee = 50.0; // $50 for referee

  /// Award rewards when a new user signs up with a referral code
  static Future<void> awardReferralRewards(String referrerCode, String newUserId) async {
    try {
      print('🎁 Awarding referral rewards for code: $referrerCode, new user: $newUserId');

      // Find the referrer's user ID
      final supabase = DatabaseService.getSupabaseClient();
      if (supabase == null) {
        print('⚠️ Supabase not available, cannot award rewards');
        return;
      }

      // Find referrer by matching the first 8 chars of their user_id
      final referrerUserId = await _findReferrerUserId(referrerCode);
      if (referrerUserId == null) {
        print('⚠️ Could not find referrer for code: $referrerCode');
        return;
      }

      print('✅ Found referrer: $referrerUserId');

      // Award rewards to referrer
      await _awardReferrerRewards(referrerUserId, newUserId);

      // Award rewards to referee (new user)
      await _awardRefereeRewards(newUserId, referrerUserId);

      // Track referral in database
      await _trackReferral(referrerUserId, newUserId, referrerCode);

      print('✅ Referral rewards awarded successfully!');
    } catch (e) {
      print('❌ Error awarding referral rewards: $e');
    }
  }

  /// Find referrer's user ID from referral code
  static Future<String?> _findReferrerUserId(String referralCode) async {
    try {
      final supabase = DatabaseService.getSupabaseClient();
      if (supabase == null) return null;

      // Get all user profiles and find one where user_id starts with the code
      final profiles = await supabase
          .from('user_profiles')
          .select('user_id')
          .limit(1000); // Get a reasonable number to search through

      for (final profile in profiles) {
        final userId = profile['user_id'] as String;
        if (userId.length >= 8 && userId.substring(0, 8).toUpperCase() == referralCode.toUpperCase()) {
          return userId;
        }
      }

      return null;
    } catch (e) {
      print('Error finding referrer: $e');
      return null;
    }
  }

  /// Award rewards to the person who referred
  static Future<void> _awardReferrerRewards(String referrerUserId, String newUserId) async {
    try {
      final supabase = DatabaseService.getSupabaseClient();
      if (supabase == null) {
        print('⚠️ Supabase not available for referrer rewards');
        return;
      }

      // Award XP - update gamification data directly in database for referrer
      try {
        final gamificationData = await DatabaseService.loadGamificationDataForUser(referrerUserId);
        if (gamificationData != null) {
          final currentXP = (gamificationData['totalXP'] as int?) ?? 0;
          gamificationData['totalXP'] = currentXP + xpRewardForReferrer;
          
          // Recalculate level
          final newLevel = GamificationService.calculateLevelFromXP(gamificationData['totalXP'] as int);
          gamificationData['level'] = newLevel;
          
          await DatabaseService.saveGamificationDataForUser(referrerUserId, gamificationData);
          print('✅ Awarded $xpRewardForReferrer XP to referrer (now at ${gamificationData['totalXP']} XP)');
        } else {
          // Create new gamification entry
          final newData = {
            'totalXP': xpRewardForReferrer,
            'level': GamificationService.calculateLevelFromXP(xpRewardForReferrer),
            'streak': 0,
            'badges': [],
            'totalTrades': 0,
            'lessonsCompleted': 0,
          };
          await DatabaseService.saveGamificationDataForUser(referrerUserId, newData);
          print('✅ Created gamification data and awarded $xpRewardForReferrer XP to referrer');
        }
      } catch (e) {
        print('⚠️ Error awarding XP reward: $e');
      }

      // Award portfolio money
      try {
        final portfolioData = await DatabaseService.loadPortfolioForUser(referrerUserId);
        if (portfolioData != null) {
          final currentCash = (portfolioData['cashBalance'] as num?)?.toDouble() ?? 0.0;
          portfolioData['cashBalance'] = currentCash + portfolioRewardForReferrer;
          portfolioData['totalValue'] = (portfolioData['totalValue'] as num? ?? 0.0).toDouble() + portfolioRewardForReferrer;
          
          await DatabaseService.savePortfolioForUser(referrerUserId, portfolioData);
          print('✅ Awarded \$$portfolioRewardForReferrer to referrer portfolio');
        } else {
          // Create new portfolio with reward
          final newPortfolio = {
            'cashBalance': 10000.0 + portfolioRewardForReferrer, // Starting balance + reward
            'totalValue': 10000.0 + portfolioRewardForReferrer,
            'positions': [],
            'tradeHistory': [],
          };
          await DatabaseService.savePortfolioForUser(referrerUserId, newPortfolio);
          print('✅ Created portfolio and awarded \$$portfolioRewardForReferrer to referrer');
        }
      } catch (e) {
        print('⚠️ Error awarding portfolio reward: $e');
      }

      // Send notification
      try {
        await NotificationManager().addNotification(
          type: 'referral_reward',
          title: 'Referral Reward! 🎉',
          message: 'You earned $xpRewardForReferrer XP and \$$portfolioRewardForReferrer for referring a friend!',
          data: {
            'xp': xpRewardForReferrer,
            'money': portfolioRewardForReferrer,
            'referred_user_id': newUserId,
          },
        );
      } catch (e) {
        print('⚠️ Error sending notification: $e');
      }
    } catch (e) {
      print('❌ Error awarding referrer rewards: $e');
    }
  }

  /// Award rewards to the person who was referred
  static Future<void> _awardRefereeRewards(String newUserId, String referrerUserId) async {
    try {
      final supabase = DatabaseService.getSupabaseClient();
      if (supabase == null) {
        print('⚠️ Supabase not available for referee rewards');
        return;
      }

      // Award XP - update gamification data directly in database for new user
      try {
        final gamificationData = await DatabaseService.loadGamificationDataForUser(newUserId);
        if (gamificationData != null) {
          final currentXP = (gamificationData['totalXP'] as int?) ?? 0;
          gamificationData['totalXP'] = currentXP + xpRewardForReferee;
          
          // Recalculate level
          final newLevel = GamificationService.calculateLevelFromXP(gamificationData['totalXP'] as int);
          gamificationData['level'] = newLevel;
          
          await DatabaseService.saveGamificationDataForUser(newUserId, gamificationData);
          print('✅ Awarded $xpRewardForReferee XP to new user (now at ${gamificationData['totalXP']} XP)');
        } else {
          // Create new gamification entry
          final newData = {
            'totalXP': xpRewardForReferee,
            'level': GamificationService.calculateLevelFromXP(xpRewardForReferee),
            'streak': 0,
            'badges': [],
            'totalTrades': 0,
            'lessonsCompleted': 0,
          };
          await DatabaseService.saveGamificationDataForUser(newUserId, newData);
          print('✅ Created gamification data and awarded $xpRewardForReferee XP to new user');
        }
      } catch (e) {
        print('⚠️ Error awarding XP reward: $e');
      }

      // Award portfolio money
      try {
        final portfolioData = await DatabaseService.loadPortfolioForUser(newUserId);
        if (portfolioData != null) {
          final currentCash = (portfolioData['cashBalance'] as num?)?.toDouble() ?? 0.0;
          portfolioData['cashBalance'] = currentCash + portfolioRewardForReferee;
          portfolioData['totalValue'] = (portfolioData['totalValue'] as num? ?? 0.0).toDouble() + portfolioRewardForReferee;
          
          await DatabaseService.savePortfolioForUser(newUserId, portfolioData);
          print('✅ Awarded \$$portfolioRewardForReferee to new user portfolio');
        } else {
          // Create new portfolio with reward (starting balance + bonus)
          final newPortfolio = {
            'cashBalance': 10000.0 + portfolioRewardForReferee,
            'totalValue': 10000.0 + portfolioRewardForReferee,
            'positions': [],
            'tradeHistory': [],
          };
          await DatabaseService.savePortfolioForUser(newUserId, newPortfolio);
          print('✅ Created portfolio and awarded \$$portfolioRewardForReferee to new user');
        }
      } catch (e) {
        print('⚠️ Error awarding portfolio reward: $e');
      }

      // Send notification
      try {
        await NotificationManager().addNotification(
          type: 'referral_signup_bonus',
          title: 'Welcome Bonus! 🎁',
          message: 'You earned $xpRewardForReferee XP and \$$portfolioRewardForReferee for signing up with a referral code!',
          data: {
            'xp': xpRewardForReferee,
            'money': portfolioRewardForReferee,
          },
        );
      } catch (e) {
        print('⚠️ Error sending notification: $e');
      }
    } catch (e) {
      print('❌ Error awarding referee rewards: $e');
    }
  }

  /// Track referral in database
  static Future<void> _trackReferral(String referrerUserId, String newUserId, String referralCode) async {
    try {
      final supabase = DatabaseService.getSupabaseClient();
      if (supabase == null) return;

      // Store referral in a referrals table (create if doesn't exist)
      try {
        await supabase.from('referrals').insert({
          'referrer_user_id': referrerUserId,
          'referred_user_id': newUserId,
          'referral_code': referralCode,
          'created_at': DateTime.now().toIso8601String(),
          'rewards_awarded': true,
        });
        print('✅ Referral tracked in database');
      } catch (e) {
        // Table might not exist, that's okay
        print('⚠️ Could not track referral in database (table may not exist): $e');
      }
    } catch (e) {
      print('❌ Error tracking referral: $e');
    }
  }

  /// Get referral stats for a user
  static Future<Map<String, dynamic>> getReferralStats(String userId) async {
    try {
      final supabase = DatabaseService.getSupabaseClient();
      if (supabase == null) {
        return {'total_referrals': 0, 'total_xp_earned': 0, 'total_money_earned': 0.0};
      }

      try {
        final referrals = await supabase
            .from('referrals')
            .select('*')
            .eq('referrer_user_id', userId);

        final totalReferrals = referrals.length;
        final totalXPEarned = totalReferrals * xpRewardForReferrer;
        final totalMoneyEarned = totalReferrals * portfolioRewardForReferrer;

        return {
          'total_referrals': totalReferrals,
          'total_xp_earned': totalXPEarned,
          'total_money_earned': totalMoneyEarned,
        };
      } catch (e) {
        // Table might not exist
        return {'total_referrals': 0, 'total_xp_earned': 0, 'total_money_earned': 0.0};
      }
    } catch (e) {
      return {'total_referrals': 0, 'total_xp_earned': 0, 'total_money_earned': 0.0};
    }
  }
}

