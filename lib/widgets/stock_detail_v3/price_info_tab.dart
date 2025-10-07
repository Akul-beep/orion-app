import 'package:flutter/material.dart';

class PriceInfoTab extends StatelessWidget {
  const PriceInfoTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(20.0),
      child: Column(
        children: [
          _InfoRow(label: 'Open', value: '\$250.75'),
          _InfoRow(label: 'High', value: '\$255.20'),
          _InfoRow(label: 'Low', value: '\$249.80'),
          _InfoRow(label: 'Previous Close', value: '\$250.50'),
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
