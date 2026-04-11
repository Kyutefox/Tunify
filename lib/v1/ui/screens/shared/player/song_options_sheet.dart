import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tunify/v1/features/device/device_music_provider.dart';
import 'package:tunify/v1/ui/widgets/common/sheet.dart'
    show showAppSheet, kSheetHorizontalPadding, SheetOptionTile;
import 'package:tunify/v1/core/constants/app_icons.dart';
import 'package:tunify/v1/data/models/song.dart';
import 'package:tunify/v1/features/downloads/download_provider.dart';
import 'package:tunify/v1/features/library/library_provider.dart';
import 'package:tunify/v1/features/player/player_state_provider.dart';
import 'package:tunify/v1/ui/theme/app_colors.dart';
import 'package:tunify/v1/ui/theme/design_tokens.dart';
import 'package:tunify/v1/ui/theme/app_routes.dart';
import '../library/add_to_playlist_sheet.dart';
import 'package:tunify/v1/ui/screens/shared/library/library_playlist_screen.dart';
import 'package:tunify/v1/ui/theme/app_colors_scheme.dart';

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
  required WidgetRef ref,
  List<SongOptionExtra> extraOptions = const [],
  bool showAddToPlaylist = true,
  bool showLike = true,
  bool showAddToQueue = true,
  bool showGoToArtist = true,
  bool showGoToAlbum = true,
  VoidCallback? onRemoveFromPlaylist,
  int? queueIndex,
  Rect? anchorRect,
  BuildContext? buttonContext,
  bool isDownloads = false,
  bool isLocalFiles = false,
}) {
  showAppSheet(
    context,
    child: _SongOptionsContent(
      song: song,
      extraOptions: extraOptions,
      showAddToPlaylist: showAddToPlaylist,
      showLike: showLike,
      showAddToQueue: showAddToQueue,
      showGoToArtist: showGoToArtist,
      showGoToAlbum: showGoToAlbum,
      onRemoveFromPlaylist: onRemoveFromPlaylist,
      queueIndex: queueIndex,
      isDownloads: isDownloads,
      isLocalFiles: isLocalFiles,
    ),
  );
}

class _SongOptionsContent extends ConsumerWidget {
  const _SongOptionsContent({
    required this.song,
    this.extraOptions = const [],
    this.showAddToPlaylist = true,
    this.showLike = true,
    this.showAddToQueue = true,
    this.showGoToArtist = true,
    this.showGoToAlbum = true,
    this.onRemoveFromPlaylist,
    this.queueIndex,
    this.isDownloads = false,
    this.isLocalFiles = false,
  });

  final Song song;
  final List<SongOptionExtra> extraOptions;
  final bool showAddToPlaylist;
  final bool showLike;
  final bool showAddToQueue;
  final bool showGoToArtist;
  final bool showGoToAlbum;
  final VoidCallback? onRemoveFromPlaylist;
  final int? queueIndex;
  final bool isDownloads;
  final bool isLocalFiles;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentSong = ref.watch(currentSongProvider);
    final songForNav =
        currentSong != null && currentSong.id == song.id ? currentSong : song;
    final downloadService = ref.watch(downloadServiceProvider);
    final isDownloaded = downloadService.isDownloaded(song.id);
    final isLocalSong = song.id.startsWith('device_');
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
                    color: AppColorsScheme.of(context).surfaceLight,
                    child: AppIcon(
                        icon: AppIcons.musicNote,
                        color: AppColorsScheme.of(context).textMuted,
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
                      style: TextStyle(
                        color: AppColorsScheme.of(context).textPrimary,
                        fontSize: AppFontSize.xl,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      song.artist,
                      style: TextStyle(
                        color: AppColorsScheme.of(context).textSecondary,
                        fontSize: AppFontSize.md,
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
            color: AppColorsScheme.of(context).surfaceHighlight,
            height: 1,
          ),
          const SizedBox(height: AppSpacing.md),
          _QuickActionRow(
            songId: song.id,
            isDownloaded: isDownloaded,
            isLocalSong: isLocalSong,
            isLiked: isLiked,
            showLike: showLike,
            showPlaylist: showAddToPlaylist ||
                onRemoveFromPlaylist != null ||
                isDownloads ||
                isLocalFiles,
            isRemoveFromPlaylist:
                onRemoveFromPlaylist != null || isDownloads || isLocalFiles,
            isDownloads: isDownloads,
            isLocalFiles: isLocalFiles,
            onDownload: isLocalSong
                ? null
                : () {
                    Navigator.of(context).pop();
                    if (isDownloaded) {
                      ref.read(downloadServiceProvider).removeDownload(song.id);
                    } else {
                      ref.read(downloadServiceProvider).enqueue(song);
                    }
                  },
            onPlaylist: () {
              Navigator.of(context).pop();
              if (isDownloads) {
                ref.read(downloadServiceProvider).removeDownload(song.id);
              } else if (isLocalFiles) {
                final deviceState = ref.read(deviceMusicProvider);
                final filePath = deviceState.pathMap[song.id];
                if (filePath != null) {
                  try {
                    final file = File(filePath);
                    file.deleteSync();
                  } catch (_) {
                    // File might have been moved or deleted already
                  }
                  ref.read(deviceMusicProvider.notifier).loadSongs();
                }
              } else if (onRemoveFromPlaylist != null) {
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
            color: AppColorsScheme.of(context).surfaceHighlight,
            height: 1,
          ),
          const SizedBox(height: AppSpacing.sm),
          if (showGoToArtist)
            SheetOptionTile(
              icon: AppIcons.artist,
              label: 'Go to Artist',
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(
                  appPageRoute<void>(
                    builder: (_) => LibraryPlaylistScreen.artist(
                      artistName: songForNav.artist,
                      thumbnailUrl: songForNav.thumbnailUrl,
                      browseId: songForNav.artistBrowseId,
                    ),
                  ),
                );
              },
            ),
          if (showGoToAlbum)
            SheetOptionTile(
              icon: AppIcons.album,
              label: 'Go to Album',
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(
                  appPageRoute<void>(
                    builder: (_) => LibraryPlaylistScreen.album(
                      songTitle: songForNav.title,
                      artistName: songForNav.artist,
                      thumbnailUrl: songForNav.thumbnailUrl,
                      browseId: songForNav.albumBrowseId,
                      name: songForNav.albumName,
                      songId: songForNav.id,
                    ),
                  ),
                );
              },
            ),
          if (showAddToQueue)
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
                  ref.read(playerProvider.notifier).addToQueue(song);
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
    required this.isLocalSong,
    required this.isLiked,
    required this.showLike,
    required this.showPlaylist,
    this.isRemoveFromPlaylist = false,
    this.isDownloads = false,
    this.isLocalFiles = false,
    this.onDownload,
    required this.onPlaylist,
    required this.onLiked,
  });

