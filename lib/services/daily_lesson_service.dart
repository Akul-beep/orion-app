import 'package:flutter/material.dart';
import 'database_service.dart';
import 'remote_lesson_service.dart';
import 'gamification_service.dart';
import '../data/interactive_lessons.dart';
import '../data/learning_pathway.dart';

class DailyLessonService extends ChangeNotifier {
  static final DailyLessonService _instance = DailyLessonService._internal();
  factory DailyLessonService() => _instance;
  DailyLessonService._internal();

  List<String> _unlockedLessons = []; // Changed to String IDs
  Map<String, DateTime> _lessonUnlockDates = {}; // Track when each lesson was unlocked
  DateTime? _lastUnlockDate;
  int _lessonsUnlockedToday = 0;
  static const int maxLessonsPerDay = 1; // Unlock 1 lesson per day

  List<String> get unlockedLessons => _unlockedLessons;
  int get lessonsUnlockedToday => _lessonsUnlockedToday;
  bool get canUnlockMoreToday => _lessonsUnlockedToday < maxLessonsPerDay;

  Future<void> initialize() async {
    await _loadUnlockedLessons();
    await _ensureFirstLessonUnlocked(); // CRITICAL: Always unlock first lesson
    await _validateUnlockedLessons(); // Ensure only sequential lessons are unlocked
    await _checkDailyUnlock();
    await _fixMissingUnlockDates(); // Fix any lessons that are unlocked but missing unlock dates
  }
  
  /// Fix lessons that are unlocked but missing unlock dates
  /// This can happen if data was migrated or corrupted
  Future<void> _fixMissingUnlockDates() async {
    bool needsSave = false;
    final now = DateTime.now();
    
    for (final lessonId in _unlockedLessons) {
      if (!_lessonUnlockDates.containsKey(lessonId)) {
        // Lesson is unlocked but has no unlock date
        // Set it to a past date (7 days ago) so it's immediately accessible
        // This fixes the issue where users can't access lessons they should be able to
        final pastDate = now.subtract(const Duration(days: 7));
        _lessonUnlockDates[lessonId] = pastDate;
        print('🔧 Fixed missing unlock date for lesson $lessonId (set to 7 days ago)');
        needsSave = true;
      }
    }
    
    if (needsSave) {
      await _saveUnlockedLessons();
      notifyListeners();
    }
  }
  
  // Ensure the first lesson (day 1) is always unlocked
  Future<void> _ensureFirstLessonUnlocked() async {
    final firstLessonId = LearningPathway.getLessonIdForDay(1);
    if (firstLessonId == null) {
      print('⚠️ Could not find first lesson (day 1)');
      return;
    }
    
    // Always unlock the first lesson if it's not already unlocked
    if (!_unlockedLessons.contains(firstLessonId)) {
      print('🔓 Unlocking first lesson: $firstLessonId');
      final now = DateTime.now();
      _unlockedLessons.insert(0, firstLessonId); // Add at beginning
      _lessonUnlockDates[firstLessonId] = now;
      
      // If this is the first time, set lastUnlockDate
      if (_lastUnlockDate == null) {
        _lastUnlockDate = now;
      }
      
      await _saveUnlockedLessons();
      notifyListeners();
    }
  }
  
