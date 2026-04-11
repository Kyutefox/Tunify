import 'package:flutter/material.dart';
import 'package:tunify/v2/core/constants/app_spacing.dart';

enum TunifyMoreIconStyle { horizontal, vertical }

/// Overflow “more” affordance (horizontal or vertical dots).
class TunifyMoreIconButton extends StatelessWidget {
  const TunifyMoreIconButton({
    super.key,
    required this.style,
    this.onPressed,
    this.color,
    this.size,
  });

  final TunifyMoreIconStyle style;
  final VoidCallback? onPressed;
  final Color? color;
  final double? size;

  @override
  Widget build(BuildContext context) {
    final effectiveSize = size ?? AppSpacing.checkboxSize;
    final icon = style == TunifyMoreIconStyle.vertical
        ? Icons.more_vert_rounded
        : Icons.more_horiz_rounded;

    return IconButton(
      icon: Icon(icon, size: effectiveSize, color: color),
      onPressed: onPressed,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(),
      style: IconButton.styleFrom(tapTargetSize: MaterialTapTargetSize.shrinkWrap),
    );
  }
}