  final String songId;
  final bool isDownloaded;
  final bool isLocalSong;
  final bool isLiked;
  final bool showLike;
  final bool showPlaylist;
  final bool isRemoveFromPlaylist;
  final bool isDownloads;
  final bool isLocalFiles;
  final VoidCallback? onDownload;
  final VoidCallback onPlaylist;
  final VoidCallback onLiked;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: isLocalSong
              ? _QuickActionButton(
                  icon: AppIcons.smartphone,
                  iconColor: AppColors.primary,
                  label: 'On Device',
                  isActive: true,
                  onTap: () {},
                )
              : _QuickActionButton(
                  icon: isDownloaded ? AppIcons.checkCircle : AppIcons.download,
                  iconColor: isDownloaded
                      ? AppColors.primary
                      : AppColorsScheme.of(context).textSecondary,
                  label: 'Download',
                  isActive: isDownloaded,
                  onTap: onDownload ?? () {},
                ),
        ),
        if (showPlaylist)
          Expanded(
            child: _QuickActionButton(
              icon: isRemoveFromPlaylist || isDownloads || isLocalFiles
                  ? AppIcons.removeCircleOutline
                  : AppIcons.playlistAdd,
              iconColor: AppColorsScheme.of(context).textSecondary,
              label: isDownloads
                  ? 'Remove'
                  : (isLocalFiles
                      ? 'Remove'
                      : (isRemoveFromPlaylist ? 'Remove' : 'Playlist')),
              onTap: onPlaylist,
            ),
          ),
        if (showLike)
          Expanded(
            child: _QuickActionButton(
              iconWidget: FavouriteIcon(
                isLiked: isLiked,
                songId: songId,
                size: 26,
                emptyColor: AppColorsScheme.of(context).textSecondary,
              ),
              label: isLiked ? 'Liked' : 'Like',
              isActive: isLiked,
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
    this.isActive = false,
  }) : assert(icon != null && iconColor != null || iconWidget != null,
            'Provide either icon+iconColor or iconWidget');

  final List<List<dynamic>>? icon;
  final Color? iconColor;
  final Widget? iconWidget;
  final String label;
  final VoidCallback onTap;
  final bool isActive;

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
                  color: isActive
                      ? AppColors.primary.withValues(alpha: 0.15)
                      : AppColorsScheme.of(context).surfaceLight,
                  border: Border.all(
                    color: isActive
                        ? AppColors.primary.withValues(alpha: 0.35)
                        : AppColorsScheme.of(context).surfaceHighlight,
                    width: 1,
                  ),
                ),
                child: Center(
                  child: iconWidget ??
                      AppIcon(
                        icon: icon!,
                        color: iconColor!,
                        size: _iconSize,
                      ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                label,
                style: TextStyle(
                  color: AppColorsScheme.of(context).textSecondary,
                  fontSize: AppFontSize.sm,
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
