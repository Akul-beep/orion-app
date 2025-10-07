import 'package:flutter/material.dart';

class RecentNews extends StatelessWidget {
  const RecentNews({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Recent News', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          _buildNewsItem('Apple stock surges on iPhone 16 launch expectations', 'Reuters', '1h ago'),
          const Divider(),
          _buildNewsItem('Tech market shows signs of volatility amid inflation fears', 'Bloomberg', '3h ago'),
        ],
      ),
    );
  }

  Widget _buildNewsItem(String title, String source, String time) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        children: [
          const Icon(Icons.article, color: Colors.grey, size: 22),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 4),
                Text('$source • $time', style: const TextStyle(color: Colors.grey, fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
