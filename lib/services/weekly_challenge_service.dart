import 'package:flutter/material.dart';
import 'database_service.dart';
import 'gamification_service.dart';
import 'paper_trading_service.dart';

class WeeklyChallengeService extends ChangeNotifier {
  static final WeeklyChallengeService _instance = WeeklyChallengeService._internal();
  factory WeeklyChallengeService() => _instance;
  WeeklyChallengeService._internal();

  WeeklyChallenge? _currentChallenge;
  Map<String, dynamic> _progress = {};
  DateTime? _challengeStartDate;
  int _xpAtChallengeStart = 0; // Track XP when challenge started
  bool _isLoading = false;

  DateTime? get challengeStartDate => _challengeStartDate;

  WeeklyChallenge? get currentChallenge => _currentChallenge;
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

  Future<void> initialize() async {
    print('🎯 Initializing Weekly Challenge Service...');
    await _loadChallenge();
    await _checkChallengeExpiry();
    
    // Sync current progress with actual stats
    await _syncProgressWithStats();
    
    print('✅ Weekly Challenge Service initialized');
    if (_currentChallenge != null) {
      print('   Active challenge: ${_currentChallenge!.title}');
      print('   Progress: ${_progress[_currentChallenge!.id] ?? 0} / ${_currentChallenge!.target}');
    }
  }
  
  /// Sync challenge progress with current user stats
  Future<void> _syncProgressWithStats() async {
    if (_currentChallenge == null) return;
    
    try {
      final gamification = GamificationService.instance;
      if (gamification == null) return;
      
      int currentValue = 0;
      switch (_currentChallenge!.type) {
        case ChallengeType.xp:
          // Calculate XP earned since challenge started
          if (gamification != null) {
            final totalXP = gamification.totalXP;
            final xpEarned = (totalXP - _xpAtChallengeStart).clamp(0, _currentChallenge!.target);
            currentValue = xpEarned;
            _progress[_currentChallenge!.id] = currentValue;
          } else {
            currentValue = _progress[_currentChallenge!.id] ?? 0;
          }
          break;
        case ChallengeType.streak:
          currentValue = gamification.streak.clamp(0, _currentChallenge!.target);
          _progress[_currentChallenge!.id] = currentValue;
          break;
        case ChallengeType.lessons:
          currentValue = _progress[_currentChallenge!.id] ?? 0;
          break;
        case ChallengeType.trades:
          currentValue = _progress[_currentChallenge!.id] ?? 0;
          break;
        case ChallengeType.riskManagement:
          // Count trades with stop-loss
          currentValue = _countTradesWithStopLoss();
          _progress[_currentChallenge!.id] = currentValue;
          break;
        case ChallengeType.profitTaking:
          // Count trades with take-profit
          currentValue = _countTradesWithTakeProfit();
          _progress[_currentChallenge!.id] = currentValue;
          break;
        case ChallengeType.researchFirst:
          // Count AI Coach analyses (stored in database)
          currentValue = _progress[_currentChallenge!.id] ?? 0;
          break;
        case ChallengeType.diversification:
          // Count unique sectors in portfolio
          currentValue = _countUniqueSectors();
          _progress[_currentChallenge!.id] = currentValue;
          break;
        case ChallengeType.perfectScore:
          // Count perfect lessons
          currentValue = gamification.perfectLessons.clamp(0, _currentChallenge!.target);
          _progress[_currentChallenge!.id] = currentValue;
          break;
      }
      
      print('   🔄 Synced progress: $currentValue / ${_currentChallenge!.target}');
      
      // Check if challenge should be completed
      if (currentValue >= _currentChallenge!.target && !isCompleted) {
        await _completeChallenge();
      }
      
      await _saveChallenge();
    } catch (e) {
      print('⚠️ Error syncing challenge progress: $e');
    }
  }

  int _countTradesWithStopLoss() {
    try {
      final trading = PaperTradingService();
      final trades = trading.tradeHistory;
      return trades.where((trade) => trade.stopLoss != null).length;
    } catch (e) {
      print('⚠️ Error counting stop-loss trades: $e');
      return 0;
    }
  }

