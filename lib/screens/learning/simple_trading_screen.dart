import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/user_progress_service.dart';

class SimpleTradingScreen extends StatefulWidget {
  final String? symbol;
  final String? lessonTitle;

  const SimpleTradingScreen({
    Key? key,
    this.symbol,
    this.lessonTitle,
  }) : super(key: key);

  @override
  _SimpleTradingScreenState createState() => _SimpleTradingScreenState();
}

class _SimpleTradingScreenState extends State<SimpleTradingScreen> {
  double _portfolioValue = 10000.0;
  double _cashBalance = 10000.0;
  Map<String, int> _holdings = {};
  List<Map<String, dynamic>> _transactions = [];
  String _selectedSymbol = 'AAPL';
  int _sharesToTrade = 10;
  double _currentPrice = 150.0;
  bool _isBuying = true;

  final Map<String, Map<String, dynamic>> _stocks = {
    'AAPL': {
      'name': 'Apple Inc.',
      'price': 150.0,
      'change': 2.5,
      'changePercent': 1.69,
      'color': Colors.green,
    },
    'TSLA': {
      'name': 'Tesla Inc.',
      'price': 200.0,
      'change': -5.0,
      'changePercent': -2.44,
      'color': Colors.red,
    },
    'GOOGL': {
      'name': 'Google Inc.',
      'price': 120.0,
      'change': 1.2,
      'changePercent': 1.01,
      'color': Colors.green,
    },
    'MSFT': {
      'name': 'Microsoft Corp.',
      'price': 300.0,
      'change': -2.0,
      'changePercent': -0.66,
      'color': Colors.red,
    },
    'AMZN': {
      'name': 'Amazon Inc.',
      'price': 100.0,
      'change': 3.0,
      'changePercent': 3.09,
      'color': Colors.green,
    },
  };

