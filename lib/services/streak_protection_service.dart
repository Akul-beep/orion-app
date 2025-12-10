import 'package:flutter/material.dart';
import 'database_service.dart';
import 'gamification_service.dart';

class StreakProtectionService extends ChangeNotifier {
  static final StreakProtectionService _instance = StreakProtectionService._internal();
  factory StreakProtectionService() => _instance;
  StreakProtectionService._internal();

  int _freezesAvailable = 0;
  int _freezesUsed = 0;
  DateTime? _lastFreezeDate;

  int get freezesAvailable => _freezesAvailable;
  int get freezesUsed => _freezesUsed;
  bool get canUseFreeze => _freezesAvailable > 0;

  Future<void> initialize() async {
    await _loadFreezes();
    await _checkFreezeRegeneration();
  }

  Future<void> _loadFreezes() async {
    try {
      final data = await DatabaseService.loadStreakProtection();
      if (data != null) {
        _freezesAvailable = data['freezesAvailable'] ?? 0;
        _freezesUsed = data['freezesUsed'] ?? 0;
        _lastFreezeDate = data['lastFreezeDate'] != null
            ? DateTime.parse(data['lastFreezeDate'])
            : null;
      } else {
        // New user gets 1 freeze
        _freezesAvailable = 1;
        await _saveFreezes();
      }
    } catch (e) {
      print('Error loading streak protection: $e');
      _freezesAvailable = 1;
    }
    notifyListeners();
  }

  Future<void> _checkFreezeRegeneration() async {
    // Regenerate 1 freeze per week if user has less than 3
    if (_freezesAvailable < 3) {
      final now = DateTime.now();
      final lastCheck = _lastFreezeDate ?? now.subtract(const Duration(days: 8));
      final daysSince = now.difference(lastCheck).inDays;

      if (daysSince >= 7) {
        _freezesAvailable = (_freezesAvailable + 1).clamp(0, 3);
        _lastFreezeDate = now;
        await _saveFreezes();
        notifyListeners();
      }
    }
  }

  Future<bool> useFreeze(GamificationService gamification) async {
    if (!canUseFreeze) return false;

    // Check if streak is actually at risk
    final dailyGoals = await DatabaseService.loadDailyGoals();
    if (dailyGoals == null) return false;

    final today = DateTime.now().toIso8601String().split('T')[0];
    final todayXP = dailyGoals['todayXP'] ?? 0;
    final todayTrades = dailyGoals['todayTrades'] ?? 0;
    final todayLessons = dailyGoals['todayLessons'] ?? 0;

    // Only allow freeze if user hasn't completed goals today
    if (todayXP > 0 || todayTrades > 0 || todayLessons > 0) {
      return false; // Can't freeze if already made progress
    }

    _freezesAvailable--;
    _freezesUsed++;
    await _saveFreezes();

    // Extend streak protection
    await DatabaseService.saveStreakFreeze({
      'usedAt': DateTime.now().toIso8601String(),
      'streak': gamification.streak,
    });

    notifyListeners();
    return true;
  }

  Future<void> earnFreeze() async {
    // User can earn freezes through achievements
    if (_freezesAvailable < 3) {
      _freezesAvailable++;
      await _saveFreezes();
      notifyListeners();
    }
  }

  Future<void> _saveFreezes() async {
    await DatabaseService.saveStreakProtection({
      'freezesAvailable': _freezesAvailable,
      'freezesUsed': _freezesUsed,
      'lastFreezeDate': _lastFreezeDate?.toIso8601String(),
    });
  }
}






