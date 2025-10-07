import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../widgets/tradingview_actual_widget.dart';

class FullMobileChartScreen extends StatefulWidget {
  final String symbol;
  final String companyName;

  const FullMobileChartScreen({
    super.key,
    required this.symbol,
    required this.companyName,
  });

  @override
  State<FullMobileChartScreen> createState() => _FullMobileChartScreenState();
}

class _FullMobileChartScreenState extends State<FullMobileChartScreen> {
  @override
  void initState() {
    super.initState();
    // Set system UI overlay style for fullscreen mobile experience
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
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
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // Mobile Header with Back Button
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(
                color: Color(0xFF2C2C54),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Back Button
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.arrow_back,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  
                  // Stock Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.symbol,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          widget.companyName,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Fullscreen Indicator
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.fullscreen,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ],
              ),
            ),
            
            // Full Mobile Chart
            Expanded(
              child: Container(
                width: double.infinity,
                color: Colors.white,
                child: TradingViewActualWidget(
                  symbol: widget.symbol,
                  height: MediaQuery.of(context).size.height - 100,
                  theme: 'light',
                  showToolbar: true,
                  showVolume: true,
                  showLegend: true,
                  interval: 'D',
                ),
              ),
            ),
            
          ],
        ),
      ),
    );
  }

}
