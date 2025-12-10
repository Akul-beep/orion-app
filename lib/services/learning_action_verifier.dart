import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import '../models/learning_action.dart';
import '../services/paper_trading_service.dart';
import '../services/gamification_service.dart';
import '../services/database_service.dart';
import '../services/notification_manager.dart';

/// Service to verify learning actions are actually completed via paper trading
class LearningActionVerifier {
  /// Check if a learning action has been completed based on paper trading activity
  static Future<bool> verifyActionCompletion(
    LearningAction action,
    BuildContext context,
  ) async {
    final tradingService = Provider.of<PaperTradingService>(context, listen: false);
    
    switch (action.type) {
      case ActionType.trade:
        return _verifyTradeAction(action, tradingService);
      case ActionType.analyze:
        return _verifyAnalyzeAction(action, tradingService);
      case ActionType.watch:
        return _verifyWatchAction(action, tradingService);
      case ActionType.research:
        return _verifyResearchAction(action, tradingService);
      case ActionType.reflect:
        // Reflection actions are always completable (user just needs to answer)
        return true;
    }
  }

  /// Verify trade actions - check if user actually made a trade
  static bool _verifyTradeAction(LearningAction action, PaperTradingService trading) {
    final recentTrades = trading.recentTrades;
    
    // Check if action specifies a symbol
    if (action.symbol != null) {
      // Check if user traded the specific symbol recently (within last hour)
      final now = DateTime.now();
      final oneHourAgo = now.subtract(const Duration(hours: 1));
      
      final hasTradedSymbol = recentTrades.any((trade) =>
        trade.symbol.toUpperCase() == action.symbol!.toUpperCase() &&
        trade.timestamp.isAfter(oneHourAgo)
      );
      
      return hasTradedSymbol;
    } else {
      // Any trade counts
      final now = DateTime.now();
      final oneHourAgo = now.subtract(const Duration(hours: 1));
      
      return recentTrades.any((trade) => trade.timestamp.isAfter(oneHourAgo));
    }
  }

  /// Verify analyze actions - check if user has positions or viewed stocks
  static bool _verifyAnalyzeAction(LearningAction action, PaperTradingService trading) {
    // Special check for "set_stop_loss" action
    if (action.id == 'set_stop_loss' || action.id.contains('stop_loss')) {
      // Check if user has any positions with stop loss set
      final hasStopLoss = trading.positions.any((pos) => pos.stopLoss != null);
      if (hasStopLoss) {
        return true;
      }
      
      // Or check recent trades with stop loss
      final now = DateTime.now();
      final oneHourAgo = now.subtract(const Duration(hours: 1));
      final recentTradeWithStopLoss = trading.recentTrades.any((trade) =>
        trade.stopLoss != null && trade.timestamp.isAfter(oneHourAgo)
      );
      return recentTradeWithStopLoss;
    }
    
    // Special check for "set_take_profit" action
    if (action.id == 'set_take_profit' || action.id.contains('take_profit')) {
      // Check if user has any positions with take profit set
      final hasTakeProfit = trading.positions.any((pos) => pos.takeProfit != null);
      if (hasTakeProfit) {
        return true;
      }
      
      // Or check recent trades with take profit
      final now = DateTime.now();
      final oneHourAgo = now.subtract(const Duration(hours: 1));
      final recentTradeWithTakeProfit = trading.recentTrades.any((trade) =>
        trade.takeProfit != null && trade.timestamp.isAfter(oneHourAgo)
      );
      return recentTradeWithTakeProfit;
    }
    
    // If user has any positions, they've analyzed stocks
    if (trading.positions.isNotEmpty) {
      return true;
    }
    
    // Or if they've made trades (which requires analysis)
    if (trading.recentTrades.isNotEmpty) {
      return true;
    }
    
    return false;
  }

  /// Verify watch actions - check if user has viewed stocks or has positions
  static bool _verifyWatchAction(LearningAction action, PaperTradingService trading) {
    // If user has positions, they've watched stocks
    if (trading.positions.isNotEmpty) {
      return true;
    }
    
    // Or if they've made any trades (which requires watching)
    if (trading.recentTrades.isNotEmpty) {
      return true;
    }
    
    // For symbol-specific watch actions, check if they have that position
    if (action.symbol != null) {
      return trading.positions.any((pos) =>
        pos.symbol.toUpperCase() == action.symbol!.toUpperCase()
      );
    }
    
    return false;
  }

  /// Verify research actions - check if user has positions or trades
  static bool _verifyResearchAction(LearningAction action, PaperTradingService trading) {
    // If user has positions, they've done research
    if (trading.positions.isNotEmpty) {
      return true;
    }
    
    // Or if they've made trades (which requires research)
    if (trading.recentTrades.isNotEmpty) {
      return true;
    }
    
    return false;
  }

