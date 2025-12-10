import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../utils/responsive_layout.dart';
import '../services/stock_api_service.dart';
import '../services/paper_trading_service.dart';
import '../services/watchlist_service.dart';
import '../services/user_progress_service.dart';
import '../models/stock_quote.dart';
import '../models/paper_trade.dart';
import '../utils/market_detector.dart';
import '../utils/currency_converter.dart';
import 'enhanced_stock_detail_screen.dart';

class ProfessionalStocksScreen extends StatefulWidget {
  final Map<String, dynamic>? routeArguments;
  
  const ProfessionalStocksScreen({super.key, this.routeArguments});

  @override
  State<ProfessionalStocksScreen> createState() => _ProfessionalStocksScreenState();
}

class _ProfessionalStocksScreenState extends State<ProfessionalStocksScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  List<StockQuote> _stocks = [];
  List<StockQuote> _searchResults = [];
  bool _isLoading = true;
  bool _isSearching = false;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  MarketType? _selectedMarket; // null = all markets, MarketType.us = US only, MarketType.indian = Indian only

  @override
  void initState() {
    super.initState();
    // Get initial tab from route arguments, default to 0 (Market)
    final initialTab = widget.routeArguments?['initialTab'] as int? ?? 0;
    _tabController = TabController(length: 3, vsync: this, initialIndex: initialTab);
    
    // Pre-fill search with symbol from route arguments if provided
    final symbol = widget.routeArguments?['symbol'] as String?;
    if (symbol != null) {
      _searchController.text = symbol;
      _searchQuery = symbol;
    }
    
    _loadStocks();
    // Load watchlist and portfolio from database
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final watchlist = Provider.of<WatchlistService>(context, listen: false);
      watchlist.loadWatchlist();
      final trading = Provider.of<PaperTradingService>(context, listen: false);
      trading.loadPortfolioFromDatabase();
      
      // Track screen visit
      UserProgressService().trackScreenVisit(
        screenName: 'ProfessionalStocksScreen',
        screenType: 'main',
        metadata: {'tab': 'market'},
      );
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadStocks() async {
    try {
      setState(() {
        _isLoading = true;
      });
      
      // Load stocks based on selected market (default to US if null)
      final stocks = await StockApiService.getPopularStocks(marketType: _selectedMarket ?? MarketType.us);
      
      if (mounted) {
        setState(() {
          _stocks = stocks;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading stocks: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  List<StockQuote> get _filteredStocks {
    List<StockQuote> stocksToFilter;
    
    if (_searchQuery.isEmpty) {
      stocksToFilter = _stocks;
    } else if (_searchResults.isNotEmpty) {
      stocksToFilter = _searchResults;
    } else {
      stocksToFilter = _stocks.where((stock) =>
          stock.symbol.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          stock.name.toLowerCase().contains(_searchQuery.toLowerCase())
      ).toList();
    }
    
    // Apply market filter if selected (but default to showing all)
    // Only filter if user explicitly selected a market
    if (_selectedMarket != null) {
      stocksToFilter = stocksToFilter.where((stock) {
        final marketType = MarketDetector.getMarketType(stock.symbol);
        return marketType == _selectedMarket;
      }).toList();
    }
    
    return stocksToFilter;
  }

  Future<void> _performSearch(String query) async {
    if (query.isEmpty || query.length < 1) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
    });

    try {
      // Search with API fallback enabled - this searches BOTH US and Indian stocks
      // Local database will be checked first (instant), then API if needed
      final results = await StockApiService.searchStocks(query, useApiFallback: true);
      if (mounted) {
        setState(() {
          // Store all results - market filter will be applied in _filteredStocks getter
          _searchResults = results;
          _isSearching = false;
        });
      }
    } catch (e) {
      print('Error searching stocks: $e');
      if (mounted) {
        setState(() {
          _searchResults = [];
          _isSearching = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isFromLearningAction = widget.routeArguments != null && widget.routeArguments!.containsKey('fromLearningAction');
    
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: ResponsiveLayout(
          maxWidth: kIsWeb ? 1000 : double.infinity,
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              if (isFromLearningAction) _buildLearningBanner(),
              _buildHeader(isFromLearningAction: isFromLearningAction),
              _buildSearchBar(),
              _buildTabBar(),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildMarketTab(),
                    _buildPortfolioTab(),
                    _buildWatchlistTab(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildLearningBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF0052FF).withOpacity(0.08),
            border: Border(
              bottom: BorderSide(
                color: const Color(0xFF0052FF).withOpacity(0.2),
                width: 1,
              ),
            ),
          ),
      child: Row(
        children: [
          const Icon(
            Icons.lightbulb_outline,
            color: Color(0xFF0052FF),
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Tap the back button above when done to complete your quiz!',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF0052FF),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader({bool isFromLearningAction = false}) {
    final canPop = Navigator.canPop(context);
    
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          // Show back button only when opened from learning action
          if (isFromLearningAction)
            IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.arrow_back, color: Color(0xFF111827)),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              iconSize: 24,
            ),
          if (isFromLearningAction) const SizedBox(width: 12),
          Text(
            'Trading',
            style: GoogleFonts.inter(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF111827),
              letterSpacing: -0.5,
            ),
          ),
          // Notification icon removed per requirements
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Column(
      children: [
        // Market Toggle
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: _buildMarketToggleButton('All', null),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMarketToggleButton('🇺🇸 US', MarketType.us),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMarketToggleButton('🇮🇳 Indian', MarketType.indian),
              ),
            ],
          ),
        ),
        // Search Bar
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          padding: const EdgeInsets.symmetric(horizontal: 16),
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
          child: TextField(
            controller: _searchController,
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
                // Clear search results when query changes (will be repopulated by search)
                _searchResults = [];
              });
              // Debounce search API calls - wait 300ms after user stops typing (reduced from 500ms)
              Future.delayed(const Duration(milliseconds: 300), () {
                if (mounted && _searchController.text == value && value.isNotEmpty) {
                  _performSearch(value);
                }
              });
            },
            decoration: InputDecoration(
              hintText: 'Search stocks...',
              hintStyle: GoogleFonts.inter(
                color: const Color(0xFF9CA3AF),
                fontSize: 16,
              ),
              border: InputBorder.none,
              prefixIcon: _isSearching
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: Padding(
                        padding: EdgeInsets.all(12.0),
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0052FF)),
                        ),
                      ),
                    )
                  : const Icon(Icons.search, color: Color(0xFF6B7280)),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, color: Color(0xFF6B7280)),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {
                          _searchQuery = '';
                          _searchResults = [];
                        });
                      },
                    )
                  : null,
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildMarketToggleButton(String label, MarketType? marketType) {
    final isSelected = _selectedMarket == marketType;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedMarket = marketType;
        });
        // Reload stocks when market changes
        _loadStocks();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0052FF) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected ? Colors.white : const Color(0xFF6B7280),
          ),
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TabBar(
        controller: _tabController,
        indicator: UnderlineTabIndicator(
          borderSide: const BorderSide(
            width: 3,
            color: Color(0xFF0052FF),
          ),
          insets: const EdgeInsets.symmetric(horizontal: 16),
        ),
        indicatorSize: TabBarIndicatorSize.label,
        labelColor: const Color(0xFF111827),
        unselectedLabelColor: const Color(0xFF6B7280),
        labelStyle: GoogleFonts.inter(
          fontWeight: FontWeight.w600,
          fontSize: 15,
        ),
        unselectedLabelStyle: GoogleFonts.inter(
          fontWeight: FontWeight.w500,
          fontSize: 15,
        ),
        tabs: const [
          Tab(text: 'Market'),
          Tab(text: 'Portfolio'),
          Tab(text: 'Watchlist'),
        ],
      ),
    );
  }

  Widget _buildMarketTab() {
    if (_isLoading && _searchQuery.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0052FF)),
        ),
      );
    }

    return SingleChildScrollView(
      padding: EdgeInsets.all(kIsWeb ? 24 : 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStocksList(),
        ],
      ),
    );
  }

  Widget _buildMarketOverview() {
    // Removed mock market overview - using real stock data instead
    return const SizedBox.shrink();
  }

  Widget _buildStocksList() {
    final filteredStocks = _filteredStocks;
    
    if (filteredStocks.isEmpty && _searchQuery.isNotEmpty && !_isSearching) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Search Results',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.search_off,
                  size: 64,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 16),
                Text(
                  'No stocks found',
                  style: GoogleFonts.inter(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF6B7280),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Try searching with a different symbol or company name',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: const Color(0xFF9CA3AF),
                    fontWeight: FontWeight.w400,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      );
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _searchQuery.isEmpty ? 'Popular Stocks' : 'Search Results',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF111827),
          ),
        ),
        const SizedBox(height: 16),
        // Use ListView.builder for lazy loading (only renders visible items)
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: filteredStocks.length,
          itemBuilder: (context, index) {
            return _buildStockCard(filteredStocks[index]);
          },
        ),
      ],
    );
  }

  Widget _buildStockCard(StockQuote stock) {
    final isPositive = stock.change >= 0;
    
    return Consumer<WatchlistService>(
      builder: (context, watchlist, child) {
        final isInWatchlist = watchlist.isInWatchlist(stock.symbol);
        
        return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () async {
            // Track interaction
            await UserProgressService().trackWidgetInteraction(
              screenName: 'ProfessionalStocksScreen',
              widgetType: 'stock_card',
              actionType: 'tap',
              widgetId: stock.symbol,
              interactionData: {'symbol': stock.symbol, 'name': stock.name},
            );
            
            // Track navigation
            await UserProgressService().trackNavigation(
              fromScreen: 'ProfessionalStocksScreen',
              toScreen: 'EnhancedStockDetailScreen',
              navigationMethod: 'push',
              navigationData: {'symbol': stock.symbol},
            );
            
            // Track trading activity
            await UserProgressService().trackTradingActivity(
              activityType: 'view_stock',
              symbol: stock.symbol,
              activityData: {'from': 'market_tab'},
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
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Stock Symbol Badge
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0052FF).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(
                      stock.symbol.substring(0, 1),
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF0052FF),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                
                // Stock Info - Properly aligned
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
                      const SizedBox(height: 2),
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
                
                // Price Info - Properly aligned
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${_getCurrencySymbol(stock.currency)}${stock.currentPrice.toStringAsFixed(2)}',
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF111827),
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: isPositive ? const Color(0xFF10B981).withOpacity(0.1) : const Color(0xFFEF4444).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isPositive ? Icons.trending_up : Icons.trending_down,
                            size: 10,
                            color: isPositive ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                          ),
                          const SizedBox(width: 2),
                          Text(
                            '${isPositive ? '+' : ''}${_getCurrencySymbol(stock.currency)}${stock.change.toStringAsFixed(2)}',
                            style: GoogleFonts.inter(
                              fontSize: 10,
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
                const SizedBox(width: 6),
                IconButton(
                  icon: Icon(
                    isInWatchlist ? Icons.star : Icons.star_border,
                    color: isInWatchlist ? const Color(0xFFF59E0B) : const Color(0xFF9CA3AF),
                    size: 20,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () async {
                    // Track interaction
                    await UserProgressService().trackWidgetInteraction(
                      screenName: 'ProfessionalStocksScreen',
                      widgetType: 'watchlist_button',
                      actionType: 'tap',
                      widgetId: stock.symbol,
                      interactionData: {'action': isInWatchlist ? 'remove' : 'add'},
                    );
                    
                    if (isInWatchlist) {
                      await watchlist.removeFromWatchlist(stock.symbol);
                      // Track trading activity
                      await UserProgressService().trackTradingActivity(
                        activityType: 'remove_watchlist',
                        symbol: stock.symbol,
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Row(
                            children: [
                              const Icon(Icons.star_border, color: Color(0xFF6B7280), size: 20),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  '${stock.symbol} removed from watchlist',
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: const Color(0xFF111827),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          backgroundColor: Colors.white,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: const BorderSide(color: Color(0xFFE5E7EB), width: 1),
                          ),
                          margin: const EdgeInsets.all(16),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    } else {
                      await watchlist.addToWatchlist(stock.symbol);
                      // Track trading activity
                      await UserProgressService().trackTradingActivity(
                        activityType: 'add_watchlist',
                        symbol: stock.symbol,
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Row(
                            children: [
                              const Icon(Icons.star, color: Color(0xFFF59E0B), size: 20),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  '${stock.symbol} added to watchlist',
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: const Color(0xFF111827),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          backgroundColor: Colors.white,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: const BorderSide(color: Color(0xFFE5E7EB), width: 1),
                          ),
                          margin: const EdgeInsets.all(16),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
      },
    );
  }

  Widget _buildPortfolioTab() {
    return Consumer<PaperTradingService>(
      builder: (context, trading, child) {
        final portfolio = trading.portfolio;
        final positions = trading.positions;
        
        return SingleChildScrollView(
          padding: EdgeInsets.all(kIsWeb ? 24 : 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildPortfolioSummary(portfolio),
              const SizedBox(height: 24),
              _buildPositionsList(positions),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPortfolioSummary(PaperPortfolio portfolio) {
    final isProfit = portfolio.totalPnL > 0;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0052FF), Color(0xFF3B82F6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0052FF).withOpacity(0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
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
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 14,
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
                    final trading = Provider.of<PaperTradingService>(context, listen: false);
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
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '\$${portfolio.totalValue.toStringAsFixed(2)}',
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(
                isProfit ? Icons.arrow_upward : Icons.arrow_downward,
                color: Colors.white,
                size: 14,
              ),
              const SizedBox(width: 4),
              Text(
                '${isProfit ? '+' : ''}\$${portfolio.totalPnL.toStringAsFixed(2)} '
                '(${isProfit ? '+' : ''}${portfolio.totalPnLPercent.toStringAsFixed(2)}%)',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Consumer<PaperTradingService>(
            builder: (context, trading, child) {
              return Row(
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
                                '\$${trading.cashBalance.toStringAsFixed(2)}',
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
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPositionsList(List<PaperPosition> positions) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
                    Text(
                      'Your Positions',
                      style: GoogleFonts.inter(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF111827),
                      ),
                    ),
        const SizedBox(height: 16),
        if (positions.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.account_balance_wallet,
                  size: 64,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 16),
                Text(
                  'No positions yet',
                  style: GoogleFonts.inter(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF6B7280),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Start trading to see your positions here',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: const Color(0xFF9CA3AF),
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: positions.length,
            itemBuilder: (context, index) {
              return _buildPositionCard(positions[index]);
            },
          ),
      ],
    );
  }

  Widget _buildPositionCard(PaperPosition position) {
    final isProfit = position.unrealizedPnL > 0;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
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
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFF0052FF).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text(
                        position.symbol.substring(0, 1),
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF0052FF),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          position.symbol,
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF111827),
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${position.quantity} shares',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: const Color(0xFF6B7280),
                            fontWeight: FontWeight.w400,
                            height: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        CurrencyConverter.formatPrice(position.currentPrice, position.symbol),
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF111827),
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isProfit ? Icons.trending_up : Icons.trending_down,
                            size: 10,
                            color: isProfit ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                          ),
                          const SizedBox(width: 2),
                          Text(
                            CurrencyConverter.formatPriceChange(position.unrealizedPnL, position.symbol),
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: isProfit ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                              fontWeight: FontWeight.w600,
                              height: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Value: ${CurrencyConverter.formatPrice(position.currentValue, position.symbol)}',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: const Color(0xFF6B7280),
                  fontWeight: FontWeight.w400,
                ),
              ),
              Text(
                '${isProfit ? '+' : ''}${position.unrealizedPnLPercent.toStringAsFixed(2)}%',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: isProfit ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWatchlistTab() {
    return Consumer<WatchlistService>(
      builder: (context, watchlist, child) {
        if (watchlist.isLoading) {
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0052FF)),
            ),
          );
        }

        if (watchlist.watchlistStocks.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 60),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F4F6),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.star_border_rounded,
                      size: 48,
                      color: Colors.grey.shade400,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Your Watchlist is Empty',
                    style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF111827),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Start building your watchlist by tapping the star icon on any stock',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: const Color(0xFF6B7280),
                      fontWeight: FontWeight.w400,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton.icon(
                    onPressed: () {
                      // Switch to Market tab
                      _tabController.animateTo(0);
                    },
                    icon: const Icon(Icons.explore, color: Colors.white, size: 20),
                    label: Text(
                      'Browse Stocks',
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0052FF),
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => watchlist.refreshWatchlist(),
            color: const Color(0xFF0052FF), // Coinbase blue
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.all(kIsWeb ? 24 : 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Watchlist (${watchlist.watchlistStocks.length})',
                      style: GoogleFonts.inter(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF111827),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh),
                      onPressed: () => watchlist.refreshWatchlist(),
                      color: const Color(0xFF0052FF),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: watchlist.watchlistStocks.length,
                  itemBuilder: (context, index) {
                    return _buildWatchlistStockCard(watchlist.watchlistStocks[index], watchlist);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _getCurrencySymbol(String currency) {
    return currency == 'INR' ? '₹' : '\$';
  }

  Widget _buildWatchlistStockCard(StockQuote stock, WatchlistService watchlist) {
    final isPositive = stock.change >= 0;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () async {
            // Track interaction
            await UserProgressService().trackWidgetInteraction(
              screenName: 'ProfessionalStocksScreen',
              widgetType: 'stock_card',
              actionType: 'tap',
              widgetId: stock.symbol,
              interactionData: {'symbol': stock.symbol, 'name': stock.name},
            );
            
            // Track navigation
            await UserProgressService().trackNavigation(
              fromScreen: 'ProfessionalStocksScreen',
              toScreen: 'EnhancedStockDetailScreen',
              navigationMethod: 'push',
              navigationData: {'symbol': stock.symbol},
            );
            
            // Track trading activity
            await UserProgressService().trackTradingActivity(
              activityType: 'view_stock',
              symbol: stock.symbol,
              activityData: {'from': 'market_tab'},
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
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0052FF).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(
                      stock.symbol.substring(0, 1),
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF0052FF),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
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
                      const SizedBox(height: 2),
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
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${_getCurrencySymbol(stock.currency)}${stock.currentPrice.toStringAsFixed(2)}',
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF111827),
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: isPositive ? const Color(0xFF10B981).withOpacity(0.1) : const Color(0xFFEF4444).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isPositive ? Icons.trending_up : Icons.trending_down,
                            size: 10,
                            color: isPositive ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                          ),
                          const SizedBox(width: 2),
                          Text(
                            '${isPositive ? '+' : ''}${_getCurrencySymbol(stock.currency)}${stock.change.toStringAsFixed(2)}',
                            style: GoogleFonts.inter(
                              fontSize: 10,
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
                const SizedBox(width: 6),
                IconButton(
                  icon: Icon(
                    Icons.star,
                    color: const Color(0xFFF59E0B),
                    size: 20,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () {
                    watchlist.removeFromWatchlist(stock.symbol);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Row(
                          children: [
                            const Icon(Icons.star_border, color: Color(0xFF6B7280), size: 20),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                '${stock.symbol} removed from watchlist',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: const Color(0xFF111827),
                                ),
                              ),
                            ),
                          ],
                        ),
                        backgroundColor: Colors.white,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: const BorderSide(color: Color(0xFFE5E7EB), width: 1),
                        ),
                        margin: const EdgeInsets.all(16),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
