import 'package:flutter/material.dart';

class TradeActionBar extends StatelessWidget {
  const TradeActionBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton.extended(
            onPressed: () {},
            label: const Text('Trade'),
            icon: const Icon(Icons.swap_horiz),
            backgroundColor: Colors.deepPurple,
          ),
        ],
      ),
    );
  }
}
