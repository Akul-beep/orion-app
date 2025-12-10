import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/paper_trading_service.dart';
import '../services/stock_api_service.dart';
import '../services/user_progress_service.dart';
import '../services/gamification_service.dart';
import '../models/paper_trade.dart';
import '../utils/currency_converter.dart';
import 'stock_detail_screen.dart';

class PaperTradingScreen extends StatefulWidget {
  const PaperTradingScreen({Key? key}) : super(key: key);

  @override
  State<PaperTradingScreen> createState() => _PaperTradingScreenState();
}

class _PaperTradingScreenState extends State<PaperTradingScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _symbolController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  String _selectedAction = 'buy';
  double _currentPrice = 0.0;
  bool _isLoading = false;
  String? _priceError;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _quantityController.text = '1';
    
    // Track screen visit
    WidgetsBinding.instance.addPostFrameCallback((_) {
      UserProgressService().trackScreenVisit(
        screenName: 'PaperTradingScreen',
        screenType: 'main',
        metadata: {'section': 'trading'},
      );
    });
    
    // Start real-time price updates
    _startPriceUpdates();
  }

  void _startPriceUpdates() {
    // Update prices every 30 seconds
    Future.delayed(const Duration(seconds: 30), () {
      if (mounted) {
        _updateAllPrices();
        _startPriceUpdates(); // Continue updating
      }
    });
  }

  void _updateAllPrices() async {
    // This would update all positions with current prices
    // For now, just trigger a rebuild
    setState(() {});
  }

  @override
  void dispose() {
    _tabController.dispose();
    _symbolController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PaperTradingService>(
      builder: (context, tradingService, child) {
        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            title: Text(
              'Paper Trading',
              style: GoogleFonts.poppins(
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
            backgroundColor: Colors.white,
            elevation: 0,
            iconTheme: const IconThemeData(color: Colors.black),
            bottom: TabBar(
              controller: _tabController,
              labelColor: const Color(0xFF0052FF),
              unselectedLabelColor: const Color(0xFF6B7280),
              indicatorColor: const Color(0xFF0052FF),
              labelStyle: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
              unselectedLabelStyle: GoogleFonts.inter(
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
              tabs: const [
                Tab(text: 'Trade'),
                Tab(text: 'Portfolio'),
                Tab(text: 'Watchlist'),
                Tab(text: 'History'),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              _buildTradeTab(tradingService),
              _buildPortfolioTab(tradingService),
              _buildWatchlistTab(tradingService),
              _buildHistoryTab(tradingService),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTradeTab(PaperTradingService tradingService) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPortfolioSummary(tradingService),
          const SizedBox(height: 24),
          _buildMarketOverview(),
          const SizedBox(height: 24),
          _buildTradeForm(tradingService),
          const SizedBox(height: 24),
          _buildQuickActions(tradingService),
        ],
      ),
    );
  }

  Widget _buildPortfolioSummary(PaperTradingService tradingService) {
    final portfolio = tradingService.portfolio;
    final isProfit = portfolio.totalPnL > 0;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isProfit 
            ? [Colors.green[50]!, Colors.green[100]!]
            : [Colors.red[50]!, Colors.red[100]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isProfit ? Colors.green[200]! : Colors.red[200]!,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isProfit ? Icons.trending_up : Icons.trending_down,
                color: isProfit ? Colors.green[600] : Colors.red[600],
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                'Portfolio Value',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '\$${portfolio.totalValue.toStringAsFixed(2)}',
            style: GoogleFonts.poppins(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                '${isProfit ? '+' : ''}\$${portfolio.totalPnL.toStringAsFixed(2)}',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isProfit ? Colors.green[600] : Colors.red[600],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '(${isProfit ? '+' : ''}${portfolio.totalPnLPercent.toStringAsFixed(2)}%)',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: isProfit ? Colors.green[600] : Colors.red[600],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildSummaryItem('Cash', '\$${portfolio.cashBalance.toStringAsFixed(2)}'),
              ),
              Expanded(
                child: _buildSummaryItem('Invested', '\$${portfolio.investedValue.toStringAsFixed(2)}'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
      ],
    );
  }

  Widget _buildMarketOverview() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.trending_up, color: Colors.blue[600], size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                'Market Overview',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildMarketIndices(),
        ],
      ),
    );
  }

  Widget _buildMarketIndices() {
    final indices = [
      {'name': 'S&P 500', 'symbol': 'SPY', 'price': 450.25, 'change': 2.15, 'changePercent': 0.48},
      {'name': 'NASDAQ', 'symbol': 'QQQ', 'price': 380.15, 'change': -1.25, 'changePercent': -0.33},
      {'name': 'DOW', 'symbol': 'DIA', 'price': 345.80, 'change': 1.45, 'changePercent': 0.42},
    ];

    return Column(
      children: indices.map((index) => _buildIndexCard(index)).toList(),
    );
  }

  Widget _buildIndexCard(Map<String, dynamic> index) {
    final isPositive = index['change'] > 0;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  index['name'],
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                Text(
                  index['symbol'],
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '\$${index['price'].toStringAsFixed(2)}',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              Row(
                children: [
                  Icon(
                    isPositive ? Icons.trending_up : Icons.trending_down,
                    color: isPositive ? Colors.green : Colors.red,
                    size: 12,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${isPositive ? '+' : ''}\$${index['change'].toStringAsFixed(2)}',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: isPositive ? Colors.green : Colors.red,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTradeForm(PaperTradingService tradingService) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Place Trade',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 20),
          // Symbol Input
          TextField(
            controller: _symbolController,
            decoration: InputDecoration(
              labelText: 'Stock Symbol',
              hintText: 'e.g., AAPL, TSLA, GOOGL',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              prefixIcon: const Icon(Icons.search),
            ),
            onChanged: (value) => _updateCurrentPrice(value.toUpperCase()),
          ),
          const SizedBox(height: 16),
          // Action Selection
          Row(
            children: [
              Expanded(
                child: _buildActionButton('Buy', 'buy', Icons.trending_up, Colors.green),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionButton('Sell', 'sell', Icons.trending_down, Colors.red),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Quantity Input
          TextField(
            controller: _quantityController,
            decoration: InputDecoration(
              labelText: 'Quantity',
              hintText: 'Number of shares',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              prefixIcon: const Icon(Icons.numbers),
            ),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),
          // Current Price Display
          if (_priceError != null)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: Colors.orange[700], size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _priceError!,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.orange[900],
                      ),
                    ),
                  ),
                ],
              ),
            )
          else if (_currentPrice > 0)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.info, color: Colors.blue[600], size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Current Price: \$${_currentPrice.toStringAsFixed(2)}',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.blue[700],
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 20),
          // Place Trade Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading ? null : () => _placeTrade(tradingService),
              style: ElevatedButton.styleFrom(
                backgroundColor: _selectedAction == 'buy' ? Colors.green : Colors.red,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : Text(
                    '${_selectedAction.toUpperCase()} ${_quantityController.text} ${_symbolController.text.toUpperCase()}',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(String label, String action, IconData icon, Color color) {
    final isSelected = _selectedAction == action;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedAction = action;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : Colors.grey[300]!,
            width: 2,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? color : Colors.grey[600],
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isSelected ? color : Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions(PaperTradingService tradingService) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildQuickActionButton(
                'Popular Stocks',
                Icons.trending_up,
                Colors.blue,
                () => _showPopularStocks(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildQuickActionButton(
                'Reset Portfolio',
                Icons.refresh,
                Colors.orange,
                () => _resetPortfolio(tradingService),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickActionButton(String label, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPortfolioTab(PaperTradingService tradingService) {
    final positions = tradingService.positions;
    
    if (positions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.account_balance_wallet_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No Positions',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Start trading to see your positions here',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: positions.length,
      itemBuilder: (context, index) {
        final position = positions[index];
        return _buildPositionCard(position);
      },
    );
  }

  Widget _buildPositionCard(PaperPosition position) {
    final isProfit = position.unrealizedPnL > 0;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  position.symbol,
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isProfit ? Colors.green[50] : Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  isProfit ? 'PROFIT' : 'LOSS',
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: isProfit ? Colors.green[700] : Colors.red[700],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildPositionItem('Shares', '${position.quantity}'),
              ),
              Expanded(
                child: _buildPositionItem('Avg Price', CurrencyConverter.formatPrice(position.averagePrice, position.symbol)),
              ),
              Expanded(
                child: _buildPositionItem('Current', CurrencyConverter.formatPrice(position.currentPrice, position.symbol)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildPositionItem('Value', CurrencyConverter.formatPrice(position.currentValue, position.symbol)),
              ),
              Expanded(
                child: _buildPositionItem('P&L', CurrencyConverter.formatPriceChange(position.unrealizedPnL, position.symbol)),
              ),
              Expanded(
                child: _buildPositionItem('P&L %', '${isProfit ? '+' : ''}${position.unrealizedPnLPercent.toStringAsFixed(2)}%'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPositionItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
      ],
    );
  }

  Widget _buildWatchlistTab(PaperTradingService tradingService) {
    final watchlist = [
      {'symbol': 'AAPL', 'name': 'Apple Inc.', 'price': 175.20, 'change': 2.15, 'changePercent': 1.24},
      {'symbol': 'TSLA', 'name': 'Tesla Inc.', 'price': 248.50, 'change': -5.30, 'changePercent': -2.09},
      {'symbol': 'GOOGL', 'name': 'Alphabet Inc.', 'price': 142.50, 'change': 1.25, 'changePercent': 0.88},
      {'symbol': 'MSFT', 'name': 'Microsoft Corp.', 'price': 378.85, 'change': 3.45, 'changePercent': 0.92},
      {'symbol': 'NVDA', 'name': 'NVIDIA Corp.', 'price': 875.30, 'change': 12.50, 'changePercent': 1.45},
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: watchlist.length,
      itemBuilder: (context, index) {
        final stock = watchlist[index];
        return _buildWatchlistCard(stock);
      },
    );
  }

  Widget _buildWatchlistCard(Map<String, dynamic> stock) {
    final isPositive = stock['change'] > 0;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  stock['symbol'],
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                Text(
                  stock['name'],
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '\$${stock['price'].toStringAsFixed(2)}',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              Row(
                children: [
                  Icon(
                    isPositive ? Icons.trending_up : Icons.trending_down,
                    color: isPositive ? Colors.green : Colors.red,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${isPositive ? '+' : ''}\$${stock['change'].toStringAsFixed(2)}',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: isPositive ? Colors.green : Colors.red,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              Text(
                '${isPositive ? '+' : ''}${stock['changePercent'].toStringAsFixed(2)}%',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: isPositive ? Colors.green : Colors.red,
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),
          Column(
            children: [
              IconButton(
                onPressed: () => _addToWatchlist(stock['symbol']),
                icon: const Icon(Icons.add, color: Colors.blue),
                tooltip: 'Add to watchlist',
              ),
              IconButton(
                onPressed: () => _tradeStock(stock['symbol']),
                icon: const Icon(Icons.trending_up, color: Colors.green),
                tooltip: 'Trade this stock',
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _addToWatchlist(String symbol) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.star, color: Color(0xFFF59E0B), size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '$symbol added to watchlist',
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

  void _tradeStock(String symbol) {
    _symbolController.text = symbol;
    _tabController.animateTo(0); // Switch to trade tab
  }

  Widget _buildHistoryTab(PaperTradingService tradingService) {
    final trades = tradingService.recentTrades;
    
    if (trades.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.history,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No Trades Yet',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your trading history will appear here',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: trades.length,
      itemBuilder: (context, index) {
        final trade = trades[index];
        return _buildTradeCard(trade);
      },
    );
  }

  Widget _buildTradeCard(PaperTrade trade) {
    final isBuy = trade.isBuy;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isBuy ? Colors.green[50] : Colors.red[50],
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              isBuy ? Icons.trending_up : Icons.trending_down,
              color: isBuy ? Colors.green[600] : Colors.red[600],
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${trade.action.toUpperCase()} ${trade.quantity} ${trade.symbol}',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Price: \$${trade.price.toStringAsFixed(2)}',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                Text(
                  'Total: \$${trade.totalValue.toStringAsFixed(2)}',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                trade.status.toUpperCase(),
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: trade.isFilled ? Colors.green[600] : Colors.orange[600],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${trade.timestamp.day}/${trade.timestamp.month}',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _updateCurrentPrice(String symbol) async {
    if (symbol.isNotEmpty) {
      setState(() {
        _isLoading = true;
      });
      
      try {
        // Try to get real price from API
        print('🔍 Fetching live price for $symbol...');
        final quote = await StockApiService.getQuote(symbol.toUpperCase());
        print('✅ Got live price for $symbol: \$${quote.currentPrice}');
        setState(() {
          _currentPrice = quote.currentPrice;
          _isLoading = false;
          _priceError = null; // Clear any previous errors
        });
        
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0052FF).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.trending_up, color: Color(0xFF0052FF), size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Live price for $symbol: \$${quote.currentPrice.toStringAsFixed(2)}',
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
              side: const BorderSide(color: Color(0xFF0052FF), width: 1.5),
            ),
            margin: const EdgeInsets.all(16),
            duration: const Duration(seconds: 2),
          ),
        );
      } catch (e) {
        // Show error instead of mock price - Apple doesn't allow fake data
        print('❌ Error fetching price for $symbol: $e');
        setState(() {
          _isLoading = false;
          _priceError = 'Unable to fetch current price. Please check your connection and try again.';
        });
        
        // Show error message to user
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Price data unavailable. Please check your connection.'),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    }
  }

  void _placeTrade(PaperTradingService tradingService) async {
    final symbol = _symbolController.text.toUpperCase();
    final quantity = int.tryParse(_quantityController.text) ?? 0;
    
    if (symbol.isEmpty || quantity <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter valid symbol and quantity'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final success = await tradingService.placeTrade(
      symbol: symbol,
      action: _selectedAction,
      quantity: quantity,
    );

    setState(() {
      _isLoading = false;
    });

    if (success) {
      // Track trade in gamification
      try {
        final gamification = Provider.of<GamificationService>(context, listen: false);
        gamification.trackTrade();
      } catch (e) {
        print('Error tracking trade: $e');
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.check_circle, color: Color(0xFF10B981), size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '${_selectedAction.toUpperCase()} order placed successfully',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
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
            side: const BorderSide(color: Color(0xFF10B981), width: 1.5),
          ),
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 2),
        ),
      );
      
      // Clear form
      _symbolController.clear();
      _quantityController.text = '1';
      _currentPrice = 0.0;
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to place order. Check your balance and try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showPopularStocks() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Popular Stocks',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 16),
            ...['AAPL', 'TSLA', 'GOOGL', 'MSFT', 'AMZN', 'META'].map((symbol) =>
              ListTile(
                title: Text(symbol),
                onTap: () {
                  _symbolController.text = symbol;
                  Navigator.pop(context);
                },
              ),
            ).toList(),
          ],
        ),
      ),
    );
  }

  void _resetPortfolio(PaperTradingService tradingService) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Reset Portfolio',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Are you sure you want to reset your portfolio? This will clear all positions and trading history.',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: GoogleFonts.poppins()),
          ),
          TextButton(
            onPressed: () {
              tradingService.resetPortfolio();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      const Icon(Icons.check_circle_outline, color: Color(0xFF10B981), size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Portfolio reset successfully',
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
            child: Text('Reset', style: GoogleFonts.poppins(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
