import 'package:flutter/material.dart';
import '../screens/enhanced_stock_detail_screen.dart';
import '../services/user_progress_service.dart';
import '../services/stock_api_service.dart';
import '../models/stock_quote.dart';

class TopMovers extends StatefulWidget {
  const TopMovers({super.key});

  @override
  State<TopMovers> createState() => _TopMoversState();
}

class _TopMoversState extends State<TopMovers> {
  List<StockQuote> _gainers = [];
  List<StockQuote> _losers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTopMovers();
  }

  Future<void> _loadTopMovers() async {
    try {
      await StockApiService.init();
      final stocks = await StockApiService.getPopularStocks();
      
      // Sort by change percentage
      stocks.sort((a, b) => b.changePercent.compareTo(a.changePercent));
      
      setState(() {
        _gainers = stocks.where((s) => s.change >= 0).take(3).toList();
        _losers = stocks.where((s) => s.change < 0).take(3).toList();
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading top movers: $e');
      // Fallback to mock data
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Top Movers', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 16),
          TabBar(
            tabs: const [Tab(text: 'Gainers'), Tab(text: 'Losers')],
            labelColor: Theme.of(context).colorScheme.primary,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Theme.of(context).colorScheme.primary,
          ),
          SizedBox(
            height: 200,
            child: TabBarView(
              children: [
                _buildMoversList(_gainers, true),
                _buildMoversList(_losers, false),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMoversList(List<StockQuote> movers, bool isGainer) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (movers.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.trending_up,
                size: 48,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 12),
              Text(
                'No data available',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      itemCount: movers.length,
      itemBuilder: (context, index) {
        final stock = movers[index];
        return _buildMoverItem(
          stock.symbol,
          '\$${stock.currentPrice.toStringAsFixed(2)}',
          '${stock.change >= 0 ? '+' : ''}${stock.changePercent.toStringAsFixed(2)}%',
          isGainer,
          _getIconForSymbol(stock.symbol),
        );
      },
    );
  }

  Widget _buildMoverItem(String ticker, String price, String change, bool isGainer, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: InkWell(
        onTap: () async {
          // Track interaction
          await UserProgressService().trackWidgetInteraction(
            screenName: 'HomeScreen',
            widgetType: 'stock_card',
            actionType: 'tap',
            widgetId: ticker,
            interactionData: {'symbol': ticker, 'type': isGainer ? 'gainer' : 'loser'},
          );
          
          // Track navigation
          await UserProgressService().trackNavigation(
            fromScreen: 'HomeScreen',
            toScreen: 'EnhancedStockDetailScreen',
            navigationMethod: 'push',
            navigationData: {'symbol': ticker},
          );
          
          // Track trading activity
          await UserProgressService().trackTradingActivity(
            activityType: 'view_stock',
            symbol: ticker,
            activityData: {'from': 'top_movers'},
          );
          
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => EnhancedStockDetailScreen(
                symbol: ticker,
                companyName: _getCompanyName(ticker),
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Icon(
                    icon,
                    color: const Color(0xFF10B981),
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      ticker,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: Color(0xFF111827),
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    price,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    change,
                    style: TextStyle(
                      color: isGainer ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getIconForSymbol(String symbol) {
    switch (symbol) {
      case 'AAPL':
        return Icons.apple;
      case 'MSFT':
        return Icons.business;
      case 'TSLA':
        return Icons.electric_car;
      case 'GOOGL':
        return Icons.search;
      case 'AMZN':
        return Icons.shopping_cart;
      case 'META':
        return Icons.people;
      case 'NVDA':
        return Icons.memory;
      case 'NFLX':
        return Icons.play_circle;
      case 'SNAP':
        return Icons.camera_alt;
      case 'DIS':
        return Icons.local_movies;
      default:
        return Icons.trending_up;
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
      case 'SNAP':
        return 'Snap Inc.';
      case 'DIS':
        return 'The Walt Disney Company';
      default:
        return symbol;
    }
  }
}
