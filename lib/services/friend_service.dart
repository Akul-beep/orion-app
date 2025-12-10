import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'database_service.dart';
import 'notification_manager.dart';

/// Friend data model
class Friend {
  final String userId;
  final String displayName;
  final String? email;
  final String? photoUrl;
  final double? portfolioValue;
  final int? level;
  final int? xp;
  final int? streak;
  final DateTime? lastActive;
  final DateTime friendsSince;

  Friend({
    required this.userId,
    required this.displayName,
    this.email,
    this.photoUrl,
    this.portfolioValue,
    this.level,
    this.xp,
    this.streak,
    this.lastActive,
    required this.friendsSince,
  });

  factory Friend.fromJson(Map<String, dynamic> json) {
    return Friend(
      userId: json['user_id'] as String,
      displayName: json['display_name'] as String? ?? 'User',
      email: json['email'] as String?,
      photoUrl: json['photo_url'] as String?,
      portfolioValue: (json['portfolio_value'] as num?)?.toDouble(),
      level: json['level'] as int?,
      xp: json['xp'] as int?,
      streak: json['streak'] as int?,
      lastActive: json['last_active'] != null 
          ? DateTime.parse(json['last_active'] as String)
          : null,
      friendsSince: DateTime.parse(json['friends_since'] as String),
    );
  }
}

/// Friend request data model
class FriendRequest {
  final String id;
  final String fromUserId;
  final String fromDisplayName;
  final String? fromPhotoUrl;
  final String toUserId;
  final DateTime createdAt;
  final String status; // 'pending', 'accepted', 'rejected'

  FriendRequest({
    required this.id,
    required this.fromUserId,
    required this.fromDisplayName,
    this.fromPhotoUrl,
    required this.toUserId,
    required this.createdAt,
    this.status = 'pending',
  });

  factory FriendRequest.fromJson(Map<String, dynamic> json) {
    return FriendRequest(
      id: json['id'] as String,
      fromUserId: json['from_user_id'] as String,
      fromDisplayName: json['from_display_name'] as String? ?? 'User',
      fromPhotoUrl: json['from_photo_url'] as String?,
      toUserId: json['to_user_id'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      status: json['status'] as String? ?? 'pending',
    );
  }
}

/// Friend Service - Competitive friend system
class FriendService extends ChangeNotifier {
  static final FriendService _instance = FriendService._internal();
  factory FriendService() => _instance;
  FriendService._internal();

  List<Friend> _friends = [];
  List<FriendRequest> _pendingRequests = []; // Requests sent TO current user
  List<FriendRequest> _sentRequests = []; // Requests sent BY current user
  bool _initialized = false;

  List<Friend> get friends => _friends;
  List<FriendRequest> get pendingRequests => _pendingRequests;
  List<FriendRequest> get sentRequests => _sentRequests;
  int get friendCount => _friends.length;
  int get pendingRequestCount => _pendingRequests.length;

  /// Initialize and load friend data
  Future<void> initialize() async {
    if (_initialized) return;
    await Future.wait([
      _loadFriends(),
      _loadPendingRequests(),
      _loadSentRequests(),
    ]);
    _initialized = true;
    notifyListeners();
  }

