import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;
import 'package:shared_preferences/shared_preferences.dart';
import 'database_service.dart';
import 'referral_service.dart';
import 'referral_rewards_service.dart';
import 'analytics_service.dart';
import 'email_sequence_service.dart';

/// Authentication service for user login/signup
/// Uses Supabase Auth with Google Sign-In and Email/Password
class AuthService {
  static SupabaseClient? get _client {
    try {
      return Supabase.instance.client;
    } catch (e) {
      return null;
    }
  }

  /// Get current user
  static User? get currentUser => _client?.auth.currentUser;

  /// Check if user is authenticated
  static bool get isAuthenticated => _client?.auth.currentUser != null;

  /// Get a valid redirect URL (handles file:// scheme on iOS)
  static String? _getValidRedirectUrl() {
    try {
      final origin = Uri.base.origin;
      if (origin.startsWith('http://') || origin.startsWith('https://')) {
        return origin;
      }
      // For iOS/mobile, return null (will use custom URL scheme)
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Auth state stream
  static Stream<AuthState> get authStateChanges {
    if (_client == null) {
      return Stream.value(AuthState(AuthChangeEvent.signedOut, null));
    }
    return _client!.auth.onAuthStateChange;
  }
  
  /// Get auth state as a simple stream for UI
  static Stream<bool> get isAuthenticatedStream {
    if (_client == null) {
      return Stream.value(false);
    }
    return _client!.auth.onAuthStateChange.map((state) => state.session != null);
  }

  /// Sign in with email and password
  static Future<AuthResponse> signInWithEmail({
    required String email,
    required String password,
  }) async {
    if (_client == null) {
      throw Exception('Supabase not initialized. Please configure Supabase credentials.');
    }
    
    // Validate inputs
    final trimmedEmail = email.trim();
    final trimmedPassword = password.trim();
    
    if (trimmedEmail.isEmpty) {
      throw Exception('Email cannot be empty');
    }
    if (trimmedPassword.isEmpty) {
      throw Exception('Password cannot be empty');
    }
    
    try {
      print('🔵 Attempting sign in with email: $trimmedEmail');
      final response = await _client!.auth.signInWithPassword(
        email: trimmedEmail,
        password: trimmedPassword,
      );
      
      print('✅ Sign in successful for user: ${response.user?.id}');
      
      // Track login in analytics
      if (response.user != null) {
        try {
          await AnalyticsService.identify(response.user!.id, properties: {
            'email': response.user!.email,
            'last_login': DateTime.now().toIso8601String(),
          });
          await AnalyticsService.trackLogin(email: response.user!.email, method: 'email');
          await AnalyticsService.trackAppOpened(); // Track daily active user
        } catch (e) {
          print('⚠️ Analytics tracking error: $e');
        }
      }
      
      // Update user profile with last login
      // CRITICAL: Only update lastLogin, preserve all other settings
      if (response.user != null) {
        try {
          final profile = await DatabaseService.loadUserProfile();
          final profileData = <String, dynamic>{
            'userId': response.user!.id,
            'lastLogin': DateTime.now().toIso8601String(),
          };
          
          // Only update displayName/name/email if they don't exist or are different
          // This preserves user's custom settings
          if (profile == null || profile['displayName'] == null) {
            final displayName = response.user!.userMetadata?['display_name'] as String?;
            final emailPart = response.user!.email?.split('@')[0];
            profileData['displayName'] = displayName ?? emailPart ?? 'User';
            profileData['name'] = response.user!.userMetadata?['name'] as String? ?? emailPart ?? 'User';
          }
          
          if (profile == null || profile['email'] == null) {
            profileData['email'] = response.user!.email ?? email;
          }
          
          if (profile == null || profile['photoURL'] == null) {
            final avatarUrl = response.user!.userMetadata?['avatar_url'] as String?;
            if (avatarUrl != null) {
              profileData['photoURL'] = avatarUrl;
            }
          }
          
          if (profile == null || profile['createdAt'] == null) {
            profileData['createdAt'] = DateTime.now().toIso8601String();
          }
          
          // saveUserProfileData will merge this with existing profile, preserving notification settings
          await DatabaseService.saveUserProfileData(profileData);
        } catch (profileError) {
          print('⚠️ Error updating user profile on login: $profileError');
          // Don't fail login if profile update fails
        }
      }
      
      // Sync local data to Supabase when user logs in
      await DatabaseService.syncLocalToSupabase();
      
      return response;
    } catch (e) {
      print('❌ Sign in error: $e');
      print('   Error type: ${e.runtimeType}');
      print('   Stack trace: ${StackTrace.current}');
      rethrow;
    }
  }

  /// Sign up with email and password
  static Future<AuthResponse> signUpWithEmail({
    required String email,
    required String password,
    String? displayName,
  }) async {
    if (_client == null) {
      throw Exception('Supabase not initialized. Please configure Supabase credentials.');
    }
    try {
      print('🔐 Starting signup for: $email');
      
      // For iOS/mobile, we don't need emailRedirectTo (it causes issues with file:// scheme)
      // Only set it if we have a valid HTTP/HTTPS URL
      String? emailRedirectTo;
      try {
        final origin = Uri.base.origin;
        if (origin.startsWith('http://') || origin.startsWith('https://')) {
          emailRedirectTo = origin;
          print('🔵 Using email redirect: $emailRedirectTo');
        } else {
          print('🔵 Skipping email redirect (invalid scheme: $origin)');
          emailRedirectTo = null;
        }
      } catch (e) {
        print('🔵 Could not determine redirect URL: $e');
        emailRedirectTo = null;
      }
      
      final response = await _client!.auth.signUp(
        email: email,
        password: password,
        data: displayName != null ? {'display_name': displayName, 'name': displayName} : null,
        emailRedirectTo: emailRedirectTo, // Only set if valid URL
      );
      
      print('✅ Signup response received');
      print('   User ID: ${response.user?.id}');
      print('   Email confirmed: ${response.user?.emailConfirmedAt != null}');
      
      // Initialize user data in database if new user
      if (response.user != null) {
        print('📝 Initializing user data...');
        try {
          await _initializeUserData(response.user!.id, displayName ?? email.split('@')[0]);
          print('✅ User data initialized successfully');
          
          // Track signup in analytics
          try {
            await AnalyticsService.identify(response.user!.id, properties: {
              'email': email,
              'display_name': displayName,
              'signup_date': DateTime.now().toIso8601String(),
            });
            await AnalyticsService.trackSignup(email: email, method: 'email');
          } catch (e) {
            print('⚠️ Analytics tracking error: $e');
          }
          
          // Send welcome email
          try {
            await EmailSequenceService.sendWelcomeEmail(
              userId: response.user!.id,
              email: email,
              displayName: displayName,
            );
          } catch (e) {
            print('⚠️ Welcome email error: $e');
          }
          
          // Check for referral code and award rewards
          try {
            final referralCode = await ReferralService.getReferredBy();
            if (referralCode != null && referralCode.isNotEmpty) {
              print('🎁 Found referral code: $referralCode - awarding rewards...');
              await ReferralRewardsService.awardReferralRewards(referralCode, response.user!.id);
            }
          } catch (e) {
            print('⚠️ Error processing referral rewards: $e');
            // Don't fail signup if referral processing fails
          }
        } catch (e) {
          print('❌ Error initializing user data: $e');
          // Don't fail signup if data init fails, but log it
        }
      } else {
        print('⚠️ No user in response - might need email confirmation');
      }
      
      // Sync local data to Supabase
      try {
        await DatabaseService.syncLocalToSupabase();
        print('✅ Local data synced');
      } catch (e) {
        print('⚠️ Error syncing local data: $e');
      }
      
      return response;
    } catch (e) {
      print('❌ Sign up error: $e');
      print('   Error type: ${e.runtimeType}');
      print('   Stack trace: ${StackTrace.current}');
      rethrow;
    }
  }

  /// Sign in with Google
  static Future<bool> signInWithGoogle() async {
    if (_client == null) {
      throw Exception('Supabase not initialized. Please configure Supabase credentials.');
    }
    try {
      print('🔵 Starting Google OAuth sign-in...');
      
      // For iOS, use the custom URL scheme that matches Info.plist
      // The redirect URL must match what's configured in Supabase
      String redirectUrl;
      
      // Detect platform and set appropriate redirect URL
      // IMPORTANT: Check for web FIRST because Platform.isIOS/Platform.isAndroid
      // throws an error on web (Platform is not available on web)
      if (kIsWeb) {
        // Web platform - use the current origin
        final origin = Uri.base.origin;
        if (origin.contains('localhost') || origin.contains('127.0.0.1')) {
          redirectUrl = 'https://lpchovurnlmucwzaltvz.supabase.co/auth/v1/callback';
        } else {
          redirectUrl = origin;
        }
        print('🌐 Detected web platform');
        print('🌐 Using redirect URL: $redirectUrl');
      } else if (Platform.isIOS || Platform.isAndroid) {
        // Mobile platform (iOS or Android) - ALWAYS use custom URL scheme
        redirectUrl = 'com.orion.app://callback';
        print('📱 Detected mobile platform: ${Platform.operatingSystem}');
      } else {
        // Fallback - assume mobile
        redirectUrl = 'com.orion.app://callback';
        print('⚠️ Platform detection unclear, defaulting to mobile URL scheme');
      }
      
      if (kIsWeb) {
        print('🔵 Platform: Web');
      } else {
        print('🔵 Platform: ${Platform.isIOS ? "iOS" : Platform.isAndroid ? "Android" : "Unknown"}');
      }
      print('🔵 Using redirect URL: $redirectUrl');
      
      // For iOS, try platformDefault first (uses in-app browser if available)
      // If that doesn't work, externalApplication opens Safari
      final launchMode = kIsWeb 
          ? LaunchMode.platformDefault 
          : LaunchMode.externalApplication;
      
      print('🔵 Launch mode: $launchMode');
      print('🔵 Initiating OAuth with Supabase...');
      
      final response = await _client!.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: redirectUrl,
        authScreenLaunchMode: launchMode,
      );
      
      print('✅ Google OAuth initiated successfully');
      print('   Response: $response');
      
      // Check if user was created (new signup) or just signed in
      // Note: OAuth redirect happens, so we check after redirect
      return true;
    } catch (e) {
      print('❌ Google sign in error: $e');
      print('   Error type: ${e.runtimeType}');
      print('   Stack trace: ${StackTrace.current}');
      
      // Provide helpful error message
      final errorStr = e.toString().toLowerCase();
      if (errorStr.contains('provider') || errorStr.contains('not enabled') || errorStr.contains('disabled')) {
        throw Exception('Google Sign-In configuration issue. Please check:\n1. Google provider is enabled in Supabase\n2. Redirect URL "com.orion.app://callback" is added in Supabase → Authentication → URL Configuration → Redirect URLs\n3. OAuth Client ID and Secret are configured');
      } else if (errorStr.contains('redirect') || errorStr.contains('url') || errorStr.contains('callback')) {
        throw Exception('Redirect URL not configured. Add "com.orion.app://callback" to Supabase → Authentication → URL Configuration → Redirect URLs');
      } else if (errorStr.contains('network') || errorStr.contains('connection')) {
        throw Exception('Network error. Please check your internet connection.');
      } else if (errorStr.contains('client') || errorStr.contains('credential')) {
        throw Exception('OAuth credentials not configured. Please set up Google OAuth Client ID and Secret in Supabase.');
      } else {
        throw Exception('Google Sign-In failed: ${e.toString()}');
      }
    }
  }
  
  /// Handle OAuth callback and initialize user data if needed
  static Future<void> handleOAuthCallback() async {
    if (_client == null) return;
    
    try {
      final session = _client!.auth.currentSession;
      if (session != null) {
        final user = session.user;
        
        // Check if user profile exists
        final profile = await DatabaseService.loadUserProfile();
        final displayName = user.userMetadata?['full_name'] ?? 
                          user.userMetadata?['name'] ?? 
                          user.email?.split('@')[0] ?? 
                          'User';
        
        if (profile == null) {
          // New user - initialize data
          await _initializeUserData(user.id, displayName);
        } else {
          // Existing user - only update last login, preserve all other settings
          final profileData = {
            'userId': user.id,
            'lastLogin': DateTime.now().toIso8601String(),
          };
          
          // Only update fields if they don't exist (preserve user's custom settings)
          if (profile['displayName'] == null) {
            profileData['displayName'] = displayName;
            profileData['name'] = displayName;
          }
          if (profile['email'] == null) {
            profileData['email'] = user.email ?? '';
          }
          if (profile['photoURL'] == null) {
            profileData['photoURL'] = user.userMetadata?['avatar_url'];
          }
          if (profile['createdAt'] == null) {
            profileData['createdAt'] = DateTime.now().toIso8601String();
          }
          
          // saveUserProfileData will merge this with existing profile, preserving notification settings
          await DatabaseService.saveUserProfileData(profileData);
        }
        
        // Sync local data
        await DatabaseService.syncLocalToSupabase();
      }
    } catch (e) {
      print('Error handling OAuth callback: $e');
    }
  }

  /// Sign out
  static Future<void> signOut() async {
    if (_client == null) return;
    try {
      print('🚪 Signing out...');
      
      // Sign out from Supabase (clears session and removes from secure storage)
      await _client!.auth.signOut();
      
      // Wait a moment for the sign out to fully process
      await Future.delayed(const Duration(milliseconds: 300));
      
      // Verify the session is actually cleared - try multiple times if needed
      int attempts = 0;
      while (_client!.auth.currentSession != null && attempts < 3) {
        print('⚠️ Session still exists after signOut (attempt ${attempts + 1}), forcing clear...');
        await _client!.auth.signOut();
        await Future.delayed(const Duration(milliseconds: 200));
        attempts++;
      }
      
      // Final verification
      final finalSession = _client!.auth.currentSession;
      if (finalSession != null) {
        print('⚠️ WARNING: Session still exists after multiple sign out attempts!');
      } else {
        print('✅ Signed out successfully - session cleared');
      }
      
      // Clear any cached OAuth state by waiting a bit more
      await Future.delayed(const Duration(milliseconds: 200));

      // IMPORTANT: Clear local user-specific data so next login doesn't see old portfolio/XP
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.clear();
        print('✅ Local storage cleared on sign out');
      } catch (e) {
        print('⚠️ Error clearing local storage on sign out: $e');
      }
      
    } catch (e) {
      print('❌ Sign out error: $e');
      // Even if Supabase signOut fails, try to clear local session
      try {
        await _client!.auth.signOut();
        await Future.delayed(const Duration(milliseconds: 300));
      } catch (e2) {
        print('❌ Secondary sign out error: $e2');
      }
      // Don't rethrow - we want logout to complete even if there's an error
    }
  }

