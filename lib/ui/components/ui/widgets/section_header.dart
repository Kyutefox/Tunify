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
    final text = (label != null && label.isNotEmpty) ? label : 'See All';
    return GestureDetector(
      onTap: onSeeAll,
      child: ShaderMask(
        shaderCallback: (bounds) =>
            AppColors.primaryGradient.createShader(bounds),
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: AppFontSize.md,
            fontWeight: FontWeight.w600,
          ),
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
      padding: const EdgeInsets.fromLTRB(AppSpacing.base, AppSpacing.xl, AppSpacing.base, AppSpacing.base),
      child: Row(
        children: [
          if (icon != null) ...[
            ShaderMask(
              shaderCallback: (bounds) => gradient.createShader(bounds),
              child: AppIcon(icon: icon!, size: 28, color: Colors.white),
            ),
            const SizedBox(width: AppSpacing.md),
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
                      fontSize: AppFontSize.h2,
                      fontWeight: FontWeight.w700,
                      letterSpacing: AppLetterSpacing.display,
                    ),
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle!,
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: AppFontSize.md,
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
