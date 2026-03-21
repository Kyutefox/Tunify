import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../config/app_icons.dart';
import '../../theme/app_colors.dart';
import '../../theme/design_tokens.dart';

/// A compact tappable list tile for library items that have a thumbnail
/// (albums, artists) or an icon placeholder (downloads, etc.).
///
/// Used by the desktop sidebar and can be reused wherever a thumbnail-based
/// library row is needed.
class LibraryThumbnailTile extends StatelessWidget {
  const LibraryThumbnailTile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.thumbnailUrl,
    this.isCircle = false,
    this.icon,
  });

  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final String? thumbnailUrl;

  /// When true, the thumbnail is clipped as a circle (for artists).
  final bool isCircle;

  /// When provided, renders an icon placeholder instead of a network image.
  final List<List<dynamic>>? icon;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: Padding(
          padding: const EdgeInsets.symmetric(
              vertical: AppSpacing.sm, horizontal: AppSpacing.sm),
          child: Row(
            children: [
              icon != null
                  ? _IconThumb(icon: icon!)
                  : _Thumb(thumbnailUrl: thumbnailUrl, isCircle: isCircle),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: AppFontSize.lg,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: AppColors.textMuted, fontSize: AppFontSize.md),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _IconThumb extends StatelessWidget {
  const _IconThumb({required this.icon});
  final List<List<dynamic>> icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Center(
        child: AppIcon(icon: icon, color: AppColors.textMuted, size: 26),
      ),
    );
  }
}

class _Thumb extends StatelessWidget {
  const _Thumb({this.thumbnailUrl, this.isCircle = false});

  final String? thumbnailUrl;
  final bool isCircle;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius:
          BorderRadius.circular(isCircle ? 26 : AppRadius.sm),
      child: Container(
        width: 52,
        height: 52,
        color: AppColors.surfaceLight,
        child: thumbnailUrl != null
            ? CachedNetworkImage(
                imageUrl: thumbnailUrl!,
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) => _icon,
              )
            : _icon,
      ),
    );
  }

  Widget get _icon => Center(
        child: AppIcon(
          icon: AppIcons.musicNote,
          color: AppColors.textMuted,
          size: 26,
        ),
      );
}