  /// Load friends list
  Future<void> _loadFriends() async {
    try {
      final supabase = DatabaseService.getSupabaseClient();
      
      if (supabase == null) {
        _friends = [];
        return;
      }

      // Use authenticated user ID if available, otherwise use local ID
      String userId;
      if (supabase.auth.currentUser != null) {
        userId = supabase.auth.currentUser!.id;
      } else {
        userId = await DatabaseService.getOrCreateLocalUserId();
        // Can't load friends without authentication
        if (userId.startsWith('local_')) {
          _friends = [];
          return;
        }
      }

      // Get all friendships where current user is either user_id or friend_id
      final friendships = await supabase
          .from('friends')
          .select('*')
          .or('user_id.eq.$userId,friend_id.eq.$userId')
          .eq('status', 'accepted');

      if (friendships.isEmpty) {
        _friends = [];
        return;
      }

      // Extract friend user IDs
      final friendIds = friendships.map((f) {
        final fid = f['friend_id'] as String;
        final uid = f['user_id'] as String;
        return fid == userId ? uid : fid;
      }).toList();

      // Get friend profiles
      final friendsList = <Friend>[];
      for (final friendId in friendIds) {
        try {
          // Get user profile
          final profileResponse = await supabase
              .from('user_profiles')
              .select('user_id, data')
              .eq('user_id', friendId)
              .maybeSingle();

          if (profileResponse == null) continue;

          // Extract data from JSONB column
          final profileData = profileResponse['data'];
          Map<String, dynamic> dataMap;
          if (profileData is Map) {
            dataMap = Map<String, dynamic>.from(profileData);
          } else if (profileData is String) {
            try {
              dataMap = Map<String, dynamic>.from(jsonDecode(profileData));
            } catch (e) {
              print('Error parsing profile data for $friendId: $e');
              continue;
            }
          } else {
            continue;
          }

          // Get portfolio value
          double? portfolioValue;
          try {
            final portfolioResponse = await supabase
                .from('portfolio')
                .select('data')
                .eq('user_id', friendId)
                .maybeSingle();

            if (portfolioResponse != null && portfolioResponse['data'] != null) {
              final portfolioData = portfolioResponse['data'] as Map<String, dynamic>;
              portfolioValue = (portfolioData['totalValue'] as num?)?.toDouble();
            }
          } catch (e) {
            print('Error loading portfolio for friend $friendId: $e');
          }

          // Get gamification stats
          Map<String, dynamic>? gamificationData;
          try {
            final gamificationResponse = await supabase
                .from('gamification')
                .select('data')
                .eq('user_id', friendId)
                .maybeSingle();

            if (gamificationResponse != null && gamificationResponse['data'] != null) {
              final gData = gamificationResponse['data'];
              if (gData is Map) {
                gamificationData = Map<String, dynamic>.from(gData);
              } else if (gData is String) {
                gamificationData = Map<String, dynamic>.from(jsonDecode(gData));
              }
            }
          } catch (e) {
            print('Error loading gamification for friend $friendId: $e');
          }

          final friendship = friendships.firstWhere(
            (f) => (f['friend_id'] == userId && f['user_id'] == friendId) ||
                   (f['user_id'] == userId && f['friend_id'] == friendId),
          );

          friendsList.add(Friend(
            userId: friendId,
            displayName: dataMap['displayName'] as String? ?? 
                        dataMap['name'] as String? ??
                        dataMap['display_name'] as String? ?? 'User',
            email: dataMap['email'] as String?,
            photoUrl: dataMap['photoURL'] as String? ?? 
                     dataMap['photo_url'] as String? ??
                     dataMap['avatar'] as String?,
            portfolioValue: portfolioValue,
            level: gamificationData?['level'] as int?,
            xp: gamificationData?['totalXP'] as int? ?? gamificationData?['total_xp'] as int?,
            streak: gamificationData?['streak'] as int?,
            lastActive: dataMap['lastActiveAt'] != null
                ? DateTime.parse(dataMap['lastActiveAt'] as String)
                : dataMap['last_active'] != null
                    ? DateTime.parse(dataMap['last_active'] as String)
                    : null,
            friendsSince: DateTime.parse(friendship['created_at'] as String),
          ));
        } catch (e) {
          print('Error loading friend $friendId: $e');
          continue;
        }
      }

      _friends = friendsList;
      notifyListeners();
    } catch (e) {
      print('Error loading friends: $e');
      _friends = [];
    }
  }

  /// Load pending friend requests (requests TO current user)
  Future<void> _loadPendingRequests() async {
    try {
      final supabase = DatabaseService.getSupabaseClient();
      
      if (supabase == null) {
        _pendingRequests = [];
        return;
      }

      // Use authenticated user ID if available
      String userId;
      if (supabase.auth.currentUser != null) {
        userId = supabase.auth.currentUser!.id;
      } else {
        userId = await DatabaseService.getOrCreateLocalUserId();
        // Can't load requests without authentication
        if (userId.startsWith('local_')) {
          _pendingRequests = [];
          return;
        }
      }

      final requests = await supabase
          .from('friend_requests')
          .select('*')
          .eq('to_user_id', userId)
          .eq('status', 'pending')
          .order('created_at', ascending: false);

      _pendingRequests = requests.map((r) => FriendRequest.fromJson(r)).toList();
      notifyListeners();
    } catch (e) {
      print('Error loading pending requests: $e');
      _pendingRequests = [];
    }
  }

