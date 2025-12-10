import 'package:flutter/material.dart';

class SparklineChart extends StatelessWidget {
  final bool isGainer;

  const SparklineChart({super.key, required this.isGainer});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(50, 20),
      painter: _SparklinePainter(isGainer: isGainer),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  final bool isGainer;

  _SparklinePainter({required this.isGainer});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = isGainer ? const Color(0xFF00D09C) : Colors.red
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final path = Path();
    if (isGainer) {
      path.moveTo(0, size.height);
      path.lineTo(size.width * 0.3, size.height * 0.4);
      path.lineTo(size.width * 0.7, size.height * 0.6);
      path.lineTo(size.width, 0);
    } else {
      path.moveTo(0, 0);
      path.lineTo(size.width * 0.3, size.height * 0.6);
      path.lineTo(size.width * 0.7, size.height * 0.4);
      path.lineTo(size.width, size.height);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
