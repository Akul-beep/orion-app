import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/tradingview_actual_widget.dart';
import '../widgets/custom_stock_chart.dart';
import '../services/user_progress_service.dart';
import '../models/company_profile.dart';
import '../utils/market_detector.dart';

class FullMobileChartScreen extends StatefulWidget {
  final String symbol;
  final String companyName;
  final CompanyProfile? profile; // Add profile for Indian stock support

  const FullMobileChartScreen({
    super.key,
    required this.symbol,
    required this.companyName,
    this.profile, // Optional profile
  });

  @override
  State<FullMobileChartScreen> createState() => _FullMobileChartScreenState();
}

class _FullMobileChartScreenState extends State<FullMobileChartScreen> {
  Key _chartKey = UniqueKey(); // Key to force chart refresh
  
  @override
  void initState() {
    super.initState();
    // Set system UI overlay style for fullscreen mobile experience
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    
    // Track screen visit
    WidgetsBinding.instance.addPostFrameCallback((_) {
      UserProgressService().trackScreenVisit(
        screenName: 'FullMobileChartScreen',
        screenType: 'detail',
        metadata: {'symbol': widget.symbol, 'company_name': widget.companyName},
      );
      
      UserProgressService().trackTradingActivity(
        activityType: 'view_chart',
        symbol: widget.symbol,
        activityData: {'chart_type': 'fullscreen'},
      );
    });
  }

  @override
  void dispose() {
    // Restore system UI when leaving fullscreen
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF111827)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.symbol,
              style: GoogleFonts.inter(
                color: const Color(0xFF111827),
                fontSize: 18,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.5,
              ),
            ),
            Text(
              widget.companyName,
              style: GoogleFonts.inter(
                color: const Color(0xFF6B7280),
                fontSize: 12,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
        centerTitle: false,
        actions: [
          // Refresh Button
          IconButton(
            onPressed: () {
              setState(() {
                // Force chart refresh by changing key
                _chartKey = UniqueKey();
              });
            },
            icon: const Icon(Icons.refresh, size: 24),
            color: const Color(0xFF0052FF),
            tooltip: 'Refresh Chart',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Container(
        width: double.infinity,
        color: Colors.white,
        child: MarketDetector.isIndianStock(widget.symbol)
            ? // Indian stocks: Use historical data chart (CustomStockChart)
              CustomStockChart(
                key: _chartKey, // Use key to force refresh
                symbol: widget.symbol,
                height: MediaQuery.of(context).size.height - 
                        MediaQuery.of(context).padding.top - 
                        kToolbarHeight,
                theme: 'light',
                interval: 'D',
              )
            : // US stocks: Use TradingView widget
              TradingViewActualWidget(
                key: _chartKey, // Use key to force refresh
                symbol: widget.symbol,
                profile: widget.profile, // Pass profile for US stock support
                height: MediaQuery.of(context).size.height - 
                        MediaQuery.of(context).padding.top - 
                        kToolbarHeight,
                theme: 'light',
                showToolbar: true,
                showVolume: true,
                showLegend: true,
                interval: 'D',
              ),
      ),
    );
  }

}
