import 'package:flutter/material.dart';

import 'package:tunify/core/constants/app_icons.dart';
import 'package:tunify/ui/theme/app_colors.dart';
import 'package:tunify/ui/theme/design_tokens.dart';
import 'package:tunify/ui/theme/desktop_tokens.dart';

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
    final t = AppTokens.of(context);
    final hPad = t.isDesktop ? DesktopSpacing.lg : AppSpacing.base;
    final resolvedPadding = padding ?? EdgeInsets.fromLTRB(hPad, 0, hPad, t.spacing.md);
    final titleFontSize = useCompactStyle ? t.font.xxl : t.font.h3;
    final subtitleFontSize = useCompactStyle ? t.font.xs : t.font.sm;

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
                    letterSpacing: t.isDesktop
                        ? (useCompactStyle ? -0.6 : t.typography.headingLetterSpacingSm)
                        : (useCompactStyle ? -0.3 : -0.5),
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
            _buildAction(context, t),
        ],
      ),
    );
  }

  Widget _buildAction(BuildContext context, AppTokens t) {
    final label = seeAllLabel;
    final text = (label != null && label.isNotEmpty) ? label : 'See All';
    return GestureDetector(
      onTap: onSeeAll,
      child: ShaderMask(
        shaderCallback: (bounds) =>
            AppColors.primaryGradient.createShader(bounds),
        child: Text(
          text,
          style: TextStyle(
            color: Colors.white,
            fontSize: t.font.md,
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
    final t = AppTokens.of(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(t.spacing.base, t.spacing.xl, t.spacing.base, t.spacing.base),
      child: Row(
        children: [
          if (icon != null) ...[
            ShaderMask(
              shaderCallback: (bounds) => gradient.createShader(bounds),
              child: AppIcon(icon: icon!, size: t.icon.lg, color: Colors.white),
            ),
            SizedBox(width: t.spacing.md),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShaderMask(
                  shaderCallback: (bounds) => gradient.createShader(bounds),
                  child: Text(
                    title,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: t.font.h2,
                      fontWeight: FontWeight.w700,
                      letterSpacing: AppLetterSpacing.display,
                    ),
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle!,
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: t.font.md,
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
