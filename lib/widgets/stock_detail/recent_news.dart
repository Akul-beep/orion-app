import 'package:flutter/material.dart';

class RecentNews extends StatelessWidget {
  const RecentNews({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Headlines 📰',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        _buildNewsItem('Apple stock surges on iPhone 16 launch expectations', 'Reuters', '1h ago'),
        const Divider(),
        _buildNewsItem('Tech market shows signs of volatility amid inflation fears', 'Bloomberg', '3h ago'),
         const Divider(),
        _buildNewsItem('Analysts remain bullish on Apple despite supply chain concerns', 'CNBC', '5h ago'),
      ],
    );
  }

  Widget _buildNewsItem(String title, String source, String time) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          Text('$source • $time', style: const TextStyle(color: Colors.grey, fontSize: 14)),
        ],
      ),
    );
  }
}
