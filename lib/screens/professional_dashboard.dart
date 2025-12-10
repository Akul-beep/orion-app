import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:fl_chart/fl_chart.dart';
import 'dart:math' as math;
import '../utils/responsive_layout.dart';
import '../services/gamification_service.dart';
import '../services/paper_trading_service.dart';
import '../services/stock_api_service.dart';
import '../services/user_progress_service.dart';
import '../services/personalization_service.dart';
import '../services/real_trading_bridge_service.dart';
import '../models/stock_quote.dart';
import '../design_system.dart';
import 'integrated_trading_screen.dart';
import 'learning/duolingo_home_screen.dart';
import 'ai_coach_screen.dart';
import 'enhanced_stock_detail_screen.dart';
import 'trading_screen.dart';
import '../widgets/animated_action_card.dart';
import 'learning/leaderboard_screen.dart';
import 'friends/friends_screen.dart';
import 'referral/referral_screen.dart';
import '../services/notification_manager.dart';
import '../services/database_service.dart';
import '../utils/currency_converter.dart';
import '../utils/market_detector.dart';
import '../models/paper_trade.dart';
import 'real_trading_bridge_screen.dart';
import 'notification_center_screen.dart';
import 'settings/settings_screen.dart';
import 'feedback/feedback_board_screen.dart';
import '../widgets/daily_login_bonus_widget.dart';
import '../widgets/level_up_celebration_widget.dart';
import '../widgets/challenges_dropdown_widget.dart';
import '../widgets/posthog_survey_widget.dart';
import '../services/posthog_surveys_service.dart';
import '../services/user_engagement_service.dart';
import '../services/web_notification_service.dart';
import '../services/daily_goals_service.dart';

// Import SurveyPrompter from widget file

class ProfessionalDashboard extends StatefulWidget {
  final TabController? tabController;
  
  const ProfessionalDashboard({super.key, this.tabController});

  @override
  State<ProfessionalDashboard> createState() => _ProfessionalDashboardState();
}

