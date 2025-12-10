import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../screens/learning/duolingo_home_screen.dart';
import '../services/database_service.dart';
import '../services/user_progress_service.dart';
import '../design_system.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LearningModule extends StatefulWidget {
  const LearningModule({super.key});

  @override
  State<LearningModule> createState() => _LearningModuleState();
}

class _LearningModuleState extends State<LearningModule> {
  Map<String, dynamic>? _currentLesson;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCurrentLesson();
  }

  Future<void> _loadCurrentLesson() async {
    try {
      final userId = await DatabaseService.getOrCreateLocalUserId();
      final supabase = DatabaseService.getSupabaseClient();
      
      if (supabase != null) {
        // Get the most recent learning progress
        final response = await supabase
            .from('learning_progress')
            .select()
            .eq('user_id', userId)
            .order('last_accessed_at', ascending: false)
            .limit(1)
            .maybeSingle();
        
        if (response != null) {
          setState(() {
            _currentLesson = {
              'lesson_name': response['lesson_name'] ?? 'Intro to Investing',
              'progress_percentage': response['progress_percentage'] ?? 0,
              'lesson_id': response['lesson_id'],
            };
          });
        } else {
          // Default lesson if no progress
          setState(() {
            _currentLesson = {
              'lesson_name': 'Intro to Investing',
              'progress_percentage': 0,
              'lesson_id': 'intro_lesson_1',
            };
          });
        }
      } else {
        // Fallback to default
        setState(() {
          _currentLesson = {
            'lesson_name': 'Intro to Investing',
            'progress_percentage': 0,
            'lesson_id': 'intro_lesson_1',
          };
        });
      }
    } catch (e) {
      print('Error loading current lesson: $e');
      // Fallback to default
      setState(() {
        _currentLesson = {
          'lesson_name': 'Intro to Investing',
          'progress_percentage': 0,
          'lesson_id': 'intro_lesson_1',
        };
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Keep Learning',
            style: OrionDesignSystem.heading3,
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: OrionDesignSystem.primaryCard,
            child: const Center(child: CircularProgressIndicator()),
          ),
        ],
      );
    }

    final lessonName = _currentLesson?['lesson_name'] ?? 'Intro to Investing';
    final progress = (_currentLesson?['progress_percentage'] ?? 0) / 100.0;
    final lessonNumber = _getLessonNumber(progress);
    final totalLessons = 5;
    final isCompleted = progress >= 1.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Keep Learning',
          style: OrionDesignSystem.heading3,
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: isCompleted 
              ? BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF58CC02), Color(0xFF6EE7B7)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF58CC02).withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                )
              : OrionDesignSystem.primaryCard,
          child: Row(
            children: [
              // Progress indicator with completion badge
              SizedBox(
                width: 64,
                height: 64,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    if (!isCompleted)
                      CircularProgressIndicator(
                        value: progress,
                        strokeWidth: 6,
                        backgroundColor: isCompleted 
                            ? Colors.white.withOpacity(0.3)
                            : OrionDesignSystem.lightGrey,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          isCompleted 
                              ? Colors.white
                              : const Color(0xFF58CC02), // Duolingo green
                        ),
                      ),
                    if (isCompleted)
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.check_circle,
                          color: Color(0xFF58CC02), // Duolingo green
                          size: 32,
                        ),
                      )
                    else
                      Icon(
                        Icons.school,
                        color: isCompleted ? Colors.white : OrionDesignSystem.textSecondary,
                        size: 28,
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            lessonName,
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                              color: isCompleted ? Colors.white : OrionDesignSystem.textPrimary,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isCompleted) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.check_circle,
                                  color: Colors.white,
                                  size: 14,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Completed',
                                  style: GoogleFonts.inter(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      isCompleted 
                          ? 'Great job! Ready for the next lesson?'
                          : 'Lesson $lessonNumber of $totalLessons',
                      style: GoogleFonts.inter(
                        color: isCompleted 
                            ? Colors.white.withOpacity(0.9)
                            : OrionDesignSystem.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                    if (!isCompleted) ...[
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 4,
                          backgroundColor: isCompleted 
                              ? Colors.white.withOpacity(0.3)
                              : OrionDesignSystem.lightGrey,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            isCompleted 
                                ? Colors.white
                                : const Color(0xFF58CC02), // Duolingo green
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: () async {
                  // Track interaction
                  await UserProgressService().trackWidgetInteraction(
                    screenName: 'HomeScreen',
                    widgetType: 'button',
                    actionType: 'tap',
                    widgetId: 'continue_learning',
                    interactionData: {'lesson_name': lessonName},
                  );
                  
                  // Track navigation
                  await UserProgressService().trackNavigation(
                    fromScreen: 'HomeScreen',
                    toScreen: 'DuolingoHomeScreen',
                    navigationMethod: 'push',
                    navigationData: {'lesson_id': _currentLesson?['lesson_id']},
                  );
                  
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const DuolingoHomeScreen(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: isCompleted ? Colors.white : const Color(0xFF58CC02), // Duolingo green
                  foregroundColor: isCompleted ? const Color(0xFF58CC02) : Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  elevation: isCompleted ? 2 : 0,
                ),
                child: Text(
                  isCompleted ? 'Next' : 'Continue',
                  style: GoogleFonts.inter(
                    color: isCompleted ? const Color(0xFF58CC02) : Colors.white, // Duolingo green
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  int _getLessonNumber(double progress) {
    // Calculate lesson number based on progress
    if (progress < 0.2) return 1;
    if (progress < 0.4) return 2;
    if (progress < 0.6) return 3;
    if (progress < 0.8) return 4;
    return 5;
  }
}
