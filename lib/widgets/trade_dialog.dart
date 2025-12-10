import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/paper_trading_service.dart';
import '../services/stock_api_service.dart';
import '../services/user_progress_service.dart';
import '../models/paper_trade.dart';
import '../design_system.dart';
import '../utils/currency_converter.dart';

class TradeDialog extends StatefulWidget {
  final String symbol;
  final String companyName;
  final double currentPrice;
  final bool isBuy;

  const TradeDialog({
    super.key,
    required this.symbol,
    required this.companyName,
    required this.currentPrice,
    this.isBuy = true,
  });

  @override
  State<TradeDialog> createState() => _TradeDialogState();

  static Future<bool> show(
    BuildContext context, {
    required String symbol,
    required String companyName,
    required double currentPrice,
    bool isBuy = true,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.6),
      useSafeArea: true,
      builder: (context) => TradeDialog(
        symbol: symbol,
        companyName: companyName,
        currentPrice: currentPrice,
        isBuy: isBuy,
      ),
    ).then((value) => value ?? false);
  }
}

class _TradeDialogState extends State<TradeDialog> {
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _stopLossController = TextEditingController();
  final TextEditingController _takeProfitController = TextEditingController();
  bool _isLoading = false;
  double _estimatedTotal = 0.0;
  PaperPosition? _currentPosition;
  bool _showAdvancedOptions = false;

  @override
  void initState() {
    super.initState();
    _quantityController.text = '1';
    _priceController.text = widget.currentPrice.toStringAsFixed(2);
    _quantityController.addListener(_calculateTotal);
    _priceController.addListener(_calculateTotal);
    _loadPosition();
    
    // Track dialog open
    WidgetsBinding.instance.addPostFrameCallback((_) {
      UserProgressService().trackWidgetInteraction(
        screenName: 'TradeDialog',
        widgetType: 'dialog',
        actionType: 'open',
        widgetId: 'trade_dialog',
        interactionData: {
          'symbol': widget.symbol,
          'is_buy': widget.isBuy,
          'current_price': widget.currentPrice,
        },
      );
      
      UserProgressService().trackTradingActivity(
        activityType: widget.isBuy ? 'open_buy_dialog' : 'open_sell_dialog',
        symbol: widget.symbol,
        activityData: {'current_price': widget.currentPrice},
      );
    });
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _priceController.dispose();
    _stopLossController.dispose();
    _takeProfitController.dispose();
    super.dispose();
  }

  void _loadPosition() {
    final trading = Provider.of<PaperTradingService>(context, listen: false);
    _currentPosition = trading.getPosition(widget.symbol);
    setState(() {});
  }

  void _calculateTotal() {
    final quantity = int.tryParse(_quantityController.text) ?? 0;
    final price = double.tryParse(_priceController.text) ?? widget.currentPrice;
    setState(() {
      _estimatedTotal = quantity * price;
    });
  }

