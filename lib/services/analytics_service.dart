import 'dart:developer' as developer;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:io';
import 'database_service.dart';

/// Analytics Service using PostHog (Free tier: 1M events/month)
/// Tracks user behavior, retention, churn, and key metrics
class AnalyticsService {
  static const String _posthogApiKey = 'phc_TjMiRpV0vQxcRQrSbCX76iGXELIM3VwFbDe0qZs61aM';
  // Using US region endpoint to match your web snippet
  static const String _posthogHost = 'https://us.i.posthog.com'; 
  static const String _apiEndpoint = '$_posthogHost/capture/';
  
  static bool _initialized = false;
  static String? _distinctId;
  static Map<String, dynamic>? _userProperties;

  /// Initialize analytics service
  static Future<void> init() async {
    if (_initialized) return;
    
    try {
      // Get or create user ID
      _distinctId = await DatabaseService.getOrCreateLocalUserId();
      
      // Load saved user properties
      final prefs = await SharedPreferences.getInstance();
      final savedProps = prefs.getString('analytics_user_properties');
      if (savedProps != null) {
        _userProperties = Map<String, dynamic>.from(jsonDecode(savedProps));
      } else {
        _userProperties = {};
      }
      
      // Identify user if authenticated
      final userId = DatabaseService.getUserId();
      if (userId != null && userId != _distinctId) {
        await identify(userId);
      }
      
      _initialized = true;
      developer.log('✅ Analytics service initialized');
      developer.log('   PostHog endpoint: $_apiEndpoint');
      developer.log('   API Key: ${_posthogApiKey.substring(0, 10)}...');
      
      // Track app opened event
      await trackEvent('app_opened', properties: {
        'platform': Platform.isIOS ? 'iOS' : Platform.isAndroid ? 'Android' : 'Web',
      });
      
      developer.log('📊 Initial app_opened event sent');
    } catch (e) {
      developer.log('⚠️ Analytics initialization failed: $e');
    }
  }

  /// Identify user (call after login/signup)
  static Future<void> identify(String userId, {Map<String, dynamic>? properties}) async {
    try {
      _distinctId = userId;
      
      if (properties != null) {
        _userProperties = {...?_userProperties, ...properties};
        
        // Save properties
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('analytics_user_properties', jsonEncode(_userProperties));
      }
      
      await _capture({
        'event': '\$identify',
        'distinct_id': userId,
        'properties': {
          '\$set': _userProperties ?? {},
          'timestamp': DateTime.now().toIso8601String(),
        },
      });
      
      developer.log('✅ User identified: $userId');
    } catch (e) {
      developer.log('⚠️ Analytics identify failed: $e');
    }
  }

  /// Track custom event
  static Future<void> trackEvent(
    String eventName, {
    Map<String, dynamic>? properties,
  }) async {
    if (!_initialized) await init();
    
    try {
      final userId = _distinctId ?? await DatabaseService.getOrCreateLocalUserId();
      final eventProperties = {
        ...?_userProperties,
        ...?properties,
        '\$lib': 'flutter',
        '\$lib_version': '1.0.0',
      };
      
      await _capture({
        'event': eventName,
        'distinct_id': userId,
        'properties': eventProperties,
        'timestamp': DateTime.now().toUtc().toIso8601String(),
      });
      
      developer.log('📊 Event tracked: $eventName');
    } catch (e) {
      developer.log('⚠️ Analytics track failed: $e');
    }
  }

  /// Track screen view
  static Future<void> trackScreenView(String screenName) async {
    await trackEvent('screen_view', properties: {
      'screen_name': screenName,
    });
  }

  /// Track user signup
  static Future<void> trackSignup({String? email, String? method}) async {
    await trackEvent('user_signed_up', properties: {
      'email': email,
      'signup_method': method ?? 'email',
    });
  }

  /// Track user login
  static Future<void> trackLogin({String? email, String? method}) async {
    await trackEvent('user_logged_in', properties: {
      'email': email,
      'login_method': method ?? 'email',
    });
  }

