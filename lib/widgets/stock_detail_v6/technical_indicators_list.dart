import 'package:flutter/material.dart';

class TechnicalIndicatorsList extends StatelessWidget {
  const TechnicalIndicatorsList({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20.0),
      children: const [
        _IndicatorTile(indicator: 'RSI (14)', value: '68.5', signal: 'Neutral'),
        _IndicatorTile(indicator: 'MACD (12, 26)', value: '1.25', signal: 'Buy'),
        _IndicatorTile(indicator: 'Moving Average (50)', value: '\$175.80', signal: 'Buy'),
         _IndicatorTile(indicator: 'Stochastic (14, 3, 3)', value: '75.2', signal: 'Sell'),
      ],
    );
  }
}

class _IndicatorTile extends StatelessWidget {
  final String indicator;
  final String value;
  final String signal;

  const _IndicatorTile({required this.indicator, required this.value, required this.signal});

  Color _getSignalColor() {
    switch (signal) {
      case 'Buy':
        return const Color(0xFF00D09C);
      case 'Sell':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(indicator, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(value),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: _getSignalColor(),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          signal,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