  // Validate that only sequential lessons are unlocked (fix any incorrect unlocks)
  Future<void> _validateUnlockedLessons() async {
    final completed = await DatabaseService.getCompletedActions();
    final validUnlockedLessons = <String>[];
    
    // Go through lessons in pathway order (day 1-30)
    for (int day = 1; day <= 30; day++) {
      final lessonId = LearningPathway.getLessonIdForDay(day);
      if (lessonId == null) continue;
      
      // Day 1 is always unlocked
      if (day == 1) {
        if (!validUnlockedLessons.contains(lessonId)) {
          validUnlockedLessons.add(lessonId);
        }
        continue;
      }
      
      // For other days, check if previous lesson is completed
      final prevLessonId = LearningPathway.getLessonIdForDay(day - 1);
      if (prevLessonId != null) {
        final prevCompleted = completed.contains('lesson_$prevLessonId') || 
                            completed.contains('lesson_${prevLessonId}_completed');
        
        // Only unlock if previous lesson is completed
        if (prevCompleted) {
          if (!validUnlockedLessons.contains(lessonId)) {
            validUnlockedLessons.add(lessonId);
          }
        } else {
          // Previous lesson not completed - stop here (don't unlock any more)
          break;
        }
      }
    }
    
    // Update unlocked lessons list if it changed
    if (validUnlockedLessons.length != _unlockedLessons.length || 
        !validUnlockedLessons.every((id) => _unlockedLessons.contains(id))) {
      print('🔧 Fixing unlocked lessons: had ${_unlockedLessons.length}, should have ${validUnlockedLessons.length}');
      _unlockedLessons = validUnlockedLessons;
      
      // Update unlock dates for valid lessons only - PRESERVE existing dates
      final validUnlockDates = <String, DateTime>{};
      for (final lessonId in validUnlockedLessons) {
        if (_lessonUnlockDates.containsKey(lessonId)) {
          // PRESERVE the original unlock date - don't reset it!
          validUnlockDates[lessonId] = _lessonUnlockDates[lessonId]!;
          print('📅 Preserved unlock date for $lessonId: ${_lessonUnlockDates[lessonId]}');
        } else {
          // Set unlock date to 7 days ago if missing (so it's immediately accessible)
          // This prevents blocking access to lessons that should be available
          final pastDate = DateTime.now().subtract(const Duration(days: 7));
          validUnlockDates[lessonId] = pastDate;
          print('🔧 Set missing unlock date for $lessonId to 7 days ago (now accessible)');
        }
      }
      _lessonUnlockDates = validUnlockDates;
      
      await _saveUnlockedLessons();
      notifyListeners();
    }
  }

  Future<void> _loadUnlockedLessons() async {
    try {
      final data = await DatabaseService.loadDailyLessons();
      if (data != null) {
        // Handle both old int IDs and new string IDs
        final rawUnlocked = data['unlockedLessons'] ?? [];
        if (rawUnlocked.isNotEmpty && rawUnlocked.first is int) {
          // Migrate from old int IDs to new string IDs
          _unlockedLessons = _migrateIntIdsToStringIds(rawUnlocked);
        } else {
          _unlockedLessons = List<String>.from(rawUnlocked);
        }
        _lastUnlockDate = data['lastUnlockDate'] != null
            ? DateTime.parse(data['lastUnlockDate'])
            : null;
        _lessonsUnlockedToday = data['lessonsUnlockedToday'] ?? 0;
        
        // Load individual lesson unlock dates
        final unlockDates = data['lessonUnlockDates'] as Map<String, dynamic>? ?? {};
        _lessonUnlockDates = unlockDates.map((key, value) => 
          MapEntry(key, DateTime.parse(value as String))
        );
        
        // If we have unlocked lessons but no unlock dates, set them to now (migration)
        final now = DateTime.now();
        for (final lessonId in _unlockedLessons) {
          if (!_lessonUnlockDates.containsKey(lessonId)) {
            _lessonUnlockDates[lessonId] = now;
          }
        }
      } else {
        // First time - unlock first lesson ('what_is_stock')
        final now = DateTime.now();
        _unlockedLessons = ['what_is_stock'];
        _lessonUnlockDates = {'what_is_stock': now};
        _lastUnlockDate = now;
        _lessonsUnlockedToday = 0;
        await _saveUnlockedLessons();
      }
    } catch (e) {
      print('Error loading daily lessons: $e');
      // Default: unlock first lesson
      final now = DateTime.now();
      _unlockedLessons = ['what_is_stock'];
      _lessonUnlockDates = {'what_is_stock': now};
      _lastUnlockDate = now;
      _lessonsUnlockedToday = 0;
    }
    notifyListeners();
  }

  // Migrate old int IDs to new string IDs
  List<String> _migrateIntIdsToStringIds(List<dynamic> intIds) {
    final allLessons = InteractiveLessons.getHardcodedLessons();
    final idMap = {
      1: 'what_is_stock',
      2: 'how_stock_prices_work',
      3: 'rsi_basics',
      // Add more mappings as needed
    };
    
    return intIds.map((id) {
      if (idMap.containsKey(id)) {
        return idMap[id]!;
      }
      // Fallback: try to find by index
      final index = id - 1;
      if (index >= 0 && index < allLessons.length) {
        return allLessons[index]['id'] as String;
      }
      return 'what_is_stock'; // Default
    }).toList();
  }

