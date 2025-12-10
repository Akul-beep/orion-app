import 'package:flutter/material.dart';
import 'database_service.dart';

/// Social service for friend system, sharing, and group challenges
class SocialService extends ChangeNotifier {
  List<String> _friends = [];
  List<Map<String, dynamic>> _friendRequests = [];
  List<Map<String, dynamic>> _groupChallenges = [];
  Map<String, dynamic>? _currentChallenge;

  List<String> get friends => _friends;
  List<Map<String, dynamic>> get friendRequests => _friendRequests;
  List<Map<String, dynamic>> get groupChallenges => _groupChallenges;
  Map<String, dynamic>? get currentChallenge => _currentChallenge;

  /// Load friends from database
  Future<void> loadFriends() async {
    try {
      final userId = await DatabaseService.getOrCreateLocalUserId();
      final supabase = DatabaseService.getSupabaseClient();
      
      if (supabase != null) {
        final response = await supabase
            .from('friends')
            .select('friend_id')
            .eq('user_id', userId)
            .eq('status', 'accepted');
        
        _friends = response.map((r) => r['friend_id'] as String).toList();
        
        // Also load friend requests
        final requests = await supabase
            .from('friends')
            .select()
            .eq('friend_id', userId)
            .eq('status', 'pending');
        
        _friendRequests = requests.map((r) => Map<String, dynamic>.from(r)).toList();
      } else {
        // Local storage fallback
        // Load from SharedPreferences
      }
      
      // Load group challenges
      await _loadGroupChallenges();
      
      notifyListeners();
    } catch (e) {
      print('Error loading friends: $e');
      // Continue with empty lists
      _friends = [];
      _friendRequests = [];
    }
  }

  /// Load group challenges
  Future<void> _loadGroupChallenges() async {
    try {
      final userId = await DatabaseService.getOrCreateLocalUserId();
      final supabase = DatabaseService.getSupabaseClient();
      
      if (supabase != null) {
        final response = await supabase
            .from('group_challenges')
            .select()
            .eq('status', 'active')
            .order('created_at', ascending: false);
        
        _groupChallenges = response.map((r) => Map<String, dynamic>.from(r)).toList();
      }
    } catch (e) {
      print('Error loading group challenges: $e');
      _groupChallenges = [];
    }
  }

  /// Send friend request
  Future<bool> sendFriendRequest(String friendUserId) async {
    try {
      final userId = await DatabaseService.getOrCreateLocalUserId();
      final supabase = DatabaseService.getSupabaseClient();
      
      if (supabase != null) {
        await supabase.from('friends').insert({
          'user_id': userId,
          'friend_id': friendUserId,
          'status': 'pending',
          'created_at': DateTime.now().toIso8601String(),
        });
      }
      
      notifyListeners();
      return true;
    } catch (e) {
      print('Error sending friend request: $e');
      return false;
    }
  }

  /// Accept friend request
  Future<bool> acceptFriendRequest(String requestId) async {
    try {
      final userId = await DatabaseService.getOrCreateLocalUserId();
      final supabase = DatabaseService.getSupabaseClient();
      
      if (supabase != null) {
        await supabase.from('friends')
            .update({'status': 'accepted'})
            .eq('id', requestId);
      }
      
      await loadFriends();
      return true;
    } catch (e) {
      print('Error accepting friend request: $e');
      return false;
    }
  }

  /// Create group challenge
  Future<bool> createGroupChallenge({
    required String title,
    required String description,
    required List<String> participantIds,
    required int gemReward,
    required DateTime endDate,
  }) async {
    try {
      final userId = await DatabaseService.getOrCreateLocalUserId();
      final challengeId = 'challenge_${DateTime.now().millisecondsSinceEpoch}';
      
      final challenge = {
        'id': challengeId,
        'creator_id': userId,
        'title': title,
        'description': description,
        'participant_ids': participantIds,
        'gem_reward': gemReward,
        'end_date': endDate.toIso8601String(),
        'created_at': DateTime.now().toIso8601String(),
        'status': 'active',
      };
      
      final supabase = DatabaseService.getSupabaseClient();
      if (supabase != null) {
        await supabase.from('group_challenges').insert(challenge);
      }
      
      _groupChallenges.add(challenge);
      notifyListeners();
      return true;
    } catch (e) {
      print('Error creating group challenge: $e');
      return false;
    }
  }

