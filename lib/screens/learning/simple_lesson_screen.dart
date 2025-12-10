import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../data/learning_pathway.dart';
import '../../services/gamification_service.dart';
import '../../services/daily_lesson_service.dart';
import '../../services/database_service.dart';
import '../../services/user_progress_service.dart';

class SimpleLessonScreen extends StatefulWidget {
  final Map<String, dynamic> lesson;

  const SimpleLessonScreen({Key? key, required this.lesson}) : super(key: key);

  @override
  State<SimpleLessonScreen> createState() => _SimpleLessonScreenState();
}

class _SimpleLessonScreenState extends State<SimpleLessonScreen>
    with TickerProviderStateMixin {
  int _currentStep = 0;
  int _score = 0;
  bool _isCompleted = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  final List<Map<String, dynamic>> _lessonSteps = [
    {
      'type': 'intro',
      'title': 'Welcome to the lesson!',
      'content': 'Let\'s learn something awesome!',
    },
    {
      'type': 'content',
      'title': 'What you\'ll learn',
      'content': 'In this lesson, you\'ll discover the key concepts that will help you make money trading stocks.',
    },
    {
      'type': 'quiz',
      'question': 'What is the golden rule of trading?',
      'options': ['Buy high, sell low', 'Buy low, sell high', 'Never trade'],
      'correct': 1,
      'explanation': 'Buy low, sell high is the golden rule! You want to buy stocks when they\'re cheap and sell when they\'re expensive.',
    },
    {
      'type': 'content',
      'title': 'Key Takeaway',
      'content': 'Remember: The goal is to buy stocks at a low price and sell them at a higher price to make a profit.',
    },
    {
      'type': 'quiz',
      'question': 'What happens when you buy a stock?',
      'options': ['You lend money to the company', 'You own a piece of the company', 'You become the CEO'],
      'correct': 1,
      'explanation': 'When you buy a stock, you become a part-owner of that company!',
    },
    {
      'type': 'summary',
      'title': 'Lesson Complete!',
      'content': 'Great job! You\'ve learned the basics. Keep practicing to become a successful trader.',
    },
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(_animationController);
    _animationController.forward();
    
    // Track screen visit and learning progress
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final lessonId = widget.lesson['id']?.toString() ?? 'unknown';
      UserProgressService().trackScreenVisit(
        screenName: 'SimpleLessonScreen',
        screenType: 'detail',
        metadata: {'lesson_id': lessonId, 'lesson_title': widget.lesson['title']},
      );
      
      UserProgressService().trackLearningProgress(
        lessonId: lessonId,
        lessonName: widget.lesson['title'] ?? 'Unknown',
        progressPercentage: 0,
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
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(Icons.arrow_back, color: Colors.black),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.lesson['title'],
          style: GoogleFonts.poppins(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: widget.lesson['color'].withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${widget.lesson['xp']} XP',
              style: GoogleFonts.poppins(
                color: widget.lesson['color'],
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
          children: [
            _buildProgressBar(),
            Expanded(
              child: _isCompleted ? _buildCompletionScreen() : _buildCurrentStep(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressBar() {
    final progress = (_currentStep + 1) / _lessonSteps.length;
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Step ${_currentStep + 1} of ${_lessonSteps.length}',
                style: GoogleFonts.poppins(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
              Text(
                '${(progress * 100).round()}% Complete',
                style: GoogleFonts.poppins(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(widget.lesson['color']),
            minHeight: 6,
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentStep() {
    final step = _lessonSteps[_currentStep];
    
    switch (step['type']) {
      case 'intro':
        return _buildIntroStep(step);
      case 'content':
        return _buildContentStep(step);
      case 'quiz':
        return _buildQuizStep(step);
      case 'summary':
        return _buildSummaryStep(step);
      default:
        return _buildContentStep(step);
    }
  }

  Widget _buildIntroStep(Map<String, dynamic> step) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: widget.lesson['color'].withOpacity(0.1),
              borderRadius: BorderRadius.circular(50),
            ),
            child: Icon(
              widget.lesson['icon'],
              color: widget.lesson['color'],
              size: 50,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            step['title'],
            style: GoogleFonts.poppins(
              color: Colors.black,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            step['content'],
            style: GoogleFonts.poppins(
              color: Colors.grey[600],
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _nextStep,
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.lesson['color'],
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Start Learning',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContentStep(Map<String, dynamic> step) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            step['title'],
            style: GoogleFonts.poppins(
              color: Colors.black,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: widget.lesson['color'].withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: widget.lesson['color'].withOpacity(0.3)),
            ),
            child: Text(
              step['content'],
              style: GoogleFonts.poppins(
                color: Colors.black,
                fontSize: 16,
                height: 1.5,
              ),
            ),
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _nextStep,
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.lesson['color'],
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Continue',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuizStep(Map<String, dynamic> step) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quiz Time!',
            style: GoogleFonts.poppins(
              color: Colors.black,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            step['question'],
            style: GoogleFonts.poppins(
              color: Colors.black,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 24),
          ...(step['options'] as List).asMap().entries.map((entry) {
            final index = entry.key;
            final option = entry.value;
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              child: Material(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                elevation: 2,
                child: InkWell(
                  onTap: () => _answerQuestion(index, step['correct']),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Text(
                              String.fromCharCode(65 + index), // A, B, C
                              style: GoogleFonts.poppins(
                                color: Colors.grey[600],
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            option,
                            style: GoogleFonts.poppins(
                              color: Colors.black,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildSummaryStep(Map<String, dynamic> step) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(50),
            ),
            child: const Icon(
              Icons.check_circle,
              color: Colors.green,
              size: 50,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            step['title'],
            style: GoogleFonts.poppins(
              color: Colors.black,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            step['content'],
            style: GoogleFonts.poppins(
              color: Colors.grey[600],
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.star, color: Colors.orange),
                const SizedBox(width: 8),
                Text(
                  'You earned ${widget.lesson['xp']} XP!',
                  style: GoogleFonts.poppins(
                    color: Colors.orange,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _completeLesson,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Complete Lesson',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompletionScreen() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(60),
            ),
            child: const Icon(
              Icons.celebration,
              color: Colors.green,
              size: 60,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Lesson Complete!',
            style: GoogleFonts.poppins(
              color: Colors.black,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            'Great job! You\'re one step closer to becoming a successful trader.',
            style: GoogleFonts.poppins(
              color: Colors.grey[600],
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildRewardItem(Icons.star, '${widget.lesson['xp']} XP', Colors.orange),
                    _buildRewardItem(Icons.trending_up, 'Progress', Colors.blue),
                    _buildRewardItem(Icons.emoji_events, 'Badge', Colors.purple),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Back to Lessons',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRewardItem(IconData icon, String text, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 8),
        Text(
          text,
          style: GoogleFonts.poppins(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  void _nextStep() {
    setState(() {
      _currentStep++;
    });
    _animationController.reset();
    _animationController.forward();
  }

  void _answerQuestion(int selectedIndex, int correctIndex) {
    final isCorrect = selectedIndex == correctIndex;
    if (isCorrect) {
      _score++;
    }

    // Show feedback
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isCorrect ? Icons.check_circle : Icons.cancel,
              color: isCorrect ? Colors.green : Colors.red,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              isCorrect ? 'Correct!' : 'Not quite right',
              style: GoogleFonts.poppins(
                color: Colors.black,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isCorrect ? 'Great job! +10 XP' : 'Keep learning!',
              style: GoogleFonts.poppins(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _nextStep();
            },
            child: Text(
              'Continue',
              style: GoogleFonts.poppins(
                color: Colors.blue,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _completeLesson() async {
    final gamification = Provider.of<GamificationService>(context, listen: false);
    final lessonId = widget.lesson['id']?.toString() ?? 'lesson_${DateTime.now().millisecondsSinceEpoch}';
    
    // Check if lesson was already completed (for repeat/practice mode)
    final completedActions = await DatabaseService.getCompletedActions();
    final isRepeat = completedActions.contains('lesson_$lessonId') || 
                    completedActions.contains('lesson_${lessonId}_completed');
    
    // Calculate XP: Full XP for first completion, reduced for repeats (practice mode)
    final baseXP = widget.lesson['xp'] as int? ?? 50;
    final xpAmount = isRepeat 
        ? (baseXP * 0.15).round().clamp(1, 20) // 15% XP for repeats (practice), min 1, max 20
        : baseXP; // Full XP for first completion
    
    // Award XP (reduced for repeats to encourage practice without farming)
    if (xpAmount > 0) {
      gamification.addXP(xpAmount, isRepeat ? 'lesson_repeat' : 'lesson');
      print('${isRepeat ? "🔄 Practice mode" : "✅ First completion"}: Awarded $xpAmount XP (base: $baseXP)');
    }
    
    // Save lesson completion to database
    await DatabaseService.saveCompletedAction('lesson_$lessonId');
    await DatabaseService.saveCompletedAction('lesson_${lessonId}_completed');
    
    // Unlock next lesson when current lesson is completed (only on first completion)
    if (!isRepeat) {
      try {
        final dailyLessonService = Provider.of<DailyLessonService>(context, listen: false);
        await dailyLessonService.unlockNextLessonAfterCompletion(lessonId);
      } catch (e) {
        print('Error unlocking next lesson: $e');
      }
    }
    
    setState(() {
      _isCompleted = true;
    });
  }
}