  /// Complete action with verification and reward XP
  static Future<bool> completeActionWithVerification(
    LearningAction action,
    BuildContext context,
  ) async {
    // Verify the action was actually completed
    final isVerified = await verifyActionCompletion(action, context);
    
    if (!isVerified) {
      // Show message that action needs to be completed first
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _getVerificationMessage(action),
          ),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 3),
          action: SnackBarAction(
            label: 'Go',
            textColor: Colors.white,
            onPressed: () {
              // Navigate to appropriate screen based on action type
              _navigateToActionScreen(action, context);
            },
          ),
        ),
      );
      return false;
    }
    
    // Check if action was already completed (XP farming prevention)
    final completedActions = await DatabaseService.getCompletedActions();
    final isRepeat = completedActions.contains(action.id);
    
    // Calculate XP: Full XP for first completion, reduced for repeats
    final baseXP = action.xpReward;
    final xpAmount = isRepeat 
        ? (baseXP * 0.1).round().clamp(1, baseXP) // 10% XP for repeats (min 1, max base)
        : baseXP; // Full XP for first completion
    
    // Action is verified - give reward
    final gamificationService = Provider.of<GamificationService>(context, listen: false);
    if (!isRepeat || xpAmount > 0) {
      gamificationService.addXP(xpAmount, isRepeat ? 'verified_action_repeat' : 'verified_action');
    }
    
    // Unlock action-specific badges (only on first completion)
    String? badgeName;
    if (!isRepeat) {
      if (action.id == 'set_stop_loss' || action.id.contains('stop_loss')) {
        badgeName = 'Stop Loss Master';
        gamificationService.unlockBadge(badgeName);
      } else if (action.id == 'set_take_profit' || action.id.contains('take_profit')) {
        badgeName = 'Take Profit Master';
        gamificationService.unlockBadge(badgeName);
      } else if (action.id == 'first_virtual_trade') {
        badgeName = 'First Trader';
        gamificationService.unlockBadge(badgeName);
      } else if (action.id == 'diversify_portfolio') {
        badgeName = 'Diversification Expert';
        gamificationService.unlockBadge(badgeName);
      } else if (action.id == 'calculate_position_size') {
        badgeName = 'Risk Calculator';
        gamificationService.unlockBadge(badgeName);
      }
    }
    
    // Check for general achievements
    gamificationService.checkAchievements();
    
    // Mark as completed in database
    await DatabaseService.saveCompletedAction(action.id);
    if (xpAmount > 0) {
      await DatabaseService.saveCompletedActionWithXP(action.id, xpAmount);
    }
    
    // Add notification for badge unlock (only first completion)
    if (badgeName != null && !isRepeat) {
      try {
        final notificationManager = Provider.of<NotificationManager>(context, listen: false);
        await notificationManager.addNotification(
          type: 'achievement',
          title: 'Badge Unlocked! 🏆',
          message: 'You earned the "$badgeName" badge!',
          data: {'badge': badgeName, 'action_id': action.id},
        );
      } catch (e) {
        print('Error adding notification: $e');
      }
    }
    
    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isRepeat 
              ? '✅ ${action.title} verified! +$xpAmount XP (Practice mode)'
              : '✅ ${action.title} verified! +$xpAmount XP',
        ),
        backgroundColor: isRepeat ? Colors.blue : const Color(0xFF58CC02),
        duration: const Duration(seconds: 2),
      ),
    );
    
    return true;
  }

  /// Get verification message for action
  static String _getVerificationMessage(LearningAction action) {
    switch (action.type) {
      case ActionType.trade:
        if (action.symbol != null) {
          return 'Make a trade with ${action.symbol} to complete this action!';
        }
        return 'Make a trade to complete this action!';
      case ActionType.analyze:
        if (action.id == 'set_stop_loss' || action.id.contains('stop_loss')) {
          return 'Set a stop loss on one of your positions to complete this action! Go to your portfolio and edit a position.';
        } else if (action.id == 'set_take_profit' || action.id.contains('take_profit')) {
          return 'Set a take profit on one of your positions to complete this action! Go to your portfolio and edit a position.';
        } else if (action.id == 'calculate_position_size') {
          return 'Calculate position size and make a trade to complete this action!';
        } else if (action.id == 'diversify_risk') {
          // Check if user has diversified portfolio (no single stock > 20%)
          return 'Ensure no single stock is more than 20% of your portfolio!';
        }
        return 'Analyze a stock or check your portfolio to complete this action!';
      case ActionType.watch:
        if (action.symbol != null) {
          return 'Watch ${action.symbol} or add it to your portfolio!';
        }
        return 'Watch stocks or check your portfolio to complete this action!';
      case ActionType.research:
        return 'Research stocks or make a trade to complete this action!';
      case ActionType.reflect:
        return 'Complete the reflection to finish this action!';
    }
  }

  /// Navigate to appropriate screen for action
  static void _navigateToActionScreen(LearningAction action, BuildContext context) {
    switch (action.type) {
      case ActionType.trade:
      case ActionType.analyze:
      case ActionType.watch:
      case ActionType.research:
        // Navigate to trading screen - use the actual route
        // For now, just show a message - navigation will be handled by the action handler
        break;
      case ActionType.reflect:
        // Stay on current screen for reflection
        break;
    }
  }

  /// Check if action can be auto-completed (user already did it)
  static Future<bool> canAutoComplete(LearningAction action, BuildContext context) async {
    return await verifyActionCompletion(action, context);
  }
}

