import 'package:flutter/material.dart';

class KeyStatsGrid extends StatelessWidget {
  const KeyStatsGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 2.0,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      children: const [
        _StatItem(label: 'Market Cap', value: '3.0T'),
        _StatItem(label: 'Volume', value: '12.3M'),
        _StatItem(label: 'P/E Ratio', value: '29.4'),
        _StatItem(label: 'Div Yield', value: '0.6%'),
        _StatItem(label: 'EPS', value: '\$6.20'),
        _StatItem(label: 'Sector', value: 'Technology'),
      ],
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;

  const _StatItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13), textAlign: TextAlign.center),
          const SizedBox(height: 6),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16), textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
