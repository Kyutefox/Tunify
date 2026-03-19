import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../components/ui/sheet.dart' show showAppSheet, kSheetHorizontalPadding, SheetOptionTile;
import '../../../config/app_icons.dart';
import '../../../models/song.dart';
import '../../../shared/providers/download_provider.dart';
import '../../../shared/providers/library_provider.dart';
import '../../../shared/providers/player_state_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/design_tokens.dart';
import '../library/add_to_playlist_sheet.dart';
import 'artist_page.dart';
import 'album_page.dart';

class SongOptionExtra {
  final List<List<dynamic>> icon;
  final String label;
  final VoidCallback onTap;

  const SongOptionExtra({
    required this.icon,
    required this.label,
    required this.onTap,
  });
}

void showSongOptionsSheet(
  BuildContext context, {
  required Song song,
  List<SongOptionExtra> extraOptions = const [],
  bool showAddToPlaylist = true,
  VoidCallback? onRemoveFromPlaylist,
  int? queueIndex,
}) {
  showAppSheet(
    context,
    child: _SongOptionsContent(
      song: song,
      extraOptions: extraOptions,
      showAddToPlaylist: showAddToPlaylist,
      onRemoveFromPlaylist: onRemoveFromPlaylist,
      queueIndex: queueIndex,
    ),
  );
}

class _SongOptionsContent extends ConsumerWidget {
  const _SongOptionsContent({
    required this.song,
    this.extraOptions = const [],
    this.showAddToPlaylist = true,
    this.onRemoveFromPlaylist,
    this.queueIndex,
  });

  final Song song;
  final List<SongOptionExtra> extraOptions;
  final bool showAddToPlaylist;
  final VoidCallback? onRemoveFromPlaylist;
  final int? queueIndex;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentSong = ref.watch(currentSongProvider);
    final songForNav = currentSong != null && currentSong.id == song.id
        ? currentSong
        : song;
    final downloadService = ref.watch(downloadServiceProvider);
    final isDownloaded = downloadService.isDownloaded(song.id);
    final likedIds = ref.watch(libraryProvider.select((s) => s.likedSongIds));
    final isLiked = likedIds.contains(song.id);
    final queue = ref.watch(playerProvider.select((s) => s.queue));
    final effectiveQueueIndex =
        queueIndex ?? queue.indexWhere((s) => s.id == song.id);
    final isInQueue = effectiveQueueIndex >= 0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: kSheetHorizontalPadding),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.sm),
              child: CachedNetworkImage(
                imageUrl: song.thumbnailUrl,
                width: 48,
                height: 48,
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) => Container(
                  width: 48,
                  height: 48,
                  color: AppColors.surfaceLight,
                  child: AppIcon(
                      icon: AppIcons.musicNote,
                      color: AppColors.textMuted,
                      size: 24),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    song.title,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    song.artist,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
          const SizedBox(height: AppSpacing.lg),
          Divider(
            color: Colors.white.withValues(alpha: 0.08),
            height: 1,
          ),
          const SizedBox(height: AppSpacing.md),
          _QuickActionRow(
            songId: song.id,
            isDownloaded: isDownloaded,
            isLiked: isLiked,
            showPlaylist: showAddToPlaylist || onRemoveFromPlaylist != null,
            isRemoveFromPlaylist: onRemoveFromPlaylist != null,
            onDownload: () {
              Navigator.of(context).pop();
              if (isDownloaded) {
                ref.read(downloadServiceProvider).removeDownload(song.id);
              } else {
                ref.read(downloadServiceProvider).enqueue(song);
              }
            },
            onPlaylist: () {
              Navigator.of(context).pop();
              if (onRemoveFromPlaylist != null) {
                onRemoveFromPlaylist!();
              } else {
                showAddToPlaylistSheet(context, song: song);
              }
            },
            onLiked: () {
              Navigator.of(context).pop();
              ref.read(libraryProvider.notifier).toggleLiked(song);
            },
          ),
          const SizedBox(height: AppSpacing.lg),
          Divider(
            color: Colors.white.withValues(alpha: 0.08),
            height: 1,
          ),
          const SizedBox(height: AppSpacing.sm),
          SheetOptionTile(
            icon: AppIcons.artist,
            label: 'Go to Artist',
            onTap: () {
              Navigator.of(context).pop();
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => ArtistPage(
                    artistName: songForNav.artist,
                    thumbnailUrl: songForNav.thumbnailUrl,
                    artistBrowseId: songForNav.artistBrowseId,
                  ),
                ),
              );
            },
          ),
          SheetOptionTile(
            icon: AppIcons.album,
            label: 'Go to Album',
            onTap: () {
              Navigator.of(context).pop();
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => AlbumPage(
                    songTitle: songForNav.title,
                    artistName: songForNav.artist,
                    thumbnailUrl: songForNav.thumbnailUrl,
                    albumBrowseId: songForNav.albumBrowseId,
                    albumName: songForNav.albumName,
                    songId: songForNav.id,
                  ),
                ),
              );
            },
          ),
          SheetOptionTile(
            icon: isInQueue
                ? AppIcons.removeCircleOutline
                : AppIcons.queueMusic,
            label: isInQueue ? 'Remove from queue' : 'Add to queue',
            onTap: () {
              Navigator.of(context).pop();
              if (isInQueue) {
                ref
                    .read(playerProvider.notifier)
                    .removeFromQueue(effectiveQueueIndex);
              } else {
                ref
                    .read(playerProvider.notifier)
                    .addToQueue(song);
              }
            },
            showChevron: false,
          ),
          for (final extra in extraOptions)
            SheetOptionTile(
              icon: extra.icon,
              label: extra.label,
              onTap: () {
                Navigator.of(context).pop();
                extra.onTap();
              },
            ),
        ],
      ),
    );
  }
}

