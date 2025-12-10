import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/learning_popup_service.dart';
import '../services/gamification_service.dart';
import '../models/learning_action.dart';

class LearningPopupWidget extends StatefulWidget {
  final Function(String answer)? onAnswerSubmitted;
  final Function()? onTimeExtended;
  final Function()? onPopupDismissed;

  const LearningPopupWidget({
    super.key,
    this.onAnswerSubmitted,
    this.onTimeExtended,
    this.onPopupDismissed,
  });

  @override
  State<LearningPopupWidget> createState() => _LearningPopupWidgetState();
}

class _LearningPopupWidgetState extends State<LearningPopupWidget>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late AnimationController _pulseController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _pulseAnimation;
  
  final TextEditingController _answerController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.elasticOut,
    ));
    
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    
    _slideController.forward();
    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _slideController.dispose();
    _pulseController.dispose();
    _answerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LearningPopupService>(
      builder: (context, popupService, child) {
        if (!popupService.isLearningMode || popupService.currentAction == null) {
          return const SizedBox.shrink();
        }

        return AnimatedBuilder(
          animation: _slideAnimation,
          builder: (context, child) {
            return SlideTransition(
              position: _slideAnimation,
              child: _buildPopupContent(popupService),
            );
          },
        );
      },
    );
  }

  Widget _buildPopupContent(LearningPopupService popupService) {
    final action = popupService.currentAction!;
    final timeRemaining = popupService.timeRemaining;
    final isMarketOpen = popupService.isMarketOpen;
    
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            spreadRadius: 2,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHeader(popupService, action, timeRemaining),
          _buildMarketStatus(popupService),
          _buildQuestionSection(popupService),
          _buildAnswerSection(popupService),
          _buildActionButtons(popupService),
        ],
      ),
    );
  }

  Widget _buildHeader(LearningPopupService popupService, LearningAction action, int timeRemaining) {
    final minutes = timeRemaining ~/ 60;
    final seconds = timeRemaining % 60;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF58CC02), Color(0xFF4CAF50)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _pulseAnimation.value,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        action.typeEmoji,
                        style: const TextStyle(fontSize: 24),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      action.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      action.description,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              _buildTimer(minutes, seconds),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimer(int minutes, int seconds) {
    final isUrgent = minutes < 1;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isUrgent ? Colors.red.withOpacity(0.2) : Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isUrgent ? Colors.red : Colors.white,
          width: 2,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.timer,
            color: isUrgent ? Colors.red : Colors.white,
            size: 16,
          ),
          const SizedBox(width: 4),
          Text(
            '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
            style: TextStyle(
              color: isUrgent ? Colors.red : Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMarketStatus(LearningPopupService popupService) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: popupService.getMarketStatusColor().withOpacity(0.1),
        border: Border(
          bottom: BorderSide(
            color: popupService.getMarketStatusColor().withOpacity(0.3),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            popupService.isMarketOpen ? Icons.trending_up : Icons.schedule,
            color: popupService.getMarketStatusColor(),
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              popupService.getMarketStatusMessage(),
              style: TextStyle(
                color: popupService.getMarketStatusColor(),
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionSection(LearningPopupService popupService) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.quiz, color: Color(0xFF58CC02), size: 20),
              const SizedBox(width: 8),
              const Text(
                'Learning Question',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF58CC02),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF58CC02).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFF58CC02).withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Text(
              popupService.currentQuestion ?? 'What did you observe?',
              style: const TextStyle(
                fontSize: 16,
                height: 1.4,
                color: Colors.black87,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            popupService.getActionGuidance(),
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnswerSection(LearningPopupService popupService) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Your Answer',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _answerController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Share what you observed or learned...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF58CC02), width: 2),
              ),
              filled: true,
              fillColor: Colors.grey[50],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(LearningPopupService popupService) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () {
                popupService.extendTime(2); // Add 2 minutes
                widget.onTimeExtended?.call();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('⏰ Added 2 more minutes!'),
                    backgroundColor: Color(0xFF58CC02),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                side: const BorderSide(color: Color(0xFF58CC02)),
              ),
              child: const Text(
                'More Time ⏰',
                style: TextStyle(
                  color: Color(0xFF58CC02),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : () => _submitAnswer(popupService),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF58CC02),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      'Submit Answer ✅',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submitAnswer(LearningPopupService popupService) async {
    if (_answerController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please write an answer before submitting!'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    // Give XP reward
    final gamificationService = Provider.of<GamificationService>(context, listen: false);
    gamificationService.addXP(popupService.currentAction!.xpReward, 'learning_popup');

    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('🎉 Great answer! +${popupService.currentAction!.xpReward} XP'),
        backgroundColor: const Color(0xFF58CC02),
      ),
    );

    // Call callback
    widget.onAnswerSubmitted?.call(_answerController.text.trim());

    // Stop learning mode
    popupService.stopLearningMode();

    setState(() {
      _isSubmitting = false;
    });
  }
}
