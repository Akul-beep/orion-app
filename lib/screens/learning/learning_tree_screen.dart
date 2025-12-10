import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../services/daily_lesson_service.dart';
import '../../services/database_service.dart';
import '../../services/user_progress_service.dart';
import '../../data/learning_pathway.dart';
import '../../data/interactive_lessons.dart';
import '../../data/trading_lessons_data.dart';
import 'interactive_lesson_screen.dart';
import 'duolingo_teaching_screen.dart';

class LearningTreeScreen extends StatefulWidget {
  const LearningTreeScreen({Key? key}) : super(key: key);

  @override
  State<LearningTreeScreen> createState() => _LearningTreeScreenState();
}

class _LearningTreeScreenState extends State<LearningTreeScreen> {
  // Make _buildDayNode accessible to child widgets
  Widget buildDayNodePublic(
    Map<String, dynamic> day,
    List<String> completedActions,
    DailyLessonService dailyLessons,
  ) {
    return _buildDayNode(day, completedActions, dailyLessons);
  }
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      UserProgressService().trackScreenVisit(
        screenName: 'LearningTreeScreen',
        screenType: 'main',
        metadata: {'section': 'learning'},
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF111827), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Learning Tree',
          style: GoogleFonts.inter(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF111827),
            letterSpacing: -0.3,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: const Color(0xFFE5E7EB),
          ),
        ),
      ),
      body: Consumer<DailyLessonService>(
        builder: (context, dailyLessons, child) {
          return FutureBuilder<List<String>>(
            future: DatabaseService.getCompletedActions(),
            builder: (context, snapshot) {
              final completedActions = snapshot.data ?? [];
              
              // Get all days from the 50-day pathway (30 real + 20 placeholder)
              return FutureBuilder<List<Map<String, dynamic>>>(
                future: LearningPathway.getAllLessonsWithPlaceholders(),
                builder: (context, allDaysSnapshot) {
                  if (!allDaysSnapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final allDays = allDaysSnapshot.data!;
              final allLessons = TradingLessonsData.getAllLessons();
              
              // Count completed lessons properly
              int completedCount = 0;
              for (var day in allDays) {
                final dayType = day['type'] as String? ?? 'lesson';
                if (dayType == 'lesson') {
                  final dayNum = day['day'] as int?;
                  // Handle both int and String IDs
                  final rawId = day['id'];
                  final lessonId = rawId is String ? rawId : (rawId is int ? rawId.toString() : null);
                  if (dayNum != null) {
                    // Check by day number or lesson ID
                    if (completedActions.contains('lesson_$dayNum') || 
                        completedActions.contains('lesson_${dayNum}_completed') ||
                        completedActions.contains('day_$dayNum') ||
                        (lessonId != null && (
                          completedActions.contains('lesson_$lessonId') ||
                          completedActions.contains('lesson_${lessonId}_completed')
                        ))) {
                      completedCount++;
                    }
                  }
                }
              }
              
              // Also count the 6 main lessons (for backwards compatibility)
              for (var lesson in allLessons) {
                // Handle both int and String IDs
                final rawId = lesson['id'];
                final lessonId = rawId is String ? rawId : (rawId is int ? rawId.toString() : '');
                if (lessonId.isNotEmpty && (
                    completedActions.contains('lesson_$lessonId') || 
                    completedActions.contains('lesson_${lessonId}_completed'))) {
                  completedCount++;
                }
              }
              
              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFFE5E7EB),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0052FF).withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.account_tree_outlined,
                                  color: Color(0xFF0052FF),
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Your Learning Journey',
                                      style: GoogleFonts.inter(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                        color: const Color(0xFF111827),
                                        letterSpacing: -0.3,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '50 lessons planned • $completedCount completed',
                                      style: GoogleFonts.inter(
                                        fontSize: 13,
                                        color: const Color(0xFF6B7280),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Quick Access: Past Completed Lessons
                    if (completedCount > 0) _buildPastLessonsQuickAccess(allDays, completedActions, dailyLessons),
                    
                    if (completedCount > 0) const SizedBox(height: 24),
                    
                    // Show all weeks (30 days + Supabase lessons)
                    FutureBuilder<List<Map<String, dynamic>>>(
                      future: LearningPathway.get30DayPathwayByWeek(),
                      builder: (context, weeksSnapshot) {
                        if (!weeksSnapshot.hasData) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        final weeks = weeksSnapshot.data!;
                        return Column(
                          children: [
                            ...weeks.map((week) => _buildWeekSection(
                      week,
                      allDays,
                      completedActions,
                      dailyLessons,
                    )),
                    
                            const SizedBox(height: 32),
                            
                            // More Lessons Coming Soon Section
                            _buildComingSoonSection(allDays, completedActions),
                            
                            const SizedBox(height: 24),
                            
                            // Challenges Section
                            _buildChallengesSection(),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              );
            },
          );
          },
        );
        },
      ),
    );
  }
  
  Widget _buildComingSoonSection(List<Map<String, dynamic>> allDays, List<String> completedActions) {
    // Get placeholder lessons (days 31-50)
    final placeholderLessons = allDays.where((day) => day['isPlaceholder'] == true).toList();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFF59E0B).withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.hourglass_empty_outlined, color: Color(0xFFF59E0B), size: 20),
            ),
            const SizedBox(width: 10),
            Text(
              'Continue Your Learning Journey',
              style: GoogleFonts.inter(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.3,
                color: const Color(0xFF111827),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ...placeholderLessons.map((day) {
          // Create a dummy DailyLessonService for placeholders
          final dummyService = DailyLessonService();
          return _buildDayNode(
            day,
            completedActions,
            dummyService, // Placeholder lessons are always locked
          );
        }).toList(),
      ],
    );
  }
  
  Widget _buildPastLessonsQuickAccess(
    List<Map<String, dynamic>> allDays,
    List<String> completedActions,
    DailyLessonService dailyLessons,
  ) {
    return _PastLessonsDropdown(
      allDays: allDays,
      completedActions: completedActions,
      dailyLessons: dailyLessons,
    );
  }
  
  Widget _buildChallengesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.emoji_events, color: Colors.amber[700], size: 24),
            const SizedBox(width: 8),
            Text(
              'Challenges',
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF111827),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.amber.withOpacity(0.3)),
          ),
          child: Column(
            children: [
              Icon(Icons.rocket_launch, size: 48, color: Colors.amber[700]),
              const SizedBox(height: 12),
              Text(
                'Weekly Challenges Available',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Complete weekly challenges to earn bonus XP and compete on leaderboards.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildWeekSection(
    Map<String, dynamic> week,
    List<Map<String, dynamic>> allDays,
    List<String> completedActions,
    DailyLessonService dailyLessons,
  ) {
    final weekNum = week['week'] as int? ?? 1;
    final weekTitle = week['title'] as String? ?? 'Week';
    final weekDays = week['days'] as List? ?? [];
    
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Week Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: _getWeekColor(weekNum).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _getWeekColor(weekNum).withOpacity(0.3),
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _getWeekColor(weekNum),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Center(
                    child: Text(
                      'W$weekNum',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        weekTitle,
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF111827),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${weekDays.length} days',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: const Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          
          // Days in this week
          ...weekDays.map((day) => _buildDayNode(
            day,
            completedActions,
            dailyLessons,
          )),
        ],
      ),
    );
  }

  Widget _buildDayNode(
    Map<String, dynamic> day,
    List<String> completedActions,
    DailyLessonService dailyLessons,
  ) {
    // Fix null error - handle case where 'day' key might not exist or be null
    final dayNum = day['day'] as int? ?? 0;
    // Handle type safely - could be String or int
    final dayTypeRaw = day['type'];
    final dayType = dayTypeRaw is String ? dayTypeRaw : (dayTypeRaw is int ? dayTypeRaw.toString() : 'lesson');
    
    final titleRaw = day['title'];
    final title = titleRaw is String ? titleRaw : (titleRaw is int ? titleRaw.toString() : 'Unknown Lesson');
    
    final durationRaw = day['duration'];
    final duration = durationRaw is String ? durationRaw : (durationRaw is int ? '$durationRaw min' : '5 min');
    
    final xp = day['xp'] as int? ?? 100;
    
    // Get lesson ID for consistent checking (same as pathway uses)
    // Handle both int and String IDs
    final rawId = day['lesson_id'] ?? day['id'];
    final lessonIdStr = rawId is String ? rawId : (rawId is int ? rawId.toString() : '');
    
    // Check if completed FIRST - completed lessons are always unlocked and accessible
    final isCompleted = completedActions.contains('lesson_$dayNum') || 
                        completedActions.contains('lesson_${dayNum}_completed') ||
                        completedActions.contains('day_$dayNum') ||
                        (lessonIdStr.isNotEmpty && (
                          completedActions.contains('lesson_$lessonIdStr') ||
                          completedActions.contains('lesson_${lessonIdStr}_completed')
                        ));
    
    // If completed, it's always unlocked and accessible
    bool isUnlocked = isCompleted;
    if (!isCompleted) {
      // Check if unlocked - ONLY use DailyLessonService (no fallback logic)
      // This ensures consistency across all screens
      if (lessonIdStr.isNotEmpty && !lessonIdStr.startsWith('placeholder_')) {
        // Use DailyLessonService unlock logic - explicitly check if in unlocked list
        isUnlocked = dailyLessons.isLessonUnlocked(lessonIdStr);
      } else if (dayNum == 1 && lessonIdStr.isNotEmpty) {
        // Day 1 is always unlocked (fallback for day 1 only)
        isUnlocked = true;
      } else {
        // All other lessons must be in unlocked list - no fallback
        isUnlocked = false;
      }
    }
    
    // Get color based on type
    final color = _getDayTypeColor(dayType);
    
    // Get lesson ID for access checking
    // Handle both int and String IDs
    final rawId2 = day['lesson_id'] ?? day['id'];
    final lessonId = rawId2 is String ? rawId2 : (rawId2 is int ? rawId2.toString() : '');
    
    // Check if lesson can be accessed (completed lessons always accessible, newly unlocked not accessible today)
    Future<bool> canAccessLesson() async {
      // Check if lesson is completed (using lessonIdStr from above)
      final lessonCompleted = completedActions.contains('lesson_$dayNum') || 
                              completedActions.contains('lesson_${dayNum}_completed') ||
                              completedActions.contains('day_$dayNum') ||
                              (lessonIdStr.isNotEmpty && (
                                completedActions.contains('lesson_$lessonIdStr') ||
                                completedActions.contains('lesson_${lessonIdStr}_completed')
                              )) ||
                              (lessonId.isNotEmpty && (
                                completedActions.contains('lesson_$lessonId') ||
                                completedActions.contains('lesson_${lessonId}_completed')
                              ));
      
      // Completed lessons are always accessible (for review)
      if (lessonCompleted) return true;
      
      // If not completed, check if it was just unlocked today
      // Use the lesson ID that's actually being used for unlocking
      final effectiveLessonId = lessonIdStr.isNotEmpty ? lessonIdStr : lessonId;
      if (effectiveLessonId.isNotEmpty && !effectiveLessonId.startsWith('placeholder_')) {
        // CRITICAL: Check if this lesson was unlocked today using DailyLessonService
        // This is the key check - if unlocked today, must wait until tomorrow
        final wasUnlockedToday = dailyLessons.wasLessonUnlockedToday(effectiveLessonId);
        if (wasUnlockedToday) {
          print('🚫 Lesson $effectiveLessonId was unlocked today - blocking access until tomorrow');
          return false; // Just unlocked today - can't access until tomorrow
        }
        
        // Also check using canAccessLessonToday for double verification
        final canAccessToday = dailyLessons.canAccessLessonToday(effectiveLessonId);
        if (!canAccessToday) {
          print('🚫 Lesson $effectiveLessonId cannot be accessed today - blocking access');
          return false;
        }
      }
      
      return true; // Can access (either unlocked before today or day 1)
    }
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: FutureBuilder<bool>(
        future: canAccessLesson(),
        builder: (context, snapshot) {
          // CRITICAL: Default to false if loading to prevent premature access
          // Only allow access if explicitly confirmed by the check
          final canAccess = snapshot.data ?? false; // Default to false if loading (safer)
          
          return GestureDetector(
            onTap: isUnlocked && dayType == 'lesson' && canAccess ? () async {
              // CRITICAL: Double check if this lesson was just unlocked today
              // This is a safety check to prevent access even if the FutureBuilder allowed it
              final effectiveLessonId = lessonIdStr.isNotEmpty ? lessonIdStr : lessonId;
              if (!isCompleted && effectiveLessonId.isNotEmpty && !effectiveLessonId.startsWith('placeholder_')) {
                // Check both methods for maximum safety
                final wasUnlockedToday = dailyLessons.wasLessonUnlockedToday(effectiveLessonId);
                final canAccessToday = dailyLessons.canAccessLessonToday(effectiveLessonId);
                
                if (wasUnlockedToday || !canAccessToday) {
                  print('🚫 Blocking access to lesson $effectiveLessonId - wasUnlockedToday: $wasUnlockedToday, canAccessToday: $canAccessToday');
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0052FF).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.lock_open, color: Color(0xFF0052FF), size: 18),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Next lesson unlocked! 🎉 Come back tomorrow to start it - great job completing the previous lesson!',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFF111827),
                              ),
                            ),
                          ),
                        ],
                      ),
                      backgroundColor: Colors.white,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: const BorderSide(color: Color(0xFF0052FF), width: 1.5),
                      ),
                      margin: const EdgeInsets.all(16),
                      duration: const Duration(seconds: 3),
                    ),
                  );
                  return; // BLOCK access - must wait until tomorrow
                }
              }
              
              // Allow accessing completed lessons for review (all past completed lessons are accessible)
              if (isCompleted) {
                // Check if it was completed today - allow access for review
                final completedToday = await DatabaseService.isActionCompletedToday('lesson_$lessonId') ||
                                       await DatabaseService.isActionCompletedToday('lesson_$dayNum') ||
                                       (effectiveLessonId.isNotEmpty && await DatabaseService.isActionCompletedToday('lesson_$effectiveLessonId'));
                
                if (completedToday) {
                  // Show message but allow review (just no XP)
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          const Icon(Icons.book_outlined, color: Color(0xFF0052FF), size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Reviewing lesson! No XP today, but great for practice',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFF111827),
                              ),
                            ),
                          ),
                        ],
                      ),
                      backgroundColor: Colors.white,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: const BorderSide(color: Color(0xFFE5E7EB), width: 1),
                      ),
                      margin: const EdgeInsets.all(16),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                }
                // Continue to navigation below - allow review access!
              }
              
              // Navigate to lesson
              if (lessonId.isNotEmpty && !lessonId.startsWith('placeholder_')) {
                // Use InteractiveLessons for new lessons
                final allInteractiveLessons = await InteractiveLessons.getAllLessons();
                final matchingLesson = allInteractiveLessons.firstWhere(
                  (l) => l['id'] == lessonId,
                  orElse: () => {},
                );
                
                if (matchingLesson.isNotEmpty) {
                  await UserProgressService().trackNavigation(
                    fromScreen: 'LearningTreeScreen',
                    toScreen: 'DuolingoTeachingScreen',
                    navigationMethod: 'push',
                    navigationData: {'lesson_id': lessonId, 'day': dayNum},
                  );
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => DuolingoTeachingScreen(lessonId: lessonId),
                    ),
                  );
                  return;
                }
              }
              
              // Fallback to old TradingLessonsData system
              final allLessons = TradingLessonsData.getAllLessons();
              Map<String, dynamic>? matchingLesson;
              
              // Try to match by title
              for (var lesson in allLessons) {
                if (lesson['title'] == title) {
                  matchingLesson = lesson;
                  break;
                }
              }
              
              if (matchingLesson != null) {
                await UserProgressService().trackNavigation(
                  fromScreen: 'LearningTreeScreen',
                  toScreen: 'DuolingoTeachingScreen',
                  navigationMethod: 'push',
                  navigationData: {'lesson_id': matchingLesson['id'], 'day': dayNum},
                );
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DuolingoTeachingScreen(lessonId: matchingLesson!['id']),
                  ),
                );
              } else {
                // For placeholder lessons or if not found
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        const Icon(Icons.info_outline, color: Color(0xFFF59E0B), size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'This lesson will be available soon! Complete previous lessons to unlock',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF111827),
                            ),
                          ),
                        ),
                      ],
                    ),
                    backgroundColor: Colors.white,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: const BorderSide(color: Color(0xFFF59E0B), width: 1.5),
                    ),
                    margin: const EdgeInsets.all(16),
                    duration: const Duration(seconds: 2),
                  ),
                );
              }
            } : !canAccess && isUnlocked ? () {
              // If just unlocked today, show message
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0052FF).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.lock_open, color: Color(0xFF0052FF), size: 18),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Next lesson unlocked! 🎉 Come back tomorrow to start it - great job completing the previous lesson!',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF111827),
                          ),
                        ),
                      ),
                    ],
                  ),
                  backgroundColor: Colors.white,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(color: Color(0xFF0052FF), width: 1.5),
                  ),
                  margin: const EdgeInsets.all(16),
                  duration: const Duration(seconds: 3),
                ),
              );
            } : isUnlocked ? () {
              // If unlocked but not a lesson (e.g., challenge)
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      const Icon(Icons.schedule_outlined, color: Color(0xFF6B7280), size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'You can attempt this tomorrow',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF111827),
                          ),
                        ),
                      ),
                    ],
                  ),
                  backgroundColor: Colors.white,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(color: Color(0xFFE5E7EB), width: 1),
                  ),
                  margin: const EdgeInsets.all(16),
                  duration: const Duration(seconds: 2),
                ),
              );
            } : null,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isCompleted 
                    ? const Color(0xFF10B981).withOpacity(0.05) // Light green background for completed
                    : isUnlocked
                        ? const Color(0xFF3B82F6).withOpacity(0.03) // Light blue background for unlocked
                        : Colors.white, // White for locked
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isCompleted
                      ? const Color(0xFF10B981) // Green border for completed
                      : isUnlocked 
                          ? const Color(0xFF0052FF) // Blue border for unlocked
                          : const Color(0xFFE5E7EB), // Grey for locked
                  width: isCompleted ? 2 : isUnlocked ? 1.5 : 1, // Subtle borders
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isCompleted ? 0.04 : isUnlocked ? 0.02 : 0.01),
                    blurRadius: 8,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Row(
                children: [
              // Day Number & Status
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: isCompleted
                      ? const Color(0xFF10B981) // Green for completed
                      : isUnlocked
                          ? const Color(0xFF0052FF) // Blue for unlocked
                          : const Color(0xFFE5E7EB), // Grey for locked
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: isCompleted
                      ? [
                          BoxShadow(
                            color: const Color(0xFF10B981).withOpacity(0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : isUnlocked
                          ? [
                              BoxShadow(
                                color: const Color(0xFF0052FF).withOpacity(0.15),
                                blurRadius: 6,
                                offset: const Offset(0, 1),
                              ),
                            ]
                          : null,
                ),
              child: Center(
                child: isCompleted
                    ? const Icon(Icons.check_circle, color: Colors.white, size: 22)
                    : !isUnlocked
                        ? const Icon(Icons.lock_outlined, color: Color(0xFF9CA3AF), size: 18)
                        : Text(
                            '$dayNum',
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
              ),
              ),
              const SizedBox(width: 16),
              // Day Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              fontWeight: isCompleted ? FontWeight.w600 : FontWeight.w600,
                              color: !isUnlocked 
                                  ? const Color(0xFF9CA3AF) // Gray for locked
                                  : const Color(0xFF111827), // Always black for unlocked/completed
                            ),
                          ),
                        ),
                        if (isCompleted)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981).withOpacity(0.08),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Done ✓',
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF10B981),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Icon(
                                  Icons.touch_app,
                                  size: 10,
                                  color: const Color(0xFF10B981),
                                ),
                              ],
                            ),
                          )
                        else if (isUnlocked)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF3B82F6).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Unlocked',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF3B82F6),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            _getDayTypeLabel(dayType),
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: color,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          duration,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: const Color(0xFF9CA3AF),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.diamond, color: color, size: 12),
                            const SizedBox(width: 3),
                            Text(
                              '$xp XP',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: color,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
          );
        },
      ),
    );
  }

  Color _getWeekColor(int weekNum) {
    final colors = [
      const Color(0xFF0052FF), // Week 1 - Blue
      const Color(0xFF1CB0F6), // Week 2 - Blue
      const Color(0xFFFF6B35), // Week 3 - Orange
      const Color(0xFF9B59B6), // Week 4 - Purple
      const Color(0xFFE74C3C), // Week 5 - Red
      const Color(0xFF2ECC71), // Week 6 - Light Green
      const Color(0xFFF39C12), // Week 7 - Yellow
    ];
    return colors[(weekNum - 1) % colors.length];
  }

  Color _getDayTypeColor(String type) {
    switch (type) {
      case 'lesson':
        return const Color(0xFF1E3A8A);
      case 'challenge':
        return const Color(0xFFFF6B35);
      case 'review':
        return const Color(0xFF9B59B6);
      case 'graduation':
        return const Color(0xFF0052FF);
      default:
        return const Color(0xFF6B7280);
    }
  }

  String _getDayTypeLabel(String type) {
    switch (type) {
      case 'lesson':
        return 'Lesson';
      case 'challenge':
        return 'Challenge';
      case 'review':
        return 'Review';
      case 'graduation':
        return 'Graduation';
      default:
        return 'Activity';
    }
  }

}

