import 'package:flutter/material.dart';
import 'package:tunify/v2/core/constants/app_border_radius.dart';
import 'package:tunify/v2/core/constants/app_colors.dart';
import 'package:tunify/v2/core/constants/app_spacing.dart';
import 'package:tunify/v2/core/theme/app_text_styles.dart';

/// Dark pill with listen affordance + label (e.g. podcast promo).
class ListenNowPillButton extends StatelessWidget {
  const ListenNowPillButton({
    super.key,
    this.label = 'Listen now',
    this.onPressed,
  });

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.nearBlack.withValues(alpha: 0.5),
      borderRadius: BorderRadius.circular(AppBorderRadius.pill),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(AppBorderRadius.pill),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.md,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const _ListenModeBarsIcon(),
              const SizedBox(width: AppSpacing.md),
              Text(
                label,
                style: AppTextStyles.small.copyWith(color: AppColors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ListenModeBarsIcon extends StatelessWidget {
  const _ListenModeBarsIcon();

  static const double _containerWidth = 18;
  static const double _containerHeight = 20;
  static const double _barWidth = 3;
  static const List<double> _barHeights = [14, 20, 10];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: _containerWidth,
      height: _containerHeight,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (final h in _barHeights)
            Container(
              width: _barWidth,
              height: h,
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(AppBorderRadius.minimal),
              ),
            ),
        ],
      ),
    );
  }
}
