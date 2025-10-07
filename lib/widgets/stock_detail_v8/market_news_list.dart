import 'package:flutter/material.dart';

class MarketNewsList extends StatelessWidget {
  const MarketNewsList({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: 3, // Number of news articles
      itemBuilder: (context, index) {
        final articles = [
          {
            'headline': 'Google Announces New AI Model',
            'source': 'Reuters',
            'date': 'May 14, 2024',
            'imageUrl': 'https://via.placeholder.com/150',
          },
          {
            'headline': 'Stock Market Hits Record Highs',
            'source': 'Bloomberg',
            'date': 'May 13, 2024',
            'imageUrl': 'https://invalid-url.com/image.png', // Intentionally invalid URL for testing
          },
          {
            'headline': 'Tech Stocks Rally on Positive Earnings',
            'source': 'Wall Street Journal',
            'date': 'May 12, 2024',
            'imageUrl': 'https://via.placeholder.com/150',
          },
        ];

        final article = articles[index];

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    article['imageUrl']!,
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 80,
                        height: 80,
                        color: Colors.grey[200],
                        child: const Icon(Icons.broken_image, color: Colors.grey, size: 40),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        article['headline']!,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${article['source']} - ${article['date']}',
                        style: TextStyle(color: Colors.grey[700], fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
