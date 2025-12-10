import 'package:flutter/material.dart';

import '../widgets/stock_list_item.dart';
import '../services/stock_api_service.dart';
import '../services/user_progress_service.dart';
import '../models/stock_quote.dart';
import '../utils/error_handler.dart';
import 'enhanced_stock_detail_screen.dart';

class StocksScreen extends StatefulWidget {
  const StocksScreen({super.key});

  @override
  State<StocksScreen> createState() => _StocksScreenState();
}

class _StocksScreenState extends State<StocksScreen> {
  List<StockQuote> _stocks = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadStocks();
    
    // Track screen visit
    WidgetsBinding.instance.addPostFrameCallback((_) {
      UserProgressService().trackScreenVisit(
        screenName: 'StocksScreen',
        screenType: 'main',
        metadata: {'section': 'stocks'},
      );
    });
  }

  Future<void> _loadStocks() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      await StockApiService.init();
      final stocks = await StockApiService.getPopularStocks();

      setState(() {
        _stocks = stocks;
        _isLoading = false;
      });
    } catch (e) {
      final errorMessage = ErrorHandler.getErrorMessage(e);
      setState(() {
        _error = errorMessage;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('Learn & Trade', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black, size: 28),
            onPressed: _loadStocks,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? ErrorHandler.buildErrorWidget(
                  _error!,
                  onRetry: _loadStocks,
                )
              : _stocks.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Error: $_error'),
                      ElevatedButton(
                        onPressed: _loadStocks,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  children: [
                    const SizedBox(height: 24),
                    _buildSectionHeader(context, 'Popular Stocks'),
                    const SizedBox(height: 8),
                    Text(
                      'Learn about these companies and practice trading!',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ..._stocks.map((stock) => _buildStockItem(stock)).toList(),
                  ],
                ),
    );
  }

  Widget _buildStockItem(StockQuote stock) {
    return GestureDetector(
      onTap: () async {
        // Track interaction
        await UserProgressService().trackWidgetInteraction(
          screenName: 'StocksScreen',
          widgetType: 'stock_card',
          actionType: 'tap',
          widgetId: stock.symbol,
          interactionData: {'symbol': stock.symbol, 'name': stock.name},
        );
        
        // Track navigation
        await UserProgressService().trackNavigation(
          fromScreen: 'StocksScreen',
          toScreen: 'EnhancedStockDetailScreen',
          navigationMethod: 'push',
          navigationData: {'symbol': stock.symbol},
        );
        
        // Track trading activity
        await UserProgressService().trackTradingActivity(
          activityType: 'view_stock',
          symbol: stock.symbol,
          activityData: {'from': 'stocks_screen'},
        );
        
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => EnhancedStockDetailScreen(
            symbol: stock.symbol,
            companyName: stock.name.isNotEmpty ? stock.name : stock.symbol,
          )),
        );
      },
      child: StockListItem(
        icon: _getIconForSymbol(stock.symbol),
        ticker: stock.symbol,
        company: stock.name.isNotEmpty ? stock.name : stock.symbol,
        price: '\$${stock.currentPrice.toStringAsFixed(2)}',
        change: '${stock.change >= 0 ? '+' : ''}${stock.changePercent.toStringAsFixed(2)}%',
        isGainer: stock.change >= 0,
      ),
    );
  }

  IconData _getIconForSymbol(String symbol) {
    switch (symbol) {
      case 'AAPL':
        return Icons.apple;
      case 'GOOGL':
        return Icons.search;
      case 'MSFT':
        return Icons.business;
      case 'AMZN':
        return Icons.shopping_cart;
      case 'TSLA':
        return Icons.electric_car;
      case 'META':
        return Icons.people;
      case 'NVDA':
        return Icons.memory;
      case 'NFLX':
        return Icons.play_circle;
      default:
        return Icons.trending_up;
    }
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold));
  }
}
