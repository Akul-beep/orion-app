import 'package:flutter/material.dart';
import '../services/user_progress_service.dart';

class StockListScreen extends StatefulWidget {
  const StockListScreen({super.key});

  @override
  State<StockListScreen> createState() => _StockListScreenState();
}

class _StockListScreenState extends State<StockListScreen> {
  @override
  void initState() {
    super.initState();
    // Track screen visit
    WidgetsBinding.instance.addPostFrameCallback((_) {
      UserProgressService().trackScreenVisit(
        screenName: 'StockListScreen',
        screenType: 'main',
        metadata: {'section': 'stock_list'},
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Padding(
          padding: const EdgeInsets.only(left: 8.0),
          child: Text('Stocks', style: Theme.of(context).textTheme.titleLarge),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20.0),
        children: [
          _buildStockRow('AAPL', 'Apple Inc.', '\$173.50', '+1.25%', context, 'assets/logos/apple.png'),
          const Divider(height: 32, thickness: 0.1, color: Colors.grey),
          _buildStockRow('TSLA', 'Tesla, Inc.', '\$181.12', '-0.89%', context, 'assets/logos/tesla.png'),
          const Divider(height: 32, thickness: 0.1, color: Colors.grey),
          _buildStockRow('GOOGL', 'Alphabet Inc.', '\$141.20', '+0.45%', context, 'assets/logos/google.png'),
          const Divider(height: 32, thickness: 0.1, color: Colors.grey),
          _buildStockRow('AMZN', 'Amazon.com, Inc.', '\$135.00', '-1.50%', context, 'assets/logos/amazon.png'),
          const Divider(height: 32, thickness: 0.1, color: Colors.grey),
          _buildStockRow('NVDA', 'NVIDIA Corporation', '\$471.16', '+2.88%', context, 'assets/logos/nvidia.png'),
          const Divider(height: 32, thickness: 0.1, color: Colors.grey),
          _buildStockRow('MSFT', 'Microsoft Corporation', '\$335.94', '+0.91%', context, 'assets/logos/microsoft.png'),
          const Divider(height: 32, thickness: 0.1, color: Colors.grey),
          _buildStockRow('META', 'Meta Platforms, Inc.', '\$316.21', '-0.44%', context, 'assets/logos/meta.png'),
        ],
      ),
    );
  }

  Widget _buildStockRow(String ticker, String companyName, String price, String change, BuildContext context, String logoPath) {
    final isPositive = !change.startsWith('-');
    return Row(
      children: [
        CircleAvatar(
          radius: 22,
          backgroundColor: Colors.grey[800],
          child: const Icon(Icons.business, color: Colors.grey), // Placeholder
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(ticker, style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 2),
              Text(companyName, style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(price, style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 2),
            Text(change, style: TextStyle(color: isPositive ? Theme.of(context).colorScheme.primary : Colors.redAccent, fontWeight: FontWeight.bold)),
          ],
        ),
      ],
    );
  }
}