  /// Load sent friend requests (requests BY current user)
  Future<void> _loadSentRequests() async {
    try {
      final supabase = DatabaseService.getSupabaseClient();
      
      if (supabase == null) {
        _sentRequests = [];
        return;
      }

      // Use authenticated user ID if available
      String userId;
      if (supabase.auth.currentUser != null) {
        userId = supabase.auth.currentUser!.id;
      } else {
        userId = await DatabaseService.getOrCreateLocalUserId();
        // Can't load requests without authentication
        if (userId.startsWith('local_')) {
          _sentRequests = [];
          return;
        }
      }

      final requests = await supabase
          .from('friend_requests')
          .select('*')
          .eq('from_user_id', userId)
          .eq('status', 'pending')
          .order('created_at', ascending: false);

      _sentRequests = requests.map((r) => FriendRequest.fromJson(r)).toList();
      notifyListeners();
    } catch (e) {
      print('Error loading sent requests: $e');
      _sentRequests = [];
    }
  }

  /// Search for users by name or email
  Future<List<Map<String, dynamic>>> searchUsers(String query) async {
    try {
      final supabase = DatabaseService.getSupabaseClient();
      
      if (supabase == null || query.isEmpty || query.length < 2) {
        print('⚠️ Search conditions not met: supabase=${supabase != null}, query="$query"');
        return [];
      }

      // Check if user is authenticated - search requires authentication
      if (supabase.auth.currentUser == null) {
        print('❌ Search requires authentication. User not logged in.');
        return [];
      }

      final userId = supabase.auth.currentUser!.id;
      print('🔍 Searching for users with query: "$query" (userId: $userId)');

      List<Map<String, dynamic>> results = [];

      try {
        final searchQuery = query.toLowerCase().trim();
        print('🔍 Searching for: "$searchQuery"');
        
        print('📡 Fetching user profiles from database...');
        
        List<Map<String, dynamic>> allProfiles = [];
        
        try {
          // Query user_profiles - should work now with updated RLS policy
          final profilesResponse = await supabase
              .from('user_profiles')
              .select('user_id, data')
              .limit(1000); // Increased limit for better search
            
          allProfiles = List<Map<String, dynamic>>.from(profilesResponse);
          print('✅ Successfully fetched ${allProfiles.length} profiles');
        } catch (e, stackTrace) {
          print('❌ Error fetching profiles: $e');
          print('Stack trace: $stackTrace');
          print('   This might be due to RLS policies blocking access.');
          print('   Make sure you ran fix_user_profiles_search_rls.sql in Supabase!');
          return [];
        }

        print('📊 Fetched ${allProfiles.length} total profiles from database');

        if (allProfiles.isEmpty) {
          print('⚠️ No user profiles found in database at all!');
          return [];
        }

        int processedCount = 0;
        int matchCount = 0;
        
        for (final profile in allProfiles) {
          try {
            processedCount++;
            final profileUserId = profile['user_id'];
            
            // Convert user_id to string for comparison
            String profileUserIdStr;
            if (profileUserId is String) {
              profileUserIdStr = profileUserId;
            } else {
              profileUserIdStr = profileUserId.toString();
            }
            
            // Skip current user - handle both UUID and local_ formats
            final currentUserIdStr = userId.toString();
            if (profileUserIdStr == currentUserIdStr || 
                profileUserIdStr.replaceAll('-', '') == currentUserIdStr.replaceAll('-', '')) {
              continue;
            }

            // Get data field
            final profileData = profile['data'];
            if (profileData == null) {
              continue;
            }

            // Parse data - it should be a Map already from Supabase
            Map<String, dynamic> dataMap;
            if (profileData is Map) {
              dataMap = Map<String, dynamic>.from(profileData);
            } else if (profileData is String) {
              // Try to parse as JSON string
              try {
                dataMap = Map<String, dynamic>.from(jsonDecode(profileData));
              } catch (e) {
                print('⚠️ Profile $profileUserIdStr has invalid JSON data: $e');
                continue;
              }
            } else {
              print('⚠️ Profile $profileUserIdStr has non-Map data: ${profileData.runtimeType}');
              continue;
            }

            // Extract name and email
            final displayName = (dataMap['displayName'] as String? ?? 
                                dataMap['name'] as String? ?? 
                                dataMap['display_name'] as String? ?? '').toLowerCase();
            final email = (dataMap['email'] as String? ?? '').toLowerCase();

            // Debug first few profiles
            if (processedCount <= 3) {
              print('📋 Profile $processedCount: userId=$profileUserIdStr, name="$displayName", email="$email"');
            }

            // Check if query matches name or email (case-insensitive)
            final nameMatches = displayName.isNotEmpty && displayName.contains(searchQuery);
            final emailMatches = email.isNotEmpty && email.contains(searchQuery);
            
            if (nameMatches || emailMatches) {
              matchCount++;
              print('✅ MATCH #$matchCount: $displayName / $email');
              results.add({
                'user_id': profileUserIdStr,
                'display_name': dataMap['displayName'] ?? dataMap['name'] ?? dataMap['display_name'] ?? 'User',
                'name': dataMap['name'] ?? dataMap['displayName'] ?? dataMap['display_name'] ?? 'User',
                'email': dataMap['email'],
                'photo_url': dataMap['photoURL'] ?? dataMap['photo_url'] ?? dataMap['avatar'],
              });
            }
          } catch (e, stackTrace) {
            print('⚠️ Error processing profile #$processedCount: $e');
            print('Stack: $stackTrace');
            continue;
          }
        }

        print('✅ Processed $processedCount profiles, found $matchCount matches');

        // Filter out existing friends and pending requests
        final friendIds = _friends.map((f) => f.userId.toString()).toSet();
        final pendingFromIds = _pendingRequests.map((r) => r.fromUserId.toString()).toSet();
        final sentToIds = _sentRequests.map((r) => r.toUserId.toString()).toSet();

        final beforeFilter = results.length;
        results = results.where((user) {
          final uid = user['user_id']?.toString() ?? '';
          final isFriend = friendIds.contains(uid);
          final hasPendingFrom = pendingFromIds.contains(uid);
          final hasSentTo = sentToIds.contains(uid);
          
          if (isFriend || hasPendingFrom || hasSentTo) {
            print('🚫 Filtered out user $uid (friend: $isFriend, pending: $hasPendingFrom, sent: $hasSentTo)');
          }
          
          return !isFriend && !hasPendingFrom && !hasSentTo;
        }).toList();

        print('✅ After filtering: ${results.length} available users (filtered out ${beforeFilter - results.length})');
      } catch (e, stackTrace) {
        print('❌ Error searching user_profiles: $e');
        print('Stack trace: $stackTrace');
      }

      return results.take(20).toList();
    } catch (e, stackTrace) {
      print('❌ Error searching users: $e');
      print('Stack trace: $stackTrace');
      return [];
    }
  }

