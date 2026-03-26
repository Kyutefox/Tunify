import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:tunify/core/constants/app_strings.dart';
import 'package:tunify/ui/theme/app_colors.dart';

/// Reusable logo + circular loading indicator: radial glow, progress ring, and
/// app logo, all centered. Use for loading states (e.g. splash, post-login).
class LogoLoadingIndicator extends StatefulWidget {
  const LogoLoadingIndicator({
    super.key,
    this.size = 88,
    this.showGlow = true,
  });

  /// Logo (and ring) size. Ring is slightly larger than logo; glow scales with size.
  final double size;

  /// Whether to show the soft radial glow behind the logo.
  final bool showGlow;

  @override
  State<LogoLoadingIndicator> createState() => _LogoLoadingIndicatorState();
}

class _LogoLoadingIndicatorState extends State<LogoLoadingIndicator>
    with TickerProviderStateMixin {
  late AnimationController _breathController;
  late AnimationController _progressController;

  @override
  void initState() {
    super.initState();
    _breathController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);

    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _breathController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final logoSize = widget.size;
    final ringSize = logoSize * (112 / 88);
    final glowMaxSize = logoSize * (180 / 88);

    return Stack(
      alignment: Alignment.center,
      children: [
        if (widget.showGlow)
          AnimatedBuilder(
            animation: _breathController,
            builder: (context, child) {
              final scale = 0.85 + 0.25 * _breathController.value;
              return Container(
                width: glowMaxSize * scale,
                height: glowMaxSize * scale,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.18),
                      blurRadius: 80,
                      spreadRadius: 20,
                    ),
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.08),
                      blurRadius: 120,
                      spreadRadius: 40,
                    ),
                  ],
                ),
              );
            },
          ),
        SizedBox(
          width: ringSize,
          height: ringSize,
          child: AnimatedBuilder(
            animation: _progressController,
            builder: (context, child) {
              return CustomPaint(
                painter: _ProgressRingPainter(
                  progress: _progressController.value,
                  gradient: AppColors.primaryGradient,
                  strokeWidth: 3,
                  backgroundColor: AppColors.surfaceLight,
                ),
              );
            },
          ),
        ),
        AnimatedBuilder(
          animation: _breathController,
          builder: (context, child) {
            final scale = 0.96 + 0.06 * _breathController.value;
            return Transform.scale(
              scale: scale,
              child: Container(
                width: logoSize,
                height: logoSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.4),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: SvgPicture.asset(
                    AppStrings.logoAsset,
                    width: logoSize,
                    height: logoSize,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

/// Paints a circular ring with a gradient sweep that rotates (indeterminate).
class _ProgressRingPainter extends CustomPainter {
  _ProgressRingPainter({
    required this.progress,
    required this.gradient,
    required this.strokeWidth,
    required this.backgroundColor,
  });

  final double progress;
  final Gradient gradient;
  final double strokeWidth;
  final Color backgroundColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - strokeWidth / 2;

    final bgPaint = Paint()
      ..color = backgroundColor.withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, bgPaint);

    final rect = Rect.fromCircle(center: center, radius: radius);
    final sweepAngle = math.pi * 0.55;
    final startAngle = -math.pi / 2 + (progress * 2 * math.pi);
    final arcPaint = Paint()
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, startAngle, sweepAngle, false, arcPaint);
  }

  @override
  bool shouldRepaint(covariant _ProgressRingPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
