import 'package:flutter/material.dart';
import 'tradingview_advanced_chart.dart';

class TradingViewAdvancedWidget extends StatelessWidget {
  final String symbol;
  final double height;
  final String theme; // 'light' or 'dark'
  final bool showToolbar;
  final bool showVolume;
  final bool showLegend;
  final String interval; // '1', '5', '15', '30', '60', 'D', 'W', 'M'

  const TradingViewAdvancedWidget({
    super.key,
    required this.symbol,
    this.height = 400,
    this.theme = 'light',
    this.showToolbar = true,
    this.showVolume = true,
    this.showLegend = true,
    this.interval = 'D',
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
      interval: interval,
    );
  }
}
