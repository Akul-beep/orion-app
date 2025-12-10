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

  // Helper method to show consistent banner messages across all entry points
  void _showUnlockedBanner(BuildContext context) {
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
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _showLockedBanner(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Complete the previous lesson to unlock this one!',
          style: GoogleFonts.inter(
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

  @override
  Widget build(BuildContext context) {
    return Consumer<GamificationService>(
      builder: (context, gamification, child) {
        return Scaffold(
          backgroundColor: const Color(0xFFF5F7FA),
          body: SafeArea(
            child: Column(
              children: [
                _buildHeader(gamification),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const DailyGoalsWidget(compact: true),
                        const SizedBox(height: 20),
                        _buildPersonalizedRecommendations(),
                        const SizedBox(height: 20),
                        _buildLessonPath(),
                        const SizedBox(height: 20),
                        _buildLearningTreeButton(),
                        const SizedBox(height: 16),
                      ],
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: const Color(0xFFE5E7EB),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Profile Avatar
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFF5F7FA),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFFE5E7EB),
                width: 1,
              ),
            ),
            child: const Icon(
              Icons.person_outline,
              color: Color(0xFF0052FF),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          // User Info - Show streak and level instead
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF6B35).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(
                        Icons.local_fire_department,
                        color: Color(0xFFFF6B35),
                        size: 14,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${gamification.streak} day streak',
                      style: GoogleFonts.inter(
                        color: const Color(0xFF111827),
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        height: 1.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Level ${gamification.level} • ${gamification.xp} XP',
                      style: GoogleFonts.inter(
                        color: const Color(0xFF6B7280),
                        fontSize: 13,
                        height: 1.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => _showLevelInfoDialog(context, gamification),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0052FF).withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.info_outline,
                          size: 16,
                          color: const Color(0xFF0052FF),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Hearts removed from header per requirements
          // Gems - Professional style
          _buildGems(gamification),
        ],
      ),
    );
  }

  Widget _buildHearts() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F7FA),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(5, (index) {
          return Padding(
            padding: EdgeInsets.only(right: index < 4 ? 3 : 0),
            child: Icon(
              Icons.favorite,
              color: index < 5 ? const Color(0xFFEF4444) : const Color(0xFFD1D5DB),
              size: 14,
            ),
          );
        }),
      ),
    );
  }

  void _showLevelInfoDialog(BuildContext context, GamificationService gamification) {
    final currentLevel = gamification.level;
    final currentXP = gamification.xp;
    final xpForCurrentLevel = (currentLevel - 1) * 1000;
    final xpForNextLevel = currentLevel * 1000;
    final xpNeeded = xpForNextLevel - currentXP;
    final progressPercent = ((currentXP - xpForCurrentLevel) / 1000 * 100).clamp(0.0, 100.0);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF0052FF).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.star,
                color: Color(0xFF0052FF),
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Level System',
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF111827),
                ),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'How Leveling Works',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'You earn XP (Experience Points) by completing activities in the app. Every 1,000 XP you earn increases your level by 1.',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: const Color(0xFF6B7280),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Your Progress',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF111827),
                          ),
                        ),
                        Text(
                          'Level $currentLevel',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF0052FF),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    LinearProgressIndicator(
                      value: progressPercent / 100,
                      backgroundColor: Colors.grey[300],
                      valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF0052FF)),
                      minHeight: 8,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '$currentXP / $xpForNextLevel XP • $xpNeeded XP to Level ${currentLevel + 1}',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: const Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Ways to Earn XP',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 12),
              _buildXPItem(Icons.school, 'Complete Lessons', '100-500 XP per lesson'),
              _buildXPItem(Icons.trending_up, 'Make Trades', '10 XP per trade'),
              _buildXPItem(Icons.login, 'Daily Login', '10-50 XP bonus'),
              _buildXPItem(Icons.emoji_events, 'Achievements', '50-500 XP per milestone'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Got it!',
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF0052FF),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildXPItem(IconData icon, String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF0052FF).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              size: 20,
              color: const Color(0xFF0052FF),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF111827),
                  ),
                ),
                Text(
                  description,
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
    );
  }

  Widget _buildGems(GamificationService gamification) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF0052FF).withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: const Color(0xFF0052FF).withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.diamond, color: Color(0xFF0052FF), size: 14),
          const SizedBox(width: 4),
          Text(
            '${gamification.xp}',
            style: GoogleFonts.inter(
              color: const Color(0xFF0052FF),
              fontWeight: FontWeight.w600,
              fontSize: 13,
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

            return FutureBuilder<Map<String, dynamic>?>(
              future: InteractiveLessons.getLessonById(nextLessonId),
              builder: (context, lessonSnapshot) {
                if (!lessonSnapshot.hasData || lessonSnapshot.data == null) {
                  return const SizedBox.shrink();
                }
                final lesson = lessonSnapshot.data!;
            
            // Check if lesson is unlocked and can be accessed
            final isUnlocked = dailyLessons.isLessonUnlocked(nextLessonId);
            final canAccess = isUnlocked && dailyLessons.canAccessLessonToday(nextLessonId);
            final wasUnlockedToday = isUnlocked && dailyLessons.wasLessonUnlockedToday(nextLessonId);
            
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
                        color: const Color(0xFF0052FF).withOpacity(0.08),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.school_outlined, color: Color(0xFF0052FF), size: 20),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Your Next Lesson',
                      style: GoogleFonts.inter(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF111827),
                        letterSpacing: -0.3,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: () async {
                    // Check if this lesson can be accessed today (Duolingo-style)
                    // If lesson was unlocked today, show banner saying it's available tomorrow
                    final dailyLessonService = Provider.of<DailyLessonService>(context, listen: false);
                    if (!dailyLessonService.canAccessLessonToday(nextLessonId!)) {
                      // Lesson is either not unlocked OR was unlocked today
                      if (dailyLessonService.isLessonUnlocked(nextLessonId!)) {
                        // Lesson was unlocked today - show banner
                        _showUnlockedBanner(context);
                      } else {
                        // Lesson not unlocked yet - show message to complete previous lesson
                        _showLockedBanner(context);
                      }
                      return;
                    }
                    
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
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: canAccess 
                            ? const Color(0xFF0052FF) // Blue border if accessible
                            : wasUnlockedToday
                                ? const Color(0xFF0052FF).withOpacity(0.5) // Light blue if unlocked today
                                : const Color(0xFFE5E7EB), // Grey if locked
                        width: canAccess ? 2 : 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: canAccess 
                              ? const Color(0xFF0052FF).withOpacity(0.1)
                              : Colors.black.withOpacity(0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: canAccess
                                ? const Color(0xFF0052FF).withOpacity(0.08)
                                : const Color(0xFFE5E7EB).withOpacity(0.5),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: canAccess
                                ? Text(
                                    lesson['badge_emoji'] ?? displayLesson['icon'] ?? '📚',
                                    style: const TextStyle(fontSize: 28),
                                  )
                                : const Icon(
                                    Icons.lock_outline,
                                    color: Color(0xFF9CA3AF),
                                    size: 24,
                                  ),
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
                                      displayLesson['title'] ?? lesson['title'] ?? 'Lesson',
                                      style: GoogleFonts.inter(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: canAccess 
                                            ? const Color(0xFF111827)
                                            : const Color(0xFF9CA3AF),
                                      ),
                                    ),
                                  ),
                                  if (wasUnlockedToday) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF0052FF).withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(
                                          color: const Color(0xFF0052FF),
                                          width: 1,
                                        ),
                                      ),
                                      child: Text(
                                        'UNLOCKED',
                                        style: GoogleFonts.inter(
                                          fontSize: 9,
                                          fontWeight: FontWeight.w700,
                                          color: const Color(0xFF0052FF),
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                canAccess
                                    ? (displayLesson['description'] ?? lesson['description'] ?? '')
                                    : wasUnlockedToday
                                        ? 'Available tomorrow! Complete previous lesson to unlock.'
                                        : 'Complete previous lessons to unlock this lesson.',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  color: canAccess 
                                      ? const Color(0xFF6B7280)
                                      : const Color(0xFF9CA3AF),
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: canAccess
                                          ? const Color(0xFF0052FF).withOpacity(0.08)
                                          : const Color(0xFFE5E7EB).withOpacity(0.5),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.diamond, 
                                          color: canAccess 
                                              ? const Color(0xFF0052FF)
                                              : const Color(0xFF9CA3AF),
                                          size: 14,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${displayLesson['xp'] ?? lesson['xp_reward'] ?? 150} XP',
                                          style: GoogleFonts.inter(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: canAccess 
                                                ? const Color(0xFF0052FF)
                                                : const Color(0xFF9CA3AF),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF5F7FA),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      displayLesson['duration'] ?? '${lesson['duration'] ?? 5} min',
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color: const Color(0xFF6B7280),
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
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: canAccess
                                ? const Color(0xFF0052FF)
                                : const Color(0xFFE5E7EB),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: canAccess ? [
                              BoxShadow(
                                color: const Color(0xFF0052FF).withOpacity(0.2),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ] : null,
                          ),
                          child: Icon(
                            canAccess 
                                ? Icons.play_arrow_rounded
                                : Icons.lock_outline,
                            color: canAccess 
                                ? Colors.white
                                : const Color(0xFF9CA3AF),
                            size: 24,
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
      },
    );
  }

  Widget _buildLessonPath() {
    return Consumer<DailyLessonService>(
      builder: (context, dailyLessons, child) {
        return FutureBuilder<String?>(
          future: dailyLessons.getNextUnlockedLessonAsync(),
          builder: (context, nextLessonSnapshot) {
            return FutureBuilder<List<String>>(
              future: DatabaseService.getCompletedActions(),
              builder: (context, snapshot) {
                final completedActions = snapshot.data ?? [];
                final nextLessonId = nextLessonSnapshot.data;
                // Use learning pathway to get lessons in proper beginner-to-advanced order
                return FutureBuilder<List<Map<String, dynamic>>>(
                  future: LearningPathway.get30DayPathway(),
                  builder: (context, pathwaySnapshot) {
                    if (!pathwaySnapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final pathway = pathwaySnapshot.data!;
            
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      'Learning Path',
                      style: GoogleFonts.inter(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF111827),
                        letterSpacing: -0.3,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0052FF).withOpacity(0.08),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: const Color(0xFF0052FF).withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.lock_open_outlined, color: Color(0xFF0052FF), size: 14),
                          const SizedBox(width: 4),
                          Text(
                            '${dailyLessons.unlockedLessons.length} unlocked',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF0052FF),
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
                    // Find the index of the next lesson (same as "Your Next Lesson" uses)
                    // This ensures they match!
                    int? nextLessonIndex;
                    if (nextLessonId != null) {
                      // Find the index of the next lesson in the pathway
                      for (int i = 0; i < pathway.length; i++) {
                        final lesson = pathway[i];
                        // Handle both int and String IDs
                        final rawId = lesson['id'];
                        final lessonId = rawId is String ? rawId : (rawId is int ? rawId.toString() : '');
                        if (lessonId == nextLessonId) {
                          nextLessonIndex = i;
                          break;
                        }
                      }
                    }
                    
                    // If next lesson not found, find the first unlocked but not completed lesson
                    if (nextLessonIndex == null) {
                      for (int i = 0; i < pathway.length; i++) {
                        final lesson = pathway[i];
                        // Handle both int and String IDs
                        final rawId = lesson['id'];
                        final lessonId = rawId is String ? rawId : (rawId is int ? rawId.toString() : '');
                        if (lessonId.isEmpty) continue;
                        final isUnlocked = dailyLessons.isLessonUnlocked(lessonId);
                        final isCompleted = completedActions.contains('lesson_$lessonId') || 
                                            completedActions.contains('lesson_${lessonId}_completed');
                        
                        if (isUnlocked && !isCompleted) {
                          nextLessonIndex = i;
                          break;
                        }
                      }
                    }
                    
                    // If all unlocked lessons are completed, find the first locked lesson
                    if (nextLessonIndex == null) {
                      for (int i = 0; i < pathway.length; i++) {
                        final lesson = pathway[i];
                        // Handle both int and String IDs
                        final rawId = lesson['id'];
                        final lessonId = rawId is String ? rawId : (rawId is int ? rawId.toString() : '');
                        if (lessonId.isEmpty) continue;
                        final isUnlocked = dailyLessons.isLessonUnlocked(lessonId);
                        if (!isUnlocked) {
                          nextLessonIndex = i;
                          break;
                        }
                      }
                    }
                    
                    // Show next 4 lessons AFTER the next lesson (exclude next lesson since it's shown in "Your Next Lesson" tab)
                    // Start from the lesson after the next lesson
                    final startIndex = nextLessonIndex != null ? nextLessonIndex! + 1 : 0;
                    final endIndex = startIndex + 4 < pathway.length ? startIndex + 4 : pathway.length;
                    
                    if (startIndex >= pathway.length) {
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
                    
                    final lessonsToShow = pathway.sublist(startIndex, endIndex);
                    
                    if (lessonsToShow.isEmpty) {
                      return const SizedBox.shrink();
                    }
                    
                    return Column(
                      children: lessonsToShow.map((lesson) {
                        // Handle both int and String IDs
                        final rawId = lesson['id'];
                        final lessonId = rawId is String ? rawId : (rawId is int ? rawId.toString() : '');
                        final dayNum = lesson['day'] as int?;
                        
                        // Check if this is the next lesson (same as "Your Next Lesson")
                        final isNextLesson = lessonId == nextLessonId;
                        
                        // Check unlock status - ONLY use DailyLessonService
                        // This ensures consistency with "Your Next Lesson"
                        // Explicitly check if lesson is in unlocked list - no defaults
                        bool isUnlocked = lessonId.isNotEmpty && dailyLessons.isLessonUnlocked(lessonId);
                        
                        // Day 1 is always unlocked (if it exists)
                        if (dayNum == 1 && lessonId.isNotEmpty) {
                          // Check if day 1 is actually in unlocked list, if not, add it
                          if (!isUnlocked) {
                            // Day 1 should always be unlocked - this is a fallback
                            isUnlocked = true;
                          }
                        }
                        
                        final isCompleted = completedActions.contains('lesson_$lessonId') || 
                                            completedActions.contains('lesson_${lessonId}_completed');
                        
                        // Check if lesson was unlocked today (Duolingo-style: unlocked but not accessible)
                        final wasUnlockedToday = dailyLessons.wasLessonUnlockedToday(lessonId);
                        final canAccessToday = isUnlocked && !wasUnlockedToday;
                        
                        // Determine unlock status message
                        String unlockStatus = '';
                        if (isCompleted) {
                          unlockStatus = 'Completed ✓';
                        } else if (isUnlocked) {
                          // For unlocked lessons, check if unlocked today
                          if (wasUnlockedToday) {
                            unlockStatus = 'Unlocked! Available tomorrow';
                          } else {
                            unlockStatus = 'Unlocked - Tap to start';
                          }
                        } else {
                          // Not unlocked - show message to complete previous lessons
                          unlockStatus = 'Complete previous lessons to unlock';
                        }
                        
                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          child: _buildLessonCard(
                            lesson: lesson,
                            title: lesson['title'] ?? 'Lesson',
                            description: lesson['description'] ?? '',
                            xp: (lesson['xp_reward'] as int?) ?? 150,
                            isCompleted: isCompleted,
                            isLocked: !canAccessToday,
                            unlockStatus: unlockStatus,
                            color: isNextLesson 
                                ? const Color(0xFF0052FF) // Highlight next lesson in blue
                                : (isUnlocked ? const Color(0xFF3B82F6) : Colors.grey),
                            icon: lesson['badge_emoji'] ?? '📚',
                            difficulty: lesson['difficulty'] ?? 'Beginner',
                            duration: '${lesson['duration'] ?? 5} min',
                            isNextLesson: isNextLesson, // Pass flag for highlighting
                            onTap: () async {
                              // Check if lesson is already completed today
                              if (isCompleted) {
                                final completedToday = await DatabaseService.isActionCompletedToday('lesson_$lessonId');
                                
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Row(
                                      children: [
                                        const Icon(Icons.check_circle_outline, color: Color(0xFF10B981), size: 20),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            completedToday
                                                ? 'Lesson completed today! Come back tomorrow to practice again'
                                                : 'Lesson completed! You can attempt it again anytime',
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
                                      side: const BorderSide(color: Color(0xFF10B981), width: 1.5),
                                    ),
                                    margin: const EdgeInsets.all(16),
                                    duration: const Duration(seconds: 2),
                                  ),
                                );
                                return;
                              }
                              
                              // Check if lesson can be accessed today (Duolingo-style)
                              final dailyLessonService = Provider.of<DailyLessonService>(context, listen: false);
                              if (!dailyLessonService.canAccessLessonToday(lessonId)) {
                                // Lesson is either not unlocked OR was unlocked today
                                if (dailyLessonService.isLessonUnlocked(lessonId)) {
                                  // Lesson was unlocked today - show message
                                  _showUnlockedBanner(context);
                                } else {
                                  // Lesson not unlocked yet
                                  _showLockedBanner(context);
                                }
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
    bool isNextLesson = false,
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
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isNextLesson
                ? const Color(0xFF0052FF) // Highlight next lesson with blue border
                : isCompleted
                    ? const Color(0xFF10B981) // Subtle green border for completed
                    : !isLocked
                        ? const Color(0xFF0052FF) // Blue border for unlocked
                        : const Color(0xFFE5E7EB), // Grey for locked
            width: isNextLesson ? 3 : (isCompleted ? 2 : !isLocked ? 1.5 : 1), // Thicker border for next lesson
          ),
          boxShadow: isNextLesson ? [
            BoxShadow(
              color: const Color(0xFF0052FF).withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ] : [
            BoxShadow(
              color: Colors.black.withOpacity(isCompleted ? 0.04 : !isLocked ? 0.02 : 0.01),
              blurRadius: 8,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Completion indicator - Professional style
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isCompleted
                    ? const Color(0xFF10B981) // Subtle green for completed
                    : !isLocked
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
                    : !isLocked
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
                    ? const Icon(Icons.check_circle, color: Colors.white, size: 24)
                    : isLocked 
                        ? const Icon(Icons.lock_outlined, color: Color(0xFF9CA3AF), size: 20)
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
                          ? const Color(0xFF9CA3AF)
                          : const Color(0xFF111827),
                      height: 1.3,
                      letterSpacing: -0.1,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    description,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: isLocked ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
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
                      child: Row(
                        children: [
                          if (isNextLesson) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0052FF).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: const Color(0xFF0052FF),
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                'NEXT',
                                style: GoogleFonts.inter(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF0052FF),
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                          ],
                          // Show unlocked badge for unlocked lessons (not completed, not locked)
                          if (!isLocked && !isCompleted && unlockStatus.contains('Unlocked')) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0052FF).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: const Color(0xFF0052FF),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.lock_open, color: Color(0xFF0052FF), size: 10),
                                  const SizedBox(width: 3),
                                  Text(
                                    'UNLOCKED',
                                    style: GoogleFonts.inter(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFF0052FF),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 6),
                          ],
                          Text(
                            unlockStatus,
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: isNextLesson
                                  ? const Color(0xFF0052FF)
                                  : isLocked 
                                      ? const Color(0xFFF59E0B)
                                      : isCompleted
                                          ? const Color(0xFF10B981)
                                          : const Color(0xFF0052FF),
                            ),
                          ),
                        ],
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
                        color: const Color(0xFF10B981),
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF10B981).withOpacity(0.2),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
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
        padding: const EdgeInsets.all(16),
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
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
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
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'View Learning Tree',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF111827),
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'See all planned lessons and your progress',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: const Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              color: Color(0xFF6B7280),
              size: 18,
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
