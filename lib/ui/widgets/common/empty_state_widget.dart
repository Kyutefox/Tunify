import 'package:flutter/material.dart';

import 'package:tunify/core/constants/app_icons.dart';
import 'package:tunify/ui/theme/app_colors.dart';
import 'package:tunify/ui/theme/design_tokens.dart';
import 'package:tunify/ui/widgets/common/button.dart';

enum EmptyStateType {
  empty,
  noResults,
  error,
  loading,
}

class EmptyStateWidget extends StatelessWidget {
  const EmptyStateWidget({
    super.key,
    required this.type,
    this.icon,
    this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
    this.query,
    this.padding,
  }) : assert(
          type != EmptyStateType.noResults || query != null || title != null,
          'noResults type requires query or title',
        );

  final EmptyStateType type;
  final List<List<dynamic>>? icon;
  final String? title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;
  final String? query;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final resolvedPadding =
        padding ?? const EdgeInsets.symmetric(horizontal: AppSpacing.xxl);

    switch (type) {
      case EmptyStateType.empty:
        return _buildEmptyState(context, resolvedPadding);
      case EmptyStateType.noResults:
        return _buildNoResults(context, resolvedPadding);
      case EmptyStateType.error:
        return _buildErrorState(context, resolvedPadding);
      case EmptyStateType.loading:
        return const Center(
            child: CircularProgressIndicator(color: AppColors.primary));
    }
  }

  Widget _buildEmptyState(BuildContext context, EdgeInsetsGeometry padding) {
    final iconWidget = icon ?? AppIcons.musicNote;
    final resolvedTitle = title ?? 'Nothing here yet';

    return Center(
      child: Padding(
        padding: padding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppIcon(icon: iconWidget, color: AppColors.textMuted, size: 48),
            const SizedBox(height: AppSpacing.lg),
            Text(
              resolvedTitle,
              style: const TextStyle(
                  color: AppColors.textMuted, fontSize: AppFontSize.xl),
              textAlign: TextAlign.center,
            ),
            if (subtitle != null && subtitle!.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                subtitle!,
                style: TextStyle(
                    color: AppColors.textMuted.withValues(alpha: 0.8),
                    fontSize: AppFontSize.base),
                textAlign: TextAlign.center,
              ),
            ],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: AppSpacing.xl),
              AppButton(
                  label: actionLabel!,
                  onPressed: onAction!,
                  variant: AppButtonVariant.filled,
                  height: 44),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildNoResults(BuildContext context, EdgeInsetsGeometry padding) {
    final resolvedTitle = title ??
        (query != null ? 'No results for "$query"' : 'No results found');

    return Center(
      child: Padding(
        padding: padding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppIcon(
                icon: AppIcons.search, color: AppColors.textMuted, size: 48),
            const SizedBox(height: AppSpacing.lg),
            Text(
              resolvedTitle,
              style: const TextStyle(
                  color: AppColors.textMuted, fontSize: AppFontSize.xl),
              textAlign: TextAlign.center,
            ),
            if (subtitle != null && subtitle!.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                subtitle!,
                style: TextStyle(
                    color: AppColors.textMuted.withValues(alpha: 0.8),
                    fontSize: AppFontSize.base),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, EdgeInsetsGeometry padding) {
    return Center(
      child: Padding(
        padding: padding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppIcon(
                icon: AppIcons.errorOutline,
                color: AppColors.textMuted,
                size: 48),
            const SizedBox(height: AppSpacing.lg),
            Text(
              title ?? 'Something went wrong',
              style: const TextStyle(
                  color: AppColors.textMuted, fontSize: AppFontSize.xl),
              textAlign: TextAlign.center,
            ),
            if (subtitle != null && subtitle!.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                subtitle!,
                style: TextStyle(
                    color: AppColors.textMuted.withValues(alpha: 0.8),
                    fontSize: AppFontSize.base),
                textAlign: TextAlign.center,
              ),
            ],
            if (onAction != null) ...[
              const SizedBox(height: AppSpacing.xl),
              AppButton(
                  label: actionLabel ?? 'Retry',
                  onPressed: onAction,
                  variant: AppButtonVariant.text),
            ],
          ],
        ),
      ),
    );
  }
}
