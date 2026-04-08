import 'package:flutter/material.dart';

import 'package:tunify/ui/theme/design_tokens.dart';
import 'button.dart';
import 'package:tunify/ui/theme/app_colors_scheme.dart';

/// Reusable empty state: icon, title, optional subtitle and action button.
class EmptyStatePlaceholder extends StatelessWidget {
  const EmptyStatePlaceholder({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
    this.iconSize = 48,
    this.padding,
  });

  final Widget icon;
  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;
  final double iconSize;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding:
            padding ?? const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(width: iconSize, height: iconSize, child: icon),
            SizedBox(height: iconSize >= 48 ? AppSpacing.lg : AppSpacing.sm),
            Text(
              title,
              style: TextStyle(
                color: AppColorsScheme.of(context).textMuted,
                fontSize: AppFontSize.xl,
              ),
              textAlign: TextAlign.center,
            ),
            if (subtitle != null && subtitle!.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                subtitle!,
                style: TextStyle(
                  color: AppColorsScheme.of(context)
                      .textMuted
                      .withValues(alpha: 0.8),
                  fontSize: AppFontSize.base,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: AppSpacing.xl),
              AppButton(
                label: actionLabel!,
                onPressed: onAction!,
                variant: AppButtonVariant.filled,
                height: 44,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
