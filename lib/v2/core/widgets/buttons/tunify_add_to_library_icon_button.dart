import 'package:flutter/material.dart';
import 'package:tunify/v2/core/constants/app_colors.dart';
import 'package:tunify/v2/core/constants/app_icons.dart';
import 'package:tunify/v2/core/constants/app_spacing.dart';

/// Add-to-library outline glyph (shared row actions).
class TunifyAddToLibraryIconButton extends StatelessWidget {
  const TunifyAddToLibraryIconButton({
    super.key,
    this.onPressed,
    this.iconColor,
    this.size,
  });

  final VoidCallback? onPressed;
  final Color? iconColor;
  final double? size;

  @override
  Widget build(BuildContext context) {
    final effectiveSize = size ?? AppSpacing.checkboxSize;
    final color = iconColor ?? AppColors.silver.withValues(alpha: 0.9);

    return IconButton(
      icon: AppIcon(icon: AppIcons.addCircle, size: effectiveSize, color: color),
      onPressed: onPressed,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(),
      style: IconButton.styleFrom(tapTargetSize: MaterialTapTargetSize.shrinkWrap),
    );
  }
}
