import 'package:flutter/material.dart';

class InfoTabs extends StatelessWidget {
  const InfoTabs({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          const TabBar(
            labelColor: Colors.black,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Colors.deepPurple,
            tabs: [
              Tab(text: 'AI Summary'),
              Tab(text: 'Key Statistics'),
            ],
          ),
          SizedBox(
            height: 300,
            child: TabBarView(
              children: [
                _buildAiSummaryTab(),
                _buildKeyStatisticsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAiSummaryTab() {
    return const Padding(
      padding: EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Based on our analysis, Apple Inc. shows strong fundamentals and consistent growth, making it a stable long-term investment.',
            style: TextStyle(fontSize: 16, height: 1.5),
          ),
          SizedBox(height: 20),
          Row(
            children: [
              Chip(label: Text('Low Risk'), backgroundColor: Color(0xFFE0F2F1)),
              SizedBox(width: 10),
              Chip(label: Text('Strong Buy'), backgroundColor: Color(0xFFE3F2FD)),
            ],
          ),
          SizedBox(height: 10),
          Text('For educational purposes only.', style: TextStyle(color: Colors.grey, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildKeyStatisticsTab() {
    return const Padding(
      padding: EdgeInsets.all(20.0),
      child: Column(
        children: [
          _StatRow(icon: Icons.business_center, label: 'Market Cap', value: '3.0T'),
          _StatRow(icon: Icons.show_chart, label: 'Volume', value: '12.3M'),
          _StatRow(icon: Icons.pie_chart, label: 'P/E Ratio', value: '29.4'),
          _StatRow(icon: Icons.attach_money, label: 'Dividend Yield', value: '0.6%'),
        ],
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _StatRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.deepPurple, size: 24),
          const SizedBox(width: 16),
          Text(label, style: const TextStyle(fontSize: 16)),
          const Spacer(),
          Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
