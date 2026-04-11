import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:tunify/v1/core/constants/app_strings.dart';
import 'package:tunify/v1/ui/theme/app_colors.dart';
import 'package:tunify/v1/ui/theme/design_tokens.dart';

/// Compact logo + app name pill used across onboarding headers.
class OnboardingMiniLogoChip extends StatelessWidget {
  const OnboardingMiniLogoChip({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight
            .withValues(alpha: UIOpacity.strong - UIOpacity.subtle),
        borderRadius: BorderRadius.circular(AppRadius.full),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: UIOpacity.medium),
          width: UIStroke.thin,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SvgPicture.asset(
            AppStrings.logoAsset,
            width: UISize.iconMd,
            height: UISize.iconMd,
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            AppStrings.appName,
            style: AppTextStyle.labelBase.copyWith(
              color: AppColors.textPrimary.withValues(alpha: UIOpacity.high),
              fontSize: AppFontSize.sm,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}
