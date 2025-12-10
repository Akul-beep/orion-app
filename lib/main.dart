import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'webview_platform_helper.dart';

import 'screens/auth_wrapper.dart';
import 'screens/main_screen.dart';
import 'screens/onboarding/notification_permission_screen.dart';
import 'services/stock_api_service.dart';
import 'services/database_service.dart';
import 'services/ai_stock_analysis_service.dart';
import 'services/gamification_service.dart';
import 'services/paper_trading_service.dart';
import 'services/watchlist_service.dart';
import 'services/learning_action_service.dart';
import 'services/learning_popup_service.dart';
import 'services/user_progress_service.dart';
import 'services/personalization_service.dart';
import 'services/real_trading_bridge_service.dart';
import 'services/daily_goals_service.dart';
import 'services/daily_lesson_service.dart';
import 'services/notification_manager.dart';
import 'services/push_notification_service.dart';
import 'services/notification_scheduler.dart';
import 'services/market_news_notification_service.dart';
import 'services/friend_service.dart';
import 'services/referral_service.dart';
import 'services/weekly_challenge_service.dart';
import 'services/monthly_challenge_service.dart';
import 'services/friend_quest_service.dart';
import 'services/dynamic_lesson_service.dart';
import 'services/analytics_service.dart';
import 'services/feedback_service.dart';
import 'services/email_sequence_service.dart';
import 'services/posthog_surveys_service.dart';
import 'models/orion_character.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables (fast, local file read)
  try {
    await dotenv.load(fileName: ".env");
    print('✅ Environment variables loaded');
  } catch (e) {
    print('⚠️ Could not load .env file: $e');
    print('💡 Using fallback values (not recommended for production)');
  }

  // NOTE:
  // We intentionally DO NOT do any network or database initialization here.
  // Heavy async work before runApp() can cause iOS to kill the app on launch
  // (especially on cold start or slower devices), which looks like a "blue screen" crash.

  // Create core services that are needed for providers
  final gamificationService = GamificationService();
  final weeklyChallengeService = WeeklyChallengeService();
  final monthlyChallengeService = MonthlyChallengeService();
  final friendService = FriendService();
  final friendQuestService = FriendQuestService();
  
  // Start the app UI as soon as possible
  runApp(MyApp(
    gamificationService: gamificationService,
    weeklyChallengeService: weeklyChallengeService,
    monthlyChallengeService: monthlyChallengeService,
    friendQuestService: friendQuestService,
    friendService: friendService,
  ));
  
  // Initialize heavy services in the background so they don't block first frame
  _initializeAppServicesInBackground(
    gamificationService: gamificationService,
    weeklyChallengeService: weeklyChallengeService,
    monthlyChallengeService: monthlyChallengeService,
    friendService: friendService,
    friendQuestService: friendQuestService,
  );
}

class MyApp extends StatelessWidget {
  final GamificationService? gamificationService;
  final WeeklyChallengeService? weeklyChallengeService;
  final MonthlyChallengeService? monthlyChallengeService;
  final FriendQuestService? friendQuestService;
  final FriendService? friendService;
  
  const MyApp({
    super.key, 
    this.gamificationService, 
    this.weeklyChallengeService,
    this.monthlyChallengeService,
    this.friendQuestService,
    this.friendService,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: gamificationService ?? GamificationService()),
        ChangeNotifierProvider(create: (_) => PaperTradingService()),
        ChangeNotifierProvider(create: (_) => WatchlistService()),
        ChangeNotifierProvider(create: (_) => LearningActionService()),
        ChangeNotifierProvider(create: (_) => LearningPopupService()),
        ChangeNotifierProvider(create: (_) => PersonalizationService()),
        ChangeNotifierProvider(create: (_) => RealTradingBridgeService()),
        ChangeNotifierProvider(create: (_) => DailyGoalsService()),
        ChangeNotifierProvider(create: (_) => DailyLessonService()),
        ChangeNotifierProvider.value(value: weeklyChallengeService ?? WeeklyChallengeService()),
        ChangeNotifierProvider.value(value: monthlyChallengeService ?? MonthlyChallengeService()),
        ChangeNotifierProvider.value(value: friendQuestService ?? FriendQuestService()),
        ChangeNotifierProvider.value(value: friendService ?? FriendService()),
        ChangeNotifierProvider(create: (_) => NotificationManager()),
      ],
      child: MaterialApp(
        title: 'Orion Financial App',
        theme: _buildThemeData(context),
        home: const AuthWrapper(),
        debugShowCheckedModeBanner: false,
        routes: {
          '/main': (context) => const MainScreen(),
        },
      ),
    );
  }

  ThemeData _buildThemeData(BuildContext context) {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF1E3A8A), // Professional blue
        brightness: Brightness.light,
        primary: const Color(0xFF1E3A8A),
        onPrimary: Colors.white,
        secondary: const Color(0xFF10B981), // Success green
        onSecondary: Colors.white,
        error: const Color(0xFFEF4444),
        surface: Colors.white,
        onSurface: const Color(0xFF111827),
        background: const Color(0xFFF9FAFB),
      ),
      scaffoldBackgroundColor: const Color(0xFFF9FAFB),
      textTheme: const TextTheme(
        displayLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.w700, color: Color(0xFF111827), height: 1.2),
        titleLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Color(0xFF111827), height: 1.3),
        titleMedium: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFF111827), height: 1.4),
        bodyLarge: TextStyle(fontSize: 16, color: Color(0xFF111827), height: 1.5),
        bodyMedium: TextStyle(fontSize: 14, color: Color(0xFF111827), height: 1.5),
        bodySmall: TextStyle(fontSize: 12, color: Color(0xFF6B7280), height: 1.4),
      ),
      cardTheme: CardTheme(
        color: Colors.white,
        elevation: 0,
        shadowColor: Colors.black.withOpacity(0.04),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF9FAFB),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF10B981), width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }
}

