import 'package:flutter/material.dart';

import '../widgets/stock_list_item.dart';
import '../services/stock_api_service.dart';
import 'enhanced_stock_detail_screen.dart';

class StocksScreen extends StatefulWidget {
  const StocksScreen({super.key});

  @override
  State<StocksScreen> createState() => _StocksScreenState();
}

class _StocksScreenState extends State<StocksScreen> {
  List<Map<String, dynamic>> _stocks = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadStocks();
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
      setState(() {
        _error = e.toString();
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

  Widget _buildStockItem(Map<String, dynamic> stock) {
    final quote = stock['quote'];
    final profile = stock['profile'];
    final symbol = stock['symbol'];
    
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => EnhancedStockDetailScreen(
            symbol: symbol,
            companyName: profile.name,
          )),
        );
      },
      child: StockListItem(
        icon: _getIconForSymbol(symbol),
        ticker: symbol,
        company: profile.name,
        price: '\$${quote.currentPrice.toStringAsFixed(2)}',
        change: '${quote.change >= 0 ? '+' : ''}${quote.changePercent.toStringAsFixed(2)}%',
        isGainer: quote.change >= 0,
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
