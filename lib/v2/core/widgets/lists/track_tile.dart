import 'package:flutter/material.dart';
import 'package:tunify/v2/core/constants/app_border_radius.dart';
import 'package:tunify/v2/core/constants/app_colors.dart';
import 'package:tunify/v2/core/constants/app_icons.dart';
import 'package:tunify/v2/core/constants/app_spacing.dart';
import 'package:tunify/v2/core/theme/app_text_styles.dart';
import 'package:tunify/v2/core/widgets/art/artwork_or_gradient.dart';
import 'package:tunify/v2/core/widgets/buttons/tunify_press_feedback.dart';

/// Reusable track tile component for displaying tracks across the app.
/// Shows artwork, title, subtitle, and a more options icon.
/// Supports tap, long press, and more icon press callbacks.
class TrackTile extends StatelessWidget {
  const TrackTile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.imageUrl,
    this.isArtist = false,
    this.isVerified = false,
    this.onTap,
    this.onLongPress,
    this.onMorePressed,
    this.showMoreIcon = true,
    this.enableMoreIcon = true,
  });

  final String title;
  final String subtitle;
  final String? imageUrl;
  final bool isArtist;
  final bool isVerified;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onMorePressed;
  final bool showMoreIcon;
  final bool enableMoreIcon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 64,
      child: TunifyPressFeedback(
        borderRadius: BorderRadius.circular(AppBorderRadius.subtle),
        onTap: onTap,
        onLongPress: onLongPress ?? () {},
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(
                isArtist ? AppBorderRadius.fullPill : AppBorderRadius.subtle,
              ),
              child: SizedBox(
                width: 48,
                height: 48,
                child: ArtworkOrGradient(imageUrl: imageUrl),
              ),
            ),
            const SizedBox(width: AppSpacing.smMd),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.listItemTitle,
                        ),
                      ),
                      if (isVerified) ...[
                        const SizedBox(width: 4),
                        AppIcon(
                          icon: AppIcons.verified,
                          color: AppColors.announcementBlue,
                          size: 12,
                        ),
                      ],
                    ],
                  ),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.small,
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            if (showMoreIcon)
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(
                  minWidth: 28,
                  minHeight: 28,
                ),
                onPressed: enableMoreIcon ? onMorePressed : null,
                icon: AppIcon(
                  icon: AppIcons.moreVert,
                  color: enableMoreIcon
                      ? AppColors.silver
                      : AppColors.silver.withValues(alpha: 0.35),
                  size: 20,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
