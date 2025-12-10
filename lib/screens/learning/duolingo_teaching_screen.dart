import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../services/gamification_service.dart';
import '../../services/user_progress_service.dart';
import '../../services/daily_lesson_service.dart';
import '../../services/database_service.dart';
import '../../data/interactive_lessons.dart';
import '../../data/learning_pathway.dart';
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
  Map<String, dynamic> _lesson = {};
  List<Map<String, dynamic>> _teachingSteps = [];
  int _currentStep = 0;
  bool _isCompleted = false;
  bool _isLoadingLesson = true;
  
  Future<void> _loadLesson() async {
    setState(() => _isLoadingLesson = true);
    try {
      final lesson = await InteractiveLessons.getLessonById(widget.lessonId);
      if (mounted) {
        setState(() {
          _lesson = lesson ?? {};
          _isLoadingLesson = false;
        });
        _loadTeachingSteps();
      }
    } catch (e) {
      print('Error loading lesson: $e');
      if (mounted) {
        setState(() {
          _lesson = {};
          _isLoadingLesson = false;
        });
      }
    }
  }

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    // Always start from the beginning when reviewing
    _currentStep = 0;
    _isCompleted = false;
    
    _loadLesson();
    
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
    
    // CRITICAL: Check if lesson was unlocked today - block access immediately
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final dailyLessonService = Provider.of<DailyLessonService>(context, listen: false);
      final completedActions = await DatabaseService.getCompletedActions();
      final isCompleted = completedActions.contains('lesson_${widget.lessonId}') || 
                          completedActions.contains('lesson_${widget.lessonId}_completed');
      
      // Get day number for this lesson
      final dayNum = LearningPathway.getDayForLessonId(widget.lessonId);
      
      // Allow first lesson (day 1) always, but block others unlocked today
      // If not completed and was unlocked today AND not the first lesson, block access
      if (!isCompleted && dayNum != 1 && dailyLessonService.wasLessonUnlockedToday(widget.lessonId)) {
        if (mounted) {
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
              duration: const Duration(seconds: 3),
            ),
          );
          
          // Navigate back immediately
          await Future.delayed(const Duration(milliseconds: 500));
          if (mounted) {
            Navigator.pop(context);
          }
          return;
        }
      }
      
      // Track screen visit and learning progress only if allowed
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
      case 'candlestick_patterns':
        return 'Green candles mean price closed higher than it opened. Red candles mean price closed lower!';
      case 'market_orders':
        return 'Market order buys immediately at current price. Limit order waits for your price!';
      case 'etfs_mutual_funds':
        return 'SPY ETF holds 500 companies. One share = instant diversification across the S&P 500!';
      case 'pe_ratio':
        return 'Apple P/E of 28 means you pay \$28 for each \$1 of earnings. Lower P/E = better value!';
      case 'moving_averages':
        return 'Price above 50-day moving average = uptrend. Price below = downtrend!';
      case 'support_resistance':
        return 'Support is like a floor - price bounces up. Resistance is like a ceiling - price bounces down!';
      case 'rsi_basics':
        return 'RSI above 70 = overbought (might drop). RSI below 30 = oversold (might bounce)!';
      case 'volume_analysis':
        return 'High volume + price up = strong move. Low volume = weak move that might reverse!';
      case 'risk_management':
        return 'If you have \$10,000, risk 1% = \$100 max per trade. Never risk more than you can afford to lose!';
      case 'position_sizing':
        return 'Stock \$50, stop loss \$45 = \$5 risk per share. Risk \$200 (2%) = buy 40 shares max!';
      case 'risk_reward_ratios':
        return 'Risk \$5 to make \$10 = 2:1 ratio. Always aim for 2:1 or better for profitable trading!';
      case 'portfolio_rebalancing':
        return 'If one stock grows to 50% of portfolio, sell 25% and buy other stocks to rebalance!';
      case 'macd_indicator':
        return 'MACD crosses above signal line = bullish buy signal. Below = bearish sell signal!';
      case 'bollinger_bands':
        return 'Price touches lower band = oversold (might bounce). Upper band = overbought (might drop)!';
      case 'chart_patterns':
        return 'Head and shoulders pattern = bearish reversal. Triangle = consolidation before breakout!';
      case 'breakout_trading':
        return 'Price breaks above \$150 resistance with high volume = strong bullish breakout signal!';
      case 'gap_trading':
        return 'Stock gaps up from \$100 to \$105. Often fills back to \$100. Trade the gap fill!';
      case 'financial_statements':
        return 'Growing revenue + growing earnings = healthy company. Check income statement before buying!';
      case 'earnings_reports':
        return 'Beat earnings = price usually goes up. Miss earnings = price usually goes down!';
      case 'sector_investing':
        return 'Diversify across sectors: tech (AAPL), healthcare (JNJ), finance (JPM), energy (XOM)!';
      case 'market_sentiment':
        return 'Extreme greed (all green) = might be top. Extreme fear (all red) = might be bottom!';
      case 'market_cycles':
        return 'Bull market = prices rising. Bear market = prices falling. Recovery = bouncing back!';
      case 'swing_trading':
        return 'Hold for 7 days. Set take profit 10% above, stop loss 5% below. That\'s swing trading!';
      case 'day_trading_basics':
        return 'Buy and sell same day. Take profit at 3% or cut loss at 3%. Fast decisions required!';
      case 'dividend_investing':
        return 'JNJ pays 3% dividend. Buy 100 shares at \$150 = \$4,500 investment = \$135/year income!';
      case 'growth_vs_value':
        return 'Growth stocks (NVDA) grow fast but expensive. Value stocks (JPM) grow slow but cheap!';
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
    if (question.toLowerCase().contains('chart') || question.toLowerCase().contains('candle')) {
      return 'Green candles = price went up. Red candles = price went down!';
    }
    if (question.toLowerCase().contains('risk') || question.toLowerCase().contains('stop')) {
      return 'Risk 1% per trade. Set stop loss 5% below entry to protect your capital!';
    }
    if (question.toLowerCase().contains('portfolio') || question.toLowerCase().contains('diversif')) {
      return 'Own 5-10 different stocks across different sectors to reduce risk!';
    }
    if (question.toLowerCase().contains('rsi') || question.toLowerCase().contains('momentum')) {
      return 'RSI under 30 = oversold (buy opportunity). RSI over 70 = overbought (sell opportunity)!';
    }
    if (question.toLowerCase().contains('moving average') || question.toLowerCase().contains('trend')) {
      return 'Price above moving average = uptrend. Price below = downtrend!';
    }
    if (question.toLowerCase().contains('support') || question.toLowerCase().contains('resistance')) {
      return 'Support = floor where price bounces up. Resistance = ceiling where price bounces down!';
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
    
    if (_lesson.isEmpty) {
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
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: _isCompleted ? _buildCompletionScreen() : _buildTeachingContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: kIsWeb ? 32 : 16,
        vertical: kIsWeb ? 16 : 12,
      ),
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
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF111827), size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          // Progress
          Text(
            '${_currentStep + 1}/${_teachingSteps.length}',
            style: GoogleFonts.inter(
              color: const Color(0xFF111827),
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          // Close button
          IconButton(
            icon: const Icon(Icons.close, color: Color(0xFF6B7280), size: 20),
            onPressed: () => Navigator.pop(context),
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
              padding: EdgeInsets.all(kIsWeb ? 32 : 20),
              child: Column(
                children: [
                  _buildProgressBar(),
                  SizedBox(height: kIsWeb ? 32 : 24),
                  Expanded(
                    child: _buildConceptCard(step),
                  ),
                  SizedBox(height: kIsWeb ? 32 : 24),
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
              style: GoogleFonts.inter(
                fontSize: 13,
                color: const Color(0xFF6B7280),
              ),
            ),
            Text(
              '${(progress * 100).round()}%',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: const Color(0xFF6B7280),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: progress,
          backgroundColor: const Color(0xFFE5E7EB),
          valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF0052FF)),
          minHeight: 4,
          borderRadius: BorderRadius.circular(2),
        ),
      ],
    );
  }

  Widget _buildConceptCard(Map<String, dynamic> step) {
    return Container(
      padding: EdgeInsets.all(kIsWeb ? 32 : 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(kIsWeb ? 20 : 16),
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
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: const Color(0xFF0052FF).withOpacity(0.08),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Text(
                step['icon'],
                style: const TextStyle(fontSize: 36),
              ),
            ),
          ),
          const SizedBox(height: 24),
          // Title
          Text(
            step['title'],
            style: GoogleFonts.inter(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF111827),
              letterSpacing: -0.3,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          // Content
          Text(
            step['content'],
            style: GoogleFonts.inter(
              fontSize: 16,
              color: const Color(0xFF111827),
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          // Example
          Container(
            padding: EdgeInsets.all(kIsWeb ? 20 : 16),
            decoration: BoxDecoration(
              color: const Color(0xFF0052FF).withOpacity(0.08),
              borderRadius: BorderRadius.circular(kIsWeb ? 16 : 12),
              border: Border.all(
                color: const Color(0xFF0052FF).withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Column(
              children: [
                Text(
                  'Example:',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF0052FF),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  step['example'],
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    color: const Color(0xFF111827),
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
            child: OutlinedButton(
              onPressed: _previousStep,
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFFE5E7EB), width: 1),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Previous',
                style: GoogleFonts.inter(
                  color: const Color(0xFF111827),
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        if (_currentStep > 0) const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton(
            onPressed: _nextStep,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0052FF),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: Text(
              _currentStep < _teachingSteps.length - 1 ? 'Next' : 'Start Quiz',
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w600,
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
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: const Color(0xFF0052FF).withOpacity(0.08),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.school_outlined,
              color: Color(0xFF0052FF),
              size: 48,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Ready for the Quiz!',
            style: GoogleFonts.inter(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF111827),
              letterSpacing: -0.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            'You\'ve learned the concepts. Now let\'s test your knowledge!',
            style: GoogleFonts.inter(
              fontSize: 15,
              color: const Color(0xFF6B7280),
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
                backgroundColor: const Color(0xFF0052FF),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: Text(
                'Start Quiz',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
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


