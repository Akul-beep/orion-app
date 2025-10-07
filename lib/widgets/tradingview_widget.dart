import 'package:flutter/material.dart';
import 'tradingview_advanced_chart.dart';

class TradingViewWidget extends StatelessWidget {
  final String symbol;
  final double height;
  final String theme; // 'light' or 'dark'
  final bool showToolbar;
  final bool showVolume;
  final bool showLegend;

  const TradingViewWidget({
    super.key,
    required this.symbol,
    this.height = 300,
    this.theme = 'light',
    this.showToolbar = true,
    this.showVolume = true,
    this.showLegend = true,
  });

  @override
  Widget build(BuildContext context) {
    return TradingViewAdvancedChart(
      symbol: symbol,
      height: height,
      theme: theme,
      showToolbar: showToolbar,
      showVolume: showVolume,
      showLegend: showLegend,
      interval: 'D',
    );
  }
}
