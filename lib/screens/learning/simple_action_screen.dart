import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/gamification_service.dart';
import '../../services/paper_trading_service.dart';
import '../../services/market_status_service.dart';
import '../../services/database_service.dart';
import '../../services/user_progress_service.dart';
import '../../screens/enhanced_stock_detail_screen.dart';
import '../../screens/professional_stocks_screen.dart';
import '../../screens/stocks_screen.dart';
import '../../design_system.dart';
import '../../data/learning_pathway.dart';
import '../../data/learning_actions_content.dart';

class SimpleActionScreen extends StatefulWidget {
  final String lessonId;
  final String lessonTitle;
  final String lessonContent;
  final bool isRepeatAttempt; // Track if this is a repeat attempt

  const SimpleActionScreen({
    Key? key,
    required this.lessonId,
    required this.lessonTitle,
    required this.lessonContent,
    this.isRepeatAttempt = false,
  }) : super(key: key);

  @override
  State<SimpleActionScreen> createState() => _SimpleActionScreenState();
}

class _SimpleActionScreenState extends State<SimpleActionScreen> {
  bool _actionCompleted = false;
  String? _selectedAnswer;
  bool _hasNavigatedAway = false;
  bool _isFirstCompletion = true;
  int _previouslyEarnedXP = 0; // Track XP already earned for this action

  @override
  void initState() {
    super.initState();
    _checkIfAlreadyCompleted();
    
    // Track screen visit
    WidgetsBinding.instance.addPostFrameCallback((_) {
      UserProgressService().trackScreenVisit(
        screenName: 'SimpleActionScreen',
        screenType: 'detail',
        metadata: {
          'lesson_id': widget.lessonId,
          'lesson_title': widget.lessonTitle,
          'is_repeat': widget.isRepeatAttempt,
        },
      );
      
      UserProgressService().trackLearningProgress(
        lessonId: widget.lessonId,
        lessonName: widget.lessonTitle,
        progressPercentage: 0,
      );
    });
  }

