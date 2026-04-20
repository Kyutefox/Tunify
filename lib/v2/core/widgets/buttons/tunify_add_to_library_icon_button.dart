import 'package:flutter/material.dart';
import 'package:tunify/v2/core/constants/app_colors.dart';
import 'package:tunify/v2/core/constants/app_icons.dart';
import 'package:tunify/v2/core/constants/app_spacing.dart';

/// Add-to-library / saved-in-library toggle glyph (shared row actions).
///
/// Shows [AppIcons.addCircle] when [isSaved] is false and
/// [AppIcons.checkCircle] (accent-tinted) when [isSaved] is true.
class TunifyAddToLibraryIconButton extends StatelessWidget {
  const TunifyAddToLibraryIconButton({
    super.key,
    this.onPressed,
    this.iconColor,
    this.size,
    this.isSaved = false,
  });

  final VoidCallback? onPressed;
  final Color? iconColor;
  final double? size;

  /// When true, renders the checkmark icon in the app accent color.
  final bool isSaved;

  @override
  Widget build(BuildContext context) {
    final effectiveSize = size ?? AppSpacing.checkboxSize;
    final color = isSaved
        ? AppColors.brandGreen
        : (iconColor ?? AppColors.silver.withValues(alpha: 0.9));

    return IconButton(
      icon: AppIcon(
        icon: isSaved ? AppIcons.checkCircle : AppIcons.addCircle,
        size: effectiveSize,
        color: color,
      ),
      onPressed: onPressed,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(),
      style: IconButton.styleFrom(tapTargetSize: MaterialTapTargetSize.shrinkWrap),
    );
  }
}
