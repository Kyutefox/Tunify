import 'package:flutter/material.dart';

import '../../../../config/app_icons.dart';
import '../../../../ui/layout/shell_context.dart';
import '../../../../ui/theme/app_colors.dart';
import '../../../../ui/theme/design_tokens.dart';

class SectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final VoidCallback? onSeeAll;
  final String? seeAllLabel;
  final Widget? trailing;
  final EdgeInsetsGeometry? padding;
  final bool useCompactStyle;

  const SectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.onSeeAll,
    this.seeAllLabel,
    this.trailing,
    this.padding,
    this.useCompactStyle = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDesktop = ShellContext.isDesktopOf(context);
    final hPad = isDesktop ? AppSpacing.xl : AppSpacing.base;
    final resolvedPadding = padding ??
        EdgeInsets.fromLTRB(hPad, 0, hPad, AppSpacing.md);
    final titleFontSize = useCompactStyle ? 20.0 : 22.0;
    final subtitleFontSize = useCompactStyle ? 12.0 : 13.0;

    return Padding(
      padding: resolvedPadding,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: titleFontSize,
                    fontWeight: FontWeight.w700,
                    letterSpacing: useCompactStyle ? -0.3 : -0.5,
                  ),
                ),
                if (subtitle != null) ...[
                  SizedBox(height: useCompactStyle ? 2 : 4),
                  Text(
                    subtitle!,
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: subtitleFontSize,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null)
            trailing!
          else if (onSeeAll != null)
            _buildAction(context),
        ],
      ),
    );
  }

  Widget _buildAction(BuildContext context) {
    final label = seeAllLabel;
    if (label != null && label.isNotEmpty) {
      return GestureDetector(
        onTap: onSeeAll,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
    }
    return GestureDetector(
      onTap: onSeeAll,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ShaderMask(
              shaderCallback: (bounds) =>
                  AppColors.primaryGradient.createShader(bounds),
              child: const Text(
                'See All',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 4),
            ShaderMask(
              shaderCallback: (bounds) =>
                  AppColors.primaryGradient.createShader(bounds),
              child: AppIcon(
                icon: AppIcons.forward,
                size: 14,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class GradientSectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final LinearGradient gradient;
  final List<List<dynamic>>? icon;

  const GradientSectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.gradient = AppColors.primaryGradient,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
      child: Row(
        children: [
          if (icon != null) ...[
            ShaderMask(
              shaderCallback: (bounds) => gradient.createShader(bounds),
              child: AppIcon(icon: icon!, size: 28, color: Colors.white),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShaderMask(
                  shaderCallback: (bounds) => gradient.createShader(bounds),
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle!,
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 13,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