  /// Send friend request
  Future<bool> sendFriendRequest(String toUserId) async {
    try {
      final userId = await DatabaseService.getOrCreateLocalUserId();
      final supabase = DatabaseService.getSupabaseClient();
      
      if (supabase == null) {
        print('❌ Cannot send friend request: Supabase not available');
        return false;
      }

      // Check if user is authenticated with Supabase (not just local ID)
      final isAuthenticated = supabase.auth.currentUser != null;
      if (!isAuthenticated) {
        print('⚠️ User not authenticated with Supabase. Cannot send friend request.');
        print('   Current user ID: $userId');
        return false;
      }

      // Use authenticated user ID (Supabase UUID)
      final authenticatedUserId = supabase.auth.currentUser!.id;
      
      // Ensure toUserId is also a valid UUID (not a local ID)
      if (toUserId.startsWith('local_')) {
        print('❌ Cannot send friend request to local user ID: $toUserId');
        return false;
      }

      // Get current user profile
      final userProfile = await DatabaseService.loadUserProfile();
      final displayName = userProfile?['displayName'] ?? 
                         userProfile?['name'] ?? 
                         userProfile?['display_name'] ??
                         supabase.auth.currentUser?.email?.split('@')[0] ??
                         'User';
      
      final photoUrl = userProfile?['photoURL'] ?? 
                      userProfile?['photo_url'] ?? 
                      userProfile?['avatar'];

      print('📤 Sending friend request from $authenticatedUserId to $toUserId');

      // Check if request already exists (in either direction)
      try {
        final existing = await supabase
            .from('friend_requests')
            .select('id, status')
            .or('and(from_user_id.eq.$authenticatedUserId,to_user_id.eq.$toUserId),and(from_user_id.eq.$toUserId,to_user_id.eq.$authenticatedUserId)')
            .maybeSingle();

        if (existing != null) {
          final status = existing['status'] as String?;
          if (status == 'pending') {
            print('⚠️ Friend request already exists (pending)');
            return false;
          } else if (status == 'accepted') {
            print('⚠️ Users are already friends');
            return false;
          }
        }
      } catch (e) {
        print('⚠️ Error checking existing requests: $e');
        // Continue anyway - might be a new request
      }

      // Check if already friends
      try {
        final existingFriendship = await supabase
            .from('friends')
            .select('id')
            .or('and(user_id.eq.$authenticatedUserId,friend_id.eq.$toUserId),and(user_id.eq.$toUserId,friend_id.eq.$authenticatedUserId)')
            .eq('status', 'accepted')
            .maybeSingle();
        
        if (existingFriendship != null) {
          print('⚠️ Users are already friends');
          return false;
        }
      } catch (e) {
        print('⚠️ Error checking existing friendship: $e');
        // Continue anyway
      }

      // Create friend request
      try {
        await supabase.from('friend_requests').insert({
          'from_user_id': authenticatedUserId,
          'from_display_name': displayName,
          'from_photo_url': photoUrl,
          'to_user_id': toUserId,
          'status': 'pending',
          'created_at': DateTime.now().toIso8601String(),
        });
        
        print('✅ Friend request created successfully');
      } catch (e) {
        print('❌ Error creating friend request: $e');
        print('   Error type: ${e.runtimeType}');
        // Check if it's a unique constraint violation
        if (e.toString().contains('unique') || e.toString().contains('duplicate')) {
          print('   Request already exists');
          return false;
        }
        rethrow;
      }

      // Add notification to recipient
      try {
        await NotificationManager().addNotification(
          type: 'friend_request',
          title: 'New Friend Request',
          message: '$displayName wants to be your friend!',
          data: {'from_user_id': authenticatedUserId, 'to_user_id': toUserId},
        );
      } catch (e) {
        print('⚠️ Error adding notification: $e');
        // Don't fail the request if notification fails
      }

      await _loadSentRequests();
      notifyListeners();
      return true;
    } catch (e, stackTrace) {
      print('❌ Error sending friend request: $e');
      print('Stack trace: $stackTrace');
      return false;
    }
  }

