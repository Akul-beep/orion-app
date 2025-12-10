import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/interactive_lessons.dart';
import '../data/learning_actions_content.dart';
import 'database_service.dart';

/// Dynamic Lesson Service - Fetches lessons from Supabase, caches locally
/// Allows updating lessons without app store releases
class DynamicLessonService {
  static final DynamicLessonService _instance = DynamicLessonService._internal();
  factory DynamicLessonService() => _instance;
  DynamicLessonService._internal();

  static const String _cachedLessonsKey = 'cached_lessons';
  static const String _cachedActionsKey = 'cached_learning_actions';
  static const String _lessonsVersionKey = 'lessons_version';
  static const String _lastUpdateKey = 'lessons_last_update';

  // Cache duration: 24 hours (lessons don't change that often)
  static const Duration _cacheDuration = Duration(hours: 24);

  bool _isInitialized = false;
  List<Map<String, dynamic>>? _cachedLessons;
  Map<String, List<dynamic>>? _cachedActions;

  /// Initialize service (check for updates on startup)
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    print('📚 Initializing Dynamic Lesson Service...');
    
    // Load cached lessons immediately (for offline support)
    await _loadCachedLessons();
    
    // Check for updates in background (don't block)
    _checkForUpdatesInBackground();
    
    _isInitialized = true;
    print('✅ Dynamic Lesson Service initialized');
  }

  /// Check for updates in background (non-blocking)
  void _checkForUpdatesInBackground() {
    Future.delayed(const Duration(seconds: 2), () async {
      try {
        final updatesAvailable = await hasUpdates();
        if (updatesAvailable) {
          print('🔄 New lessons available, fetching...');
          await getAllLessons(forceRefresh: true);
        }
      } catch (e) {
        print('⚠️ Error checking for updates: $e');
      }
    });
  }

  /// Get all lessons (from cache or fetch from server)
  Future<List<Map<String, dynamic>>> getAllLessons({bool forceRefresh = false}) async {
    try {
      // Check if we need to refresh
      if (!forceRefresh && await _isCacheValid()) {
        print('📚 Using cached lessons (${_cachedLessons?.length ?? 0} lessons)');
        return _cachedLessons ?? _getFallbackLessons();
      }

      // Fetch from Supabase
      print('🔄 Fetching lessons from Supabase...');
      final supabaseLessons = await _fetchLessonsFromServer();
      
      // Get hardcoded lessons (always include them)
      final hardcodedLessons = _getFallbackLessons();
      
      // Merge: Hardcoded lessons 1-30 + Supabase lessons 31+
      // Strategy: Keep hardcoded lessons, add Supabase lessons on top
      final mergedLessons = <Map<String, dynamic>>[];
      
      // Add hardcoded lessons first (lessons 1-30)
      mergedLessons.addAll(hardcodedLessons);
      
      // Add Supabase lessons (lessons 31+)
      // Filter out any Supabase lessons that have same ID as hardcoded (avoid duplicates)
      final hardcodedIds = hardcodedLessons.map((l) => l['id'] as String).toSet();
      for (final lesson in supabaseLessons) {
        final lessonId = lesson['id'] as String;
        if (!hardcodedIds.contains(lessonId)) {
          mergedLessons.add(lesson);
        }
      }
      
      if (supabaseLessons.isNotEmpty) {
        print('✅ Merged: ${hardcodedLessons.length} hardcoded + ${supabaseLessons.length} Supabase = ${mergedLessons.length} total lessons');
      } else {
        print('✅ Using ${hardcodedLessons.length} hardcoded lessons (no Supabase lessons yet)');
      }
      
      // Cache the merged lessons
      await _cacheLessons(mergedLessons);
      _cachedLessons = mergedLessons;
      
      return mergedLessons;
    } catch (e) {
      // Silently handle errors - just use hardcoded lessons
      print('📚 Using hardcoded lessons (${_getFallbackLessons().length} lessons)');
      // Fallback to cache even if expired, or fallback lessons
      if (_cachedLessons != null && _cachedLessons!.isNotEmpty) {
        return _cachedLessons!;
      }
      return _getFallbackLessons();
    }
  }

  /// Fetch lessons from Supabase
  Future<List<Map<String, dynamic>>> _fetchLessonsFromServer() async {
    try {
      final supabase = DatabaseService.getSupabaseClient();
      if (supabase == null) {
        print('⚠️ Supabase not available, using fallback');
        return [];
      }
      
      final response = await supabase
          .from('lessons')
          .select()
          .eq('is_active', true)
          .order('order_index');

      if (response.isEmpty) {
        return [];
      }

      // Convert to list of maps and extract content
      final lessons = <Map<String, dynamic>>[];
      for (final row in response) {
        final lesson = Map<String, dynamic>.from(row);
        
        // Extract content from JSONB
        if (lesson['content'] != null) {
          final content = lesson['content'];
          if (content is Map) {
            // Merge content into lesson (content contains all lesson data)
            lesson.addAll(Map<String, dynamic>.from(content));
          }
        }
        
        // Extract learning_actions if present
        if (lesson['learning_actions'] != null) {
          lesson['learning_actions'] = lesson['learning_actions'];
        }
        
        lessons.add(lesson);
      }

      return lessons;
    } catch (e) {
      // Silently handle missing table - just return empty list
      // This allows the app to work with just hardcoded lessons
      if (e.toString().contains('PGRST205') || e.toString().contains('table') || e.toString().contains('schema cache')) {
        print('📚 Lessons table not found in Supabase, using hardcoded lessons only');
        return [];
      }
      // For other errors, still return empty list (graceful degradation)
      print('⚠️ Error fetching lessons from Supabase (using hardcoded): ${e.toString().split('\n').first}');
      return [];
    }
  }

  /// Get a specific lesson by ID
  Future<Map<String, dynamic>?> getLessonById(String id) async {
    try {
      final lessons = await getAllLessons();
      try {
        return lessons.firstWhere((lesson) => lesson['id'] == id);
      } catch (e) {
        return null;
      }
    } catch (e) {
      print('⚠️ Error getting lesson by ID: $e');
      // Fallback to hardcoded lessons
      return InteractiveLessons.getLessonById(id);
    }
  }

  /// Get lessons by difficulty
  Future<List<Map<String, dynamic>>> getLessonsByDifficulty(String difficulty) async {
    try {
      final lessons = await getAllLessons();
      return lessons.where((lesson) => lesson['difficulty'] == difficulty).toList();
    } catch (e) {
      print('⚠️ Error getting lessons by difficulty: $e');
      return InteractiveLessons.getLessonsByDifficulty(difficulty);
    }
  }

  /// Get learning actions for a lesson
  Future<List<dynamic>> getLearningActionsForLesson(String lessonId) async {
    try {
      // Try to get from cached actions
      if (_cachedActions != null && _cachedActions!.containsKey(lessonId)) {
        return _cachedActions![lessonId]!;
      }

      // Try to get from lesson data
      final lesson = await getLessonById(lessonId);
      if (lesson != null && lesson['learning_actions'] != null) {
        final actions = lesson['learning_actions'];
        if (actions is List) {
          return actions;
        }
      }

      // Fallback to hardcoded actions
      final fallbackActions = LearningActionsContent.getActionsForLesson(lessonId);
      return fallbackActions.map((action) => action.toJson()).toList();
    } catch (e) {
      print('⚠️ Error getting learning actions: $e');
      // Fallback to hardcoded
      final fallbackActions = LearningActionsContent.getActionsForLesson(lessonId);
      return fallbackActions.map((action) => action.toJson()).toList();
    }
  }

  /// Check if cache is still valid
  Future<bool> _isCacheValid() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastUpdate = prefs.getString(_lastUpdateKey);
      
      if (lastUpdate == null) return false;
      
      final lastUpdateTime = DateTime.parse(lastUpdate);
      final now = DateTime.now();
      
      return now.difference(lastUpdateTime) < _cacheDuration;
    } catch (e) {
      return false;
    }
  }

  /// Load cached lessons from local storage
  Future<void> _loadCachedLessons() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString(_cachedLessonsKey);
      
      if (cached != null) {
        _cachedLessons = List<Map<String, dynamic>>.from(jsonDecode(cached));
        print('📦 Loaded ${_cachedLessons!.length} cached lessons');
      }

      // Load cached actions
      final cachedActions = prefs.getString(_cachedActionsKey);
      if (cachedActions != null) {
        _cachedActions = Map<String, List<dynamic>>.from(
          jsonDecode(cachedActions).map((key, value) => 
            MapEntry(key, List<dynamic>.from(value))
          )
        );
      }
    } catch (e) {
      print('⚠️ Error loading cached lessons: $e');
    }
  }

  /// Cache lessons locally
  Future<void> _cacheLessons(List<Map<String, dynamic>> lessons) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_cachedLessonsKey, jsonEncode(lessons));
      await prefs.setString(_lastUpdateKey, DateTime.now().toIso8601String());
      
      // Also cache version
      final supabase = DatabaseService.getSupabaseClient();
      if (supabase != null) {
        try {
          final versionResponse = await supabase
              .from('lesson_versions')
              .select()
              .order('version', ascending: false)
              .limit(1)
              .maybeSingle();
          
          if (versionResponse != null) {
            await prefs.setInt(_lessonsVersionKey, versionResponse['version'] as int);
          }
        } catch (e) {
          print('⚠️ Error caching version: $e');
        }
      }
      
      print('✅ Cached ${lessons.length} lessons locally');
    } catch (e) {
      print('⚠️ Error caching lessons: $e');
    }
  }

  /// Check for lesson updates (lightweight version check)
  Future<bool> hasUpdates() async {
    try {
      final supabase = DatabaseService.getSupabaseClient();
      if (supabase == null) return false;
      
      final prefs = await SharedPreferences.getInstance();
      final cachedVersion = prefs.getInt(_lessonsVersionKey) ?? 0;
      
      final versionResponse = await supabase
          .from('lesson_versions')
          .select()
          .order('version', ascending: false)
          .limit(1)
          .maybeSingle();
      
      if (versionResponse == null) return false;
      
      final serverVersion = versionResponse['version'] as int;
      return serverVersion > cachedVersion;
    } catch (e) {
      print('⚠️ Error checking for updates: $e');
      return false;
    }
  }

  /// Get fallback lessons (hardcoded - for offline/initial load)
  List<Map<String, dynamic>> _getFallbackLessons() {
    print('📚 Using fallback lessons (hardcoded)');
    return InteractiveLessons.getHardcodedLessons();
  }

  /// Save user lesson progress
  Future<void> saveLessonProgress({
    required String lessonId,
    required bool isCompleted,
    required int xpEarned,
    int? score,
    bool? perfectScore,
    Map<String, dynamic>? progressData,
  }) async {
    try {
      final supabase = DatabaseService.getSupabaseClient();
      if (supabase == null) {
        print('⚠️ Supabase not available, cannot save progress');
        return;
      }

      final userId = supabase.auth.currentUser?.id;
      if (userId == null) {
        print('⚠️ User not authenticated, cannot save progress');
        return;
      }

      await supabase.from('user_lesson_progress').upsert({
        'user_id': userId,
        'lesson_id': lessonId,
        'is_completed': isCompleted,
        'xp_earned': xpEarned,
        'score': score,
        'perfect_score': perfectScore ?? false,
        'completed_at': isCompleted ? DateTime.now().toIso8601String() : null,
        'last_accessed_at': DateTime.now().toIso8601String(),
        'progress_data': progressData,
      });

      print('✅ Saved lesson progress for $lessonId');
    } catch (e) {
      print('⚠️ Error saving lesson progress: $e');
    }
  }

  /// Get user lesson progress
  Future<Map<String, dynamic>?> getLessonProgress(String lessonId) async {
    try {
      final supabase = DatabaseService.getSupabaseClient();
      if (supabase == null) return null;

      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return null;

      final response = await supabase
          .from('user_lesson_progress')
          .select()
          .eq('user_id', userId)
          .eq('lesson_id', lessonId)
          .maybeSingle();

      if (response == null) return null;
      return Map<String, dynamic>.from(response);
    } catch (e) {
      print('⚠️ Error getting lesson progress: $e');
      return null;
    }
  }

  /// Get all user lesson progress
  Future<Map<String, Map<String, dynamic>>> getAllLessonProgress() async {
    try {
      final supabase = DatabaseService.getSupabaseClient();
      if (supabase == null) return {};

      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return {};

      final response = await supabase
          .from('user_lesson_progress')
          .select()
          .eq('user_id', userId);

      final progressMap = <String, Map<String, dynamic>>{};
      for (final row in response) {
        progressMap[row['lesson_id'] as String] = Map<String, dynamic>.from(row);
      }

      return progressMap;
    } catch (e) {
      print('⚠️ Error getting all lesson progress: $e');
      return {};
    }
  }
}

