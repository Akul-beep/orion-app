import 'package:flutter/material.dart';

class StockListItem extends StatelessWidget {
  final IconData icon;
  final String ticker;
  final String company;
  final String price;
  final String change;
  final bool isGainer;

  const StockListItem({
    super.key,
    required this.icon,
    required this.ticker,
    required this.company,
    required this.price,
    required this.change,
    required this.isGainer,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: Colors.grey[100],
            child: Icon(icon, size: 28, color: Colors.black),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(ticker, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 4),
                Text(company, style: const TextStyle(color: Colors.grey, fontSize: 14)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(price, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 4),
              Text(
                change,
                style: TextStyle(
                  color: isGainer ? const Color(0xFF00D09C) : Colors.red,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