  Future<void> _checkDailyUnlock() async {
    final today = DateTime.now();
    final todayKey = today.toIso8601String().split('T')[0];
    
    // Check if we need to unlock a new lesson today
    if (_lastUnlockDate == null) {
      _lastUnlockDate = today;
      // Only unlock first lesson if no lessons are unlocked yet
      if (_unlockedLessons.isEmpty) {
        await _unlockNextLesson();
      }
      return;
    }

    final lastUnlockKey = _lastUnlockDate!.toIso8601String().split('T')[0];
    
    // If it's a new day, reset counter
    // BUT DON'T auto-unlock - only unlock when a lesson is completed
    if (todayKey != lastUnlockKey) {
      _lessonsUnlockedToday = 0;
      _lastUnlockDate = today;
      // DO NOT auto-unlock here - lessons unlock only when previous lesson is completed
    }
  }

  Future<void> _unlockNextLesson() async {
    if (!canUnlockMoreToday) return;

    final nextLessonId = await _getNextLessonToUnlock();
    
    if (nextLessonId != null && !_unlockedLessons.contains(nextLessonId)) {
      final now = DateTime.now();
      _unlockedLessons.add(nextLessonId);
      _lessonUnlockDates[nextLessonId] = now;
      _lessonsUnlockedToday++;
      await _saveUnlockedLessons();
      notifyListeners();
      print('🎉 Unlocked new lesson: $nextLessonId');
    }
  }

  Future<String?> _getNextLessonToUnlock() async {
    // Use pathway order - find the first lesson that is NOT unlocked yet
    // This ensures sequential unlocking based on day order (1-30)
    final completed = await DatabaseService.getCompletedActions();
    
    // Go through lessons in pathway order (day 1-30)
    for (int day = 1; day <= 30; day++) {
      final lessonId = LearningPathway.getLessonIdForDay(day);
      if (lessonId == null) continue;
      
      // Check if this lesson is already unlocked
      if (_unlockedLessons.contains(lessonId)) {
        continue; // Already unlocked, check next
      }
      
      // Check if previous lesson is completed (for sequential unlock)
      if (day > 1) {
        final prevLessonId = LearningPathway.getLessonIdForDay(day - 1);
        if (prevLessonId != null) {
          final prevCompleted = completed.contains('lesson_$prevLessonId') || 
                              completed.contains('lesson_${prevLessonId}_completed');
          if (!prevCompleted) {
            // Previous lesson not completed, can't unlock this one yet
            continue;
          }
        }
      }
      
      // This is the next lesson to unlock (first unlocked lesson in sequence)
      return lessonId;
    }
    
    return null; // All lessons unlocked
  }

  bool isLessonUnlocked(String lessonId) {
    return _unlockedLessons.contains(lessonId);
  }

  Future<String?> getNextUnlockedLessonAsync() async {
    final completed = await DatabaseService.getCompletedActions();
    
    // Get lessons in pathway order (day 1-30)
    // This ensures we return the next lesson in sequence, not just any unlocked lesson
    for (int day = 1; day <= 30; day++) {
      final lessonId = LearningPathway.getLessonIdForDay(day);
      if (lessonId == null) continue;
      
      // Check if this lesson is unlocked
      if (!_unlockedLessons.contains(lessonId)) {
        // If we hit a locked lesson, we've gone past all unlocked lessons
        // But we should still show the NEXT lesson that should be unlocked
        // This is the lesson the user should work towards
        return lessonId; // Return the next lesson to unlock (even if locked)
      }
      
      // Check if this lesson is completed
      final isCompleted = completed.contains('lesson_$lessonId') || 
                          completed.contains('lesson_${lessonId}_completed');
      
      // Return the first unlocked lesson that is NOT completed (in pathway order)
      if (!isCompleted) {
        return lessonId;
      }
    }
    
    // If all lessons are completed, return null
    return null;
  }

  Future<void> _saveUnlockedLessons() async {
    await DatabaseService.saveDailyLessons({
      'unlockedLessons': _unlockedLessons,
      'lastUnlockDate': _lastUnlockDate?.toIso8601String(),
      'lessonsUnlockedToday': _lessonsUnlockedToday,
      'lessonUnlockDates': _lessonUnlockDates.map((key, value) => 
        MapEntry(key, value.toIso8601String())
      ),
    });
  }

  // Manually unlock next lesson (for testing or special cases)
  Future<void> unlockNextLesson() async {
    await _unlockNextLesson();
  }
  
  // Public method to unlock a specific lesson (used when previous lesson completes)
  // This is called when a lesson is completed - unlocks the NEXT lesson
  Future<void> unlockLesson(String lessonId) async {
    if (!_unlockedLessons.contains(lessonId)) {
      final now = DateTime.now();
      _unlockedLessons.add(lessonId);
      _lessonUnlockDates[lessonId] = now;
      _lessonsUnlockedToday++;
      _lastUnlockDate = now;
      await _saveUnlockedLessons();
      notifyListeners();
      print('🎉 Unlocked lesson: $lessonId (unlocked today, available tomorrow)');
    }
  }
  
