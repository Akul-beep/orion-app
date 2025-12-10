import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class QuizGameWidget extends StatefulWidget {
  final String title;
  final List<QuizQuestion> questions;
  final int timeLimit; // in seconds
  final VoidCallback? onComplete;
  final Function(int score)? onScoreUpdate;

  const QuizGameWidget({
    Key? key,
    required this.title,
    required this.questions,
    this.timeLimit = 60,
    this.onComplete,
    this.onScoreUpdate,
  }) : super(key: key);

  @override
  _QuizGameWidgetState createState() => _QuizGameWidgetState();
}

class _QuizGameWidgetState extends State<QuizGameWidget>
    with TickerProviderStateMixin {
  late AnimationController _timerController;
  late AnimationController _questionController;
  late Animation<double> _scaleAnimation;
  late Animation<Color?> _colorAnimation;

  int _currentQuestion = 0;
  int _correctAnswers = 0;
  int _timeRemaining = 0;
  bool _isGameActive = false;
  bool _isGameComplete = false;
  String? _selectedAnswer;
  bool _showFeedback = false;

  @override
  void initState() {
    super.initState();
    _timeRemaining = widget.timeLimit;

    _timerController = AnimationController(
      duration: Duration(seconds: widget.timeLimit),
      vsync: this,
    );

    _questionController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _questionController,
      curve: Curves.easeInOut,
    ));

    _colorAnimation = ColorTween(
      begin: Colors.blue,
      end: Colors.red,
    ).animate(CurvedAnimation(
      parent: _timerController,
      curve: Curves.linear,
    ));
  }

  @override
  void dispose() {
    _timerController.dispose();
    _questionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
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
      child: _isGameComplete ? _buildGameComplete() : _buildGame(),
    );
  }

  Widget _buildGame() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(),
        const SizedBox(height: 24),
        _buildProgress(),
        const SizedBox(height: 24),
        _buildQuestion(),
        const SizedBox(height: 24),
        _buildAnswers(),
        if (_showFeedback) ...[
          const SizedBox(height: 24),
          _buildFeedback(),
        ],
      ],
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.title,
              style: GoogleFonts.inter(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF111827),
                letterSpacing: -0.3,
              ),
            ),
            Text(
              'Quiz Game',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: const Color(0xFF6B7280),
              ),
            ),
          ],
        ),
        if (_isGameActive)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _timeRemaining < 10 ? const Color(0xFFEF4444).withOpacity(0.08) : const Color(0xFF0052FF).withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: _timeRemaining < 10 ? const Color(0xFFEF4444).withOpacity(0.2) : const Color(0xFF0052FF).withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Text(
              '${_timeRemaining}s',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: _timeRemaining < 10 ? const Color(0xFFEF4444) : const Color(0xFF0052FF),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildProgress() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Question ${_currentQuestion + 1} of ${widget.questions.length}',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF111827),
              ),
            ),
            Text(
              'Score: $_correctAnswers',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF10B981),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: (_currentQuestion + 1) / widget.questions.length,
          backgroundColor: const Color(0xFFE5E7EB),
          valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF0052FF)),
          minHeight: 4,
          borderRadius: BorderRadius.circular(2),
        ),
        if (_isGameActive) ...[
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: _timeRemaining / widget.timeLimit,
            backgroundColor: const Color(0xFFE5E7EB),
            valueColor: AlwaysStoppedAnimation<Color>(
              _timeRemaining < 10 ? const Color(0xFFEF4444) : const Color(0xFF0052FF),
            ),
            minHeight: 4,
            borderRadius: BorderRadius.circular(2),
          ),
        ],
      ],
    );
  }

  Widget _buildQuestion() {
    if (_currentQuestion >= widget.questions.length) return const SizedBox.shrink();

    final question = widget.questions[_currentQuestion];
    return AnimatedBuilder(
      animation: _questionController,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F7FA),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFFE5E7EB),
                width: 1,
              ),
            ),
            child: Text(
              question.question,
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF111827),
                height: 1.5,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAnswers() {
    if (_currentQuestion >= widget.questions.length) return const SizedBox.shrink();

    final question = widget.questions[_currentQuestion];
    return Column(
      children: question.answers.asMap().entries.map((entry) {
        final index = entry.key;
        final answer = entry.value;
        final isSelected = _selectedAnswer == answer;
        final isCorrect = answer == question.correctAnswer;
        final showResult = _showFeedback;

        Color backgroundColor = Colors.white;
        Color borderColor = const Color(0xFFE5E7EB);
        Color textColor = Colors.black;

        if (showResult) {
          if (isCorrect) {
            backgroundColor = const Color(0xFF10B981).withOpacity(0.08);
            borderColor = const Color(0xFF10B981);
            textColor = const Color(0xFF10B981);
          } else if (isSelected && !isCorrect) {
            backgroundColor = const Color(0xFFEF4444).withOpacity(0.08);
            borderColor = const Color(0xFFEF4444);
            textColor = const Color(0xFFEF4444);
          }
        } else if (isSelected) {
          backgroundColor = const Color(0xFF0052FF).withOpacity(0.08);
          borderColor = const Color(0xFF0052FF);
          textColor = const Color(0xFF0052FF);
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          child: GestureDetector(
            onTap: _showFeedback ? null : () => _selectAnswer(answer),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: borderColor, width: 2),
              ),
              child: Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: showResult && isCorrect
                          ? const Color(0xFF10B981)
                          : showResult && isSelected && !isCorrect
                              ? const Color(0xFFEF4444)
                              : isSelected
                                  ? const Color(0xFF0052FF)
                                  : const Color(0xFFD1D5DB),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: showResult && isCorrect
                        ? const Icon(Icons.check, color: Colors.white, size: 16)
                        : showResult && isSelected && !isCorrect
                            ? const Icon(Icons.close, color: Colors.white, size: 16)
                            : isSelected
                                ? const Icon(Icons.radio_button_checked, color: Colors.white, size: 16)
                                : const Icon(Icons.radio_button_unchecked, color: Colors.white, size: 16),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      answer,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: textColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildFeedback() {
    final question = widget.questions[_currentQuestion];
    final isCorrect = _selectedAnswer == question.correctAnswer;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isCorrect ? const Color(0xFF10B981).withOpacity(0.08) : const Color(0xFFEF4444).withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCorrect ? const Color(0xFF10B981).withOpacity(0.2) : const Color(0xFFEF4444).withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                isCorrect ? Icons.check_circle : Icons.cancel_outlined,
                color: isCorrect ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  isCorrect ? 'Correct!' : 'Not quite right',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: isCorrect ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                  ),
                ),
              ),
            ],
          ),
          if (question.explanation.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              question.explanation,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: const Color(0xFF6B7280),
                height: 1.5,
              ),
            ),
          ],
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _nextQuestion,
              style: ElevatedButton.styleFrom(
                backgroundColor: isCorrect ? const Color(0xFF10B981) : const Color(0xFF0052FF),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: Text(
                _currentQuestion + 1 >= widget.questions.length ? 'Finish Quiz' : 'Next Question',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGameComplete() {
    final score = (_correctAnswers / widget.questions.length * 100).toInt();
    final isPerfect = _correctAnswers == widget.questions.length;

    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: isPerfect ? const Color(0xFF10B981).withOpacity(0.08) : const Color(0xFF0052FF).withOpacity(0.08),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Icon(
            isPerfect ? Icons.emoji_events : Icons.check_circle_outlined,
            color: isPerfect ? const Color(0xFF10B981) : const Color(0xFF0052FF),
            size: 40,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          isPerfect ? 'Perfect Score!' : 'Quiz Complete!',
          style: GoogleFonts.inter(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF111827),
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'You got $_correctAnswers out of ${widget.questions.length} questions correct!',
          style: GoogleFonts.inter(
            fontSize: 15,
            color: const Color(0xFF6B7280),
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        _buildScoreCard(score),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: _retryQuiz,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF5F7FA),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  side: const BorderSide(
                    color: Color(0xFFE5E7EB),
                    width: 1,
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'Try Again',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF111827),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  widget.onComplete?.call();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0052FF),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'Continue',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildScoreCard(int score) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
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
      child: Column(
        children: [
          _buildScoreRow('Score', '$score%'),
          const SizedBox(height: 12),
          _buildScoreRow('Correct Answers', '$_correctAnswers'),
          const SizedBox(height: 12),
          _buildScoreRow('XP Earned', '+${_correctAnswers * 10}'),
          const SizedBox(height: 12),
          _buildScoreRow('Achievement', score >= 80 ? 'Quiz Master' : 'Keep Learning'),
        ],
      ),
    );
  }

  Widget _buildScoreRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 14,
            color: const Color(0xFF6B7280),
          ),
        ),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF111827),
          ),
        ),
      ],
    );
  }

  void _startGame() {
    setState(() {
      _isGameActive = true;
      _timeRemaining = widget.timeLimit;
    });

    _timerController.forward();
    _timerController.addListener(() {
      setState(() {
        _timeRemaining = (widget.timeLimit * (1 - _timerController.value)).round();
      });

      if (_timeRemaining <= 0) {
        _finishGame();
      }
    });
  }

  void _selectAnswer(String answer) {
    setState(() {
      _selectedAnswer = answer;
    });

    _questionController.forward().then((_) {
      _questionController.reverse();
    });

    Future.delayed(const Duration(milliseconds: 500), () {
      _checkAnswer();
    });
  }

  void _checkAnswer() {
    final question = widget.questions[_currentQuestion];
    final isCorrect = _selectedAnswer == question.correctAnswer;

    setState(() {
      _showFeedback = true;
      if (isCorrect) {
        _correctAnswers++;
      }
    });

    widget.onScoreUpdate?.call(_correctAnswers);
  }

  void _nextQuestion() {
    setState(() {
      _currentQuestion++;
      _selectedAnswer = null;
      _showFeedback = false;
    });

    if (_currentQuestion >= widget.questions.length) {
      _finishGame();
    }
  }

  void _finishGame() {
    setState(() {
      _isGameActive = false;
      _isGameComplete = true;
    });
    _timerController.stop();
  }

  void _retryQuiz() {
    setState(() {
      _currentQuestion = 0;
      _correctAnswers = 0;
      _timeRemaining = widget.timeLimit;
      _isGameActive = false;
      _isGameComplete = false;
      _selectedAnswer = null;
      _showFeedback = false;
    });
    _timerController.reset();
    _questionController.reset();
  }
}

class QuizQuestion {
  final String question;
  final List<String> answers;
  final String correctAnswer;
  final String explanation;

  QuizQuestion({
    required this.question,
    required this.answers,
    required this.correctAnswer,
    required this.explanation,
  });
}