  /// Share achievement to social media
  Future<bool> shareAchievement({
    required String achievementType,
    required String achievementData,
    String? imageUrl,
  }) async {
    try {
      // Track sharing for analytics
      final userId = await DatabaseService.getOrCreateLocalUserId();
      
      // Award gems for sharing
      // This would be handled by GamificationService
      
      return true;
    } catch (e) {
      print('Error sharing achievement: $e');
      return false;
    }
  }

  /// Get friend leaderboard
  Future<List<Map<String, dynamic>>> getFriendLeaderboard() async {
    try {
      final userId = await DatabaseService.getOrCreateLocalUserId();
      final supabase = DatabaseService.getSupabaseClient();
      
      if (supabase != null && _friends.isNotEmpty) {
        // Build OR query for user_id in list
        final userIds = [userId, ..._friends];
        
        // Fetch all leaderboard entries and filter in Dart
        // (Supabase doesn't have in_ method, so we filter client-side)
        final allResponse = await supabase
            .from('leaderboard')
            .select()
            .order('xp', ascending: false);
        
        // Filter to only include our friends and current user
        final filtered = allResponse
            .where((entry) => userIds.contains(entry['user_id']))
            .map((r) => Map<String, dynamic>.from(r))
            .toList();
        
        return filtered;
      }
      
      return [];
    } catch (e) {
      print('Error getting friend leaderboard: $e');
      return [];
    }
  }

  /// Search users by username
  Future<List<Map<String, dynamic>>> searchUsers(String query) async {
    try {
      final supabase = DatabaseService.getSupabaseClient();
      
      if (supabase != null) {
        // Search in user_profiles for username
        final response = await supabase
            .from('user_profiles')
            .select()
            .ilike('data->>username', '%$query%')
            .limit(10);
        
        // Also get leaderboard data for these users
        final results = <Map<String, dynamic>>[];
        for (var profile in response) {
          final userId = profile['user_id'];
          final data = profile['data'] as Map<String, dynamic>?;
          
          // Get leaderboard entry
          final leaderboardEntry = await supabase
              .from('leaderboard')
              .select()
              .eq('user_id', userId)
              .maybeSingle();
          
          results.add({
            'user_id': userId,
            'username': data?['username'] ?? data?['displayName'] ?? 'User',
            'level': leaderboardEntry?['level'] ?? 1,
            'xp': leaderboardEntry?['xp'] ?? 0,
          });
        }
        
        return results;
      }
      
      return [];
    } catch (e) {
      print('Error searching users: $e');
      return [];
    }
  }

  /// Add friend by invite code
  Future<bool> addFriendByInviteCode(String inviteCode) async {
    try {
      final supabase = DatabaseService.getSupabaseClient();
      
      if (supabase != null) {
        // Find user by invite code (first 8 chars of user_id)
        final allProfiles = await supabase
            .from('user_profiles')
            .select();
        
        // Find user whose ID starts with the invite code
        for (var profile in allProfiles) {
          final userId = profile['user_id'] as String;
          if (userId.toUpperCase().startsWith(inviteCode.toUpperCase())) {
            return await sendFriendRequest(userId);
          }
        }
      }
      
      return false;
    } catch (e) {
      print('Error adding friend by invite code: $e');
      return false;
    }
  }

  /// Decline friend request
  Future<bool> declineFriendRequest(String requestId) async {
    try {
      final supabase = DatabaseService.getSupabaseClient();
      
      if (supabase != null) {
        await supabase.from('friends')
            .delete()
            .eq('id', requestId);
      }
      
      await loadFriends();
      return true;
    } catch (e) {
      print('Error declining friend request: $e');
      return false;
    }
  }
}

