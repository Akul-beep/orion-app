import 'package:flutter/material.dart';
import '../services/user_progress_service.dart';

class MarketNews extends StatelessWidget {
  const MarketNews({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Market News', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 16),
        _buildNewsCard(context, 'Market Hits All-Time High', 'Reuters • 2h ago', 'https://i.imgur.com/2OD5u2p.png'),
        const SizedBox(height: 16),
        _buildNewsCard(context, 'Inflation Concerns Ease', 'Bloomberg • 4h ago', 'https://i.imgur.com/3ZJ7Q8p.png'),
        const SizedBox(height: 16),
        _buildNewsCard(context, 'Tech Stocks Lead the Way', 'Yahoo Finance • 5h ago', 'https://i.imgur.com/L7X9e5l.png'),
      ],
    );
  }

  Widget _buildNewsCard(BuildContext context, String headline, String source, String imageUrl) {
    return Card(
      color: Colors.white,
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () async {
          // Track interaction
          await UserProgressService().trackWidgetInteraction(
            screenName: 'HomeScreen',
            widgetType: 'news_card',
            actionType: 'tap',
            widgetId: headline,
            interactionData: {'headline': headline, 'source': source},
          );
          
          // Navigate to news detail or open web view
          _showNewsDetail(context, headline, source);
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8.0),
                child: Image.network(imageUrl, width: 80, height: 80, fit: BoxFit.cover),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(headline, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 8),
                    Text(source, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  void _showNewsDetail(BuildContext context, String headline, String source) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(headline),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Source: $source'),
              const SizedBox(height: 16),
              const Text('This is a sample news article. In a real app, this would contain the full article content or link to the actual news source.'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                // In a real app, this would open the full article
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Opening full article...')),
                );
              },
              child: const Text('Read Full Article'),
            ),
          ],
        );
      },
    );
  }
}
