import 'package:flutter/material.dart';

import 'package:tunify/v1/ui/theme/app_colors.dart';
import 'package:tunify/v1/ui/theme/design_tokens.dart';

/// Frosted panel container shared by auth choice and credential screens.
class OnboardingGlassPanel extends StatelessWidget {
  const OnboardingGlassPanel({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.xl,
        AppSpacing.lg,
        AppSpacing.lg,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight.withValues(alpha: UIOpacity.subtle * 3),
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(
          color: AppColors.surfaceHighlight.withValues(alpha: UIOpacity.medium),
          width: UIStroke.hairline,
        ),
      ),
      child: child,
    );
  }
}
