import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tunify/core/constants/app_icons.dart';
import 'package:tunify/core/constants/app_strings.dart';
import 'package:tunify/features/auth/auth_provider.dart';
import 'package:tunify/features/settings/guest_profile_provider.dart';
import 'package:tunify/data/repositories/database_repository.dart';
import 'package:tunify/ui/widgets/common/sheet.dart';
import 'package:tunify/ui/theme/app_colors.dart';
import 'package:tunify/ui/theme/design_tokens.dart';
import 'package:tunify/ui/theme/app_routes.dart';
import 'package:tunify/ui/widgets/auth/auth_shared.dart';
import 'package:tunify/ui/widgets/auth/desktop_auth_layout.dart';
import 'package:tunify/ui/widgets/auth/guest_profile_setup_form.dart';
import 'package:tunify/ui/screens/mobile/auth/auth_screen.dart' as mobile_auth;
import 'package:tunify/ui/shell/shell_context.dart';
import 'guest_profile_setup_screen.dart';
import 'package:tunify/ui/theme/app_colors_scheme.dart';

class WelcomeScreen extends ConsumerStatefulWidget {
  const WelcomeScreen({super.key});

  @override
  ConsumerState<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends ConsumerState<WelcomeScreen> {
  bool _showAuthForm = false;
  bool _showGuestSetup = false;
  bool _initialSignUp = false;

  @override
  Widget build(BuildContext context) {
    if (ShellContext.isDesktopPlatform) {
      return DesktopAuthLayout(
        rightContent: AnimatedSwitcher(
          duration: const Duration(milliseconds: 240),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeOutCubic,
          transitionBuilder: (child, animation) {
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.03),
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              ),
            );
          },
          child: _showGuestSetup
              ? _buildDesktopGuestSetupCard()
              : (_showAuthForm
                  ? _buildDesktopAuthCard()
                  : _buildDesktopWelcomeButtons()),
        ),
      );
    }

    return _MobileWelcomeScreen(
      onShowAuth: (signUp) {
        showRawSheet(
          context,
          child: mobile_auth.MobileAuthScreen(initialSignUp: signUp),
        );
      },
      onShowGuestSetup: () {
        showRawSheet(
          context,
          child: const GuestProfileSetupScreen(isInitial: true),
        );
      },
    );
  }

  Widget _buildDesktopGuestSetupCard() {
    return Container(
      key: const ValueKey('guest-setup'),
      constraints: const BoxConstraints(maxWidth: 400),
      child: Container(
        decoration: BoxDecoration(
          color: AppColorsScheme.of(context).surface,
          borderRadius: BorderRadius.circular(AppRadius.xxl),
          border: Border.all(
            color: AppColors.glassBorder,
            width: 0.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 40,
              offset: const Offset(0, 20),
            ),
          ],
        ),
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildBackButton(() {
              setState(() {
                _showGuestSetup = false;
              });
            }),
            const SizedBox(height: AppSpacing.lg),
            GuestProfileSetupForm(
              isInitial: true,
              onBack: () {
                setState(() {
                  _showGuestSetup = false;
                });
              },
              onContinue: () {
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
            ),
          ],
        ),
      ).animate().fadeIn(duration: AppDuration.slow).slideY(
            begin: 0.1,
            end: 0,
            duration: AppDuration.slow,
            curve: Curves.easeOut,
          ),
    );
  }

  Widget _buildDesktopWelcomeButtons() {
    return Container(
      key: const ValueKey('welcome'),
      constraints: const BoxConstraints(maxWidth: 400),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            decoration: BoxDecoration(
              color: AppColorsScheme.of(context).surface,
              borderRadius: BorderRadius.circular(AppRadius.xxl),
              border: Border.all(
                color: AppColors.glassBorder,
                width: 0.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 40,
                  offset: const Offset(0, 20),
                ),
              ],
            ),
            padding: const EdgeInsets.all(AppSpacing.xxl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Welcome',
                  style: TextStyle(
                    color: AppColorsScheme.of(context).textPrimary,
                    fontSize: AppFontSize.display2,
                    fontWeight: FontWeight.w900,
                    letterSpacing: AppLetterSpacing.display,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Sign in to continue to ${AppStrings.appName}',
                  style: TextStyle(
                    color: AppColorsScheme.of(context).textSecondary,
                    fontSize: AppFontSize.base,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxl),
                _DesktopButton(
                  label: 'Get started',
                  onTap: () {
                    setState(() {
                      _initialSignUp = true;
                      _showAuthForm = true;
                    });
                  },
                  filled: true,
                ),
                const SizedBox(height: AppSpacing.md),
                _DesktopButton(
                  label: 'Sign in',
                  onTap: () {
                    setState(() {
                      _initialSignUp = false;
                      _showAuthForm = true;
                    });
                  },
                  filled: false,
                ),
                const SizedBox(height: AppSpacing.lg),
                _buildGuestLink(),
              ],
            ),
          ).animate().fadeIn(duration: AppDuration.slow).slideY(
                begin: 0.1,
                end: 0,
                duration: AppDuration.slow,
                curve: Curves.easeOut,
              ),
        ],
      ),
    );
  }

  Widget _buildDesktopAuthCard() {
    return Container(
      key: const ValueKey('auth'),
      constraints: const BoxConstraints(maxWidth: 400),
      child: Container(
        decoration: BoxDecoration(
          color: AppColorsScheme.of(context).surface,
          borderRadius: BorderRadius.circular(AppRadius.xxl),
          border: Border.all(
            color: AppColors.glassBorder,
            width: 0.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 40,
              offset: const Offset(0, 20),
            ),
          ],
        ),
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildBackButton(),
            const SizedBox(height: AppSpacing.md),
            AuthForm(
              initialSignUp: _initialSignUp,
              showHeader: true,
              onToggle: () {
                setState(() {
                  _initialSignUp = !_initialSignUp;
                });
              },
            ),
          ],
        ),
      ).animate().fadeIn(duration: AppDuration.slow).slideY(
            begin: 0.1,
            end: 0,
            duration: AppDuration.slow,
            curve: Curves.easeOut,
          ),
    );
  }

  Widget _buildBackButton([VoidCallback? onBack]) {
    return GestureDetector(
      onTap: onBack ??
          () {
            setState(() {
              _showAuthForm = false;
            });
          },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppIcon(
            icon: AppIcons.back,
            size: 18,
            color: AppColorsScheme.of(context).textSecondary,
          ),
          const SizedBox(width: AppSpacing.xs),
          Text(
            'Back',
            style: TextStyle(
              color: AppColorsScheme.of(context).textSecondary,
              fontSize: AppFontSize.base,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGuestLink() {
    return GestureDetector(
      onTap: () async {
        if (ShellContext.isDesktopPlatform) {
          setState(() {
            _showGuestSetup = true;
          });
          return;
        }
        final existing = await ref
            .read(databaseBridgeProvider)
            .getSetting(kGuestUsernameKey);
        if (!mounted) return;
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
      child: Center(
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
      ),
    );
  }
}

class _DesktopButton extends StatelessWidget {
  const _DesktopButton({
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
        height: 52,
        decoration: BoxDecoration(
          gradient: filled ? AppColors.primaryGradient : null,
          border: filled
              ? null
              : Border.all(color: AppColors.glassBorder, width: 1),
          borderRadius: BorderRadius.circular(AppRadius.md),
          color: filled ? null : AppColors.glassWhite,
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: filled ? Colors.white : AppColorsScheme.of(context).textPrimary,
            fontSize: AppFontSize.base,
            fontWeight: FontWeight.w700,
            letterSpacing: AppLetterSpacing.normal,
          ),
        ),
      ),
    );
  }
}

class _MobileWelcomeScreen extends StatelessWidget {
  const _MobileWelcomeScreen({
    required this.onShowAuth,
    required this.onShowGuestSetup,
  });

  final void Function(bool signUp) onShowAuth;
  final VoidCallback onShowGuestSetup;

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
                    AppColorsScheme.of(context).background.withValues(alpha: 0.55),
                    AppColorsScheme.of(context).background.withValues(alpha: 0.92),
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
                  _MobileGuestLink()
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
              : Border.all(color: AppColors.glassBorder, width: 1),
          borderRadius: BorderRadius.circular(AppRadius.input),
          color: filled ? null : AppColors.glassWhite,
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: filled ? Colors.white : AppColorsScheme.of(context).textPrimary,
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
