import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tunify/v1/data/models/song.dart';
import 'package:tunify/v1/features/player/player_state_provider.dart';
import 'package:tunify/v1/features/settings/content_settings_provider.dart';
import 'package:tunify/v1/ui/theme/app_colors.dart';
import 'package:tunify/v1/ui/theme/design_tokens.dart';
import 'package:tunify/v1/ui/theme/app_tokens.dart';
import 'package:tunify/v1/ui/screens/shared/home/home_shared.dart';
import '../player/now_playing_indicator.dart';
import 'package:tunify/v1/ui/theme/app_colors_scheme.dart';

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
    final t = AppTokens.of(context);
    final showExplicitContent = ref.watch(showExplicitContentProvider);
    final showEBadge = showExplicitContent && song.isExplicit;

    // PERF: Per-song selectors instead of NowPlayingStatus.of(ref, song.id).
    // Each tile only rebuilds when its specific song's play state changes —
    // not on every player state emission. With 100 list items, a song change
    // previously rebuilt all 100 tiles; now only 2 rebuild (old → new current).
    final isNowPlaying = ref.watch(
      playerProvider.select((s) => s.currentSong?.id == song.id),
    );
    final isActivePlaying = ref.watch(
      playerProvider.select((s) => s.isPlaying && s.currentSong?.id == song.id),
    );

    return RepaintBoundary(
      child: _buildTile(context, t, isNowPlaying, isActivePlaying, showEBadge),
    );
  }

  Widget _buildTile(
    BuildContext context,
    AppTokens t,
    bool isNowPlaying,
    bool isActivePlaying,
    bool showEBadge,
  ) {
    Widget tile = Container(
      color: highlightBackground && isNowPlaying
          ? AppColors.primary.withValues(alpha: 0.08)
          : null,
      padding: contentPadding,
      child: Row(
        children: [
          if (index != null) ...[
            SizedBox(
              width: 24,
              child: AnimatedSwitcher(
                duration: AppDuration.fast,
                transitionBuilder: (child, anim) =>
                    FadeTransition(opacity: anim, child: child),
                child: isNowPlaying && showIndexIndicator
                    ? NowPlayingIndicator(
                        key: const ValueKey('indicator'),
                        size: 16,
                        barCount: 3,
                        animate: isActivePlaying)
                    : Text(
                        '$index',
                        key: ValueKey('idx_$index'),
                        style: TextStyle(
                          color: t.mutedColor,
                          fontSize: t.font.base,
                        ),
                      ),
              ),
            ),
            SizedBox(width: t.spacing.sm),
          ],
          SizedBox(
            width: thumbnailSize,
            height: thumbnailSize,
            child: thumbnail ??
                DpiAwareThumbnail(
                  url: song.thumbnailUrl,
                  size: thumbnailSize,
                  radius: AppRadius.sm,
                ),
          ),
          SizedBox(width: t.spacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedSize(
                      duration: AppDuration.fast,
                      curve: Curves.easeOut,
                      child:
                          isNowPlaying && (index == null || !showIndexIndicator)
                              ? InlineNowPlayingDot(animate: isActivePlaying)
                              : const SizedBox.shrink(),
                    ),
                    Expanded(
                      child: AnimatedDefaultTextStyle(
                        duration: AppDuration.fast,
                        curve: Curves.easeOut,
                        style: TextStyle(
                          color: isNowPlaying
                              ? AppColors.primary
                              : AppColorsScheme.of(context).textPrimary,
                          fontSize: t.font.base,
                          fontWeight: t.typography.titleWeight,
                          height: t.typography.bodyLineHeight,
                        ),
                        child: Text(
                          song.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                subtitle ??
                    Row(
                      children: [
                        if (showEBadge) ...[
                          const ExplicitBadge(),
                          const SizedBox(width: 4),
                        ],
                        Expanded(
                          child: Text(
                            song.artist,
                            style: TextStyle(
                              color: t.mutedColor,
                              fontSize: t.font.sm,
                              height: t.typography.bodyLineHeight,
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
    );

    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: tile,
    );
  }
}
