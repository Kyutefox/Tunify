import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:tunify/core/constants/app_strings.dart';
import 'package:tunify/ui/theme/app_colors.dart';
import 'package:tunify/ui/theme/design_tokens.dart';
import 'package:tunify/ui/theme/app_colors_scheme.dart';

class AuthBranding extends StatelessWidget {
  const AuthBranding({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.5),
                blurRadius: 24,
                spreadRadius: 2,
              ),
            ],
          ),
          child: ClipOval(
            child: SvgPicture.asset(
              AppStrings.logoAsset,
              width: 56,
              height: 56,
            ),
          ),
        ).animate().fadeIn(duration: AppDuration.normal).scale(
              begin: const Offset(0.7, 0.7),
              curve: AppCurves.spring,
            ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          AppStrings.appName,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColorsScheme.of(context).textPrimary,
            fontSize: AppFontSize.hero,
            fontWeight: FontWeight.w800,
            letterSpacing: AppLetterSpacing.display,
            height: AppLineHeight.tight,
          ),
        )
            .animate(delay: 80.ms)
            .fadeIn(duration: AppDuration.normal)
            .slideY(begin: 0.15, curve: AppCurves.decelerate),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Your music.\nYour mood.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColorsScheme.of(context).textSecondary,
            fontSize: AppFontSize.h3,
            fontWeight: FontWeight.w400,
            height: AppLineHeight.relaxed,
            letterSpacing: AppLetterSpacing.heading,
          ),
        )
            .animate(delay: 160.ms)
            .fadeIn(duration: AppDuration.normal)
            .slideY(begin: 0.15, curve: AppCurves.decelerate),
      ],
    );
  }
}

class DesktopAuthLayout extends StatelessWidget {
  const DesktopAuthLayout({
    super.key,
    required this.rightContent,
  });

  final Widget rightContent;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColorsScheme.of(context).background,
      body: Row(
        children: [
          const Expanded(
            child: _DesktopLeftPanel(),
          ),
          Expanded(
            child: _DesktopRightPanel(child: rightContent),
          ),
        ],
      ),
    );
  }
}

class _DesktopLeftPanel extends StatelessWidget {
  const _DesktopLeftPanel();

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const WaveBackground(),
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  AppColorsScheme.of(context).background.withValues(alpha: 0.2),
                  AppColorsScheme.of(context).background.withValues(alpha: 0.5),
                ],
                stops: const [0.0, 0.5, 1.0],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ),
        Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
            child: const AuthBranding(),
          ),
        ),
      ],
    );
  }
}

class _DesktopRightPanel extends StatelessWidget {
  const _DesktopRightPanel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColorsScheme.of(context).background,
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl * 2),
          child: child,
        ),
      ),
    );
  }
}

class WaveBackground extends StatefulWidget {
  const WaveBackground({super.key});

  @override
  State<WaveBackground> createState() => _WaveBackgroundState();
}

class _WaveBackgroundState extends State<WaveBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => CustomPaint(
        painter: WavePainter(_ctrl.value),
      ),
    );
  }
}

class WavePainter extends CustomPainter {
  WavePainter(this.t);
  final double t;

  static const _barCount = 28;
  static const _primaryColor = AppColors.primary;

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
        ..color = _primaryColor.withValues(alpha: opacity)
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
  bool shouldRepaint(WavePainter old) => old.t != t;
}
