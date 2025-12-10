import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../services/gamification_service.dart';
import '../../services/database_service.dart';
import '../../services/user_progress_service.dart';

class LessonScreen extends StatefulWidget {
  final Map<String, dynamic> lesson;
  
  const LessonScreen({Key? key, required this.lesson}) : super(key: key);

  @override
  State<LessonScreen> createState() => _LessonScreenState();
}

class _LessonScreenState extends State<LessonScreen> {
  int currentStep = 0;
  bool isCompleted = false;

  @override
  void initState() {
    super.initState();
    // Track screen visit and learning progress
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final lessonId = widget.lesson['id']?.toString() ?? 'unknown';
      UserProgressService().trackScreenVisit(
        screenName: 'LessonScreen',
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
          'Trading Basics',
          style: GoogleFonts.poppins(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          _buildHeader(),
          _buildTabs(),
          Expanded(
            child: _buildContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.lesson['title'] ?? 'Stock Market Basics',
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${currentStep + 1} of ${widget.lesson['steps']?.length ?? 1} lessons',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabs() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _buildTab('Lessons', true),
          _buildTab('Tests', false),
          _buildTab('Discuss', false),
        ],
      ),
    );
  }

  Widget _buildTab(String label, bool isActive) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isActive ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            color: isActive ? Colors.black : Colors.grey[600],
            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    final steps = widget.lesson['steps'] as List<dynamic>? ?? [];
    if (currentStep >= steps.length) {
      return _buildCompletionScreen();
    }
    
