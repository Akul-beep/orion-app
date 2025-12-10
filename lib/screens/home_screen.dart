import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../widgets/top_movers.dart';
import '../widgets/learning_module.dart';
import '../widgets/market_news.dart';
import '../services/user_progress_service.dart';
import '../services/paper_trading_service.dart';
import 'enhanced_stock_detail_screen.dart';
// Portfolio is now in ProfessionalStocksScreen tab
import 'professional_stocks_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
    // Track screen visit
    WidgetsBinding.instance.addPostFrameCallback((_) {
      UserProgressService().trackScreenVisit(
        screenName: 'HomeScreen',
        screenType: 'main',
        metadata: {'section': 'home'},
      );
      
      // Refresh portfolio when screen is first shown
      _refreshPortfolioIfNeeded();
    });
  }
  
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // App came to foreground - refresh portfolio
      _refreshPortfolioIfNeeded();
    }
  }
  
  void _refreshPortfolioIfNeeded() {
    final paperTrading = Provider.of<PaperTradingService>(context, listen: false);
    if (paperTrading.positions.isNotEmpty) {
      // onAppResumed() has built-in logic to only refresh if > 10 min since last update
      // This saves API credits
      paperTrading.onAppResumed().catchError((e) {
        print('⚠️ Error refreshing portfolio: $e');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Use a very large fixed bottom padding to ensure last item is never hidden
    // This accounts for navigation bar (90px) + safe area (up to 34px) + extra space (200px)
    const double bottomPadding = 324.0; // Large fixed value that will definitely work
    
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.only(
            left: 16.0,
            right: 16.0,
            top: 16.0,
            bottom: bottomPadding,
          ),
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            _buildHeader(context),
            const SizedBox(height: 20),
            _buildPortfolioCard(context),
            const SizedBox(height: 20),
            const TopMovers(),
            const SizedBox(height: 20),
            const LearningModule(),
            const SizedBox(height: 20),
            const MarketNews(),
            const SizedBox(height: bottomPadding), // Same large spacing at the end
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Welcome back,',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF6B7280),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Tanya Myroniuk',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF111827),
                  height: 1.3,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: IconButton(
            icon: const Icon(Icons.search, color: Color(0xFF111827), size: 22),
            onPressed: () async {
              await _showSearchDialog(context);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPortfolioCard(BuildContext context) {
    return Consumer<PaperTradingService>(
      builder: (context, paperTrading, child) {
        final totalValue = paperTrading.totalValue;
        final dayChange = paperTrading.dayChange;
        final dayChangePercent = paperTrading.dayChangePercent;
        final isPositive = dayChange >= 0;
        
        return InkWell(
          onTap: () async {
            // Track interaction
            await UserProgressService().trackWidgetInteraction(
              screenName: 'HomeScreen',
              widgetType: 'portfolio_card',
              actionType: 'tap',
              widgetId: 'portfolio_card',
            );
            
            // Track navigation
            await UserProgressService().trackNavigation(
              fromScreen: 'HomeScreen',
              toScreen: 'PortfolioScreen',
              navigationMethod: 'push',
            );
            
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const ProfessionalStocksScreen(),
              ),
            );
          },
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF1E3A8A),
                  Color(0xFF3B82F6),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF1E3A8A).withOpacity(0.25),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Portfolio Value',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.9),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
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
                            await paperTrading.refreshPortfolioPrices();
                            await paperTrading.calculatePortfolioValue();
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
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  '\$${totalValue.toStringAsFixed(2)}',
                  style: GoogleFonts.inter(
                    fontSize: 28,
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      isPositive ? Icons.trending_up : Icons.trending_down,
                      color: isPositive ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                      size: 18,
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        '${isPositive ? '+' : ''}\$${dayChange.toStringAsFixed(2)} (${isPositive ? '+' : ''}${dayChangePercent.toStringAsFixed(2)}%) Today',
                        style: GoogleFonts.inter(
                          color: isPositive ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.account_balance_wallet,
                              size: 18,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Cash Available',
                                  style: GoogleFonts.inter(
                                    color: Colors.white.withOpacity(0.8),
                                    fontWeight: FontWeight.w500,
                                    fontSize: 11,
                                  ),
                                ),
                                Text(
                                  '\$${paperTrading.cashBalance.toStringAsFixed(2)}',
                                  style: GoogleFonts.inter(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.trending_up,
                              size: 18,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Invested',
                                  style: GoogleFonts.inter(
                                    color: Colors.white.withOpacity(0.8),
                                    fontWeight: FontWeight.w500,
                                    fontSize: 11,
                                  ),
                                ),
                                Text(
                                  '\$${(totalValue - paperTrading.cashBalance).toStringAsFixed(2)}',
                                  style: GoogleFonts.inter(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
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
        );
      },
    );
  }

  void _showSearchDialog(BuildContext context) async {
    final searchController = TextEditingController();
    
    // Track interaction
    await UserProgressService().trackWidgetInteraction(
      screenName: 'HomeScreen',
      widgetType: 'button',
      actionType: 'tap',
      widgetId: 'search_button',
    );
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Search'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: searchController,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Search stocks, news, or topics...',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.search),
                ),
                onSubmitted: (value) async {
                  Navigator.of(context).pop();
                  if (value.isNotEmpty) {
                    await _handleSearch(context, value);
                  }
                },
              ),
              const SizedBox(height: 16),
              const Text('Popular searches:'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: ['AAPL', 'TSLA', 'MSFT', 'GOOGL'].map((symbol) {
                  return ActionChip(
                    label: Text(symbol),
                    onPressed: () async {
                      Navigator.of(context).pop();
                      await _handleSearch(context, symbol);
                    },
                  );
                }).toList(),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                if (searchController.text.isNotEmpty) {
                  await _handleSearch(context, searchController.text);
                }
              },
              child: const Text('Search'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _handleSearch(BuildContext context, String query) async {
    // Track search
    await UserProgressService().trackWidgetInteraction(
      screenName: 'HomeScreen',
      widgetType: 'search',
      actionType: 'submit',
      widgetId: 'search_input',
      interactionData: {'query': query},
    );
    
    // Check if it's a stock symbol (uppercase, 1-5 letters)
    final isStockSymbol = RegExp(r'^[A-Z]{1,5}$').hasMatch(query.toUpperCase());
    
    if (isStockSymbol) {
      // Navigate to stock detail
      await UserProgressService().trackNavigation(
        fromScreen: 'HomeScreen',
        toScreen: 'EnhancedStockDetailScreen',
        navigationMethod: 'push',
        navigationData: {'symbol': query.toUpperCase(), 'from': 'search'},
      );
      
      await UserProgressService().trackTradingActivity(
        activityType: 'view_stock',
        symbol: query.toUpperCase(),
        activityData: {'from': 'search'},
      );
      
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => EnhancedStockDetailScreen(
            symbol: query.toUpperCase(),
            companyName: _getCompanyName(query.toUpperCase()),
          ),
        ),
      );
    } else {
      // Show search results or navigate to stocks screen
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Searching for: $query'),
            action: SnackBarAction(
              label: 'View Stocks',
              onPressed: () async {
                await UserProgressService().trackNavigation(
                  fromScreen: 'HomeScreen',
                  toScreen: 'ProfessionalStocksScreen',
                  navigationMethod: 'push',
                  navigationData: {'from': 'search'},
                );
                
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ProfessionalStocksScreen(),
                  ),
                );
              },
            ),
        ),
      );
    }
  }

  String _getCompanyName(String symbol) {
    switch (symbol) {
      case 'AAPL':
        return 'Apple Inc.';
      case 'MSFT':
        return 'Microsoft Corporation';
      case 'TSLA':
        return 'Tesla Inc.';
      case 'GOOGL':
        return 'Alphabet Inc.';
      case 'AMZN':
        return 'Amazon.com Inc.';
      case 'META':
        return 'Meta Platforms Inc.';
      case 'NVDA':
        return 'NVIDIA Corporation';
      case 'NFLX':
        return 'Netflix Inc.';
      default:
        return symbol;
    }
  }
}
