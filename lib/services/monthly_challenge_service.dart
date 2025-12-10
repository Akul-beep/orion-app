import 'package:flutter/material.dart';
import 'database_service.dart';
import 'gamification_service.dart';
import 'weekly_challenge_service.dart';

/// Monthly Challenge Service - Longer-term goals (like Duolingo)
class MonthlyChallengeService extends ChangeNotifier {
  static final MonthlyChallengeService _instance = MonthlyChallengeService._internal();
  factory MonthlyChallengeService() => _instance;
  MonthlyChallengeService._internal();

  MonthlyChallenge? _currentChallenge;
  Map<String, dynamic> _progress = {};
  DateTime? _challengeStartDate;
  bool _isLoading = false;

  DateTime? get challengeStartDate => _challengeStartDate;
  MonthlyChallenge? get currentChallenge => _currentChallenge;
  Map<String, dynamic> get progress => _progress;
  bool get isChallengeActive => _currentChallenge != null;
  bool get isLoading => _isLoading;
  
  double get progressPercentage {
    if (_currentChallenge == null) return 0.0;
    final total = _currentChallenge!.target;
    final current = _progress[_currentChallenge!.id] ?? 0;
    return (current / total).clamp(0.0, 1.0);
  }
  
  bool get isCompleted => progressPercentage >= 1.0;
  int get daysLeft {
    if (_challengeStartDate == null) return 30;
    final now = DateTime.now();
    final daysSinceStart = now.difference(_challengeStartDate!).inDays;
    return (30 - daysSinceStart).clamp(0, 30);
  }

  Future<void> initialize() async {
    print('📅 Initializing Monthly Challenge Service...');
    await _loadChallenge();
    await _checkChallengeExpiry();
    await _syncProgressWithStats();
    
    print('✅ Monthly Challenge Service initialized');
    if (_currentChallenge != null) {
      print('   Active challenge: ${_currentChallenge!.title}');
      print('   Progress: ${_progress[_currentChallenge!.id] ?? 0} / ${_currentChallenge!.target}');
      print('   Days left: $daysLeft');
    }
  }

