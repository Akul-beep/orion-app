import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/learning_action_service.dart';
import '../../services/gamification_service.dart';
import '../../services/smart_action_handler.dart';
import '../../services/learning_action_verifier.dart';
import '../../services/user_progress_service.dart';
import '../../services/daily_goals_service.dart';
import '../../services/database_service.dart';
import '../../models/learning_action.dart';
import '../../data/smart_learning_actions.dart';

class PerfectGenZActionsScreen extends StatefulWidget {
  final String lessonId;
  final String lessonContent;
  final String lessonTitle;

  const PerfectGenZActionsScreen({
    super.key,
    required this.lessonId,
    required this.lessonContent,
    required this.lessonTitle,
  });

  @override
  State<PerfectGenZActionsScreen> createState() => _PerfectGenZActionsScreenState();
}

class _PerfectGenZActionsScreenState extends State<PerfectGenZActionsScreen>
    with TickerProviderStateMixin {
  late LearningActionService _actionService;
  int _currentStep = 0; // 0: Learn, 1: Act, 2: Done
  int _actionsCompleted = 0;
  int _totalXPEarned = 0;
  
  late AnimationController _bounceController;
  late AnimationController _pulseController;
  late Animation<double> _bounceAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _actionService = LearningActionService();
    _actionService.generateActionsFromLesson(widget.lessonId, widget.lessonContent);
    
    _bounceController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    // Track screen visit
    WidgetsBinding.instance.addPostFrameCallback((_) {
      UserProgressService().trackScreenVisit(
        screenName: 'PerfectGenZActionsScreen',
        screenType: 'detail',
        metadata: {'lesson_id': widget.lessonId, 'lesson_title': widget.lessonTitle},
      );
      
      UserProgressService().trackLearningProgress(
        lessonId: widget.lessonId,
        lessonName: widget.lessonTitle,
        progressPercentage: 0,
      );
    });
    
    _bounceAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _bounceController, curve: Curves.elasticOut),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    
    _bounceController.forward();
    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _bounceController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Consumer<LearningActionService>(
          builder: (context, actionService, child) {
            return Column(
              children: [
                _buildGenZHeader(),
                Expanded(
                  child: _currentStep == 0 
                      ? _buildLearnStep()
                      : _currentStep == 1 
                          ? _buildActStep()
                          : _buildDoneStep(),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildGenZHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF58CC02), Color(0xFF4CAF50)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF58CC02).withOpacity(0.3),
            spreadRadius: 2,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.lessonTitle,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Let\'s practice what you learned!',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              Consumer<GamificationService>(
                builder: (context, gamification, child) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.star, color: Colors.white, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          '${gamification.xp} XP',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildProgressIndicator(),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Row(
      children: [
        _buildProgressStep(0, '📚', 'Learn', _currentStep >= 0),
        _buildProgressConnector(),
        _buildProgressStep(1, '🎯', 'Practice', _currentStep >= 1),
        _buildProgressConnector(),
        _buildProgressStep(2, '✅', 'Done', _currentStep >= 2),
      ],
    );
  }

  Widget _buildProgressStep(int step, String emoji, String title, bool isActive) {
    return Expanded(
      child: AnimatedBuilder(
        animation: isActive ? _pulseAnimation : const AlwaysStoppedAnimation(1.0),
        builder: (context, child) {
          return Transform.scale(
            scale: isActive ? _pulseAnimation.value : 1.0,
            child: Column(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: isActive ? Colors.white : Colors.white.withOpacity(0.3),
                    shape: BoxShape.circle,
                    boxShadow: isActive ? [
                      BoxShadow(
                        color: Colors.white.withOpacity(0.5),
                        spreadRadius: 2,
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ] : null,
                  ),
                  child: Center(
                    child: Text(
                      emoji,
                      style: const TextStyle(fontSize: 24),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                    color: Colors.white,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildProgressConnector() {
    return Container(
      height: 2,
      width: 20,
      color: Colors.white.withOpacity(0.5),
    );
  }

  Widget _buildLearnStep() {
    return AnimatedBuilder(
      animation: _bounceAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _bounceAnimation.value,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7F9FC),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFF58CC02), width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF58CC02).withOpacity(0.1),
                        spreadRadius: 2,
                        blurRadius: 8,
                        offset: const Offset(0, 4),
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
                              color: const Color(0xFF58CC02),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.lightbulb, color: Colors.white, size: 24),
                          ),
                          const SizedBox(width: 16),
                          const Expanded(
                            child: Text(
                              'What You Just Learned',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF58CC02),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        widget.lessonContent,
                        style: const TextStyle(
                          fontSize: 16,
                          height: 1.6,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF58CC02).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.touch_app, color: Color(0xFF58CC02), size: 20),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Ready to practice with real trading? Let\'s go! 🚀',
                                style: TextStyle(
                                  color: Color(0xFF58CC02),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _currentStep = 1;
                      });
                      _bounceController.reset();
                      _bounceController.forward();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF58CC02),
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 4,
                    ),
                    child: const Text(
                      'Let\'s Practice! 🎯',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildActStep() {
    final actions = SmartLearningActions.getActionsForLesson(widget.lessonId);
    
    return AnimatedBuilder(
      animation: _bounceAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _bounceAnimation.value,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      '🎯 Practice Time',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF58CC02).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '$_actionsCompleted/${actions.length} done',
                        style: const TextStyle(
                          color: Color(0xFF58CC02),
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                const Text(
                  'Just 2 quick actions to practice what you learned:',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: ListView.builder(
                    itemCount: actions.length,
                    itemBuilder: (context, index) {
                      final action = actions[index];
                      return _buildGenZActionCard(action, index);
                    },
                  ),
                ),
                if (_actionsCompleted > 0) ...[
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF58CC02), Color(0xFF4CAF50)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.celebration, color: Colors.white, size: 24),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Amazing progress! 🔥',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                'You\'ve earned $_totalXPEarned XP so far!',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _currentStep = 2;
                            });
                            _bounceController.reset();
                            _bounceController.forward();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            'Finish! ✅',
                            style: TextStyle(
                              color: Color(0xFF58CC02),
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildGenZActionCard(LearningAction action, int index) {
    final isCompleted = _actionsCompleted > index;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isCompleted ? const Color(0xFF58CC02).withOpacity(0.1) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isCompleted ? const Color(0xFF58CC02) : Colors.grey[200]!,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 6,
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
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: isCompleted ? const Color(0xFF58CC02) : Colors.grey[300],
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Center(
                  child: Text(
                    isCompleted ? '✅' : action.typeEmoji,
                    style: const TextStyle(fontSize: 24),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      action.title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isCompleted ? const Color(0xFF58CC02) : Colors.black,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      action.guidance ?? action.description,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black87,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF58CC02).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '+${action.xpReward} XP',
                  style: const TextStyle(
                    color: Color(0xFF58CC02),
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${action.timeRequired} min',
                  style: const TextStyle(
                    color: Colors.blue,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              const Spacer(),
              if (!isCompleted)
                ElevatedButton(
                  onPressed: () => _completeAction(action),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF58CC02),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  child: const Text(
                    'Do It!',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDoneStep() {
    return AnimatedBuilder(
      animation: _bounceAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _bounceAnimation.value,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF58CC02), Color(0xFF4CAF50)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF58CC02).withOpacity(0.3),
                        spreadRadius: 2,
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.celebration, color: Colors.white, size: 60),
                      const SizedBox(height: 16),
                      const Text(
                        'Lesson Complete! 🎉',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'You earned $_totalXPEarned XP and completed $_actionsCompleted actions!',
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Column(
                          children: [
                            Text(
                              'How did you feel about your trading decisions?',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            SizedBox(height: 12),
                            TextField(
                              decoration: InputDecoration(
                                hintText: 'Type your thoughts here...',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.all(Radius.circular(8)),
                                ),
                                filled: true,
                                fillColor: Colors.white,
                              ),
                              maxLines: 2,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      // Check if this is a repeat attempt
                      final actionId = 'genz_lesson_${widget.lessonId}';
                      final completedActions = await DatabaseService.getCompletedActions();
                      final isRepeat = completedActions.contains(actionId);
                      
                      // Calculate XP: Full for first, reduced for repeats
                      final baseXP = 50;
                      final xpAmount = isRepeat 
                          ? (baseXP * 0.1).round() // 10% for practice
                          : baseXP; // Full XP for first completion
                      
                      // Only award XP if first completion or if repeat XP > 0
                      if (!isRepeat || xpAmount > 0) {
                        final gamificationService = Provider.of<GamificationService>(context, listen: false);
                        gamificationService.addXP(xpAmount, isRepeat ? 'lesson_repeat' : 'lesson_complete');
                      }
                      
                      // Track lesson completion in daily goals (only first completion)
                      if (!isRepeat) {
                        try {
                          DailyGoalsService().trackLesson();
                        } catch (e) {
                          print('Error tracking lesson: $e');
                        }
                      }
                      
                      // Save completion
                      await DatabaseService.saveCompletedAction(actionId);
                      if (xpAmount > 0) {
                        await DatabaseService.saveCompletedActionWithXP(actionId, xpAmount);
                      }
                      
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            isRepeat 
                                ? '✅ Practice complete! +$xpAmount XP (Practice mode)'
                                : '🎉 Lesson complete! +$xpAmount bonus XP',
                          ),
                          backgroundColor: isRepeat ? Colors.blue : const Color(0xFF58CC02),
                        ),
                      );
                      
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF58CC02),
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 4,
                    ),
                    child: const Text(
                      'Complete Lesson 🎉',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _completeAction(LearningAction action) async {
    // Verify and complete action with badge unlocking
    final verified = await LearningActionVerifier.completeActionWithVerification(action, context);
    
    if (verified) {
      setState(() {
        _actionsCompleted++;
        _totalXPEarned += action.xpReward;
      });
      _bounceController.reset();
      _bounceController.forward();
    } else {
      // Action not verified - use smart handler to guide user
      await SmartActionHandler.executeAction(action, context);
    }
  }
}
