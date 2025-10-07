
import 'package:flutter/material.dart';

class NewsCard extends StatelessWidget {
  final String headline;
  final String source;
  final String time;

  const NewsCard({super.key, required this.headline, required this.source, required this.time});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(headline, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(source, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                const SizedBox(width: 16),
                Text(time, style: const TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