  /// Accept friend request
  Future<bool> acceptFriendRequest(String requestId) async {
    try {
      final supabase = DatabaseService.getSupabaseClient();
      
      if (supabase == null) return false;

      // Use authenticated user ID
      if (supabase.auth.currentUser == null) {
        print('❌ Cannot accept friend request: User not authenticated');
        return false;
      }

      final userId = supabase.auth.currentUser!.id;

      // Get request details
      final request = await supabase
          .from('friend_requests')
          .select('*')
          .eq('id', requestId)
          .eq('to_user_id', userId)
          .eq('status', 'pending')
          .maybeSingle();

      if (request == null) {
        print('❌ Friend request not found or already processed');
        return false;
      }

      final fromUserId = request['from_user_id'] as String;

      // Update request status
      await supabase
          .from('friend_requests')
          .update({'status': 'accepted'})
          .eq('id', requestId);

      // Create friendship (bidirectional)
      final now = DateTime.now().toIso8601String();
      try {
        await supabase.from('friends').insert({
          'user_id': userId,
          'friend_id': fromUserId,
          'status': 'accepted',
          'created_at': now,
        });
        print('✅ Friendship created successfully');
      } catch (e) {
        print('❌ Error creating friendship: $e');
        // Check if friendship already exists
        if (e.toString().contains('unique') || e.toString().contains('duplicate')) {
          print('   Friendship already exists, continuing...');
        } else {
          rethrow;
        }
      }

      // Add notification to requester
      try {
        final userProfile = await DatabaseService.loadUserProfile();
        final displayName = userProfile?['displayName'] ?? 
                           userProfile?['name'] ?? 'User';
        await NotificationManager().addNotification(
          type: 'friend_request_accepted',
          title: 'Friend Request Accepted!',
          message: '$displayName accepted your friend request!',
          data: {'user_id': userId, 'friend_id': fromUserId},
        );
      } catch (e) {
        print('Error adding notification: $e');
      }

      await Future.wait([
        _loadFriends(),
        _loadPendingRequests(),
      ]);
      
      return true;
    } catch (e) {
      print('Error accepting friend request: $e');
      return false;
    }
  }