  /// Delete user account
  /// This permanently deletes the user account and all associated data
  static Future<void> deleteAccount() async {
    if (_client == null) {
      throw Exception('Supabase not initialized. Cannot delete account.');
    }
    
    try {
      final user = _client!.auth.currentUser;
      if (user == null) {
        throw Exception('No user logged in. Cannot delete account.');
      }
      
      print('🗑️ Deleting user account: ${user.id}');
      
      // First, try to delete user data from Supabase tables
      try {
        final userId = user.id;
        final supabase = DatabaseService.getSupabaseClient();
        
        // Delete user data from all tables
        if (supabase != null && DatabaseService.isSupabaseAvailable) {
          // Delete portfolio data
          try {
            await supabase.from('portfolio').delete().eq('user_id', userId);
            print('✅ Deleted portfolio data');
          } catch (e) {
            print('⚠️ Error deleting portfolio: $e');
          }
          
          // Delete trades
          try {
            await supabase.from('trades').delete().eq('user_id', userId);
            print('✅ Deleted trades');
          } catch (e) {
            print('⚠️ Error deleting trades: $e');
          }
          
          // Delete gamification data
          try {
            await supabase.from('gamification').delete().eq('user_id', userId);
            print('✅ Deleted gamification data');
          } catch (e) {
            print('⚠️ Error deleting gamification: $e');
          }
          
          // Delete leaderboard entry
          try {
            await supabase.from('leaderboard').delete().eq('user_id', userId);
            print('✅ Deleted leaderboard entry');
          } catch (e) {
            print('⚠️ Error deleting leaderboard: $e');
          }
          
          // Delete user profile
          try {
            await supabase.from('user_profiles').delete().eq('user_id', userId);
            print('✅ Deleted user profile');
          } catch (e) {
            print('⚠️ Error deleting profile: $e');
          }
          
          // Delete completed actions
          try {
            await supabase.from('completed_actions').delete().eq('user_id', userId);
            print('✅ Deleted completed actions');
          } catch (e) {
            print('⚠️ Error deleting completed actions: $e');
          }
        }
      } catch (e) {
        print('⚠️ Error deleting user data from database: $e');
        // Continue with account deletion even if data deletion fails
      }
      
      // Delete user data from Supabase tables (already done above)
      // For the auth account itself, we need to use a server-side function
      // or the user can delete it through Supabase dashboard
      // For now, we'll delete all user data and sign them out
      
      // Sign out the user (this clears the session)
      await _client!.auth.signOut();
      print('✅ User signed out');
      
      // Clear all local storage
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.clear();
        print('✅ Local storage cleared');
      } catch (e) {
        print('⚠️ Error clearing local storage: $e');
      }
      
      print('✅ Account deletion process completed');
      print('📝 All user data has been deleted from the database');
      print('📝 Local storage has been cleared');
      print('⚠️ Note: The auth account record may remain in Supabase for security/audit purposes');
      print('   To fully remove the auth account, contact support or use Supabase dashboard');
      
    } catch (e) {
      print('❌ Delete account error: $e');
      rethrow;
    }
  }

  /// Send password reset email
  static Future<void> sendPasswordResetEmail(String email) async {
    if (_client == null) {
      throw Exception('Supabase not initialized. Please configure Supabase credentials.');
    }
    try {
      await _client!.auth.resetPasswordForEmail(
        email,
        redirectTo: _getValidRedirectUrl() ?? 'com.orion.app://reset-password',
      );
    } catch (e) {
      print('Password reset error: $e');
      rethrow;
    }
  }

  /// Update user profile
  static Future<void> updateProfile({
    String? displayName,
    String? avatar,
  }) async {
    if (_client == null) return;
    try {
      final user = _client!.auth.currentUser;
      if (user == null) return;

      await _client!.auth.updateUser(
        UserAttributes(
          data: {
            if (displayName != null) 'display_name': displayName,
            if (avatar != null) 'avatar': avatar,
          },
        ),
      );
    } catch (e) {
      print('Update profile error: $e');
      rethrow;
    }
  }

  /// Initialize user data in database
  static Future<void> _initializeUserData(String userId, String displayName) async {
    try {
      print('📦 Initializing data for user: $userId');
      final user = _client?.auth.currentUser;
      final finalDisplayName = displayName.isNotEmpty 
          ? displayName 
          : (user?.userMetadata?['display_name'] ?? 
             user?.userMetadata?['name'] ?? 
             user?.email?.split('@')[0] ?? 
             'User');
      
      print('   Display name: $finalDisplayName');
      
      // Initialize user profile FIRST (needed for other services)
      final profileData = {
        'userId': userId,
        'displayName': finalDisplayName,
        'name': finalDisplayName,
        'email': user?.email ?? '',
        'photoURL': user?.userMetadata?['avatar_url'],
        'createdAt': DateTime.now().toIso8601String(),
        'lastLogin': DateTime.now().toIso8601String(),
      };
      print('💾 Saving user profile...');
      await DatabaseService.saveUserProfileData(profileData);
      print('✅ User profile saved');

      // Initialize gamification data
      print('💾 Saving gamification data...');
      final now = DateTime.now();
      final gamificationData = {
        'totalXP': 0,
        'streak': 0,
        'level': 1,
        'badges': <String>[],
        'dailyXP': <String, int>{},
        'lastActivityDate': null,
        'lessonsCompleted': 0,
        'perfectLessons': 0,
        'consecutiveLearningDays': 0,
        'lastLearningDate': null,
        'accountCreatedDate': now.toIso8601String(),
      };
      await DatabaseService.saveGamificationData(gamificationData);
      print('✅ Gamification data saved');

      // Initialize portfolio with $10,000 starting balance
      print('💾 Saving portfolio...');
      final portfolioData = {
        'cashBalance': 10000.0,
        'totalValue': 10000.0,
        'positions': <Map<String, dynamic>>[],
        'lastUpdated': DateTime.now().toIso8601String(),
      };
      await DatabaseService.savePortfolio(portfolioData);
      print('✅ Portfolio saved');

      // Initialize leaderboard entry
      print('💾 Saving leaderboard entry...');
      await DatabaseService.updateLeaderboardEntry(
        userId: userId,
        displayName: finalDisplayName,
        xp: 0,
        streak: 0,
        level: 1,
        badges: 0,
      );
      print('✅ Leaderboard entry saved');
      print('🎉 All user data initialized successfully!');
    } catch (e) {
      print('❌ Error initializing user data: $e');
      print('   Stack trace: ${StackTrace.current}');
      rethrow; // Re-throw so we know if initialization fails
    }
  }
}
