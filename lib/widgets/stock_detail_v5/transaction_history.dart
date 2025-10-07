import 'package:flutter/material.dart';
import './transaction_list_item.dart';

class TransactionHistory extends StatelessWidget {
  const TransactionHistory({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            'Recent Transactions',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 15),
          TransactionListItem(
            type: 'Bought Bitcoin',
            date: 'Jun 23, 2024',
            amount: '+0.001 BTC',
            usdValue: '\$47.60',
            isCredit: true,
          ),
          Divider(),
          TransactionListItem(
            type: 'Sold Bitcoin',
            date: 'Jun 21, 2024',
            amount: '-0.002 BTC',
            usdValue: '\$95.20',
          ),
          Divider(),
          TransactionListItem(
            type: 'Bought Bitcoin',
            date: 'Jun 20, 2024',
            amount: '+0.0005 BTC',
            usdValue: '\$23.80',
            isCredit: true,
          ),
        ],
      ),
    );
  }
}
