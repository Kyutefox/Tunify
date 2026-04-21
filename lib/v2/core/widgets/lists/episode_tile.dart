import 'package:flutter/material.dart';
import 'package:tunify/v2/core/constants/app_border_radius.dart';
import 'package:tunify/v2/core/constants/app_colors.dart';
import 'package:tunify/v2/core/constants/app_icons.dart';
import 'package:tunify/v2/core/constants/app_spacing.dart';
import 'package:tunify/v2/core/theme/app_text_styles.dart';
import 'package:tunify/v2/core/widgets/art/artwork_or_gradient.dart';
import 'package:tunify/v2/core/widgets/buttons/tunify_press_feedback.dart';

/// Reusable episode tile component for displaying podcast episodes.
/// Shows artwork, title, description, individual stat, and action buttons.
/// Supports tap, long press, and action button callbacks.
class EpisodeTile extends StatelessWidget {
  const EpisodeTile({
    super.key,
    required this.title,
    required this.description,
    required this.individualStat,
    required this.imageUrl,
    this.onTap,
    this.onLongPress,
    this.onMorePressed,
    this.onLaterPressed,
    this.onDownloadPressed,
    this.onSharePressed,
    this.showActionButtons = true,
    this.showSeparator = true,
    this.isAddedToLater = false,
    this.isExplicit = false,
  });

  final String title;
  final String description;
  final String individualStat;
  final String? imageUrl;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onMorePressed;
  final VoidCallback? onLaterPressed;
  final VoidCallback? onDownloadPressed;
  final VoidCallback? onSharePressed;
  final bool showActionButtons;
  final bool showSeparator;
  final bool isAddedToLater;
  final bool isExplicit;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TunifyPressFeedback(
          borderRadius: BorderRadius.circular(AppBorderRadius.subtle),
          onTap: onTap,
          onLongPress: onLongPress ?? () {},
          child: Padding(
            padding: const EdgeInsets.symmetric(
              vertical: AppSpacing.sm,
              horizontal: AppSpacing.sm,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    ClipRRect(
                      borderRadius:
                          BorderRadius.circular(AppBorderRadius.subtle),
                      child: SizedBox(
                        width: 48,
                        height: 48,
                        child: ArtworkOrGradient(imageUrl: imageUrl),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.smMd),
                    Expanded(
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.listItemTitle,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    if (onMorePressed != null)
                      IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 28,
                          minHeight: 28,
                        ),
                        onPressed: onMorePressed,
                        icon: AppIcon(
                          icon: AppIcons.moreVert,
                          color: AppColors.silver,
                          size: 20,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.small.copyWith(
                    color: AppColors.silver,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    if (isExplicit && individualStat.trim().isNotEmpty) ...[
                      const _ExplicitBadge(),
                      const SizedBox(width: 6),
                    ],
                    Expanded(
                      child: Text(
                        individualStat,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.micro.copyWith(
                          color: AppColors.silver,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    if (showActionButtons) ...[
                      _AddButton(
                        onPressed: onLaterPressed,
                        isAdded: isAddedToLater,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      _ActionButton(
                        icon: AppIcons.download,
                        onPressed: onDownloadPressed,
                        size: 20,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      _ActionButton(
                        icon: AppIcons.share,
                        onPressed: onSharePressed,
                        size: 20,
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
        if (showSeparator)
          Container(
            height: 1,
            color: AppColors.borderGray.withValues(alpha: 0.3),
          ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    this.onPressed,
    this.size = 18,
  });

  final List<List<dynamic>> icon;
  final VoidCallback? onPressed;
  final double size;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(
        minWidth: 28,
        minHeight: 28,
      ),
      onPressed: onPressed,
      icon: AppIcon(
        icon: icon,
        color: onPressed != null
            ? AppColors.silver
            : AppColors.silver.withValues(alpha: 0.35),
        size: size,
      ),
    );
  }
}

class _AddButton extends StatelessWidget {
  const _AddButton({
    this.onPressed,
    this.isAdded = false,
  });

  final VoidCallback? onPressed;
  final bool isAdded;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(
        minWidth: 28,
        minHeight: 28,
      ),
      onPressed: onPressed,
      icon: AppIcon(
        icon: isAdded ? AppIcons.checkCircle : AppIcons.addCircle,
        color: onPressed != null
            ? (isAdded ? AppColors.brandGreen : AppColors.silver)
            : AppColors.silver.withValues(alpha: 0.35),
        size: 20,
      ),
    );
  }
}

class _ExplicitBadge extends StatelessWidget {
  const _ExplicitBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      decoration: BoxDecoration(
        color: AppColors.brandGreen.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: AppColors.brandGreen.withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      child: Text(
        'E',
        style: AppTextStyles.micro.copyWith(
          color: AppColors.brandGreen,
          fontWeight: FontWeight.w700,
          height: 1,
        ),
      ),
    );
  }
}
