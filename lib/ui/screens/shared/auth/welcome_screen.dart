import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:tunify/core/constants/app_strings.dart';
import 'package:tunify/ui/theme/app_colors.dart';
import 'package:tunify/ui/theme/design_tokens.dart';
import 'package:tunify/ui/theme/app_routes.dart';
import 'package:tunify/ui/widgets/common/button.dart';
import 'package:tunify/ui/screens/shared/auth/auth_choice_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Page 1: Welcome / Get Started
// ─────────────────────────────────────────────────────────────────────────────

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _WelcomeBody();
  }
}

class _WelcomeBody extends StatefulWidget {
  const _WelcomeBody();

  @override
  State<_WelcomeBody> createState() => _WelcomeBodyState();
}

class _WelcomeBodyState extends State<_WelcomeBody>
    with TickerProviderStateMixin {
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: Duration(
        milliseconds: AppDuration.slow.inMilliseconds * 5,
      ),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _onGetStarted() {
    Navigator.of(context).push(
      appPageRoute<void>(builder: (_) => const AuthChoiceScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── Layered ambient background ──────────────────────────────────
          _AmbientBackground(
            pulseController: _pulseController,
          ),

          // ── Bottom dark vignette ────────────────────────────────────────
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    AppColors.glassBlack.withValues(alpha: UIOpacity.medium),
                    AppColors.background.withValues(alpha: UIOpacity.high),
                    AppColors.background,
                  ],
                  stops: const [0.0, 0.25, 0.60, 1.0],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),

          // ── Content ─────────────────────────────────────────────────────
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Spacer(flex: 5),

                  // Logo mark
                  _LogoMark(pulseController: _pulseController)
                      .animate()
                      .fadeIn(
                        duration: AppDuration.slow,
                        delay: AppDuration.fast,
                      )
                      .scale(
                        begin: const Offset(0.85, 0.85),
                        curve: AppCurves.spring,
                        duration: AppDuration.page,
                        delay: AppDuration.fast,
                      ),

                  const SizedBox(height: AppSpacing.xxl),

                  // App name
                  Text(
                    AppStrings.appName,
                    style: AppTextStyle.hero,
                  )
                      .animate(delay: AppDuration.normal)
                      .fadeIn(duration: AppDuration.slow)
                      .slideY(begin: 0.15, curve: AppCurves.decelerate),

                  const SizedBox(height: AppSpacing.md),

                  // Tagline
                  DefaultTextStyle(
                    style: AppTextStyle.bodyLg.copyWith(
                      color: AppColors.textSecondary.withValues(alpha: UIOpacity.high),
                      letterSpacing: 0.1,
                    ),
                    child: Row(
                      children: [
                        const Expanded(
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: Text('Your Music'),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                          ),
                          child: Icon(
                            Icons.circle,
                            size: AppSpacing.sm,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const Expanded(
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text('Your Taste'),
                          ),
                        ),
                      ],
                    ),
                  )
                      .animate(delay: AppDuration.medium)
                      .fadeIn(duration: AppDuration.slow)
                      .slideY(begin: 0.12, curve: AppCurves.decelerate),

                  const Spacer(flex: 4),

                  // CTA button
                  AppButton(
                    label: 'Get Started',
                    onPressed: _onGetStarted,
                    useGradient: true,
                    fullWidth: true,
                    height: UISize.buttonHeightLg,
                  )
                      .animate(delay: AppDuration.slow)
                      .fadeIn(duration: AppDuration.page)
                      .slideY(begin: 0.2, curve: AppCurves.decelerate),

                  const SizedBox(height: AppSpacing.xl),

                  // Fine-print
                  Text(
                    'By continuing you agree to our Terms & Privacy Policy.',
                    textAlign: TextAlign.center,
                    style: AppTextStyle.micro.copyWith(
                      color: AppColors.textMuted.withValues(alpha: UIOpacity.emphasis),
                      height: AppLineHeight.relaxed,
                    ),
                  )
                      .animate(delay: AppDuration.page)
                      .fadeIn(duration: AppDuration.page),

                  const SizedBox(height: AppSpacing.xxl),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Logo mark with animated ring ────────────────────────────────────────────

class _LogoMark extends StatelessWidget {
  const _LogoMark({required this.pulseController});
  final AnimationController pulseController;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: pulseController,
      builder: (_, __) {
        final scale = 0.98 + (pulseController.value * 0.06);
        return Transform.scale(
          scale: scale,
          child: SizedBox(
            width: UISize.appLogoMd,
            height: UISize.appLogoMd,
            child: ClipOval(
              child: SvgPicture.asset(
                AppStrings.logoAsset,
                width: UISize.appLogoMd,
                height: UISize.appLogoMd,
                fit: BoxFit.cover,
              ),
            ),
          ),
        );
      },
    );
  }
}

// ─── Ambient animated background ─────────────────────────────────────────────

class _AmbientBackground extends StatelessWidget {
  const _AmbientBackground({
    required this.pulseController,
  });
  final AnimationController pulseController;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: pulseController,
      builder: (_, __) {
        return CustomPaint(
          size: Size.infinite,
          painter: _AmbientPainter(pulse: pulseController.value),
        );
      },
    );
  }
}

class _AmbientPainter extends CustomPainter {
  _AmbientPainter({required this.pulse});
  final double pulse;

  @override
  void paint(Canvas canvas, Size size) {
    // Dark base
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = AppColors.background,
    );

    // Centered ambient glow so motion feels anchored behind the logo.
    final center = Offset(size.width * 0.5, size.height * 0.40);
    final coreRadius = size.width * (0.34 + pulse * 0.05);
    final outerRadius = size.width * (0.58 + pulse * 0.03);

    final coreGlow = Paint()
      ..shader = RadialGradient(
        colors: [
          AppColors.primary.withValues(alpha: 0.24 + pulse * 0.08),
          Colors.transparent,
        ],
      ).createShader(
        Rect.fromCircle(center: center, radius: coreRadius),
      );
    canvas.drawCircle(center, coreRadius, coreGlow);

    final outerGlow = Paint()
      ..shader = RadialGradient(
        colors: [
          AppColors.primaryDark.withValues(alpha: 0.16 + pulse * 0.05),
          Colors.transparent,
        ],
      ).createShader(
        Rect.fromCircle(center: center, radius: outerRadius),
      );
    canvas.drawCircle(center, outerRadius, outerGlow);
  }

  @override
  bool shouldRepaint(_AmbientPainter old) => old.pulse != pulse;
}
