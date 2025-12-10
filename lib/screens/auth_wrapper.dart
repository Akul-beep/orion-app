import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/auth_service.dart';
import '../services/gamification_service.dart';
import '../services/paper_trading_service.dart';
import '../services/watchlist_service.dart';
import '../services/learning_action_service.dart';
import '../services/learning_popup_service.dart';
import '../services/user_progress_service.dart';
import '../services/database_service.dart';
import '../services/notification_scheduler.dart';
import '../services/push_notification_service.dart';
import 'auth/login_screen.dart';
import 'main_screen.dart';
import 'onboarding/onboarding_screen.dart';
import 'onboarding/personalized_onboarding_screen.dart';
import 'landing_page_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// TEMPORARY BYPASS FLAG: Set to true to skip authentication (for testing on restricted networks)
/// Set to false to re-enable authentication
const bool _BYPASS_AUTH = false;

/// Wrapper that handles authentication state
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    // TEMPORARY BYPASS: Skip authentication if flag is set
    if (_BYPASS_AUTH) {
      print('⚠️ AUTH BYPASS ENABLED: Skipping authentication, going directly to main app');
      return _buildAuthenticatedApp();
    }
    
    // Normal authentication flow
    try {
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      initialData: AuthState(
        Supabase.instance.client.auth.currentSession != null 
            ? AuthChangeEvent.signedIn 
            : AuthChangeEvent.signedOut,
        Supabase.instance.client.auth.currentSession,
      ),
      builder: (context, snapshot) {
        // Handle OAuth callback
        if (snapshot.hasData && snapshot.data!.event == AuthChangeEvent.signedIn) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            AuthService.handleOAuthCallback();
          });
        }
        
        // Show loading while checking auth state
        if (snapshot.connectionState == ConnectionState.waiting) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white,
                const Color(0xFFF8F9FA),
              ],
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.trending_up,
                    color: Color(0xFF0052FF),
                    size: 40,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Orion',
                  style: GoogleFonts.inter(
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF111827),
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 48),
                const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0052FF)),
                    strokeWidth: 2.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
        }

        // Check if user is logged in
        final isAuthenticated = snapshot.data?.session != null;
        
        // DEBUG: Force show login screen to test logo
        // Set this to true temporarily to always show login screen
        const bool FORCE_LOGIN_SCREEN = false; // Change to true to force login screen
        
        if (FORCE_LOGIN_SCREEN) {
          print('🔍 FORCE_LOGIN_SCREEN enabled - showing login screen for logo testing');
          return const LoginScreen();
        }

        // If user is logged in, show main app
        if (isAuthenticated) {
          return _buildAuthenticatedApp();
        }

        // If user is not logged in, show landing page on web, login screen on mobile
        print('🔍 User not authenticated');
        if (kIsWeb) {
          return const LandingPageScreen();
        }
        return const LoginScreen();
      },
    );
    } catch (e) {
      // If Supabase fails (e.g., network blocked), bypass auth
      print('⚠️ Supabase auth check failed: $e');
      print('⚠️ Bypassing authentication and going to main app');
      return _buildAuthenticatedApp();
    }
  }

  Widget _buildAuthenticatedApp() {
    return _AuthenticatedApp();
  }
}

class _AuthenticatedApp extends StatefulWidget {
  const _AuthenticatedApp({super.key});

  @override
  State<_AuthenticatedApp> createState() => _AuthenticatedAppState();
}

class _AuthenticatedAppState extends State<_AuthenticatedApp> with WidgetsBindingObserver {
  bool _dataLoaded = false;
  bool _onboardingChecked = false;
  bool _needsOnboarding = false;