  Future<void> _loadChallenge() async {
    setState(() => _isLoading = true);
    try {
      final data = await DatabaseService.loadMonthlyChallenge();
      if (data != null) {
        _currentChallenge = MonthlyChallenge.fromJson(data['challenge']);
        _progress = data['progress'] ?? {};
        _challengeStartDate = data['startDate'] != null 
            ? DateTime.parse(data['startDate']) 
            : DateTime.now();
      } else {
        await _generateNewChallenge();
      }
    } catch (e) {
      print('Error loading monthly challenge: $e');
      await _generateNewChallenge();
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _checkChallengeExpiry() async {
    if (_challengeStartDate == null) return;
    
    final now = DateTime.now();
    final daysSinceStart = now.difference(_challengeStartDate!).inDays;
    
    if (daysSinceStart >= 30) {
      // Challenge expired, generate new one
      await _completeChallenge();
      await _generateNewChallenge();
    }
  }

  Future<void> _generateNewChallenge() async {
    final challenges = [
      MonthlyChallenge(
        id: 'monthly_xp_2000',
        title: 'Monthly XP Master',
        description: 'Earn 2000 XP this month',
        target: 2000,
        reward: 500,
        type: MonthlyChallengeType.xp,
        icon: Icons.emoji_events,
      ),
      MonthlyChallenge(
        id: 'monthly_lessons_20',
        title: 'Monthly Learner',
        description: 'Complete 20 lessons this month',
        target: 20,
        reward: 400,
        type: MonthlyChallengeType.lessons,
        icon: Icons.school,
      ),
      MonthlyChallenge(
        id: 'monthly_trades_30',
        title: 'Monthly Trader',
        description: 'Make 30 trades this month',
        target: 30,
        reward: 600,
        type: MonthlyChallengeType.trades,
        icon: Icons.trending_up,
      ),
      MonthlyChallenge(
        id: 'monthly_streak_20',
        title: 'Monthly Streak',
        description: 'Maintain a 20-day streak',
        target: 20,
        reward: 700,
        type: MonthlyChallengeType.streak,
        icon: Icons.local_fire_department,
      ),
      MonthlyChallenge(
        id: 'monthly_portfolio_10',
        title: 'Monthly Growth',
        description: 'Grow portfolio by 10% this month',
        target: 10,
        reward: 800,
        type: MonthlyChallengeType.portfolioGrowth,
        icon: Icons.show_chart,
      ),
    ];

    // Use month number to rotate challenges
    final monthIndex = DateTime.now().month % challenges.length;
    _currentChallenge = challenges[monthIndex];
    _progress = {};
    _challengeStartDate = DateTime.now();
    
    print('📅 Generated new monthly challenge: ${_currentChallenge!.title}');
    print('   Target: ${_currentChallenge!.target}, Reward: ${_currentChallenge!.reward} XP');
    
    await _saveChallenge();
    notifyListeners();
  }

  Future<void> _syncProgressWithStats() async {
    if (_currentChallenge == null) return;
    
    try {
      final gamification = GamificationService.instance;
      if (gamification == null) return;
      
      int currentValue = 0;
      switch (_currentChallenge!.type) {
        case MonthlyChallengeType.xp:
          // Track XP earned this month (from challenge start)
          currentValue = _progress[_currentChallenge!.id] ?? 0;
          break;
        case MonthlyChallengeType.streak:
          currentValue = gamification.streak.clamp(0, _currentChallenge!.target);
          _progress[_currentChallenge!.id] = currentValue;
          break;
        case MonthlyChallengeType.lessons:
          currentValue = _progress[_currentChallenge!.id] ?? 0;
          break;
        case MonthlyChallengeType.trades:
          currentValue = _progress[_currentChallenge!.id] ?? 0;
          break;
        case MonthlyChallengeType.portfolioGrowth:
          // Calculate portfolio growth percentage
          currentValue = _calculatePortfolioGrowth();
          _progress[_currentChallenge!.id] = currentValue;
          break;
      }
      
      if (currentValue >= _currentChallenge!.target && !isCompleted) {
        await _completeChallenge();
      }
      
      await _saveChallenge();
    } catch (e) {
      print('⚠️ Error syncing monthly challenge progress: $e');
    }
  }

  int _calculatePortfolioGrowth() {
    try {
      // This would need portfolio value at challenge start
      // For now, return current progress
      return _progress[_currentChallenge!.id] ?? 0;
    } catch (e) {
      return 0;
    }
  }

  Future<void> trackProgress(String type, int amount) async {
    if (_currentChallenge == null) return;
    
    bool shouldTrack = false;
    switch (_currentChallenge!.type) {
      case MonthlyChallengeType.xp:
        shouldTrack = type == 'xp';
        break;
      case MonthlyChallengeType.lessons:
        shouldTrack = type == 'lesson';
        break;
      case MonthlyChallengeType.trades:
        shouldTrack = type == 'trade';
        break;
      case MonthlyChallengeType.streak:
        shouldTrack = type == 'streak';
        break;
      case MonthlyChallengeType.portfolioGrowth:
        shouldTrack = type == 'portfolio_growth';
        break;
    }

    if (!shouldTrack) return;

    final current = _progress[_currentChallenge!.id] ?? 0;
    final newProgress = (current + amount).clamp(0, _currentChallenge!.target);
    _progress[_currentChallenge!.id] = newProgress;

    if (newProgress >= _currentChallenge!.target && !isCompleted) {
      await _completeChallenge();
    }

    await _saveChallenge();
    notifyListeners();
  }

  Future<void> _completeChallenge() async {
    if (_currentChallenge == null || isCompleted) return;

    print('🎉 Completing monthly challenge: ${_currentChallenge!.title}');
    print('   Awarding ${_currentChallenge!.reward} XP reward');

    try {
      final gamification = GamificationService.instance ?? GamificationService();
      gamification.addXP(_currentChallenge!.reward, 'monthly_challenge');
    } catch (e) {
      print('❌ Error awarding monthly challenge reward: $e');
    }

    try {
      await DatabaseService.saveMonthlyChallengeCompletion({
        'challengeId': _currentChallenge!.id,
        'completedAt': DateTime.now().toIso8601String(),
        'reward': _currentChallenge!.reward,
      });
    } catch (e) {
      print('⚠️ Error saving monthly challenge completion: $e');
    }

    notifyListeners();
  }

  Future<void> _saveChallenge() async {
    await DatabaseService.saveMonthlyChallenge({
      'challenge': _currentChallenge!.toJson(),
      'progress': _progress,
      'startDate': _challengeStartDate?.toIso8601String(),
    });
  }

  void setState(VoidCallback fn) {
    fn();
    notifyListeners();
  }
}

enum MonthlyChallengeType {
  xp,
  lessons,
  trades,
  streak,
  portfolioGrowth,
}

class MonthlyChallenge {
  final String id;
  final String title;
  final String description;
  final int target;
  final int reward;
  final MonthlyChallengeType type;
  final IconData icon;

  MonthlyChallenge({
    required this.id,
    required this.title,
    required this.description,
    required this.target,
    required this.reward,
    required this.type,
    required this.icon,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'target': target,
    'reward': reward,
    'type': type.toString().split('.').last,
    'icon': icon.codePoint,
  };

  factory MonthlyChallenge.fromJson(Map<String, dynamic> json) => MonthlyChallenge(
    id: json['id'],
    title: json['title'],
    description: json['description'],
    target: json['target'],
    reward: json['reward'],
    type: MonthlyChallengeType.values.firstWhere(
      (e) => e.toString().split('.').last == json['type'],
      orElse: () => MonthlyChallengeType.xp,
    ),
    icon: IconData(json['icon'], fontFamily: 'MaterialIcons'),
  );
}

