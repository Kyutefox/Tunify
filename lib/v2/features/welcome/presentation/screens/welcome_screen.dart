import 'package:flutter/material.dart';
import 'package:tunify/v2/core/constants/app_colors.dart';
import 'package:tunify/v2/core/constants/app_icons.dart';
import 'package:tunify/v2/core/constants/app_spacing.dart';
import 'package:tunify/v2/core/theme/app_button_styles.dart';
import 'package:tunify/v2/core/theme/app_text_styles.dart';
import 'package:tunify/v2/features/auth/presentation/screens/auth_choice_screen.dart';
import 'package:tunify/v2/features/auth/presentation/screens/privacy_policy_screen.dart';
import 'package:tunify/v2/features/auth/presentation/screens/terms_of_use_screen.dart';
import 'package:tunify/v2/features/settings/presentation/screens/settings_screen.dart';
import 'package:tunify/v2/features/welcome/presentation/widgets/tunify_logo.dart';

/// Tunify Welcome Screen
/// Strictly per DESIGN.md specifications:
/// - Background: #121212 (nearBlack)
/// - Logo: Brand green circle with sound waves
/// - Headline: Section Title 24px/700
/// - Primary CTA: Brand Green button (per DESIGN.md: "Spotify Green for primary CTAs")
/// - Secondary CTA: Dark Pill button (per DESIGN.md: "Dark Pill for secondary actions")
/// - Terms: Micro text 10px/400, silver color with brand green links
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.nearBlack,
      appBar: AppBar(
        backgroundColor: AppColors.nearBlack,
        elevation: 0,
        actions: [
          // Settings icon
          IconButton(
            icon: AppIcon(
              icon: AppIcons.settings,
              color: AppColors.white,
            ),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const SettingsScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Column(
            children: [
              const Spacer(flex: 1),

              // Tunify Logo - Brand Green
              const TunifyLogo(size: AppSpacing.welcomeLogoSize),

              const SizedBox(height: AppSpacing.xxl),

              // Welcome Headline - Section Title: 24px/700 per DESIGN.md
              Text(
                'Millions of songs.\nFree on Tunify.',
                textAlign: TextAlign.center,
                style: AppTextStyles.sectionTitle,
              ),

              const Spacer(flex: 3),

              // Primary CTA: Sign Up Free
              // DESIGN.md: Brand Green Large Pill for primary CTAs
              AppButtonStyles.brandGreenLargePill(
                label: 'Sign up free',
                width: double.infinity,
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const AuthChoiceScreen(
                        mode: AuthMode.signup,
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: AppSpacing.lg),

              // Secondary CTA: Log In
              // DESIGN.md: Dark Large Pill for secondary actions
              AppButtonStyles.darkLargePill(
                label: 'Log in',
                width: double.infinity,
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const AuthChoiceScreen(
                        mode: AuthMode.login,
                      ),
                    ),
                  );
                },
              ),

              const Spacer(flex: 1),

              // Terms and Privacy Text
              // DESIGN.md: Micro 10px/400, silver color
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: Wrap(
                  alignment: WrapAlignment.center,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      'By tapping on "Sign up free", you agree to our ',
                      style: AppTextStyles.micro,
                      textAlign: TextAlign.center,
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const TermsOfUseScreen(),
                          ),
                        );
                      },
                      child: Text(
                        'Terms of use',
                        style: AppTextStyles.micro.copyWith(
                          color: AppColors.brandGreen,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Text(
                      ' and ',
                      style: AppTextStyles.micro,
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const PrivacyPolicyScreen(),
                          ),
                        );
                      },
                      child: Text(
                        'Privacy Policy',
                        style: AppTextStyles.micro.copyWith(
                          color: AppColors.brandGreen,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Text(
                      '.',
                      style: AppTextStyles.micro,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.xl),
            ],
          ),
        ),
      ),
    );
  }
}
