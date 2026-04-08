import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:tunify/core/constants/app_icons.dart';
import 'package:tunify/core/constants/app_strings.dart';
import 'package:tunify/features/auth/auth_provider.dart';
import 'package:tunify/features/settings/guest_profile_provider.dart';
import 'package:tunify/data/repositories/database_repository.dart';
import 'package:tunify/ui/widgets/common/sheet.dart';
import 'package:tunify/ui/theme/app_colors.dart';
import 'package:tunify/ui/theme/design_tokens.dart';
import 'package:tunify/ui/theme/app_routes.dart';
import 'package:tunify/ui/screens/mobile/auth/auth_screen.dart' as mobile_auth;
import 'guest_profile_setup_screen.dart';
import 'package:tunify/ui/theme/app_colors_scheme.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return _MobileWelcomeScreen(
      onShowAuth: (signUp) {
        showRawSheet(
          context,
          child: mobile_auth.MobileAuthScreen(initialSignUp: signUp),
        );
      },
    );
  }
}

class _MobileWelcomeScreen extends StatelessWidget {
  const _MobileWelcomeScreen({
    required this.onShowAuth,
  });

  final void Function(bool signUp) onShowAuth;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColorsScheme.of(context).background,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const Positioned.fill(child: WaveBackground()),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    AppColorsScheme.of(context)
                        .background
                        .withValues(alpha: 0.55),
                    AppColorsScheme.of(context)
                        .background
                        .withValues(alpha: 0.92),
                    AppColorsScheme.of(context).background,
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
                  const AuthBranding(),
                  const Spacer(flex: 2),
                  _MobileButton(
                    label: 'Get started',
                    onTap: () => onShowAuth(true),
                    filled: true,
                  )
                      .animate(delay: 100.ms)
                      .fadeIn(duration: AppDuration.normal)
                      .slideY(begin: 0.2, curve: AppCurves.decelerate),
                  const SizedBox(height: AppSpacing.md),
                  _MobileButton(
                    label: 'Sign in',
                    onTap: () => onShowAuth(false),
                    filled: false,
                  )
                      .animate(delay: 150.ms)
                      .fadeIn(duration: AppDuration.normal)
                      .slideY(begin: 0.2, curve: AppCurves.decelerate),
                  const SizedBox(height: AppSpacing.lg),
                  const _MobileGuestLink()
                      .animate(delay: 200.ms)
                      .fadeIn(duration: AppDuration.normal),
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

class _MobileButton extends StatelessWidget {
  const _MobileButton({
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
              : Border.all(
                  color: AppColorsScheme.of(context).surfaceHighlight,
                  width: 1,
                ),
          borderRadius: BorderRadius.circular(AppRadius.input),
          color: filled ? null : AppColorsScheme.of(context).surfaceLight,
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color:
                filled ? Colors.white : AppColorsScheme.of(context).textPrimary,
            fontSize: AppFontSize.xl,
            fontWeight: FontWeight.w700,
            letterSpacing: AppLetterSpacing.normal,
          ),
        ),
      ),
    );
  }
}

class _MobileGuestLink extends ConsumerWidget {
  const _MobileGuestLink();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
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
              builder: (_) => const GuestProfileSetupScreen(isInitial: true),
            ),
          );
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Continue as guest',
              style: TextStyle(
                color: AppColorsScheme.of(context).textSecondary,
                fontSize: AppFontSize.base,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 4),
            AppIcon(
              icon: AppIcons.chevronRight,
              size: 11,
              color: AppColorsScheme.of(context).textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}

class WaveBackground extends StatelessWidget {
  const WaveBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withValues(alpha: 0.16),
            AppColors.secondary.withValues(alpha: 0.10),
            AppColorsScheme.of(context).background,
          ],
        ),
      ),
    );
  }
}

class AuthBranding extends StatefulWidget {
  const AuthBranding({super.key});

  @override
  State<AuthBranding> createState() => _AuthBrandingState();
}

class _AuthBrandingState extends State<AuthBranding>
    with SingleTickerProviderStateMixin {
  late final AnimationController _waveController;

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
    return Column(
      children: [
        SizedBox(
          width: 180,
          height: 120,
          child: Stack(
            alignment: Alignment.center,
            children: [
              AnimatedBuilder(
                animation: _waveController,
                builder: (_, __) => CustomPaint(
                  painter: _WelcomeVisualizerPainter(_waveController.value),
                ),
              ),
              ClipOval(
                child: SvgPicture.asset(
                  AppStrings.logoAsset,
                  width: 72,
                  height: 72,
                  fit: BoxFit.cover,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        Text(
          AppStrings.appName,
          style: TextStyle(
            color: AppColorsScheme.of(context).textPrimary,
            fontSize: AppFontSize.display2,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Your music, beautifully organized.',
          style: TextStyle(
            color: AppColorsScheme.of(context).textSecondary,
            fontSize: AppFontSize.base,
          ),
        ),
      ],
    );
  }
}

class _WelcomeVisualizerPainter extends CustomPainter {
  _WelcomeVisualizerPainter(this.t);
  final double t;

  static const _barCount = 24;

  @override
  void paint(Canvas canvas, Size size) {
    final barWidth = size.width / (_barCount * 2.0);
    final maxHeight = size.height * 0.52;
    final baseY = size.height * 0.5;

    for (int i = 0; i < _barCount; i++) {
      final phase = (i / _barCount) * math.pi * 2;
      final wave1 = math.sin(t * math.pi * 2 + phase) * 0.5 + 0.5;
      final wave2 = math.sin(t * math.pi * 2 * 1.3 + phase * 1.7) * 0.3 + 0.3;
      final height = (wave1 * 0.65 + wave2 * 0.35) * maxHeight + 6;

      final x = (i * 2 + 0.5) * barWidth + barWidth * 0.5;
      final opacity = 0.28 + wave1 * 0.42;
      final paint = Paint()
        ..color = AppColors.primary.withValues(alpha: opacity)
        ..strokeWidth = barWidth * 1.2
        ..strokeCap = StrokeCap.round;

      canvas.drawLine(
        Offset(x, baseY - height / 2),
        Offset(x, baseY + height / 2),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_WelcomeVisualizerPainter oldDelegate) =>
      oldDelegate.t != t;
}
