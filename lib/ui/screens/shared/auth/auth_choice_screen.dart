import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tunify/core/constants/app_icons.dart';
import 'package:tunify/data/repositories/database_repository.dart';
import 'package:tunify/features/auth/auth_provider.dart';
import 'package:tunify/features/settings/guest_profile_provider.dart';
import 'package:tunify/ui/screens/shared/auth/guest_profile_setup_screen.dart';
import 'package:tunify/ui/screens/shared/auth/onboarding_auth_screen.dart';
import 'package:tunify/ui/theme/app_colors.dart';
import 'package:tunify/ui/theme/app_routes.dart';
import 'package:tunify/ui/theme/design_tokens.dart';
import 'package:tunify/ui/widgets/onboarding/onboarding_auth_option.dart';
import 'package:tunify/ui/widgets/onboarding/onboarding_back_label_button.dart';
import 'package:tunify/ui/widgets/onboarding/onboarding_glass_panel.dart';
import 'package:tunify/ui/widgets/onboarding/onboarding_hero_section.dart';
import 'package:tunify/ui/widgets/onboarding/onboarding_layout_sizing.dart';
import 'package:tunify/ui/widgets/onboarding/onboarding_spaced_scroll_body.dart';

class AuthChoiceScreen extends ConsumerWidget {
  const AuthChoiceScreen({super.key});

  void _navigateToAuth(BuildContext context, {required bool signUp}) {
    Navigator.of(context).push(
      appPageRoute<void>(
        keyboardInsetsUnmasked: true,
        builder: (_) => OnboardingAuthScreen(initialSignUp: signUp),
      ),
    );
  }

  Future<void> _navigateToGuest(BuildContext context, WidgetRef ref) async {
    final existing =
        await ref.read(databaseBridgeProvider).getSetting(kGuestUsernameKey);
    if (!context.mounted) return;
    if (existing != null && existing.isNotEmpty) {
      ref.read(guestModeProvider.notifier).enterGuestMode();
    } else {
      Navigator.of(context).push(
        appPageRoute<void>(
          keyboardInsetsUnmasked: true,
          builder: (_) => const GuestProfileSetupScreen(isInitial: true),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: OnboardingSpacedScrollBody(
          minContentHeight: OnboardingLayoutSizing.authChoiceMinHeight,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(flex: 2),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                child: const OnboardingHeroSection(
                  title: 'How would you\nlike to continue?',
                  subtitle:
                      'Sign in to sync your library, or jump right in as a guest.',
                ),
              ),
              const Spacer(flex: 2),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                child: OnboardingGlassPanel(
                  child: Column(
                    children: [
                      OnboardingAuthOptionTile(
                        icon: AppIcons.verified,
                        label: 'Sign In',
                        sublabel: 'Welcome back',
                        accent: false,
                        onTap: () => _navigateToAuth(context, signUp: false),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      OnboardingAuthOptionTile(
                        icon: AppIcons.personOutline,
                        label: 'Create an Account',
                        sublabel: 'Sync, backup & more',
                        accent: false,
                        onTap: () => _navigateToAuth(context, signUp: true),
                      ),
                      const SizedBox(height: AppSpacing.xxl),
                      Row(
                        children: [
                          Expanded(
                            child: Divider(
                              color: AppColors.surfaceHighlight
                                  .withValues(alpha: UIOpacity.high),
                              thickness: UIStroke.hairline,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.md,
                            ),
                            child: Text(
                              'or',
                              style: AppTextStyle.caption.copyWith(
                                color: AppColors.textMuted
                                    .withValues(alpha: UIOpacity.emphasis),
                              ),
                            ),
                          ),
                          Expanded(
                            child: Divider(
                              color: AppColors.surfaceHighlight
                                  .withValues(alpha: UIOpacity.high),
                              thickness: UIStroke.hairline,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xxl),
                      OnboardingAuthOutlineTile(
                        icon: AppIcons.person,
                        label: 'Continue as Guest',
                        onTap: () => _navigateToGuest(context, ref),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      Center(
                        child: OnboardingBackLabelButton(
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Spacer(flex: 1),
              const SizedBox(height: AppSpacing.xxl),
            ],
          ),
        ),
      ),
    );
  }
}
