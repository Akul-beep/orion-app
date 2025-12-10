import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../data/interactive_lessons.dart';
import '../../data/learning_pathway.dart';
import '../../services/gamification_service.dart';
import '../../services/daily_lesson_service.dart';
import '../../services/database_service.dart';
import '../../services/user_progress_service.dart';

class InteractiveLessonScreen extends StatefulWidget {
  final String lessonId;
  
  const InteractiveLessonScreen({Key? key, required this.lessonId}) : super(key: key);

  @override
  State<InteractiveLessonScreen> createState() => _InteractiveLessonScreenState();
}

class _InteractiveLessonScreenState extends State<InteractiveLessonScreen>
    with TickerProviderStateMixin {
  Map<String, dynamic> lesson = {};
  int currentStep = 0;
  int totalXP = 0;
  int _score = 0; // Track correct answers
  int _totalQuestions = 0; // Track total questions
  bool isCompleted = false;
  bool _isLoadingLesson = true;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  Future<void> _loadLesson() async {
    setState(() => _isLoadingLesson = true);
    try {
      final loadedLesson = await InteractiveLessons.getLessonById(widget.lessonId);
      if (mounted) {
        setState(() {
          lesson = loadedLesson ?? {};
          _isLoadingLesson = false;
        });
      }
    } catch (e) {
      print('Error loading lesson: $e');
      if (mounted) {
        setState(() {
          lesson = {};
          _isLoadingLesson = false;
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _loadLesson();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(_animationController);
    _animationController.forward();
    
    // Track screen visit and learning progress
    WidgetsBinding.instance.addPostFrameCallback((_) {
      UserProgressService().trackScreenVisit(
        screenName: 'InteractiveLessonScreen',
        screenType: 'detail',
        metadata: {'lesson_id': widget.lessonId, 'lesson_title': lesson['title']},
      );
      
      UserProgressService().trackLearningProgress(
        lessonId: widget.lessonId,
        lessonName: lesson['title'] ?? 'Unknown',
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
    if (_isLoadingLesson) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0052FF)),
          ),
        ),
      );
    }
    
    if (lesson.isEmpty) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: const Text('Lesson Not Found'),
        ),
        body: const Center(
          child: Text('Lesson not found'),
        ),
      );
    }
    if (lesson.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Lesson Not Found')),
        body: const Center(child: Text('Lesson not found')),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          lesson['title'] ?? 'Interactive Lesson',
          style: GoogleFonts.poppins(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.orange[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${currentStep + 1}/${lesson['steps']?.length ?? 1}',
              style: GoogleFonts.poppins(
                color: Colors.orange[800],
                fontWeight: FontWeight.bold,
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
              child: _buildCurrentStep(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressBar() {
    final steps = lesson['steps'] as List<dynamic>? ?? [];
    final progress = (currentStep + 1) / steps.length;
    
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Progress',
                style: GoogleFonts.poppins(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
              Text(
                '${(progress * 100).round()}%',
                style: GoogleFonts.poppins(
                  color: Colors.orange[800],
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(Colors.orange[600]!),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentStep() {
    final steps = lesson['steps'] as List<dynamic>? ?? [];
    if (currentStep >= steps.length) {
      return _buildCompletionScreen();
    }
    
    final step = steps[currentStep];
    final stepType = step['type'] as String? ?? '';
    
    switch (stepType) {
      case 'intro':
        return _buildIntroStep(step);
      case 'multiple_choice':
        return _buildMultipleChoiceStep(step);
      case 'true_false':
        return _buildTrueFalseStep(step);
      case 'chart_analysis':
        return _buildChartAnalysisStep(step);
      case 'simulation':
        return _buildSimulationStep(step);
      case 'scenario':
        return _buildScenarioStep(step);
      case 'calculation':
        return _buildCalculationStep(step);
      case 'summary':
        return _buildSummaryStep(step);
      default:
        return _buildIntroStep(step);
    }
  }

  Widget _buildIntroStep(Map<String, dynamic> step) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(60),
            ),
            child: Center(
              child: Text(
                step['icon'] ?? '📚',
                style: const TextStyle(fontSize: 48),
              ),
            ),
          ),
          const SizedBox(height: 32),
          Text(
            step['content'] ?? 'Ready to learn?',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            step['subtitle'] ?? 'Let\'s get started!',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 48),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _nextStep,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[600],
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Start Learning',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMultipleChoiceStep(Map<String, dynamic> step) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            step['question'] ?? 'What is the correct answer?',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 24),
          ...(step['options'] as List<dynamic>? ?? []).asMap().entries.map((entry) {
            final index = entry.key;
            final option = entry.value as String;
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              child: _buildOptionButton(option, index, step['correct'] as int? ?? 0),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildTrueFalseStep(Map<String, dynamic> step) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            step['question'] ?? 'True or False?',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              Expanded(
                child: _buildOptionButton('True', 0, step['correct'] == true ? 0 : 1),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildOptionButton('False', 1, step['correct'] == true ? 1 : 0),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChartAnalysisStep(Map<String, dynamic> step) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            step['question'] ?? 'Analyze this chart',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 24),
          Container(
            width: double.infinity,
            height: 200,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '📊 Chart Placeholder',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    step['chart_data'] ?? 'Chart data here',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          ...(step['options'] as List<dynamic>? ?? []).asMap().entries.map((entry) {
            final index = entry.key;
            final option = entry.value as String;
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              child: _buildOptionButton(option, index, step['correct'] as int? ?? 0),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildSimulationStep(Map<String, dynamic> step) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            step['title'] ?? 'Try it yourself!',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            step['scenario'] ?? 'Simulation scenario',
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 24),
          ...(step['options'] as List<dynamic>? ?? []).asMap().entries.map((entry) {
            final index = entry.key;
            final option = entry.value as Map<String, dynamic>;
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              child: _buildSimulationButton(option, index, step['correct'] as int? ?? 0),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildScenarioStep(Map<String, dynamic> step) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            step['title'] ?? 'Scenario',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            step['scenario'] ?? 'What would you do?',
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 24),
          ...(step['options'] as List<dynamic>? ?? []).asMap().entries.map((entry) {
            final index = entry.key;
            final option = entry.value as Map<String, dynamic>;
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              child: _buildScenarioButton(option, index, step['correct'] as int? ?? 0),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildCalculationStep(Map<String, dynamic> step) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            step['question'] ?? 'Calculate the answer',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 24),
          ...(step['options'] as List<dynamic>? ?? []).asMap().entries.map((entry) {
            final index = entry.key;
            final option = entry.value as String;
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              child: _buildOptionButton(option, index, step['correct'] as int? ?? 0),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildSummaryStep(Map<String, dynamic> step) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: Colors.green[50],
              borderRadius: BorderRadius.circular(60),
            ),
            child: Center(
              child: Text(
                '🎉',
                style: const TextStyle(fontSize: 48),
              ),
            ),
          ),
          const SizedBox(height: 32),
          Text(
            step['title'] ?? 'Congratulations!',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            step['subtitle'] ?? 'You completed the lesson!',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Concepts Learned:',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[800],
                  ),
                ),
                const SizedBox(height: 12),
                ...(step['concepts_learned'] as List<dynamic>? ?? []).map((concept) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.green[600], size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            concept.toString(),
                            style: GoogleFonts.poppins(
                              color: Colors.blue[700],
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _completeLesson,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[600],
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Continue Learning',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 18,
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
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.emoji_events,
            size: 80,
            color: Colors.amber[600],
          ),
          const SizedBox(height: 24),
          Text(
            'Lesson Complete!',
            style: GoogleFonts.poppins(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'You earned $totalXP XP!',
            style: GoogleFonts.poppins(
              fontSize: 18,
              color: Colors.orange[600],
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[600],
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Back to Lessons',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionButton(String text, int index, int correctIndex) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () => _handleAnswer(index, correctIndex),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.grey[300]!),
          ),
        ),
        child: Text(
          text,
          style: GoogleFonts.poppins(
            color: Colors.black,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildSimulationButton(Map<String, dynamic> option, int index, int correctIndex) {
    final action = option['action'] as String? ?? '';
    final icon = option['icon'] as String? ?? '📈';
    final color = option['color'] as String? ?? 'blue';
    
    Color buttonColor;
    switch (color) {
      case 'green':
        buttonColor = Colors.green[600]!;
        break;
      case 'red':
        buttonColor = Colors.red[600]!;
        break;
      default:
        buttonColor = Colors.blue[600]!;
    }
    
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () => _handleAnswer(index, correctIndex),
        style: ElevatedButton.styleFrom(
          backgroundColor: buttonColor,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(icon, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 8),
            Text(
              action,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScenarioButton(Map<String, dynamic> option, int index, int correctIndex) {
    final emotion = option['emotion'] as String? ?? '';
    final reason = option['reason'] as String? ?? '';
    
    return Container(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () => _handleAnswer(index, correctIndex),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          padding: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.grey[300]!),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              emotion,
              style: GoogleFonts.poppins(
                color: Colors.black,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              reason,
              style: GoogleFonts.poppins(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleAnswer(int selectedIndex, int correctIndex) {
    final steps = lesson['steps'] as List<dynamic>? ?? [];
    final step = steps[currentStep];
    final isCorrect = selectedIndex == correctIndex;
    final xp = step['xp'] as int? ?? 10;
    
    // Track total questions (only count question-type steps once)
    if (currentStep == 0 || _totalQuestions == 0) {
      _totalQuestions = steps.where((s) {
        final type = s['type'] as String?;
        return type == 'multiple_choice' || type == 'true_false' || 
               type == 'fill_blank' || type == 'match' || type == 'speak';
      }).length;
    }
    
    if (isCorrect) {
      _score++;
      totalXP += xp;
      _showFeedback('✅ Correct! +$xp XP', Colors.green);
    } else {
      _showFeedback('❌ Try again!', Colors.red);
    }
    
    // Show explanation if available
    if (step['explanation'] != null) {
      Future.delayed(const Duration(milliseconds: 1000), () {
        _showExplanation(step['explanation']);
      });
    } else {
      Future.delayed(const Duration(milliseconds: 1500), () {
        _nextStep();
      });
    }
  }

  void _showFeedback(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: color,
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _showExplanation(String explanation) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Explanation',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: Text(
          explanation,
          style: GoogleFonts.poppins(),
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
                color: Colors.blue[600],
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _nextStep() {
    setState(() {
      currentStep++;
    });
    _animationController.reset();
    _animationController.forward();
  }

  void _completeLesson() async {
    final gamificationService = Provider.of<GamificationService>(context, listen: false);
    final lessonId = lesson['id']?.toString() ?? 'interactive_lesson_${DateTime.now().millisecondsSinceEpoch}';
    
    // Check if lesson was already completed (for repeat/practice mode)
    final completedActions = await DatabaseService.getCompletedActions();
    final isRepeat = completedActions.contains('lesson_$lessonId') || 
                    completedActions.contains('lesson_${lessonId}_completed');
    
    // Calculate XP: Full XP for first completion, reduced for repeats (practice mode)
    final xpAmount = isRepeat 
        ? (totalXP * 0.15).round().clamp(1, 20) // 15% XP for repeats (practice), min 1, max 20
        : totalXP; // Full XP for first completion
    
    // Award XP (reduced for repeats to encourage practice without farming)
    if (xpAmount > 0) {
      gamificationService.addXP(xpAmount, isRepeat ? 'lesson_repeat' : 'lesson');
      print('${isRepeat ? "🔄 Practice mode" : "✅ First completion"}: Awarded $xpAmount XP (base: $totalXP)');
    }
    
    // Track lesson completion (badges are now awarded automatically based on achievements)
    if (!isRepeat) {
      // Check if lesson was completed perfectly (100% accuracy)
      final isPerfect = _score == _totalQuestions;
      gamificationService.trackLessonCompletion(isPerfect: isPerfect);
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
      isCompleted = true;
    });
    
    Navigator.pop(context);
  }
}



