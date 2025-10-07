import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class StockDetailHeader extends StatelessWidget {
  const StockDetailHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 22),
            onPressed: () => Navigator.of(context).pop(),
          ),
          Column(
            children: [
              Text('Apple Inc.', style: GoogleFonts.roboto(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 20)),
              Text('AAPL', style: GoogleFonts.openSans(color: Colors.grey, fontSize: 16)),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.star_outline, color: Colors.black, size: 28),
            onPressed: () {},
          ),
        ],
      ),
    );
  }
}
