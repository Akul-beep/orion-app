import 'package:flutter/material.dart';

class KeyStatsGrid extends StatelessWidget {
  const KeyStatsGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 2,
        crossAxisSpacing: 15,
        mainAxisSpacing: 15,
        childAspectRatio: 2.5,
        children: const [
          _StatCard(label: 'Market Cap', value: '\$2.1T'),
          _StatCard(label: 'P/E Ratio', value: '28.5'),
          _StatCard(label: 'EPS', value: '\$6.12'),
          _StatCard(label: 'Div. Yield', value: '0.5%'),
          _StatCard(label: 'Beta', value: '1.01'),
          _StatCard(label: 'Volume', value: '60.5M'),
          _StatCard(label: '52-Wk High', value: '\$185.04'),
          _StatCard(label: '52-Wk Low', value: '\$124.35'),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;

  const _StatCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey[200]!)
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 14)),
          const SizedBox(height: 5),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        ],
      ),
    );
  }
}
