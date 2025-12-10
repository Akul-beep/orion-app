import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/learning_action_service.dart';
import '../../services/gamification_service.dart';
import '../../services/paper_trading_service.dart';
import '../../services/user_progress_service.dart';
import '../../models/learning_action.dart';

class LearningActionsScreen extends StatefulWidget {
  final String lessonId;
  final String lessonContent;

  const LearningActionsScreen({
    super.key,
    required this.lessonId,
    required this.lessonContent,
  });

  @override
  State<LearningActionsScreen> createState() => _LearningActionsScreenState();
}

class _LearningActionsScreenState extends State<LearningActionsScreen> {
  late LearningActionService _actionService;
  int _currentStep = 0; // 0: Learn, 1: Act, 2: Reflect
  final Set<String> _processingActions = {}; // Track actions being processed
  bool _isNavigating = false; // Prevent multiple navigations

  @override
  void initState() {
    super.initState();
    _actionService = LearningActionService();
    _actionService.generateActionsFromLesson(widget.lessonId, widget.lessonContent);
    
    // Track screen visit
    WidgetsBinding.instance.addPostFrameCallback((_) {
      UserProgressService().trackScreenVisit(
        screenName: 'LearningActionsScreen',
        screenType: 'detail',
        metadata: {'lesson_id': widget.lessonId},
      );
      
      UserProgressService().trackLearningProgress(
        lessonId: widget.lessonId,
        lessonName: 'Learning Action',
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
        title: const Text(
          'Your Learning Journey',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
      body: Consumer<LearningActionService>(
        builder: (context, actionService, child) {
          return Column(
            children: [
              // Progress Steps
              _buildProgressSteps(),
              
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

  Widget _buildProgressSteps() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          _buildStep(0, '📚', 'Learn', _currentStep >= 0),
          _buildStepConnector(),
          _buildStep(1, '🎯', 'Act', _currentStep >= 1),
          _buildStepConnector(),
          _buildStep(2, '🤔', 'Reflect', _currentStep >= 2),
        ],
      ),
    );
  }

  Widget _buildStep(int step, String emoji, String title, bool isActive) {
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

  Widget _buildStepConnector() {
    return Container(
      height: 2,
      width: 20,
      color: Colors.grey[300],
    );
  }

  Widget _buildLearnStep() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '📚 What You Just Learned',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFF7F9FC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF58CC02), width: 2),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Lesson Summary',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Text(
                  widget.lessonContent,
                  style: const TextStyle(fontSize: 16, height: 1.5),
                ),
                const SizedBox(height: 15),
                Row(
                  children: [
                    const Icon(Icons.check_circle, color: Color(0xFF58CC02)),
                    const SizedBox(width: 8),
                    const Text(
                      'Ready to apply this knowledge?',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
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
                'Let\'s Apply This Knowledge! 🎯',
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
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '🎯 Take Action',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          const Text(
            'Apply what you learned with these hands-on activities:',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: ListView.builder(
              itemCount: _actionService.availableActions.length,
              itemBuilder: (context, index) {
                final action = _actionService.availableActions[index];
                return _buildActionCard(action);
              },
            ),
          ),
          if (_actionService.completedActions.isNotEmpty) ...[
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
                  'Time to Reflect 🤔',
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

  Widget _buildActionCard(LearningAction action) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                action.typeEmoji,
                style: const TextStyle(fontSize: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      action.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
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
          const SizedBox(height: 12),
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
              ElevatedButton(
                onPressed: _processingActions.contains(action.id) || _isNavigating
                    ? null
                    : () => _completeAction(action),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _processingActions.contains(action.id) || _isNavigating
                      ? Colors.grey
                      : const Color(0xFF58CC02),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _processingActions.contains(action.id)
                    ? const SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        'Do It!',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
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
    final reflectionPrompts = _actionService.generateReflectionPrompts();
    
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '🤔 Reflect on Your Learning',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          const Text(
            'Think about what you learned and how you applied it:',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: ListView.builder(
              itemCount: reflectionPrompts.length,
              itemBuilder: (context, index) {
                final prompt = reflectionPrompts[index];
                return _buildReflectionCard(prompt, index);
              },
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                // Give bonus XP for completing the full cycle
                final gamificationService = Provider.of<GamificationService>(context, listen: false);
                gamificationService.addXP(50, 'reflection');
                
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('🎉 Learning cycle completed! +50 bonus XP'),
                    backgroundColor: Color(0xFF58CC02),
                  ),
                );
                
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF58CC02),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Complete Learning Cycle 🎉',
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

  Widget _buildReflectionCard(String prompt, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F9FC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF58CC02).withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: const BoxDecoration(
                  color: Color(0xFF58CC02),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  prompt,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            decoration: InputDecoration(
              hintText: 'Write your thoughts here...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFF58CC02)),
              ),
            ),
            maxLines: 3,
          ),
        ],
      ),
    );
  }

  Future<void> _completeAction(LearningAction action) async {
    // Prevent multiple clicks
    if (_processingActions.contains(action.id) || _isNavigating) {
      return;
    }

    setState(() {
      _processingActions.add(action.id);
    });

    try {
      // Complete action (this may trigger navigation)
      await _actionService.completeAction(action.id, context);
      
      setState(() {
        _processingActions.remove(action.id);
      });
    } catch (e) {
      print('❌ Error completing action: $e');
      setState(() {
        _processingActions.remove(action.id);
      });
    }
  }
}
