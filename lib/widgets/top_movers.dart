import 'package:flutter/material.dart';

import 'sparkline_chart.dart';

class TopMovers extends StatelessWidget {
  const TopMovers({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Top Movers', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 16),
          TabBar(
            tabs: const [Tab(text: 'Gainers'), Tab(text: 'Losers')],
            labelColor: Theme.of(context).colorScheme.primary,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Theme.of(context).colorScheme.primary,
          ),
          SizedBox(
            height: 200,
            child: TabBarView(
              children: [
                _buildMoversList(true),
                _buildMoversList(false),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static Widget _buildMoversList(bool isGainer) {
    final movers = isGainer
        ? [
            {'icon': Icons.apple, 'ticker': 'AAPL', 'price': '\$175.20', 'change': '+2.5%'},
            {'icon': Icons.business, 'ticker': 'MSFT', 'price': '\$340.80', 'change': '+1.8%'},
            {'icon': Icons.electric_car, 'ticker': 'TSLA', 'price': '\$240.50', 'change': '+1.2%'},
          ]
        : [
            {'icon': Icons.camera_alt, 'ticker': 'SNAP', 'price': '\$12.30', 'change': '-3.1%'},
            {'icon': Icons.local_movies, 'ticker': 'DIS', 'price': '\$85.60', 'change': '-2.4%'},
            {'icon': Icons.shopping_cart, 'ticker': 'AMZN', 'price': '\$135.10', 'change': '-1.9%'},
          ];

    return ListView.builder(
      itemCount: movers.length,
      itemBuilder: (context, index) {
        final mover = movers[index];
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          child: Row(
            children: [
              CircleAvatar(child: Icon(mover['icon'] as IconData), backgroundColor: Colors.grey[200]),
              const SizedBox(width: 12),
              Text(mover['ticker'] as String, style: const TextStyle(fontWeight: FontWeight.bold)),
              const Spacer(),
              SparklineChart(isGainer: isGainer),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(mover['price'] as String, style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text(
                    mover['change'] as String,
                    style: TextStyle(color: isGainer ? const Color(0xFF00D09C) : Colors.red, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
