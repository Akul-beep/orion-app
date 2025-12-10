import 'dart:developer' as developer;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'analytics_service.dart';
import 'database_service.dart';

/// PostHog Surveys Service - Integrates PostHog surveys (NPS, feedback, etc.)
/// Supports NPS (Net Promoter Score), feedback surveys, and custom surveys
class PostHogSurveysService {
  static const String _posthogApiKey = 'phc_TjMiRpV0vQxcRQrSbCX76iGXELIM3VwFbDe0qZs61aM';
  static const String _posthogHost = 'https://us.i.posthog.com';
  
  static bool _initialized = false;

  /// Initialize surveys service
  static Future<void> init() async {
    if (_initialized) return;
    _initialized = true;
    developer.log('✅ PostHog Surveys service initialized');
  }

  /// Get active surveys for the current user
  static Future<List<Map<String, dynamic>>> getActiveSurveys() async {
    try {
      final userId = await DatabaseService.getOrCreateLocalUserId();
      
      // Get surveys via PostHog API
      final response = await http.get(
        Uri.parse('$_posthogHost/api/surveys/?active=true'),
        headers: {
          'Authorization': 'Bearer $_posthogApiKey',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final surveys = List<Map<String, dynamic>>.from(data['results'] ?? []);
        
        // Filter surveys that should be shown to this user
        final activeSurveys = <Map<String, dynamic>>[];
        for (final survey in surveys) {
          if (await _shouldShowSurvey(survey, userId)) {
            activeSurveys.add(survey);
          }
        }
        
        return activeSurveys;
      } else {
        developer.log('⚠️ PostHog surveys API error: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      developer.log('⚠️ Error fetching surveys: $e');
      return [];
    }
  }

  /// Check if survey should be shown to user
  static Future<bool> _shouldShowSurvey(Map<String, dynamic> survey, String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final surveyId = survey['id']?.toString() ?? '';
      
      // Check if user already completed this survey
      final completedSurveys = prefs.getStringList('completed_surveys') ?? [];
      if (completedSurveys.contains(surveyId)) {
        return false;
      }
      
      // Check survey targeting conditions
      final conditions = survey['targeting_flag_filters'] ?? {};
      
      // For now, show all active surveys
      // You can add more targeting logic here based on user properties
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Submit survey response
  static Future<bool> submitSurveyResponse({
    required String surveyId,
    required Map<String, dynamic> responses,
  }) async {
    try {
      final userId = await DatabaseService.getOrCreateLocalUserId();
      
      // Track survey response in PostHog
      await AnalyticsService.trackEvent('survey_response', properties: {
        'survey_id': surveyId,
        'responses': responses,
      });
      
      // Mark survey as completed
      final prefs = await SharedPreferences.getInstance();
      final completedSurveys = prefs.getStringList('completed_surveys') ?? [];
      if (!completedSurveys.contains(surveyId)) {
        completedSurveys.add(surveyId);
        await prefs.setStringList('completed_surveys', completedSurveys);
      }
      
      developer.log('✅ Survey response submitted: $surveyId');
      return true;
    } catch (e) {
      developer.log('⚠️ Error submitting survey response: $e');
      return false;
    }
  }

  /// Submit NPS (Net Promoter Score) response
  static Future<bool> submitNPS({
    required int score, // 0-10
    String? feedback,
  }) async {
    try {
      await submitSurveyResponse(
        surveyId: 'nps_survey',
        responses: {
          'score': score,
          'feedback': feedback ?? '',
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
      
      // Track NPS score separately for analytics
      await AnalyticsService.trackEvent('nps_score', properties: {
        'score': score,
        'category': _getNPSCategory(score),
        'feedback': feedback,
      });
      
      developer.log('✅ NPS score submitted: $score');
      return true;
    } catch (e) {
      developer.log('⚠️ Error submitting NPS: $e');
      return false;
    }
  }

  /// Get NPS category from score
  static String _getNPSCategory(int score) {
    if (score >= 9) return 'promoter';
    if (score >= 7) return 'passive';
    return 'detractor';
  }

  /// Check if user should see NPS survey
  /// Shows after user has used app for a while (e.g., 7 days, completed 5+ lessons, etc.)
  static Future<bool> shouldShowNPSSurvey() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Check if already completed
      final completedSurveys = prefs.getStringList('completed_surveys') ?? [];
      if (completedSurveys.contains('nps_survey')) {
        return false;
      }
      
      // Check if user has been active enough
      final firstLaunchDate = prefs.getString('first_launch_date');
      if (firstLaunchDate != null) {
        final firstLaunch = DateTime.parse(firstLaunchDate);
        final daysSinceLaunch = DateTime.now().difference(firstLaunch).inDays;
        
        // Show NPS after 7 days of usage
        if (daysSinceLaunch >= 7) {
          // Also check if user has been active
          final lastActiveDate = prefs.getString('last_active_date');
          if (lastActiveDate != null) {
            final lastActive = DateTime.parse(lastActiveDate);
            final daysSinceLastActive = DateTime.now().difference(lastActive).inDays;
            
            // Only show if user was active recently (within last 3 days)
            if (daysSinceLastActive <= 3) {
              return true;
            }
          }
        }
      }
      
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Record app launch date (call on first launch)
  static Future<void> recordFirstLaunch() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getString('first_launch_date') == null) {
        await prefs.setString('first_launch_date', DateTime.now().toIso8601String());
      }
      await prefs.setString('last_active_date', DateTime.now().toIso8601String());
    } catch (e) {
      developer.log('⚠️ Error recording first launch: $e');
    }
  }

  /// Record user activity (call periodically)
  static Future<void> recordActivity() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('last_active_date', DateTime.now().toIso8601String());
    } catch (e) {
      developer.log('⚠️ Error recording activity: $e');
    }
  }
}