class _PastLessonsDropdown extends StatefulWidget {
  final List<Map<String, dynamic>> allDays;
  final List<String> completedActions;
  final DailyLessonService dailyLessons;

  const _PastLessonsDropdown({
    required this.allDays,
    required this.completedActions,
    required this.dailyLessons,
  });

  @override
  State<_PastLessonsDropdown> createState() => _PastLessonsDropdownState();
}

class _PastLessonsDropdownState extends State<_PastLessonsDropdown> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    // Get ALL completed lessons (sorted by day number)
    final completedLessons = widget.allDays.where((day) {
      final dayType = day['type'] as String? ?? 'lesson';
      if (dayType != 'lesson') return false;
      
      final dayNum = day['day'] as int?;
      // Handle both int and String IDs
      final rawId = day['lesson_id'] ?? day['id'];
      final lessonId = rawId is String ? rawId : (rawId is int ? rawId.toString() : '');
      
      if (dayNum != null) {
        return widget.completedActions.contains('lesson_$dayNum') || 
               widget.completedActions.contains('lesson_${dayNum}_completed') ||
               widget.completedActions.contains('day_$dayNum') ||
               (lessonId.isNotEmpty && (
                 widget.completedActions.contains('lesson_$lessonId') ||
                 widget.completedActions.contains('lesson_${lessonId}_completed')
               ));
      }
      return false;
    }).toList();
    
    // Sort by day number
    completedLessons.sort((a, b) {
      final dayA = a['day'] as int? ?? 0;
      final dayB = b['day'] as int? ?? 0;
      return dayB.compareTo(dayA); // Most recent first
    });
    
    if (completedLessons.isEmpty) return const SizedBox.shrink();
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header - clickable to expand/collapse
          InkWell(
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
            ),
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withOpacity(0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.history_outlined,
                      color: Color(0xFF10B981),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Review Past Lessons',
                      style: GoogleFonts.inter(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.3,
                        color: const Color(0xFF111827),
                      ),
                    ),
                  ),
                  Text(
                    '${completedLessons.length}',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF10B981),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    _isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: const Color(0xFF6B7280),
                    size: 24,
                  ),
                ],
              ),
            ),
          ),
          // Collapsible content
          if (_isExpanded) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: completedLessons.map((lesson) {
                  final dayNum = lesson['day'] as int? ?? 0;
                  // Handle type safely
                  final titleRaw = lesson['title'];
                  final title = titleRaw is String ? titleRaw : (titleRaw is int ? titleRaw.toString() : 'Unknown Lesson');
                  // Handle both int and String IDs
                  final rawId = lesson['lesson_id'] ?? lesson['id'];
                  final lessonId = rawId is String ? rawId : (rawId is int ? rawId.toString() : '');
                  final durationRaw = lesson['duration'];
                  final duration = durationRaw is String ? durationRaw : (durationRaw is int ? '$durationRaw min' : '5 min');
                  final xp = lesson['xp'] as int? ?? 100;
                  
                  // Create a day map with completed status
                  final completedDay = {
                    'day': dayNum,
                    'type': 'lesson',
                    'title': title,
                    'lesson_id': lessonId,
                    'id': lessonId,
                    'duration': duration,
                    'xp': xp,
                  };
                  
                  // Build completed lesson card - access parent's method via context
                  return Builder(
                    builder: (context) {
                      // Get the parent LearningTreeScreen state
                      final parentState = context.findAncestorStateOfType<_LearningTreeScreenState>();
                      if (parentState != null) {
                        return parentState.buildDayNodePublic(
                          completedDay,
                          widget.completedActions,
                          widget.dailyLessons,
                        );
                      }
                      // Fallback if state not found
                      return const SizedBox.shrink();
                    },
                  );
                }).toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
