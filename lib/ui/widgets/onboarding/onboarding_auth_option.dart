import 'package:flutter/material.dart';

import 'package:tunify/core/constants/app_icons.dart';
import 'package:tunify/ui/theme/app_colors.dart';
import 'package:tunify/ui/theme/design_tokens.dart';

/// Tappable row used on the auth choice screen (Sign In / Create account).
class OnboardingAuthOptionTile extends StatefulWidget {
  const OnboardingAuthOptionTile({
    super.key,
    required this.icon,
    required this.label,
    required this.sublabel,
    required this.accent,
    required this.onTap,
  });

  final List<List<dynamic>> icon;
  final String label;
  final String sublabel;
  final bool accent;
  final VoidCallback onTap;

  @override
  State<OnboardingAuthOptionTile> createState() =>
      _OnboardingAuthOptionTileState();
}

class _OnboardingAuthOptionTileState extends State<OnboardingAuthOptionTile> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final borderColor = widget.accent
        ? AppColors.primary.withValues(alpha: UIOpacity.emphasis)
        : AppColors.surfaceHighlight.withValues(alpha: UIOpacity.high);
    final iconColor =
        widget.accent ? AppColors.primary : AppColors.textSecondary;

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedOpacity(
        opacity: _pressed ? UIOpacity.high : 1.0,
        duration: AppDuration.fast,
        curve: AppCurves.standard,
        child: Container(
          height: 68,
          decoration: BoxDecoration(
            color: AppColors.surfaceLight.withValues(alpha: UIOpacity.strong),
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: borderColor, width: UIStroke.thin),
          ),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          child: Row(
            children: [
              AppIcon(icon: widget.icon, size: UISize.iconMd, color: iconColor),
              const SizedBox(width: AppSpacing.base),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      widget.label,
                      style: AppTextStyle.titleBase.copyWith(
                        fontSize: AppFontSize.base,
                      ),
                    ),
                    Text(
                      widget.sublabel,
                      style: AppTextStyle.caption,
                    ),
                  ],
                ),
              ),
              AppIcon(
                icon: AppIcons.chevronRight,
                size: UISize.iconSm,
                color: AppColors.textMuted.withValues(alpha: UIOpacity.high),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Outlined secondary action matching guest entry on auth choice.
class OnboardingAuthOutlineTile extends StatefulWidget {
  const OnboardingAuthOutlineTile({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final List<List<dynamic>> icon;
  final String label;
  final VoidCallback onTap;

  @override
  State<OnboardingAuthOutlineTile> createState() =>
      _OnboardingAuthOutlineTileState();
}

class _OnboardingAuthOutlineTileState extends State<OnboardingAuthOutlineTile> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedOpacity(
        opacity: _pressed ? UIOpacity.high : 1.0,
        duration: AppDuration.fast,
        curve: AppCurves.standard,
        child: Container(
          height: 52,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(
              color:
                  AppColors.surfaceHighlight.withValues(alpha: UIOpacity.strong),
              width: UIStroke.hairline,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AppIcon(
                icon: widget.icon,
                size: UISize.iconSm,
                color: AppColors.textSecondary.withValues(alpha: UIOpacity.high),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                widget.label,
                style: AppTextStyle.bodyBase.copyWith(
                  color:
                      AppColors.textSecondary.withValues(alpha: UIOpacity.high),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