  // Method to unlock next lesson when current lesson is completed
  Future<void> unlockNextLessonAfterCompletion(String completedLessonId) async {
    // Get the day number for the completed lesson
    final dayNum = LearningPathway.getDayForLessonId(completedLessonId);
    if (dayNum == null) {
      print('⚠️ Could not find day number for lesson: $completedLessonId');
      return;
    }
    
    // Get the next lesson ID (day + 1)
    final nextDayNum = dayNum + 1;
    if (nextDayNum > 30) {
      print('✅ All lessons completed!');
      return;
    }
    
    final nextLessonId = LearningPathway.getLessonIdForDay(nextDayNum);
    if (nextLessonId == null) {
      print('⚠️ Could not find lesson for day: $nextDayNum');
      return;
    }
    
    // Unlock the next lesson
    await unlockLesson(nextLessonId);
  }
  
  // Check if a lesson was unlocked today
  bool wasLessonUnlockedToday(String lessonId) {
    final unlockDate = _lessonUnlockDates[lessonId];
    if (unlockDate == null) return false;
    
    final today = DateTime.now();
    final unlockDay = DateTime(unlockDate.year, unlockDate.month, unlockDate.day);
    final todayDay = DateTime(today.year, today.month, today.day);
    
    // Check if unlock date is today (0 days difference)
    final daysDifference = todayDay.difference(unlockDay).inDays;
    return daysDifference == 0;
  }
  
  // Check if a lesson can be accessed today (Duolingo-style: unlocked but not today)
  // Returns true if lesson is unlocked AND was unlocked before today
  // Returns false if lesson is not unlocked OR was unlocked today
  // EXCEPTION: First lesson (day 1) is always accessible immediately
  bool canAccessLessonToday(String lessonId) {
    // If lesson is not unlocked, can't access
    if (!_unlockedLessons.contains(lessonId)) {
      print('🔒 Lesson $lessonId is not unlocked');
      return false;
    }
    
    // CRITICAL FIX: First lesson (day 1) is always accessible immediately
    final dayNum = LearningPathway.getDayForLessonId(lessonId);
    if (dayNum == 1) {
      print('✅ First lesson (day 1) is always accessible');
      return true; // First lesson is always accessible
    }
    
    // Get unlock date
    final unlockDate = _lessonUnlockDates[lessonId];
    if (unlockDate == null) {
      // No unlock date - this shouldn't happen, but allow access to be safe
      print('⚠️ Lesson $lessonId is unlocked but has no unlock date - allowing access');
      return true;
    }
    
    // Check if lesson was unlocked today
    final today = DateTime.now();
    final unlockDay = DateTime(unlockDate.year, unlockDate.month, unlockDate.day);
    final todayDay = DateTime(today.year, today.month, today.day);
    
    // Calculate days difference
    final daysDifference = todayDay.difference(unlockDay).inDays;
    
    print('📅 Lesson $lessonId: Unlocked ${daysDifference} days ago (unlock: $unlockDay, today: $todayDay)');
    
    // If lesson was unlocked today (0 days ago), can't access until tomorrow
    if (daysDifference == 0) {
      print('🚫 Lesson $lessonId was unlocked today - must wait until tomorrow');
      return false;
    }
    
    // If lesson was unlocked yesterday or earlier, can access today
    if (daysDifference >= 1) {
      print('✅ Lesson $lessonId was unlocked $daysDifference days ago - accessible today');
      return true;
    }
    
    // Future unlock date (shouldn't happen, but block it)
    print('⚠️ Lesson $lessonId has future unlock date - blocking access');
    return false;
  }
  
  // Get unlock date for a lesson
  DateTime? getLessonUnlockDate(String lessonId) {
    return _lessonUnlockDates[lessonId];
  }
  
  // Get the last day a lesson was completed (for tracking daily progress)
  Future<DateTime?> getLastCompletionDate(String lessonId) async {
    return await DatabaseService.getActionCompletionDate('lesson_$lessonId');
  }
  
  // Check if lesson was completed today
  Future<bool> wasLessonCompletedToday(String lessonId) async {
    return await DatabaseService.isActionCompletedToday('lesson_$lessonId');
  }
}

