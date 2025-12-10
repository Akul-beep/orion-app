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
import '../../data/simple_learning_actions.dart';
import '../../data/smart_learning_actions.dart';

class SimpleActionsScreen extends StatefulWidget {
  final String lessonId;
  final String lessonContent;
  final String lessonTitle;

  const SimpleActionsScreen({
    super.key,
    required this.lessonId,
    required this.lessonContent,
    required this.lessonTitle,
  });

  @override
  State<SimpleActionsScreen> createState() => _SimpleActionsScreenState();
}

class _SimpleActionsScreenState extends State<SimpleActionsScreen> {
  late LearningActionService _actionService;
  int _currentStep = 0; // 0: Learn, 1: Act, 2: Reflect
  int _actionsCompleted = 0;
  int _totalXPEarned = 0;

  @override
  void initState() {
    super.initState();
    _actionService = LearningActionService();
    _actionService.generateActionsFromLesson(widget.lessonId, widget.lessonContent);
    
    // Track screen visit
    WidgetsBinding.instance.addPostFrameCallback((_) {
      UserProgressService().trackScreenVisit(
        screenName: 'SimpleActionsScreen',
        screenType: 'detail',
        metadata: {'lesson_id': widget.lessonId, 'lesson_title': widget.lessonTitle},
      );
      
      UserProgressService().trackLearningProgress(
        lessonId: widget.lessonId,
        lessonName: widget.lessonTitle,
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
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.lessonTitle,
          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        actions: [
          Consumer<GamificationService>(
            builder: (context, gamification, child) {
              return Container(
                margin: const EdgeInsets.only(right: 16),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF58CC02).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.star, color: Color(0xFF58CC02), size: 16),
                    const SizedBox(width: 4),
                    Text(
                      '${gamification.xp} XP',
                      style: const TextStyle(
                        color: Color(0xFF58CC02),
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
      body: Consumer<LearningActionService>(
        builder: (context, actionService, child) {
          return Column(
            children: [
              // Simple Progress Steps
              _buildSimpleProgress(),
              
              // Content based on current step
              Expanded(
                child: _currentStep == 0 
                    ? _buildLearnStep()
                    : _currentStep == 1 
                        ? _buildActStep()
                        : _buildReflectStep(),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSimpleProgress() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          _buildSimpleStep(0, '📚', 'Learn', _currentStep >= 0),
          _buildSimpleStep(1, '🎯', 'Act', _currentStep >= 1),
          _buildSimpleStep(2, '✅', 'Done', _currentStep >= 2),
        ],
      ),
    );
  }

  Widget _buildSimpleStep(int step, String emoji, String title, bool isActive) {
    return Expanded(
      child: Column(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: isActive ? const Color(0xFF58CC02) : Colors.grey[300],
              shape: BoxShape.circle,
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
              color: isActive ? const Color(0xFF58CC02) : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLearnStep() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF58CC02),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '📚 What You Learned',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  widget.lessonContent,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                    height: 1.5,
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
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF58CC02),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
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
    );
  }

  Widget _buildActStep() {
    final actions = SmartLearningActions.getActionsForLesson(widget.lessonId);
    
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '🎯 Quick Practice',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
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
                return _buildSimpleActionCard(action, index);
              },
            ),
          ),
          if (_actionsCompleted > 0) ...[
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  setState(() {
                    _currentStep = 2;
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF58CC02),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'All Done! ✅',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSimpleActionCard(LearningAction action, int index) {
    final isCompleted = _actionsCompleted > index;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isCompleted ? const Color(0xFF58CC02).withOpacity(0.1) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCompleted ? const Color(0xFF58CC02) : Colors.grey[300]!,
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isCompleted ? const Color(0xFF58CC02) : Colors.grey[300],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Center(
                  child: Text(
                    isCompleted ? '✅' : action.typeEmoji,
                    style: const TextStyle(fontSize: 20),
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

  Widget _buildReflectStep() {
    final prompts = SimpleLearningActions.getSimpleReflectionPrompts();
    
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '✅ Almost Done!',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          const Text(
            'Just one quick question:',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFF7F9FC),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF58CC02).withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  prompts.first, // Just use the first question
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Type your answer here...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF58CC02)),
                    ),
                    contentPadding: const EdgeInsets.all(16),
                  ),
                  maxLines: 2,
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
                final actionId = 'reflection_lesson_${widget.lessonId}';
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
                  gamificationService.addXP(xpAmount, isRepeat ? 'reflection_repeat' : 'reflection');
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
    } else {
      // Action not verified - use smart handler to guide user
      await SmartActionHandler.executeAction(action, context);
    }
  }
}
