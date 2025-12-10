import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../services/gamification_service.dart';
import '../../services/user_progress_service.dart';
import '../../data/interactive_lessons.dart';
import 'duolingo_lesson_screen.dart';

class DuolingoTeachingScreen extends StatefulWidget {
  final String lessonId; // Changed to String

  const DuolingoTeachingScreen({
    Key? key,
    required this.lessonId,
  }) : super(key: key);

  @override
  State<DuolingoTeachingScreen> createState() => _DuolingoTeachingScreenState();
}

class _DuolingoTeachingScreenState extends State<DuolingoTeachingScreen>
    with TickerProviderStateMixin {
  late Map<String, dynamic> _lesson;
  List<Map<String, dynamic>> _teachingSteps = [];
  int _currentStep = 0;
  bool _isCompleted = false;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _lesson = InteractiveLessons.getLessonById(widget.lessonId) ?? {};
    _loadTeachingSteps();
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOut));
    
    _animationController.forward();
    
    // Track screen visit and learning progress
    WidgetsBinding.instance.addPostFrameCallback((_) {
      UserProgressService().trackScreenVisit(
        screenName: 'DuolingoTeachingScreen',
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

  void _loadTeachingSteps() {
    // Create teaching steps based on lesson content
    _teachingSteps = _createTeachingSteps(_lesson);
  }

  List<Map<String, dynamic>> _createTeachingSteps(Map<String, dynamic> lesson) {
    if (lesson.isEmpty) return [];
    
    final steps = lesson['steps'] as List<dynamic>? ?? [];
    final teachingSteps = <Map<String, dynamic>>[];
    
    // Extract intro step
    for (final step in steps) {
      if (step['type'] == 'intro') {
        teachingSteps.add({
          'type': 'concept',
          'title': step['content'] ?? lesson['title'] ?? 'Lesson',
          'content': step['subtitle'] ?? lesson['description'] ?? 'Let\'s learn!',
          'example': _getExampleForLesson(lesson['id'] as String? ?? ''),
          'icon': step['icon'] ?? lesson['badge_emoji'] ?? '📚',
        });
        break; // Only use first intro
      }
    }
    
    // Extract concepts from explanations in questions
    for (final step in steps) {
      if (step['type'] == 'multiple_choice' || step['type'] == 'true_false') {
        final explanation = step['explanation'] as String?;
        if (explanation != null && explanation.isNotEmpty) {
          // Extract key concept from explanation
          final question = step['question'] as String? ?? '';
          teachingSteps.add({
            'type': 'concept',
            'title': question,
            'content': explanation,
            'example': _getExampleFromQuestion(question, explanation),
            'icon': _getIconForConcept(question),
          });
        }
      }
    }
    
    // If no teaching steps were created, create default ones
    if (teachingSteps.isEmpty) {
      teachingSteps.addAll(_getDefaultTeachingSteps(lesson));
    }
    
    return teachingSteps.take(4).toList(); // Max 4 teaching steps
  }

  String _getExampleForLesson(String lessonId) {
    // Provide examples based on lesson ID
    switch (lessonId) {
      case 'what_is_stock':
        return 'If Apple has 1 billion shares and you buy 100 shares, you own 0.00001% of Apple!';
      case 'how_stock_prices_work':
        return 'Good news about Apple = more buyers = price goes up!';
      case 'market_cap':
        return 'Apple stock at \$175 × 16 billion shares = \$2.8 trillion market cap!';
      case 'building_portfolio':
        return 'Buy 5 different stocks instead of putting everything in one stock!';
      default:
        return 'Open Trading from the bottom menu to practice these concepts with real market data!';
    }
  }

  String _getExampleFromQuestion(String question, String explanation) {
    // Extract simple example from question/explanation
    if (question.toLowerCase().contains('stock') || question.toLowerCase().contains('apple')) {
      return 'Buy Apple at \$150, sell at \$200 = \$50 profit!';
    }
    if (question.toLowerCase().contains('price') || question.toLowerCase().contains('up')) {
      return 'Good news = more buyers = price goes up!';
    }
    return 'Open Trading from the bottom menu to see this in action with real market data!';
  }

  String _getIconForConcept(String question) {
    if (question.toLowerCase().contains('stock')) return '📈';
    if (question.toLowerCase().contains('price') || question.toLowerCase().contains('money')) return '💰';
    if (question.toLowerCase().contains('risk')) return '🛡️';
    if (question.toLowerCase().contains('chart')) return '📊';
    return '📚';
  }

  List<Map<String, dynamic>> _getDefaultTeachingSteps(Map<String, dynamic> lesson) {
    final title = lesson['title'] as String? ?? 'Lesson';
    final description = lesson['description'] as String? ?? 'Learn important concepts';
    final icon = lesson['badge_emoji'] as String? ?? '📚';
    
    return [
      {
        'type': 'concept',
        'title': title,
        'content': description,
        'example': 'Open Trading from the bottom menu to practice these concepts with real market data!',
        'icon': icon,
      },
    ];
  }

  List<Map<String, dynamic>> _getOldHardcodedSteps(int lessonId) {
    switch (lessonId) {
      case 1: // What is a Stock?
        return [
          {
            'type': 'concept',
            'title': 'What is a Stock?',
            'content': 'A stock is a piece of a company that you can buy and own.',
            'example': 'If Apple has 1 billion shares and you buy 100 shares, you own 0.00001% of Apple!',
            'icon': '📈',
          },
          {
            'type': 'concept',
            'title': 'Why Companies Sell Stocks',
            'content': 'Companies sell stocks to raise money for growth, research, and expansion.',
            'example': 'Tesla went public in 2010 to fund electric vehicle development.',
            'icon': '🏢',
          },
          {
            'type': 'concept',
            'title': 'How You Make Money',
            'content': 'You make money from stocks in two ways: 1) Price goes up, 2) Dividends (company pays you cash).',
            'example': 'Buy Apple at \$150, sell at \$200 = \$50 profit per share!',
            'icon': '💰',
          },
        ];
      case 2: // How to Make Money Trading
        return [
          {
            'type': 'concept',
            'title': 'The Golden Rule',
            'content': 'Buy low, sell high - this is how you make money trading stocks.',
            'example': 'Buy a stock for \$10, sell it for \$15 = \$5 profit!',
            'icon': '📈',
          },
          {
            'type': 'concept',
            'title': 'Price Movements',
            'content': 'Stock prices change based on supply and demand, company news, and market conditions.',
            'example': 'Good news = price goes up, bad news = price goes down.',
            'icon': '📊',
          },
          {
            'type': 'concept',
            'title': 'Timing is Everything',
            'content': 'The key is buying when prices are low and selling when they\'re high.',
            'example': 'Buy during market dips, sell during peaks.',
            'icon': '⏰',
          },
        ];
      case 3: // Reading Stock Charts
        return [
          {
            'type': 'concept',
            'title': 'Green vs Red',
            'content': 'Green candles mean the stock price went up, red candles mean it went down.',
            'example': 'Green = good day, Red = bad day for that stock.',
            'icon': '📊',
          },
          {
            'type': 'concept',
            'title': 'Trends',
            'content': 'An upward trend means the stock price is generally increasing over time.',
            'example': 'Bullish trend = prices going up, Bearish trend = prices going down.',
            'icon': '📈',
          },
          {
            'type': 'concept',
            'title': 'Support & Resistance',
            'content': 'Support is where prices tend to bounce up, resistance is where they tend to bounce down.',
            'example': 'Think of support as a floor and resistance as a ceiling.',
            'icon': '🛡️',
          },
        ];
      case 4: // Risk Management
        return [
          {
            'type': 'concept',
            'title': 'The 1% Rule',
            'content': 'Never risk more than 1% of your total account on a single trade.',
            'example': 'If you have \$10,000, never risk more than \$100 on one trade.',
            'icon': '🛡️',
          },
          {
            'type': 'concept',
            'title': 'Stop Loss Orders',
            'content': 'A stop loss automatically sells your stock if the price drops too much.',
            'example': 'Set stop loss at 5% below your buy price to limit losses.',
            'icon': '🛑',
          },
          {
            'type': 'concept',
            'title': 'Diversification',
            'content': 'Don\'t put all your money in one stock - spread it across many different stocks.',
            'example': 'Buy 10 different stocks instead of putting everything in one.',
            'icon': '🎯',
          },
        ];
      case 5: // Trading Psychology
        return [
          {
            'type': 'concept',
            'title': 'Fear and Greed',
            'content': 'Fear makes you sell too early, greed makes you hold too long.',
            'example': 'Fear: "I\'m losing money, sell now!" Greed: "It\'s going up, hold longer!"',
            'icon': '🧠',
          },
          {
            'type': 'concept',
            'title': 'FOMO (Fear of Missing Out)',
            'content': 'Don\'t buy stocks just because everyone else is buying them.',
            'example': 'Just because everyone is buying GameStop doesn\'t mean you should too.',
            'icon': '😰',
          },
          {
            'type': 'concept',
            'title': 'Stay Calm',
            'content': 'The best traders stay calm and stick to their plan, even when emotions run high.',
            'example': 'Market crashes? Stay calm, don\'t panic sell everything.',
            'icon': '😌',
          },
        ];
      case 6: // Real Trading Practice
        return [
          {
            'type': 'concept',
            'title': 'Start with Paper Trading',
            'content': 'Practice with fake money first to learn without risking real money.',
            'example': 'Use paper trading apps to practice before using real money.',
            'icon': '📝',
          },
          {
            'type': 'concept',
            'title': 'Start Small',
            'content': 'When you start with real money, start with small amounts you can afford to lose.',
            'example': 'Start with \$100, not \$10,000 when you begin real trading.',
            'icon': '💰',
          },
          {
            'type': 'concept',
            'title': 'Research First',
            'content': 'Always research companies before buying their stocks.',
            'example': 'Read news, check financials, understand what the company does.',
            'icon': '🔍',
          },
        ];
      default:
        return [];
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
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
                child: _isCompleted ? _buildCompletionScreen() : _buildTeachingContent(),
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
          // Progress
          Text(
            '${_currentStep + 1}/${_teachingSteps.length}',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
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

  Widget _buildTeachingContent() {
    if (_currentStep >= _teachingSteps.length) {
      return _buildCompletionScreen();
    }

    final step = _teachingSteps[_currentStep];
    
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _buildProgressBar(),
                  const SizedBox(height: 24),
                  Expanded(
                    child: _buildConceptCard(step),
                  ),
                  const SizedBox(height: 24),
                  _buildNavigationButtons(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildProgressBar() {
    final progress = (_currentStep + 1) / _teachingSteps.length;
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Learning Step ${_currentStep + 1}',
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

  Widget _buildConceptCard(Map<String, dynamic> step) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFF58CC02).withOpacity(0.1),
              borderRadius: BorderRadius.circular(40),
            ),
            child: Center(
              child: Text(
                step['icon'],
                style: const TextStyle(fontSize: 40),
              ),
            ),
          ),
          const SizedBox(height: 24),
          // Title
          Text(
            step['title'],
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          // Content
          Text(
            step['content'],
            style: GoogleFonts.poppins(
              fontSize: 18,
              color: Colors.black87,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          // Example
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue[200]!),
            ),
            child: Column(
              children: [
                Text(
                  'Example:',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[700],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  step['example'],
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: Colors.blue[800],
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationButtons() {
    return Row(
      children: [
        if (_currentStep > 0)
          Expanded(
            child: ElevatedButton(
              onPressed: _previousStep,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey[300],
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Previous',
                style: GoogleFonts.poppins(
                  color: Colors.black,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        if (_currentStep > 0) const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton(
            onPressed: _nextStep,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF58CC02),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              _currentStep < _teachingSteps.length - 1 ? 'Next' : 'Start Quiz',
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
              color: const Color(0xFF58CC02).withOpacity(0.1),
              borderRadius: BorderRadius.circular(60),
            ),
            child: const Icon(
              Icons.school,
              color: Color(0xFF58CC02),
              size: 60,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Ready for the Quiz!',
            style: GoogleFonts.poppins(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            'You\'ve learned the concepts. Now let\'s test your knowledge!',
            style: GoogleFonts.poppins(
              fontSize: 18,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                // Track navigation
                UserProgressService().trackNavigation(
                  fromScreen: 'DuolingoTeachingScreen',
                  toScreen: 'DuolingoLessonScreen',
                  navigationMethod: 'replace',
                  navigationData: {'lesson_id': widget.lessonId},
                );
                
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DuolingoLessonScreen(lessonId: widget.lessonId),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF58CC02),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Start Quiz',
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

  void _nextStep() {
    if (_currentStep < _teachingSteps.length - 1) {
      setState(() {
        _currentStep++;
      });
      _animationController.reset();
      _animationController.forward();
    } else {
      setState(() {
        _isCompleted = true;
      });
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
      _animationController.reset();
      _animationController.forward();
    }
  }
}


