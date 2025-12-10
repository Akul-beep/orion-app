import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/paper_trading_service.dart';
import '../services/stock_api_service.dart';
import '../services/user_progress_service.dart';
import '../models/paper_trade.dart';
import '../models/stock_quote.dart';
import '../utils/currency_converter.dart';

class TradingScreen extends StatefulWidget {
  final String symbol;
  final String companyName;
  final double currentPrice;
  final bool isBuy;

  const TradingScreen({
    super.key,
    required this.symbol,
    required this.companyName,
    required this.currentPrice,
    this.isBuy = true,
  });

  @override
  State<TradingScreen> createState() => _TradingScreenState();
}

class _TradingScreenState extends State<TradingScreen> {
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _stopLossController = TextEditingController();
  final TextEditingController _takeProfitController = TextEditingController();
  bool _isLoading = false;
  double _estimatedTotal = 0.0;
  PaperPosition? _currentPosition;
  StockQuote? _currentQuote;
  bool _showAdvancedOptions = false;

  @override
  void initState() {
    super.initState();
    _quantityController.text = '1';
    _quantityController.addListener(_calculateTotal);
    
    // Track screen visit
    WidgetsBinding.instance.addPostFrameCallback((_) {
      UserProgressService().trackScreenVisit(
        screenName: 'TradingScreen',
        screenType: 'detail',
        metadata: {'symbol': widget.symbol, 'is_buy': widget.isBuy},
      );
      
      UserProgressService().trackTradingActivity(
        activityType: widget.isBuy ? 'open_buy_screen' : 'open_sell_screen',
        symbol: widget.symbol,
        activityData: {'current_price': widget.currentPrice},
      );
    });
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _stopLossController.dispose();
    _takeProfitController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_currentQuote == null) {
      _loadData();
    }
  }

  Future<void> _loadData() async {
    final trading = Provider.of<PaperTradingService>(context, listen: false);
    if (mounted) {
      setState(() {
        _currentPosition = trading.getPosition(widget.symbol);
        if (_currentPosition?.stopLoss != null) {
          _stopLossController.text = _currentPosition!.stopLoss!.toStringAsFixed(2);
        }
        if (_currentPosition?.takeProfit != null) {
          _takeProfitController.text = _currentPosition!.takeProfit!.toStringAsFixed(2);
        }
      });
    }

    try {
      final quote = await StockApiService.getQuote(widget.symbol);
      if (mounted) {
        setState(() {
          _currentQuote = quote;
          _estimatedTotal = double.parse(_quantityController.text) * quote.currentPrice;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _estimatedTotal = double.parse(_quantityController.text) * widget.currentPrice;
        });
      }
    }
  }

  void _calculateTotal() {
    final quantity = int.tryParse(_quantityController.text) ?? 0;
    final price = _currentQuote?.currentPrice ?? widget.currentPrice;
    setState(() {
      _estimatedTotal = quantity * price;
    });
  }

  Future<void> _executeTrade() async {
    final quantity = int.tryParse(_quantityController.text) ?? 0;

    if (quantity <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid quantity'),
          backgroundColor: Color(0xFFEF4444),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final trading = Provider.of<PaperTradingService>(context, listen: false);
    
    try {
      final stopLoss = _stopLossController.text.isNotEmpty 
          ? double.tryParse(_stopLossController.text) 
          : null;
      final takeProfit = _takeProfitController.text.isNotEmpty 
          ? double.tryParse(_takeProfitController.text) 
          : null;

      final success = await trading.placeTrade(
        symbol: widget.symbol,
        action: widget.isBuy ? 'buy' : 'sell',
        quantity: quantity,
        stopLoss: stopLoss,
        takeProfit: takeProfit,
      );

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        if (success) {
          Navigator.of(context).pop(true);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '${widget.isBuy ? 'Bought' : 'Sold'} $quantity ${widget.symbol} shares successfully!',
              ),
              backgroundColor: const Color(0xFF10B981),
              duration: const Duration(seconds: 2),
            ),
          );
        } else {
          final trading = Provider.of<PaperTradingService>(context, listen: false);
          final cashBalance = trading.cashBalance;
          final maxAffordable = widget.isBuy
              ? (cashBalance / widget.currentPrice).floor()
              : (_currentPosition?.quantity ?? 0);
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                widget.isBuy
                    ? 'Insufficient funds. You need ${CurrencyConverter.formatPrice(_estimatedTotal, widget.symbol)}'
                    : 'Insufficient shares. You have ${_currentPosition?.quantity ?? 0} shares',
              ),
              backgroundColor: const Color(0xFFEF4444),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    }
  }

  void _setQuickAmount(double percentage) {
    try {
      final trading = Provider.of<PaperTradingService>(context, listen: false);
      final cashBalance = trading.cashBalance;
      final price = _currentQuote?.currentPrice ?? widget.currentPrice;
      
      if (widget.isBuy) {
        final maxShares = (cashBalance / price).floor();
        final shares = (maxShares * percentage).floor();
        _quantityController.text = shares.toString();
      } else if (_currentPosition != null) {
        final shares = (_currentPosition!.quantity * percentage).floor();
        _quantityController.text = shares.toString();
      }
    } catch (e) {
      print('Error setting quick amount: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PaperTradingService>(
      builder: (context, trading, child) {
        final cashBalance = trading.cashBalance;
        final price = _currentQuote?.currentPrice ?? widget.currentPrice;
        final maxAffordable = widget.isBuy
            ? (cashBalance / price).floor()
            : (_currentPosition?.quantity ?? 0);

        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Color(0xFF111827)),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            title: Text(
              widget.isBuy ? 'Buy ${widget.symbol}' : 'Sell ${widget.symbol}',
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF111827),
                letterSpacing: -0.5,
              ),
            ),
            centerTitle: false,
          ),
          body: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Coinbase-style Large Price Display
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(24, 32, 24, 40),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border(
                      bottom: BorderSide(
                        color: const Color(0xFFE5E7EB),
                        width: 1,
                      ),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.companyName,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: const Color(0xFF6B7280),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            CurrencyConverter.formatPrice(price, widget.symbol),
                            style: GoogleFonts.inter(
                              fontSize: 48,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF111827),
                              letterSpacing: -1.0,
                              height: 1.0,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            margin: const EdgeInsets.only(top: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: widget.isBuy 
                                  ? const Color(0xFF10B981).withOpacity(0.1)
                                  : const Color(0xFFEF4444).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  widget.isBuy ? Icons.trending_up : Icons.trending_down,
                                  color: widget.isBuy ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                                  size: 14,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  widget.isBuy ? 'BUY' : 'SELL',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: widget.isBuy ? const Color(0xFF10B981) : const Color(0xFFEF4444),
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

                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Amount Input - Coinbase Style
                      Text(
                        'Amount',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF111827),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3F4F6),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
                        ),
                        child: TextField(
                          controller: _quantityController,
                          keyboardType: TextInputType.number,
                          style: GoogleFonts.inter(
                            fontSize: 32,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF111827),
                            letterSpacing: -0.5,
                          ),
                          decoration: InputDecoration(
                            hintText: '0',
                            hintStyle: GoogleFonts.inter(
                              fontSize: 32,
                              color: const Color(0xFF9CA3AF),
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                            suffixText: 'shares',
                            suffixStyle: GoogleFonts.inter(
                              fontSize: 16,
                              color: const Color(0xFF6B7280),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      
                      // Quick Amount Buttons
                      Row(
                        children: [
                          Expanded(
                            child: _QuickAmountButton(
                              label: '25%',
                              onTap: () => _setQuickAmount(0.25),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _QuickAmountButton(
                              label: '50%',
                              onTap: () => _setQuickAmount(0.5),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _QuickAmountButton(
                              label: '75%',
                              onTap: () => _setQuickAmount(0.75),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _QuickAmountButton(
                              label: '100%',
                              onTap: () => _setQuickAmount(1.0),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Estimated Total - Large Display
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3F4F6),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Estimated Total',
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    color: const Color(0xFF6B7280),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  CurrencyConverter.formatPrice(_estimatedTotal, widget.symbol),
                                  style: GoogleFonts.inter(
                                    fontSize: 36,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF111827),
                                    letterSpacing: -1.0,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Account Info
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  widget.isBuy ? 'Cash Balance' : 'Available Shares',
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    color: const Color(0xFF6B7280),
                                  ),
                                ),
                                Text(
                                  widget.isBuy
                                      ? '\$${cashBalance.toStringAsFixed(2)}'
                                      : '${_currentPosition?.quantity ?? 0} shares',
                                  style: GoogleFonts.inter(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF111827),
                                  ),
                                ),
                              ],
                            ),
                            if (!widget.isBuy && _currentPosition != null) ...[
                              const SizedBox(height: 12),
                              const Divider(color: Color(0xFFE5E7EB)),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Average Price',
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      color: const Color(0xFF6B7280),
                                    ),
                                  ),
                                  Text(
                                    CurrencyConverter.formatPrice(_currentPosition!.averagePrice, widget.symbol),
                                    style: GoogleFonts.inter(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF111827),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Advanced Options Toggle
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _showAdvancedOptions = !_showAdvancedOptions;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Advanced Options',
                                style: GoogleFonts.inter(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF111827),
                                ),
                              ),
                              Icon(
                                _showAdvancedOptions ? Icons.expand_less : Icons.expand_more,
                                color: const Color(0xFF6B7280),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Advanced Options (Stop Loss, Take Profit)
                      if (_showAdvancedOptions) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF3F4F6),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Stop Loss
                              Text(
                                'Stop Loss',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF111827),
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextField(
                                controller: _stopLossController,
                                keyboardType: TextInputType.numberWithOptions(decimal: true),
                                decoration: InputDecoration(
                                  hintText: 'e.g., ${(price * 0.95).toStringAsFixed(2)}',
                                  prefixText: '\$',
                                  prefixStyle: GoogleFonts.inter(
                                    color: const Color(0xFF6B7280),
                                  ),
                                  filled: true,
                                  fillColor: Colors.white,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(color: Color(0xFF0052FF), width: 2),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Automatically sell if price drops to this level',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  color: const Color(0xFF6B7280),
                                ),
                              ),
                              const SizedBox(height: 16),
                              // Take Profit
                              Text(
                                'Take Profit',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF111827),
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextField(
                                controller: _takeProfitController,
                                keyboardType: TextInputType.numberWithOptions(decimal: true),
                                decoration: InputDecoration(
                                  hintText: 'e.g., ${(price * 1.10).toStringAsFixed(2)}',
                                  prefixText: '\$',
                                  prefixStyle: GoogleFonts.inter(
                                    color: const Color(0xFF6B7280),
                                  ),
                                  filled: true,
                                  fillColor: Colors.white,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(color: Color(0xFF0052FF), width: 2),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Automatically sell if price reaches this level',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  color: const Color(0xFF6B7280),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],

                      const SizedBox(height: 8),
                      
                      // Action Button - Coinbase Style
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _executeTrade,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: widget.isBuy ? const Color(0xFF0052FF) : const Color(0xFFEF4444),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 0,
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : Text(
                                  widget.isBuy ? 'Buy ${widget.symbol}' : 'Sell ${widget.symbol}',
                                  style: GoogleFonts.inter(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      
                      // Info text
                      Center(
                        child: Text(
                          widget.isBuy
                              ? 'Max affordable: $maxAffordable shares'
                              : 'Available: ${_currentPosition?.quantity ?? 0} shares',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: const Color(0xFF6B7280),
                          ),
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
  }
}

class _QuickAmountButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _QuickAmountButton({
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
        ),
        child: Center(
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF111827),
            ),
          ),
        ),
      ),
    );
  }
}
