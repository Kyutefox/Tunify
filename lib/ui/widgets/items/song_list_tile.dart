import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tunify/core/constants/app_icons.dart';
import 'package:tunify/data/models/song.dart';
import 'package:tunify/features/settings/content_settings_provider.dart';
import 'package:tunify/ui/theme/app_colors.dart';
import 'package:tunify/ui/theme/design_tokens.dart';
import 'package:tunify/ui/theme/desktop_tokens.dart';
import '../../../../ui/screens/home/home_shared.dart';
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
    final t = AppTokens.of(context);
    final status = NowPlayingStatus.of(ref, song.id);
    final showExplicitContent = ref.watch(showExplicitContentProvider);
    final showEBadge = showExplicitContent && song.isExplicit;

    Widget tile = Container(
      color: highlightBackground && status.isNowPlaying
          ? AppColors.primary.withValues(alpha: 0.08)
          : null,
      padding: contentPadding,
      child: Row(
        children: [
          if (index != null) ...[
            SizedBox(
              width: 24,
              child: status.isNowPlaying && showIndexIndicator
                  ? NowPlayingIndicator(size: 16, barCount: 3, animate: status.isPlaying)
                  : Text(
                      '$index',
                      style: TextStyle(
                        color: t.mutedColor,
                        fontSize: t.font.base,
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
                  placeholder: _thumbPlaceholder(),
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
                    if (status.isNowPlaying && (index == null || !showIndexIndicator))
                      InlineNowPlayingDot(animate: status.isPlaying),
                    Expanded(
                      child: Text(
                        song.title,
                        style: TextStyle(
                          color: status.isNowPlaying
                              ? AppColors.primary
                              : AppColors.textPrimary,
                          fontSize: t.font.base,
                          fontWeight: t.typography.titleWeight,
                          height: t.typography.bodyLineHeight,
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

    if (t.isDesktop) {
      return _HoverTile(child: InkWell(onTap: onTap, borderRadius: BorderRadius.circular(AppRadius.sm), child: tile));
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: tile,
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

/// Subtle hover highlight for desktop list rows.
class _HoverTile extends StatefulWidget {
  const _HoverTile({required this.child});
  final Widget child;

  @override
  State<_HoverTile> createState() => _HoverTileState();
}

class _HoverTileState extends State<_HoverTile> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        decoration: BoxDecoration(
          color: _hovered ? AppColors.hoverOverlay : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        child: widget.child,
      ),
    );
  }
}