class _QuickActionRow extends StatelessWidget {
  const _QuickActionRow({
    required this.songId,
    required this.isDownloaded,
    required this.isLiked,
    required this.showPlaylist,
    this.isRemoveFromPlaylist = false,
    required this.onDownload,
    required this.onPlaylist,
    required this.onLiked,
  });

  final String songId;
  final bool isDownloaded;
  final bool isLiked;
  final bool showPlaylist;
  final bool isRemoveFromPlaylist;
  final VoidCallback onDownload;
  final VoidCallback onPlaylist;
  final VoidCallback onLiked;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _QuickActionButton(
            icon: isDownloaded ? AppIcons.checkCircle : AppIcons.download,
            iconColor: isDownloaded ? AppColors.primary : AppColors.textSecondary,
            label: 'Download',
            onTap: onDownload,
          ),
        ),
        if (showPlaylist)
          Expanded(
            child: _QuickActionButton(
              icon: isRemoveFromPlaylist ? AppIcons.removeCircleOutline : AppIcons.playlistAdd,
              iconColor: AppColors.textSecondary,
              label: isRemoveFromPlaylist ? 'Remove' : 'Playlist',
              onTap: onPlaylist,
            ),
          ),
        Expanded(
          child: _QuickActionButton(
            iconWidget: FavouriteIcon(
              isLiked: isLiked,
              songId: songId,
              size: 26,
              emptyColor: AppColors.textSecondary,
            ),
            label: isLiked ? 'Liked' : 'Like',
            onTap: onLiked,
          ),
        ),
      ],
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  const _QuickActionButton({
    this.icon,
    this.iconColor,
    this.iconWidget,
    required this.label,
    required this.onTap,
  }) : assert(icon != null && iconColor != null || iconWidget != null,
         'Provide either icon+iconColor or iconWidget');

  final List<List<dynamic>>? icon;
  final Color? iconColor;
  final Widget? iconWidget;
  final String label;
  final VoidCallback onTap;

  static const double _circleSize = 44.0;
  static const double _iconSize = 26.0;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        splashColor: AppColors.primary.withValues(alpha: 0.12),
        highlightColor: AppColors.primary.withValues(alpha: 0.06),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: _circleSize,
                height: _circleSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.glassWhite,
                  border: Border.all(
                    color: AppColors.glassBorder,
                    width: 1,
                  ),
                ),
                child: Center(
                  child: iconWidget ?? AppIcon(
                    icon: icon!,
                    color: iconColor!,
                    size: _iconSize,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