  @override
  void initState() {
    super.initState();
    // Add lifecycle observer for app foreground/background
    WidgetsBinding.instance.addObserver(this);
    
    _checkOnboardingAndLoadData();
    
    // Track screen visit (auth wrapper)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      UserProgressService().trackScreenVisit(
        screenName: 'AuthWrapper',
        screenType: 'main',
        metadata: {'section': 'auth'},
      );
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Handle app lifecycle changes (foreground/background)
  /// Duolingo reschedules notifications when app comes to foreground
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    switch (state) {
      case AppLifecycleState.resumed:
        // App came to foreground - reschedule notifications if needed
        print('📱 App resumed - checking notifications...');
        NotificationScheduler().handleAppForeground(context).catchError((e) {
          print('⚠️ Error handling app foreground: $e');
        });
        break;
      case AppLifecycleState.paused:
        // App went to background - update activity time
        print('📱 App paused - updating activity...');
        NotificationScheduler().handleAppBackground().catchError((e) {
          print('⚠️ Error handling app background: $e');
        });
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        // App is inactive or hidden
        break;
    }
  }

  Future<void> _checkOnboardingAndLoadData() async {
    // Use WidgetsBinding to ensure context is available
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (mounted) {
        try {
          // Check onboarding status (skip if bypassing auth)
          bool onboardingCompleted = false;
          try {
            onboardingCompleted = await DatabaseService.isOnboardingCompleted();
          } catch (e) {
            print('⚠️ Could not check onboarding status: $e');
            // If we can't check, assume onboarding is done to skip it
            onboardingCompleted = true;
          }
          
          // Load app data
          final gamificationService = Provider.of<GamificationService>(context, listen: false);
          final paperTradingService = Provider.of<PaperTradingService>(context, listen: false);
          final watchlistService = Provider.of<WatchlistService>(context, listen: false);
          
          try {
          await gamificationService.loadFromDatabase();
          } catch (e) {
            print('⚠️ Could not load gamification data: $e');
          }
          
          try {
          await paperTradingService.loadPortfolioFromDatabase();
          } catch (e) {
            print('⚠️ Could not load portfolio data: $e');
          }
          
          try {
          await watchlistService.loadWatchlist();
          } catch (e) {
            print('⚠️ Could not load watchlist: $e');
          }
          
          // Initialize notification scheduler after data is loaded
          // Only for mobile platforms (web uses WebNotificationService directly)
          if (!kIsWeb) {
          try {
            await NotificationScheduler().initialize(context);
            // Update last app open time when app launches
            await PushNotificationService().updateLastAppOpen();
            print('✅ Notification scheduler initialized');
          } catch (e) {
            print('⚠️ Could not initialize notification scheduler: $e');
            }
          }
          
          if (mounted) {
            setState(() {
              _dataLoaded = true;
              _onboardingChecked = true;
              // Skip onboarding when bypassing auth
              _needsOnboarding = _BYPASS_AUTH ? false : !onboardingCompleted;
            });
          }
        } catch (e) {
          print('⚠️ Error loading data: $e');
          if (mounted) {
            setState(() {
              _dataLoaded = true;
              _onboardingChecked = true;
              // Skip onboarding on error when bypassing auth
              _needsOnboarding = _BYPASS_AUTH ? false : true;
            });
          }
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Show loading while checking onboarding
    if (!_onboardingChecked || !_dataLoaded) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.white,
                const Color(0xFFF8F9FA),
              ],
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // App Logo
                ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Image.asset(
                    'assets/logo/app_logo.png',
                    width: 100,
                    height: 100,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: const Color(0xFF0052FF),
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF0052FF).withOpacity(0.2),
                              blurRadius: 24,
                              offset: const Offset(0, 8),
                              spreadRadius: 0,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.trending_up,
                          color: Colors.white,
                          size: 50,
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  'Orion',
                  style: GoogleFonts.inter(
                    fontSize: 36,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF0052FF),
                    letterSpacing: -1.0,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Stock Trading & Learning',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    color: const Color(0xFF6B7280),
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 56),
                const SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0052FF)),
                    strokeWidth: 3.0,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Loading your portfolio...',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: const Color(0xFF6B7280),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Show simple onboarding if needed (just introduces the app, no personalization)
    if (_needsOnboarding) {
      return const OnboardingScreen();
    }

    // Show main app
    return const MainScreen();
  }
}
