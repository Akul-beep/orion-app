import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'database_service.dart';
import '../data/interactive_lessons.dart';

/// Service for fetching lessons from Supabase (remote) or local fallback
/// This allows adding new lessons without app updates!
class RemoteLessonService {
  /// Fetch lessons from Supabase or fallback to local
  static Future<List<Map<String, dynamic>>> fetchLessons({
    int? limit,
    String? difficulty,
    bool activeOnly = true,
    int? minLevel,
  }) async {
    try {
      final supabase = DatabaseService.getSupabaseClient();
      
      // If Supabase not available, use local lessons
      if (supabase == null || !DatabaseService.isSupabaseAvailable) {
        print('📚 Using local lessons (Supabase not available)');
        return await _filterLocalLessons(
          difficulty: difficulty,
          limit: limit,
        );
      }

      // Fetch from Supabase
      // Build query chain: filters first, then ordering and limit
      var query = supabase
          .from('lessons')
          .select();

      // Apply filters
      if (activeOnly) {
        query = query.eq('is_active', true);
      }

      if (difficulty != null) {
        query = query.eq('difficulty', difficulty);
      }

      if (minLevel != null) {
        query = query.lte('unlock_level', minLevel);
      }

      // Chain ordering and limit - these return PostgrestTransformBuilder
      // so we need to build the final query chain
      dynamic finalQuery = query;
      finalQuery = finalQuery.order('order_index', ascending: true);

      if (limit != null) {
        finalQuery = finalQuery.limit(limit);
      }

      final response = await finalQuery;
      final remoteLessons = List<Map<String, dynamic>>.from(response);
      
      print('📚 Fetched ${remoteLessons.length} remote lessons');
      
      // Combine with local lessons (local lessons take priority)
      final localLessons = await InteractiveLessons.getAllLessons();
      final allLessons = [...localLessons, ...remoteLessons];
      
      return allLessons;
    } catch (e) {
      print('❌ Error fetching remote lessons: $e');
      // Fallback to local lessons
      return await _filterLocalLessons(
        difficulty: difficulty,
        limit: limit,
      );
    }
  }

  /// Filter local lessons
  static Future<List<Map<String, dynamic>>> _filterLocalLessons({
    String? difficulty,
    int? limit,
  }) async {
    var lessons = await InteractiveLessons.getAllLessons();
    
    if (difficulty != null) {
      lessons = lessons.where((l) => l['difficulty'] == difficulty).toList();
    }
    
    if (limit != null && limit < lessons.length) {
      lessons = lessons.take(limit).toList();
    }
    
    return lessons;
  }

  /// Sync lessons from remote and cache locally
  static Future<void> syncLessons() async {
    try {
      final lessons = await fetchLessons(activeOnly: true);
      await _cacheLessons(lessons);
      print('✅ Lessons synced and cached');
    } catch (e) {
      print('❌ Error syncing lessons: $e');
    }
  }

  /// Cache lessons locally for offline access
  static Future<void> _cacheLessons(List<Map<String, dynamic>> lessons) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('cached_lessons', jsonEncode(lessons));
    } catch (e) {
      print('Error caching lessons: $e');
    }
  }

  /// Get cached lessons (for offline access)
  static Future<List<Map<String, dynamic>>> getCachedLessons() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString('cached_lessons');
      if (cached != null) {
        return List<Map<String, dynamic>>.from(jsonDecode(cached));
      }
    } catch (e) {
      print('Error loading cached lessons: $e');
    }
    
    // Fallback to local lessons
    return await InteractiveLessons.getAllLessons();
  }

  /// Check if a lesson can be unlocked based on requirements
  static bool canUnlockLesson(
    Map<String, dynamic> lesson,
    int userLevel,
    int userStreak,
    List<String> userBadges,
  ) {
    final requirements = lesson['unlock_requirement'] as Map<String, dynamic>?;
    if (requirements == null) return true;

    // Check level requirement
    final requiredLevel = requirements['level'] as int?;
    if (requiredLevel != null && userLevel < requiredLevel) {
      return false;
    }

    // Check streak requirement
    final requiredStreak = requirements['streak'] as int?;
    if (requiredStreak != null && userStreak < requiredStreak) {
      return false;
    }

    // Check badge requirement
    final requiredBadge = requirements['badge'] as String?;
    if (requiredBadge != null && !userBadges.contains(requiredBadge)) {
      return false;
    }

    return true;
  }
}