  /// Track password reset request
  static Future<void> trackPasswordResetRequest({String? email}) async {
    await trackEvent('password_reset_requested', properties: {
      'email': email,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  /// Track password reset email sent
  static Future<void> trackPasswordResetEmailSent({String? email, bool success = true}) async {
    await trackEvent('password_reset_email_sent', properties: {
      'email': email,
      'success': success,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  /// Track password reset completed
  static Future<void> trackPasswordResetCompleted({String? email}) async {
    await trackEvent('password_reset_completed', properties: {
      'email': email,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  /// Track trade execution
  static Future<void> trackTrade({
    required String symbol,
    required String action, // 'buy' or 'sell'
    required double shares,
    required double price,
    double? totalValue,
  }) async {
    await trackEvent('trade_executed', properties: {
      'symbol': symbol,
      'action': action,
      'shares': shares,
      'price': price,
      'total_value': totalValue ?? (shares * price),
    });
  }

  /// Track lesson completion
  static Future<void> trackLessonCompleted({
    required String moduleId,
    required String lessonId,
    int? xpEarned,
  }) async {
    await trackEvent('lesson_completed', properties: {
      'module_id': moduleId,
      'lesson_id': lessonId,
      'xp_earned': xpEarned,
    });
  }

  /// Track achievement unlocked
  static Future<void> trackAchievement(String achievementId) async {
    await trackEvent('achievement_unlocked', properties: {
      'achievement_id': achievementId,
    });
  }

  /// Track feature request submitted
  static Future<void> trackFeedbackSubmitted({
    required String feedbackType,
    String? category,
  }) async {
    await trackEvent('feedback_submitted', properties: {
      'feedback_type': feedbackType,
      'category': category,
    });
  }

  /// Track session start (call when user opens app)
  static Future<void> trackSessionStart() async {
    await trackEvent('session_start', properties: {
      'session_id': DateTime.now().millisecondsSinceEpoch.toString(),
    });
  }

  /// Track session end (call when user closes app or becomes inactive)
  static Future<void> trackSessionEnd({Duration? sessionDuration}) async {
    await trackEvent('session_end', properties: {
      'session_duration_seconds': sessionDuration?.inSeconds,
    });
  }

  /// Track retention event (call daily to measure retention)
  static Future<void> trackRetention({required int daysSinceSignup}) async {
    await trackEvent('retention_day_$daysSinceSignup', properties: {
      'days_since_signup': daysSinceSignup,
    });
  }

  /// Track churn risk indicators
  static Future<void> trackChurnRisk({
    required String reason,
    int? daysSinceLastActive,
  }) async {
    await trackEvent('churn_risk_detected', properties: {
      'reason': reason,
      'days_since_last_active': daysSinceLastActive,
    });
  }

  /// Set user properties (for filtering in PostHog)
  static Future<void> setUserProperties(Map<String, dynamic> properties) async {
    _userProperties = {...?_userProperties, ...properties};
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('analytics_user_properties', jsonEncode(_userProperties));
    
    // Update in PostHog
    if (_distinctId != null) {
      await identify(_distinctId!, properties: properties);
    }
  }

  /// Track app opened (daily active users)
  static Future<void> trackAppOpened() async {
    await trackEvent('app_opened', properties: {
      'date': DateTime.now().toIso8601String().split('T')[0],
    });
  }

  /// Internal method to send events to PostHog
  static Future<void> _capture(Map<String, dynamic> data) async {
    if (_posthogApiKey == 'YOUR_POSTHOG_API_KEY') {
      developer.log('⚠️ PostHog API key not configured. Analytics disabled.');
      return;
    }
    
    try {
      final distinctId = data['distinct_id'] ?? await DatabaseService.getOrCreateLocalUserId();
      
      // PostHog batch API format (correct format)
      final eventData = {
        'api_key': _posthogApiKey,
        'batch': [
          {
            'event': data['event'],
            'distinct_id': distinctId,
            'properties': data['properties'] ?? {},
            'timestamp': data['timestamp'] ?? DateTime.now().toUtc().toIso8601String(),
          }
        ],
      };
      
      developer.log('📤 Sending PostHog event: ${data['event']}');
      developer.log('   Distinct ID: $distinctId');
      developer.log('   Endpoint: $_apiEndpoint');
      
      final response = await http.post(
        Uri.parse('$_posthogHost/batch/'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(eventData),
      ).timeout(const Duration(seconds: 5));
      
      developer.log('📥 PostHog response: ${response.statusCode}');
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        developer.log('✅ PostHog event sent successfully: ${data['event']}');
      } else {
        developer.log('⚠️ PostHog API error: ${response.statusCode}');
        developer.log('   Response body: ${response.body}');
        developer.log('   Event: ${data['event']}');
        developer.log('   Full request: ${jsonEncode(eventData)}');
      }
    } catch (e, stackTrace) {
      developer.log('❌ PostHog request failed: $e');
      developer.log('   Stack trace: $stackTrace');
      // Fail silently - don't block app functionality
    }
  }

  /// Reset analytics (for logout)
  static Future<void> reset() async {
    _distinctId = null;
    _userProperties = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('analytics_user_properties');
    _initialized = false;
  }
}

