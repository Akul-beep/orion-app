import 'dart:math' show Random;
import 'package:flutter/material.dart';
import 'database_service.dart';
import 'gamification_service.dart';
import 'friend_service.dart';

/// Friend Quest Service - Collaborative challenges with friends (like Duolingo)
class FriendQuestService extends ChangeNotifier {
  static final FriendQuestService _instance = FriendQuestService._internal();
  factory FriendQuestService() => _instance;
  FriendQuestService._internal();

  FriendQuest? _currentQuest;
  Map<String, int> _progress = {}; // userId -> progress
  DateTime? _questStartDate;
  bool _isLoading = false;

  DateTime? get questStartDate => _questStartDate;
  FriendQuest? get currentQuest => _currentQuest;
  Map<String, int> get progress => _progress;
  bool get isQuestActive => _currentQuest != null;
  bool get isLoading => _isLoading;
  
  double get progressPercentage {
    if (_currentQuest == null) return 0.0;
    final total = _currentQuest!.target;
    final combinedProgress = _progress.values.fold<int>(0, (sum, p) => sum + p);
    return (combinedProgress / total).clamp(0.0, 1.0);
  }
  
  bool get isCompleted => progressPercentage >= 1.0;
  int get daysLeft {
    if (_questStartDate == null) return 7;
    final now = DateTime.now();
    final daysSinceStart = now.difference(_questStartDate!).inDays;
    return (7 - daysSinceStart).clamp(0, 7);
  }

  String? get partnerId => _currentQuest?.partnerId;
  String? get partnerName => _currentQuest?.partnerName;

  Future<void> initialize() async {
    print('👥 Initializing Friend Quest Service...');
    await _loadQuest();
    await _checkQuestExpiry();
    await _syncProgress();
    
    print('✅ Friend Quest Service initialized');
    if (_currentQuest != null) {
      print('   Active quest: ${_currentQuest!.title}');
      print('   Partner: ${_currentQuest!.partnerName}');
      final combinedProgress = _progress.values.fold<int>(0, (sum, p) => sum + p);
      print('   Combined progress: $combinedProgress / ${_currentQuest!.target}');
    }
  }

