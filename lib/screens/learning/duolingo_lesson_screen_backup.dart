import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../services/gamification_service.dart';
import '../../services/database_service.dart';
import '../../services/user_progress_service.dart';
import '../../services/daily_goals_service.dart';
import '../../services/notification_manager.dart';
import '../../services/daily_lesson_service.dart';
import '../../data/interactive_lessons.dart';
import '../../data/learning_pathway.dart';
import '../../data/trading_lessons_data.dart';
import 'simple_action_screen.dart';

class DuolingoLessonScreen extends StatefulWidget {
  final String lessonId; // Changed to String

  const DuolingoLessonScreen({
    Key? key,
    required this.lessonId,
  }) : super(key: key);

  @override
  State<DuolingoLessonScreen> createState() => _DuolingoLessonScreenState();
}

class _DuolingoLessonScreenState extends State<DuolingoLessonScreen>
    with TickerProviderStateMixin {
  late Map<String, dynamic> _lesson;
  List<Map<String, dynamic>> _questions = [];
  int _currentQuestion = 0;
  int _correctAnswers = 0;
  int _hearts = 5;
  bool _isCompleted = false;
  bool _showFeedback = false;
  bool _isCorrect = false;
  int? _selectedAnswer;
  
  // Matching quiz variables
  int? _selectedTermIndex;
  Set<int> _matchedPairs = {};
  bool _isRecording = false;
  
  // Randomized answer tracking for multiple choice questions
  Map<int, Map<String, dynamic>> _randomizedQuestions = {}; // Maps question index to randomized data

  late AnimationController _animationController;
  late AnimationController _feedbackController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    // Use new InteractiveLessons (string IDs)
    _lesson = InteractiveLessons.getLessonById(widget.lessonId) ?? {};
    // Extract questions from steps
    final steps = _lesson['steps'] as List<dynamic>? ?? [];
    _questions = steps.where((step) {
      final type = step['type'] as String?;
      return type == 'multiple_choice' || 
             type == 'true_false' || 
             type == 'fill_blank' || 
             type == 'match' || 
             type == 'speak';
    }).map((step) => Map<String, dynamic>.from(step)).toList();
    
    // Randomize multiple choice answers for each question
    _randomizeAnswers();
    
    // If no questions found, try old system as fallback (for backwards compatibility)
    if (_questions.isEmpty) {
      final lessonIdInt = int.tryParse(widget.lessonId);
      if (lessonIdInt != null) {
        _lesson = TradingLessonsData.getLessonById(lessonIdInt) ?? {};
        _questions = List<Map<String, dynamic>>.from(_lesson['questions'] ?? []);
      }
    }
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _feedbackController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    _animationController.forward();
    
    // Track screen visit and learning progress
    WidgetsBinding.instance.addPostFrameCallback((_) {
      UserProgressService().trackScreenVisit(
        screenName: 'DuolingoLessonScreen',
        screenType: 'detail',
        metadata: {'lesson_id': widget.lessonId, 'lesson_title': _lesson['title']},
      );
      
      UserProgressService().trackLearningProgress(
        lessonId: widget.lessonId.toString(),
        lessonName: _lesson['title'] ?? 'Unknown',
        progressPercentage: 0,
        timeSpentSeconds: 0,
      );
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _feedbackController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF58CC02),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: _isCompleted ? _buildCompletionScreen() : _buildQuestion(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          // Hearts
          Row(
            children: List.generate(5, (index) {
              return Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Icon(
                  Icons.favorite,
                  color: index < _hearts ? Colors.red : Colors.grey[300],
                  size: 20,
                ),
              );
            }),
          ),
          const Spacer(),
          // Progress
          Text(
            '${_currentQuestion + 1}/${_questions.length}',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 16),
          // Close button
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.close, color: Colors.white, size: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestion() {
    final question = _questions[_currentQuestion];
    
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Opacity(
            opacity: _fadeAnimation.value,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _buildProgressBar(),
                  const SizedBox(height: 24),
                  Expanded(
                    child: _buildQuestionContent(question),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildProgressBar() {
    final progress = (_currentQuestion + 1) / _questions.length;
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Question ${_currentQuestion + 1}',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            Text(
              '${(progress * 100).round()}%',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: progress,
          backgroundColor: Colors.grey[200],
          valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF58CC02)),
          minHeight: 6,
        ),
      ],
    );
  }

  Widget _buildQuestionContent(Map<String, dynamic> question) {
    switch (question['type']) {
      case 'multiple_choice':
        return _buildMultipleChoice(question);
      case 'true_false':
        return _buildTrueFalse(question);
      case 'fill_blank':
        return _buildFillBlank(question);
      case 'match':
        return _buildMatch(question);
      case 'speak':
        return _buildSpeak(question);
      default:
        return _buildMultipleChoice(question);
    }
  }

  Widget _buildMultipleChoice(Map<String, dynamic> question) {
    // Get randomized version if it exists, otherwise use original
    final questionIndex = _currentQuestion;
    final randomizedData = _randomizedQuestions[questionIndex];
    final List<dynamic> options = randomizedData?['options'] as List<dynamic>? ?? (question['options'] as List);
    final int correctIndex = randomizedData?['correct'] as int? ?? (question['correct'] as int);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          question['question'],
          style: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 32),
        Expanded(
          child: Column(
            children: options.asMap().entries.map((entry) {
              final index = entry.key;
              final option = entry.value;
              final isSelected = _selectedAnswer == index;
              final isCorrect = index == correctIndex;
              
              Color backgroundColor = Colors.white;
              Color borderColor = Colors.grey[300]!;
              
              if (_showFeedback) {
                if (isCorrect) {
                  backgroundColor = Colors.green.withOpacity(0.1);
                  borderColor = Colors.green;
                } else if (isSelected && !isCorrect) {
                  backgroundColor = Colors.red.withOpacity(0.1);
                  borderColor = Colors.red;
                }
              } else if (isSelected) {
                backgroundColor = const Color(0xFF58CC02).withOpacity(0.1);
                borderColor = const Color(0xFF58CC02);
              }

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                child: Material(
                  color: backgroundColor,
                  borderRadius: BorderRadius.circular(16),
                  elevation: _showFeedback ? 0 : 2,
                  child: InkWell(
                    onTap: _showFeedback ? null : () => _selectAnswer(index),
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: borderColor, width: 2),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: borderColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Center(
                              child: Text(
                                String.fromCharCode(65 + index),
                                style: GoogleFonts.poppins(
                                  color: borderColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              option,
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                color: Colors.black,
                              ),
                            ),
                          ),
                          if (_showFeedback && isCorrect)
                            const Icon(Icons.check_circle, color: Colors.green, size: 24),
                          if (_showFeedback && isSelected && !isCorrect)
                            const Icon(Icons.cancel, color: Colors.red, size: 24),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        if (_showFeedback) _buildFeedback(question),
      ],
    );
  }

  Widget _buildTrueFalse(Map<String, dynamic> question) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          question['question'],
          style: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 32),
        Expanded(
          child: Column(
            children: [
              Expanded(
                child: _buildTrueFalseButton('True', true, question['correct']),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: _buildTrueFalseButton('False', false, question['correct']),
              ),
            ],
          ),
        ),
        if (_showFeedback) _buildFeedback(question),
      ],
    );
  }

  Widget _buildTrueFalseButton(String label, bool value, bool correct) {
    final buttonIndex = value ? 1 : 0;
    final isSelected = _selectedAnswer == buttonIndex;
    final isCorrect = value == correct;
    
    Color backgroundColor = Colors.white;
    Color borderColor = Colors.grey[300]!;
    
    if (_showFeedback) {
      if (isCorrect) {
        backgroundColor = Colors.green.withOpacity(0.1);
        borderColor = Colors.green;
      } else if (isSelected && !isCorrect) {
        backgroundColor = Colors.red.withOpacity(0.1);
        borderColor = Colors.red;
      }
    } else if (isSelected) {
      backgroundColor = const Color(0xFF58CC02).withOpacity(0.1);
      borderColor = const Color(0xFF58CC02);
    }

    return Container(
      width: double.infinity,
      child: Material(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
        elevation: _showFeedback ? 0 : 2,
        child: InkWell(
          onTap: _showFeedback ? null : () => _selectAnswer(buttonIndex),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: borderColor, width: 2),
            ),
            child: Center(
              child: Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFillBlank(Map<String, dynamic> question) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          question['question'],
          style: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 32),
        Expanded(
          child: Column(
            children: (question['options'] as List).asMap().entries.map((entry) {
              final index = entry.key;
              final option = entry.value;
              final isSelected = _selectedAnswer == index;
              final isCorrect = index == question['correct'];
              
              Color backgroundColor = Colors.white;
              Color borderColor = Colors.grey[300]!;
              
              if (_showFeedback) {
                if (isCorrect) {
                  backgroundColor = Colors.green.withOpacity(0.1);
                  borderColor = Colors.green;
                } else if (isSelected && !isCorrect) {
                  backgroundColor = Colors.red.withOpacity(0.1);
                  borderColor = Colors.red;
                }
              } else if (isSelected) {
                backgroundColor = const Color(0xFF58CC02).withOpacity(0.1);
                borderColor = const Color(0xFF58CC02);
              }

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                child: Material(
                  color: backgroundColor,
                  borderRadius: BorderRadius.circular(16),
                  elevation: _showFeedback ? 0 : 2,
                  child: InkWell(
                    onTap: _showFeedback ? null : () => _selectAnswer(index),
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: borderColor, width: 2),
                      ),
                      child: Center(
                        child: Text(
                          option,
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        if (_showFeedback) _buildFeedback(question),
      ],
    );
  }

  Widget _buildMatch(Map<String, dynamic> question) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          question['question'],
          style: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Drag the terms to match with their definitions',
          style: GoogleFonts.poppins(
            fontSize: 16,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 24),
        Expanded(
          child: _buildInteractiveMatching(List<Map<String, dynamic>>.from(question['pairs'])),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _nextQuestion,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF58CC02),
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
    );
  }

  Widget _buildInteractiveMatching(List<Map<String, dynamic>> pairs) {
    return Column(
      children: [
        // Matching Instructions
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue[200]!),
          ),
          child: Row(
            children: [
              Icon(Icons.touch_app, color: Colors.blue[600], size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Match the terms with their definitions by tapping them in order!',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.blue[700],
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Terms and Definitions Grid
        Expanded(
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 2.5,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: pairs.length * 2, // Terms + Definitions
            itemBuilder: (context, index) {
              final isTerm = index < pairs.length;
              final pairIndex = isTerm ? index : index - pairs.length;
              final pair = pairs[pairIndex];
              final content = isTerm ? pair['term'] : pair['definition'];
              final isSelected = _selectedTermIndex == index;
              final isMatched = _matchedPairs.contains(index);
              
              return _matchedPairs.contains(index)
                  ? Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green[100],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.green, width: 2),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle, color: Colors.green[600], size: 20),
                          const SizedBox(height: 4),
                          Text(
                            content,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
                    )
                  : Draggable<int>(
                      data: index,
                      feedback: Material(
                        elevation: 4,
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isTerm ? Colors.blue[100] : Colors.purple[100],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: isTerm ? Colors.blue : Colors.purple, width: 2),
                          ),
                          child: Text(
                            content,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ),
                      childWhenDragging: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[400]!, width: 2),
                        ),
                        child: Opacity(
                          opacity: 0.5,
                          child: Text(
                            content,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ),
                      child: DragTarget<int>(
                        onWillAccept: (data) => data != null,
                        onAccept: (draggedIndex) {
                          _handleMatchingDrop(draggedIndex, index, isTerm);
                        },
                        builder: (context, candidateData, rejectedData) {
                          final isHighlighted = candidateData.isNotEmpty;
                          return Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isHighlighted
                                  ? (isTerm ? Colors.blue[50] : Colors.purple[50])
                                  : isSelected
                                      ? Colors.orange[100]
                                      : Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isHighlighted
                                    ? (isTerm ? Colors.blue : Colors.purple)
                                    : isSelected
                                        ? Colors.orange
                                        : Colors.grey[300]!,
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.1),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (isSelected)
                                  Icon(
                                    Icons.touch_app,
                                    color: Colors.orange[600],
                                    size: 20,
                                  ),
                                if (isSelected) const SizedBox(height: 4),
                                Text(
                                  content,
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    );
            },
          ),
        ),
        const SizedBox(height: 16),
        // Progress and Status
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Row(
            children: [
              Icon(Icons.analytics, color: Colors.grey[600], size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Progress: ${_matchedPairs.length ~/ 2}/${pairs.length} pairs matched',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSpeak(Map<String, dynamic> question) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          question['question'],
          style: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 32),
        Expanded(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: _isRecording ? null : _simulateSpeechRecognition,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: _isRecording 
                        ? Colors.red.withOpacity(0.1)
                        : const Color(0xFF58CC02).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(60),
                      border: Border.all(
                        color: _isRecording ? Colors.red : const Color(0xFF58CC02), 
                        width: 3,
                      ),
                    ),
                    child: _isRecording
                      ? const Icon(
                          Icons.stop,
                          color: Colors.red,
                          size: 60,
                        )
                      : const Icon(
                          Icons.mic,
                          color: Color(0xFF58CC02),
                          size: 60,
                        ),
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Text(
                    question['text'],
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Tap the microphone and say it!',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '🎤 Simulated: Tap to "speak"',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.blue[700],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _nextQuestion,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF58CC02),
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
    );
  }

  Widget _buildFeedback(Map<String, dynamic> question) {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _isCorrect ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _isCorrect ? Colors.green : Colors.red,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            _isCorrect ? Icons.check_circle : Icons.cancel,
            color: _isCorrect ? Colors.green : Colors.red,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _isCorrect ? 'Correct! ✅' : 'Not quite right',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: _isCorrect ? Colors.green : Colors.red,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompletionScreen() {
    return FutureBuilder<bool>(
      future: _checkIfRepeat(widget.lessonId.toString()),
      builder: (context, snapshot) {
        final isRepeatAttempt = snapshot.data ?? false;
        final xpReward = (_lesson['xp_reward'] as int?) ?? (_lesson['xp'] as int?) ?? 150;
        
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: const Color(0xFF58CC02).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(60),
                ),
                child: const Icon(
                  Icons.celebration,
                  color: Color(0xFF58CC02),
                  size: 60,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Lesson Complete!',
                style: GoogleFonts.poppins(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                isRepeatAttempt 
                    ? 'Great job! Keep practicing!'
                    : 'Great job! You earned $xpReward 💎 gems!',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  color: Colors.grey[600],
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
                    if (!isRepeatAttempt) _buildRewardItem(Icons.diamond, '${xpReward} 💎', const Color(0xFF3B82F6)), // Gems - blue
                    _buildRewardItem(Icons.trending_up, 'Progress', const Color(0xFF58CC02)), // Learning green
                    _buildRewardItem(Icons.emoji_events, 'Badge', const Color(0xFFF59E0B)), // Gold
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF58CC02).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF58CC02), width: 2),
            ),
            child: Column(
              children: [
                const Text(
                  '🎯 Ready to Apply What You Learned?',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF58CC02),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Take action with hands-on activities and reflect on your learning!',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: Builder(
                  builder: (buttonContext) => ElevatedButton(
                    onPressed: () async {
                      try {
                        // Access provider from button context which is in the widget tree
                        final gamification = Provider.of<GamificationService>(buttonContext, listen: false);
                        final xpAmount = _lesson['xp'] as int? ?? 50;
                        gamification.addXP(xpAmount, 'lesson_skip');
                        
                        // Save lesson completion to database
                        final lessonId = widget.lessonId.toString();
                        await DatabaseService.saveCompletedAction('lesson_$lessonId');
                        await DatabaseService.saveCompletedAction('lesson_${lessonId}_skipped');
                        
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('✅ Lesson skipped! +$xpAmount 💎 gems'),
                              backgroundColor: const Color(0xFF58CC02),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                          Navigator.pop(context);
                        }
                      } catch (e) {
                        print('Error skipping lesson: $e');
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[300],
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Skip for Now',
                      style: GoogleFonts.poppins(
                        color: Colors.grey[600],
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Builder(
                  builder: (buttonContext) => ElevatedButton(
                    onPressed: () async {
                      try {
                        // Access provider from button context which is in the widget tree
                        final gamification = Provider.of<GamificationService>(buttonContext, listen: false);
                        final lessonId = widget.lessonId.toString();
                        
                        // Check if lesson was already completed (XP farming prevention)
                        final completedActions = await DatabaseService.getCompletedActions();
                        final isRepeat = completedActions.contains('lesson_$lessonId') || 
                                        completedActions.contains('lesson_${lessonId}_completed');
                        
                        // Calculate XP: Full XP for first completion, reduced for repeats
                        final baseXP = (_lesson['xp_reward'] as int?) ?? (_lesson['xp'] as int?) ?? 50;
                        final xpAmount = isRepeat 
                            ? (baseXP * 0.1).round() // 10% XP for repeats (practice mode)
                            : baseXP; // Full XP for first completion
                        
                        // ONLY award XP on first completion - NO XP on repeats (prevent infinite glitch)
                        if (!isRepeat) {
                          gamification.addXP(xpAmount, 'lesson_complete');
                        }
                        
                        // Unlock lesson-specific badge (only on first completion)
                        final badgeName = _lesson['badge'] as String?;
                        if (badgeName != null && !isRepeat) {
                          gamification.unlockBadge(badgeName);
                        }
                        
                        // Check for general achievements
                        gamification.checkAchievements();
                        
                        // Track lesson completion in daily goals (only first completion counts)
                        if (!isRepeat) {
                          try {
                            DailyGoalsService().trackLesson();
                          } catch (e) {
                            print('Error tracking lesson: $e');
                          }
                        }
                        
                        // Save lesson completion to database
                        await DatabaseService.saveCompletedAction('lesson_$lessonId');
                        await DatabaseService.saveCompletedAction('lesson_${lessonId}_completed');
                        
                        // Save XP earned for this lesson
                        await DatabaseService.saveCompletedActionWithXP('lesson_$lessonId', xpAmount);
                        
                        // Unlock next lesson when current lesson is completed (sequential unlock)
                        if (!isRepeat) {
                          try {
                            final dailyLessonService = Provider.of<DailyLessonService>(buttonContext, listen: false);
                            // Get next lesson ID from pathway
                            final dayNum = LearningPathway.getDayForLessonId(lessonId);
                            if (dayNum != null && dayNum < 30) {
                              final nextLessonId = LearningPathway.getLessonIdForDay(dayNum + 1);
                              if (nextLessonId != null) {
                                // Unlock next lesson using public method
                                await dailyLessonService.unlockLesson(nextLessonId);
                              }
                            }
                          } catch (e) {
                            print('Error unlocking next lesson: $e');
                          }
                        }
                        
                        // Add notification for badge unlock (only first completion)
                        if (badgeName != null && !isRepeat) {
                          try {
                            final notificationManager = Provider.of<NotificationManager>(buttonContext, listen: false);
                            await notificationManager.addNotification(
                              type: 'achievement',
                              title: 'Badge Unlocked! 🏆',
                              message: 'You earned the "$badgeName" badge!',
                              data: {'badge': badgeName, 'lesson_id': lessonId},
                            );
                          } catch (e) {
                            print('Error adding notification: $e');
                          }
                        }
                        
                        if (mounted) {
                          // Only show XP message if NOT a repeat (no XP banners for repeats)
                          if (!isRepeat) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('🎉 Lesson complete! +$xpAmount XP earned!'),
                                backgroundColor: const Color(0xFF58CC02),
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          } else {
                            // For repeats, just show simple completion message (no XP mentioned)
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('✅ Practice complete! Keep learning!'),
                                backgroundColor: Colors.blue[600]!,
                                duration: const Duration(seconds: 1),
                              ),
                            );
                          }
                          
                          // Navigate to simple action screen
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => SimpleActionScreen(
                                lessonId: lessonId,
                                lessonContent: _lesson['content'] ?? 'Great job completing this lesson!',
                                lessonTitle: _lesson['title'] ?? 'Lesson Complete',
                                isRepeatAttempt: isRepeat,
                              ),
                            ),
                          );
                        }
                      } catch (e) {
                        print('Error completing lesson: $e');
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF58CC02),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Take Action! 🎯',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
        ),
        );
      },
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

  // Randomize answers for multiple choice questions
  void _randomizeAnswers() {
    for (int i = 0; i < _questions.length; i++) {
      final question = _questions[i];
      if (question['type'] == 'multiple_choice') {
        final originalOptions = List<String>.from(question['options'] as List);
        final originalCorrect = question['correct'] as int;
        final correctAnswer = originalOptions[originalCorrect];
        
        // Shuffle options
        final shuffledOptions = List<String>.from(originalOptions);
        shuffledOptions.shuffle();
        
        // Find new index of correct answer
        final newCorrectIndex = shuffledOptions.indexOf(correctAnswer);
        
        // Store randomized data
        _randomizedQuestions[i] = {
          'options': shuffledOptions,
          'correct': newCorrectIndex,
        };
      }
    }
  }

  // Helper method to check if lesson is a repeat (for XP banner prevention)
  Future<bool> _checkIfRepeat(String lessonId) async {
    final completedActions = await DatabaseService.getCompletedActions();
    return completedActions.contains('lesson_$lessonId') || 
           completedActions.contains('lesson_${lessonId}_completed');
  }

  void _selectAnswer(int answerIndex) {
    setState(() {
      _selectedAnswer = answerIndex;
    });

    final question = _questions[_currentQuestion];
    bool isCorrect;
    
    // Handle different question types
    if (question['type'] == 'true_false') {
      // For true/false: answerIndex 1 = true, 0 = false
      final selectedValue = answerIndex == 1;
      isCorrect = selectedValue == question['correct'];
    } else if (question['type'] == 'multiple_choice') {
      // For multiple choice: use randomized correct index if available
      final randomizedData = _randomizedQuestions[_currentQuestion];
      final correctAnswer = randomizedData?['correct'] as int? ?? question['correct'] as int;
      isCorrect = answerIndex == correctAnswer;
    } else {
      // For fill_blank and other types
      isCorrect = answerIndex == question['correct'];
    }
    
    setState(() {
      _isCorrect = isCorrect;
      _showFeedback = true;
      if (isCorrect) {
        _correctAnswers++;
      } else {
        _hearts--;
      }
    });

    _feedbackController.forward();

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        _nextQuestion();
      }
    });
  }

  void _nextQuestion() {
    if (_currentQuestion < _questions.length - 1) {
      setState(() {
        _currentQuestion++;
        _selectedAnswer = null;
        _showFeedback = false;
        _isCorrect = false;
      });
      _animationController.reset();
      _animationController.forward();
    } else {
      setState(() {
        _isCompleted = true;
      });
    }
  }

  void _simulateSpeechRecognition() async {
    if (_isRecording) return;
    
    // Show recording animation
    if (!mounted) return;
    setState(() {
      _isRecording = true;
    });
    
    try {
      // Simulate recording with visual feedback
      await Future.delayed(const Duration(seconds: 2));
      
      if (!mounted) return;
      
      // Stop recording
      setState(() {
        _isRecording = false;
        _isCorrect = true;
        _correctAnswers++;
        _showFeedback = true;
      });
      
      // Get the text to "speak"
      final question = _questions[_currentQuestion];
      final questionText = question['text'] ?? 
                          question['question'] ?? 
                          'Perfect!';
      
      // Show success feedback
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        '✅ Perfect!',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        'You said: "$questionText"',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF58CC02),
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
        
        // Auto-advance after showing feedback
        await Future.delayed(const Duration(milliseconds: 2500));
        if (mounted) {
          _nextQuestion();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isRecording = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e. Try again!'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  void _selectTerm(String term) {
    // Handle term selection for matching
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Selected: $term'),
        backgroundColor: Colors.blue,
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _selectDefinition(String definition) {
    // Handle definition selection for matching
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Selected: $definition'),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _handleMatchingDrop(int draggedIndex, int targetIndex, bool isTargetTerm) {
    if (_matchedPairs.contains(draggedIndex) || _matchedPairs.contains(targetIndex)) {
      return; // Already matched
    }
    
    final pairs = _questions[_currentQuestion]['pairs'] as List;
    final isDraggedTerm = draggedIndex < pairs.length;
    
    // Can only match term with definition (different types)
    if (isDraggedTerm == isTargetTerm) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ Match a term with its definition!'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 1),
        ),
      );
      return;
    }
    
    // Calculate pair indices
    final draggedPairIndex = isDraggedTerm ? draggedIndex : draggedIndex - pairs.length;
    final targetPairIndex = isTargetTerm ? targetIndex : targetIndex - pairs.length;
    
    if (draggedPairIndex == targetPairIndex) {
      // Correct match!
      setState(() {
        _matchedPairs.add(draggedIndex);
        _matchedPairs.add(targetIndex);
        _selectedTermIndex = null;
      });
      
      // Show success feedback
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Correct match!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 1),
        ),
      );
      
      // Check if all pairs are matched
      if (_matchedPairs.length == pairs.length * 2) {
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) {
            _nextQuestion();
          }
        });
      }
    } else {
      // Wrong match
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ Wrong match! Try again.'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 1),
        ),
      );
    }
  }

  void _handleMatchingTap(int index, bool isTerm) {
    // Keep tap functionality as fallback
    if (_matchedPairs.contains(index)) return;
    
    if (_selectedTermIndex == null) {
      setState(() {
        _selectedTermIndex = index;
      });
    } else {
      final firstIndex = _selectedTermIndex!;
      final pairs = _questions[_currentQuestion]['pairs'] as List;
      final isFirstTerm = firstIndex < pairs.length;
      
      if (isFirstTerm == isTerm) {
        setState(() {
          _selectedTermIndex = index;
        });
      } else {
        final firstPairIndex = isFirstTerm ? firstIndex : firstIndex - pairs.length;
        final secondPairIndex = isTerm ? index : index - pairs.length;
        
        if (firstPairIndex == secondPairIndex) {
          setState(() {
            _matchedPairs.add(firstIndex);
            _matchedPairs.add(index);
            _selectedTermIndex = null;
          });
          
          if (_matchedPairs.length == pairs.length * 2) {
            Future.delayed(const Duration(seconds: 1), () {
              if (mounted) {
                _nextQuestion();
              }
            });
          }
        } else {
          setState(() {
            _selectedTermIndex = null;
          });
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('❌ Wrong match! Try again.'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 1),
            ),
          );
        }
      }
    }
  }
}
