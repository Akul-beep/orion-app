import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../data/micro_learning_plan.dart';
import '../../data/trading_lessons.dart';
import '../../services/gamification_service.dart';
import '../../services/database_service.dart';
import '../../services/user_progress_service.dart';
import 'lesson_screen.dart';

class MicroLearningScreen extends StatefulWidget {
  const MicroLearningScreen({Key? key}) : super(key: key);

  @override
  State<MicroLearningScreen> createState() => _MicroLearningScreenState();
}

class _MicroLearningScreenState extends State<MicroLearningScreen>
    with TickerProviderStateMixin {
  int currentDay = 1;
  int streak = 0;
  List<String> badges = [];
  bool isLessonCompleted = false;
  bool isMindsetBreakCompleted = false;
  bool isJournalCompleted = false;

  late AnimationController _animationController;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    // Track screen visit
    WidgetsBinding.instance.addPostFrameCallback((_) {
      UserProgressService().trackScreenVisit(
        screenName: 'MicroLearningScreen',
        screenType: 'main',
        metadata: {'section': 'micro_learning'},
      );
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Map<String, dynamic> get currentDayData => MicroLearningPlan.getDay(currentDay);

  void _completeLesson() async {
    // Add XP to database via GamificationService
    final gamification = Provider.of<GamificationService>(context, listen: false);
    final lessonId = 'micro_lesson_day_$currentDay';
    
    // Check if lesson was already completed (for repeat/practice mode)
    final completedActions = await DatabaseService.getCompletedActions();
    final isRepeat = completedActions.contains(lessonId);
    
    // Calculate XP: Full XP for first completion, reduced for repeats
    final baseXP = currentDayData['xp_reward'] as int;
    final xpAmount = isRepeat 
        ? (baseXP * 0.15).round().clamp(1, 20) // 15% XP for repeats (practice), min 1, max 20
        : baseXP; // Full XP for first completion
    
    // Award XP (reduced for repeats to encourage practice without farming)
    if (xpAmount > 0) {
      gamification.addXP(xpAmount, isRepeat ? 'lesson_repeat' : 'micro_lesson');
      print('${isRepeat ? "🔄 Practice mode" : "✅ First completion"}: Awarded $xpAmount XP (base: $baseXP)');
    }
    
    // Save lesson completion to database
    await DatabaseService.saveCompletedAction(lessonId);
    
    setState(() {
      isLessonCompleted = true;
      _animationController.forward();
    });
  }

  void _completeMindsetBreak() {
    // Add XP to database via GamificationService
    final gamification = Provider.of<GamificationService>(context, listen: false);
    gamification.addXP(50, 'mindset_break');
    
    setState(() {
      isMindsetBreakCompleted = true;
    });
  }

  void _completeJournal() {
    // Add XP to database via GamificationService
    final gamification = Provider.of<GamificationService>(context, listen: false);
    gamification.addXP(25, 'journal');
    
    setState(() {
      isJournalCompleted = true;
    });
  }

  void _nextDay() {
    if (currentDay < 29) {
      setState(() {
        currentDay++;
        isLessonCompleted = false;
        isMindsetBreakCompleted = false;
        isJournalCompleted = false;
        streak++;
        _animationController.reset();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Day $currentDay: ${currentDayData['title']}',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFF2C2C54),
        elevation: 0,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            child: Row(
              children: [
                Icon(Icons.local_fire_department, color: Colors.orange),
                const SizedBox(width: 4),
                Text(
                  '$streak',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 24),
              _buildProgressBar(),
              const SizedBox(height: 24),
              _buildLessonCard(),
              const SizedBox(height: 16),
              if (currentDayData['mindset_break'] != null) ...[
                _buildMindsetBreakCard(),
                const SizedBox(height: 16),
              ],
              _buildJournalCard(),
              const SizedBox(height: 24),
              _buildActionButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2C2C54), Color(0xFF40407A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.school, color: Colors.white, size: 24),
              const SizedBox(width: 12),
              Text(
                'Micro-Learning',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            currentDayData['goal'] ?? '',
            style: GoogleFonts.poppins(
              color: Colors.white70,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.timer, color: Colors.white60, size: 16),
              const SizedBox(width: 4),
              Text(
                '${currentDayData['duration']} minutes',
                style: GoogleFonts.poppins(
                  color: Colors.white60,
                  fontSize: 14,
                ),
              ),
              const SizedBox(width: 16),
              Icon(Icons.star, color: Colors.yellow, size: 16),
              const SizedBox(width: 4),
              Text(
                '${currentDayData['xp_reward']} XP',
                style: GoogleFonts.poppins(
                  color: Colors.yellow,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Progress',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Consumer<GamificationService>(
                builder: (context, gamification, child) {
                  return Text(
                    '${gamification.totalXP} XP',
                    style: GoogleFonts.poppins(
                      color: Colors.yellow,
                      fontWeight: FontWeight.bold,
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          AnimatedBuilder(
            animation: _progressAnimation,
            builder: (context, child) {
              return LinearProgressIndicator(
                value: _progressAnimation.value,
                backgroundColor: Colors.white.withOpacity(0.2),
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
              );
            },
          ),
          const SizedBox(height: 8),
          Text(
            'Day $currentDay of 29',
            style: GoogleFonts.poppins(
              color: Colors.white70,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLessonCard() {
    final lessons = TradingLessons.getAllLessons();
    final currentLesson = lessons.isNotEmpty ? lessons[currentDay % lessons.length] : null;
    
    if (currentLesson == null) {
      return Container();
    }
    
    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.school, color: Colors.blue[600], size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        currentLesson['title'] ?? 'Trading Lesson',
                        style: GoogleFonts.poppins(
                          color: Colors.black,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        currentLesson['description'] ?? 'Learn trading basics',
                        style: GoogleFonts.poppins(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isLessonCompleted)
                  Icon(Icons.check_circle, color: Colors.green, size: 24),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildInfoChip(Icons.timer, currentLesson['duration'] ?? '5 min'),
                const SizedBox(width: 8),
                _buildInfoChip(Icons.signal_cellular_alt, currentLesson['difficulty'] ?? 'Beginner'),
              ],
            ),
            const SizedBox(height: 16),
            if (!isLessonCompleted)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => LessonScreen(lesson: currentLesson),
                      ),
                    ).then((_) {
                      _completeLesson();
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2C2C54),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'Start Lesson',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.grey[600]),
          const SizedBox(width: 4),
          Text(
            text,
            style: GoogleFonts.poppins(
              color: Colors.grey[600],
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLessonStep(Map<String, dynamic> step) {
    final lesson = currentDayData['micro_lesson'] as List<dynamic>? ?? [];
    final stepIndex = lesson.indexOf(step);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Text(
                '${stepIndex + 1}',
                style: GoogleFonts.poppins(
                  color: Colors.blue,
                  fontWeight: FontWeight.bold,
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
                  step['action'] ?? '',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  step['description'] ?? '',
                  style: GoogleFonts.poppins(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${step['time']} minutes',
                  style: GoogleFonts.poppins(
                    color: Colors.blue,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMindsetBreakCard() {
    final mindsetBreak = currentDayData['mindset_break'] as Map<String, dynamic>?;
    if (mindsetBreak == null) return const SizedBox.shrink();

    return Card(
      color: const Color(0xFF40407A),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.psychology, color: Colors.purple, size: 24),
                const SizedBox(width: 12),
                Text(
                  'Mindset Break',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                if (isMindsetBreakCompleted)
                  Icon(Icons.check_circle, color: Colors.green, size: 24),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              mindsetBreak['content'] ?? '',
              style: GoogleFonts.poppins(
                color: Colors.white70,
                fontSize: 14,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.purple.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.touch_app, color: Colors.purple, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      mindsetBreak['action'] ?? '',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (!isMindsetBreakCompleted)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _completeMindsetBreak,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'Complete Mindset Break (+50 XP)',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildJournalCard() {
    return Card(
      color: const Color(0xFF2C2C54),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.edit_note, color: Colors.orange, size: 24),
                const SizedBox(width: 12),
                Text(
                  'Daily Journal',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                if (isJournalCompleted)
                  Icon(Icons.check_circle, color: Colors.green, size: 24),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              currentDayData['journal_prompt'] ?? '',
              style: GoogleFonts.poppins(
                color: Colors.white70,
                fontSize: 14,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 16),
            if (!isJournalCompleted)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _completeJournal,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'Complete Journal (+25 XP)',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    final allCompleted = isLessonCompleted && 
        (currentDayData['mindset_break'] == null || isMindsetBreakCompleted) &&
        isJournalCompleted;

    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: allCompleted ? _nextDay : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: allCompleted ? Colors.green : Colors.grey,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              currentDay < 29 ? 'Next Day' : 'Complete Course',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
