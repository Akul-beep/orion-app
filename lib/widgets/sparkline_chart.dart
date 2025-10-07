import 'package:flutter/material.dart';

class SparklineChart extends StatelessWidget {
  final bool isGainer;

  const SparklineChart({super.key, required this.isGainer});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 50,
      height: 20,
      decoration: BoxDecoration(
        color: isGainer ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Center(
        child: Icon(
          isGainer ? Icons.trending_up : Icons.trending_down,
          color: isGainer ? Colors.green : Colors.red,
          size: 16,
        ),
      ),
    );
  }
}

