import 'package:flutter/material.dart';
import 'package:tunify/v2/core/constants/app_border_radius.dart';
import 'package:tunify/v2/core/constants/app_colors.dart';
import 'package:tunify/v2/core/constants/app_spacing.dart';
import 'package:tunify/v2/core/theme/app_text_styles.dart';
import 'package:tunify/v2/core/widgets/buttons/filter_single_pill.dart';

/// Button styles strictly per DESIGN.md Component Stylings section
class AppButtonStyles {
  AppButtonStyles._();

  /// Dark Large Pill Button
  /// DESIGN.md: Background #181818, Text #ffffff, Padding 0px 43px, Radius 500px
  /// Use: Primary app navigation buttons
  static Widget darkLargePill({
    required String label,
    VoidCallback? onPressed,
    double? width,
  }) {
    return SizedBox(
      width: width,
      height: AppSpacing.xxxl,
      child: Material(
        color: AppColors.darkSurface,
        borderRadius: BorderRadius.circular(AppBorderRadius.pill),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(AppBorderRadius.pill),
          child: Container(
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxxl - 5),
            child: Text(
              label.toUpperCase(),
              style: AppTextStyles.buttonUppercase.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Brand Green Large Pill Button (Primary CTA)
  /// DESIGN.md: Brand Green #1ed760 for "primary CTAs"
  /// Uses Dark Large Pill dimensions: 500px radius, 0px 43px padding
  static Widget brandGreenLargePill({
    required String label,
    VoidCallback? onPressed,
    double? width,
  }) {
    final bool isEnabled = onPressed != null;
    return SizedBox(
      width: width,
      height: AppSpacing.xxxl,
      child: Material(
        color: isEnabled ? AppColors.brandGreen : AppColors.lightBorder,
        borderRadius: BorderRadius.circular(AppBorderRadius.pill),
        child: InkWell(
          onTap: isEnabled ? onPressed : null,
          borderRadius: BorderRadius.circular(AppBorderRadius.pill),
          child: Container(
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxxl - 5),
            child: Text(
              label.toUpperCase(),
              style: AppTextStyles.buttonUppercase.copyWith(
                color: isEnabled ? AppColors.nearBlack : AppColors.white.withValues(alpha: 0.5),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Outlined Pill Button
  /// DESIGN.md: Background transparent, Border 1px solid #7c7c7c, Text #ffffff
  /// Padding: 4px 16px 4px 36px (with icon) or 8px 16px (without icon)
  /// Use: Follow buttons, secondary actions
  static Widget outlinedPill({
    required String label,
    VoidCallback? onPressed,
    double? width,
    Widget? icon,
  }) {
    final EdgeInsets padding = icon != null
        ? const EdgeInsets.only(
            left: 36,
            top: 4,
            right: 16,
            bottom: 4,
          )
        : const EdgeInsets.symmetric(
            vertical: AppSpacing.md,
            horizontal: AppSpacing.lg,
          );

    return SizedBox(
      width: width,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppBorderRadius.fullPill),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(AppBorderRadius.fullPill),
          child: Container(
            padding: padding,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              border: Border.all(
                color: AppColors.lightBorder,
                width: 1,
              ),
              borderRadius: BorderRadius.circular(AppBorderRadius.fullPill),
            ),
            child: icon != null
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      icon,
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        label.toUpperCase(),
                        style: AppTextStyles.buttonUppercase.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  )
                : Text(
                    label.toUpperCase(),
                    style: AppTextStyles.buttonUppercase.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  /// Library-style filter pill (Figma “Menu - Library” single chip).
  ///
  /// Optional [showCloseControl] + [onClose] match Figma category row.
  static Widget navigationDarkPill({
    required String label,
    required bool selected,
    VoidCallback? onPressed,
    bool showCloseControl = false,
    VoidCallback? onClose,
  }) {
    return FilterSinglePill(
      label: label,
      selected: selected,
      onPressed: onPressed,
      showCloseControl: showCloseControl,
      onClose: onClose,
    );
  }
}
