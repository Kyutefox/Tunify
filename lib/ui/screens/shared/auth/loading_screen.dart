import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:tunify/core/constants/app_strings.dart';
import 'package:tunify/ui/widgets/common/logo_loading_indicator.dart';
import 'package:tunify/ui/theme/app_colors.dart';
import 'package:tunify/ui/theme/design_tokens.dart';
import 'package:tunify/ui/theme/app_colors_scheme.dart';

/// Loading screen shown after login. Creative design: gradient background,
/// breathing logo, green progress ring, and animated waveform background.
class LoadingScreen extends StatefulWidget {
  const LoadingScreen({super.key});

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _waveController;

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();
  }

  @override
  void dispose() {
    _waveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: AppColors.backgroundGradient,
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Animated waveform background — same as welcome screen
            AnimatedBuilder(
              animation: _waveController,
              builder: (_, __) => CustomPaint(
                painter: _LoadingWavePainter(_waveController.value),
              ),
            ),
            // Dark gradient overlay so content stays readable
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      AppColorsScheme.of(context).background.withValues(alpha: 0.45),
                      AppColorsScheme.of(context).background.withValues(alpha: 0.85),
                      AppColorsScheme.of(context).background,
                    ],
                    stops: const [0.0, 0.3, 0.6, 1.0],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const LogoLoadingIndicator(),
                  const SizedBox(height: AppSpacing.xxl),
                  Text(
                    AppStrings.appName,
                    style: TextStyle(
                      color: AppColorsScheme.of(context).textPrimary,
                      fontSize: AppFontSize.display3,
                      fontWeight: FontWeight.w800,
                      letterSpacing: AppLetterSpacing.display,
                      height: AppLineHeight.tight,
                      shadows: [
                        Shadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Loading your music…',
                    style: TextStyle(
                      color: AppColorsScheme.of(context).textSecondary.withValues(alpha: 0.95),
                      fontSize: AppFontSize.lg,
                      fontWeight: FontWeight.w500,
                      letterSpacing: AppLetterSpacing.normal,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Same wave painter as the welcome screen for visual consistency.
class _LoadingWavePainter extends CustomPainter {
  _LoadingWavePainter(this.t);
  final double t;

  static const _barCount = 28;

  @override
  void paint(Canvas canvas, Size size) {
    final barWidth = size.width / (_barCount * 2.0);
    final maxHeight = size.height * 0.38;
    final baseY = size.height * 0.52;

    for (int i = 0; i < _barCount; i++) {
      final phase = (i / _barCount) * math.pi * 2;
      final wave1 = math.sin(t * math.pi * 2 + phase) * 0.5 + 0.5;
      final wave2 = math.sin(t * math.pi * 2 * 1.3 + phase * 1.7) * 0.3 + 0.3;
      final height = (wave1 * 0.65 + wave2 * 0.35) * maxHeight + 8;

      final x = (i * 2 + 0.5) * barWidth + barWidth * 0.5;
      final opacity = 0.12 + wave1 * 0.22;

      final paint = Paint()
        ..color = AppColors.primary.withValues(alpha: opacity)
        ..strokeWidth = barWidth * 0.7
        ..strokeCap = StrokeCap.round;

      canvas.drawLine(
        Offset(x, baseY - height / 2),
        Offset(x, baseY + height / 2),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_LoadingWavePainter old) => old.t != t;
}
