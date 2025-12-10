import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'database_service.dart';
import 'analytics_service.dart';

/// Feedback Service for managing user feedback and feature requests
/// Stores feedback in Supabase with local fallback
class FeedbackService {
  static SupabaseClient? _supabase;
  static SharedPreferences? _prefs;

  /// Initialize feedback service
  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    try {
      _supabase = Supabase.instance.client;
    } catch (e) {
      _supabase = null;
      print('⚠️ Feedback service: Supabase not available, using local storage');
    }
  }

  /// Submit feedback or feature request
  static Future<bool> submitFeedback({
    required String title,
    required String description,
    String? category, // e.g., 'feature_request', 'bug_report', 'improvement'
    String? priority, // e.g., 'low', 'medium', 'high'
  }) async {
    try {
      final userId = await DatabaseService.getOrCreateLocalUserId();
      final feedbackData = {
        'user_id': userId,
        'title': title,
        'description': description,
        'category': category ?? 'feature_request',
        'priority': priority ?? 'medium',
        'upvotes': 0,
        'status': 'open', // 'open', 'in_progress', 'completed', 'rejected'
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      // Try Supabase first with timeout
      if (_supabase != null) {
        try {
          await _supabase!.from('feedback').insert(feedbackData)
              .timeout(const Duration(seconds: 3)); // 3 second timeout
          print('✅ Feedback submitted to Supabase');
          
          // Track analytics in background (non-blocking)
          AnalyticsService.trackFeedbackSubmitted(
            feedbackType: category ?? 'feature_request',
            category: category,
          ).catchError((e) => print('Analytics error: $e'));
          
          return true;
        } catch (e) {
          print('⚠️ Supabase feedback submission failed or timed out: $e');
          // Fall through to local storage
        }
      }

      // Fallback to local storage
      final localFeedbacks = _prefs?.getStringList('local_feedback') ?? [];
      localFeedbacks.add(jsonEncode({
        ...feedbackData,
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
      }));
      await _prefs?.setStringList('local_feedback', localFeedbacks);
      
      // Track analytics in background (non-blocking)
      AnalyticsService.trackFeedbackSubmitted(
        feedbackType: category ?? 'feature_request',
        category: category,
      ).catchError((e) => print('Analytics error: $e'));
      
      print('✅ Feedback saved locally');
      return true;
    } catch (e) {
      print('❌ Error submitting feedback: $e');
      return false;
    }
  }

  /// Get all feedback items (for admin or user's own feedback)
  static Future<List<Map<String, dynamic>>> getFeedback({
    String? status,
    String? category,
    int limit = 50,
  }) async {
    try {
      if (_supabase != null) {
        try {
          var query = _supabase!.from('feedback').select();
          
          if (status != null) {
            query = query.eq('status', status);
          }
          if (category != null) {
            query = query.eq('category', category);
          }
          
          final response = await query.order('upvotes', ascending: false).limit(limit);
          return List<Map<String, dynamic>>.from(response);
        } catch (e) {
          print('⚠️ Supabase feedback fetch failed: $e');
        }
      }

      // Fallback to local storage
      final localFeedbacks = _prefs?.getStringList('local_feedback') ?? [];
      return localFeedbacks
          .map((item) => Map<String, dynamic>.from(jsonDecode(item)))
          .where((item) {
            if (status != null && item['status'] != status) return false;
            if (category != null && item['category'] != category) return false;
            return true;
          })
          .toList()
        ..sort((a, b) => (b['upvotes'] ?? 0).compareTo(a['upvotes'] ?? 0));
    } catch (e) {
      print('❌ Error fetching feedback: $e');
      return [];
    }
  }

  /// Upvote a feedback item
  static Future<bool> upvoteFeedback(String feedbackId) async {
    try {
      final userId = await DatabaseService.getOrCreateLocalUserId();
      
      if (_supabase != null) {
        try {
          // Check if user already upvoted
          final existingVote = await _supabase!
              .from('feedback_votes')
              .select()
              .eq('feedback_id', feedbackId)
              .eq('user_id', userId)
              .maybeSingle();
          
          if (existingVote != null) {
            // User already upvoted, remove upvote
            await _supabase!
                .from('feedback_votes')
                .delete()
                .eq('feedback_id', feedbackId)
                .eq('user_id', userId);
            
            // Decrement upvotes
            await _supabase!
                .rpc('decrement_feedback_upvotes', params: {'feedback_id': feedbackId});
            
            print('✅ Upvote removed');
            return true;
          } else {
            // Add upvote
            await _supabase!.from('feedback_votes').insert({
              'feedback_id': feedbackId,
              'user_id': userId,
              'created_at': DateTime.now().toIso8601String(),
            });
            
            // Increment upvotes
            await _supabase!
                .rpc('increment_feedback_upvotes', params: {'feedback_id': feedbackId});
            
            print('✅ Upvote added');
            return true;
          }
        } catch (e) {
          print('⚠️ Supabase upvote failed: $e');
          // If RPC functions don't exist, manually update
          try {
            final feedback = await _supabase!
                .from('feedback')
                .select('upvotes')
                .eq('id', feedbackId)
                .single();
            
            final currentUpvotes = feedback['upvotes'] ?? 0;
            final existingVote = await _supabase!
                .from('feedback_votes')
                .select()
                .eq('feedback_id', feedbackId)
                .eq('user_id', userId)
                .maybeSingle();
            
            if (existingVote != null) {
              // Remove upvote
              await _supabase!
                  .from('feedback_votes')
                  .delete()
                  .eq('feedback_id', feedbackId)
                  .eq('user_id', userId);
              await _supabase!
                  .from('feedback')
                  .update({'upvotes': currentUpvotes - 1})
                  .eq('id', feedbackId);
            } else {
              // Add upvote
              await _supabase!.from('feedback_votes').insert({
                'feedback_id': feedbackId,
                'user_id': userId,
                'created_at': DateTime.now().toIso8601String(),
              });
              await _supabase!
                  .from('feedback')
                  .update({'upvotes': currentUpvotes + 1})
                  .eq('id', feedbackId);
            }
            return true;
          } catch (e2) {
            print('⚠️ Manual upvote update failed: $e2');
          }
        }
      }

      // Fallback to local storage
      final localFeedbacks = _prefs?.getStringList('local_feedback') ?? [];
      final updatedFeedbacks = localFeedbacks.map((item) {
        final feedback = Map<String, dynamic>.from(jsonDecode(item));
        if (feedback['id'] == feedbackId) {
          feedback['upvotes'] = (feedback['upvotes'] ?? 0) + 1;
        }
        return jsonEncode(feedback);
      }).toList();
      await _prefs?.setStringList('local_feedback', updatedFeedbacks);
      return true;
    } catch (e) {
      print('❌ Error upvoting feedback: $e');
      return false;
    }
  }

  /// Check if user has upvoted a feedback item
  static Future<bool> hasUserUpvoted(String feedbackId) async {
    try {
      final userId = await DatabaseService.getOrCreateLocalUserId();
      
      if (_supabase != null) {
        try {
          final vote = await _supabase!
              .from('feedback_votes')
              .select()
              .eq('feedback_id', feedbackId)
              .eq('user_id', userId)
              .maybeSingle();
          return vote != null;
        } catch (e) {
          print('⚠️ Check upvote failed: $e');
        }
      }

      // Fallback: check local storage
      final localFeedbacks = _prefs?.getStringList('local_feedback') ?? [];
      final upvotedIds = _prefs?.getStringList('upvoted_feedback_ids') ?? [];
      return upvotedIds.contains(feedbackId);
    } catch (e) {
      return false;
    }
  }

  /// Get user's own feedback submissions
  static Future<List<Map<String, dynamic>>> getUserFeedback() async {
    try {
      final userId = await DatabaseService.getOrCreateLocalUserId();
      
      if (_supabase != null) {
        try {
          final response = await _supabase!
              .from('feedback')
              .select()
              .eq('user_id', userId)
              .order('created_at', ascending: false);
          return List<Map<String, dynamic>>.from(response);
        } catch (e) {
          print('⚠️ Supabase user feedback fetch failed: $e');
        }
      }

      // Fallback to local storage
      final localFeedbacks = _prefs?.getStringList('local_feedback') ?? [];
      return localFeedbacks
          .map((item) => Map<String, dynamic>.from(jsonDecode(item)))
          .where((item) => item['user_id'] == userId)
          .toList()
        ..sort((a, b) => (b['created_at'] ?? '').compareTo(a['created_at'] ?? ''));
    } catch (e) {
      print('❌ Error fetching user feedback: $e');
      return [];
    }
  }
}

