import 'dart:async';
import 'package:flutter/material.dart';
import 'learning_popup_service.dart';

class LearningTimerService {
  static final LearningTimerService _instance = LearningTimerService._internal();
  factory LearningTimerService() => _instance;
  LearningTimerService._internal();

  Timer? _timer;
  LearningPopupService? _popupService;

  void startTimer(LearningPopupService popupService) {
    _popupService = popupService;
    
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_popupService != null && _popupService!.isLearningMode) {
        _popupService!.updateTimer();
        
        // Auto-submit if time runs out
        if (_popupService!.timeRemaining <= 0) {
          _autoSubmit();
        }
      } else {
        timer.cancel();
      }
    });
  }

  void stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  void _autoSubmit() {
    // Auto-submit with a default answer if time runs out
    if (_popupService != null) {
      // You could implement auto-submission logic here
      // For now, just stop the timer
      stopTimer();
    }
  }

  void dispose() {
    stopTimer();
  }
}
