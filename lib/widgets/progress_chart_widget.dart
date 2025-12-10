import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/gamification_service.dart';

class ProgressChartWidget extends StatelessWidget {
  final String title;
  final List<int> data;
  final Color color;
  final String unit;

  const ProgressChartWidget({
    Key? key,
    required this.title,
    required this.data,
    required this.color,
    this.unit = '',
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Center(
          child: Text(
            'No data available',
            style: GoogleFonts.poppins(
              color: const Color(0xFF6B7280),
              fontSize: 14,
            ),
          ),
        ),
      );
    }

    final maxValue = data.reduce((a, b) => a > b ? a : b);
    final minValue = data.reduce((a, b) => a < b ? a : b);
    final range = maxValue - minValue;
    final normalizedData = range > 0
        ? data.map((v) => (v - minValue) / range).toList()
        : data.map((_) => 0.5).toList();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 120,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: normalizedData.asMap().entries.map((entry) {
                final index = entry.key;
                final value = entry.value;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Container(
                          height: value * 100,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                color,
                                color.withOpacity(0.6),
                              ],
                            ),
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(4),
                              topRight: Radius.circular(4),
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${data[index]}$unit',
                          style: GoogleFonts.poppins(
                            fontSize: 9,
                            color: const Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class XPProgressWidget extends StatelessWidget {
  const XPProgressWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<GamificationService>(
      builder: (context, gamification, child) {
        // Get last 7 days of XP
        final dailyXP = gamification.dailyXP;
        final now = DateTime.now();
        final last7Days = List.generate(7, (i) {
          final date = now.subtract(Duration(days: 6 - i));
          final dateKey = date.toIso8601String().split('T')[0];
          return dailyXP[dateKey] ?? 0;
        });

        return ProgressChartWidget(
          title: 'XP Progress (Last 7 Days)',
          data: last7Days,
          color: const Color(0xFF3B82F6),
          unit: '',
        );
      },
    );
  }
}






