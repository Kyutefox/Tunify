import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../config/app_icons.dart';
import '../../../../models/song.dart';
import '../../../../shared/providers/content_settings_provider.dart';
import '../../../../shared/providers/player_state_provider.dart';
import '../../../../ui/theme/app_colors.dart';
import '../../../../ui/theme/design_tokens.dart';
import 'now_playing_indicator.dart';

class SongListTile extends ConsumerWidget {
  const SongListTile({
    super.key,
    required this.song,
    required this.onTap,
    this.index,
    this.thumbnailSize = 48,
    this.thumbnail,
    this.subtitle,
    this.trailing,
    this.contentPadding = const EdgeInsets.symmetric(
      horizontal: AppSpacing.base,
      vertical: AppSpacing.xs,
    ),
    this.highlightBackground = false,
    this.showIndexIndicator = true,
  });

  final Song song;
  final VoidCallback onTap;

  final int? index;

  final double thumbnailSize;

  final Widget? thumbnail;

  final Widget? subtitle;

  final Widget? trailing;

  final EdgeInsets contentPadding;

  final bool highlightBackground;

  final bool showIndexIndicator;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Use .select() to scope each tile's rebuild to only its own now-playing status,
    // avoiding O(n) mass rebuilds across all tiles when the current song changes.
    final isNowPlaying = ref.watch(
      playerProvider.select((s) => s.currentSong?.id == song.id),
    );
    final isActuallyPlaying = ref.watch(
      playerProvider.select((s) => s.isPlaying),
    );
    final showExplicitContent = ref.watch(showExplicitContentProvider);
    final showEBadge = showExplicitContent && song.isExplicit;

    return InkWell(
      onTap: onTap,
      child: Container(
        color: highlightBackground && isNowPlaying
            ? AppColors.primary.withValues(alpha: 0.08)
            : null,
        padding: contentPadding,
        child: Row(
          children: [
            if (index != null) ...[
              SizedBox(
                width: 24,
                child: isNowPlaying && showIndexIndicator
                    ? NowPlayingIndicator(
                        size: 16, barCount: 3, animate: isActuallyPlaying)
                    : Text(
                        '$index',
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 14,
                        ),
                      ),
              ),
              const SizedBox(width: AppSpacing.sm),
            ],

            // Keep the cover art static; move the animated visualiser to the title.
            SizedBox(
              width: thumbnailSize,
              height: thumbnailSize,
              child: thumbnail ?? _defaultThumbnail(),
            ),

            const SizedBox(width: AppSpacing.md),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isNowPlaying)
                        Padding(
                          padding:
                              const EdgeInsets.only(right: AppSpacing.xs),
                          child: SizedBox(
                            width: 10,
                            height: 10,
                            child: FittedBox(
                              fit: BoxFit.contain,
                              child: NowPlayingIndicator(
                                size: 8,
                                barCount: 3,
                                animate: isActuallyPlaying,
                              ),
                            ),
                          ),
                        ),
                      Expanded(
                        child: Text(
                          song.title,
                          style: TextStyle(
                            color: isNowPlaying
                                ? AppColors.primary
                                : AppColors.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  subtitle ??
                      Row(
                        children: [
                          if (showEBadge) ...[
                            _ExplicitBadge(),
                            const SizedBox(width: 4),
                          ],
                          Expanded(
                            child: Text(
                              song.artist,
                              style: const TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 12,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                ],
              ),
            ),

            if (trailing != null) trailing!,
          ],
        ),
      ),
    );
  }

  Widget _defaultThumbnail() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.xs),
      child: song.thumbnailUrl.isNotEmpty
          ? CachedNetworkImage(
              imageUrl: song.thumbnailUrl,
              width: thumbnailSize,
              height: thumbnailSize,
              memCacheWidth: thumbnailSize.toInt(),
              memCacheHeight: thumbnailSize.toInt(),
              fit: BoxFit.cover,
              errorWidget: (_, __, ___) => _thumbPlaceholder(),
            )
          : _thumbPlaceholder(),
    );
  }

  Widget _thumbPlaceholder() {
    return Container(
      width: thumbnailSize,
      height: thumbnailSize,
      color: AppColors.surfaceLight,
      child: Center(
        child: AppIcon(
          icon: AppIcons.musicNote,
          color: AppColors.textMuted,
          size: thumbnailSize > 50 ? 24 : 22,
        ),
      ),
    );
  }
}

class _ExplicitBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.textMuted.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(4),
      ),
      child: const Text(
        'E',
        style: TextStyle(
          color: AppColors.textMuted,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
