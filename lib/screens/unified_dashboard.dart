import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/gamification_service.dart';
import '../services/paper_trading_service.dart';
import '../services/stock_api_service.dart';
import '../services/user_progress_service.dart';
import '../models/stock_quote.dart';
import '../design_system.dart';
import 'learning/duolingo_home_screen.dart';
import 'professional_stocks_screen.dart';
import 'stocks_screen.dart';
import 'enhanced_stock_detail_screen.dart';
import 'achievements/achievements_screen.dart';
import '../widgets/weekly_challenge_widget.dart';
// Uncomment the line below to enable cache testing widget
// import '../widgets/cache_test_widget.dart';

class UnifiedDashboard extends StatefulWidget {
  const UnifiedDashboard({super.key});

  @override
  State<UnifiedDashboard> createState() => _UnifiedDashboardState();
}

class _UnifiedDashboardState extends State<UnifiedDashboard> with TickerProviderStateMixin {
  List<StockQuote> _liveStocks = [];
  bool _isLoading = true;
  late AnimationController _pulseController;
  late AnimationController _slideController;
  late Animation<double> _pulseAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _loadLiveData();
    _setupAnimations();
    
    // Track screen visit
    WidgetsBinding.instance.addPostFrameCallback((_) {
      UserProgressService().trackScreenVisit(
        screenName: 'UnifiedDashboard',
        screenType: 'main',
        metadata: {'section': 'dashboard'},
      );
    });
  }

  void _setupAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOut));
    
    _slideController.forward();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  Future<void> _loadLiveData() async {
    try {
      final stocks = await StockApiService.getPopularStocks();
      setState(() {
        _liveStocks = stocks;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: OrionDesignSystem.lightGrey,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: SlideTransition(
            position: _slideAnimation,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 24),
                _buildPortfolioCard(),
                const SizedBox(height: 24),
                const WeeklyChallengeWidget(),
                const SizedBox(height: 24),
                _buildQuickActions(),
                const SizedBox(height: 24),
                _buildLiveMarketPulse(),
                const SizedBox(height: 24),
                _buildTodaysMission(),
                const SizedBox(height: 24),
                _buildYourPositions(),
                // Uncomment the line below to test cache system
                // const CacheTestWidget(),
                const SizedBox(height: 100), // Bottom padding
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Consumer<GamificationService>(
      builder: (context, gamification, child) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: OrionDesignSystem.gradientCard,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome back! 👋',
                        style: OrionDesignSystem.heading3.copyWith(color: Colors.white),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Ready to make money?',
                        style: OrionDesignSystem.bodyMedium.copyWith(color: Colors.white70),
                      ),
                    ],
                  ),
                  ScaleTransition(
                    scale: _pulseAnimation,
                    child: OrionDesignSystem.buildStreakBadge(gamification.streak),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const AchievementsScreen()),
                        );
                      },
                      child: _buildStatCard(
                        'Level',
                        '${gamification.level}',
                        Icons.star,
                        OrionDesignSystem.gold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const AchievementsScreen()),
                        );
                      },
                      child: _buildStatCard(
                        'XP',
                        '${gamification.xp}',
                        Icons.bolt,
                        OrionDesignSystem.successGreen,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Achievements Link
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AchievementsScreen()),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.emoji_events, color: Colors.white, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'View ${gamification.badges.length} Achievements',
                        style: OrionDesignSystem.bodyMedium.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 16),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: OrionDesignSystem.heading3.copyWith(color: Colors.white),
              ),
              Text(
                label,
                style: OrionDesignSystem.bodySmall.copyWith(color: Colors.white70),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPortfolioCard() {
    return Consumer<PaperTradingService>(
      builder: (context, trading, child) {
        final portfolio = trading.portfolio;
        final todayChange = portfolio.totalValue - 10000; // Starting balance
        final todayPercent = 10000 > 0 
            ? (todayChange / 10000) * 100 
            : 0.0;

        return Container(
          padding: const EdgeInsets.all(24),
          decoration: OrionDesignSystem.primaryCard,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Portfolio Value',
                    style: OrionDesignSystem.bodyLarge,
                  ),
                  Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.refresh, size: 22),
                          color: Colors.white,
                          padding: const EdgeInsets.all(8),
                          onPressed: () async {
                            // Refresh portfolio prices
                            try {
                              await trading.refreshPortfolioPrices();
                              await trading.calculatePortfolioValue();
                              // Show a brief feedback
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Portfolio refreshed'),
                                  duration: Duration(seconds: 1),
                                  backgroundColor: Color(0xFF0052FF),
                                ),
                              );
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Error refreshing: $e'),
                                  duration: const Duration(seconds: 2),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: todayChange >= 0 
                              ? OrionDesignSystem.successGreen.withOpacity(0.1) 
                              : OrionDesignSystem.warningOrange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${todayChange >= 0 ? '+' : ''}${todayPercent.toStringAsFixed(1)}%',
                          style: OrionDesignSystem.bodySmall.copyWith(
                            color: todayChange >= 0 
                                ? OrionDesignSystem.successGreen 
                                : OrionDesignSystem.warningOrange,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                '\$${portfolio.totalValue.toStringAsFixed(2)}',
                style: OrionDesignSystem.heading1,
              ),
              const SizedBox(height: 8),
              Text(
                '${todayChange >= 0 ? '+' : ''}\$${todayChange.toStringAsFixed(2)} today',
                style: OrionDesignSystem.bodyMedium.copyWith(
                  color: todayChange >= 0 
                      ? OrionDesignSystem.successGreen 
                      : OrionDesignSystem.warningOrange,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: OrionDesignSystem.heading2,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: OrionDesignSystem.buildQuickActionCard(
                title: '📚 Learn Now',
                subtitle: '5 min lesson',
                icon: Icons.school,
                color: OrionDesignSystem.successGreen,
                onTap: () async {
                  await UserProgressService().trackWidgetInteraction(
                    screenName: 'UnifiedDashboard',
                    widgetType: 'button',
                    actionType: 'tap',
                    widgetId: 'learn_now',
                  );
                  await UserProgressService().trackNavigation(
                    fromScreen: 'UnifiedDashboard',
                    toScreen: 'DuolingoHomeScreen',
                    navigationMethod: 'push',
                  );
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const DuolingoHomeScreen()),
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OrionDesignSystem.buildQuickActionCard(
                title: '💰 Trade Now',
                subtitle: 'Live trading',
                icon: Icons.trending_up,
                color: OrionDesignSystem.primaryBlue,
                onTap: () async {
                  await UserProgressService().trackWidgetInteraction(
                    screenName: 'UnifiedDashboard',
                    widgetType: 'button',
                    actionType: 'tap',
                    widgetId: 'trade_now',
                  );
                  await UserProgressService().trackNavigation(
                    fromScreen: 'UnifiedDashboard',
                    toScreen: 'ProfessionalStocksScreen',
                    navigationMethod: 'push',
                  );
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ProfessionalStocksScreen()),
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OrionDesignSystem.buildQuickActionCard(
                title: '📊 Analyze',
                subtitle: 'Charts & data',
                icon: Icons.analytics,
                color: OrionDesignSystem.infoBlue,
                onTap: () async {
                  await UserProgressService().trackWidgetInteraction(
                    screenName: 'UnifiedDashboard',
                    widgetType: 'button',
                    actionType: 'tap',
                    widgetId: 'analyze',
                  );
                  await UserProgressService().trackNavigation(
                    fromScreen: 'UnifiedDashboard',
                    toScreen: 'StocksScreen',
                    navigationMethod: 'push',
                  );
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const StocksScreen()),
                  );
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLiveMarketPulse() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Live Market Pulse',
              style: OrionDesignSystem.heading2,
            ),
            const SizedBox(width: 8),
            ScaleTransition(
              scale: _pulseAnimation,
              child: Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: OrionDesignSystem.successGreen,
                  shape: BoxShape.circle,
                ),
              ),
            ),
            const SizedBox(width: 4),
            Text(
              'LIVE',
              style: OrionDesignSystem.bodySmall.copyWith(
                color: OrionDesignSystem.successGreen,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (_isLoading)
          const Center(child: CircularProgressIndicator())
        else
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _liveStocks.take(4).map<Widget>((stock) {
                return Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: OrionDesignSystem.buildLivePriceTicker(
                    symbol: stock.symbol,
                    price: stock.currentPrice,
                    change: stock.change,
                    changePercent: stock.changePercent,
                  ),
                );
              }).toList(),
            ),
          ),
      ],
    );
  }

  Widget _buildTodaysMission() {
    return OrionDesignSystem.buildMissionCard(
      title: "Today's Learning Mission",
      description: 'Master PE Ratios - Learn how to identify undervalued stocks',
      progress: '3/5 steps complete',
      onContinue: () async {
        await UserProgressService().trackWidgetInteraction(
          screenName: 'UnifiedDashboard',
          widgetType: 'button',
          actionType: 'tap',
          widgetId: 'mission_continue',
        );
        await UserProgressService().trackNavigation(
          fromScreen: 'UnifiedDashboard',
          toScreen: 'DuolingoHomeScreen',
          navigationMethod: 'push',
        );
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const DuolingoHomeScreen()),
        );
      },
      onSkip: () async {
        await UserProgressService().trackWidgetInteraction(
          screenName: 'UnifiedDashboard',
          widgetType: 'button',
          actionType: 'tap',
          widgetId: 'mission_skip',
        );
        await UserProgressService().trackNavigation(
          fromScreen: 'UnifiedDashboard',
          toScreen: 'PaperTradingScreen',
          navigationMethod: 'push',
        );
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const PaperTradingScreen()),
        );
      },
    );
  }

  Widget _buildYourPositions() {
    return Consumer<PaperTradingService>(
      builder: (context, trading, child) {
        final positions = trading.positions;
        
        if (positions.isEmpty) {
          return OrionDesignSystem.buildEmptyState(
            icon: Icons.account_balance_wallet,
            title: 'No positions yet',
            subtitle: 'Start trading to see your positions here and track your profits!',
            buttonText: 'Start Trading',
            onButtonPressed: () async {
              await UserProgressService().trackWidgetInteraction(
                screenName: 'UnifiedDashboard',
                widgetType: 'button',
                actionType: 'tap',
                widgetId: 'start_trading',
              );
              await UserProgressService().trackNavigation(
                fromScreen: 'UnifiedDashboard',
                toScreen: 'PaperTradingScreen',
                navigationMethod: 'push',
              );
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const PaperTradingScreen()),
              );
            },
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your Positions',
              style: OrionDesignSystem.heading2,
            ),
            const SizedBox(height: 16),
            ...positions.map((position) {
              final currentPrice = position.currentPrice;
              final totalValue = position.quantity * currentPrice;
              final totalCost = position.quantity * position.averagePrice;
              final profitLoss = totalValue - totalCost;
              final profitLossPercent = totalCost > 0 ? (profitLoss / totalCost) * 100 : 0.0;

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: OrionDesignSystem.buildPositionCard(
                  symbol: position.symbol,
                  quantity: position.quantity,
                  averagePrice: position.averagePrice,
                  currentPrice: currentPrice,
                  profitLoss: profitLoss,
                  profitLossPercent: profitLossPercent,
                ),
              );
            }).toList(),
          ],
        );
      },
    );
  }
}