class _ProfessionalDashboardState extends State<ProfessionalDashboard> with TickerProviderStateMixin {
  List<StockQuote> _liveStocks = [];
  bool _isLoadingStocks = true;
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));
    
    _loadStocks();
    // Load all data from database on init
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final gamification = Provider.of<GamificationService>(context, listen: false);
      gamification.loadFromDatabase();
      final trading = Provider.of<PaperTradingService>(context, listen: false);
      trading.loadPortfolioFromDatabase();
      
      // Initialize engagement and retention services
      _initializeEngagementServices();
      
      // Track screen visit
      UserProgressService().trackScreenVisit(
        screenName: 'ProfessionalDashboard',
        screenType: 'main',
        metadata: {'section': 'home'},
      );
      
      // Track session start for engagement
      UserEngagementService().trackSessionStart();
      
      // Record activity for surveys
      PostHogSurveysService.recordActivity();
      
      // Check and show surveys after a delay (so UI loads first)
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          SurveyPrompter.checkAndShowSurvey(context);
        }
      });
      
      // Start animations
      _fadeController.forward();
      _slideController.forward();
    });
  }

  Future<void> _initializeEngagementServices() async {
    try {
      // Initialize web notifications if on web
      final webNotification = WebNotificationService();
      final hasPermission = await webNotification.areNotificationsEnabled();
      
      if (hasPermission) {
        final gamification = Provider.of<GamificationService>(context, listen: false);
        final dailyGoals = Provider.of<DailyGoalsService>(context, listen: false);
        
        // Schedule daily notifications
        await webNotification.scheduleDailyNotifications(
          gamification: gamification,
          dailyGoals: dailyGoals,
        );
        
        // Check for streak-at-risk
        await webNotification.sendStreakAtRiskNotification(gamification);
      }
      
      // Track inactivity
      final engagementService = UserEngagementService();
      await engagementService.trackInactivity();
    } catch (e) {
      print('Error initializing engagement services: $e');
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  Future<void> _loadStocks() async {
    try {
      final stocks = await StockApiService.getPopularStocks();
      if (mounted) {
        setState(() {
          _liveStocks = stocks;
          _isLoadingStocks = false;
        });
      }
    } catch (e) {
      print('Error loading live stocks: $e');
      // Error handler will show message if needed, but don't block UI
      if (mounted) {
        setState(() {
          _isLoadingStocks = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB), // gray-50 background matching React
      body: Stack(
        children: [
          SafeArea(
            top: true,
            bottom: false,
            child: RefreshIndicator(
              onRefresh: () async {
                await _loadStocks();
                final gamification = Provider.of<GamificationService>(context, listen: false);
                gamification.loadFromDatabase();
                final trading = Provider.of<PaperTradingService>(context, listen: false);
                // Only refresh portfolio prices on manual pull-to-refresh (saves API credits)
                await trading.refreshPortfolioPrices();
              },
              color: const Color(0xFF2563EB), // blue-600
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final screenWidth = constraints.maxWidth;
                  // Calculate responsive padding based on screen width
                  final horizontalPadding = kIsWeb 
                      ? (screenWidth > 1600 ? 80.0 : screenWidth > 1200 ? 48.0 : screenWidth > 800 ? 32.0 : 16.0)
                      : 16.0;
                  final verticalPadding = kIsWeb ? 32.0 : 16.0;
                  
                  return SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        horizontalPadding,
                        verticalPadding,
                        horizontalPadding,
                        0,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildHeader(),
                          const SizedBox(height: 24),
                          // Challenges Card - Weekly and Friend Quests
                          const ChallengesDropdownWidget(),
                          const SizedBox(height: 32),
                          _buildPowerBIGrid(),
                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          // Daily login bonus overlay
          const DailyLoginBonusWidget(),
          // Level up celebration overlay
          const LevelUpCelebrationWidget(),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData inactiveIcon, IconData activeIcon, String label, bool isActive) {
    return Tooltip(
      message: label,
      child: GestureDetector(
        onTap: () {
          // Navigation handled by MainScreen's tab controller
          if (widget.tabController != null) {
            if (label == 'Trading') {
              widget.tabController!.animateTo(1);
            } else if (label == 'Learn') {
              widget.tabController!.animateTo(2);
            } else if (label == 'AI Coach') {
              widget.tabController!.animateTo(3);
            } else if (label == 'Settings') {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            }
          }
        },
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFFEFF6FF) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isActive ? activeIcon : inactiveIcon,
                color: isActive ? const Color(0xFF2563EB) : const Color(0xFF6B7280),
                size: 24,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                  color: isActive ? const Color(0xFF2563EB) : const Color(0xFF6B7280),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }


  Widget _buildHeader() {
    return FutureBuilder<Map<String, dynamic>?>(
      future: DatabaseService.loadUserProfile(),
      builder: (context, snapshot) {
        final userName = snapshot.data?['displayName'] ?? snapshot.data?['name'] ?? 'User';
        final greeting = _getGreeting();
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              greeting,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: const Color(0xFF6B7280),
                fontWeight: FontWeight.w400,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Hi, $userName',
              style: GoogleFonts.inter(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF111827),
                letterSpacing: -0.5,
              ),
            ),
          ],
        );
      },
    );
  }


  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning!';
    if (hour < 17) return 'Good afternoon!';
    return 'Good evening!';
  }


  Widget _buildCompactStat(int value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(11),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 15),
          const SizedBox(width: 4),
          Text(
            '$value',
            style: GoogleFonts.inter(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String value, String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: Colors.white,
            size: 20,
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 10,
              color: Colors.white.withOpacity(0.8),
              fontWeight: FontWeight.w500,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }


  Widget _buildPowerBIGrid() {
    if (!kIsWeb) {
      // Mobile/Tablet: Single column layout
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildBalanceCard(),
          const SizedBox(height: 24),
          _buildMarketOverviewCard(),
          const SizedBox(height: 24),
          _buildQuickFeaturesCard(),
          const SizedBox(height: 24),
          _buildProfitPieChartCard(),
          const SizedBox(height: 24),
          _buildLearningModulesCard(),
        ],
      );
    }
    
    // Web layout
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        // Responsive breakpoints
        final isWide = screenWidth > 1200;
        final isMedium = screenWidth > 900;
        final isNarrow = screenWidth > 600;
        
        if (isWide) {
          // Power BI-style Desktop Grid Layout
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Row 1: Current Balance (reduced) + Learning Progress (same height)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 2, child: _buildBalanceCard()),
                        SizedBox(width: screenWidth > 1400 ? 24 : 16),
                        Expanded(flex: 1, child: _buildLearningModulesCard()),
                      ],
                    ),
                    SizedBox(height: screenWidth > 1400 ? 24 : 16),
                    // Row 2: Market Overview (left) + Stock Profit Distribution (right, same height, same width as Learning Progress)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 2, child: _buildMarketOverviewCard()),
                        SizedBox(width: screenWidth > 1400 ? 24 : 16),
                        Expanded(flex: 1, child: _buildProfitPieChartCard()),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          );
        } else if (isMedium) {
          // Medium width: 2 column grid
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _buildBalanceCard()),
                  const SizedBox(width: 16),
                  Expanded(child: _buildLearningModulesCard()),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _buildMarketOverviewCard()),
                  const SizedBox(width: 16),
                  Expanded(child: _buildProfitPieChartCard()),
                ],
              ),
            ],
          );
        } else {
          // Narrow/Single column
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildBalanceCard(),
              const SizedBox(height: 16),
              _buildMarketOverviewCard(),
              const SizedBox(height: 16),
              _buildProfitPieChartCard(),
              const SizedBox(height: 16),
              _buildLearningModulesCard(),
            ],
          );
        }
      },
    );
  }

  Widget _buildFloatingDock() {
    return Container(
      width: 160, // Reduced width
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
            spreadRadius: 0,
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: _buildSocialSection(),
    );
  }

  Widget _buildCompactCommunityButton(String title, IconData icon, VoidCallback onTap) {
    return SizedBox(
      height: 80, // Uniform height for both buttons
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: double.infinity, // Same width for both buttons
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: Colors.white.withOpacity(0.2),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: Colors.white, size: 18),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBalanceCard() {
    return SizedBox(
      height: 240, // Increased height for uniform community buttons
      child: Consumer<PaperTradingService>(
        builder: (context, trading, child) {
          final portfolio = trading.portfolio;
          final todayChange = portfolio.totalValue - 10000;
          final todayPercent = 10000 > 0 ? (todayChange / 10000) * 100 : 0.0;
          final isPositive = todayChange >= 0;
          final hasPositions = trading.positions.isNotEmpty;
          // Use actual portfolio values
          final availableBalance = portfolio.cashBalance;
          final investedValue = portfolio.investedValue;
          // Calculate profit correctly: totalPnL from portfolio (already handles Indian stock conversion to USD)
          // This value is calculated in PaperTradingService and includes all positions' unrealizedPnL converted to USD
          final profit = portfolio.totalPnL; // This is already in USD and accounts for Indian stock conversions

          return FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF1E40AF), // blue-700
                      Color(0xFF2563EB), // blue-600
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF2563EB).withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                      spreadRadius: 0,
                    ),
                  ],
                ),
                child: Stack(
                children: [
                  // Decorative background element
                  Positioned(
                    top: -64,
                    right: -64,
                    child: Container(
                      width: 256,
                      height: 256,
                      decoration: BoxDecoration(
                        color: const Color(0xFF3B82F6).withOpacity(0.2), // blue-500
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Left side: Balance information
                      Expanded(
                        flex: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  'Current Balance',
                                  style: GoogleFonts.inter(
                                    color: const Color(0xFFDBEAFE), // blue-100
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              children: [
                                Text(
                                  '\$${portfolio.totalValue.toStringAsFixed(2)}',
                                  style: GoogleFonts.inter(
                                    color: Colors.white,
                                    fontSize: 36,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: -1.0,
                                    height: 1.0,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: isPositive ? const Color(0xFF10B981).withOpacity(0.2) : const Color(0xFFEF4444).withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        isPositive ? Icons.trending_up : Icons.trending_down,
                                        color: isPositive ? const Color(0xFF86EFAC) : const Color(0xFFFCA5A5),
                                        size: 12,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${isPositive ? '+' : ''}${todayPercent.toStringAsFixed(1)}%',
                                        style: GoogleFonts.inter(
                                          color: isPositive ? const Color(0xFF86EFAC) : const Color(0xFFFCA5A5),
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            Container(
                              padding: const EdgeInsets.only(top: 16),
                              decoration: BoxDecoration(
                                border: Border(
                                  top: BorderSide(
                                    color: const Color(0xFF3B82F6).withOpacity(0.3), // blue-500/30
                                    width: 1,
                                  ),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Available Balance',
                                          style: GoogleFonts.inter(
                                            color: const Color(0xFF93C5FD), // blue-300
                                            fontSize: 11,
                                            fontWeight: FontWeight.w400,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '\$${availableBalance.toStringAsFixed(2)}',
                                          style: GoogleFonts.inter(
                                            color: Colors.white,
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Invested Value',
                                          style: GoogleFonts.inter(
                                            color: const Color(0xFF93C5FD), // blue-300
                                            fontSize: 11,
                                            fontWeight: FontWeight.w400,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '\$${investedValue.toStringAsFixed(2)}',
                                          style: GoogleFonts.inter(
                                            color: Colors.white,
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Profit',
                                          style: GoogleFonts.inter(
                                            color: const Color(0xFF93C5FD), // blue-300
                                            fontSize: 11,
                                            fontWeight: FontWeight.w400,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '${profit >= 0 ? '+' : '-'}\$${profit.abs().toStringAsFixed(2)}',
                                          style: GoogleFonts.inter(
                                            color: profit >= 0 ? const Color(0xFF86EFAC) : const Color(0xFFFCA5A5),
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Right side: Community section
                      Container(
                        width: 1,
                        margin: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              const Color(0xFF3B82F6).withOpacity(0.3),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 1,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'Community',
                              style: GoogleFonts.inter(
                                color: const Color(0xFFDBEAFE), // blue-100
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Expanded(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  _buildCompactCommunityButton(
                                    'Friends',
                                    Icons.people,
                                    () async {
                                      await UserProgressService().trackNavigation(
                                        fromScreen: 'ProfessionalDashboard',
                                        toScreen: 'FriendsScreen',
                                        navigationMethod: 'push',
                                      );
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(builder: (context) => const FriendsScreen()),
                                      );
                                    },
                                  ),
                                  const SizedBox(height: 10),
                                  _buildCompactCommunityButton(
                                    'Leaderboard',
                                    Icons.leaderboard,
                                    () async {
                                      await UserProgressService().trackNavigation(
                                        fromScreen: 'ProfessionalDashboard',
                                        toScreen: 'LeaderboardScreen',
                                        navigationMethod: 'push',
                                      );
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(builder: (context) => const LeaderboardScreen()),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    ),
    );
  }

  Widget _buildCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
            spreadRadius: 0,
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildAssetsAllocationCard() {
    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFDBEAFE), // blue-50
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.pie_chart, color: Color(0xFF2563EB), size: 20), // blue-600
              ),
              const SizedBox(width: 12),
              Text(
                'Assets Allocation',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF111827),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '12.3%',
                style: GoogleFonts.inter(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF10B981), // green-500
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'assets',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: const Color(0xFF6B7280), // gray-500
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'growth increased from last month',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: const Color(0xFF9CA3AF), // gray-400
            ),
          ),
          const SizedBox(height: 24),
          // Simple bar chart representation
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  children: [
                    Container(
                      height: 64,
                      decoration: BoxDecoration(
                        color: const Color(0xFFBFDBFE), // blue-200
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(12),
                          topRight: Radius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Cardano',
                      style: GoogleFonts.inter(fontSize: 12, color: Color(0xFF6B7280)),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  children: [
                    Container(
                      height: 96,
                      decoration: BoxDecoration(
                        color: const Color(0xFF93C5FD), // blue-400
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(12),
                          topRight: Radius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Ethereum',
                      style: GoogleFonts.inter(fontSize: 12, color: Color(0xFF6B7280)),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  children: [
                    Container(
                      height: 128,
                      decoration: BoxDecoration(
                        color: const Color(0xFF2563EB), // blue-600
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(12),
                          topRight: Radius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Bitcoin',
                      style: GoogleFonts.inter(fontSize: 12, color: Color(0xFF6B7280)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Column(
            children: [
              _buildLegendItem(const Color(0xFFBFDBFE), 'Cardano'),
              const SizedBox(height: 8),
              _buildLegendItem(const Color(0xFF93C5FD), 'Ethereum'),
              const SizedBox(height: 8),
              _buildLegendItem(const Color(0xFF2563EB), 'Bitcoin'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: GoogleFonts.inter(fontSize: 12, color: Color(0xFF6B7280)),
        ),
      ],
    );
  }

  Widget _buildQuickActionCard() {
    return _buildCard(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Color(0xFF2563EB), // blue-600
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.bolt, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 12),
              Text(
                'Balance Quick Action',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF111827),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Column(
            children: [
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    // Top up action
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB), // blue-600
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'Top Up',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    // Withdraw action
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF2563EB), // blue-600
                    side: const BorderSide(color: Color(0xFFBFDBFE)), // blue-200
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Withdraw',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPortfolioOverviewCard() {
    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDBEAFE), // blue-50
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.trending_up, color: Color(0xFF2563EB), size: 20),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Portfolio Overview',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF111827),
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'This Month',
                      style: GoogleFonts.inter(fontSize: 12, color: Color(0xFF6B7280)),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.keyboard_arrow_down, size: 14, color: Color(0xFF6B7280)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            'Balance',
            style: GoogleFonts.inter(fontSize: 14, color: Color(0xFF6B7280)),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '\$231,238.21',
                style: GoogleFonts.inter(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF111827),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.trending_up, size: 14, color: Color(0xFF10B981)),
                    const SizedBox(width: 4),
                    Text(
                      '+12.3%',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF10B981),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Simple chart representation
          Container(
            height: 128,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  const Color(0xFF2563EB).withOpacity(0.1),
                  Colors.transparent,
                ],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: CustomPaint(
              painter: _WaveLinePainter(),
              child: Container(),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  _buildChartLegend(const Color(0xFF2563EB), 'Bitcoin'),
                  const SizedBox(width: 16),
                  _buildChartLegend(const Color(0xFF93C5FD), 'Ethereum'),
                  const SizedBox(width: 16),
                  _buildChartLegend(const Color(0xFFD1D5DB), 'Cardano'),
                ],
              ),
              Row(
                children: [
                  Text('Week 1', style: GoogleFonts.inter(fontSize: 12, color: Color(0xFF9CA3AF))),
                  const SizedBox(width: 16),
                  Text('Week 2', style: GoogleFonts.inter(fontSize: 12, color: Color(0xFF9CA3AF))),
                  const SizedBox(width: 16),
                  Text('Week 3', style: GoogleFonts.inter(fontSize: 12, color: Color(0xFF9CA3AF))),
                  const SizedBox(width: 16),
                  Text('Week 4', style: GoogleFonts.inter(fontSize: 12, color: Color(0xFF9CA3AF))),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChartLegend(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: GoogleFonts.inter(fontSize: 12, color: Color(0xFF6B7280)),
        ),
      ],
    );
  }

  Widget _buildExchangeCard() {
    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: Color(0xFF2563EB),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.swap_horiz, color: Colors.white, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Exchange',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF111827),
                    ),
                  ),
                ],
              ),
              const Icon(Icons.more_horiz, color: Color(0xFF9CA3AF), size: 20),
            ],
          ),
          const SizedBox(height: 24),
          // Buy/Sell tabs
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6), // gray-100
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        'Buy',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF111827),
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      'Sell',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF6B7280),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // From section
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'From',
                    style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF6B7280)),
                  ),
                  Text(
                    'Available: \$18,867.21',
                    style: GoogleFonts.inter(fontSize: 12, color: Color(0xFF9CA3AF)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9FAFB), // gray-50
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFF3F4F6)),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.account_balance_wallet, color: Color(0xFF10B981), size: 16),
                            const SizedBox(width: 8),
                            Text(
                              'My Balance',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF111827),
                              ),
                            ),
                          ],
                        ),
                        const Icon(Icons.keyboard_arrow_down, color: Color(0xFF9CA3AF), size: 16),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '18,000',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF111827),
                          ),
                        ),
                        Text(
                          'USD',
                          style: GoogleFonts.inter(fontSize: 12, color: Color(0xFF9CA3AF)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Swap button
          Center(
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFF3F4F6)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: const Icon(Icons.swap_vert, color: Color(0xFF2563EB), size: 14),
            ),
          ),
          const SizedBox(height: 16),
          // To section
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'To',
                style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF6B7280)),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFF3F4F6)),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 16,
                              height: 16,
                              decoration: const BoxDecoration(
                                color: Color(0xFFFB923C), // orange-400
                                shape: BoxShape.circle,
                              ),
                              child: const Center(
                                child: Text(
                                  '₿',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Bitcoin',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF111827),
                              ),
                            ),
                          ],
                        ),
                        const Icon(Icons.keyboard_arrow_down, color: Color(0xFF9CA3AF), size: 16),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '0,000023',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF111827),
                          ),
                        ),
                        Text(
                          'BTC',
                          style: GoogleFonts.inter(fontSize: 12, color: Color(0xFF9CA3AF)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                // Buy Bitcoin action
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: Text(
                'Buy Bitcoin',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'RATE',
                style: GoogleFonts.inter(fontSize: 12, color: Color(0xFF6B7280)),
              ),
              Text(
                '\$1 BTC = 18,92 ETH',
                style: GoogleFonts.inter(fontSize: 12, color: Color(0xFF9CA3AF)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'ROUTE',
                style: GoogleFonts.inter(fontSize: 12, color: Color(0xFF6B7280)),
              ),
              Text(
                'ETH > BTC',
                style: GoogleFonts.inter(fontSize: 12, color: Color(0xFF9CA3AF)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProfitCard() {
    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Color(0xFF2563EB),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.pie_chart, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 12),
              Text(
                'Profit',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF111827),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Gauge chart representation
          Center(
            child: Container(
              width: 192,
              height: 96,
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFF3F4F6), width: 16),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(192),
                  topRight: Radius.circular(192),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Column(
              children: [
                Text(
                  '\$58,253',
                  style: GoogleFonts.inter(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.trending_up, size: 12, color: Color(0xFF10B981)),
                    const SizedBox(width: 4),
                    Text(
                      '+12.3%',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF10B981),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Column(
            children: [
              _buildProfitItem(const Color(0xFF93C5FD), 'Ethereum', '\$17,475.9'),
              const SizedBox(height: 12),
              _buildProfitItem(const Color(0xFF2563EB), 'Cardano', '\$11,650.6'),
              const SizedBox(height: 12),
              _buildProfitItem(const Color(0xFF1E3A8A), 'Bitcoin', '\$29,117.5'),
            ],
          ),
        ],
      ),
    );
  }

  // New Power BI-style card wrappers
  Widget _buildMarketOverviewCard() {
    return SizedBox(
      height: 400, // Fixed height
      child: _buildCard(
        child: _buildMarketOverview(),
      ),
    );
  }

  Widget _buildQuickFeaturesCard() {
    return _buildCard(
      child: _buildSocialSection(),
    );
  }

  Future<Map<String, dynamic>> _calculateProfitDistribution(List<PaperPosition> positions) async {
    final profitData = <String, double>{}; // Store actual profit/loss (can be negative)
    final stockMarkets = <String, bool>{};
    double totalProfitValueUSD = 0;
    
    // Get USD to INR rate for conversion
    final usdToInrRate = await CurrencyConverter.getUsdToInrRate();
    
    for (var position in positions) {
      final isIndian = MarketDetector.isIndianStock(position.symbol);
      stockMarkets[position.symbol] = isIndian;
      
      // Calculate profit: (currentPrice - averagePrice) * quantity
      // This matches React implementation - store actual profit/loss (can be negative)
      final profitNative = (position.currentPrice - position.averagePrice) * position.quantity;
      
      // Include all positions (both profit and loss) for distribution
      if (profitNative != 0) {
        // Store actual profit/loss value (not absolute) to preserve sign
        profitData[position.symbol] = profitNative;
        
        // Convert to USD for total calculation
        if (isIndian) {
          // Indian stocks: profit is in INR, convert to USD
          totalProfitValueUSD += profitNative / usdToInrRate;
        } else {
          // US stocks: profit is already in USD
          totalProfitValueUSD += profitNative;
        }
      }
    }
    
    // If no positions, use mock data
    if (profitData.isEmpty) {
      profitData['AAPL'] = 1500.0;
      profitData['GOOGL'] = 1200.0;
      profitData['TSLA'] = 800.0;
      stockMarkets['AAPL'] = false;
      stockMarkets['GOOGL'] = false;
      stockMarkets['TSLA'] = false;
      totalProfitValueUSD = 3500.0;
    }
    
    return {
      'profitData': profitData,
      'stockMarkets': stockMarkets,
      'totalProfitValueUSD': totalProfitValueUSD, // Keep actual value (can be negative)
    };
  }

  Widget _buildProfitPieChartCard() {
    return Consumer<PaperTradingService>(
      builder: (context, trading, child) {
        final positions = trading.positions;
        final totalProfit = trading.portfolio.totalValue - 10000;
        
        return FutureBuilder<Map<String, dynamic>>(
          future: _calculateProfitDistribution(positions),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return SizedBox(
                height: 400,
                child: _buildCard(
                  child: Center(
                    child: CircularProgressIndicator(
                      color: const Color(0xFF2563EB),
                    ),
                  ),
                ),
              );
            }
            
            final profitData = snapshot.data!['profitData'] as Map<String, double>;
            final stockMarkets = snapshot.data!['stockMarkets'] as Map<String, bool>;
            final totalProfitValueUSD = snapshot.data!['totalProfitValueUSD'] as double;
            
            return SizedBox(
              height: 400, // Fixed height to match Market Overview
              child: _buildCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: Color(0xFF2563EB),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.pie_chart, color: Colors.white, size: 16),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Stock Profit Distribution',
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF111827),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Pie Chart - smaller, improved layout
                    Expanded(
                      child: Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: SizedBox(
                              height: 200,
                              child: _buildProfitPieChart(profitData, totalProfitValueUSD),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: FutureBuilder<double>(
                              future: CurrencyConverter.getUsdToInrRate(),
                              builder: (context, rateSnapshot) {
                                return _buildProfitLegend(
                                  profitData, 
                                  totalProfitValueUSD, 
                                  stockMarkets,
                                  rateSnapshot.data ?? 83.0,
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Total Profit Summary - compact
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9FAFB),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Total Profit',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  color: const Color(0xFF6B7280),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '\$${totalProfitValueUSD.toStringAsFixed(2)}',
                                style: GoogleFonts.inter(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: totalProfitValueUSD >= 0 
                                      ? const Color(0xFF10B981) 
                                      : const Color(0xFFEF4444),
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: totalProfitValueUSD >= 0 
                                  ? const Color(0xFF10B981).withOpacity(0.1)
                                  : const Color(0xFFEF4444).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  totalProfitValueUSD >= 0 ? Icons.trending_up : Icons.trending_down,
                                  size: 12,
                                  color: totalProfitValueUSD >= 0 
                                      ? const Color(0xFF10B981) 
                                      : const Color(0xFFEF4444),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${totalProfitValueUSD >= 0 ? '+' : ''}${((totalProfitValueUSD / 10000) * 100).toStringAsFixed(1)}%',
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: totalProfitValueUSD >= 0 
                                        ? const Color(0xFF10B981) 
                                        : const Color(0xFFEF4444),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildProfitPieChart(Map<String, double> profitData, double totalProfit) {
    if (profitData.isEmpty) {
      return Center(
        child: Text(
          'No profit data',
          style: GoogleFonts.inter(
            fontSize: 12,
            color: const Color(0xFF6B7280),
          ),
        ),
      );
    }

    final colors = [
      const Color(0xFF2563EB),
      const Color(0xFF10B981),
      const Color(0xFFF59E0B),
      const Color(0xFFEF4444),
      const Color(0xFF8B5CF6),
      const Color(0xFFEC4899),
    ];

    final entries = profitData.entries.toList();
    // Sort by absolute value descending for better visualization
    entries.sort((a, b) => b.value.abs().compareTo(a.value.abs()));
    
    // Calculate total absolute value for percentage calculation
    final totalAbs = entries.fold<double>(0, (sum, entry) => sum + entry.value.abs());
    
    final pieChartData = entries.asMap().entries.map((entry) {
      final index = entry.key;
      final dataEntry = entry.value;
      final absValue = dataEntry.value.abs();
      final percentage = totalAbs > 0 ? (absValue / totalAbs * 100) : 0;
      // Use green for profit, red for loss
      final isProfit = dataEntry.value >= 0;
      final color = isProfit ? colors[index % colors.length] : const Color(0xFFEF4444);
      return PieChartSectionData(
        value: absValue, // Use absolute value for chart size
        title: percentage > 5 ? '${percentage.toStringAsFixed(0)}%' : '', // Show percentage if > 5%
        color: color,
        radius: 50,
        showTitle: true,
        titleStyle: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      );
    }).toList();

    return PieChart(
      PieChartData(
        sections: pieChartData,
        sectionsSpace: 1,
        centerSpaceRadius: 30,
        startDegreeOffset: -90,
      ),
    );
  }

  Widget _buildProfitLegend(Map<String, double> profitData, double totalProfitUSD, Map<String, bool> stockMarkets, double usdToInrRate) {
    final colors = [
      const Color(0xFF2563EB),
      const Color(0xFF10B981),
      const Color(0xFFF59E0B),
      const Color(0xFFEF4444),
      const Color(0xFF8B5CF6),
      const Color(0xFFEC4899),
    ];

    final entries = profitData.entries.toList();
    // Sort by absolute value descending to match pie chart
    entries.sort((a, b) => b.value.abs().compareTo(a.value.abs()));
    
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: entries.asMap().entries.map((entry) {
          final index = entry.key;
          final dataEntry = entry.value;
          final profitValue = dataEntry.value; // Actual profit/loss (can be negative)
          final symbol = dataEntry.key;
          final isIndian = stockMarkets[symbol] ?? false;
          final currencySymbol = isIndian ? '₹' : '\$';
          final isProfit = profitValue >= 0;
          
          // Use green for profit, red for loss
          final color = isProfit ? colors[index % colors.length] : const Color(0xFFEF4444);
          
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              symbol.replaceAll('.NS', '').replaceAll('.BO', ''),
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF111827),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 3),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
                            decoration: BoxDecoration(
                              color: isIndian ? const Color(0xFF10B981).withOpacity(0.1) : const Color(0xFF2563EB).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(3),
                            ),
                            child: Text(
                              isIndian ? 'IN' : 'US',
                              style: GoogleFonts.inter(
                                fontSize: 8,
                                fontWeight: FontWeight.w600,
                                color: isIndian ? const Color(0xFF10B981) : const Color(0xFF2563EB),
                              ),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        '${isProfit ? '+' : '-'}$currencySymbol${profitValue.abs().toStringAsFixed(0)}',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          color: isProfit ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildLearningModulesCard() {
    return SizedBox(
      height: 240, // Increased height to match Current Balance card
      child: _buildCard(
        child: _buildLearningSection(),
      ),
    );
  }

  Widget _buildProfitItem(Color color, String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.inter(fontSize: 14, color: Color(0xFF6B7280)),
            ),
          ],
        ),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF111827),
          ),
        ),
      ],
    );
  }

  Widget _buildRecentTransactionCard() {
    return Consumer<PaperTradingService>(
      builder: (context, trading, child) {
        final recentTrades = trading.recentTrades.take(3).toList();
        
        return _buildCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: Color(0xFF2563EB),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.credit_card, color: Colors.white, size: 18),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Recent Transaction',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF111827),
                        ),
                      ),
                    ],
                  ),
                  const Icon(Icons.more_horiz, color: Color(0xFF9CA3AF), size: 20),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                'Today',
                style: GoogleFonts.inter(fontSize: 12, color: Color(0xFF9CA3AF)),
              ),
              const SizedBox(height: 12),
              if (recentTrades.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      children: [
                        Icon(Icons.history, size: 48, color: Colors.grey[300]),
                        const SizedBox(height: 12),
                        Text(
                          'No recent transactions',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Column(
                  children: recentTrades.asMap().entries.map((entry) {
                    final trade = entry.value;
                    final isLast = entry.key == recentTrades.length - 1;
                    return Column(
                      children: [
                        _buildTransactionItem(
                          trade.symbol,
                          '\$${(trade.price * trade.quantity).toStringAsFixed(2)}',
                          _formatTimeAgo(trade.timestamp),
                          trade.action == 'buy' ? const Color(0xFFFBBF24) : const Color(0xFFEF4444), // yellow-400 or red-400
                          trade.action == 'buy' ? 'Pending' : 'Completed',
                        ),
                        if (!isLast) const SizedBox(height: 16),
                      ],
                    );
                  }).toList(),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTransactionItem(String symbol, String amount, String time, Color statusColor, String status) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            symbol,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF111827),
            ),
          ),
        ),
        Expanded(
          child: Text(
            amount,
            textAlign: TextAlign.right,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF10B981),
            ),
          ),
        ),
        if (kIsWeb)
          Expanded(
            child: Text(
              time,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 14, color: Color(0xFF6B7280)),
            ),
          ),
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: statusColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                status,
                style: GoogleFonts.inter(fontSize: 14, color: Color(0xFF6B7280)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSocialSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Community',
          style: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF111827),
            letterSpacing: -0.3,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        // Friends button
        _buildCompactActionCard(
          'Friends',
          Icons.people,
          const Color(0xFF0052FF),
          () async {
            await UserProgressService().trackNavigation(
              fromScreen: 'ProfessionalDashboard',
              toScreen: 'FriendsScreen',
              navigationMethod: 'push',
            );
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const FriendsScreen()),
            );
          },
        ),
        const SizedBox(height: 12),
        // Leaderboard button
        _buildCompactActionCard(
          'Leaderboard',
          Icons.leaderboard,
          const Color(0xFF0052FF),
          () async {
            await UserProgressService().trackNavigation(
              fromScreen: 'ProfessionalDashboard',
              toScreen: 'LeaderboardScreen',
              navigationMethod: 'push',
            );
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const LeaderboardScreen()),
            );
          },
        ),
      ],
    );
  }

  Widget _buildCompactActionCard(String title, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
        child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: const Color(0xFFE5E7EB),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF111827),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildCompactLinkCard(String title, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: const Color(0xFFE5E7EB),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF111827),
                ),
                softWrap: true,
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.arrow_forward_ios, color: const Color(0xFF9CA3AF), size: 12),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard(String title, String subtitle, IconData icon, Color color, VoidCallback onTap) {
    return AnimatedActionCard(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFFE5E7EB),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 2),
              spreadRadius: 0,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    color.withOpacity(0.15),
                    color.withOpacity(0.08),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: color.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF111827),
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              subtitle,
              style: GoogleFonts.inter(
                fontSize: 11,
                color: const Color(0xFF6B7280),
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildMarketOverview() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Market Overview',
              style: GoogleFonts.inter(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF111827),
                letterSpacing: -0.3,
              ),
            ),
            GestureDetector(
              onTap: () {
                widget.tabController?.animateTo(1);
              },
              child: Text(
                'View All',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF0052FF),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Expanded(
          child: _isLoadingStocks
              ? Center(
                  child: CircularProgressIndicator(
                    color: const Color(0xFF0052FF),
                    strokeWidth: 2,
                  ),
                )
              : SingleChildScrollView(
                  child: Column(
                    children: _liveStocks.take(3).map((stock) => _buildStockCard(stock)).toList(),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildStockCard(StockQuote stock) {
    final isPositive = stock.change >= 0;
    
    return GestureDetector(
      onTap: () async {
        // Track interaction
        await UserProgressService().trackWidgetInteraction(
          screenName: 'ProfessionalDashboard',
          widgetType: 'stock_card',
          actionType: 'tap',
          widgetId: stock.symbol,
          interactionData: {'symbol': stock.symbol},
        );
        
        // Track navigation
        await UserProgressService().trackNavigation(
          fromScreen: 'ProfessionalDashboard',
          toScreen: 'EnhancedStockDetailScreen',
          navigationMethod: 'push',
          navigationData: {'symbol': stock.symbol},
        );
        
        // Track trading activity
        await UserProgressService().trackTradingActivity(
          activityType: 'view_stock',
          symbol: stock.symbol,
          activityData: {'from': 'dashboard'},
        );
        
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EnhancedStockDetailScreen(
              symbol: stock.symbol,
              companyName: stock.name,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFFE5E7EB),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFF0052FF).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  stock.symbol.substring(0, 1),
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0052FF),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    stock.symbol,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF111827),
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    stock.name,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: const Color(0xFF6B7280),
                      fontWeight: FontWeight.w400,
                      height: 1.2,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '\$${stock.currentPrice.toStringAsFixed(2)}',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF111827),
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: isPositive 
                        ? const Color(0xFF10B981).withOpacity(0.1) 
                        : const Color(0xFFEF4444).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isPositive ? Icons.trending_up : Icons.trending_down,
                        size: 12,
                        color: isPositive ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                      ),
                      const SizedBox(width: 3),
                      Text(
                        '${isPositive ? '+' : ''}\$${stock.change.toStringAsFixed(2)}',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: isPositive ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                          fontWeight: FontWeight.w600,
                          height: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLearningSection() {
    final tabController = widget.tabController;
    return Consumer2<GamificationService, PaperTradingService>(
      builder: (context, gamification, trading, child) {
        // Calculate progress to next level (level up every 1000 XP)
        final currentLevelXP = (gamification.level - 1) * 1000;
        final nextLevelXP = gamification.level * 1000;
        final progressXP = gamification.xp - currentLevelXP;
        final levelXPNeeded = nextLevelXP - currentLevelXP;
        final progressPercent = levelXPNeeded > 0 
            ? (progressXP / levelXPNeeded).clamp(0.0, 1.0)
            : 1.0;
        final xpToNext = (nextLevelXP - gamification.xp).clamp(0, nextLevelXP);
        
        // Get trading stats for integration
        final portfolio = trading.portfolio;
        final hasPositions = trading.positions.isNotEmpty;
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Learning Progress',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF111827),
                    letterSpacing: -0.3,
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    tabController?.animateTo(2);
                  },
                  child: Text(
                    'View All',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF0052FF),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFFE5E7EB),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header with icon and stats
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: const Color(0xFF0052FF).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.school,
                          color: Color(0xFF0052FF),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Level ${gamification.level}',
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF111827),
                              ),
                            ),
                            const SizedBox(height: 2),
                                Text(
                              '$xpToNext XP to next level',
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    color: const Color(0xFF6B7280),
                                  ),
                            ),
                          ],
                        ),
                      ),
                      // Trading connection badge
                      if (hasPositions)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0052FF).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.trending_up, color: Color(0xFF0052FF), size: 11),
                              const SizedBox(width: 3),
                              Text(
                                '${trading.positions.length}',
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF0052FF),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Progress bar
                  Container(
                    height: 6,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: progressPercent,
                        child: Container(
                          decoration: const BoxDecoration(
                            color: Color(0xFF0052FF),
                            borderRadius: BorderRadius.all(Radius.circular(3)),
                            ),
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 14),
                  // Action buttons - integrated
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            if (tabController != null) {
                              tabController!.animateTo(2);
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0052FF),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            elevation: 0,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.play_arrow, size: 16),
                              const SizedBox(width: 6),
                              Text(
                                'Continue Learning',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                                ),
                              ),
                            ],
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildProgressItem(String value, String label, IconData icon, Color color) {
    return Column(
      children: [
        Icon(
          icon,
          color: color,
          size: 20,
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF111827),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 11,
            color: const Color(0xFF6B7280),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: const Color(0xFF6B7280),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivity() {
    final tabController = widget.tabController;
    return Consumer<PaperTradingService>(
      builder: (context, trading, child) {
        final recentTrades = trading.recentTrades.take(3).toList();
        final hasActivity = recentTrades.isNotEmpty;
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent Activity',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF111827),
                  ),
                ),
                if (hasActivity)
                  GestureDetector(
                    onTap: () {
                      tabController?.animateTo(1);
                    },
                    child: Text(
                      'View All',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF059669),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: hasActivity
                  ? Column(
                      children: recentTrades.asMap().entries.map((entry) {
                        final trade = entry.value;
                        final isLast = entry.key == recentTrades.length - 1;
                        return Column(
                          children: [
                            _buildActivityItem(
                              '${trade.action.toUpperCase()} ${trade.quantity} ${trade.symbol}',
                              '\$${(trade.price * trade.quantity).toStringAsFixed(2)} • ${_formatTimeAgo(trade.timestamp)}',
                              trade.action == 'buy' ? Icons.trending_up : Icons.trending_down,
                              trade.action == 'buy' ? const Color(0xFF059669) : const Color(0xFFEF4444),
                            ),
                            if (!isLast) const SizedBox(height: 16),
                          ],
                        );
                      }).toList(),
                    )
                  : Column(
                      children: [
                        Icon(
                          Icons.history,
                          size: 48,
                          color: Colors.grey[300],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No recent activity',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Start trading to see your activity here',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildActivityItem(String title, String subtitle, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1A1A1A),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: const Color(0xFF6B7280),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  Widget _buildChallengeOfTheWeek() {
    // Challenge section removed - keeping as placeholder for future use
    return const SizedBox.shrink();
  }

  Map<String, dynamic> _getWeekChallenge() {
    // Get current week number
    final now = DateTime.now();
    final weekNumber = ((now.difference(DateTime(now.year, 1, 1)).inDays) / 7).floor() + 1;
    
    // Return challenge based on week
    return {
      'title': 'Complete 5 Lessons This Week',
      'description': 'Learn and earn! Complete 5 lessons to unlock bonus gems.',
      'gem_reward': 500,
      'week': weekNumber,
    };
  }

  int _getDaysUntilWeekEnd() {
    final now = DateTime.now();
    final daysUntilSunday = 7 - now.weekday;
    return daysUntilSunday;
  }
}

// Custom painter for wave line chart
class _WaveLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF2563EB) // blue-600
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    final width = size.width;
    final height = size.height;
    
    // Create a wave-like path
    path.moveTo(0, height * 0.5);
    path.cubicTo(
      width * 0.15, height * 0.2,
      width * 0.4, height * 0.75,
      width * 0.6, height * 0.25,
    );
    path.cubicTo(
      width * 0.7, height * 0.05,
      width * 0.85, height * 0.6,
      width, height * 0.05,
    );
    
    canvas.drawPath(path, paint);
    
    // Fill area under the curve
    final fillPath = Path.from(path);
    fillPath.lineTo(width, height);
    fillPath.lineTo(0, height);
    fillPath.close();
    
    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFF2563EB).withOpacity(0.1),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(0, 0, width, height))
      ..style = PaintingStyle.fill;
    
    canvas.drawPath(fillPath, fillPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}