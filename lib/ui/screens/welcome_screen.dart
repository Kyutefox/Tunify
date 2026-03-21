import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../shared/providers/auth_provider.dart';
import '../../shared/providers/guest_profile_provider.dart';
import '../../system/bridges/database_repository.dart';
import '../../config/app_strings.dart';
import '../components/ui/sheet.dart';
import '../theme/app_colors.dart';
import '../theme/design_tokens.dart';
import '../theme/app_routes.dart';
import 'auth_screen.dart';
import 'guest_profile_setup_screen.dart';

class WelcomeScreen extends ConsumerWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Animated waveform background
          const Positioned.fill(child: _WaveBackground()),

          // Dark gradient overlay so text stays readable
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    AppColors.background.withValues(alpha: 0.55),
                    AppColors.background.withValues(alpha: 0.92),
                    AppColors.background,
                  ],
                  stops: const [0.0, 0.3, 0.6, 1.0],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Spacer(flex: 3),

                  // Logo
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
                  )
                      .animate()
                      .fadeIn(duration: AppDuration.normal)
                      .scale(begin: const Offset(0.7, 0.7), curve: AppCurves.spring),

                  const SizedBox(height: AppSpacing.lg),

                  // App name
                  Text(
                    AppStrings.appName,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 56,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -2.0,
                      height: 1.0,
                    ),
                  )
                      .animate(delay: 80.ms)
                      .fadeIn(duration: AppDuration.normal)
                      .slideY(begin: 0.15, curve: AppCurves.decelerate),

                  const SizedBox(height: AppSpacing.sm),

                  // Tagline
                  const Text(
                    'Your music.\nYour mood.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 20,
                      fontWeight: FontWeight.w400,
                      height: 1.4,
                      letterSpacing: -0.2,
                    ),
                  )
                      .animate(delay: 160.ms)
                      .fadeIn(duration: AppDuration.normal)
                      .slideY(begin: 0.15, curve: AppCurves.decelerate),

                  const Spacer(flex: 2),

                  // Primary CTA
                  _WelcomeButton(
                    label: 'Get started',
                    onTap: () => _showAuthSheet(context, signUp: true),
                    filled: true,
                  )
                      .animate(delay: 260.ms)
                      .fadeIn(duration: AppDuration.normal)
                      .slideY(begin: 0.2, curve: AppCurves.decelerate),

                  const SizedBox(height: AppSpacing.md),

                  // Secondary CTA
                  _WelcomeButton(
                    label: 'Sign in',
                    onTap: () => _showAuthSheet(context, signUp: false),
                    filled: false,
                  )
                      .animate(delay: 310.ms)
                      .fadeIn(duration: AppDuration.normal)
                      .slideY(begin: 0.2, curve: AppCurves.decelerate),

                  const SizedBox(height: AppSpacing.lg),

                  // Guest link
                  GestureDetector(
                    onTap: () async {
                      final existing = await ref
                          .read(databaseBridgeProvider)
                          .getSetting(kGuestUsernameKey);
                      if (!context.mounted) return;
                      if (existing != null && existing.isNotEmpty) {
                        ref.read(guestModeProvider.notifier).enterGuestMode();
                      } else {
                        Navigator.of(context).push(
                          appPageRoute<void>(
                            builder: (_) =>
                                const GuestProfileSetupScreen(isInitial: true),
                          ),
                        );
                      }
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Continue as guest',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.arrow_forward_ios,
                            size: 11,
                            color: AppColors.textSecondary,
                          ),
                        ],
                      ),
                    ),
                  ).animate(delay: 380.ms).fadeIn(duration: AppDuration.normal),

                  const SizedBox(height: AppSpacing.xxl),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAuthSheet(BuildContext context, {required bool signUp}) {
    showRawSheet(
      context,
      child: AuthBottomSheet(initialSignUp: signUp),
    );
  }
}

// ── Animated waveform background ─────────────────────────────────────────────

class _WaveBackground extends StatefulWidget {
  const _WaveBackground();

  @override
  State<_WaveBackground> createState() => _WaveBackgroundState();
}

class _WaveBackgroundState extends State<_WaveBackground>
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
        painter: _WavePainter(_ctrl.value),
      ),
    );
  }
}

class _WavePainter extends CustomPainter {
  _WavePainter(this.t);
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
  bool shouldRepaint(_WavePainter old) => old.t != t;
}

// ── Buttons ───────────────────────────────────────────────────────────────────

class _WelcomeButton extends StatelessWidget {
  const _WelcomeButton({
    required this.label,
    required this.onTap,
    required this.filled,
  });
  final String label;
  final VoidCallback onTap;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 54,
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: filled ? AppColors.primaryGradient : null,
          border: filled
              ? null
              : Border.all(color: AppColors.glassBorder, width: 1),
          borderRadius: BorderRadius.circular(AppRadius.input),
          color: filled ? null : AppColors.glassWhite,
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: filled ? Colors.white : AppColors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.1,
          ),
        ),
      ),
    );
  }
}