  Future<void> _loadQuest() async {
    setState(() => _isLoading = true);
    try {
      final data = await DatabaseService.loadFriendQuest();
      if (data != null) {
        _currentQuest = FriendQuest.fromJson(data['quest']);
        _progress = Map<String, int>.from(data['progress'] ?? {});
        _questStartDate = data['startDate'] != null 
            ? DateTime.parse(data['startDate']) 
            : DateTime.now();
        
        // Check if quest has old-style title and regenerate if needed
        final oldTitles = [
          'Friend Quest: XP Together',
          'Friend Quest: Learn Together',
          'Friend Quest: Trade Together',
        ];
        
        if (oldTitles.contains(_currentQuest!.title)) {
          print('🔄 Old friend quest title detected, regenerating with new format...');
          await _tryGenerateNewQuest();
        }
      } else {
        await _tryGenerateNewQuest();
      }
    } catch (e) {
      print('Error loading friend quest: $e');
      await _tryGenerateNewQuest();
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _checkQuestExpiry() async {
    if (_questStartDate == null) return;
    
    final now = DateTime.now();
    final daysSinceStart = now.difference(_questStartDate!).inDays;
    
    if (daysSinceStart >= 7) {
      // Quest expired, try to generate new one
      await _completeQuest();
      await _tryGenerateNewQuest();
    }
  }

  Future<void> _tryGenerateNewQuest() async {
    try {
      final friendService = FriendService();
      // Ensure friends are loaded (initialize is idempotent)
      await friendService.initialize();
      
      final friends = friendService.friends;
      if (friends.isEmpty) {
        print('👥 No friends available for Friend Quest');
        return;
      }

      // Pick a random friend
      final random = Random();
      final randomFriend = friends[random.nextInt(friends.length)];
      
      // Generate quest
      final quests = [
        FriendQuest(
          id: 'friend_quest_xp',
          title: 'Earn 1000 XP Together',
          description: 'Team up with ${randomFriend.displayName} to earn XP',
          target: 1000,
          reward: 300,
          type: FriendQuestType.xp,
          partnerId: randomFriend.userId,
          partnerName: randomFriend.displayName,
          icon: Icons.people,
        ),
        FriendQuest(
          id: 'friend_quest_lessons',
          title: 'Complete 10 Lessons Together',
          description: 'Learn together with ${randomFriend.displayName}',
          target: 10,
          reward: 250,
          type: FriendQuestType.lessons,
          partnerId: randomFriend.userId,
          partnerName: randomFriend.displayName,
          icon: Icons.school,
        ),
        FriendQuest(
          id: 'friend_quest_trades',
          title: 'Make 15 Trades Together',
          description: 'Trade together with ${randomFriend.displayName}',
          target: 15,
          reward: 400,
          type: FriendQuestType.trades,
          partnerId: randomFriend.userId,
          partnerName: randomFriend.displayName,
          icon: Icons.trending_up,
        ),
      ];

      final questIndex = DateTime.now().weekday % quests.length;
      _currentQuest = quests[questIndex];
      _progress = {};
      _questStartDate = DateTime.now();
      
      print('👥 Generated new friend quest: ${_currentQuest!.title}');
      print('   Partner: ${_currentQuest!.partnerName}');
      print('   Target: ${_currentQuest!.target}, Reward: ${_currentQuest!.reward} XP each');
      
      await _saveQuest();
      notifyListeners();
    } catch (e) {
      print('⚠️ Error generating friend quest: $e');
    }
  }

  Future<void> _syncProgress() async {
    if (_currentQuest == null) return;
    
    try {
      // Sync progress from database (both users contribute)
      final data = await DatabaseService.loadFriendQuestProgress(_currentQuest!.id);
      if (data != null) {
        _progress = Map<String, int>.from(data);
      }
      
      // Check if quest should be completed
      final combinedProgress = _progress.values.fold<int>(0, (sum, p) => sum + p);
      if (combinedProgress >= _currentQuest!.target && !isCompleted) {
        await _completeQuest();
      }
      
      await _saveQuest();
    } catch (e) {
      print('⚠️ Error syncing friend quest progress: $e');
    }
  }

  Future<void> trackProgress(String type, int amount) async {
    if (_currentQuest == null) return;
    
    bool shouldTrack = false;
    switch (_currentQuest!.type) {
      case FriendQuestType.xp:
        shouldTrack = type == 'xp';
        break;
      case FriendQuestType.lessons:
        shouldTrack = type == 'lesson';
        break;
      case FriendQuestType.trades:
        shouldTrack = type == 'trade';
        break;
    }

    if (!shouldTrack) return;

    // Get current user ID
    final userId = await DatabaseService.getOrCreateLocalUserId();
    final current = _progress[userId] ?? 0;
    final newProgress = (current + amount).clamp(0, _currentQuest!.target);
    _progress[userId] = newProgress;

    // Save progress to database (so partner can see it)
    await DatabaseService.saveFriendQuestProgress(
      _currentQuest!.id,
      userId,
      newProgress,
    );

    // Check if quest is completed (combined progress)
    final combinedProgress = _progress.values.fold<int>(0, (sum, p) => sum + p);
    if (combinedProgress >= _currentQuest!.target && !isCompleted) {
      await _completeQuest();
    }

    await _saveQuest();
    notifyListeners();
  }

  Future<void> _completeQuest() async {
    if (_currentQuest == null || isCompleted) return;

    print('🎉 Completing friend quest: ${_currentQuest!.title}');
    print('   Awarding ${_currentQuest!.reward} XP to both partners');

    // Award reward to current user
    try {
      final gamification = GamificationService.instance ?? GamificationService();
      gamification.addXP(_currentQuest!.reward, 'friend_quest');
      print('   ✅ Reward awarded to current user');
    } catch (e) {
      print('❌ Error awarding friend quest reward: $e');
    }

    // Save completion (partner will get reward when they sync)
    try {
      await DatabaseService.saveFriendQuestCompletion({
        'questId': _currentQuest!.id,
        'completedAt': DateTime.now().toIso8601String(),
        'reward': _currentQuest!.reward,
        'partnerId': _currentQuest!.partnerId,
      });
    } catch (e) {
      print('⚠️ Error saving friend quest completion: $e');
    }

    notifyListeners();
  }

  Future<void> _saveQuest() async {
    await DatabaseService.saveFriendQuest({
      'quest': _currentQuest!.toJson(),
      'progress': _progress,
      'startDate': _questStartDate?.toIso8601String(),
    });
  }

  void setState(VoidCallback fn) {
    fn();
    notifyListeners();
  }
}

enum FriendQuestType {
  xp,
  lessons,
  trades,
}

class FriendQuest {
  final String id;
  final String title;
  final String description;
  final int target;
  final int reward;
  final FriendQuestType type;
  final String partnerId;
  final String partnerName;
  final IconData icon;

  FriendQuest({
    required this.id,
    required this.title,
    required this.description,
    required this.target,
    required this.reward,
    required this.type,
    required this.partnerId,
    required this.partnerName,
    required this.icon,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'target': target,
    'reward': reward,
    'type': type.toString().split('.').last,
    'partnerId': partnerId,
    'partnerName': partnerName,
    'icon': icon.codePoint,
  };

  factory FriendQuest.fromJson(Map<String, dynamic> json) => FriendQuest(
    id: json['id'],
    title: json['title'],
    description: json['description'],
    target: json['target'],
    reward: json['reward'],
    type: FriendQuestType.values.firstWhere(
      (e) => e.toString().split('.').last == json['type'],
      orElse: () => FriendQuestType.xp,
    ),
    partnerId: json['partnerId'],
    partnerName: json['partnerName'],
    icon: IconData(json['icon'], fontFamily: 'MaterialIcons'),
  );
}

