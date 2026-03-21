import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:tunify/config/app_strings.dart';
import 'package:tunify/ui/components/ui/widgets/logo_loading_indicator.dart';
import 'package:tunify/ui/theme/app_colors.dart';
import 'package:tunify/ui/theme/design_tokens.dart';

/// Loading screen shown after login. Creative design: gradient background,
/// breathing logo, green progress ring, and subtle equalizer.
class LoadingScreen extends StatefulWidget {
  const LoadingScreen({super.key});

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _barsController;

  @override
  void initState() {
    super.initState();
    _barsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _barsController.dispose();
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
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const LogoLoadingIndicator(),
                  const SizedBox(height: 32),
                  // App name
                  Text(
                    AppStrings.appName,
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                      height: 1.1,
                      shadows: [
                        Shadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Loading your music…',
                    style: TextStyle(
                      color: AppColors.textSecondary.withValues(alpha: 0.95),
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(height: 40),
                  // Subtle equalizer bars
                  _EqualizerBars(animation: _barsController),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Animated equalizer-style bars.
class _EqualizerBars extends StatelessWidget {
  const _EqualizerBars({required this.animation});

  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    const barCount = 5;
    const barWidth = 4.0;
    const barSpacing = 6.0;
    const maxHeight = 20.0;

    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(barCount, (i) {
        final phase = i / barCount;
        return AnimatedBuilder(
          animation: animation,
          builder: (context, child) {
            // Staggered heights for wave effect (up then down)
            final t = (animation.value + phase) % 1.0;
            final wave = t < 0.5
                ? _easeInOutCubic(t * 2)
                : _easeInOutCubic((1 - t) * 2);
            final height = maxHeight * (0.3 + 0.7 * wave);
            return Container(
              width: barWidth,
              height: height.clamp(4.0, maxHeight),
              margin: EdgeInsets.only(
                left: i == 0 ? 0 : barSpacing / 2,
                right: i == barCount - 1 ? 0 : barSpacing / 2,
              ),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(
                  alpha: 0.5 + 0.5 * (height / maxHeight),
                ),
                borderRadius: BorderRadius.circular(AppRadius.xs),
              ),
            );
          },
        );
      }),
    );
  }

  static double _easeInOutCubic(double t) {
    if (t < 0.5) return 4 * t * t * t;
    return 1 - math.pow(-2 * t + 2, 3) / 2;
  }
}