  @override
  void initState() {
    super.initState();
    if (widget.symbol != null) {
      _selectedSymbol = widget.symbol!;
      _currentPrice = _stocks[widget.symbol!]!['price'];
    }
    
    // Track screen visit
    WidgetsBinding.instance.addPostFrameCallback((_) {
      UserProgressService().trackScreenVisit(
        screenName: 'SimpleTradingScreen',
        screenType: 'detail',
        metadata: {'symbol': _selectedSymbol, 'lesson_title': widget.lessonTitle},
      );
      
      UserProgressService().trackTradingActivity(
        activityType: 'open_trading_screen',
        symbol: _selectedSymbol,
        activityData: {'lesson_title': widget.lessonTitle},
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Trade ${_selectedSymbol}',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '\$${_portfolioValue.toStringAsFixed(0)}',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildPortfolioCard(),
            const SizedBox(height: 24),
            _buildStockCard(),
            const SizedBox(height: 24),
            _buildTradeForm(),
            const SizedBox(height: 24),
            _buildRecentTransactions(),
          ],
        ),
      ),
    );
  }

  Widget _buildPortfolioCard() {
    final totalValue = _calculateTotalValue();
    final gainLoss = totalValue - 10000.0;
    final gainLossPercent = (gainLoss / 10000.0) * 100;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue[600]!, Colors.purple[600]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your Portfolio',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total Value',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                  ),
                  Text(
                    '\$${totalValue.toStringAsFixed(2)}',
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Today\'s Change',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                  ),
                  Text(
                    '${gainLoss >= 0 ? '+' : ''}\$${gainLoss.toStringAsFixed(2)} (${gainLossPercent.toStringAsFixed(1)}%)',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: gainLoss >= 0 ? Colors.green : Colors.red,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildPortfolioStat('Cash', '\$${_cashBalance.toStringAsFixed(0)}', Colors.white70),
              ),
              Expanded(
                child: _buildPortfolioStat('Invested', '\$${(totalValue - _cashBalance).toStringAsFixed(0)}', Colors.white70),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPortfolioStat(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: color,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildStockCard() {
    final stock = _stocks[_selectedSymbol]!;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _selectedSymbol,
                    style: GoogleFonts.poppins(
                      fontSize: 20,
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
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: stock['color'].withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${stock['changePercent'] >= 0 ? '+' : ''}${stock['changePercent'].toStringAsFixed(2)}%',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: stock['color'],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Price',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              Text(
                '\$${stock['price'].toStringAsFixed(2)}',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Change',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              Text(
                '${stock['change'] >= 0 ? '+' : ''}\$${stock['change'].toStringAsFixed(2)}',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: stock['color'],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTradeForm() {
    final totalCost = _sharesToTrade * _currentPrice;
    final canAfford = totalCost <= _cashBalance;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Place Trade',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildTradeButton('Buy', true, Colors.green),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTradeButton('Sell', false, Colors.red),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Number of Shares',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Slider(
                  value: _sharesToTrade.toDouble(),
                  min: 1,
                  max: 100,
                  divisions: 99,
                  onChanged: (value) {
                    setState(() {
                      _sharesToTrade = value.round();
                    });
                  },
                ),
              ),
              Container(
                width: 60,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$_sharesToTrade',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Shares:',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    Text(
                      '$_sharesToTrade',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Price per share:',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    Text(
                      '\$${_currentPrice.toStringAsFixed(2)}',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total Cost:',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    Text(
                      '\$${totalCost.toStringAsFixed(2)}',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: canAfford ? Colors.green : Colors.red,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: canAfford ? _executeTrade : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: _isBuying ? Colors.green : Colors.red,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                '${_isBuying ? 'Buy' : 'Sell'} $_sharesToTrade Shares',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTradeButton(String label, bool isBuy, Color color) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _isBuying = isBuy;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: _isBuying == isBuy ? color : Colors.grey[200],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: _isBuying == isBuy ? Colors.white : Colors.grey[600],
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildRecentTransactions() {
    if (_transactions.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          children: [
            Text(
              'No Transactions Yet',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Make your first trade to see it here!',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recent Transactions',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 16),
          ..._transactions.take(5).map((transaction) => _buildTransactionItem(transaction)),
        ],
      ),
    );
  }

  Widget _buildTransactionItem(Map<String, dynamic> transaction) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: transaction['type'] == 'BUY' ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              transaction['type'] == 'BUY' ? Icons.arrow_upward : Icons.arrow_downward,
              color: transaction['type'] == 'BUY' ? Colors.green : Colors.red,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${transaction['type']} ${transaction['symbol']}',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                Text(
                  '${transaction['shares']} shares at \$${transaction['price'].toStringAsFixed(2)}',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Text(
            '\$${transaction['total'].toStringAsFixed(2)}',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: transaction['type'] == 'BUY' ? Colors.red : Colors.green,
            ),
          ),
        ],
      ),
    );
  }

  void _executeTrade() {
    final totalCost = _sharesToTrade * _currentPrice;
    
    if (_isBuying) {
      if (totalCost <= _cashBalance) {
        setState(() {
          _cashBalance -= totalCost;
          _holdings[_selectedSymbol] = (_holdings[_selectedSymbol] ?? 0) + _sharesToTrade;
          _transactions.insert(0, {
            'type': 'BUY',
            'symbol': _selectedSymbol,
            'shares': _sharesToTrade,
            'price': _currentPrice,
            'total': totalCost,
            'timestamp': DateTime.now(),
          });
        });
        _showSuccessMessage('Bought $_sharesToTrade shares of $_selectedSymbol!');
      }
    } else {
      final currentHoldings = _holdings[_selectedSymbol] ?? 0;
      if (_sharesToTrade <= currentHoldings) {
        setState(() {
          _cashBalance += totalCost;
          _holdings[_selectedSymbol] = currentHoldings - _sharesToTrade;
          _transactions.insert(0, {
            'type': 'SELL',
            'symbol': _selectedSymbol,
            'shares': _sharesToTrade,
            'price': _currentPrice,
            'total': totalCost,
            'timestamp': DateTime.now(),
          });
        });
        _showSuccessMessage('Sold $_sharesToTrade shares of $_selectedSymbol!');
      } else {
        _showErrorMessage('You don\'t have enough shares to sell!');
      }
    }
  }

  double _calculateTotalValue() {
    double totalValue = _cashBalance;
    _holdings.forEach((symbol, shares) {
      if (_stocks.containsKey(symbol)) {
        totalValue += shares * _stocks[symbol]!['price'];
      }
    });
    return totalValue;
  }

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}