    final step = steps[currentStep];
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildLessonCard(step),
          const SizedBox(height: 20),
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildLessonCard(Map<String, dynamic> step) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildIllustration(step),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  step['title'] ?? 'Lesson Content',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  step['content'] ?? 'Learn about trading basics...',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: Colors.grey[700],
                    height: 1.5,
                  ),
                ),
                if (step['example'] != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Example:',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[800],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          step['example'],
                          style: GoogleFonts.poppins(
                            color: Colors.blue[700],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIllustration(Map<String, dynamic> step) {
    return Container(
      height: 200,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _getStepIcon(step['type'] ?? 'basic'),
              size: 60,
              color: Colors.blue[400],
            ),
            const SizedBox(height: 12),
            Text(
              step['iconText'] ?? 'Learn Trading',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.blue[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getStepIcon(String type) {
    switch (type) {
      case 'trading':
        return Icons.trending_up;
      case 'risk':
        return Icons.shield;
      case 'analysis':
        return Icons.analytics;
      case 'news':
        return Icons.newspaper;
      default:
        return Icons.school;
    }
  }

  Widget _buildActionButtons() {
    final steps = widget.lesson['steps'] as List<dynamic>? ?? [];
    final isLastStep = currentStep >= steps.length - 1;
    
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () async {
              if (isLastStep) {
                // Complete lesson - save to database and award XP
                try {
                  final gamification = Provider.of<GamificationService>(context, listen: false);
                  final xpAmount = widget.lesson['xp'] as int? ?? 50;
                  gamification.addXP(xpAmount, 'lesson_complete');
                  
                  // Save lesson completion
                  final lessonId = widget.lesson['id']?.toString() ?? 'lesson_${widget.lesson['title']}';
                  await DatabaseService.saveCompletedAction('lesson_$lessonId');
                  
                  if (mounted) {
                    setState(() {
                      isCompleted = true;
                    });
                  }
                } catch (e) {
                  print('Error completing lesson: $e');
                  if (mounted) {
                    setState(() {
                      isCompleted = true;
                    });
                  }
                }
              } else {
                setState(() {
                  currentStep++;
                });
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2C2C54),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              isLastStep ? 'Complete Lesson' : 'Next Step',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ),
        if (!isLastStep) ...[
          const SizedBox(height: 12),
          TextButton(
            onPressed: () {
              setState(() {
                currentStep++;
              });
            },
            child: Text(
              'Skip to Quiz',
              style: GoogleFonts.poppins(
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildCompletionScreen() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.check_circle,
            size: 80,
            color: Colors.green[400],
          ),
          const SizedBox(height: 20),
          Text(
            'Lesson Completed!',
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Great job! You\'ve learned the basics of trading.',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 30),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => QuizScreen(lesson: widget.lesson),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Take Quiz',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class QuizScreen extends StatefulWidget {
  final Map<String, dynamic> lesson;
  
  const QuizScreen({Key? key, required this.lesson}) : super(key: key);

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  int currentQuestion = 0;
  int? selectedAnswer;
  int score = 0;
  bool showResult = false;

  @override
  Widget build(BuildContext context) {
    final questions = widget.lesson['quiz'] as List<dynamic>? ?? [];
    if (currentQuestion >= questions.length) {
      return _buildQuizComplete();
    }
    
    final question = questions[currentQuestion];
    
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
          '${currentQuestion + 1} of ${questions.length}',
          style: GoogleFonts.poppins(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          _buildQuestion(question),
          _buildAnswerOptions(question),
          const Spacer(),
          _buildContinueButton(question),
        ],
      ),
    );
  }

  Widget _buildQuestion(Map<String, dynamic> question) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
                Text(
                  question['question'] ?? 'What is the correct answer?',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
          const SizedBox(height: 20),
          Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.quiz,
                    size: 60,
                    color: Colors.blue[400],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Trading Quiz',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.blue[600],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnswerOptions(Map<String, dynamic> question) {
    final options = question['options'] as List<dynamic>? ?? [];
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: options.asMap().entries.map((entry) {
          final index = entry.key;
          final option = entry.value;
          final isSelected = selectedAnswer == index;
          final isCorrect = showResult && index == question['correct'];
          final isWrong = showResult && isSelected && index != question['correct'];
          
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            child: GestureDetector(
              onTap: showResult ? null : () {
                setState(() {
                  selectedAnswer = index;
                });
              },
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isCorrect 
                      ? Colors.green[100]
                      : isWrong
                          ? Colors.red[100]
                          : isSelected
                              ? Colors.orange[100]
                              : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isCorrect
                        ? Colors.green
                        : isWrong
                            ? Colors.red
                            : isSelected
                                ? Colors.orange
                                : Colors.grey[300]!,
                    width: isSelected || isCorrect || isWrong ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: isCorrect
                            ? Colors.green
                            : isWrong
                                ? Colors.red
                                : isSelected
                                    ? Colors.orange
                                    : Colors.grey[300],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          String.fromCharCode(65 + index),
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        option,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          color: Colors.black,
                        ),
                      ),
                    ),
                    if (isCorrect)
                      Icon(Icons.check, color: Colors.green, size: 20),
                    if (isWrong)
                      Icon(Icons.close, color: Colors.red, size: 20),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildContinueButton(Map<String, dynamic> question) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: selectedAnswer != null ? () {
            if (showResult) {
              setState(() {
                currentQuestion++;
                selectedAnswer = null;
                showResult = false;
              });
            } else {
              setState(() {
                showResult = true;
                if (selectedAnswer == question['correct']) {
                  score++;
                }
              });
            }
          } : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: selectedAnswer != null 
                ? const Color(0xFF2C2C54)
                : Colors.grey[300],
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Text(
            showResult ? 'Continue' : 'Check Answer',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuizComplete() {
    final totalQuestions = widget.lesson['quiz']?.length ?? 1;
    final percentage = (score / totalQuestions * 100).round();
    
    // Save quiz completion when widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        final gamification = Provider.of<GamificationService>(context, listen: false);
        final quizXP = (percentage / 100 * 50).round(); // Up to 50 XP based on score
        gamification.addXP(quizXP, 'quiz_complete');
        
        // Save quiz completion
        final lessonId = widget.lesson['id']?.toString() ?? 'lesson_${widget.lesson['title']}';
        await DatabaseService.saveCompletedAction('quiz_$lessonId');
        await DatabaseService.saveCompletedAction('quiz_${lessonId}_score_$percentage');
      } catch (e) {
        print('Error saving quiz completion: $e');
      }
    });
    
    return Scaffold(
      backgroundColor: Colors.white,
      body: Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              percentage >= 70 ? Icons.emoji_events : Icons.school,
              size: 80,
              color: percentage >= 70 ? Colors.amber : Colors.blue,
            ),
            const SizedBox(height: 20),
            Text(
              percentage >= 70 ? 'Excellent!' : 'Good Job!',
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'You scored $score out of $totalQuestions',
              style: GoogleFonts.poppins(
                fontSize: 18,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '$percentage%',
              style: GoogleFonts.poppins(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: percentage >= 70 ? Colors.green : Colors.orange,
              ),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2C2C54),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Back to Lessons',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
