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
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF111827)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Learning Tree',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF111827),
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
              final allDays = LearningPathway.getAllLessonsWithPlaceholders();
              final allLessons = TradingLessonsData.getAllLessons();
              
              // Count completed lessons properly
              int completedCount = 0;
              for (var day in allDays) {
                final dayType = day['type'] as String? ?? 'lesson';
                if (dayType == 'lesson') {
                  final dayNum = day['day'] as int?;
                  final lessonId = day['id'] as String?;
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
                final lessonId = lesson['id'] as int;
                if (completedActions.contains('lesson_$lessonId') || 
                    completedActions.contains('lesson_${lessonId}_completed')) {
                  completedCount++;
                }
              }
              
              return SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFF1E3A8A),
                            const Color(0xFF3B82F6),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF1E3A8A).withOpacity(0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
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
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.account_tree,
                                  color: Colors.white,
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
                                      style: GoogleFonts.poppins(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '50 lessons planned • $completedCount completed',
                                      style: GoogleFonts.poppins(
                                        fontSize: 13,
                                        color: Colors.white.withOpacity(0.9),
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
                    
                    // Show all weeks (30 days)
                    ...LearningPathway.get30DayPathwayByWeek().map((week) => _buildWeekSection(
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
                ),
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
            Icon(Icons.hourglass_empty, color: Colors.orange[700], size: 24),
            const SizedBox(width: 8),
            Text(
              'More Lessons Coming Soon',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w700,
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
    // Get ALL completed lessons (sorted by day number)
    final completedLessons = allDays.where((day) {
      final dayType = day['type'] as String? ?? 'lesson';
      if (dayType != 'lesson') return false;
      
      final dayNum = day['day'] as int?;
      final lessonId = day['lesson_id'] as String? ?? day['id'] as String? ?? '';
      
      if (dayNum != null) {
        return completedActions.contains('lesson_$dayNum') || 
               completedActions.contains('lesson_${dayNum}_completed') ||
               completedActions.contains('day_$dayNum') ||
               (lessonId.isNotEmpty && (
                 completedActions.contains('lesson_$lessonId') ||
                 completedActions.contains('lesson_${lessonId}_completed')
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
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF58CC02).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.history,
                color: Color(0xFF58CC02),
                size: 20,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Review Past Lessons',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF111827),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFF58CC02).withOpacity(0.2),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF58CC02).withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              ...completedLessons.map((lesson) {
                final dayNum = lesson['day'] as int? ?? 0;
                final title = lesson['title'] as String? ?? 'Unknown Lesson';
                final lessonId = lesson['lesson_id'] as String? ?? lesson['id'] as String? ?? '';
                
                // Show ALL completed lessons (including today's) - all past completed modules should be accessible
                return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: InkWell(
                        onTap: () async {
                          // Navigate to lesson for review
                          if (lessonId.isNotEmpty && !lessonId.startsWith('placeholder_')) {
                            final allInteractiveLessons = InteractiveLessons.getAllLessons();
                            final matchingLesson = allInteractiveLessons.firstWhere(
                              (l) => l['id'] == lessonId,
                              orElse: () => {},
                            );
                            
                            if (matchingLesson.isNotEmpty) {
                              await UserProgressService().trackNavigation(
                                fromScreen: 'LearningTreeScreen',
                                toScreen: 'DuolingoTeachingScreen',
                                navigationMethod: 'push',
                                navigationData: {'lesson_id': lessonId, 'day': dayNum, 'isReview': true},
                              );
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => DuolingoTeachingScreen(lessonId: lessonId),
                                ),
                              );
                            }
                          }
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF58CC02).withOpacity(0.05),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: const Color(0xFF58CC02).withOpacity(0.2),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF58CC02),
                                  borderRadius: BorderRadius.circular(18),
                                ),
                                child: const Center(
                                  child: Icon(
                                    Icons.check_circle,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Day $dayNum',
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: const Color(0xFF58CC02),
                                      ),
                                    ),
                                    Text(
                                      title,
                                      style: GoogleFonts.poppins(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700, // BOLD for past lessons
                                        color: const Color(0xFF111827),
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(
                                Icons.arrow_forward_ios,
                                color: Color(0xFF58CC02),
                                size: 16,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
              }).toList(),
            ],
          ),
        ),
      ],
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
              style: GoogleFonts.poppins(
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
                'Challenge Mode Coming Soon!',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Test your skills with timed challenges and competitive leaderboards.',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
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
    final weekNum = week['week'] as int;
    final weekTitle = week['title'] as String;
    final weekDays = week['days'] as List;
    
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
                      style: GoogleFonts.poppins(
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
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF111827),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${weekDays.length} days',
                        style: GoogleFonts.poppins(
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
    final dayType = day['type'] as String? ?? 'lesson';
    final title = day['title'] as String? ?? 'Unknown Lesson';
    final duration = day['duration'] as String? ?? '5 min';
    final xp = day['xp'] as int? ?? 100;
    
    // Get lesson ID for consistent checking (same as pathway uses)
    final lessonIdStr = day['lesson_id'] as String? ?? day['id'] as String? ?? '';
    
    // Check if unlocked - use same logic as pathway (DailyLessonService)
    bool isUnlocked = false;
    if (lessonIdStr.isNotEmpty && !lessonIdStr.startsWith('placeholder_')) {
      // Use DailyLessonService unlock logic (same as pathway)
      isUnlocked = dailyLessons.isLessonUnlocked(lessonIdStr);
    } else if (dayNum == 1) {
      // Day 1 is always unlocked
      isUnlocked = true;
    } else {
      // Check if previous day is completed (sequential unlock)
      final prevDayNum = dayNum - 1;
      final prevLessonId = LearningPathway.getLessonIdForDay(prevDayNum);
      if (prevLessonId != null) {
        final prevCompleted = completedActions.contains('lesson_$prevLessonId') || 
                             completedActions.contains('lesson_${prevLessonId}_completed') ||
                             completedActions.contains('lesson_$prevDayNum') ||
                             completedActions.contains('lesson_${prevDayNum}_completed') ||
                             completedActions.contains('day_$prevDayNum');
        isUnlocked = prevCompleted;
      } else {
        // Fallback: check if previous day number was completed
        final prevCompletedByDay = completedActions.contains('lesson_$prevDayNum') || 
                                   completedActions.contains('lesson_${prevDayNum}_completed') ||
                                   completedActions.contains('day_$prevDayNum');
        isUnlocked = prevCompletedByDay;
      }
    }
    
    // Check if completed - use same logic as pathway (check by lesson ID AND day number)
    final isCompleted = completedActions.contains('lesson_$dayNum') || 
                        completedActions.contains('lesson_${dayNum}_completed') ||
                        completedActions.contains('day_$dayNum') ||
                        (lessonIdStr.isNotEmpty && (
                          completedActions.contains('lesson_$lessonIdStr') ||
                          completedActions.contains('lesson_${lessonIdStr}_completed')
                        ));
    
    // Get color based on type
    final color = _getDayTypeColor(dayType);
    
    // Get lesson ID for access checking
    final lessonId = day['lesson_id'] as String? ?? day['id'] as String? ?? '';
    
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
        // Check if this lesson was unlocked today using DailyLessonService
        if (dailyLessons.wasLessonUnlockedToday(effectiveLessonId)) {
          return false; // Just unlocked today - can't access until tomorrow
        }
      }
      
      return true; // Can access (either unlocked before today or day 1)
    }
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: FutureBuilder<bool>(
        future: canAccessLesson(),
        builder: (context, snapshot) {
          final canAccess = snapshot.data ?? true; // Default to true if loading
          
          return GestureDetector(
            onTap: isUnlocked && dayType == 'lesson' && canAccess ? () async {
              // Double check if this lesson was just unlocked today
              final effectiveLessonId = lessonIdStr.isNotEmpty ? lessonIdStr : lessonId;
              if (!isCompleted && effectiveLessonId.isNotEmpty && !effectiveLessonId.startsWith('placeholder_')) {
                if (dailyLessons.wasLessonUnlockedToday(effectiveLessonId)) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('🎉 Next lesson unlocked! Available tomorrow - great job completing the previous lesson!'),
                      backgroundColor: const Color(0xFF3B82F6),
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
                      content: Text('📚 Reviewing lesson! (No XP today, but great for practice!)'),
                      backgroundColor: const Color(0xFF3B82F6),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                }
                // Continue to navigation below - allow review access!
              }
              
              // Navigate to lesson
              if (lessonId.isNotEmpty && !lessonId.startsWith('placeholder_')) {
                // Use InteractiveLessons for new lessons
                final allInteractiveLessons = InteractiveLessons.getAllLessons();
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
                    content: Text('This lesson will be available soon! Complete previous lessons to unlock.'),
                    backgroundColor: Colors.orange[700]!,
                    duration: const Duration(seconds: 2),
                  ),
                );
              }
            } : !canAccess && isUnlocked ? () {
              // If just unlocked today, show message
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('🎉 Next lesson unlocked! Available tomorrow - come back tomorrow to start!'),
                  backgroundColor: const Color(0xFF3B82F6),
                  duration: const Duration(seconds: 3),
                ),
              );
            } : isUnlocked ? () {
              // If unlocked but not a lesson (e.g., challenge)
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('You can attempt this tomorrow!'),
                  backgroundColor: const Color(0xFF1E3A8A),
                  duration: const Duration(seconds: 2),
                ),
              );
            } : null,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isCompleted 
                    ? const Color(0xFF58CC02).withOpacity(0.05) // Light green background for completed
                    : isUnlocked
                        ? const Color(0xFF3B82F6).withOpacity(0.03) // Light blue background for unlocked
                        : Colors.white, // White for locked
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isCompleted
                      ? const Color(0xFF58CC02) // Green border for completed
                      : isUnlocked 
                          ? const Color(0xFF3B82F6) // Blue border for unlocked
                          : Colors.grey[300]!, // Grey for locked
                  width: isCompleted ? 3 : isUnlocked ? 2 : 1.5, // Thicker border for completed/unlocked
                ),
                boxShadow: isCompleted
                    ? [
                        BoxShadow(
                          color: const Color(0xFF58CC02).withOpacity(0.2),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : isUnlocked
                        ? [
                            BoxShadow(
                              color: const Color(0xFF3B82F6).withOpacity(0.15),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ]
                        : [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
              ),
              child: Row(
                children: [
              // Day Number & Status
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isCompleted
                      ? const Color(0xFF58CC02) // Green for completed
                      : isUnlocked
                          ? const Color(0xFF3B82F6) // Blue for unlocked
                          : Colors.grey[300]!, // Grey for locked
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: isCompleted
                      ? [
                          BoxShadow(
                            color: const Color(0xFF58CC02).withOpacity(0.4),
                            blurRadius: 12,
                            offset: const Offset(0, 3),
                          ),
                        ]
                      : isUnlocked
                          ? [
                              BoxShadow(
                                color: const Color(0xFF3B82F6).withOpacity(0.3),
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : null,
                ),
                child: Center(
                  child: !isUnlocked
                      ? const Icon(Icons.lock, color: Colors.white, size: 20)
                      : isCompleted
                          ? const Icon(Icons.check_circle, color: Colors.white, size: 24)
                          : Text(
                              '$dayNum',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
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
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: isCompleted ? FontWeight.w700 : FontWeight.w600, // BOLD for completed
                              color: !isUnlocked 
                                  ? Colors.grey[400]! 
                                  : isCompleted 
                                      ? const Color(0xFF111827) // Dark color for completed
                                      : const Color(0xFF111827),
                            ),
                          ),
                        ),
                        if (isCompleted)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF58CC02).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Done ✓',
                                  style: GoogleFonts.poppins(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF58CC02),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Icon(
                                  Icons.touch_app,
                                  size: 10,
                                  color: Color(0xFF58CC02),
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
                              style: GoogleFonts.poppins(
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
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: color,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          duration,
                          style: GoogleFonts.poppins(
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
                              style: GoogleFonts.poppins(
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
      const Color(0xFF58CC02), // Week 1 - Green
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
        return const Color(0xFF58CC02);
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
