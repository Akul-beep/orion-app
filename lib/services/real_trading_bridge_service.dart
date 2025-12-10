import 'package:flutter/material.dart';
import 'database_service.dart';
import 'gamification_service.dart';
import 'paper_trading_service.dart';

/// Service to bridge paper trading to real trading
class RealTradingBridgeService extends ChangeNotifier {
  bool _isReadyForRealTrading = false;
  Map<String, dynamic> _readinessMetrics = {};
  List<Map<String, dynamic>> _brokerageOptions = [];

  bool get isReadyForRealTrading => _isReadyForRealTrading;
  Map<String, dynamic> get readinessMetrics => _readinessMetrics;
  List<Map<String, dynamic>> get brokerageOptions => _brokerageOptions;

  /// Check if user is ready for real trading
  Future<void> checkReadiness() async {
    try {
      final completedActions = await DatabaseService.getCompletedActions();
      final completedCount = completedActions.length;
      
      // Check various readiness criteria
      final hasCompletedBasics = completedCount >= 10;
      final hasTradingExperience = await _hasTradingExperience();
      final hasProfitability = await _hasProfitability();
      final hasRiskManagement = completedActions.any((a) => a.contains('risk'));
      
      _readinessMetrics = {
        'lessons_completed': completedCount,
        'has_trading_experience': hasTradingExperience,
        'has_profitability': hasProfitability,
        'has_risk_management': hasRiskManagement,
        'readiness_score': _calculateReadinessScore(
          hasCompletedBasics,
          hasTradingExperience,
          hasProfitability,
          hasRiskManagement,
        ),
      };
      
      _isReadyForRealTrading = _readinessMetrics['readiness_score'] >= 70;
      
      if (_isReadyForRealTrading) {
        await _loadBrokerageOptions();
      }
      
      notifyListeners();
    } catch (e) {
      print('Error checking readiness: $e');
    }
  }

  Future<bool> _hasTradingExperience() async {
    // Check if user has made at least 20 paper trades
    try {
      final tradingService = PaperTradingService();
      final trades = tradingService.recentTrades;
      return trades.length >= 20;
    } catch (e) {
      return false;
    }
  }

  Future<bool> _hasProfitability() async {
    // Check if user has been profitable in paper trading
    try {
      final tradingService = PaperTradingService();
      final portfolio = tradingService.portfolio;
      return portfolio.totalPnL > 0 && portfolio.totalPnLPercent > 5; // At least 5% profit
    } catch (e) {
      return false;
    }
  }

  int _calculateReadinessScore(
    bool hasBasics,
    bool hasExperience,
    bool hasProfitability,
    bool hasRiskManagement,
  ) {
    int score = 0;
    if (hasBasics) score += 30;
    if (hasExperience) score += 25;
    if (hasProfitability) score += 25;
    if (hasRiskManagement) score += 20;
    return score;
  }

  Future<void> _loadBrokerageOptions() async {
    // Load recommended brokerages
    _brokerageOptions = [
      {
        'name': 'Robinhood',
        'description': 'Commission-free trading, beginner-friendly',
        'min_deposit': 0,
        'features': ['No commission', 'Fractional shares', 'Mobile app'],
        'url': 'https://robinhood.com',
      },
      {
        'name': 'TD Ameritrade',
        'description': 'Professional platform with education resources',
        'min_deposit': 0,
        'features': ['Paper trading', 'Education', 'Research tools'],
        'url': 'https://tdameritrade.com',
      },
      {
        'name': 'E*TRADE',
        'description': 'Full-featured platform for all traders',
        'min_deposit': 500,
        'features': ['Advanced tools', 'Options trading', 'Research'],
        'url': 'https://etrade.com',
      },
    ];
  }

  /// Mark user as ready for real trading milestone
  Future<void> markReadyForRealTrading() async {
    final actionId = 'milestone_ready_for_real_trading';
    await DatabaseService.saveCompletedAction(actionId);
    _isReadyForRealTrading = true;
    notifyListeners();
  }
}

