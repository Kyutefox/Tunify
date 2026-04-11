import 'package:flutter/material.dart';
import 'package:tunify/v2/core/constants/app_colors.dart';
import 'package:tunify/v2/core/constants/app_spacing.dart';
import 'package:tunify/v2/core/theme/app_button_styles.dart';
import 'package:tunify/v2/core/theme/app_text_styles.dart';
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
    final size = MediaQuery.of(context).size;
    final horizontalPadding = size.width * 0.08;

    return Scaffold(
      backgroundColor: AppColors.nearBlack,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
          child: Column(
            children: [
              const Spacer(flex: 2),

              // Tunify Logo - Brand Green
              const TunifyLogo(size: 72),

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
                  // TODO: Navigate to sign up flow
                },
              ),

              const SizedBox(height: AppSpacing.lg),

              // Secondary CTA: Log In
              // DESIGN.md: Dark Large Pill for secondary actions
              AppButtonStyles.darkLargePill(
                label: 'Log in',
                width: double.infinity,
                onPressed: () {
                  // TODO: Navigate to login flow
                },
              ),

              const Spacer(flex: 1),

              // Terms and Privacy Text
              // DESIGN.md: Micro 10px/400, silver color
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: 'By tapping on "Sign up free", you agree to our ',
                        style: AppTextStyles.micro,
                      ),
                      TextSpan(
                        text: 'Terms of Service',
                        style: AppTextStyles.micro.copyWith(
                          color: AppColors.brandGreen,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      TextSpan(
                        text: ' and ',
                        style: AppTextStyles.micro,
                      ),
                      TextSpan(
                        text: 'Privacy Policy',
                        style: AppTextStyles.micro.copyWith(
                          color: AppColors.brandGreen,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      TextSpan(
                        text: '.',
                        style: AppTextStyles.micro,
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
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