  int _countTradesWithTakeProfit() {
    try {
      final trading = PaperTradingService();
      final trades = trading.tradeHistory;
      return trades.where((trade) => trade.takeProfit != null).length;
    } catch (e) {
      print('⚠️ Error counting take-profit trades: $e');
      return 0;
    }
  }

  int _countUniqueSectors() {
    try {
      final trading = PaperTradingService();
      final positions = trading.positions;
      // Simple sector detection based on symbol patterns
      // In a real app, you'd have sector data from API
      final sectors = <String>{};
      for (final position in positions) {
        // Basic sector detection (can be improved with actual sector data)
        final symbol = position.symbol.toUpperCase();
        if (symbol.startsWith('AAPL') || symbol.startsWith('MSFT') || symbol.startsWith('GOOGL')) {
          sectors.add('Tech');
        } else if (symbol.startsWith('JPM') || symbol.startsWith('BAC') || symbol.startsWith('WFC')) {
          sectors.add('Finance');
        } else if (symbol.startsWith('JNJ') || symbol.startsWith('PFE') || symbol.startsWith('UNH')) {
          sectors.add('Healthcare');
        } else {
          sectors.add('Other');
        }
      }
      return sectors.length;
    } catch (e) {
      print('⚠️ Error counting sectors: $e');
      return 0;
    }
  }

