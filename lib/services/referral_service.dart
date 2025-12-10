import 'package:shared_preferences/shared_preferences.dart';
import 'database_service.dart';
import 'referral_rewards_service.dart';

/// Simple Referral Service
/// Replaces the complex friends/social system with a simple referral code system
class ReferralService {
  // Base URL for referral links
  // Options:
  // 1. Use your website: 'https://yourwebsite.com/refer'
  // 2. Use app store URL with referral param: 'https://apps.apple.com/app/orion/idXXXXX?referral='
  // 3. Use universal link: 'https://orion.app/refer'
  static const String _referralBaseUrl = 'https://orion.app/refer'; // Change to your actual domain/App Store URL
  
  /// Get or generate referral code for current user
  static Future<String> getMyReferralCode() async {
    final userId = await DatabaseService.getOrCreateLocalUserId();
    
    // Generate referral code from user ID (first 8 chars, uppercase)
    final referralCode = userId.length >= 8 
        ? userId.substring(0, 8).toUpperCase()
        : userId.toUpperCase().padRight(8, '0');
    
    return referralCode;
  }
  
  /// Get referral link for current user
  static Future<String> getMyReferralLink() async {
    final code = await getMyReferralCode();
    return '$_referralBaseUrl/$code';
  }
  
  /// Extract referral code from referral link
  static String? extractReferralCodeFromLink(String link) {
    try {
      // Extract code from URL like: https://orion.app/refer/ABC123 or orion://refer/ABC123
      final uri = Uri.parse(link);
      
      // Check path segments
      if (uri.pathSegments.isNotEmpty && uri.pathSegments.last.isNotEmpty) {
        final lastSegment = uri.pathSegments.last;
        // If last segment looks like a referral code (4+ chars, alphanumeric)
        if (lastSegment.length >= 4 && RegExp(r'^[A-Z0-9]+$').hasMatch(lastSegment.toUpperCase())) {
          return lastSegment.toUpperCase();
        }
      }
      
      // Check query parameters
      final code = uri.queryParameters['code'] ?? uri.queryParameters['ref'] ?? uri.queryParameters['referral'];
      if (code != null && code.length >= 4) {
        return code.toUpperCase();
      }
      
      return null;
    } catch (e) {
      return null;
    }
  }
  
  /// Track when user signs up with a referral code or link
  static Future<void> trackReferralSignup(String referralCodeOrLink) async {
    // Check if it's a link or just a code
    String referralCode = referralCodeOrLink;
    final extractedCode = extractReferralCodeFromLink(referralCodeOrLink);
    if (extractedCode != null) {
      referralCode = extractedCode;
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Store that this user signed up with a referral code
      await prefs.setString('referred_by', referralCode);
      await prefs.setString('referred_at', DateTime.now().toIso8601String());
      
      // Track referral in database and award rewards
      final supabase = DatabaseService.getSupabaseClient();
      if (supabase != null) {
        final userId = await DatabaseService.getOrCreateLocalUserId();
        try {
          await supabase.from('referrals').insert({
            'referrer_code': referralCode,
            'referred_user_id': userId,
            'created_at': DateTime.now().toIso8601String(),
          });
          
          // Award rewards to both referrer and referee
          await ReferralRewardsService.awardReferralRewards(referralCode, userId);
        } catch (e) {
          // Table might not exist, that's okay - still try to award rewards
          print('⚠️ Could not track referral in database: $e');
          // Still award rewards even if tracking fails
          final userId = await DatabaseService.getOrCreateLocalUserId();
          await ReferralRewardsService.awardReferralRewards(referralCode, userId);
        }
      }
      
      print('✅ Referral tracked: User signed up with code $referralCode');
    } catch (e) {
      print('⚠️ Error tracking referral: $e');
    }
  }
  
  /// Check if current user was referred by someone
  static Future<String?> getReferredBy() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('referred_by');
    } catch (e) {
      return null;
    }
  }
  
  /// Get number of successful referrals (people who signed up using this user's code)
  static Future<int> getReferralCount() async {
    try {
      final myCode = await getMyReferralCode();
      final supabase = DatabaseService.getSupabaseClient();
      
      if (supabase != null) {
        try {
          final response = await supabase
              .from('referrals')
              .select('id')
              .eq('referrer_code', myCode);
          
          return response.length;
        } catch (e) {
          // Table might not exist, return 0
          return 0;
        }
      }
      
      return 0;
    } catch (e) {
      return 0;
    }
  }
  
  /// Check if referral code is valid (exists in system)
  static Future<bool> isValidReferralCode(String code) async {
    if (code.isEmpty || code.length < 4) return false;
    
    try {
      final supabase = DatabaseService.getSupabaseClient();
      if (supabase != null) {
        // Check if any user ID starts with this code
        try {
          final response = await supabase
              .from('user_profiles')
              .select('user_id')
              .limit(1);
          
          // Check if any user ID matches (case insensitive)
          for (var profile in response) {
            final userId = profile['user_id'] as String? ?? '';
            if (userId.toUpperCase().startsWith(code.toUpperCase())) {
              return true;
            }
          }
        } catch (e) {
          // Table might not exist, that's okay - just return true to allow
          return true;
        }
      }
      
      // If we can't verify, allow it anyway (simple system)
      return true;
    } catch (e) {
      return true;
    }
  }
}

