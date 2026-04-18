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
    this.dense = false,
  });

  final String label;
  final VoidCallback? onPressed;

  /// Smaller vertical padding (e.g. Spotify-style compact promo row).
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    final vPad = dense ? AppSpacing.sm + AppSpacing.xs : AppSpacing.md;
    final hPad = dense ? AppSpacing.md + AppSpacing.xs : AppSpacing.md;
    final labelStyle = (dense ? AppTextStyles.caption : AppTextStyles.small).copyWith(
      color: AppColors.white.withValues(alpha: enabled ? 1 : 0.5),
      fontWeight: dense ? FontWeight.w600 : FontWeight.w400,
    );
    final child = Padding(
      padding: EdgeInsets.symmetric(
        horizontal: hPad,
        vertical: vPad,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ListenModeBarsIcon(
            foreground: AppColors.white.withValues(alpha: enabled ? 1 : 0.5),
          ),
          const SizedBox(width: AppSpacing.md),
          Text(label, style: labelStyle),
        ],
      ),
    );
    return Material(
      color: AppColors.nearBlack.withValues(alpha: enabled ? 0.5 : 0.35),
      borderRadius: BorderRadius.circular(AppBorderRadius.pill),
      child: enabled
          ? InkWell(
              onTap: onPressed,
              borderRadius: BorderRadius.circular(AppBorderRadius.pill),
              child: child,
            )
          : child,
    );
  }
}

class _ListenModeBarsIcon extends StatelessWidget {
  const _ListenModeBarsIcon({this.foreground = AppColors.white});

  final Color foreground;

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
                color: foreground,
                borderRadius: BorderRadius.circular(AppBorderRadius.minimal),
              ),
            ),
        ],
      ),
    );
  }
}
