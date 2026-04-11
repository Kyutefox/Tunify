import 'package:flutter/material.dart';

import 'package:tunify/v1/ui/theme/app_colors.dart';
import 'package:tunify/v1/ui/theme/design_tokens.dart';

/// Text “Back” row with chevron — used at the bottom of onboarding panels.
class OnboardingBackLabelButton extends StatelessWidget {
  const OnboardingBackLabelButton({
    super.key,
    required this.onPressed,
  });

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Back',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(AppRadius.full),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.chevron_left,
                  size: UISize.iconLg,
                  color:
                      AppColors.textSecondary.withValues(alpha: UIOpacity.high),
                ),
                Text(
                  'Back',
                  style: AppTextStyle.bodyBase.copyWith(
                    color: AppColors.textSecondary
                        .withValues(alpha: UIOpacity.emphasis),
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
