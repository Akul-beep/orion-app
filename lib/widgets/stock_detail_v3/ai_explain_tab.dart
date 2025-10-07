import 'package:flutter/material.dart';

class AiExplainTab extends StatelessWidget {
  const AiExplainTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'AI Analysis: Apple Inc.',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 15),
          Text(
            'Based on current market trends and technical indicators, our AI suggests a neutral short-term outlook. Long-term fundamentals remain strong due to consistent revenue growth and product innovation.',
            style: TextStyle(fontSize: 16, height: 1.5),
          ),
          SizedBox(height: 20),
          Row(
            children: [
              Chip(label: Text('Low Risk'), backgroundColor: Color(0xFFE0F2F1)),
              SizedBox(width: 10),
              Chip(label: Text('Neutral Stance'), backgroundColor: Color(0xFFFFF9C4)),
            ],
          ),
          SizedBox(height: 10),
          Text(
            'This is not financial advice. For educational purposes only.',
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
