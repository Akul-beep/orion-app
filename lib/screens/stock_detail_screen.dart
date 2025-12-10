import 'package:flutter/material.dart';

// Importing the final design widgets
import '../widgets/stock_detail_v4/stock_price_header.dart';
import '../widgets/stock_detail_v4/chart_view.dart';
import '../widgets/stock_detail_v4/wallet_card.dart';
import '../widgets/stock_detail_v4/trade_button.dart';
import '../widgets/stock_detail_v4/about_section.dart';

// Importing the new transaction history widget
import '../widgets/stock_detail_v5/transaction_history.dart';
import '../services/user_progress_service.dart';

class StockDetailScreen extends StatefulWidget {
  final String symbol;
  final String companyName;
  
  const StockDetailScreen({
    super.key,
    required this.symbol,
    required this.companyName,
  });

  @override
  State<StockDetailScreen> createState() => _StockDetailScreenState();
}

class _StockDetailScreenState extends State<StockDetailScreen> {
  @override
  void initState() {
    super.initState();
    // Track screen visit
    WidgetsBinding.instance.addPostFrameCallback((_) {
      UserProgressService().trackScreenVisit(
        screenName: 'StockDetailScreen',
        screenType: 'detail',
        metadata: {'symbol': widget.symbol, 'company_name': widget.companyName},
      );
      
      UserProgressService().trackTradingActivity(
        activityType: 'view_stock_detail',
        symbol: widget.symbol,
        activityData: {'company_name': widget.companyName},
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          widget.companyName,
          style: const TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            StockPriceHeader(symbol: widget.symbol),
            const SizedBox(height: 20),
            ChartView(symbol: widget.symbol),
            const WalletCard(),
            const TradeButton(),
            const AboutSection(),
            const SizedBox(height: 20),
            const TransactionHistory(), // <-- New Widget Added Here
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