  /// Reject friend request
  Future<bool> rejectFriendRequest(String requestId) async {
    try {
      final supabase = DatabaseService.getSupabaseClient();
      if (supabase == null) return false;

      // Use authenticated user ID
      if (supabase.auth.currentUser == null) {
        print('❌ Cannot reject friend request: User not authenticated');
        return false;
      }

      final userId = supabase.auth.currentUser!.id;

      // Verify the request is to current user
      final request = await supabase
          .from('friend_requests')
          .select('to_user_id')
          .eq('id', requestId)
          .maybeSingle();

      if (request == null || request['to_user_id'] != userId) {
        print('❌ Friend request not found or not for current user');
        return false;
      }

      await supabase
          .from('friend_requests')
          .update({'status': 'rejected'})
          .eq('id', requestId);

      await _loadPendingRequests();
      notifyListeners();
      return true;
    } catch (e) {
      print('Error rejecting friend request: $e');
      return false;
    }
  }

  /// Remove friend
  Future<bool> removeFriend(String friendId) async {
    try {
      final supabase = DatabaseService.getSupabaseClient();
      
      if (supabase == null) return false;

      // Use authenticated user ID
      if (supabase.auth.currentUser == null) {
        print('❌ Cannot remove friend: User not authenticated');
        return false;
      }

      final userId = supabase.auth.currentUser!.id;

      // Delete friendship (both directions)
      await supabase
          .from('friends')
          .delete()
          .or('and(user_id.eq.$userId,friend_id.eq.$friendId),and(user_id.eq.$friendId,friend_id.eq.$userId)');

      await _loadFriends();
      notifyListeners();
      return true;
    } catch (e) {
      print('Error removing friend: $e');
      return false;
    }
  }

  /// Cancel sent friend request
  Future<bool> cancelFriendRequest(String requestId) async {
    try {
      final supabase = DatabaseService.getSupabaseClient();
      if (supabase == null) return false;

      // Use authenticated user ID to verify ownership
      if (supabase.auth.currentUser == null) {
        print('❌ Cannot cancel friend request: User not authenticated');
        return false;
      }

      final userId = supabase.auth.currentUser!.id;

      // Verify the request belongs to current user before deleting
      final request = await supabase
          .from('friend_requests')
          .select('from_user_id')
          .eq('id', requestId)
          .maybeSingle();

      if (request == null || request['from_user_id'] != userId) {
        print('❌ Friend request not found or not owned by user');
        return false;
      }

      await supabase
          .from('friend_requests')
          .delete()
          .eq('id', requestId);

      await _loadSentRequests();
      notifyListeners();
      return true;
    } catch (e) {
      print('Error canceling friend request: $e');
      return false;
    }
  }

  /// Refresh friend data (call periodically to update portfolio values, etc.)
  Future<void> refresh() async {
    await Future.wait([
      _loadFriends(),
      _loadPendingRequests(),
      _loadSentRequests(),
    ]);
  }
}

