import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class StockPriceHeader extends StatelessWidget {
  final String symbol;
  
  const StockPriceHeader({
    super.key,
    required this.symbol,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$symbol price',
            style: const TextStyle(color: Colors.grey, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                '\$253.06', // This would be dynamic in a real app
                style: GoogleFonts.roboto(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '-1.36%', // This would be dynamic in a real app
                style: GoogleFonts.roboto(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.red, // Red for negative change
                ),
              ),
              const Spacer(),
              const Icon(Icons.star_outline, color: Colors.grey, size: 28),
            ],
          ),
        ],
      ),
    );
  }
}
