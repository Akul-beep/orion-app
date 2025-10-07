import 'package:flutter/material.dart';
import '../tradingview_embedded_chart.dart';

class PriceChart extends StatelessWidget {
  const PriceChart({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 250,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('\$253.06', style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold)),
          const Text('-1.36 (0.54%) Today', style: TextStyle(color: Colors.red, fontSize: 16, fontWeight: FontWeight.bold)),
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(top: 20),
              child: TradingViewEmbeddedChart(
                symbol: 'AAPL',
                height: 200,
                theme: 'light',
                showToolbar: false,
                showVolume: true,
                showLegend: true,
                interval: 'D',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
