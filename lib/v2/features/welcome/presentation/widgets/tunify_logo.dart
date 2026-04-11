import 'package:flutter/material.dart';
import 'package:tunify/v2/core/constants/app_colors.dart';

/// Tunify logo widget with brand green color
/// Displays the iconic circle with sound wave bars
class TunifyLogo extends StatelessWidget {
  final double size;
  final Color color;

  const TunifyLogo({
    super.key,
    this.size = 80,
    this.color = AppColors.brandGreen,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _TunifyLogoPainter(color: color),
      ),
    );
  }
}

class _TunifyLogoPainter extends CustomPainter {
  final Color color;

  _TunifyLogoPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Draw circle background
    final circlePaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius, circlePaint);

    // Draw sound wave arcs (white)
    final wavePaint = Paint()
      ..color = AppColors.nearBlack
      ..style = PaintingStyle.stroke
      ..strokeWidth = radius * 0.12
      ..strokeCap = StrokeCap.round;

    // Three curved lines representing sound waves
    final rect = Rect.fromCenter(center: center, width: radius * 1.6, height: radius * 1.6);
    
    // Outer arc
    canvas.drawArc(
      rect,
      -0.9,
      2.5,
      false,
      wavePaint,
    );

    // Middle arc
    final middleRect = Rect.fromCenter(center: center, width: radius * 1.15, height: radius * 1.15);
    canvas.drawArc(
      middleRect,
      -0.85,
      2.4,
      false,
      wavePaint,
    );

    // Inner arc
    final innerRect = Rect.fromCenter(center: center, width: radius * 0.7, height: radius * 0.7);
    canvas.drawArc(
      innerRect,
      -0.8,
      2.3,
      false,
      wavePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
