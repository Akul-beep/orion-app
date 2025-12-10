import 'package:flutter/material.dart';
import 'database_service.dart';
import 'gamification_service.dart';
import 'paper_trading_service.dart';

/// Personalization service for AI recommendations and custom learning paths
class PersonalizationService extends ChangeNotifier {
  List<String> _recommendedLessons = [];
  List<String> _recommendedStocks = [];
  Map<String, dynamic> _userPreferences = {};
  String _learningPath = 'beginner'; // beginner, intermediate, advanced

  List<String> get recommendedLessons => _recommendedLessons;
  List<String> get recommendedStocks => _recommendedStocks;
  Map<String, dynamic> get userPreferences => _userPreferences;
  String get learningPath => _learningPath;

  /// Load user preferences
  Future<void> loadUserPreferences() async {
    try {
      final userId = await DatabaseService.getOrCreateLocalUserId();
      final supabase = DatabaseService.getSupabaseClient();
      
      if (supabase != null) {
        final response = await supabase
            .from('user_preferences')
            .select()
            .eq('user_id', userId)
            .maybeSingle();
        
        if (response != null) {
          _userPreferences = Map<String, dynamic>.from(response);
          _learningPath = response['learning_path'] ?? 'beginner';
        }
      }
      
      await _generateRecommendations();
      notifyListeners();
    } catch (e) {
      print('Error loading user preferences: $e');
    }
  }

  /// Generate personalized recommendations
  Future<void> _generateRecommendations() async {
    // Analyze user progress, trading activity, and preferences
    // This would use AI/ML in production, but for now we'll use simple rules
    
    final completedActions = await DatabaseService.getCompletedActions();
    final completedCount = completedActions.length;
    
    // Determine learning path based on progress
    if (completedCount < 5) {
      _learningPath = 'beginner';
    } else if (completedCount < 15) {
      _learningPath = 'intermediate';
    } else {
      _learningPath = 'advanced';
    }
    
    // Generate lesson recommendations
    _recommendedLessons = _getRecommendedLessons(_learningPath, completedActions);
    
    // Generate stock recommendations based on user activity
    _recommendedStocks = _getRecommendedStocks();
    
    notifyListeners();
  }

  List<String> _getRecommendedLessons(String path, List<String> completed) {
    // Simple recommendation logic
    // In production, this would use ML models
    
    final allLessons = ['1', '2', '3', '4', '5', '6', '7', '8', '9', '10'];
    final uncompleted = allLessons.where((id) => 
      !completed.contains('lesson_$id') && 
      !completed.contains('lesson_${id}_completed')
    ).toList();
    
    // Return next 3 uncompleted lessons
    return uncompleted.take(3).toList();
  }

  List<String> _getRecommendedStocks() {
    // Recommend popular stocks for beginners
    // In production, this would analyze user's trading history
    return ['AAPL', 'TSLA', 'GOOGL', 'MSFT', 'AMZN'];
  }

  /// Update learning path
  Future<void> updateLearningPath(String path) async {
    _learningPath = path;
    await _savePreferences();
    await _generateRecommendations();
  }

  /// Save preferences
  Future<void> _savePreferences() async {
    try {
      final userId = await DatabaseService.getOrCreateLocalUserId();
      final supabase = DatabaseService.getSupabaseClient();
      
      if (supabase != null) {
        await supabase.from('user_preferences').upsert({
          'user_id': userId,
          'learning_path': _learningPath,
          'preferences': _userPreferences,
          'updated_at': DateTime.now().toIso8601String(),
        });
      }
    } catch (e) {
      print('Error saving preferences: $e');
    }
  }
}






