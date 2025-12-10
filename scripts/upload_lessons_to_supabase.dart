// Migration script to upload existing lessons to Supabase
// Run this once to migrate your 30 lessons to Supabase
// 
// Usage: 
// 1. Make sure Supabase is initialized in your app
// 2. Call runLessonMigration() from your app (e.g., from a button in settings)
// 3. This will upload all lessons from InteractiveLessons to Supabase

import 'package:supabase_flutter/supabase_flutter.dart';
import '../lib/data/interactive_lessons.dart';
import '../lib/data/learning_actions_content.dart';
import '../lib/models/learning_action.dart';

Future<void> uploadLessonsToSupabase() async {
  print('🚀 Starting lesson upload to Supabase...');
  
  try {
    final supabase = Supabase.instance.client;
    // Get hardcoded lessons (fallback method)
    final lessons = InteractiveLessons._getHardcodedLessons();
    
    print('📚 Found ${lessons.length} lessons to upload');
    
    int uploaded = 0;
    int errors = 0;
    
    for (var lesson in lessons) {
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
          'order_index': lessons.indexOf(lesson),
          'is_active': true,
          'version': 1,
        };
        
        // Upload to Supabase
        await supabase.from('lessons').upsert(lessonData);
        
        uploaded++;
        print('✅ Uploaded: ${lesson['title']}');
      } catch (e) {
        errors++;
        print('❌ Error uploading ${lesson['title']}: $e');
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
    print('');
    print('📝 Next steps:');
    print('   1. Verify lessons in Supabase dashboard');
    print('   2. Test app with DynamicLessonService');
    print('   3. Add more lessons via Supabase (no app update needed!)');
    
  } catch (e, stackTrace) {
    print('❌ Fatal error uploading lessons: $e');
    print('Stack trace: $stackTrace');
  }
}

// Helper function to run from app (call this from a button or on app start)
Future<void> runLessonMigration() async {
  await uploadLessonsToSupabase();
}