/// Heavy service initialization that can safely run in the background
/// This significantly improves app launch time by not blocking on non-critical work
Future<void> _initializeAppServicesInBackground({
  required GamificationService gamificationService,
  required WeeklyChallengeService weeklyChallengeService,
  required MonthlyChallengeService monthlyChallengeService,
  required FriendService friendService,
  required FriendQuestService friendQuestService,
}) async {
  print('🚀 Starting background service initialization...');
  try {
    // --- Supabase & database (moved out of main to avoid launch-time crash) ---
    print('🔵 Initializing Supabase in background...');
    try {
      final supabaseUrl = dotenv.env['SUPABASE_URL'] ?? 'https://lpchovurnlmucwzaltvz.supabase.co';
      final supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'] ??
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImxwY2hvdnVybmxtdWN3emFsdHZ6Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjMxMjc0MjQsImV4cCI6MjA3ODcwMzQyNH0.lWkytAl7eJg-mrjrBJwXWVmkn3QGDKQmCPEAlNXZouA';

      if (dotenv.env['SUPABASE_URL'] == null || dotenv.env['SUPABASE_ANON_KEY'] == null) {
        print('⚠️ WARNING: Using fallback Supabase credentials. Please set SUPABASE_URL and SUPABASE_ANON_KEY in .env file');
      }

      await Supabase.initialize(
        url: supabaseUrl,
        anonKey: supabaseAnonKey,
        authOptions: const FlutterAuthClientOptions(
          authFlowType: AuthFlowType.pkce,
        ),
        debug: false,
      );

      try {
        final client = Supabase.instance.client;
        print('✅ Supabase client created (background)');
        print('   URL: $supabaseUrl');
        final testQuery = client.from('leaderboard').select('count').limit(1);
        print('✅ Supabase connection test query created (background): $testQuery');
      } catch (testError) {
        print('⚠️ Supabase connection test failed in background: $testError');
      }

      print('✅ Supabase initialized successfully in background');
    } catch (e, stackTrace) {
      print('❌ Supabase initialization FAILED in background: $e');
      print(stackTrace);
    }

    // Database service
    try {
      await DatabaseService.init();
      print('✅ DatabaseService initialized in background');
    } catch (e, stackTrace) {
      print('⚠️ DatabaseService.init() failed in background: $e');
      print(stackTrace);
    }

    // Initialize WebView platform for web only (but won't be used on web)
    if (kIsWeb) {
      initializeWebViewPlatform();
    }

    // --- Existing background initializations ---
    // Initialize analytics/feedback/email/surveys (non-critical for first frame)
    await AnalyticsService.init();
    await FeedbackService.init();
    await EmailSequenceService.init();
    await PostHogSurveysService.init();
    await PostHogSurveysService.recordFirstLaunch();
    
    // Force use new Duolingo-style notification messages (skip old Supabase templates)
    OrionCharacter.forceUseNewMessages();
    
    // Initialize API and AI services
    await StockApiService.init();
    await AIStockAnalysisService.init();
    
    // Initialize user progress tracking and start session
    await UserProgressService().startSession();
    
    // Initialize gamification and dependent services
    await gamificationService.initialize();
    
    final dailyGoalsService = DailyGoalsService();
    await dailyGoalsService.initialize();
    await dailyGoalsService.refreshDailyXPGoal();
    
    await DailyLessonService().initialize();
    
    await weeklyChallengeService.initialize();
    await monthlyChallengeService.initialize();
    
    await friendService.initialize();
    await friendQuestService.initialize();
    
    await DynamicLessonService().initialize();
    
    await NotificationManager().initialize();
    
    // Only initialize mobile push notifications on mobile platforms
    if (!kIsWeb) {
      await PushNotificationService().initialize();
      await MarketNewsNotificationService().initialize();
    }
    
    // Web notifications are initialized per-request in the dashboard
    
    print('✅ Background service initialization complete');
  } catch (e, stackTrace) {
    print('⚠️ Error during background service initialization: $e');
    print(stackTrace);
  }
}
