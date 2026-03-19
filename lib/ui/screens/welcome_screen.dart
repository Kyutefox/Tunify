import 'package:flutter/material.dart';

import '../components/ui/sheet.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../shared/providers/auth_provider.dart';
import '../../config/app_strings.dart';
import '../theme/app_colors.dart';
import '../theme/design_tokens.dart';
import 'auth_screen.dart';

class WelcomeScreen extends ConsumerWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0, -0.45),
                  radius: 1.1,
                  colors: [
                    AppColors.primary.withValues(alpha: 0.28),
                    AppColors.secondary.withValues(alpha: 0.10),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
            ),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
              child: Column(
                children: [
                  const Spacer(flex: 2),

                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.45),
                          blurRadius: 32,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: SvgPicture.asset(
                        AppStrings.logoAsset,
                        width: 80,
                        height: 80,
                      ),
                    ),
                  ).animate().fadeIn(duration: AppDuration.normal).scale(
                        begin: const Offset(0.7, 0.7),
                        curve: AppCurves.spring,
                      ),

                  const SizedBox(height: AppSpacing.xl),

                  Text(
                    AppStrings.appName,
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 52,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -1.5,
                      height: 1.0,
                    ),
                  )
                      .animate(delay: 100.ms)
                      .fadeIn(duration: AppDuration.normal)
                      .slideY(begin: 0.2, curve: AppCurves.decelerate),

                  const SizedBox(height: AppSpacing.md),

                  const Text(
                    'Millions of songs.\nAll for you.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 17,
                      fontWeight: FontWeight.w400,
                      height: 1.5,
                    ),
                  )
                      .animate(delay: 180.ms)
                      .fadeIn(duration: AppDuration.normal)
                      .slideY(begin: 0.2, curve: AppCurves.decelerate),

                  const Spacer(flex: 3),

                  Row(
                    children: [
                      Expanded(
                        child: _WelcomeButton(
                          label: 'Get Started',
                          onTap: () => _showAuthSheet(context, signUp: true),
                          filled: true,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: _WelcomeButton(
                          label: 'Sign In',
                          onTap: () => _showAuthSheet(context, signUp: false),
                          filled: false,
                        ),
                      ),
                    ],
                  )
                      .animate(delay: 300.ms)
                      .fadeIn(duration: AppDuration.normal)
                      .slideY(begin: 0.3, curve: AppCurves.decelerate),

                  const SizedBox(height: AppSpacing.base),

                  Center(
                    child: GestureDetector(
                      onTap: () {
                        ref.read(guestModeProvider.notifier).enterGuestMode();
                      },
                      child: const Padding(
                        padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
                        child: Text(
                          'Continue as Guest',
                          style: TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ).animate(delay: 420.ms).fadeIn(duration: AppDuration.normal),

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
            letterSpacing: 0.2,
          ),
        ),
      ),
    );
  }
}
