import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/paper_trade.dart';
import '../services/gamification_service.dart';

/// Database service for persisting user data
/// Uses Supabase (PostgreSQL) with SharedPreferences (local fallback)
class DatabaseService {
  static SupabaseClient? _supabase;
  static SharedPreferences? _prefs;
  static bool _supabaseAvailable = false;
  
  // Leaderboard cache (in-memory)
  static final Map<String, Map<String, dynamic>> _leaderboardCache = {};
  static const Duration _leaderboardCacheTTL = Duration(minutes: 3); // Cache for 3 minutes

  // Notification templates cache (in-memory)
  static List<Map<String, dynamic>>? _notificationTemplatesCache;
  static DateTime? _notificationTemplatesCacheTime;
  static const Duration _notificationTemplatesCacheTTL = Duration(hours: 1); // Cache for 1 hour

  /// Initialize database service
  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    
    // Check if Supabase is available
    try {
      _supabase = Supabase.instance.client;
      
      // Verify Supabase is actually working by testing a simple query
      try {
        print('🔍 Testing Supabase connection...');
        // Try a simple query to verify connection works
        await _supabase!.from('leaderboard').select('count').limit(1);
        _supabaseAvailable = true;
        print('✅ Supabase services available and working!');
      } catch (testError) {
        print('⚠️ Supabase client exists but query failed: $testError');
        print('   This might be an RLS policy issue or network problem');
        // Still mark as available - might just be a policy issue
        _supabaseAvailable = true;
      }
    } catch (e, stackTrace) {
      _supabaseAvailable = false;
      _supabase = null;
      print('❌ Supabase not initialized - using local storage only');
      print('   Error: $e');
      print('   Stack trace: $stackTrace');
      print('💡 To enable Supabase, check main.dart initialization');
    }
  }
  
  /// Check if Supabase is available
  static bool get isSupabaseAvailable => _supabaseAvailable;

  /// Get Supabase client (for services that need direct access)
  static SupabaseClient? getSupabaseClient() => _supabase;

  /// Get current user ID (or generate a local one)
  static String? getUserId() {
    return _supabase?.auth.currentUser?.id ?? _prefs?.getString('local_user_id');
  }

  /// Generate and save local user ID if not authenticated
  static Future<String> getOrCreateLocalUserId() async {
    if (_supabaseAvailable && _supabase?.auth.currentUser != null) {
      return _supabase!.auth.currentUser!.id;
    }
    
    final userId = _prefs?.getString('local_user_id');
    if (userId != null) {
      return userId;
    }
    
    final newUserId = 'local_${DateTime.now().millisecondsSinceEpoch}';
    await _prefs?.setString('local_user_id', newUserId);
    return newUserId;
  }

  // ========== PORTFOLIO DATA ==========

  /// Save portfolio data
  static Future<void> savePortfolio(Map<String, dynamic> portfolioData) async {
    print('💾 ========== SAVE PORTFOLIO ==========');
    
    // Always save locally first (fast and reliable)
    await _prefs?.setString('portfolio_data', jsonEncode(portfolioData));
    print('✅ Portfolio saved to local storage');
    
    // Then try to save to Supabase if authenticated
    try {
      if (_supabaseAvailable && _supabase?.auth.currentUser != null) {
        // CRITICAL: Use authenticated user ID, not local ID
        final authenticatedUserId = _supabase!.auth.currentUser!.id;
        print('   User authenticated: $authenticatedUserId');
        print('   Saving to Supabase...');
        
        try {
          await _supabase!.from('portfolio').upsert({
            'user_id': authenticatedUserId, // Use authenticated UUID, not local ID
            'data': portfolioData,
            'updated_at': DateTime.now().toIso8601String(),
          });
          print('✅ Portfolio saved to Supabase successfully');
          
          // Verify it was saved
          try {
            await Future.delayed(const Duration(milliseconds: 500));
            final verify = await _supabase!
                .from('portfolio')
                .select()
                .eq('user_id', authenticatedUserId)
                .maybeSingle();
            
            if (verify != null) {
              print('✅ Verification: Portfolio exists in Supabase');
              final savedData = verify['data'] as Map<String, dynamic>?;
              final positions = savedData?['positions'] as List?;
              print('   Saved positions count: ${positions?.length ?? 0}');
              print('   Saved cash balance: ${savedData?['cashBalance']}');
            } else {
              print('⚠️ WARNING: Portfolio not found after save!');
            }
          } catch (verifyError) {
            print('⚠️ Could not verify save: $verifyError');
          }
        } catch (e) {
          print('❌ Supabase save portfolio error: $e');
          print('   Error type: ${e.runtimeType}');
          print('   Error details: ${e.toString()}');
          // Don't throw - we still saved locally
        }
      } else {
        print('⚠️ Supabase not available or user not authenticated');
        print('   Supabase available: $_supabaseAvailable');
        print('   User authenticated: ${_supabase?.auth.currentUser != null}');
        print('   Portfolio saved to local storage only');
      }
    } catch (e) {
      print('❌ Error in savePortfolio: $e');
      // Don't throw - we still saved locally
    }
    
    print('💾 ========== SAVE COMPLETE ==========');
  }

  /// Load portfolio data
  /// Also MIGRATES legacy local-only data to Supabase for authenticated users
  static Future<Map<String, dynamic>?> loadPortfolio() async {
    print('📥 ========== LOAD PORTFOLIO ==========');
    
    bool triedSupabase = false;
    bool supabaseHadData = false;
    
    try {
      // Try Supabase first if authenticated
      if (_supabaseAvailable && _supabase?.auth.currentUser != null) {
        // CRITICAL: Use authenticated user ID, not local ID
        final authenticatedUserId = _supabase!.auth.currentUser!.id;
        print('   User authenticated: $authenticatedUserId');
        print('   Loading from Supabase...');
        triedSupabase = true;
        
        try {
          final response = await _supabase!
              .from('portfolio')
              .select()
              .eq('user_id', authenticatedUserId) // Use authenticated UUID
              .maybeSingle();
          
          print('   Supabase response: ${response != null ? "FOUND" : "NOT FOUND"}');
          
          if (response != null && response['data'] != null) {
            supabaseHadData = true;
            final data = Map<String, dynamic>.from(response['data'] as Map);
            final positions = data['positions'] as List?;
            print('✅ Portfolio loaded from Supabase');
            print('   Positions count: ${positions?.length ?? 0}');
            print('   Cash balance: ${data['cashBalance']}');
            print('   Total value: ${data['totalValue']}');
            
            // ALWAYS sync Supabase data to local storage (overwrite local)
            await _prefs?.setString('portfolio_data', jsonEncode(data));
            print('✅ Synced Supabase data to local storage');
            
            print('📥 ========== LOAD COMPLETE (FROM SUPABASE) ==========');
            return data;
          } else {
            print('⚠️ No portfolio found in Supabase for user: $authenticatedUserId');
            print('   This might be a new user or portfolio not created yet');
            print('   Will check local storage...');
          }
        } catch (e) {
          print('❌ Supabase load portfolio error: $e');
          print('   Error type: ${e.runtimeType}');
          print('   Error details: ${e.toString()}');
          print('   Will try local storage as fallback');
        }
      } else {
        print('⚠️ Supabase not available or user not authenticated');
        print('   Supabase available: $_supabaseAvailable');
        print('   User authenticated: ${_supabase?.auth.currentUser != null}');
        print('   Will try local storage as fallback');
      }
    } catch (e) {
      print('❌ Error in loadPortfolio: $e');
      print('   Will try local storage as fallback');
    }
    
    // Fallback to local storage (and MIGRATE to Supabase if needed)
    try {
      final localData = _prefs?.getString('portfolio_data');
      if (localData != null) {
        final data = jsonDecode(localData) as Map<String, dynamic>;
        final positions = data['positions'] as List?;
        print('✅ Portfolio loaded from local storage');
        print('   Positions count: ${positions?.length ?? 0}');
        print('   Cash balance: ${data['cashBalance']}');
        
        // If we are authenticated and Supabase had no data, MIGRATE local -> Supabase
        if (_supabaseAvailable && _supabase?.auth.currentUser != null && triedSupabase && !supabaseHadData) {
          try {
            print('🔄 MIGRATION: Syncing local portfolio to Supabase for authenticated user...');
            await savePortfolio(data); // This will upsert using authenticated user ID
            print('✅ MIGRATION: Local portfolio synced to Supabase');
          } catch (e) {
            print('⚠️ MIGRATION ERROR: Could not sync local portfolio to Supabase: $e');
          }
        }
        
        print('📥 ========== LOAD COMPLETE (FROM LOCAL) ==========');
        return data;
      } else {
        print('⚠️ No portfolio data found in local storage either');
        print('📥 ========== LOAD COMPLETE (NO DATA) ==========');
      }
    } catch (e) {
      print('❌ Error loading from local storage: $e');
    }
    
    return null;
  }

  // ========== TRADE HISTORY ==========

  /// Save trade to history
  static Future<void> saveTrade(PaperTrade trade) async {
    final userId = await getOrCreateLocalUserId();
    final tradeData = trade.toJson();
    
    // Always save to local storage first (fast, reliable)
    final trades = await loadTradeHistory();
    trades.insert(0, tradeData);
    // Keep only last 100 trades locally
    if (trades.length > 100) {
      trades.removeRange(100, trades.length);
    }
    await _prefs?.setString('trade_history', jsonEncode(trades));
    
    // Then try to save to Supabase (even if not authenticated, use local user ID)
    try {
      if (_supabaseAvailable) {
        try {
          await _supabase!.from('trades').insert({
            'user_id': userId,
            'trade_data': tradeData,
            'created_at': trade.timestamp.toIso8601String(),
          });
          print('✅ Saved trade to Supabase: ${trade.symbol} ${trade.action} ${trade.quantity} @ ${trade.price}');
        } catch (e) {
          print('⚠️ Supabase save trade error (data saved locally): $e');
        }
      }
    } catch (e) {
      print('⚠️ Supabase save trade error: $e');
    }
  }

  /// Load trade history
  static Future<List<Map<String, dynamic>>> loadTradeHistory() async {
    final userId = await getOrCreateLocalUserId();
    
    try {
      // Try Supabase first (even if not authenticated, use local user ID)
      if (_supabaseAvailable) {
        try {
          final response = await _supabase!
              .from('trades')
              .select()
              .eq('user_id', userId)
              .order('created_at', ascending: false)
              .limit(100);
          
          if (response.isNotEmpty) {
            final trades = response.map((r) => Map<String, dynamic>.from(r['trade_data'] as Map)).toList();
            // Sync to local storage as backup
            await _prefs?.setString('trade_history', jsonEncode(trades));
            print('✅ Loaded ${trades.length} trades from Supabase');
            return trades;
          }
        } catch (e) {
          print('⚠️ Supabase load trades error (will try local): $e');
        }
      }
    } catch (e) {
      print('⚠️ Supabase load trades error: $e');
    }
    
    // Fallback to local
    final localData = _prefs?.getString('trade_history');
    if (localData != null) {
      final trades = List<Map<String, dynamic>>.from(jsonDecode(localData));
      print('✅ Loaded ${trades.length} trades from local storage');
      return trades;
    }
    
    return [];
  }

  // ========== GAMIFICATION DATA ==========

  /// Save gamification progress
  static Future<void> saveGamificationData(Map<String, dynamic> data) async {
    final userId = await getOrCreateLocalUserId();
    
    // Always save to local storage first (fast, reliable)
    await _prefs?.setString('gamification_data', jsonEncode(data));
    
    // Then try to save to Supabase (even if not authenticated, use local user ID)
    try {
      if (_supabaseAvailable) {
        try {
          await _supabase!.from('gamification').upsert({
            'user_id': userId,
            'data': data,
            'updated_at': DateTime.now().toIso8601String(),
          });
          print('✅ Saved gamification data to Supabase: ${data['totalXP']} XP, ${data['streak']} streak');
        } catch (e) {
          print('⚠️ Supabase save gamification error (data saved locally): $e');
        }
      }
    } catch (e) {
      print('⚠️ Supabase save gamification error: $e');
    }
  }

  /// Load gamification progress for a specific user (for referral rewards)
  static Future<Map<String, dynamic>?> loadGamificationDataForUser(String userId) async {
    try {
      if (_supabaseAvailable) {
        try {
          final response = await _supabase!
              .from('gamification')
              .select()
              .eq('user_id', userId)
              .maybeSingle();
          
          if (response != null && response['data'] != null) {
            return Map<String, dynamic>.from(response['data'] as Map);
          }
        } catch (e) {
          print('⚠️ Supabase load gamification for user error: $e');
        }
      }
    } catch (e) {
      print('⚠️ Error loading gamification for user: $e');
    }
    return null;
  }

  /// Save gamification data for a specific user (for referral rewards)
  static Future<void> saveGamificationDataForUser(String userId, Map<String, dynamic> data) async {
    try {
      if (_supabaseAvailable) {
        try {
          await _supabase!.from('gamification').upsert({
            'user_id': userId,
            'data': data,
            'updated_at': DateTime.now().toIso8601String(),
          });
          print('✅ Saved gamification data for user $userId: ${data['totalXP']} XP');
        } catch (e) {
          print('⚠️ Supabase save gamification for user error: $e');
        }
      }
    } catch (e) {
      print('⚠️ Error saving gamification for user: $e');
    }
  }

  /// Load portfolio data for a specific user (for referral rewards)
  static Future<Map<String, dynamic>?> loadPortfolioForUser(String userId) async {
    try {
      if (_supabaseAvailable) {
        try {
          final response = await _supabase!
              .from('portfolio')
              .select()
              .eq('user_id', userId)
              .maybeSingle();
          
          if (response != null && response['data'] != null) {
            return Map<String, dynamic>.from(response['data'] as Map);
          }
        } catch (e) {
          print('⚠️ Supabase load portfolio for user error: $e');
        }
      }
    } catch (e) {
      print('⚠️ Error loading portfolio for user: $e');
    }
    return null;
  }

  /// Save portfolio data for a specific user (for referral rewards)
  static Future<void> savePortfolioForUser(String userId, Map<String, dynamic> portfolioData) async {
    try {
      if (_supabaseAvailable) {
        try {
          await _supabase!.from('portfolio').upsert({
            'user_id': userId,
            'data': portfolioData,
            'updated_at': DateTime.now().toIso8601String(),
          });
          print('✅ Saved portfolio for user $userId');
        } catch (e) {
          print('⚠️ Supabase save portfolio for user error: $e');
        }
      }
    } catch (e) {
      print('⚠️ Error saving portfolio for user: $e');
    }
  }

  /// Load gamification progress
  /// Also MIGRATES legacy local-only data to Supabase for authenticated users
  static Future<Map<String, dynamic>?> loadGamificationData() async {
    String? authenticatedUserId = _supabaseAvailable ? _supabase?.auth.currentUser?.id : null;
    final localUserId = _prefs?.getString('local_user_id');
    
    try {
      // If Supabase and authenticated, try loading by authenticated user ID first
      if (_supabaseAvailable && authenticatedUserId != null) {
        try {
          print('🔍 Loading gamification for authenticated user: $authenticatedUserId');
          final response = await _supabase!
              .from('gamification')
              .select()
              .eq('user_id', authenticatedUserId)
              .maybeSingle();
          
          if (response != null && response['data'] != null) {
            final data = Map<String, dynamic>.from(response['data'] as Map);
            // Sync to local storage as backup
            await _prefs?.setString('gamification_data', jsonEncode(data));
            print('✅ Loaded gamification data from Supabase (auth user): ${data['totalXP']} XP, ${data['streak']} streak');
            return data;
          } else {
            print('⚠️ No gamification data found for authenticated user in Supabase');
          }
        } catch (e) {
          print('⚠️ Supabase load gamification error for authenticated user (will try local/migration): $e');
        }
      }
    } catch (e) {
      print('⚠️ Supabase load gamification error: $e');
    }
    
    // Fallback to local storage
    final localData = _prefs?.getString('gamification_data');
    if (localData != null) {
      final data = jsonDecode(localData) as Map<String, dynamic>;
      print('✅ Loaded gamification data from local storage: ${data['totalXP']} XP, ${data['streak']} streak');
      
      // If authenticated and Supabase had no data, MIGRATE local -> Supabase under authenticated ID
      if (_supabaseAvailable && authenticatedUserId != null) {
        try {
          print('🔄 MIGRATION: Syncing local gamification data to Supabase for authenticated user...');
          await saveGamificationDataForUser(authenticatedUserId, data);
          print('✅ MIGRATION: Local gamification data synced to Supabase for $authenticatedUserId');
        } catch (e) {
          print('⚠️ MIGRATION ERROR: Could not sync local gamification data to Supabase: $e');
        }
      } else if (_supabaseAvailable && authenticatedUserId == null && localUserId != null) {
        // Legacy behavior: ensure Supabase row exists for local user ID
        try {
          print('🔄 Ensuring legacy local user gamification exists in Supabase: $localUserId');
          await saveGamificationDataForUser(localUserId, data);
        } catch (e) {
          print('⚠️ Legacy gamification save error: $e');
        }
      }
      
      return data;
    }
    
    print('⚠️ No gamification data found in database or local storage');
    return null;
  }

  // ========== DAILY GOALS ==========

  /// Save daily goals data
  static Future<void> saveDailyGoals(Map<String, dynamic> data) async {
    final userId = await getOrCreateLocalUserId();
    
    try {
      // Try Supabase first
      if (_supabaseAvailable && _supabase?.auth.currentUser != null) {
        await _supabase!.from('daily_goals').upsert({
          'user_id': userId,
          'data': data,
          'updated_at': DateTime.now().toIso8601String(),
        });
      }
    } catch (e) {
      print('Supabase save daily goals error: $e');
    }
    
    // Always save locally as fallback
    await _prefs?.setString('daily_goals_data', jsonEncode(data));
  }

  /// Load daily goals data
  static Future<Map<String, dynamic>?> loadDailyGoals() async {
    final userId = await getOrCreateLocalUserId();
    
    try {
      if (_supabaseAvailable && _supabase?.auth.currentUser != null) {
        final response = await _supabase!
            .from('daily_goals')
            .select()
            .eq('user_id', userId)
            .maybeSingle();
        
        if (response != null && response['data'] != null) {
          final data = Map<String, dynamic>.from(response['data'] as Map);
          await _prefs?.setString('daily_goals', jsonEncode(data));
          return data;
        }
      }
    } catch (e) {
      print('Supabase load daily goals error: $e');
    }
    
    final localData = _prefs?.getString('daily_goals');
    if (localData != null) {
      return jsonDecode(localData) as Map<String, dynamic>;
    }
    return null;
  }

  // ========== WEEKLY CHALLENGES ==========

  /// Save weekly challenge data
  static Future<void> saveWeeklyChallenge(Map<String, dynamic> data) async {
    final userId = await getOrCreateLocalUserId();
    
    try {
      if (_supabaseAvailable && _supabase?.auth.currentUser != null) {
        await _supabase!.from('weekly_challenges').upsert({
          'user_id': userId,
          'data': data,
          'updated_at': DateTime.now().toIso8601String(),
        });
      }
    } catch (e) {
      print('Supabase save weekly challenge error: $e');
    }
    
    await _prefs?.setString('weekly_challenge', jsonEncode(data));
  }

  /// Load weekly challenge data
  static Future<Map<String, dynamic>?> loadWeeklyChallenge() async {
    final userId = await getOrCreateLocalUserId();
    
    try {
      if (_supabaseAvailable && _supabase?.auth.currentUser != null) {
        final response = await _supabase!
            .from('weekly_challenges')
            .select()
            .eq('user_id', userId)
            .maybeSingle();
        
        if (response != null && response['data'] != null) {
          final data = Map<String, dynamic>.from(response['data'] as Map);
          await _prefs?.setString('weekly_challenge', jsonEncode(data));
          return data;
        }
      }
    } catch (e) {
      print('Supabase load weekly challenge error: $e');
    }
    
    final localData = _prefs?.getString('weekly_challenge');
    if (localData != null) {
      return jsonDecode(localData) as Map<String, dynamic>;
    }
    return null;
  }

  // ========== MONTHLY CHALLENGES ==========

  /// Save monthly challenge data
  static Future<void> saveMonthlyChallenge(Map<String, dynamic> data) async {
    final userId = await getOrCreateLocalUserId();
    
    try {
      if (_supabaseAvailable && _supabase?.auth.currentUser != null) {
        await _supabase!.from('monthly_challenges').upsert({
          'user_id': userId,
          'data': data,
          'updated_at': DateTime.now().toIso8601String(),
        });
      }
    } catch (e) {
      print('Supabase save monthly challenge error: $e');
    }
    
    await _prefs?.setString('monthly_challenge', jsonEncode(data));
  }

  /// Load monthly challenge data
  static Future<Map<String, dynamic>?> loadMonthlyChallenge() async {
    final userId = await getOrCreateLocalUserId();
    
    try {
      if (_supabaseAvailable && _supabase?.auth.currentUser != null) {
        final response = await _supabase!
            .from('monthly_challenges')
            .select()
            .eq('user_id', userId)
            .maybeSingle();
        
        if (response != null && response['data'] != null) {
          final data = Map<String, dynamic>.from(response['data'] as Map);
          await _prefs?.setString('monthly_challenge', jsonEncode(data));
          return data;
        }
      }
    } catch (e) {
      print('Supabase load monthly challenge error: $e');
    }
    
    final localData = _prefs?.getString('monthly_challenge');
    if (localData != null) {
      return jsonDecode(localData) as Map<String, dynamic>;
    }
    
    return null;
  }

  /// Save monthly challenge completion
  static Future<void> saveMonthlyChallengeCompletion(Map<String, dynamic> data) async {
    final userId = await getOrCreateLocalUserId();
    
    try {
      if (_supabaseAvailable && _supabase?.auth.currentUser != null) {
        await _supabase!.from('monthly_challenge_completions').insert({
          'user_id': userId,
          'data': data,
          'completed_at': DateTime.now().toIso8601String(),
        });
      }
    } catch (e) {
      print('Supabase save monthly challenge completion error: $e');
    }
  }

  // ========== FRIEND QUESTS ==========

  /// Save friend quest data
  static Future<void> saveFriendQuest(Map<String, dynamic> data) async {
    final userId = await getOrCreateLocalUserId();
    
    try {
      if (_supabaseAvailable && _supabase?.auth.currentUser != null) {
        await _supabase!.from('friend_quests').upsert({
          'user_id': userId,
          'data': data,
          'updated_at': DateTime.now().toIso8601String(),
        });
      }
    } catch (e) {
      print('Supabase save friend quest error: $e');
    }
    
    await _prefs?.setString('friend_quest', jsonEncode(data));
  }

  /// Load friend quest data
  static Future<Map<String, dynamic>?> loadFriendQuest() async {
    final userId = await getOrCreateLocalUserId();
    
    try {
      if (_supabaseAvailable && _supabase?.auth.currentUser != null) {
        final response = await _supabase!
            .from('friend_quests')
            .select()
            .eq('user_id', userId)
            .maybeSingle();
        
        if (response != null && response['data'] != null) {
          final data = Map<String, dynamic>.from(response['data'] as Map);
          await _prefs?.setString('friend_quest', jsonEncode(data));
          return data;
        }
      }
    } catch (e) {
      print('Supabase load friend quest error: $e');
    }
    
    final localData = _prefs?.getString('friend_quest');
    if (localData != null) {
      return jsonDecode(localData) as Map<String, dynamic>;
    }
    
    return null;
  }

  /// Save friend quest progress (for both users)
  static Future<void> saveFriendQuestProgress(String questId, String userId, int progress) async {
    try {
      if (_supabaseAvailable && _supabase?.auth.currentUser != null) {
        await _supabase!.from('friend_quest_progress').upsert({
          'quest_id': questId,
          'user_id': userId,
          'progress': progress,
          'updated_at': DateTime.now().toIso8601String(),
        });
      }
    } catch (e) {
      print('Supabase save friend quest progress error: $e');
    }
  }

  /// Load friend quest progress (combined progress from both users)
  static Future<Map<String, int>?> loadFriendQuestProgress(String questId) async {
    try {
      if (_supabaseAvailable && _supabase?.auth.currentUser != null) {
        final response = await _supabase!
            .from('friend_quest_progress')
            .select()
            .eq('quest_id', questId);
        
        final progress = <String, int>{};
        for (final entry in response) {
          progress[entry['user_id'] as String] = entry['progress'] as int;
        }
        return progress;
      }
    } catch (e) {
      print('Supabase load friend quest progress error: $e');
    }
    
    return null;
  }

  /// Save friend quest completion
  static Future<void> saveFriendQuestCompletion(Map<String, dynamic> data) async {
    final userId = await getOrCreateLocalUserId();
    
    try {
      if (_supabaseAvailable && _supabase?.auth.currentUser != null) {
        await _supabase!.from('friend_quest_completions').insert({
          'user_id': userId,
          'data': data,
          'completed_at': DateTime.now().toIso8601String(),
        });
      }
    } catch (e) {
      print('Supabase save friend quest completion error: $e');
    }
  }

  /// Save weekly challenge completion
  static Future<void> saveWeeklyChallengeCompletion(Map<String, dynamic> data) async {
    final userId = await getOrCreateLocalUserId();
    
    try {
      if (_supabaseAvailable && _supabase?.auth.currentUser != null) {
        await _supabase!.from('challenge_completions').insert({
          'user_id': userId,
          'challenge_id': data['challengeId'],
          'completed_at': data['completedAt'],
          'reward': data['reward'],
        });
      }
    } catch (e) {
      print('Supabase save challenge completion error: $e');
    }
    
    final completions = _prefs?.getStringList('challenge_completions') ?? [];
    completions.add(jsonEncode(data));
    await _prefs?.setStringList('challenge_completions', completions);
  }

  // ========== STREAK PROTECTION ==========

  /// Save streak protection data
  static Future<void> saveStreakProtection(Map<String, dynamic> data) async {
    final userId = await getOrCreateLocalUserId();
    
    try {
      if (_supabaseAvailable && _supabase?.auth.currentUser != null) {
        await _supabase!.from('streak_protection').upsert({
          'user_id': userId,
          'freezes_available': data['freezesAvailable'],
          'freezes_used': data['freezesUsed'],
          'last_freeze_date': data['lastFreezeDate'],
          'updated_at': DateTime.now().toIso8601String(),
        });
      }
    } catch (e) {
      print('Supabase save streak protection error: $e');
    }
    
    await _prefs?.setString('streak_protection', jsonEncode(data));
  }

  /// Load streak protection data
  static Future<Map<String, dynamic>?> loadStreakProtection() async {
    final userId = await getOrCreateLocalUserId();
    
    try {
      if (_supabaseAvailable && _supabase?.auth.currentUser != null) {
        final response = await _supabase!
            .from('streak_protection')
            .select()
            .eq('user_id', userId)
            .maybeSingle();
        
        if (response != null) {
          final data = {
            'freezesAvailable': response['freezes_available'] ?? 0,
            'freezesUsed': response['freezes_used'] ?? 0,
            'lastFreezeDate': response['last_freeze_date'],
          };
          await _prefs?.setString('streak_protection', jsonEncode(data));
          return data;
        }
      }
    } catch (e) {
      print('Supabase load streak protection error: $e');
    }
    
    final localData = _prefs?.getString('streak_protection');
    if (localData != null) {
      return jsonDecode(localData) as Map<String, dynamic>;
    }
    return null;
  }

  /// Save streak freeze usage
  static Future<void> saveStreakFreeze(Map<String, dynamic> data) async {
    final userId = await getOrCreateLocalUserId();
    
    try {
      if (_supabaseAvailable && _supabase?.auth.currentUser != null) {
        await _supabase!.from('streak_freezes').insert({
          'user_id': userId,
          'used_at': data['usedAt'],
          'streak': data['streak'],
        });
      }
    } catch (e) {
      print('Supabase save streak freeze error: $e');
    }
    
    final freezes = _prefs?.getStringList('streak_freezes') ?? [];
    freezes.add(jsonEncode(data));
    await _prefs?.setStringList('streak_freezes', freezes);
  }

  // ========== NOTIFICATIONS ==========

  /// Save notifications
  static Future<void> saveNotifications(Map<String, dynamic> data) async {
    // Always save to local storage first (fast, reliable)
    await _prefs?.setString('notifications', jsonEncode(data));
    
    // Then try to save to Supabase using authenticated user ID when available
    try {
      if (_supabaseAvailable && _supabase?.auth.currentUser != null) {
        final authenticatedUserId = _supabase!.auth.currentUser!.id;
        await _supabase!.from('notifications').upsert({
          'user_id': authenticatedUserId,
          'data': data,
          'updated_at': DateTime.now().toIso8601String(),
        });
      }
    } catch (e) {
      print('Supabase save notifications error: $e');
    }
  }

  /// Load notifications
  static Future<Map<String, dynamic>?> loadNotifications() async {
    String? authenticatedUserId = _supabaseAvailable ? _supabase?.auth.currentUser?.id : null;
    
    try {
      // If Supabase and authenticated, load notifications from cloud first
      if (_supabaseAvailable && authenticatedUserId != null) {
        final response = await _supabase!
            .from('notifications')
            .select()
            .eq('user_id', authenticatedUserId)
            .maybeSingle();
        
        if (response != null && response['data'] != null) {
          final data = Map<String, dynamic>.from(response['data'] as Map);
          await _prefs?.setString('notifications', jsonEncode(data));
          return data;
        }
      }
    } catch (e) {
      print('Supabase load notifications error: $e');
    }
    
    // Fallback to local storage
    final localData = _prefs?.getString('notifications');
    if (localData != null) {
      return jsonDecode(localData) as Map<String, dynamic>;
    }
    return null;
  }

  // ========== DAILY LESSONS ==========

  /// Save daily lesson unlock data
  static Future<void> saveDailyLessons(Map<String, dynamic> data) async {
    final userId = await getOrCreateLocalUserId();
    
    // Always save to local storage first (fast, reliable)
    await _prefs?.setString('daily_lessons', jsonEncode(data));
    
    // Then try to save to Supabase (even if not authenticated, use local user ID)
    try {
      if (_supabaseAvailable) {
        try {
          await _supabase!.from('daily_lessons').upsert({
            'user_id': userId,
            'data': data,
            'updated_at': DateTime.now().toIso8601String(),
          });
          print('✅ Saved daily lessons to Supabase');
        } catch (e) {
          print('⚠️ Supabase save daily lessons error (data saved locally): $e');
        }
      }
    } catch (e) {
      print('⚠️ Supabase save daily lessons error: $e');
    }
  }

  /// Load daily lesson unlock data
  static Future<Map<String, dynamic>?> loadDailyLessons() async {
    final userId = await getOrCreateLocalUserId();
    
    try {
      // Try Supabase first (even if not authenticated, use local user ID)
      if (_supabaseAvailable) {
        try {
          final response = await _supabase!
              .from('daily_lessons')
              .select()
              .eq('user_id', userId)
              .maybeSingle();
          
          if (response != null && response['data'] != null) {
            final data = Map<String, dynamic>.from(response['data'] as Map);
            // Sync to local storage as backup
            await _prefs?.setString('daily_lessons', jsonEncode(data));
            print('✅ Loaded daily lessons from Supabase');
            return data;
          }
        } catch (e) {
          print('⚠️ Supabase load daily lessons error (will try local): $e');
        }
      }
    } catch (e) {
      print('⚠️ Supabase load daily lessons error: $e');
    }
    
    // Fallback to local storage
    final localData = _prefs?.getString('daily_lessons');
    if (localData != null) {
      print('✅ Loaded daily lessons from local storage');
      return jsonDecode(localData) as Map<String, dynamic>;
    }
    
    print('⚠️ No daily lessons data found');
    return null;
  }

  // ========== FRIEND ACTIVITY ==========

  /// Save friend activity
  static Future<void> saveFriendActivity(Map<String, dynamic> activity) async {
    final userId = await getOrCreateLocalUserId();
    
    try {
      if (_supabaseAvailable && _supabase?.auth.currentUser != null) {
        await _supabase!.from('friend_activities').insert({
          'user_id': userId,
          'activity_type': activity['type'],
          'activity_data': activity['data'],
          'created_at': DateTime.now().toIso8601String(),
        });
      }
    } catch (e) {
      print('Supabase save friend activity error: $e');
    }
  }

  /// Get friend activities
  static Future<List<Map<String, dynamic>>> getFriendActivities({int limit = 50}) async {
    final userId = await getOrCreateLocalUserId();
    
    try {
      if (_supabaseAvailable && _supabase?.auth.currentUser != null) {
        // Get friends list first
        final friendsResponse = await _supabase!
            .from('friends')
            .select('friend_id')
            .eq('user_id', userId);
        
        final friendIds = friendsResponse.map((r) => r['friend_id'] as String).toList();
        
        if (friendIds.isNotEmpty) {
          // Query activities for each friend and combine results
          // This is more reliable than using in_ which may not be available
          List<Map<String, dynamic>> allActivities = [];
          
          for (final friendId in friendIds) {
            try {
              final activitiesResponse = await _supabase!
                  .from('friend_activities')
                  .select()
                  .eq('user_id', friendId)
                  .order('created_at', ascending: false)
                  .limit(limit);
              
              allActivities.addAll(
                activitiesResponse.map((r) => Map<String, dynamic>.from(r)).toList()
              );
            } catch (e) {
              print('Error fetching activities for friend $friendId: $e');
            }
          }
          
          // Sort by created_at and limit
          allActivities.sort((a, b) {
            final aTime = DateTime.parse(a['created_at'] ?? DateTime.now().toIso8601String());
            final bTime = DateTime.parse(b['created_at'] ?? DateTime.now().toIso8601String());
            return bTime.compareTo(aTime);
          });
          
          return allActivities.take(limit).toList();
        }
      }
    } catch (e) {
      print('Supabase get friend activities error: $e');
    }
    
    return [];
  }


  // ========== LEARNING ACTIONS ==========

  /// Save completed learning action
  static Future<void> saveCompletedAction(String actionId) async {
    await saveCompletedActionWithXP(actionId, null);
  }
  
  /// Save completed learning action with XP earned
  static Future<void> saveCompletedActionWithXP(String actionId, int? xpEarned) async {
    final userId = await getOrCreateLocalUserId();
    
    // Always save to local storage first (fast, reliable)
    final completedActions = _prefs?.getStringList('completed_actions') ?? [];
    if (!completedActions.contains(actionId)) {
      completedActions.add(actionId);
      await _prefs?.setStringList('completed_actions', completedActions);
    }
    
    // Store completion date locally (for daily check)
    final completionDate = DateTime.now().toIso8601String();
    await _prefs?.setString('action_date_$actionId', completionDate);
    
    // Store XP earned locally
    if (xpEarned != null) {
      await _prefs?.setInt('action_xp_$actionId', xpEarned);
    }
    
    // Then try to save to Supabase (even if not authenticated, use local user ID)
    try {
      if (_supabaseAvailable) {
        try {
          final data = {
            'user_id': userId,
            'action_id': actionId,
            'completed_at': completionDate,
          };
          if (xpEarned != null) {
            data['xp_earned'] = xpEarned.toString();
          }
          await _supabase!.from('completed_actions').upsert(data);
          print('✅ Saved completed action to Supabase: $actionId');
        } catch (e) {
          print('⚠️ Supabase save completed action error (data saved locally): $e');
        }
      }
    } catch (e) {
      print('⚠️ Supabase save completed action error: $e');
    }
  }

  /// Get all completed learning actions
  static Future<List<String>> getCompletedActions() async {
    final userId = await getOrCreateLocalUserId();
    
    try {
      // Try Supabase first (even if not authenticated, use local user ID)
      if (_supabaseAvailable) {
        try {
          final response = await _supabase!
              .from('completed_actions')
              .select('action_id')
              .eq('user_id', userId);
          final actions = response.map((r) => r['action_id'] as String).toList();
          // Sync to local storage as backup
          if (actions.isNotEmpty) {
            await _prefs?.setStringList('completed_actions', actions);
          }
          print('✅ Loaded ${actions.length} completed actions from Supabase');
          return actions;
        } catch (e) {
          print('⚠️ Supabase load completed actions error (will try local): $e');
        }
      }
    } catch (e) {
      print('⚠️ Supabase load completed actions error: $e');
    }
    
    // Fallback to local storage
    final localActions = _prefs?.getStringList('completed_actions') ?? [];
    print('✅ Loaded ${localActions.length} completed actions from local storage');
    return localActions;
  }
  
  /// Get completion date for a specific action (returns null if not completed)
  static Future<DateTime?> getActionCompletionDate(String actionId) async {
    final userId = await getOrCreateLocalUserId();
    
    try {
      // Try Supabase first (even if not authenticated, use local user ID)
      if (_supabaseAvailable) {
        try {
          final response = await _supabase!
              .from('completed_actions')
              .select('completed_at')
              .eq('user_id', userId)
              .eq('action_id', actionId)
              .maybeSingle();
          
          if (response != null && response['completed_at'] != null) {
            final date = DateTime.parse(response['completed_at']);
            // Sync to local storage as backup
            await _prefs?.setString('action_date_$actionId', date.toIso8601String());
            return date;
          }
        } catch (e) {
          print('⚠️ Supabase get action completion date error (will try local): $e');
        }
      }
    } catch (e) {
      print('⚠️ Supabase get action completion date error: $e');
    }
    
    // Fallback to local storage
    final dateString = _prefs?.getString('action_date_$actionId');
    if (dateString != null) {
      try {
        return DateTime.parse(dateString);
      } catch (e) {
        return null;
      }
    }
    
    return null;
  }
  
  /// Check if action was completed today
  static Future<bool> isActionCompletedToday(String actionId) async {
    final completionDate = await getActionCompletionDate(actionId);
    if (completionDate == null) return false;
    
    final today = DateTime.now();
    final completionDay = DateTime(completionDate.year, completionDate.month, completionDate.day);
    final todayDay = DateTime(today.year, today.month, today.day);
    
    return completionDay.isAtSameMomentAs(todayDay);
  }

  // ========== LEADERBOARD ==========

  /// Invalidate leaderboard cache (call when data changes)
  static void _invalidateLeaderboardCache() {
    _leaderboardCache.clear();
    print('🗑️ Leaderboard cache invalidated');
    
    // Also clear SharedPreferences cache
    try {
      final keys = _prefs?.getKeys();
      if (keys != null) {
        for (final key in keys) {
          if (key.startsWith('leaderboard_cache_')) {
            _prefs?.remove(key);
          }
        }
        print('   💾 Cleared SharedPreferences leaderboard cache');
      }
    } catch (e) {
      print('⚠️ Error clearing SharedPreferences cache: $e');
    }
  }

  /// Update user leaderboard entry
  static Future<void> updateLeaderboardEntry({
    required String userId,
    required String displayName,
    required int xp,
    required int streak,
    required int level,
    required int badges,
    double? portfolioValue,
  }) async {
    print('📊 ========== UPDATE LEADERBOARD ENTRY ==========');
    print('   User: $userId, Name: $displayName, XP: $xp, Level: $level');
    
    // Get better name from profile if available
    String finalDisplayName = displayName;
    String? avatar = '🎯';
    
    try {
      if (_supabaseAvailable && _supabase?.auth.currentUser != null) {
        // Use authenticated user ID
        final authenticatedUserId = _supabase!.auth.currentUser!.id;
        
        // Try to get better name from profile
        try {
          final profile = await loadUserProfile();
          if (profile != null) {
            final profileName = profile['displayName'] ?? profile['name'] ?? profile['display_name'];
            if (profileName != null && profileName.toString().isNotEmpty && profileName != 'User') {
              finalDisplayName = profileName.toString();
              print('   ✅ Using profile name: $finalDisplayName');
            }
            
            final profileAvatar = profile['avatar'] ?? profile['photoURL'] ?? profile['photo_url'];
            if (profileAvatar != null) {
              avatar = profileAvatar.toString();
            }
          }
        } catch (e) {
          print('   ⚠️ Could not get profile: $e');
        }
        
        final leaderboardData = {
          'user_id': authenticatedUserId, // Use authenticated UUID
          'display_name': finalDisplayName,
          'xp': xp,
          'streak': streak,
          'level': level,
          'badges': badges,
          'updated_at': DateTime.now().toIso8601String(),
          'avatar': avatar,
        };
        
        // Add portfolio value - always include it, default to $10,000 if null to prevent $0 display
        leaderboardData['portfolio_value'] = portfolioValue ?? 10000.0;
        
        try {
          await _supabase!.from('leaderboard').upsert(leaderboardData);
          print('✅ Leaderboard entry updated successfully');
          print('   Portfolio value saved: ${leaderboardData['portfolio_value'] ?? 'null'}');
          
          // Invalidate cache for all sort types (since user's position may change in any category)
          _invalidateLeaderboardCache();
          
          // Verify it was saved
          try {
            await Future.delayed(const Duration(milliseconds: 300));
            final verify = await _supabase!
                .from('leaderboard')
                .select('portfolio_value')
                .eq('user_id', authenticatedUserId)
                .maybeSingle();
            
            if (verify != null) {
              print('   Verified portfolio_value in DB: ${verify['portfolio_value']}');
            }
          } catch (verifyError) {
            print('⚠️ Could not verify portfolio_value: $verifyError');
          }
        } catch (e) {
          print('❌ Supabase update leaderboard error: $e');
          print('   Leaderboard data: $leaderboardData');
        }
      } else {
        print('⚠️ Supabase not available or user not authenticated');
      }
    } catch (e) {
      print('❌ Error updating leaderboard: $e');
    }
    
    // Also save locally for offline leaderboard
    try {
      final localLeaderboard = getLocalLeaderboard();
      localLeaderboard.removeWhere((entry) => 
        entry['user_id'] == userId || entry['userId'] == userId
      );
      localLeaderboard.add({
        'user_id': userId,
        'userId': userId,
        'display_name': finalDisplayName,
        'displayName': finalDisplayName,
        'xp': xp,
        'streak': streak,
        'level': level,
        'badges': badges,
        'portfolio_value': portfolioValue ?? 10000.0, // Default to starting balance, never $0
        'portfolioValue': portfolioValue ?? 10000.0,
        'updated_at': DateTime.now().toIso8601String(),
        'avatar': avatar,
      });
      await _prefs?.setString('local_leaderboard', jsonEncode(localLeaderboard));
    } catch (e) {
      print('⚠️ Error saving local leaderboard: $e');
    }
  }

  /// Get leaderboard data
  static Future<List<Map<String, dynamic>>> getLeaderboard({
    String sortBy = 'xp',
    int limit = 50,
    bool forceRefresh = false,
  }) async {
    print('📊 ========== GET LEADERBOARD ==========');
    print('   Sort by: $sortBy, Limit: $limit, Force refresh: $forceRefresh');
    
    // Map UI sortBy to database column name
    String dbSortBy = sortBy;
    if (sortBy.toLowerCase() == 'portfolio') {
      dbSortBy = 'portfolio_value';
    }
    
    // Create cache key
    final cacheKey = 'leaderboard_${sortBy.toLowerCase()}_$limit';
    
    // Check cache first (unless force refresh)
    if (!forceRefresh) {
      final cached = _leaderboardCache[cacheKey];
      if (cached != null) {
        final cachedTime = cached['timestamp'] as DateTime?;
        if (cachedTime != null) {
          final age = DateTime.now().difference(cachedTime);
          if (age < _leaderboardCacheTTL) {
            print('   ✅ Using cached leaderboard (age: ${age.inSeconds}s)');
            return List<Map<String, dynamic>>.from(cached['data'] as List);
          } else {
            print('   ⏰ Cache expired (age: ${age.inSeconds}s), fetching fresh data');
          }
        }
      }
      
      // Also try SharedPreferences as backup cache
      try {
        final cachedJson = _prefs?.getString('leaderboard_cache_$cacheKey');
        if (cachedJson != null) {
          final cachedData = jsonDecode(cachedJson) as Map<String, dynamic>;
          final cachedTime = DateTime.parse(cachedData['timestamp'] as String);
          final age = DateTime.now().difference(cachedTime);
          if (age < _leaderboardCacheTTL) {
            print('   ✅ Using SharedPreferences cached leaderboard (age: ${age.inSeconds}s)');
            final data = List<Map<String, dynamic>>.from(
              (cachedData['data'] as List).map((e) => Map<String, dynamic>.from(e))
            );
            // Also update in-memory cache
            _leaderboardCache[cacheKey] = {
              'data': data,
              'timestamp': cachedTime,
            };
            return data;
          }
        }
      } catch (e) {
        print('   ⚠️ Error reading SharedPreferences cache: $e');
      }
    }
    
    try {
      if (_supabaseAvailable && _supabase != null) {
        print('   🔍 Supabase available, attempting to fetch leaderboard...');
        // Build query - filter out users with $10,000 portfolio (starting amount) for portfolio tab
        // NOTE: Leaderboard should be viewable by everyone, not just authenticated users
        var query = _supabase!.from('leaderboard').select();
        
        // For portfolio leaderboard, exclude users who haven't started trading ($10,000 = starting balance)
        if (sortBy.toLowerCase() == 'portfolio' || dbSortBy == 'portfolio_value') {
          // Filter out $10,000 portfolios (starting amount) - users who haven't traded yet
          // Use gt (greater than) to exclude exactly $10,000
          query = query.gt('portfolio_value', 10000.0);
          print('   Filtering out users with \$10,000 portfolio (starting amount)');
        }
        
        // Get leaderboard entries
        print('   📊 Executing leaderboard query: sortBy=$dbSortBy, limit=$limit');
        final response = await query
            .order(dbSortBy, ascending: false)
            .limit(limit);
        
        print('   ✅ Query successful! Found ${response.length} leaderboard entries');
        
        if (response.isNotEmpty) {
          // Enrich with user profile data (names, avatars)
          final enrichedLeaderboard = <Map<String, dynamic>>[];
          
          for (int i = 0; i < response.length; i++) {
            final entry = Map<String, dynamic>.from(response[i] as Map);
            final userId = entry['user_id'] as String?;
            
            // Try to get user profile for better name/avatar
            if (userId != null) {
              try {
                final profileResponse = await _supabase!
                    .from('user_profiles')
                    .select('data')
                    .eq('user_id', userId)
                    .maybeSingle();
                
                if (profileResponse != null && profileResponse['data'] != null) {
                  final profileData = profileResponse['data'];
                  Map<String, dynamic> dataMap;
                  if (profileData is Map) {
                    dataMap = Map<String, dynamic>.from(profileData);
                  } else if (profileData is String) {
                    dataMap = Map<String, dynamic>.from(jsonDecode(profileData));
                  } else {
                    dataMap = {};
                  }
                  
                  // Update display name from profile if available
                  final profileName = dataMap['displayName'] ?? 
                                     dataMap['name'] ?? 
                                     dataMap['display_name'];
                  if (profileName != null && profileName.toString().isNotEmpty && profileName != 'User') {
                    entry['display_name'] = profileName.toString();
                    print('   ✅ Updated name for $userId: $profileName');
                  }
                  
                  // Update avatar from profile if available
                  final profileAvatar = dataMap['avatar'] ?? 
                                       dataMap['photoURL'] ?? 
                                       dataMap['photo_url'];
                  if (profileAvatar != null) {
                    entry['avatar'] = profileAvatar.toString();
                  }
                }
              } catch (e) {
                print('   ⚠️ Could not get profile for $userId: $e');
                // Continue with leaderboard data
              }
            }
            
            // Normalize field names for consistency
            entry['userId'] = entry['user_id'] ?? userId;
            entry['displayName'] = entry['display_name'] ?? entry['displayName'] ?? 'User';
            entry['rank'] = i + 1;
            
            enrichedLeaderboard.add(entry);
          }
          
          print('✅ Returning ${enrichedLeaderboard.length} enriched leaderboard entries');
          
          // Cache the result (in-memory and SharedPreferences)
          final now = DateTime.now();
          _leaderboardCache[cacheKey] = {
            'data': enrichedLeaderboard,
            'timestamp': now,
          };
          
          // Also cache in SharedPreferences
          try {
            await _prefs?.setString('leaderboard_cache_$cacheKey', jsonEncode({
              'data': enrichedLeaderboard,
              'timestamp': now.toIso8601String(),
            }));
            print('   💾 Cached leaderboard to SharedPreferences');
          } catch (e) {
            print('   ⚠️ Error caching to SharedPreferences: $e');
          }
          
          return enrichedLeaderboard;
        } else {
          print('⚠️ No leaderboard entries found in database');
        }
      } else {
        print('⚠️ Supabase not available or user not authenticated');
      }
    } catch (e, stackTrace) {
      print('❌ Supabase get leaderboard error: $e');
      print('   Error type: ${e.runtimeType}');
      print('   Stack trace: $stackTrace');
      print('   Supabase available: $_supabaseAvailable');
      print('   Supabase client: ${_supabase != null ? "exists" : "null"}');
      
      // If it's an RLS policy error, give helpful message
      final errorStr = e.toString().toLowerCase();
      if (errorStr.contains('policy') || errorStr.contains('permission') || errorStr.contains('row level security')) {
        print('   ⚠️ This looks like an RLS (Row Level Security) policy issue!');
        print('   💡 Run fix_leaderboard_rls.sql in Supabase SQL Editor to fix this');
      }
    }
    
    // Fallback to cached leaderboard (if available and not expired)
    try {
      final cachedJson = _prefs?.getString('leaderboard_cache_$cacheKey');
      if (cachedJson != null) {
        final cachedData = jsonDecode(cachedJson) as Map<String, dynamic>;
        final cachedTime = DateTime.parse(cachedData['timestamp'] as String);
        final age = DateTime.now().difference(cachedTime);
        if (age < _leaderboardCacheTTL) {
          print('📦 Using fallback cached leaderboard (age: ${age.inSeconds}s)');
          return List<Map<String, dynamic>>.from(
            (cachedData['data'] as List).map((e) => Map<String, dynamic>.from(e))
          );
        } else {
          print('⚠️ Fallback cache expired (age: ${age.inSeconds}s)');
        }
      }
    } catch (e) {
      print('⚠️ Error reading fallback cache: $e');
    }
    
    print('⚠️ No leaderboard data available');
    return [];
  }

  /// Get local leaderboard (for offline mode)
  static List<Map<String, dynamic>> getLocalLeaderboard() {
    final localData = _prefs?.getString('local_leaderboard');
    if (localData != null) {
      final list = List<Map<String, dynamic>>.from(jsonDecode(localData));
      // Add rank
      for (int i = 0; i < list.length; i++) {
        list[i]['rank'] = i + 1;
      }
      return list;
    }
    return [];
  }

  /// Get current user's leaderboard position
  static Future<Map<String, dynamic>?> getUserLeaderboardEntry() async {
    final userId = await getOrCreateLocalUserId();
    
    print('👤 Getting leaderboard entry for user: $userId');
    
    try {
      if (_supabaseAvailable && _supabase?.auth.currentUser != null) {
        // Use authenticated user ID
        final authenticatedUserId = _supabase!.auth.currentUser!.id;
        
        final response = await _supabase!
            .from('leaderboard')
            .select()
            .eq('user_id', authenticatedUserId)
            .maybeSingle();
        
        if (response != null) {
          final entry = Map<String, dynamic>.from(response);
          // Normalize field names
          entry['userId'] = entry['user_id'] ?? authenticatedUserId;
          entry['displayName'] = entry['display_name'] ?? entry['displayName'] ?? 'User';
          
          // Try to get better name from profile
          try {
            final profile = await loadUserProfile();
            if (profile != null) {
              final profileName = profile['displayName'] ?? profile['name'] ?? profile['display_name'];
              if (profileName != null && profileName.toString().isNotEmpty && profileName != 'User') {
                entry['displayName'] = profileName.toString();
                entry['display_name'] = profileName.toString();
              }
            }
          } catch (e) {
            print('⚠️ Could not get profile for user: $e');
          }
          
          print('✅ Found leaderboard entry for user');
          return entry;
        } else {
          print('⚠️ No leaderboard entry found for user');
        }
      }
    } catch (e) {
      print('❌ Supabase get user leaderboard error: $e');
    }
    
    // Check local
    final localLeaderboard = getLocalLeaderboard();
    final localEntry = localLeaderboard.firstWhere(
      (entry) => entry['user_id'] == userId || entry['userId'] == userId,
      orElse: () => {},
    );
    
    if (localEntry.isNotEmpty) {
      localEntry['userId'] = localEntry['user_id'] ?? userId;
      localEntry['displayName'] = localEntry['display_name'] ?? localEntry['displayName'] ?? 'User';
    }
    
    return localEntry.isEmpty ? null : localEntry;
  }

  // ========== USER PROFILE ==========

  /// Save user profile (with named parameters)
  static Future<void> saveUserProfile({
    required String displayName,
    String? avatar,
    String? username,
  }) async {
    final profileData = {
      'displayName': displayName,
      'username': username ?? displayName.toLowerCase().replaceAll(' ', '_'),
      'avatar': avatar ?? '🎯',
      'createdAt': DateTime.now().toIso8601String(),
      'lastActiveAt': DateTime.now().toIso8601String(),
    };
    await saveUserProfileData(profileData);
  }

  /// Save user profile (with Map data)
  /// This function merges the provided data with existing profile data to prevent data loss
  static Future<void> saveUserProfileData(Map<String, dynamic> profileData) async {
    print('💾 ========== SAVE USER PROFILE DATA ==========');
    print('   Incoming data keys: ${profileData.keys.toList()}');
    
    // CRITICAL FIX: Load existing profile first and merge to prevent data loss
    Map<String, dynamic> mergedProfileData;
    
    if (_supabaseAvailable && _supabase?.auth.currentUser != null) {
      final supabaseUserId = _supabase!.auth.currentUser!.id;
      
      // Load existing profile from Supabase
      try {
        final existingResponse = await _supabase!
            .from('user_profiles')
            .select()
            .eq('user_id', supabaseUserId)
            .maybeSingle();
        
        if (existingResponse != null && existingResponse['data'] != null) {
          final existingData = Map<String, dynamic>.from(existingResponse['data'] as Map);
          print('✅ Found existing profile in Supabase');
          print('   Existing keys: ${existingData.keys.toList()}');
          
          // Merge: existing data first, then override with new data
          mergedProfileData = Map<String, dynamic>.from(existingData);
          mergedProfileData.addAll(profileData);
          print('✅ Merged profile data');
          print('   Merged keys: ${mergedProfileData.keys.toList()}');
        } else {
          // No existing profile, use the provided data
          print('⚠️ No existing profile found, using provided data');
          mergedProfileData = Map<String, dynamic>.from(profileData);
        }
      } catch (e) {
        print('⚠️ Error loading existing profile: $e');
        // Fallback: try local storage
        final localData = _prefs?.getString('user_profile');
        if (localData != null) {
          final existingData = jsonDecode(localData) as Map<String, dynamic>;
          print('✅ Found existing profile in local storage');
          mergedProfileData = Map<String, dynamic>.from(existingData);
          mergedProfileData.addAll(profileData);
        } else {
          mergedProfileData = Map<String, dynamic>.from(profileData);
        }
      }
    } else {
      // Not authenticated, try local storage
      final localData = _prefs?.getString('user_profile');
      if (localData != null) {
        final existingData = jsonDecode(localData) as Map<String, dynamic>;
        print('✅ Found existing profile in local storage');
        mergedProfileData = Map<String, dynamic>.from(existingData);
        mergedProfileData.addAll(profileData);
      } else {
        mergedProfileData = Map<String, dynamic>.from(profileData);
      }
    }
    
    // Always update updatedAt timestamp
    mergedProfileData['updatedAt'] = DateTime.now().toIso8601String();
    
    // Ensure critical fields are the correct types (defensive programming)
    if (mergedProfileData['displayName'] != null && mergedProfileData['displayName'] is! String) {
      print('⚠️ WARNING: displayName is not a String, converting...');
      mergedProfileData['displayName'] = mergedProfileData['displayName'].toString();
    }
    if (mergedProfileData['name'] != null && mergedProfileData['name'] is! String) {
      print('⚠️ WARNING: name is not a String, converting...');
      mergedProfileData['name'] = mergedProfileData['name'].toString();
    }
    if (mergedProfileData['reminderTime'] != null && mergedProfileData['reminderTime'] is! String) {
      print('⚠️ WARNING: reminderTime is not a String, converting...');
      mergedProfileData['reminderTime'] = mergedProfileData['reminderTime'].toString();
    }
    if (mergedProfileData['notificationsEnabled'] != null && mergedProfileData['notificationsEnabled'] is! bool) {
      print('⚠️ WARNING: notificationsEnabled is not a bool, converting...');
      mergedProfileData['notificationsEnabled'] = mergedProfileData['notificationsEnabled'] == true || 
                                                   mergedProfileData['notificationsEnabled'] == 'true' ||
                                                   mergedProfileData['notificationsEnabled'] == 1;
    }
    
    print('   Final merged data keys: ${mergedProfileData.keys.toList()}');
    print('   Notifications enabled: ${mergedProfileData['notificationsEnabled']} (type: ${mergedProfileData['notificationsEnabled'].runtimeType})');
    print('   Reminder time: ${mergedProfileData['reminderTime']} (type: ${mergedProfileData['reminderTime']?.runtimeType})');
    print('   Display name: ${mergedProfileData['displayName']} (type: ${mergedProfileData['displayName']?.runtimeType})');
    
    // Always save locally first (fast and reliable)
    await _prefs?.setString('user_profile', jsonEncode(mergedProfileData));
    print('✅ Profile saved to local storage');
    
    // Then try to save to Supabase - MUST be authenticated with Supabase UUID
    try {
      if (_supabaseAvailable && _supabase?.auth.currentUser != null) {
        // Use the actual Supabase UUID, not local ID
        final supabaseUserId = _supabase!.auth.currentUser!.id;
        print('   User authenticated: $supabaseUserId');
        
        // Ensure we're using the Supabase UUID, not a local ID
        if (supabaseUserId.startsWith('local_')) {
          print('❌ ERROR: Cannot save to Supabase with local user ID!');
          print('   User must be authenticated with Supabase to save profile data.');
          return;
        }
        
        print('   Executing upsert to user_profiles table...');
        
        // Use upsert - will insert or update based on user_id (primary key)
        final result = await _supabase!.from('user_profiles').upsert({
          'user_id': supabaseUserId,
          'data': mergedProfileData,
          'updated_at': DateTime.now().toIso8601String(),
        });
        
        print('✅ Profile saved to Supabase successfully');
        
        // Verify it was saved by immediately loading it back
        try {
          await Future.delayed(const Duration(milliseconds: 500)); // Wait for DB to update
          final verify = await _supabase!
              .from('user_profiles')
              .select()
              .eq('user_id', supabaseUserId)
              .maybeSingle();
          
          if (verify != null) {
            print('✅ Verification: Profile exists in Supabase');
            final savedData = verify['data'] as Map<String, dynamic>?;
            print('   Saved reminder time: ${savedData?['reminderTime']}');
            print('   Saved notifications: ${savedData?['notificationsEnabled']}');
            print('   Saved display name: ${savedData?['displayName']}');
            
            if (savedData?['reminderTime'] != mergedProfileData['reminderTime']) {
              print('⚠️ WARNING: Reminder time mismatch!');
              print('   Expected: ${mergedProfileData['reminderTime']}');
              print('   Got: ${savedData?['reminderTime']}');
            } else {
              print('✅ Reminder time matches!');
            }
            
            if (savedData?['notificationsEnabled'] != mergedProfileData['notificationsEnabled']) {
              print('⚠️ WARNING: Notifications enabled mismatch!');
              print('   Expected: ${mergedProfileData['notificationsEnabled']}');
              print('   Got: ${savedData?['notificationsEnabled']}');
            } else {
              print('✅ Notifications enabled matches!');
            }
          } else {
            print('⚠️ WARNING: Profile not found after save!');
          }
        } catch (verifyError) {
          print('⚠️ Could not verify save: $verifyError');
        }
      } else {
        print('⚠️ Supabase not available or user not authenticated');
        print('   Supabase available: $_supabaseAvailable');
        print('   User authenticated: ${_supabase?.auth.currentUser != null}');
        print('   Will save to local storage only');
      }
    } catch (e) {
      print('❌ Supabase save profile error: $e');
      print('   Error type: ${e.runtimeType}');
      print('   Error details: ${e.toString()}');
      print('   Stack trace: ${StackTrace.current}');
      // Don't throw - we still saved locally
    }
    
    print('💾 ========== SAVE COMPLETE ==========');
  }

  /// Load user profile
  static Future<Map<String, dynamic>?> loadUserProfile() async {
    print('📥 ========== LOAD USER PROFILE ==========');
    
    try {
      if (_supabaseAvailable && _supabase?.auth.currentUser != null) {
        // Use the actual Supabase UUID, not local ID
        final supabaseUserId = _supabase!.auth.currentUser!.id;
        print('   User authenticated: $supabaseUserId');
        print('   Loading from Supabase...');
        
        // Force fresh load from Supabase (don't use cache)
        final response = await _supabase!
            .from('user_profiles')
            .select()
            .eq('user_id', supabaseUserId)
            .maybeSingle();
        
        print('   Supabase response: ${response != null ? "FOUND" : "NOT FOUND"}');
        
        if (response != null && response['data'] != null) {
          final data = Map<String, dynamic>.from(response['data'] as Map);
          print('✅ Profile loaded from Supabase');
          print('   Reminder time: ${data['reminderTime']}');
          print('   Notifications enabled: ${data['notificationsEnabled']}');
          print('   All profile keys: ${data.keys.toList()}');
          
          // ALWAYS sync Supabase data to local storage (overwrite local)
          await _prefs?.setString('user_profile', jsonEncode(data));
          print('✅ Synced Supabase data to local storage');
          
          print('📥 ========== LOAD COMPLETE (FROM SUPABASE) ==========');
          return data;
        } else {
          print('⚠️ No profile found in Supabase for user: $supabaseUserId');
          print('   This might be a new user or profile not created yet');
          
          // If authenticated but no profile, check local storage but don't trust it
          // Return null so caller can use defaults
          print('   Returning null - caller should use defaults');
          print('📥 ========== LOAD COMPLETE (NO PROFILE) ==========');
          return null;
        }
      } else {
        print('⚠️ Supabase not available or user not authenticated');
        print('   Supabase available: $_supabaseAvailable');
        print('   User authenticated: ${_supabase?.auth.currentUser != null}');
        print('   Will try local storage as fallback');
      }
    } catch (e) {
      print('❌ Supabase load profile error: $e');
      print('   Error type: ${e.runtimeType}');
      print('   Error details: ${e.toString()}');
      print('   Will try local storage as fallback');
    }
    
    // Only use local storage if NOT authenticated
    // If authenticated, we should have gotten data from Supabase above
    if (_supabaseAvailable && _supabase?.auth.currentUser != null) {
      print('⚠️ Authenticated but couldn\'t load from Supabase - returning null');
      print('📥 ========== LOAD COMPLETE (AUTHENTICATED BUT NO DATA) ==========');
      return null;
    }
    
    // Fallback to local storage only if not authenticated
    print('   Loading from local storage (not authenticated)...');
    final localData = _prefs?.getString('user_profile');
    if (localData != null) {
      final data = jsonDecode(localData) as Map<String, dynamic>;
      print('✅ Profile loaded from local storage');
      print('   Reminder time: ${data['reminderTime']}');
      print('   Notifications enabled: ${data['notificationsEnabled']}');
      print('📥 ========== LOAD COMPLETE (FROM LOCAL) ==========');
      return data;
    }
    
    print('⚠️ No profile data found (local or Supabase)');
    print('📥 ========== LOAD COMPLETE (NO DATA) ==========');
    return null;
  }

  // ========== WATCHLIST ==========

  /// Save watchlist
  static Future<void> saveWatchlist(List<String> symbols) async {
    final userId = await getOrCreateLocalUserId();
    
    try {
      if (_supabaseAvailable && _supabase?.auth.currentUser != null) {
        await _supabase!.from('watchlist').upsert({
          'user_id': userId,
          'symbols': symbols,
          'updated_at': DateTime.now().toIso8601String(),
        });
      }
    } catch (e) {
      print('Supabase save watchlist error: $e');
    }
    
    await _prefs?.setString('watchlist', jsonEncode(symbols));
  }

  /// Load watchlist
  static Future<List<String>> loadWatchlist() async {
    final userId = await getOrCreateLocalUserId();
    
    try {
      if (_supabaseAvailable && _supabase?.auth.currentUser != null) {
        final response = await _supabase!
            .from('watchlist')
            .select()
            .eq('user_id', userId)
            .maybeSingle();
        
        if (response != null && response['symbols'] != null) {
          final symbols = List<String>.from(response['symbols'] as List);
          await _prefs?.setString('watchlist', jsonEncode(symbols));
          return symbols;
        }
      }
    } catch (e) {
      print('Supabase load watchlist error: $e');
    }
    
    final localData = _prefs?.getString('watchlist');
    if (localData != null) {
      return List<String>.from(jsonDecode(localData));
    }
    
    return [];
  }

  // ========== STOCK DATA CACHE ==========

  /// Save cached stock quote (5 minute TTL to save API credits)
  /// NOTE: Cache is SHARED across all users (stock data is the same for everyone)
  static Future<void> saveCachedQuote(String symbol, Map<String, dynamic> quoteData) async {
    final cacheKey = 'quote_$symbol';
    final cacheData = {
      'data': quoteData,
      'cached_at': DateTime.now().toIso8601String(),
      'ttl': 300, // 5 minutes in seconds (extended to save API credits)
    };
    
    try {
      // Stock cache is SHARED - no need to check for authenticated user
      // Stock data is the same for everyone, so we can share the cache
      if (_supabaseAvailable && _supabase != null) {
        await _supabase!.from('stock_cache').upsert({
          'cache_key': cacheKey,
          'cache_data': cacheData,
          'updated_at': DateTime.now().toIso8601String(),
        });
        print('💾 Saved shared cache for $symbol (available to all users)');
      }
    } catch (e) {
      print('Supabase save cache error: $e');
    }
    
    await _prefs?.setString('cache_$cacheKey', jsonEncode(cacheData));
  }

  /// Get cached stock quote if still valid
  /// NOTE: Cache is SHARED across all users (stock data is the same for everyone)
  static Future<Map<String, dynamic>?> getCachedQuote(String symbol) async {
    final cacheKey = 'quote_$symbol';
    
    try {
      // Stock cache is SHARED - no need to check for authenticated user
      // Stock data is the same for everyone, so we can share the cache
      if (_supabaseAvailable && _supabase != null) {
        final response = await _supabase!
            .from('stock_cache')
            .select()
            .eq('cache_key', cacheKey)
            .maybeSingle();
        
        if (response != null && response['cache_data'] != null) {
          final cacheData = Map<String, dynamic>.from(response['cache_data'] as Map);
          final cachedAt = cacheData['cached_at'] as String?;
          final ttl = cacheData['ttl'] as int? ?? 300; // Default to 5 minutes
          
          if (cachedAt != null) {
            final cachedTime = DateTime.parse(cachedAt);
            final age = DateTime.now().difference(cachedTime).inSeconds;
            if (age < ttl) {
              print('✅ [SHARED CACHE HIT] Quote for $symbol (age: ${age}s, ttl: ${ttl}s)');
              return cacheData['data'] as Map<String, dynamic>?;
            } else {
              print('⏰ [CACHE EXPIRED] Quote for $symbol (age: ${age}s > ttl: ${ttl}s)');
            }
          }
        }
      }
    } catch (e) {
      print('Supabase get cache error: $e');
    }
    
    // Check local cache
    final localCache = _prefs?.getString('cache_$cacheKey');
    if (localCache != null) {
      final cacheData = jsonDecode(localCache) as Map<String, dynamic>;
      final cachedAt = cacheData['cached_at'] as int?;
      final ttl = cacheData['ttl'] as int? ?? 300; // Default to 5 minutes
      
      if (cachedAt != null) {
        final age = (DateTime.now().millisecondsSinceEpoch - cachedAt) ~/ 1000;
        if (age < ttl) {
          return cacheData['data'] as Map<String, dynamic>?;
        }
      }
    }
    
    return null;
  }
  
  /// Get stale cached quote (even if expired) - useful as fallback
  static Future<Map<String, dynamic>?> getStaleCachedQuote(String symbol) async {
    final cacheKey = 'quote_$symbol';
    
    try {
      if (_supabaseAvailable && _supabase != null) {
        final response = await _supabase!
            .from('stock_cache')
            .select()
            .eq('cache_key', cacheKey)
            .maybeSingle();
        
        if (response != null && response['cache_data'] != null) {
          final cacheData = Map<String, dynamic>.from(response['cache_data'] as Map);
          // Return even if expired (stale data is better than no data)
          if (cacheData['data'] != null) {
            print('✅ [STALE CACHE] Returning expired quote for $symbol (better than nothing)');
            return cacheData['data'] as Map<String, dynamic>?;
          }
        }
      }
    } catch (e) {
      print('Supabase get stale cache error: $e');
    }
    
    // Check local cache (even if expired)
    final localCache = _prefs?.getString('cache_$cacheKey');
    if (localCache != null) {
      final cacheData = jsonDecode(localCache) as Map<String, dynamic>;
      if (cacheData['data'] != null) {
        return cacheData['data'] as Map<String, dynamic>?;
      }
    }
    
    return null;
  }

  /// Save cached company profile (30 minute TTL - profiles change rarely)
  /// NOTE: Cache is SHARED across all users (stock data is the same for everyone)
  static Future<void> saveCachedProfile(String symbol, Map<String, dynamic> profileData) async {
    final cacheKey = 'profile_$symbol';
    final cacheData = {
      'data': profileData,
      'cached_at': DateTime.now().toIso8601String(),
      'ttl': 1800, // 30 minutes in seconds (profiles change rarely)
    };
    
    try {
      // Stock cache is SHARED - no need to check for authenticated user
      if (_supabaseAvailable && _supabase != null) {
        await _supabase!.from('stock_cache').upsert({
          'cache_key': cacheKey,
          'cache_data': cacheData,
          'updated_at': DateTime.now().toIso8601String(),
        });
        print('💾 Saved shared profile cache for $symbol (available to all users)');
      }
    } catch (e) {
      print('Supabase save profile cache error: $e');
    }
    
    await _prefs?.setString('cache_$cacheKey', jsonEncode(cacheData));
  }

  /// Get cached company profile if still valid
  /// NOTE: Cache is SHARED across all users (stock data is the same for everyone)
  static Future<Map<String, dynamic>?> getCachedProfile(String symbol) async {
    final cacheKey = 'profile_$symbol';
    
    try {
      // Stock cache is SHARED - no need to check for authenticated user
      if (_supabaseAvailable && _supabase != null) {
        final response = await _supabase!
            .from('stock_cache')
            .select()
            .eq('cache_key', cacheKey)
            .maybeSingle();
        
        if (response != null && response['cache_data'] != null) {
          final cacheData = Map<String, dynamic>.from(response['cache_data'] as Map);
          final cachedAt = cacheData['cached_at'] as String?;
          final ttl = cacheData['ttl'] as int? ?? 1800; // Default to 30 minutes for profiles
          
          if (cachedAt != null) {
            final cachedTime = DateTime.parse(cachedAt);
            final age = DateTime.now().difference(cachedTime).inSeconds;
            if (age < ttl) {
              print('✅ [SHARED CACHE HIT] Profile for $symbol (age: ${age}s, ttl: ${ttl}s)');
              return cacheData['data'] as Map<String, dynamic>?;
            } else {
              print('⏰ [CACHE EXPIRED] Profile for $symbol (age: ${age}s > ttl: ${ttl}s)');
            }
          }
        }
      }
    } catch (e) {
      print('Supabase get profile cache error: $e');
    }
    
    // Check local cache
    final localCache = _prefs?.getString('cache_$cacheKey');
    if (localCache != null) {
      final cacheData = jsonDecode(localCache) as Map<String, dynamic>;
      final cachedAt = cacheData['cached_at'] as int?;
      final ttl = cacheData['ttl'] as int? ?? 300;
      
      if (cachedAt != null) {
        final age = (DateTime.now().millisecondsSinceEpoch - cachedAt) ~/ 1000;
        if (age < ttl) {
          return cacheData['data'] as Map<String, dynamic>?;
        }
      }
    }
    
    return null;
  }

  // ========== SYNC ==========

  /// Sync local data to Supabase (when user logs in)
  static Future<void> syncLocalToSupabase() async {
    if (!_supabaseAvailable || _supabase?.auth.currentUser == null) return;
    
    final userId = _supabase!.auth.currentUser!.id;
    
    // Sync portfolio
    final portfolio = _prefs?.getString('portfolio_data');
    if (portfolio != null) {
      await _supabase!.from('portfolio').upsert({
        'user_id': userId,
        'data': jsonDecode(portfolio),
        'updated_at': DateTime.now().toIso8601String(),
      });
    }
    
    // Sync trades
    final trades = _prefs?.getString('trade_history');
    if (trades != null) {
      final tradesList = List<Map<String, dynamic>>.from(jsonDecode(trades));
      for (final trade in tradesList.take(50)) {
        await _supabase!.from('trades').insert({
          'user_id': userId,
          'trade_data': trade,
          'created_at': trade['timestamp'] ?? DateTime.now().toIso8601String(),
        });
      }
    }
    
    // Sync gamification
    final gamification = _prefs?.getString('gamification_data');
    if (gamification != null) {
      await _supabase!.from('gamification').upsert({
        'user_id': userId,
        'data': jsonDecode(gamification),
        'updated_at': DateTime.now().toIso8601String(),
      });
    }
    
    // Sync watchlist
    final watchlist = _prefs?.getString('watchlist');
    if (watchlist != null) {
      final symbols = List<String>.from(jsonDecode(watchlist));
      await saveWatchlist(symbols);
    }
  }

  // ========== USER PROGRESS ==========

  /// Get user progress
  static Future<Map<String, dynamic>?> getUserProgress() async {
    final userId = await getOrCreateLocalUserId();
    
    try {
      if (_supabaseAvailable && _supabase?.auth.currentUser != null) {
        final response = await _supabase!
            .from('user_progress')
            .select()
            .eq('user_id', userId)
            .maybeSingle();
        
        if (response != null) {
          final data = Map<String, dynamic>.from(response);
          await _prefs?.setString('user_progress', jsonEncode(data));
          return data;
        }
      }
    } catch (e) {
      print('Supabase get user progress error: $e');
    }
    
    final localData = _prefs?.getString('user_progress');
    if (localData != null) {
      return jsonDecode(localData) as Map<String, dynamic>;
    }
    
    return null;
  }

  /// Save user progress
  static Future<void> saveUserProgress(Map<String, dynamic> progressData) async {
    final userId = await getOrCreateLocalUserId();
    
    // Load existing progress and merge with new data
    final existingProgress = await loadUserProgress() ?? {};
    final mergedProgress = {...existingProgress, ...progressData};
    mergedProgress['updated_at'] = DateTime.now().toIso8601String();
    
    print('💾 Saving user progress: onboarding_completed = ${mergedProgress['onboarding_completed']}');
    
    try {
      if (_supabaseAvailable && _supabase?.auth.currentUser != null) {
        // The user_progress table has onboarding_completed as a direct column
        // Extract it and other direct columns, keep rest in JSONB fields
        final supabaseData = <String, dynamic>{
          'user_id': _supabase!.auth.currentUser!.id, // Use authenticated user ID
          'updated_at': DateTime.now().toIso8601String(),
        };
        
        // Add direct columns if they exist in progressData
        if (mergedProgress.containsKey('onboarding_completed')) {
          supabaseData['onboarding_completed'] = mergedProgress['onboarding_completed'];
        }
        if (mergedProgress.containsKey('last_screen_visited')) {
          supabaseData['last_screen_visited'] = mergedProgress['last_screen_visited'];
        }
        if (mergedProgress.containsKey('last_screen_visited_at')) {
          supabaseData['last_screen_visited_at'] = mergedProgress['last_screen_visited_at'];
        }
        
        // Store other data in JSONB fields
        final jsonbData = <String, dynamic>{};
        for (final key in mergedProgress.keys) {
          if (!['user_id', 'onboarding_completed', 'last_screen_visited', 'last_screen_visited_at', 'updated_at'].contains(key)) {
            jsonbData[key] = mergedProgress[key];
          }
        }
        
        if (jsonbData.isNotEmpty) {
          supabaseData['preferences'] = jsonbData;
        }
        
        await _supabase!.from('user_progress').upsert(supabaseData);
        print('✅ Saved user progress to Supabase');
      }
    } catch (e) {
      print('⚠️ Supabase save user progress error: $e');
    }
    
    // Always save to local storage (this is the critical fallback)
    await _prefs?.setString('user_progress', jsonEncode(mergedProgress));
    print('✅ Saved user progress to local storage');
    
    // Verify it was saved
    final verify = _prefs?.getString('user_progress');
    if (verify != null) {
      final verifyData = jsonDecode(verify) as Map<String, dynamic>;
      print('✅ Verified: onboarding_completed = ${verifyData['onboarding_completed']}');
    }
  }

  /// Load user progress
  static Future<Map<String, dynamic>?> loadUserProgress() async {
    // Try Supabase first if authenticated
    try {
      if (_supabaseAvailable && _supabase?.auth.currentUser != null) {
        final authenticatedUserId = _supabase!.auth.currentUser!.id;
        final response = await _supabase!
            .from('user_progress')
            .select()
            .eq('user_id', authenticatedUserId)
            .maybeSingle();
        
        if (response != null) {
          // The user_progress table has onboarding_completed as a direct column
          final data = <String, dynamic>{};
          
          // Copy direct columns
          if (response.containsKey('onboarding_completed')) {
            data['onboarding_completed'] = response['onboarding_completed'];
          }
          if (response.containsKey('last_screen_visited')) {
            data['last_screen_visited'] = response['last_screen_visited'];
          }
          if (response.containsKey('last_screen_visited_at')) {
            data['last_screen_visited_at'] = response['last_screen_visited_at'];
          }
          
          // Merge JSONB fields (preferences, etc.)
          if (response.containsKey('preferences') && response['preferences'] is Map) {
            data.addAll(Map<String, dynamic>.from(response['preferences'] as Map));
          }
          
          // Save to local storage as backup
          await _prefs?.setString('user_progress', jsonEncode(data));
          print('✅ Loaded user progress from Supabase: onboarding_completed = ${data['onboarding_completed']}');
          return data;
        }
      }
    } catch (e) {
      print('⚠️ Supabase load user progress error: $e');
    }
    
    // Fallback to local storage (this should always work)
    final localData = _prefs?.getString('user_progress');
    if (localData != null) {
      final data = jsonDecode(localData) as Map<String, dynamic>;
      print('✅ Loaded user progress from local storage: onboarding_completed = ${data['onboarding_completed']}');
      return data;
    }
    
    print('⚠️ No user progress found');
    return null;
  }

  /// Check if onboarding is completed
  static Future<bool> isOnboardingCompleted() async {
    try {
      final progress = await loadUserProgress();
      if (progress != null) {
        final isCompleted = progress['onboarding_completed'] == true;
        print('🔍 Onboarding check: completed = $isCompleted');
        return isCompleted;
      }
      print('🔍 Onboarding check: no progress found, returning false');
      return false;
    } catch (e) {
      print('⚠️ Error checking onboarding status: $e');
      return false;
    }
  }

  // ========== NOTIFICATION TEMPLATES ==========

  /// Load notification templates from Supabase (with caching)
  static Future<List<Map<String, dynamic>>> loadNotificationTemplates() async {
    // Check cache first
    if (_notificationTemplatesCache != null && _notificationTemplatesCacheTime != null) {
      final cacheAge = DateTime.now().difference(_notificationTemplatesCacheTime!);
      if (cacheAge < _notificationTemplatesCacheTTL) {
        print('✅ Using cached notification templates (${cacheAge.inMinutes}m old)');
        return _notificationTemplatesCache!;
      }
    }

    try {
      // Try Supabase first
      if (_supabaseAvailable) {
        try {
          final response = await _supabase!
              .from('notification_templates')
              .select()
              .eq('is_active', true)
              .order('template_type')
              .order('priority', ascending: false);
          
          if (response.isNotEmpty) {
            final templates = response.map((r) => Map<String, dynamic>.from(r)).toList();
            
            // Cache the results
            _notificationTemplatesCache = templates;
            _notificationTemplatesCacheTime = DateTime.now();
            
            // Also save to local storage as fallback
            await _prefs?.setString('notification_templates', jsonEncode(templates));
            await _prefs?.setString('notification_templates_cache_time', DateTime.now().toIso8601String());
            
            print('✅ Loaded ${templates.length} notification templates from Supabase');
            return templates;
          }
        } catch (e) {
          print('⚠️ Supabase load notification templates error: $e');
        }
      }
    } catch (e) {
      print('⚠️ Error loading notification templates: $e');
    }
    
    // Fallback to local storage
    try {
      final localData = _prefs?.getString('notification_templates');
      if (localData != null) {
        final templates = List<Map<String, dynamic>>.from(jsonDecode(localData) as List);
        print('✅ Loaded ${templates.length} notification templates from local storage');
        return templates;
      }
    } catch (e) {
      print('⚠️ Error loading notification templates from local storage: $e');
    }
    
    // Return empty list if nothing found (will use hardcoded defaults)
    print('⚠️ No notification templates found, will use hardcoded defaults');
    return [];
  }

  /// Clear notification templates cache (call when templates are updated in Supabase)
  static void clearNotificationTemplatesCache() {
    _notificationTemplatesCache = null;
    _notificationTemplatesCacheTime = null;
    _prefs?.remove('notification_templates');
    _prefs?.remove('notification_templates_cache_time');
    print('🗑️ Cleared notification templates cache');
  }
}
