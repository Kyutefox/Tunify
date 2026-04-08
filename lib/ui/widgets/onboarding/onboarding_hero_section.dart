import 'package:flutter/material.dart';

import 'package:tunify/ui/theme/app_colors.dart';
import 'package:tunify/ui/theme/design_tokens.dart';
import 'package:tunify/ui/widgets/onboarding/onboarding_mini_logo_chip.dart';

/// Logo chip + display title + supporting copy (auth choice, sign-in/up).
class OnboardingHeroSection extends StatelessWidget {
  const OnboardingHeroSection({
    super.key,
    required this.title,
    required this.subtitle,
    this.maxTitleWidth = 320,
    this.maxSubtitleWidth = 340,
  });

  final String title;
  final String subtitle;
  final double maxTitleWidth;
  final double maxSubtitleWidth;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const OnboardingMiniLogoChip(),
        const SizedBox(height: AppSpacing.xl + 2),
        ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxTitleWidth),
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: AppTextStyle.display3,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxSubtitleWidth),
          child: Text(
            subtitle,
            textAlign: TextAlign.center,
            style: AppTextStyle.bodyBase.copyWith(
              height: AppLineHeight.relaxed,
              color: AppColors.textSecondary.withValues(alpha: UIOpacity.high),
              letterSpacing: 0.1,
            ),
          ),
        ),
      ],
    );
  }
}
