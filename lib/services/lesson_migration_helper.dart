// Helper service to upload lessons to Supabase
// Call this once from your app (e.g., from a settings screen or admin panel)

import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/interactive_lessons.dart';
import '../data/learning_actions_content.dart';
import '../models/learning_action.dart';
import 'database_service.dart';

class LessonMigrationHelper {
  /// Upload all hardcoded lessons to Supabase
  /// Call this ONCE to migrate your 30 lessons to Supabase
  static Future<Map<String, dynamic>> uploadLessonsToSupabase() async {
    print('🚀 Starting lesson upload to Supabase...');
    
    try {
      final supabase = DatabaseService.getSupabaseClient();
      if (supabase == null) {
        return {
          'success': false,
          'error': 'Supabase not initialized',
          'uploaded': 0,
          'errors': 0,
        };
      }
      
      // Get hardcoded lessons directly (for migration)
      final hardcodedLessons = InteractiveLessons.getHardcodedLessons();
      
      print('📚 Found ${hardcodedLessons.length} lessons to upload');
      
      int uploaded = 0;
      int errors = 0;
      List<String> errorMessages = [];
      
      for (var lesson in hardcodedLessons) {
        try {
          // Get learning actions for this lesson
          final lessonId = lesson['id'] as String;
          final actions = LearningActionsContent.getActionsForLesson(lessonId);
          final actionsJson = actions.map((action) => action.toJson()).toList();
          
          // Prepare lesson data for Supabase
          final lessonData = {
            'id': lessonId,
            'title': lesson['title'],
            'description': lesson['description'],
            'content': lesson, // Store entire lesson as JSONB (includes steps, questions, etc.)
            'learning_actions': actionsJson, // Store learning actions
            'category': lesson['category'] ?? 'Basics',
            'difficulty': lesson['difficulty'] ?? 'Beginner',
            'duration': lesson['duration'] ?? 5,
            'xp_reward': lesson['xp_reward'] ?? 150,
            'icon': lesson['badge_emoji'] ?? '📚',
            'badge': lesson['badge'] ?? '',
            'badge_emoji': lesson['badge_emoji'] ?? '📚',
            'order_index': hardcodedLessons.indexOf(lesson),
            'is_active': true,
            'version': 1,
          };
          
          // Upload to Supabase
          await supabase.from('lessons').upsert(lessonData);
          
          uploaded++;
          print('✅ Uploaded: ${lesson['title']}');
        } catch (e) {
          errors++;
          final errorMsg = 'Error uploading ${lesson['title']}: $e';
          errorMessages.add(errorMsg);
          print('❌ $errorMsg');
        }
      }
      
      // Update version
      try {
        await supabase.from('lesson_versions').upsert({
          'version': 1,
          'total_lessons': uploaded,
          'updated_at': DateTime.now().toIso8601String(),
        });
        print('✅ Updated lesson version to 1');
      } catch (e) {
        print('⚠️ Error updating version: $e');
      }
      
      print('');
      print('🎉 Upload complete!');
      print('   ✅ Uploaded: $uploaded lessons');
      print('   ❌ Errors: $errors');
      
      return {
        'success': errors == 0,
        'uploaded': uploaded,
        'errors': errors,
        'errorMessages': errorMessages,
      };
      
    } catch (e, stackTrace) {
      print('❌ Fatal error uploading lessons: $e');
      print('Stack trace: $stackTrace');
      return {
        'success': false,
        'error': e.toString(),
        'uploaded': 0,
        'errors': 0,
      };
    }
  }
  
}