  Future<void> _loadChallenge() async {
    setState(() => _isLoading = true);
    try {
      final data = await DatabaseService.loadWeeklyChallenge();
      if (data != null) {
        _currentChallenge = WeeklyChallenge.fromJson(data['challenge']);
        _progress = data['progress'] ?? {};
        _challengeStartDate = data['startDate'] != null 
            ? DateTime.parse(data['startDate']) 
            : DateTime.now();
        _xpAtChallengeStart = data['xpAtStart'] ?? 0;
        
        // Check if challenge has old-style title and regenerate if needed
        final oldTitles = [
          'Learning Streak Challenge',
          'Risk Manager Challenge',
          'Research First Challenge',
          'Diversification Challenge',
          'Profit Target Challenge',
          'Perfect Score Challenge',
          'Streak Champion Challenge',
        ];
        
        if (oldTitles.contains(_currentChallenge!.title)) {
          print('🔄 Old challenge title detected, regenerating with new format...');
          await _generateNewChallenge();
        }
      } else {
        await _generateNewChallenge();
      }
    } catch (e) {
      print('Error loading weekly challenge: $e');
      await _generateNewChallenge();
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _checkChallengeExpiry() async {
    if (_challengeStartDate == null) return;
    
    final now = DateTime.now();
    final daysSinceStart = now.difference(_challengeStartDate!).inDays;
    
    if (daysSinceStart >= 7) {
      // Challenge expired, generate new one
      await _completeChallenge();
      await _generateNewChallenge();
    }
  }

  Future<void> _generateNewChallenge() async {
    // PRIORITY: Critical skill-based challenges first!
    final criticalChallenges = [
      // TIER 1: CRITICAL SKILLS (Most Important!)
      WeeklyChallenge(
        id: 'risk_manager',
        title: 'Set Stop-Loss on 5 Trades',
        description: 'Protect your portfolio by setting stop-loss orders',
        target: 5,
        reward: 300,
        type: ChallengeType.riskManagement,
        icon: Icons.shield,
      ),
      WeeklyChallenge(
        id: 'research_first',
        title: 'Research 5 Stocks with AI',
        description: 'Use AI Coach to analyze stocks before trading',
        target: 5,
        reward: 350,
        type: ChallengeType.researchFirst,
        icon: Icons.search,
      ),
      WeeklyChallenge(
        id: 'diversification',
        title: 'Diversify Across 3 Sectors',
        description: 'Spread your investments across different sectors',
        target: 3,
        reward: 400,
        type: ChallengeType.diversification,
        icon: Icons.account_balance,
      ),
      WeeklyChallenge(
        id: 'profit_taking',
        title: 'Set Take-Profit on 3 Trades',
        description: 'Lock in profits by setting take-profit targets',
        target: 3,
        reward: 250,
        type: ChallengeType.profitTaking,
        icon: Icons.trending_up,
      ),
      WeeklyChallenge(
        id: 'perfect_score',
        title: 'Get 100% on 3 Quizzes',
        description: 'Ace your lesson quizzes with perfect scores',
        target: 3,
        reward: 300,
        type: ChallengeType.perfectScore,
        icon: Icons.star,
      ),
    ];

    // TIER 2: Learning & Engagement
    final learningChallenges = [
      WeeklyChallenge(
        id: 'complete_5_lessons',
        title: 'Complete 5 Lessons',
        description: 'Finish 5 lessons this week to master new trading skills',
        target: 5,
        reward: 200,
        type: ChallengeType.lessons,
        icon: Icons.school,
      ),
      WeeklyChallenge(
        id: 'maintain_streak',
        title: 'Maintain 7-Day Streak',
        description: 'Stay active for 7 consecutive days',
        target: 7,
        reward: 300,
        type: ChallengeType.streak,
        icon: Icons.local_fire_department,
      ),
    ];

    // Mix: 70% critical challenges, 30% learning challenges
    final allChallenges = [...criticalChallenges, ...learningChallenges];
    
    // Use day of week to rotate, but prioritize critical challenges
    final dayIndex = DateTime.now().weekday;
    final challengeIndex = dayIndex % allChallenges.length;
    
    _currentChallenge = allChallenges[challengeIndex];
    _progress = {};
    _challengeStartDate = DateTime.now();
    
    // Track XP at challenge start for XP challenges
    try {
      final gamification = GamificationService.instance;
      if (gamification != null && _currentChallenge!.type == ChallengeType.xp) {
        _xpAtChallengeStart = gamification.totalXP;
      } else {
        _xpAtChallengeStart = 0;
      }
    } catch (e) {
      _xpAtChallengeStart = 0;
    }
    
    print('🎯 Generated new challenge: ${_currentChallenge!.title} (${_currentChallenge!.type})');
    print('   Target: ${_currentChallenge!.target}, Reward: ${_currentChallenge!.reward} XP');
    
    await _saveChallenge();
    notifyListeners();
  }

  Future<void> trackProgress(String type, int amount) async {
    if (_currentChallenge == null) {
      return;
    }
    
    print('📊 Challenge progress tracking: type=$type, amount=$amount');
    print('   Current challenge: ${_currentChallenge!.title} (${_currentChallenge!.type})');
    
    // Check if this progress type matches the challenge
    bool shouldTrack = false;
    switch (_currentChallenge!.type) {
      case ChallengeType.xp:
        shouldTrack = type == 'xp';
        break;
      case ChallengeType.lessons:
        shouldTrack = type == 'lesson';
        break;
      case ChallengeType.trades:
        shouldTrack = type == 'trade';
        break;
      case ChallengeType.streak:
        shouldTrack = type == 'streak';
        break;
      case ChallengeType.riskManagement:
        shouldTrack = type == 'stop_loss';
        break;
      case ChallengeType.profitTaking:
        shouldTrack = type == 'take_profit';
        break;
      case ChallengeType.researchFirst:
        shouldTrack = type == 'ai_analysis';
        break;
      case ChallengeType.diversification:
        shouldTrack = type == 'diversification';
        break;
      case ChallengeType.perfectScore:
        shouldTrack = type == 'perfect_lesson';
        break;
    }

    if (!shouldTrack) {
      return;
    }

    final current = _progress[_currentChallenge!.id] ?? 0;
    
    // For streak and perfect score, use current value instead of incrementing
    int newProgress;
    if (_currentChallenge!.type == ChallengeType.streak) {
      final gamification = GamificationService.instance;
      if (gamification != null) {
        newProgress = gamification.streak.clamp(0, _currentChallenge!.target);
      } else {
        newProgress = current;
      }
    } else if (_currentChallenge!.type == ChallengeType.perfectScore) {
      final gamification = GamificationService.instance;
      if (gamification != null) {
        newProgress = gamification.perfectLessons.clamp(0, _currentChallenge!.target);
      } else {
        newProgress = current;
      }
    } else if (_currentChallenge!.type == ChallengeType.riskManagement) {
      // Count all trades with stop-loss
      newProgress = _countTradesWithStopLoss().clamp(0, _currentChallenge!.target);
    } else if (_currentChallenge!.type == ChallengeType.profitTaking) {
      // Count all trades with take-profit
      newProgress = _countTradesWithTakeProfit().clamp(0, _currentChallenge!.target);
    } else if (_currentChallenge!.type == ChallengeType.diversification) {
      // Count unique sectors
      newProgress = _countUniqueSectors().clamp(0, _currentChallenge!.target);
    } else if (_currentChallenge!.type == ChallengeType.xp) {
      // For XP challenges, calculate from start date
      final gamification = GamificationService.instance;
      if (gamification != null) {
        final totalXP = gamification.totalXP;
        newProgress = (totalXP - _xpAtChallengeStart).clamp(0, _currentChallenge!.target);
      } else {
        newProgress = (current + amount).clamp(0, _currentChallenge!.target);
      }
    } else {
      newProgress = (current + amount).clamp(0, _currentChallenge!.target);
    }
    
    _progress[_currentChallenge!.id] = newProgress;
    
    print('   📈 Progress: $current → $newProgress / ${_currentChallenge!.target} (${((newProgress / _currentChallenge!.target) * 100).toStringAsFixed(1)}%)');

    if (newProgress >= _currentChallenge!.target && !isCompleted) {
      print('   🎉 Challenge completed!');
      await _completeChallenge();
    }

    await _saveChallenge();
    notifyListeners();
  }

  Future<void> _completeChallenge() async {
    if (_currentChallenge == null) return;
    
    if (isCompleted) {
      print('⚠️ Challenge already completed, skipping reward');
      return;
    }

    print('🎉 Completing challenge: ${_currentChallenge!.title}');
    print('   Awarding ${_currentChallenge!.reward} XP reward');

    // Award reward
    try {
      final gamification = GamificationService.instance ?? GamificationService();
      gamification.addXP(_currentChallenge!.reward, 'weekly_challenge');
      print('   ✅ Reward awarded successfully');
    } catch (e) {
      print('❌ Error awarding challenge reward: $e');
    }

    // Save completion
    try {
      await DatabaseService.saveWeeklyChallengeCompletion({
        'challengeId': _currentChallenge!.id,
        'completedAt': DateTime.now().toIso8601String(),
        'reward': _currentChallenge!.reward,
      });
      print('   ✅ Completion saved to database');
    } catch (e) {
      print('⚠️ Error saving challenge completion: $e');
    }

    // Award bonus for completing critical challenges (encourages skill-building)
    if (_currentChallenge!.type == ChallengeType.riskManagement ||
        _currentChallenge!.type == ChallengeType.researchFirst ||
        _currentChallenge!.type == ChallengeType.diversification) {
      try {
        final gamification = GamificationService.instance ?? GamificationService();
        gamification.addXP(50, 'critical_challenge_bonus');
        print('   🎯 Bonus 50 XP for completing critical challenge!');
      } catch (e) {
        print('⚠️ Error awarding critical challenge bonus: $e');
      }
    }

    notifyListeners();
  }

  Future<void> _saveChallenge() async {
    await DatabaseService.saveWeeklyChallenge({
      'challenge': _currentChallenge!.toJson(),
      'progress': _progress,
      'startDate': _challengeStartDate?.toIso8601String(),
      'xpAtStart': _xpAtChallengeStart,
    });
  }

  void setState(VoidCallback fn) {
    fn();
    notifyListeners();
  }
}

enum ChallengeType {
  xp,
  lessons,
  trades,
  streak,
  riskManagement,
  profitTaking,
  researchFirst,
  diversification,
  perfectScore,
}

class WeeklyChallenge {
  final String id;
  final String title;
  final String description;
  final int target;
  final int reward;
  final ChallengeType type;
  final IconData icon;

  WeeklyChallenge({
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

  factory WeeklyChallenge.fromJson(Map<String, dynamic> json) => WeeklyChallenge(
    id: json['id'],
    title: json['title'],
    description: json['description'],
    target: json['target'],
    reward: json['reward'],
    type: ChallengeType.values.firstWhere(
      (e) => e.toString().split('.').last == json['type'],
      orElse: () => ChallengeType.xp,
    ),
    icon: IconData(json['icon'], fontFamily: 'MaterialIcons'),
  );
}
