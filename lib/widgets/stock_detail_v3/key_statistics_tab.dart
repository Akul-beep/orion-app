import 'package:flutter/material.dart';

class KeyStatisticsTab extends StatelessWidget {
  const KeyStatisticsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(20.0),
      child: Column(
        children: [
          _InfoRow(label: 'Market Cap', value: '3.0T'),
          _InfoRow(label: 'P/E Ratio', value: '29.4'),
          _InfoRow(label: 'Volume', value: '12.3M'),
          _InfoRow(label: 'Dividend Yield', value: '0.6%'),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 16, color: Colors.grey)),
          Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
