import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../services/gamification_service.dart';
import '../../services/database_service.dart';
import '../../services/user_progress_service.dart';
import '../../services/daily_lesson_service.dart';
import '../../services/personalization_service.dart';
import '../../widgets/daily_goals_widget.dart';
import '../../data/interactive_lessons.dart';
import '../../data/learning_pathway.dart';
import '../../data/trading_lessons_data.dart';
import 'interactive_lesson_screen.dart';
import 'duolingo_teaching_screen.dart';
import 'learning_tree_screen.dart';

class DuolingoHomeScreen extends StatefulWidget {
  const DuolingoHomeScreen({Key? key}) : super(key: key);

  @override
  State<DuolingoHomeScreen> createState() => _DuolingoHomeScreenState();
}

class _DuolingoHomeScreenState extends State<DuolingoHomeScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _progressAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
    // Load gamification data from database
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final gamification = Provider.of<GamificationService>(context, listen: false);
      gamification.loadFromDatabase();
      
      // Load personalization
      final personalization = Provider.of<PersonalizationService>(context, listen: false);
      personalization.loadUserPreferences();
      
      // Initialize daily lesson service
      await DailyLessonService().initialize();
      
      // Track screen visit
      UserProgressService().trackScreenVisit(
        screenName: 'DuolingoHomeScreen',
        screenType: 'main',
        metadata: {'section': 'learning'},
      );
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<GamificationService>(
      builder: (context, gamification, child) {
        return Scaffold(
          backgroundColor: const Color(0xFF58CC02), // Duolingo green
          body: SafeArea(
            child: Column(
              children: [
                _buildHeader(gamification),
                Expanded(
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                      ),
                    ),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const DailyGoalsWidget(compact: true),
                          const SizedBox(height: 24),
                          _buildPersonalizedRecommendations(),
                          const SizedBox(height: 24),
                          _buildLessonPath(),
                          const SizedBox(height: 24),
                          _buildLearningTreeButton(),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(GamificationService gamification) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        children: [
          // Profile Avatar
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: Colors.white, width: 2.5),
            ),
            child: const Icon(Icons.person, color: Color(0xFF10B981), size: 22),
          ),
          const SizedBox(width: 10),
          // User Info - Show streak and level instead
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Icon(Icons.local_fire_department, color: Colors.white, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      '${gamification.streak} day streak',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        height: 1.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  'Level ${gamification.level} • ${gamification.xp} XP',
                  style: GoogleFonts.inter(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 12,
                    height: 1.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          // Hearts (Lives) - Smaller
          _buildHearts(),
          const SizedBox(width: 6),
          // Gems - Smaller
          _buildGems(gamification),
        ],
      ),
    );
  }

  Widget _buildHearts() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(5, (index) {
          return Padding(
            padding: EdgeInsets.only(right: index < 4 ? 2 : 0),
            child: Icon(
              Icons.favorite,
              color: index < 5 ? Colors.red[400] : Colors.grey[300],
              size: 12,
            ),
          );
        }),
      ),
    );
  }

  Widget _buildGems(GamificationService gamification) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF3B82F6).withOpacity(0.25),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.diamond, color: Color(0xFF60A5FA), size: 14),
          const SizedBox(width: 3),
          Text(
            '${gamification.xp}',
            style: GoogleFonts.inter(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildPersonalizedRecommendations() {
    return Consumer2<DailyLessonService, GamificationService>(
      builder: (context, dailyLessons, gamification, child) {
        return FutureBuilder<String?>(
          future: dailyLessons.getNextUnlockedLessonAsync(),
          builder: (context, snapshot) {
            final nextLessonId = snapshot.data;
            
            if (nextLessonId == null) {
              return const SizedBox.shrink();
            }

            final lesson = InteractiveLessons.getLessonById(nextLessonId);
            if (lesson == null) return const SizedBox.shrink();
            
            // Convert lesson data for compatibility with UI
            final displayLesson = {
              'id': lesson['id'],
              'title': lesson['title'],
              'description': lesson['description'],
              'duration': '${lesson['duration']} min',
              'xp': lesson['xp_reward'] ?? 150,
              'color': 0xFF3B82F6, // Default blue
            };

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E3A8A).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.school, color: Color(0xFF1E3A8A), size: 20),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Your Next Lesson',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF111827),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: () async {
                    await UserProgressService().trackNavigation(
                      fromScreen: 'DuolingoHomeScreen',
                      toScreen: 'DuolingoTeachingScreen',
                      navigationMethod: 'push',
                    );
                    // Navigate to DuolingoTeachingScreen first (TEACH then QUIZ - like Duolingo!)
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => DuolingoTeachingScreen(
                          lessonId: nextLessonId!,
                        ),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Color(displayLesson['color'] as int? ?? 0xFF3B82F6),
                          Color(displayLesson['color'] as int? ?? 0xFF3B82F6).withOpacity(0.7),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Color(displayLesson['color'] as int? ?? 0xFF3B82F6).withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Text(
                              lesson['badge_emoji'] ?? displayLesson['icon'] ?? '📚',
                              style: const TextStyle(fontSize: 28),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                displayLesson['title'] ?? lesson['title'] ?? 'Lesson',
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                displayLesson['description'] ?? lesson['description'] ?? '',
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  color: Colors.white.withOpacity(0.9),
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.diamond, color: Colors.white, size: 14),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${displayLesson['xp'] ?? lesson['xp_reward'] ?? 150} XP',
                                          style: GoogleFonts.poppins(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      displayLesson['duration'] ?? '${lesson['duration'] ?? 5} min',
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.play_arrow,
                            color: Color(0xFF1E3A8A),
                            size: 28,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildLessonPath() {
    return Consumer<DailyLessonService>(
      builder: (context, dailyLessons, child) {
            return FutureBuilder<List<String>>(
          future: DatabaseService.getCompletedActions(),
          builder: (context, snapshot) {
            final completedActions = snapshot.data ?? [];
            // Use learning pathway to get lessons in proper beginner-to-advanced order
            final pathway = LearningPathway.get30DayPathway();
            
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Learning Path',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF111827),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E3A8A).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.lock_open, color: const Color(0xFF1E3A8A), size: 14),
                          const SizedBox(width: 4),
                          Text(
                            '${dailyLessons.unlockedLessons.length} unlocked',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF1E3A8A),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Builder(
                  builder: (context) {
                    // Find the next lesson to complete (first unlocked but not completed)
                    int? nextLessonIndex;
                    for (int i = 0; i < pathway.length; i++) {
                      final lesson = pathway[i];
                      final lessonId = lesson['id'] as String;
                      final isUnlocked = dailyLessons.isLessonUnlocked(lessonId);
                      final isCompleted = completedActions.contains('lesson_$lessonId') || 
                                          completedActions.contains('lesson_${lessonId}_completed');
                      
                      if (isUnlocked && !isCompleted) {
                        nextLessonIndex = i;
                        break;
                      }
                    }
                    
                    // If all unlocked lessons are completed, find the first locked lesson
                    if (nextLessonIndex == null) {
                      for (int i = 0; i < pathway.length; i++) {
                        final lesson = pathway[i];
                        final lessonId = lesson['id'] as String;
                        final isUnlocked = dailyLessons.isLessonUnlocked(lessonId);
                        if (!isUnlocked) {
                          nextLessonIndex = i;
                          break;
                        }
                      }
                    }
                    
                    // Show next 4 lessons starting from the next incomplete lesson (auto-updates as user progresses)
                    final startIndex = nextLessonIndex ?? 0;
                    final lessonsToShow = pathway.sublist(
                      startIndex,
                      startIndex + 4 < pathway.length ? startIndex + 4 : pathway.length,
                    );
                    
                    if (lessonsToShow.isEmpty) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32.0),
                          child: Column(
                            children: [
                              Icon(Icons.emoji_events, size: 64, color: Colors.amber[600]),
                              const SizedBox(height: 16),
                              Text(
                                '🎉 Amazing!',
                                style: GoogleFonts.poppins(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF111827),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'You\'ve completed all unlocked lessons!\nNew lessons unlock daily.',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }
                    
                    return Column(
                      children: lessonsToShow.map((lesson) {
                        final lessonId = lesson['id'] as String;
                        final dayNum = lesson['day'] as int?;
                        
                        // Check unlock status - use same logic as tree (check by DailyLessonService OR previous completion)
                        bool isUnlocked = dailyLessons.isLessonUnlocked(lessonId);
                        
                        // Also check if previous lesson is completed (sequential unlock - same as tree)
                        if (!isUnlocked && dayNum != null) {
                          if (dayNum == 1) {
                            // Day 1 is always unlocked
                            isUnlocked = true;
                          } else {
                            // Check if previous day is completed
                            final prevLessonId = LearningPathway.getLessonIdForDay(dayNum - 1);
                            if (prevLessonId != null) {
                              final prevCompleted = completedActions.contains('lesson_$prevLessonId') || 
                                                    completedActions.contains('lesson_${prevLessonId}_completed');
                              if (prevCompleted) {
                                // Unlock next lesson if previous is completed (same logic as tree)
                                isUnlocked = true;
                              }
                            } else {
                              // Fallback: check by day number
                              final prevDayNum = dayNum - 1;
                              final prevCompletedByDay = completedActions.contains('lesson_$prevDayNum') || 
                                                         completedActions.contains('lesson_${prevDayNum}_completed') ||
                                                         completedActions.contains('day_$prevDayNum');
                              isUnlocked = prevCompletedByDay;
                            }
                          }
                        }
                        
                        final isCompleted = completedActions.contains('lesson_$lessonId') || 
                                            completedActions.contains('lesson_${lessonId}_completed');
                        
                        // Determine unlock status message - check if unlocked today
                        String unlockStatus = '';
                        if (!isUnlocked && !isCompleted) {
                          // Check if previous lesson is completed
                          if (dayNum != null && dayNum > 1) {
                            final prevLessonId = LearningPathway.getLessonIdForDay(dayNum - 1);
                            if (prevLessonId != null) {
                              final prevCompleted = completedActions.contains('lesson_$prevLessonId') || 
                                                    completedActions.contains('lesson_${prevLessonId}_completed');
                              if (prevCompleted) {
                                unlockStatus = 'Unlocked! Tap to start';
                              } else {
                                unlockStatus = 'Complete lesson ${dayNum - 1} to unlock';
                              }
                            } else {
                              unlockStatus = 'Unlocks tomorrow';
                            }
                          } else {
                            unlockStatus = 'Unlocks tomorrow';
                          }
                        } else if (isUnlocked && !isCompleted) {
                          // For unlocked lessons, check if previous lesson was completed today
                          // If so, show "Available tomorrow", otherwise "Tap to start"
                          unlockStatus = 'Unlocked - Tap to start'; // Default, will be checked in onTap
                        } else if (isCompleted) {
                          unlockStatus = 'Completed today ✓'; // Will check exact date in onTap
                        }
                        
                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          child: _buildLessonCard(
                            lesson: lesson,
                            title: lesson['title'] ?? 'Lesson',
                            description: lesson['description'] ?? '',
                            xp: (lesson['xp_reward'] as int?) ?? 150,
                            isCompleted: isCompleted,
                            isLocked: !isUnlocked,
                            unlockStatus: unlockStatus,
                            color: isUnlocked ? const Color(0xFF3B82F6) : Colors.grey,
                            icon: lesson['badge_emoji'] ?? '📚',
                            difficulty: lesson['difficulty'] ?? 'Beginner',
                            duration: '${lesson['duration'] ?? 5} min',
                      onTap: () async {
                        // Check if lesson is already completed today
                        if (isCompleted) {
                          final completedToday = await DatabaseService.isActionCompletedToday('lesson_$lessonId');
                          
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(completedToday
                                  ? '✅ Lesson completed today! Come back tomorrow to practice again.'
                                  : '✅ Lesson completed! You can attempt it again anytime.'),
                              backgroundColor: const Color(0xFF58CC02),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                          return;
                        }
                        
                        // Check if this lesson was just unlocked today using DailyLessonService
                        // If so, tell user it's available tomorrow
                        final dailyLessonService = Provider.of<DailyLessonService>(context, listen: false);
                        if (dailyLessonService.wasLessonUnlockedToday(lessonId)) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('🎉 Next lesson unlocked! Available tomorrow - great job completing the previous lesson!'),
                              backgroundColor: const Color(0xFF3B82F6),
                              duration: const Duration(seconds: 3),
                            ),
                          );
                          return;
                        }
                        
                        // Navigate to TEACHING screen first (like Duolingo - teach then quiz!)
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => DuolingoTeachingScreen(
                              lessonId: lessonId,
                            ),
                          ),
                        );
                      },
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildLessonCard({
    required Map<String, dynamic> lesson,
    required String title,
    required String description,
    required int xp,
    required bool isCompleted,
    required bool isLocked,
    required Color color,
    required String icon,
    required String difficulty,
    required String duration,
    String unlockStatus = '',
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: isLocked ? null : (onTap ?? () async {
        final lessonId = lesson['id'].toString();
        
        // Track interaction
        await UserProgressService().trackWidgetInteraction(
          screenName: 'DuolingoHomeScreen',
          widgetType: 'lesson_card',
          actionType: 'tap',
          widgetId: lessonId,
          interactionData: {'lesson_name': lesson['title']},
        );
        
        // Track navigation
        await UserProgressService().trackNavigation(
          fromScreen: 'DuolingoHomeScreen',
          toScreen: 'InteractiveLessonScreen',
          navigationMethod: 'push',
          navigationData: {'lesson_id': lessonId},
        );
        
        // Track learning progress
        await UserProgressService().trackLearningProgress(
          lessonId: lessonId,
          lessonName: lesson['title'],
          progressPercentage: 0,
        );
        
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => InteractiveLessonScreen(
              lessonId: lessonId,
            ),
          ),
        );
      }),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isCompleted
              ? const Color(0xFF58CC02).withOpacity(0.08) // Light green background for completed
              : !isLocked
                  ? const Color(0xFF3B82F6).withOpacity(0.04) // Light blue background for unlocked
                  : Colors.grey[50], // Grey for locked
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isCompleted
                ? const Color(0xFF58CC02) // Green border for completed
                : !isLocked
                    ? const Color(0xFF3B82F6) // Blue border for unlocked
                    : Colors.grey[300]!, // Grey for locked
            width: isCompleted ? 3 : !isLocked ? 2 : 1.5, // Thicker border for completed/unlocked
          ),
          boxShadow: isCompleted
              ? [
                  BoxShadow(
                    color: const Color(0xFF58CC02).withOpacity(0.2),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : !isLocked
                  ? [
                      BoxShadow(
                        color: const Color(0xFF3B82F6).withOpacity(0.15),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ]
                  : null,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Completion indicator - Very prominent
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: isCompleted
                    ? const Color(0xFF58CC02) // Green for completed
                    : !isLocked
                        ? const Color(0xFF3B82F6) // Blue for unlocked
                        : Colors.grey[300]!, // Grey for locked
                borderRadius: BorderRadius.circular(26),
                boxShadow: isCompleted
                    ? [
                        BoxShadow(
                          color: const Color(0xFF58CC02).withOpacity(0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : !isLocked
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
                child: isLocked 
                    ? const Icon(Icons.lock, color: Colors.white, size: 22)
                    : isCompleted 
                        ? const Icon(Icons.check_circle, color: Colors.white, size: 26)
                        : Text(
                            icon,
                            style: const TextStyle(fontSize: 22),
                          ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: isLocked 
                          ? Colors.grey[400] 
                          : isCompleted 
                              ? const Color(0xFF111827)
                              : const Color(0xFF111827),
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    description,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: isLocked ? Colors.grey[400] : const Color(0xFF6B7280),
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  // Show unlock status if provided
                  if (unlockStatus.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      child: Text(
                        unlockStatus,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isLocked 
                              ? Colors.orange[700] 
                              : isCompleted
                                  ? const Color(0xFF58CC02)
                                  : const Color(0xFF3B82F6),
                        ),
                      ),
                    ),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: _getDifficultyColor(difficulty).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          difficulty,
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: _getDifficultyColor(difficulty),
                          ),
                        ),
                      ),
                      Text(
                        duration,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: const Color(0xFF9CA3AF),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (!isLocked)
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (isCompleted)
                    Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF58CC02), Color(0xFF6EE7B7)],
                        ),
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF58CC02).withOpacity(0.3),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.check_circle, color: Colors.white, size: 12),
                          const SizedBox(width: 4),
                          Text(
                            'Done',
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (!isLocked)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
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
                          if (isCompleted) ...[
                            const SizedBox(width: 4),
                            Text(
                              '(Practice: ${(xp * 0.1).round()} XP)',
                              style: GoogleFonts.inter(
                                fontSize: 9,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLearningTreeButton() {
    return GestureDetector(
      onTap: () async {
        await UserProgressService().trackNavigation(
          fromScreen: 'DuolingoHomeScreen',
          toScreen: 'LearningTreeScreen',
          navigationMethod: 'push',
        );
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const LearningTreeScreen(),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFF1E3A8A),
              const Color(0xFF1E3A8A).withOpacity(0.8),
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
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.account_tree,
                color: Colors.white,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'View Learning Tree',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'See all planned lessons and your progress',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              color: Colors.white,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

class CircularProgressPainter extends CustomPainter {
  final double progress;
  final Color color;

  CircularProgressPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 4;

    // Background circle
    final backgroundPaint = Paint()
      ..color = Colors.grey[200]!
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;

    canvas.drawCircle(center, radius, backgroundPaint);

    // Progress arc
    final progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    final sweepAngle = 2 * 3.14159 * progress;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -3.14159 / 2, // Start from top
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

Color _getDifficultyColor(String difficulty) {
  switch (difficulty.toLowerCase()) {
    case 'beginner':
      return Colors.green;
    case 'intermediate':
      return Colors.orange;
    case 'advanced':
      return Colors.red;
    default:
      return Colors.grey;
  }
}
