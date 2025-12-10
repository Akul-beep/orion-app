import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../widgets/learning/web_swipe_card.dart';
import '../../widgets/learning/swipe_learning_card.dart';
import '../../services/user_progress_service.dart';

class DailyChallengeScreen extends StatefulWidget {
  const DailyChallengeScreen({Key? key}) : super(key: key);

  @override
  _DailyChallengeScreenState createState() => _DailyChallengeScreenState();
}

class _DailyChallengeScreenState extends State<DailyChallengeScreen>
    with TickerProviderStateMixin {
  late AnimationController _timerController;
  late AnimationController _progressController;
  late Animation<double> _progressAnimation;

  int _currentQuestion = 0;
  int _correctAnswers = 0;
  int _timeRemaining = 120; // 2 minutes
  bool _isChallengeActive = false;
  bool _isChallengeComplete = false;

  @override
  void initState() {
    super.initState();
    // Track screen visit
    WidgetsBinding.instance.addPostFrameCallback((_) {
      UserProgressService().trackScreenVisit(
        screenName: 'DailyChallengeScreen',
        screenType: 'main',
        metadata: {'section': 'daily_challenge'},
      );
    });
  }

  final List<Map<String, dynamic>> _questions = [
    {
      'question': 'What does AAPL stand for?',
      'answer': 'Apple Inc.',
      'explanation': 'AAPL is the stock symbol for Apple Inc., one of the most valuable companies in the world.',
      'type': 'stock',
    },
    {
      'question': 'If a stock price goes from \$100 to \$105, what\'s the percentage change?',
      'answer': '5%',
      'explanation': 'A \$5 increase on a \$100 stock is a 5% gain. This is calculated as (105-100)/100 * 100 = 5%.',
      'type': 'price',
    },
    {
      'question': 'Which investment is generally considered HIGHER risk?',
      'answer': 'Individual stocks',
      'explanation': 'Individual stocks are riskier than index funds because they lack diversification. Index funds spread risk across many companies.',
      'type': 'risk',
    },
    {
      'question': 'What does this chart pattern suggest?',
      'answer': 'Bullish trend',
      'explanation': 'This upward-sloping pattern indicates a bullish (positive) trend, suggesting the stock price is likely to continue rising.',
      'type': 'pattern',
    },
    {
      'question': 'What does TSLA stand for?',
      'answer': 'Tesla Inc.',
      'explanation': 'TSLA is the stock symbol for Tesla Inc., the electric vehicle and clean energy company led by Elon Musk.',
      'type': 'stock',
    },
  ];

  @override
  void initState() {
    super.initState();
    _timerController = AnimationController(
      duration: const Duration(seconds: 120),
      vsync: this,
    );

    _progressController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _progressController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _timerController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Daily Challenge',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        actions: [
          if (_isChallengeActive)
            Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${_timeRemaining}s',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
            ),
        ],
      ),
      body: _isChallengeComplete
          ? _buildCompletionScreen()
          : _buildChallengeScreen(),
    );
  }

  Widget _buildChallengeScreen() {
    return Column(
      children: [
        _buildChallengeHeader(),
        Expanded(
          child: _isChallengeActive
              ? _buildActiveChallenge()
              : _buildChallengeIntro(),
        ),
      ],
    );
  }

  Widget _buildChallengeHeader() {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Daily Challenge',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${_currentQuestion + 1}/${_questions.length}',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildProgressBar(),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem('Correct', '$_correctAnswers', Colors.green),
              _buildStatItem('Time', '${_timeRemaining}s', Colors.orange),
              _buildStatItem('XP', '+100', Colors.amber),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Progress',
              style: GoogleFonts.poppins(
                color: Colors.white70,
                fontSize: 12,
              ),
            ),
            Text(
              '${((_currentQuestion / _questions.length) * 100).toInt()}%',
              style: GoogleFonts.poppins(
                color: Colors.white70,
                fontSize: 12,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: _currentQuestion / _questions.length,
          backgroundColor: Colors.white.withOpacity(0.3),
          valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
        ),
      ],
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: Colors.white70,
          ),
        ),
      ],
    );
  }

  Widget _buildChallengeIntro() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(60),
            ),
            child: const Icon(
              Icons.local_fire_department,
              color: Colors.orange,
              size: 60,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Ready for the Challenge?',
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            'Complete 5 questions in 2 minutes to earn 100 XP and unlock the "Speed Demon" achievement!',
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          _buildChallengeRules(),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _startChallenge,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Start Challenge',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChallengeRules() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildRuleItem(Icons.timer, '2 minutes to complete'),
          const SizedBox(height: 12),
          _buildRuleItem(Icons.touch_app, 'Swipe right for "Got it"'),
          const SizedBox(height: 12),
          _buildRuleItem(Icons.arrow_back, 'Swipe left for "Don\'t know"'),
          const SizedBox(height: 12),
          _buildRuleItem(Icons.bolt, 'Earn 100 XP for completion'),
        ],
      ),
    );
  }

  Widget _buildRuleItem(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: Colors.orange, size: 20),
        const SizedBox(width: 12),
        Text(
          text,
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: Colors.grey[700],
          ),
        ),
      ],
    );
  }

  Widget _buildActiveChallenge() {
    if (_currentQuestion >= _questions.length) {
      _completeChallenge();
      return _buildCompletionScreen();
    }

    final question = _questions[_currentQuestion];
    return WebSwipeCard(
      question: question['question'],
      answer: question['answer'],
      explanation: question['explanation'],
      type: question['type'],
      onCorrect: _handleCorrectAnswer,
      onIncorrect: _handleIncorrectAnswer,
    );
  }

  Widget _buildCompletionScreen() {
    final score = (_correctAnswers / _questions.length * 100).toInt();
    final isPerfect = _correctAnswers == _questions.length;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: isPerfect ? Colors.green.withOpacity(0.1) : Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(60),
            ),
            child: Icon(
              isPerfect ? Icons.emoji_events : Icons.check_circle,
              color: isPerfect ? Colors.green : Colors.blue,
              size: 60,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            isPerfect ? 'Perfect Score!' : 'Challenge Complete!',
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            'You got $_correctAnswers out of ${_questions.length} questions correct!',
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          _buildCompletionStats(),
          const SizedBox(height: 32),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: _retryChallenge,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[200],
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Try Again',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[700],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: _finishChallenge,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Continue',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCompletionStats() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildStatRow('Score', '${(_correctAnswers / _questions.length * 100).toInt()}%'),
          const SizedBox(height: 12),
          _buildStatRow('Correct Answers', '$_correctAnswers'),
          const SizedBox(height: 12),
          _buildStatRow('XP Earned', '+100'),
          const SizedBox(height: 12),
          _buildStatRow('Achievement', 'Speed Demon'),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
      ],
    );
  }

  void _startChallenge() {
    setState(() {
      _isChallengeActive = true;
      _currentQuestion = 0;
      _correctAnswers = 0;
      _timeRemaining = 120;
    });

    _startTimer();
  }

  void _startTimer() {
    _timerController.forward();
    _timerController.addListener(() {
      setState(() {
        _timeRemaining = (120 * (1 - _timerController.value)).round();
      });

      if (_timeRemaining <= 0) {
        _completeChallenge();
      }
    });
  }

  void _handleCorrectAnswer() {
    setState(() {
      _correctAnswers++;
      _currentQuestion++;
    });
    _progressController.forward();
  }

  void _handleIncorrectAnswer() {
    setState(() {
      _currentQuestion++;
    });
    _progressController.forward();
  }

  void _completeChallenge() {
    setState(() {
      _isChallengeActive = false;
      _isChallengeComplete = true;
    });
    _timerController.stop();
  }

  void _retryChallenge() {
    setState(() {
      _isChallengeComplete = false;
      _currentQuestion = 0;
      _correctAnswers = 0;
      _timeRemaining = 120;
    });
    _timerController.reset();
    _progressController.reset();
  }

  void _finishChallenge() {
    Navigator.pop(context);
  }
}
