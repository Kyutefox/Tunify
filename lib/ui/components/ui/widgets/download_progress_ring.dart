import 'package:flutter/material.dart';

import '../../../../ui/theme/app_colors.dart';

class DownloadProgressRingPainter extends CustomPainter {
  DownloadProgressRingPainter({
    required this.progress,
    required this.rotation,
    this.trackColor = AppColors.textMuted,
    this.progressColor = AppColors.accentGreen,
    this.strokeWidth = 2.0,
  });

  final double? progress;
  final double rotation;
  final Color trackColor;
  final Color progressColor;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - strokeWidth / 2;

    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, trackPaint);

    final progressPaint = Paint()
      ..color = progressColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    if (progress != null && progress! > 0) {
      const startAngle = -3.14159265359 / 2;
      final sweepAngle = 2 * 3.14159265359 * progress!.clamp(0.0, 1.0);
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
        progressPaint,
      );
    } else {
      const sweepAngle = 3.14159265359 * 0.75;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        rotation,
        sweepAngle,
        false,
        progressPaint,
      );
    }
  }

  @override
  bool shouldRepaint(DownloadProgressRingPainter old) =>
      old.progress != progress ||
      old.rotation != rotation ||
      old.trackColor != trackColor ||
      old.progressColor != progressColor ||
      old.strokeWidth != strokeWidth;
}
