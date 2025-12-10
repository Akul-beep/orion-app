import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/learning_action.dart';
import '../models/stock_quote.dart';
import '../data/learning_actions_content.dart';
import '../data/simple_learning_actions.dart';
import '../data/smart_learning_actions.dart';
import 'paper_trading_service.dart';
import 'gamification_service.dart';
import 'learning_action_verifier.dart';

class LearningActionService extends ChangeNotifier {
  static final LearningActionService _instance = LearningActionService._internal();
  factory LearningActionService() => _instance;
  LearningActionService._internal();

  List<LearningAction> _availableActions = [];
  List<LearningAction> _completedActions = [];

  List<LearningAction> get availableActions => _availableActions;
  List<LearningAction> get completedActions => _completedActions;

  // Generate actionable insights based on lesson content (SIMPLE like Duolingo)
  List<LearningAction> generateActionsFromLesson(String lessonId, String lessonContent) {
    _availableActions.clear();
    
    // Get smart actions (MAX 2 per lesson) that guide users to specific places
    _availableActions.addAll(SmartLearningActions.getActionsForLesson(lessonId));
    
    notifyListeners();
    return _availableActions;
  }

  // Add dynamic actions based on lesson content
  void _addDynamicActions(String lessonContent) {
    final content = lessonContent.toLowerCase();
    
    // Add Apple-specific actions if mentioned
    if (content.contains('apple') || content.contains('aapl')) {
      _availableActions.addAll([
        LearningAction(
          id: 'watch_aapl_dynamic',
          title: '🍎 Watch Apple Live',
          description: 'Monitor AAPL price for 3 minutes and see how it moves',
          type: ActionType.watch,
          symbol: 'AAPL',
          xpReward: 30,
          timeRequired: 3,
        ),
        LearningAction(
          id: 'trade_aapl_dynamic',
          title: '💰 Trade Apple Stock',
          description: 'Make a small trade with AAPL using your virtual money',
          type: ActionType.trade,
          symbol: 'AAPL',
          xpReward: 50,
          timeRequired: 2,
        ),
      ]);
    }
    
    // Add Tesla-specific actions if mentioned
    if (content.contains('tesla') || content.contains('tsla')) {
      _availableActions.addAll([
        LearningAction(
          id: 'watch_tsla_dynamic',
          title: '⚡ Watch Tesla Live',
          description: 'Monitor TSLA price for 3 minutes - it moves fast!',
          type: ActionType.watch,
          symbol: 'TSLA',
          xpReward: 35,
          timeRequired: 3,
        ),
        LearningAction(
          id: 'trade_tsla_dynamic',
          title: '🚗 Trade Tesla Stock',
          description: 'Make a small trade with TSLA - high volatility!',
          type: ActionType.trade,
          symbol: 'TSLA',
          xpReward: 60,
          timeRequired: 2,
        ),
      ]);
    }
    
    // Add market-specific actions
    if (content.contains('market') || content.contains('trend')) {
      _availableActions.addAll([
        LearningAction(
          id: 'watch_market_dynamic',
          title: '📊 Watch Market Overview',
          description: 'Check S&P 500, NASDAQ, and DOW for 3 minutes',
          type: ActionType.watch,
          symbol: null,
          xpReward: 40,
          timeRequired: 3,
        ),
      ]);
    }
  }

  // Complete an action and give rewards (with verification)
  Future<void> completeAction(String actionId, BuildContext context) async {
    final action = _availableActions.firstWhere((a) => a.id == actionId);
    
    // Verify action was actually completed via paper trading
    final verified = await LearningActionVerifier.completeActionWithVerification(
      action,
      context,
    );
    
    if (!verified) {
      // Action not verified - user needs to complete it first
      return;
    }
    
    // Move to completed
    _availableActions.remove(action);
    _completedActions.add(action.copyWith(completedAt: DateTime.now()));
    
    notifyListeners();
  }
  
  // Check if action can be auto-completed (user already did it)
  Future<bool> canAutoComplete(String actionId, BuildContext context) async {
    final action = _availableActions.firstWhere((a) => a.id == actionId);
    return await LearningActionVerifier.canAutoComplete(action, context);
  }

  // Generate reflection prompts based on completed actions (SIMPLE like Duolingo)
  List<String> generateReflectionPrompts() {
    return SmartLearningActions.getSimpleReflectionPrompts();
  }

  // Get next recommended action based on user progress
  LearningAction? getNextRecommendedAction() {
    if (_availableActions.isEmpty) return null;
    
    // Prioritize by XP reward and time required
    _availableActions.sort((a, b) {
      final aScore = a.xpReward / a.timeRequired;
      final bScore = b.xpReward / b.timeRequired;
      return bScore.compareTo(aScore);
    });
    
    return _availableActions.first;
  }

  // Clear completed actions (daily reset)
  void resetDailyActions() {
    _completedActions.clear();
    notifyListeners();
  }
}