  Future<void> _checkIfAlreadyCompleted() async {
    final actionId = 'action_lesson_${widget.lessonId}_quiz';
    final userId = await DatabaseService.getOrCreateLocalUserId();
    final supabase = DatabaseService.getSupabaseClient();
    
    try {
      if (supabase != null) {
        final response = await supabase
            .from('completed_actions')
            .select()
            .eq('user_id', userId)
            .eq('action_id', actionId)
            .maybeSingle();
        
        if (response != null) {
          // Check if XP was already earned
          final xpEarned = response['xp_earned'] as int? ?? 0;
          setState(() {
            _isFirstCompletion = false;
            _previouslyEarnedXP = xpEarned;
          });
        }
      } else {
        // Check local storage
        final completedActions = await DatabaseService.getCompletedActions();
        if (completedActions.contains(actionId)) {
          // Check local XP storage
          final prefs = await SharedPreferences.getInstance();
          final localXP = prefs.getInt('action_xp_$actionId') ?? 75;
          setState(() {
            _isFirstCompletion = false;
            _previouslyEarnedXP = localXP;
          });
        }
      }
    } catch (e) {
      print('Error checking completion: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: OrionDesignSystem.backgroundGray,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF111827)),
          onPressed: () => _safePop(),
        ),
        title: Text(
          'Take Action',
          style: GoogleFonts.inter(
            color: const Color(0xFF111827),
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: const Color(0xFFE5E7EB),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Card
            Container(
              width: double.infinity,
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0052FF).withOpacity(0.08),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.rocket_launch_outlined,
                          color: Color(0xFF0052FF),
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.lessonTitle,
                              style: GoogleFonts.inter(
                                color: const Color(0xFF111827),
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                letterSpacing: -0.3,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _isFirstCompletion 
                                  ? 'Complete this action to earn gems!'
                                  : 'Practice mode - Reduced gems',
                              style: GoogleFonts.inter(
                                color: const Color(0xFF6B7280),
                                fontSize: 13,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Mission Card
            Container(
              width: double.infinity,
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
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF3B82F6).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.assignment,
                          color: Color(0xFF3B82F6),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Your Mission',
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF111827),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ..._getStepInstructions().asMap().entries.map((entry) {
                    int index = entry.key;
                    String instruction = entry.value;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: const Color(0xFF3B82F6),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                '${index + 1}',
                                style: GoogleFonts.inter(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              instruction,
                              style: GoogleFonts.inter(
                                fontSize: 15,
                                color: const Color(0xFF6B7280),
                                height: 1.5,
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

            const SizedBox(height: 20),

            // Action Button Section
            if (!_actionCompleted) ...[
              Container(
                width: double.infinity,
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
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF59E0B).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.explore,
                            color: Color(0xFFF59E0B),
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Ready to Explore?',
                            style: GoogleFonts.inter(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF111827),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFFFCD34D),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.info_outline,
                            color: Color(0xFFF59E0B),
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _getNavigationInstructions(),
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: const Color(0xFF92400E),
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => _navigateToAction(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF3B82F6),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.arrow_forward,
                              color: Colors.white,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _getActionButtonText(),
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Return Button (shown after navigation)
            if (_hasNavigatedAway && !_actionCompleted) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0052FF), Color(0xFF3B82F6)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0052FF).withOpacity(0.2),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.arrow_back,
                          color: Colors.white,
                          size: 24,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Return to Complete Quiz',
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tap the back button above to return and answer the quiz!',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.9),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],

            // Interactive Questions (shown after action is marked complete)
            if (_actionCompleted) ...[
              const SizedBox(height: 20),
              _buildInteractiveQuestions(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInteractiveQuestions() {
    return Container(
      width: double.infinity,
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
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.quiz,
                  color: Color(0xFF10B981),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Quick Quiz',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF111827),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            _getInteractiveQuestion(),
            style: GoogleFonts.inter(
              fontSize: 16,
              color: const Color(0xFF6B7280),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          _buildMCQOptions(),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _selectedAnswer != null ? () => _submitFinalAnswer() : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: _selectedAnswer != null 
                    ? const Color(0xFF10B981) 
                    : const Color(0xFF9CA3AF),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: Text(
                'Submit Answer',
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

  Widget _buildMCQOptions() {
    List<String> options = _getMCQOptions();
    return Column(
      children: options.asMap().entries.map((entry) {
        int index = entry.key;
        String option = entry.value;
        bool isSelected = _selectedAnswer == option;
        return Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 10),
          child: InkWell(
            onTap: () => setState(() => _selectedAnswer = option),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isSelected 
                    ? const Color(0xFF10B981).withOpacity(0.1)
                    : const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected 
                      ? const Color(0xFF10B981)
                      : const Color(0xFFE5E7EB),
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: isSelected 
                          ? const Color(0xFF10B981)
                          : Colors.transparent,
                      border: Border.all(
                        color: isSelected 
                            ? const Color(0xFF10B981)
                            : const Color(0xFF9CA3AF),
                        width: 2,
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: isSelected
                        ? const Icon(
                            Icons.check,
                            color: Colors.white,
                            size: 16,
                          )
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      option,
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        color: isSelected 
                            ? const Color(0xFF111827)
                            : const Color(0xFF6B7280),
                        fontWeight: isSelected 
                            ? FontWeight.w600
                            : FontWeight.w400,
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

  List<String> _getStepInstructions() {
    // Get actions for this lesson to show clear instructions
    final actions = LearningActionsContent.getActionsForLesson(widget.lessonId);
    
    if (actions.isEmpty) {
      return [
        'Tap the button below to open Trading',
        'Search for any stock and explore',
        'Find information related to this lesson',
        '⚠️ Remember to tap back to return and complete the quiz!',
      ];
    }
    
    // Use the first action's guidance as instructions
    final firstAction = actions.first;
    final guidance = firstAction.guidance ?? firstAction.description;
    
    // Parse guidance into clear numbered steps
    List<String> steps = [];
    
    // Try splitting by arrow (→)
    if (guidance.contains('→')) {
      steps = guidance.split('→').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
    } 
    // Or split by periods for sentences
    else {
      final sentences = guidance.split('.').map((s) => s.trim()).where((s) => s.isNotEmpty && s.length > 15).toList();
      if (sentences.length >= 2) {
        steps = sentences.take(4).toList();
      } else {
        // If it's one long sentence, try to break it logically
        if (guidance.contains(',')) {
          final parts = guidance.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty && s.length > 10).toList();
          steps = parts.take(4).toList();
        } else {
          steps = [guidance];
        }
      }
    }
    
    final instructions = <String>[
      'Tap the button below to open the Trading screen',
      ...steps.take(3), // Take first 3 meaningful steps
      '⚠️ IMPORTANT: After completing the action, tap the back button to return here and answer the quiz!',
    ];
    
    return instructions;
  }
  
  int _getInitialTab() {
    // Map lesson to initial tab (0=Market, 1=Portfolio, 2=Watchlist)
    final actions = LearningActionsContent.getActionsForLesson(widget.lessonId);
    if (actions.isEmpty) return 0;
    
    final metadata = actions.first.metadata ?? {};
    final tab = metadata['tab'] as String?;
    
    if (tab == 'portfolio') return 1;
    if (tab == 'watchlist') return 2;
    return 0; // Default to Market
  }
  
  String? _getInitialSymbol() {
    // Get symbol from first action if available
    final actions = LearningActionsContent.getActionsForLesson(widget.lessonId);
    if (actions.isEmpty) return null;
    
    return actions.first.symbol;
  }

  String _getNavigationInstructions() {
    // Get clear instructions from actions
    final actions = LearningActionsContent.getActionsForLesson(widget.lessonId);
    if (actions.isEmpty) {
      return 'You\'ll go to the Trading screen. Search stocks, check your portfolio, or explore the market!\n\n⚠️ Remember to tap the back button to return and complete the quiz!';
    }
    
    final firstAction = actions.first;
    final guidance = firstAction.guidance ?? firstAction.description;
    
    return '$guidance\n\n⚠️ Remember to tap the back button to return and complete the quiz!';
  }

  String _getActionButtonText() {
    // Get action title from learning actions
    final actions = LearningActionsContent.getActionsForLesson(widget.lessonId);
    if (actions.isNotEmpty) {
      return actions.first.title;
    }
    
    // Fallback to lesson-based text
    switch (widget.lessonId) {
      case 'what_is_stock': return '👀 Watch Apple Stock Price';
      case 'how_stock_prices_work': return '📊 Watch Price Change';
      case 'building_portfolio': return '📈 Check Your Portfolio';
      case 'market_cap': return '📊 Check Market Cap';
      case 'candlestick_patterns': return '🕯️ Look at Stock Chart';
      default: return '🚀 Go to Trading';
    }
  }

  String _getInteractiveQuestion() {
    // Get lesson ID - could be day number or lesson ID string
    String lessonIdStr = widget.lessonId;
    
    // Try to get actual lesson ID from pathway if it's a day number
    final dayNum = int.tryParse(lessonIdStr);
    if (dayNum != null && dayNum >= 1 && dayNum <= 30) {
      lessonIdStr = LearningPathway.getLessonIdForDay(dayNum) ?? lessonIdStr;
    }
    
    // Get actions for this lesson to use the follow-up question
    final actions = LearningActionsContent.getActionsForLesson(lessonIdStr);
    
    // Use the follow-up question from the first action, or create lesson-specific question
    if (actions.isNotEmpty && actions.first.followUpQuestion != null && actions.first.followUpQuestion!.isNotEmpty) {
      return actions.first.followUpQuestion!;
    }
    
    // Fallback to lesson-specific questions based on lesson ID
    switch (lessonIdStr) {
      case 'what_is_stock':
        return 'Did you see the price move? Was it going up or down?';
      case 'how_stock_prices_work':
        return 'Is Tesla up or down today? What percentage did it move?';
      case 'market_cap':
        return 'What is Apple\'s market cap? Is it a large company or small?';
      case 'building_portfolio':
        return 'What\'s your total portfolio value? Are you making money?';
      case 'candlestick_patterns':
        return 'Are there more green candles or red candles on Apple\'s chart?';
      case 'market_orders':
        return 'Did your order execute immediately? That\'s a market order!';
      case 'etfs_mutual_funds':
        return 'What is SPY? How is it different from a regular stock like AAPL?';
      case 'pe_ratio':
        return 'What is Apple\'s P/E ratio? Is it expensive or cheap?';
      case 'moving_averages':
        return 'Is Apple\'s price above or below its moving average? What does that mean?';
      case 'support_resistance':
        return 'Did you find a support or resistance level? Where was it?';
      case 'rsi_basics':
        return 'What RSI level did you find? Is the stock overbought or oversold?';
      case 'volume_analysis':
        return 'Is the volume higher or lower than usual? What does that tell you?';
      case 'risk_management':
        return 'What\'s your 2% risk amount based on your portfolio?';
      case 'position_sizing':
        return 'How many shares did you calculate based on your risk?';
      case 'risk_reward_ratios':
        return 'What\'s your risk/reward ratio for this trade? Is it good?';
      case 'portfolio_rebalancing':
        return 'What\'s your biggest portfolio holding? Should you rebalance?';
      case 'macd_indicator':
        return 'What does the MACD indicator show? Is it bullish or bearish?';
      case 'bollinger_bands':
        return 'Is the price near the upper or lower Bollinger Band? What does that mean?';
      case 'chart_patterns':
        return 'What chart patterns did you spot? What do they suggest?';
      case 'breakout_trading':
        return 'Did you find a stock breaking above resistance? What happened?';
      case 'gap_trading':
        return 'Did you spot a gap in the price chart? Was it a gap up or gap down?';
      case 'financial_statements':
        return 'What financial metric did you find? Revenue, profit, or debt?';
      case 'earnings_reports':
        return 'How did the earnings report perform? Did it beat expectations?';
      case 'sector_investing':
        return 'Which sector is performing best today? Why is that important?';
      case 'market_sentiment':
        return 'What\'s the overall market mood (fear or greed)?';
      case 'market_cycles':
        return 'What phase of the market cycle are we in? Bull or bear market?';
      case 'swing_trading':
        return 'What swing trading setup did you identify? Entry and exit points?';
      case 'day_trading_basics':
        return 'How many trades did you make today? What was your strategy?';
      case 'dividend_investing':
        return 'What dividend yield did you find? Is it good for income investing?';
      case 'growth_vs_value':
        return 'Is this stock a growth stock or value stock? How can you tell?';
      default:
        return 'What did you learn from this action? How will you apply it?';
    }
  }

  List<String> _getMCQOptions() {
    // Get lesson ID - could be day number or lesson ID string
    String lessonIdStr = widget.lessonId;
    
    // Try to get actual lesson ID from pathway if it's a day number
    final dayNum = int.tryParse(lessonIdStr);
    if (dayNum != null && dayNum >= 1 && dayNum <= 30) {
      lessonIdStr = LearningPathway.getLessonIdForDay(dayNum) ?? lessonIdStr;
    }
    
    // Return lesson-specific relevant options
    switch (lessonIdStr) {
      case 'what_is_stock':
        return [
          'Price was going up - I saw it rise!',
          'Price was going down - I saw it fall!',
          'Price stayed mostly the same',
          'I saw the price move but couldn\'t tell the direction',
        ];
      case 'how_stock_prices_work':
        return [
          'Tesla is up today (green percentage)',
          'Tesla is down today (red percentage)',
          'Tesla is flat (no change)',
          'I couldn\'t see the percentage change',
        ];
      case 'market_cap':
        return [
          'Apple has a very large market cap (trillions)',
          'Apple has a large market cap (hundreds of billions)',
          'Apple has a medium market cap (billions)',
          'I couldn\'t find the market cap number',
        ];
      case 'building_portfolio':
        return [
          'I\'m making money - portfolio is green!',
          'I have a loss - portfolio is red',
          'I\'m breaking even - no big changes',
          'I need to check my portfolio value',
        ];
      case 'candlestick_patterns':
        return [
          'More green candles - price is trending up!',
          'More red candles - price is trending down',
          'Mixed green and red - sideways movement',
          'I couldn\'t see the chart clearly',
        ];
      case 'market_orders':
        return [
          'Yes, my order executed immediately at market price!',
          'It took a moment but executed',
          'I\'m not sure if it executed',
          'I need to check my trade history',
        ];
      case 'etfs_mutual_funds':
        return [
          'SPY is an ETF that holds many stocks (500+)',
          'SPY is just like AAPL - a single company stock',
          'SPY is a mutual fund (different from ETF)',
          'I\'m not sure what SPY is',
        ];
      case 'pe_ratio':
        return [
          'P/E is low (under 20) - stock is cheap!',
          'P/E is high (over 30) - stock is expensive',
          'P/E is moderate (20-30) - reasonable price',
          'I couldn\'t find the P/E ratio',
        ];
      case 'moving_averages':
        return [
          'Price is above MA - bullish uptrend!',
          'Price is below MA - bearish downtrend',
          'Price is near MA - neutral/no clear trend',
          'I couldn\'t find the moving average',
        ];
      case 'support_resistance':
        return [
          'I found a support level - price bounces up from there',
          'I found a resistance level - price drops from there',
          'I found both support and resistance levels',
          'I couldn\'t identify any clear levels',
        ];
      case 'rsi_basics':
        return [
          'RSI above 70 - stock is overbought (might drop)',
          'RSI below 30 - stock is oversold (might rise)',
          'RSI between 30-70 - neutral zone',
          'I couldn\'t find the RSI indicator',
        ];
      case 'volume_analysis':
        return [
          'Volume is higher than usual - strong interest!',
          'Volume is lower than usual - weak interest',
          'Volume is about average - normal activity',
          'I couldn\'t determine the volume trend',
        ];
      case 'risk_management':
        return [
          'I calculated my 2% risk amount correctly',
          'My risk amount seems too high for my portfolio',
          'My risk amount seems too low',
          'I need to learn more about risk calculation',
        ];
      case 'position_sizing':
        return [
          'I calculated the right number of shares for my risk',
          'My position size is too large',
          'My position size is too small',
          'I need to review my position sizing strategy',
        ];
      case 'risk_reward_ratios':
        return [
          'Risk/reward is good (1:2 or better)',
          'Risk/reward is poor (less than 1:1)',
          'Risk/reward is moderate (around 1:1)',
          'I need to calculate the risk/reward ratio',
        ];
      case 'portfolio_rebalancing':
        return [
          'One stock is too big - I should rebalance',
          'My portfolio is well balanced',
          'I need more diversification',
          'I should review all my holdings',
        ];
      case 'macd_indicator':
        return [
          'MACD shows bullish signal - buy signal!',
          'MACD shows bearish signal - sell signal',
          'MACD is neutral - no clear signal',
          'I couldn\'t find the MACD indicator',
        ];
      case 'bollinger_bands':
        return [
          'Price near upper band - might be overbought',
          'Price near lower band - might be oversold',
          'Price in middle of bands - normal range',
          'I couldn\'t find Bollinger Bands',
        ];
      case 'chart_patterns':
        return [
          'I spotted a bullish pattern - price might go up!',
          'I spotted a bearish pattern - price might go down',
          'I saw a pattern but not sure what it means',
          'I couldn\'t identify any clear patterns',
        ];
      case 'breakout_trading':
        return [
          'Stock broke above resistance - bullish breakout!',
          'Stock broke below support - bearish breakdown',
          'No clear breakout yet - waiting',
          'I couldn\'t identify any breakout',
        ];
      case 'gap_trading':
        return [
          'I saw a gap up - bullish signal!',
          'I saw a gap down - bearish signal',
          'I saw a gap but need to analyze it more',
          'I couldn\'t spot any gaps',
        ];
      case 'financial_statements':
        return [
          'I found revenue/profit data - company is doing well',
          'I found debt data - need to check if it\'s manageable',
          'I found multiple financial metrics',
          'I couldn\'t find financial statement data',
        ];
      case 'earnings_reports':
        return [
          'Earnings beat expectations - good news!',
          'Earnings missed expectations - bad news',
          'Earnings met expectations - as expected',
          'I couldn\'t find earnings data',
        ];
      case 'sector_investing':
        return [
          'Technology sector is performing best',
          'Healthcare sector is performing best',
          'Finance sector is performing best',
          'Market is mixed across sectors',
        ];
      case 'market_sentiment':
        return [
          'Market shows fear - mostly red, investors worried',
          'Market shows greed - mostly green, investors optimistic',
          'Market is mixed - uncertain sentiment',
          'I couldn\'t determine the overall sentiment',
        ];
      case 'market_cycles':
        return [
          'We\'re in a bull market - prices rising',
          'We\'re in a bear market - prices falling',
          'Market is in a sideways cycle',
          'I couldn\'t determine the market cycle',
        ];
      case 'swing_trading':
        return [
          'I identified a good swing setup with clear entry/exit',
          'I found a potential swing but need to plan more',
          'No good swing opportunities right now',
          'I need to learn more about swing trading strategies',
        ];
      case 'day_trading_basics':
        return [
          'I made several trades using day trading strategies',
          'I made one or two trades today',
          'I watched but didn\'t trade today',
          'I need to learn more day trading techniques',
        ];
      case 'dividend_investing':
        return [
          'Dividend yield is good (above 3%) - great for income!',
          'Dividend yield is low (below 1%) - not good for income',
          'Dividend yield is moderate (1-3%) - okay',
          'I couldn\'t find dividend information',
        ];
      case 'growth_vs_value':
        return [
          'This is a growth stock - high P/E, fast growing',
          'This is a value stock - low P/E, undervalued',
          'It has characteristics of both',
          'I need more info to determine growth vs value',
        ];
      default:
        return [
          'I successfully completed the action and learned something new',
          'I completed the action but need more practice',
          'I tried but had some difficulty',
          'I need to review the lesson and try again',
        ];
    }
  }

  void _navigateToAction() async {
    // Mark that user started the action
    final actionId = 'action_lesson_${widget.lessonId}_started';
    await DatabaseService.saveCompletedAction(actionId);
    
    setState(() {
      _hasNavigatedAway = true;
    });

    // ALWAYS navigate to Trading screen (ProfessionalStocksScreen) from nav bar
    // Determine initial tab and symbol based on lesson
    final tab = _getInitialTab();
    final symbol = _getInitialSymbol();
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProfessionalStocksScreen(
          routeArguments: {
            'initialTab': tab,
            'symbol': symbol,
            'fromLearningAction': true, // Mark that this is from learning action
          },
        ),
      ),
    ).then((_) {
      // When user returns, show the quiz
      if (mounted) {
        setState(() {
          _actionCompleted = true;
        });
      }
    });
  }

  void _submitFinalAnswer() async {
    if (_selectedAnswer == null) return;

    // Calculate XP: Only give what they haven't earned yet
    const maxXP = 75;
    final xpToGive = _isFirstCompletion 
        ? maxXP 
        : (_previouslyEarnedXP < maxXP ? maxXP - _previouslyEarnedXP : 0);
    
    final gamification = Provider.of<GamificationService>(context, listen: false);
    
    if (xpToGive > 0) {
      gamification.addXP(xpToGive, 'interactive_quiz');
    }

    // Save action completion to database with XP earned
    final actionId = 'action_lesson_${widget.lessonId}_quiz';
    final totalXPEarned = _previouslyEarnedXP + xpToGive;
    await DatabaseService.saveCompletedActionWithXP(actionId, totalXPEarned);

    // Update learning progress
    await UserProgressService().trackLearningProgress(
      lessonId: widget.lessonId,
      lessonName: widget.lessonTitle,
      progressPercentage: 100,
    );

    // Show success message - NO XP banners for repeats
    if (mounted) {
      String message;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              if (_isFirstCompletion)
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0052FF).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.diamond, color: Color(0xFF0052FF), size: 18),
                )
              else
                const Icon(Icons.check_circle_outline, color: Color(0xFF10B981), size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _isFirstCompletion
                      ? 'Great job! +$xpToGive gems earned'
                      : 'Practice complete! Keep learning',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: _isFirstCompletion ? FontWeight.w600 : FontWeight.w500,
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
            side: BorderSide(
              color: _isFirstCompletion ? const Color(0xFF0052FF) : const Color(0xFFE5E7EB),
              width: _isFirstCompletion ? 1.5 : 1,
            ),
          ),
          margin: const EdgeInsets.all(16),
          duration: Duration(seconds: _isFirstCompletion ? 2 : 1),
        ),
      );

      // Wait a moment then navigate back to learning home
      await Future.delayed(const Duration(milliseconds: 800));
      _navigateToLearningHome();
    }
  }
  
  void _navigateToLearningHome() {
    // Navigate back to learning home screen
    // First, pop the action screen
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    }
    
    // Then check if we need to navigate to learning home
    // The action screen is typically opened from a lesson screen,
    // which is opened from DuolingoHomeScreen
    // So popping twice should get us back to DuolingoHomeScreen
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    }
  }

  void _safePop() {
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    } else {
      // If we can't pop, navigate to a safe screen
      Navigator.of(context).pushNamedAndRemoveUntil(
        '/',
        (route) => false,
      );
    }
  }

  @override
  void dispose() {
    super.dispose();
  }
}
