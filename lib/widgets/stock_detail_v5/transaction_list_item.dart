import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TransactionListItem extends StatelessWidget {
  final String type;
  final String date;
  final String amount;
  final String usdValue;
  final bool isCredit;

  const TransactionListItem({
    super.key,
    required this.type,
    required this.date,
    required this.amount,
    required this.usdValue,
    this.isCredit = false,
  });

  @override
  Widget build(BuildContext context) {
    final Color amountColor = isCredit ? const Color(0xFF00D09C) : Colors.red;
    final IconData iconData = isCredit ? Icons.arrow_downward : Icons.arrow_upward;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        children: [
          Icon(iconData, color: amountColor, size: 28),
          const SizedBox(width: 15),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(type, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(date, style: const TextStyle(color: Colors.grey, fontSize: 14)),
            ],
          ),
          const Spacer(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                amount,
                style: GoogleFonts.roboto(fontWeight: FontWeight.bold, fontSize: 16, color: amountColor),
              ),
              const SizedBox(height: 4),
              Text(
                usdValue,
                style: const TextStyle(color: Colors.grey, fontSize: 14),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
