import 'package:flutter/material.dart';

class InfoTabs extends StatelessWidget {
  const InfoTabs({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          const TabBar(
            labelColor: Colors.black,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Colors.deepPurple,
            indicatorWeight: 3,
            tabs: [
              Tab(text: 'AI Explain 💡'),
              Tab(text: 'Overview'),
              Tab(text: 'Technical'),
            ],
          ),
          SizedBox(
            height: 280,
            child: TabBarView(
              children: [
                _buildAiExplainTab(),
                _buildOverviewTab(),
                _buildTechnicalTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAiExplainTab() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Apple remains one of the most stable tech giants, demonstrating strong brand loyalty and consistent financial performance.', style: TextStyle(fontSize: 16)),
          SizedBox(height: 20),
          _BulletPoint(icon: '📊', text: 'Strong fundamentals and unmatched global reach.'),
          _BulletPoint(icon: '💰', text: 'Consistent and impressive revenue growth.'),
          _BulletPoint(icon: '⚠️', text: 'High valuation may lead to short-term volatility.'),
          SizedBox(height: 20),
          Row(
            children: [
              Text('Risk Level: ', style: TextStyle(fontWeight: FontWeight.bold)),
              Chip(label: Text('Low', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)), backgroundColor: Colors.green, padding: EdgeInsets.symmetric(horizontal: 8)),
            ],
          ),
          SizedBox(height: 12),
          Text('AI Tip: Diversify across the tech sector to mitigate exposure.', style: TextStyle(fontStyle: FontStyle.italic, color: Colors.deepPurple)),
          Spacer(),
          Center(child: Text('For educational purposes only.', style: TextStyle(color: Colors.grey, fontSize: 12))),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Apple Inc. designs, manufactures, and markets smartphones, personal computers, tablets, wearables, and accessories worldwide. The company also offers a variety of related services, including the App Store, Apple Music, and iCloud.'),
          SizedBox(height: 20),
          _InfoRow(label: 'Industry', value: 'Technology'),
          _InfoRow(label: 'Country', value: 'United States'),
          _InfoRow(label: 'IPO Date', value: 'December 12, 1980'),
          _InfoRow(label: 'Website', value: 'apple.com', isLink: true),
        ],
      ),
    );
  }

  Widget _buildTechnicalTab() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
           _InfoRow(label: 'RSI (14)', value: '65.5 - Neutral'),
           Text('Above 70 is considered overbought, while below 30 is oversold.', style: TextStyle(color: Colors.grey, fontSize: 12)),
           SizedBox(height: 16),
          _InfoRow(label: 'SMA (20)', value: '\$240.41'),
          _InfoRow(label: 'EMA (20)', value: '\$242.94'),
           SizedBox(height: 16),
          _InfoRow(label: 'MACD', value: '2.5'),
          _InfoRow(label: 'Bollinger Bands', value: 'Upper: \$250, Lower: \$230'),
          Spacer(),
          Center(child: Text('Updated 3 mins ago', style: TextStyle(color: Colors.grey, fontSize: 12))),
        ],
      ),
    );
  }
}

class _BulletPoint extends StatelessWidget {
  final String icon; 
  final String text;

  const _BulletPoint({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(icon, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 16))),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isLink;

  const _InfoRow({required this.label, required this.value, this.isLink = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 15)),
          Text(
            value,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: isLink ? Colors.blue : Colors.black,
              decoration: isLink ? TextDecoration.underline : TextDecoration.none,
            ),
          ),
        ],
      ),
    );
  }
}
