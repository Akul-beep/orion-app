import 'package:flutter/material.dart';

class IndicatorsTab extends StatelessWidget {
  const IndicatorsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(20.0),
      child: Column(
        children: [
          _InfoRow(label: 'RSI (14)', value: '58.2', sentiment: 'Neutral'),
          _InfoRow(label: 'MACD (12, 26, 9)', value: '-2.3', sentiment: 'Sell'),
          _InfoRow(label: 'Bollinger Bands (20, 2)', value: 'Expanded', sentiment: 'Volatile'),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final String sentiment;

  const _InfoRow({required this.label, required this.value, required this.sentiment});

  Color _getSentimentColor() {
    switch (sentiment) {
      case 'Neutral':
        return Colors.orange;
      case 'Sell':
        return Colors.red;
      case 'Volatile':
        return Colors.blue;
      default:
        return Colors.black;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 16, color: Colors.grey)),
          Row(
            children: [
              Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(width: 10),
              Text(sentiment, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _getSentimentColor())),
            ],
          ),
        ],
      ),
    );
  }
}
