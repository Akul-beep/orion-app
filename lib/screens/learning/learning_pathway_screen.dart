import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../services/gamification_service.dart';
import '../../services/user_progress_service.dart';
import '../../services/daily_lesson_service.dart';
import '../../services/database_service.dart';
import '../../data/learning_pathway.dart';
import 'duolingo_teaching_screen.dart';

class LearningPathwayScreen extends StatefulWidget {
  const LearningPathwayScreen({Key? key}) : super(key: key);

  @override
  State<LearningPathwayScreen> createState() => _LearningPathwayScreenState();
}

class _LearningPathwayScreenState extends State<LearningPathwayScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    _animationController.forward();
    
    // Track screen visit
    WidgetsBinding.instance.addPostFrameCallback((_) {
      UserProgressService().trackScreenVisit(
        screenName: 'LearningPathwayScreen',
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
          backgroundColor: const Color(0xFF58CC02),
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
                    child: AnimatedBuilder(
                      animation: _fadeAnimation,
                      builder: (context, child) {
                        return Opacity(
                          opacity: _fadeAnimation.value,
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildProgressOverview(gamification),
                                const SizedBox(height: 24),
                                _buildPathway(),
                              ],
                            ),
                          ),
                        );
                      },
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
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Trading Mastery Path',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'From beginner to profitable trader',
                  style: GoogleFonts.poppins(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${gamification.xp} XP',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressOverview(GamificationService gamification) {
    final totalDays = 30;
    final completedDays = gamification.xp ~/ 200; // Rough estimate
    final progress = completedDays / totalDays;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue[50]!, Colors.purple[50]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.timeline, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                'Your Progress',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Day $completedDays of $totalDays',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: progress,
                      backgroundColor: Colors.grey[200],
                      valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
                      minHeight: 8,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${(progress * 100).round()}% Complete',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Column(
                children: [
                  Text(
                    '${gamification.streak}',
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                    ),
                  ),
                  Text(
                    'Day Streak',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPathway() {
    return Consumer<DailyLessonService>(
      builder: (context, dailyLessonService, child) {
        return FutureBuilder<String?>(
          future: dailyLessonService.getNextUnlockedLessonAsync(),
          builder: (context, nextLessonSnapshot) {
            return FutureBuilder<List<String>>(
              future: DatabaseService.getCompletedActions(),
              builder: (context, completedSnapshot) {
                final completedActions = completedSnapshot.data ?? [];
                final nextLessonId = nextLessonSnapshot.data;
                return FutureBuilder<List<Map<String, dynamic>>>(
                  future: LearningPathway.get30DayPathwayByWeek(),
                  builder: (context, pathwaySnapshot) {
                    if (!pathwaySnapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final pathway = pathwaySnapshot.data!;
                
                    // Update pathway with actual unlock/completion status
                // Only show lessons as unlocked if they're actually in the unlocked list
                // All future lessons beyond the last unlocked lesson should show as locked
                final updatedPathway = pathway.map((week) {
                  final updatedDays = (week['days'] as List).map((day) {
                    final lessonId = day['lesson_id'] as String? ?? '';
                    // Only check if lesson is actually unlocked (not just in pathway)
                    // Explicitly set to false if not in unlocked list
                    final isUnlocked = lessonId.isNotEmpty && dailyLessonService.isLessonUnlocked(lessonId);
                    final isNextLesson = lessonId == nextLessonId;
                    final isCompleted = completedActions.contains('lesson_$lessonId') || 
                                        completedActions.contains('lesson_${lessonId}_completed');
                    return {
                      ...day,
                      'unlocked': isUnlocked, // Explicitly false if not in unlocked list
                      'isNextLesson': isNextLesson, // Mark the next lesson
                      'completed': isCompleted, // Check actual completion status
                    };
                  }).toList();
                  
                  return {
                    ...week,
                    'days': updatedDays,
                  };
                }).toList();
            
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Learning Pathway',
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ...updatedPathway.map((week) => _buildWeekCard(week)).toList(),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildWeekCard(Map<String, dynamic> week) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Week Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _getWeekColor(week['week']).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _getWeekColor(week['week']).withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _getWeekColor(week['week']),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Center(
                    child: Text(
                      'W${week['week']}',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        week['title'],
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      Text(
                        week['description'],
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Days
          ...(week['days'] as List).map((day) => _buildDayCard(day)).toList(),
        ],
      ),
    );
  }

  Widget _buildDayCard(Map<String, dynamic> day) {
    final isUnlocked = day['unlocked'] as bool? ?? false;
    final isCompleted = day['completed'] as bool? ?? false;
    final isNextLesson = day['isNextLesson'] as bool? ?? false;
    final dayType = day['type'] as String? ?? 'lesson';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        elevation: isUnlocked ? 2 : 0,
        child: InkWell(
          onTap: isUnlocked ? () => _startDay(day) : null,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isNextLesson
                  ? const Color(0xFF0052FF) // Highlight next lesson with blue border
                  : isUnlocked 
                    ? (isCompleted ? Colors.green : Colors.blue.withOpacity(0.3))
                    : Colors.grey[300]!,
                width: isNextLesson ? 3 : 2, // Thicker border for next lesson
              ),
              boxShadow: isNextLesson ? [
                BoxShadow(
                  color: const Color(0xFF0052FF).withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ] : null,
            ),
            child: Row(
              children: [
                // Day Icon
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _getDayColor(dayType, isUnlocked, isCompleted),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Center(
                    child: isUnlocked
                      ? (isCompleted 
                          ? const Icon(Icons.check, color: Colors.white, size: 20)
                          : _getDayIcon(dayType))
                      : const Icon(Icons.lock, color: Colors.white, size: 16),
                  ),
                ),
                const SizedBox(width: 16),
                // Day Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Day ${day['day'] as int? ?? 0}: ${day['title'] ?? 'Lesson'}',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isUnlocked ? Colors.black : Colors.grey[400],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          if (isNextLesson) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0052FF).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: const Color(0xFF0052FF),
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                'NEXT',
                                style: GoogleFonts.poppins(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF0052FF),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: _getTypeColor(dayType ?? 'lesson').withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              (dayType ?? 'lesson').toUpperCase(),
                              style: GoogleFonts.poppins(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: _getTypeColor(dayType ?? 'lesson'),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            day['duration'] ?? '5 min',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Colors.grey[500],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${day['xp'] as int? ?? 150} XP',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Colors.orange,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      if (day['paper_trading_action'] != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          '📱 ${day['paper_trading_action']}',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: Colors.blue[600],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                // Arrow
                if (isUnlocked)
                  Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.grey[400],
                    size: 16,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getWeekColor(int week) {
    switch (week) {
      case 1: return Colors.green;
      case 2: return Colors.blue;
      case 3: return Colors.orange;
      case 4: return Colors.purple;
      default: return Colors.grey;
    }
  }

  Color _getDayColor(String type, bool isUnlocked, bool isCompleted) {
    if (!isUnlocked) return Colors.grey;
    if (isCompleted) return Colors.green;
    return _getTypeColor(type);
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'lesson': return Colors.blue;
      case 'challenge': return Colors.orange;
      case 'review': return Colors.purple;
      case 'graduation': return Colors.amber;
      default: return Colors.grey;
    }
  }

  Widget _getDayIcon(String type) {
    switch (type) {
      case 'lesson': return const Icon(Icons.school, color: Colors.white, size: 20);
      case 'challenge': return const Icon(Icons.emoji_events, color: Colors.white, size: 20);
      case 'review': return const Icon(Icons.refresh, color: Colors.white, size: 20);
      case 'graduation': return const Icon(Icons.celebration, color: Colors.white, size: 20);
      default: return const Icon(Icons.play_arrow, color: Colors.white, size: 20);
    }
  }

  void _startDay(Map<String, dynamic> day) {
    if (day['type'] == 'lesson') {
      final lessonId = day['lesson_id'] as String?;
      if (lessonId == null || lessonId.isEmpty) return;
      
      final dailyLessonService = Provider.of<DailyLessonService>(context, listen: false);
      
      // Check if lesson can be accessed today (Duolingo-style)
      if (!dailyLessonService.canAccessLessonToday(lessonId)) {
        // Lesson is either not unlocked OR was unlocked today
        if (dailyLessonService.isLessonUnlocked(lessonId)) {
          // Lesson was unlocked today - show banner (consistent with other entry points)
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
                      style: GoogleFonts.poppins(
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
              duration: const Duration(seconds: 4),
            ),
          );
        } else {
          // Lesson not unlocked yet
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Complete the previous lesson to unlock this one!',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF111827),
                ),
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
        return;
      }
      
      // Lesson can be accessed - navigate to it
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => DuolingoTeachingScreen(
            lessonId: lessonId,
          ),
        ),
      );
    } else {
      // Handle other types (challenge, review, graduation)
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('This lesson type will be available in your learning path. Continue with daily lessons to unlock more content!'),
          backgroundColor: const Color(0xFF58CC02),
        ),
      );
    }
  }
}
