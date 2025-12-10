import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/learning_action.dart';
import '../services/gamification_service.dart';
import '../services/paper_trading_service.dart';
import '../services/stock_api_service.dart';
import 'learning_timer_service.dart';

class LearningPopupService extends ChangeNotifier {
  static final LearningPopupService _instance = LearningPopupService._internal();
  factory LearningPopupService() => _instance;
  LearningPopupService._internal();

  bool _isLearningMode = false;
  LearningAction? _currentAction;
  String? _currentQuestion;
  DateTime? _popupStartTime;
  int _timeRemaining = 0;
  bool _isMarketOpen = true; // We'll check this dynamically
  
  // Getters
  bool get isLearningMode => _isLearningMode;
  LearningAction? get currentAction => _currentAction;
  String? get currentQuestion => _currentQuestion;
  int get timeRemaining => _timeRemaining;
  bool get isMarketOpen => _isMarketOpen;

  // Start learning mode with action
  void startLearningMode(LearningAction action, String question) {
    _isLearningMode = true;
    _currentAction = action;
    _currentQuestion = question;
    _popupStartTime = DateTime.now();
    _timeRemaining = action.timeRequired * 60; // Convert minutes to seconds
    _checkMarketStatus();
    
    // Start timer
    LearningTimerService().startTimer(this);
    
    notifyListeners();
  }

  // Stop learning mode
  void stopLearningMode() {
    _isLearningMode = false;
    _currentAction = null;
    _currentQuestion = null;
    _popupStartTime = null;
    _timeRemaining = 0;
    
    // Stop timer
    LearningTimerService().stopTimer();
    
    notifyListeners();
  }

  // Check if market is open (simplified - in real app, check market hours)
  Future<void> _checkMarketStatus() async {
    // For demo purposes, assume market is open during business hours
    final now = DateTime.now();
    final hour = now.hour;
    final day = now.weekday;
    
    // Market closed on weekends
    if (day == DateTime.saturday || day == DateTime.sunday) {
      _isMarketOpen = false;
    }
    // Market hours: 9:30 AM - 4:00 PM EST (simplified)
    else if (hour >= 9 && hour < 16) {
      _isMarketOpen = true;
    } else {
      _isMarketOpen = false;
    }
    notifyListeners();
  }

  // Update timer
  void updateTimer() {
    if (_isLearningMode && _timeRemaining > 0) {
      _timeRemaining--;
      notifyListeners();
    }
  }

  // Extend time
  void extendTime(int additionalMinutes) {
    _timeRemaining += additionalMinutes * 60;
    notifyListeners();
  }

  // Get market status message
  String getMarketStatusMessage() {
    if (_isMarketOpen) {
      return "Market is OPEN - Live prices updating! 📈";
    } else {
      return "Market is CLOSED - Prices from last close 📊";
    }
  }

  // Get market status color
  Color getMarketStatusColor() {
    return _isMarketOpen ? Colors.green : Colors.orange;
  }

  // Check if action is possible given market conditions
  bool isActionPossible() {
    if (_currentAction == null) return false;
    
    switch (_currentAction!.type) {
      case ActionType.watch:
        return true; // Always possible to watch
      case ActionType.analyze:
        return true; // Always possible to analyze
      case ActionType.trade:
        return _isMarketOpen; // Trading only when market is open
      case ActionType.research:
        return true; // Always possible to research
      case ActionType.reflect:
        return true; // Always possible to reflect
    }
  }

  // Get action guidance based on market conditions
  String getActionGuidance() {
    if (_currentAction == null) return "";
    
    if (!_isMarketOpen && _currentAction!.type == ActionType.trade) {
      return "Market is closed, but you can still practice with paper trading! 💡";
    }
    
    return _currentAction!.guidance ?? _currentAction!.description;
  }
}