  Future<void> _executeTrade() async {
    final quantity = int.tryParse(_quantityController.text) ?? 0;
    final price = double.tryParse(_priceController.text) ?? widget.currentPrice;

    if (quantity <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please enter a valid quantity'),
          backgroundColor: OrionDesignSystem.warningOrange,
        ),
      );
      return;
    }

    // Track trade execution
    await UserProgressService().trackWidgetInteraction(
      screenName: 'TradeDialog',
      widgetType: 'button',
      actionType: 'tap',
      widgetId: widget.isBuy ? 'execute_buy' : 'execute_sell',
      interactionData: {
        'symbol': widget.symbol,
        'quantity': quantity,
        'price': price,
        'total': quantity * price,
      },
    );
    
    await UserProgressService().trackTradingActivity(
      activityType: widget.isBuy ? 'execute_buy' : 'execute_sell',
      symbol: widget.symbol,
      activityData: {
        'quantity': quantity,
        'price': price,
        'total': quantity * price,
      },
    );

    setState(() {
      _isLoading = true;
    });

    final trading = Provider.of<PaperTradingService>(context, listen: false);
    
    // Parse stop loss and take profit if provided
    double? stopLoss;
    double? takeProfit;
    
    if (_stopLossController.text.isNotEmpty) {
      stopLoss = double.tryParse(_stopLossController.text);
      if (stopLoss != null && stopLoss > 0) {
        // Validate stop loss: for buy orders, stop loss should be below current price
        // For sell orders, stop loss should be above current price (for short selling concept)
        if (widget.isBuy && stopLoss >= widget.currentPrice) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Stop loss must be below current price for buy orders'),
              backgroundColor: OrionDesignSystem.warningOrange,
            ),
          );
          setState(() {
            _isLoading = false;
          });
          return;
        }
      }
    }
    
    if (_takeProfitController.text.isNotEmpty) {
      takeProfit = double.tryParse(_takeProfitController.text);
      if (takeProfit != null && takeProfit > 0) {
        // Validate take profit: for buy orders, take profit should be above current price
        if (widget.isBuy && takeProfit <= widget.currentPrice) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Take profit must be above current price for buy orders'),
              backgroundColor: OrionDesignSystem.warningOrange,
            ),
          );
          setState(() {
            _isLoading = false;
          });
          return;
        }
      }
    }
    
    // Use market price from API
    try {
      final quote = await StockApiService.getQuote(widget.symbol);
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
              backgroundColor: OrionDesignSystem.successGreen,
              duration: const Duration(seconds: 2),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                widget.isBuy
                    ? 'Insufficient funds. You need ${CurrencyConverter.formatPrice(_estimatedTotal, widget.symbol)}'
                    : 'Insufficient shares. You have ${_currentPosition?.quantity ?? 0} shares',
              ),
              backgroundColor: OrionDesignSystem.warningOrange,
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
            backgroundColor: OrionDesignSystem.warningOrange,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final trading = Provider.of<PaperTradingService>(context);
    final cashBalance = trading.cashBalance;
    final maxAffordable = widget.isBuy
        ? (cashBalance / widget.currentPrice).floor()
        : (_currentPosition?.quantity ?? 0);

    return Material(
      type: MaterialType.transparency,
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 450, maxHeight: 600),
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
              // Professional Header
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: widget.isBuy
                        ? [const Color(0xFF58CC02), const Color(0xFF4CAF50)]
                        : [const Color(0xFFE53935), const Color(0xFFC62828)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        widget.isBuy ? Icons.trending_up : Icons.trending_down,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.isBuy ? 'Buy ${widget.symbol}' : 'Sell ${widget.symbol}',
                            style: GoogleFonts.poppins(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.companyName,
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: Colors.white.withOpacity(0.9),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.of(context).pop(false),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Current Price Card
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2C2C54).withOpacity(0.05),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFF2C2C54).withOpacity(0.1),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Current Price',
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                CurrencyConverter.formatPrice(widget.currentPrice, widget.symbol),
                                style: GoogleFonts.poppins(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF2C2C54),
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF2C2C54).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.attach_money,
                              color: const Color(0xFF2C2C54),
                              size: 24,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Quantity Input
                    Text(
                      'Quantity',
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF2C2C54),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _quantityController,
                      keyboardType: TextInputType.number,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Enter number of shares',
                        filled: true,
                        fillColor: Colors.grey[50],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: widget.isBuy
                                ? const Color(0xFF58CC02)
                                : const Color(0xFFE53935),
                            width: 2,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        suffixIcon: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove_circle_outline),
                              onPressed: () {
                                final current = int.tryParse(_quantityController.text) ?? 0;
                                if (current > 1) {
                                  _quantityController.text = (current - 1).toString();
                                }
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.add_circle_outline),
                              onPressed: () {
                                final current = int.tryParse(_quantityController.text) ?? 0;
                                if (current < maxAffordable) {
                                  _quantityController.text = (current + 1).toString();
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (widget.isBuy)
                      Text(
                        'Max affordable: $maxAffordable shares',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      )
                    else if (_currentPosition != null)
                      Text(
                        'Available: ${_currentPosition!.quantity} shares',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    const SizedBox(height: 20),

                    // Estimated Total
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: widget.isBuy
                              ? [const Color(0xFF58CC02), const Color(0xFF4CAF50)]
                              : [const Color(0xFFE53935), const Color(0xFFC62828)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: (widget.isBuy ? const Color(0xFF58CC02) : const Color(0xFFE53935)).withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Estimated Total',
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  color: Colors.white.withOpacity(0.9),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                CurrencyConverter.formatPrice(_estimatedTotal, widget.symbol),
                                style: GoogleFonts.poppins(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.calculate,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Cash Balance / Position Info
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2C2C54).withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFF2C2C54).withOpacity(0.1),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF2C2C54).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              widget.isBuy ? Icons.account_balance_wallet : Icons.inventory,
                              color: const Color(0xFF2C2C54),
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              widget.isBuy
                                  ? 'Cash Balance: \$${cashBalance.toStringAsFixed(2)}'
                                  : _currentPosition != null
                                      ? 'Position: ${_currentPosition!.quantity} shares @ ${CurrencyConverter.formatPrice(_currentPosition!.averagePrice, widget.symbol)}'
                                      : 'No position',
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFF2C2C54),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Advanced Options Toggle
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _showAdvancedOptions = !_showAdvancedOptions;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2C2C54).withOpacity(0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFF2C2C54).withOpacity(0.1),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.tune,
                                  color: const Color(0xFF2C2C54),
                                  size: 20,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'Advanced Options (Stop Loss / Take Profit)',
                                  style: GoogleFonts.poppins(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF2C2C54),
                                  ),
                                ),
                              ],
                            ),
                            Icon(
                              _showAdvancedOptions
                                  ? Icons.keyboard_arrow_up
                                  : Icons.keyboard_arrow_down,
                              color: const Color(0xFF2C2C54),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Stop Loss & Take Profit (Advanced Options)
                    if (_showAdvancedOptions) ...[
                      // Stop Loss Input
                      Text(
                        'Stop Loss (Optional)',
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF2C2C54),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _stopLossController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                        decoration: InputDecoration(
                          hintText: widget.isBuy 
                              ? 'Set stop loss below current price' 
                              : 'Set stop loss above current price',
                          prefixIcon: const Icon(Icons.stop_circle_outlined),
                          filled: true,
                          fillColor: Colors.grey[50],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Color(0xFFE53935),
                              width: 2,
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          helperText: widget.isBuy
                              ? 'Auto-sell if price drops to this level'
                              : 'Auto-buy if price rises to this level',
                          helperStyle: GoogleFonts.poppins(
                            fontSize: 11,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Take Profit Input
                      Text(
                        'Take Profit (Optional)',
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF2C2C54),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _takeProfitController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                        decoration: InputDecoration(
                          hintText: widget.isBuy
                              ? 'Set take profit above current price'
                              : 'Set take profit below current price',
                          prefixIcon: const Icon(Icons.trending_up),
                          filled: true,
                          fillColor: Colors.grey[50],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Color(0xFF58CC02),
                              width: 2,
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          helperText: widget.isBuy
                              ? 'Auto-sell if price reaches this level'
                              : 'Auto-buy if price drops to this level',
                          helperStyle: GoogleFonts.poppins(
                            fontSize: 11,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Quick Set Buttons
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                if (widget.isBuy) {
                                  _stopLossController.text = (widget.currentPrice * 0.95).toStringAsFixed(2);
                                } else {
                                  _stopLossController.text = (widget.currentPrice * 1.05).toStringAsFixed(2);
                                }
                              },
                              icon: const Icon(Icons.speed, size: 18),
                              label: const Text('5% Stop'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFFE53935),
                                side: const BorderSide(color: Color(0xFFE53935)),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                if (widget.isBuy) {
                                  _takeProfitController.text = (widget.currentPrice * 1.10).toStringAsFixed(2);
                                } else {
                                  _takeProfitController.text = (widget.currentPrice * 0.90).toStringAsFixed(2);
                                }
                              },
                              icon: const Icon(Icons.trending_up, size: 18),
                              label: const Text('10% Profit'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFF58CC02),
                                side: const BorderSide(color: Color(0xFF58CC02)),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                    ],

                    // Action Buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _isLoading ? null : () => Navigator.of(context).pop(false),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              side: BorderSide(color: Colors.grey[300]!, width: 1.5),
                            ),
                            child: Text(
                              'Cancel',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[700],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _executeTrade,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: widget.isBuy
                                  ? const Color(0xFF58CC02)
                                  : const Color(0xFFE53935),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 4,
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  )
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        widget.isBuy ? Icons.trending_up : Icons.trending_down,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        widget.isBuy ? 'Buy' : 'Sell',
                                        style: GoogleFonts.poppins(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
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
            ),
          ),
        ),
      ),
    );
  }
}

