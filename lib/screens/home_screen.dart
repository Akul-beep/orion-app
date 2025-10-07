import 'package:flutter/material.dart';

import '../widgets/top_movers.dart';
import '../widgets/learning_module.dart';
import '../widgets/market_news.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          children: [
            const SizedBox(height: 24),
            _buildHeader(context),
            const SizedBox(height: 32),
            _buildPortfolioCard(context),
            const SizedBox(height: 32),
            const TopMovers(),
            const SizedBox(height: 32),
            const LearningModule(),
            const SizedBox(height: 32),
            const MarketNews(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome back,',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 16),
            ),
            const SizedBox(height: 4),
            Text(
              'Tanya Myroniuk',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ],
        ),
        CircleAvatar(
          radius: 26,
          backgroundColor: Colors.grey[100],
          child: IconButton(
            icon: const Icon(Icons.search, color: Colors.black, size: 26),
            onPressed: () {},
          ),
        ),
      ],
    );
  }

  Widget _buildPortfolioCard(BuildContext context) {
    return Card(
      child: Container(
        padding: const EdgeInsets.all(24.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20.0),
          image: const DecorationImage(
            image: NetworkImage('https://i.imgur.com/4lH2M4n.png'), // World map background
            fit: BoxFit.cover,
            opacity: 0.1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Portfolio Value',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white70),
                ),
                const Icon(Icons.wifi_tethering, color: Colors.white70, size: 24),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '\$12,324',
              style: Theme.of(context).textTheme.displayLarge,
            ),
            const SizedBox(height: 12),
            Text(
              '+123.45 (1.01%) Today',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: const Color(0xFF00D09C)),
            ),
          ],
        ),
      ),
    );
  }
}
