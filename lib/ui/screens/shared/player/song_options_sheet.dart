import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tunify/ui/widgets/common/adaptive_menu.dart';
import 'package:tunify/ui/widgets/common/sheet.dart'
    show showAppSheet, kSheetHorizontalPadding, SheetOptionTile;
import 'package:tunify/ui/shell/shell_context.dart';
import 'package:tunify/core/constants/app_icons.dart';
import 'package:tunify/data/models/library_playlist.dart';
import 'package:tunify/data/models/song.dart';
import 'package:tunify/features/downloads/download_provider.dart';
import 'package:tunify/features/library/library_provider.dart';
import 'package:tunify/features/player/player_state_provider.dart';
import 'package:tunify/ui/theme/app_colors.dart';
import 'package:tunify/ui/theme/design_tokens.dart';
import 'package:tunify/ui/theme/app_routes.dart';
import '../library/add_to_playlist_sheet.dart';
import 'package:tunify/ui/screens/shared/library/library_playlist_screen.dart';

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
  VoidCallback? onRemoveFromPlaylist,
  int? queueIndex,
  Rect? anchorRect,
  BuildContext? buttonContext,
}) {
  if (_isDesktop()) {
    _showDesktopSongMenu(
      context,
      ref: ref,
      song: song,
      extraOptions: extraOptions,
      showAddToPlaylist: showAddToPlaylist,
      onRemoveFromPlaylist: onRemoveFromPlaylist,
      queueIndex: queueIndex,
      anchorRect: anchorRect ?? _rectFromContext(buttonContext ?? context),
    );
    return;
  }
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

void _showDesktopSongMenu(
  BuildContext context, {
  required WidgetRef ref,
  required Song song,
  List<SongOptionExtra> extraOptions = const [],
  bool showAddToPlaylist = true,
  VoidCallback? onRemoveFromPlaylist,
  int? queueIndex,
  Rect? anchorRect,
}) {
  final effectiveRect = anchorRect ?? _rectFromContext(context);

  // Capture navigator before the menu opens — the context may be deactivated
  // by the time a menu item's onTap fires (e.g. search screen gets popped).
  // Use rootNavigator: true so we always get a valid navigator for sheets/dialogs.
  final navigator = Navigator.of(context, rootNavigator: true);
  // Capture the shell's content-navigator push callback so Artist/Album pages
  // open inside the desktop content panel instead of full-screen.
  // Use getElementForInheritedWidgetOfExactType (read-only, no rebuild
  // subscription) because this is a one-shot call, not a build method.
  final pushDetail = (context
          .getElementForInheritedWidgetOfExactType<ShellContext>()
          ?.widget as ShellContext?)
      ?.onPushDetail;

  final downloadService = ref.read(downloadServiceProvider);
  final isDownloaded = downloadService.isDownloaded(song.id);
  final isLocalSong = song.id.startsWith('device_');
  final isLiked = ref.read(libraryProvider).likedSongIds.contains(song.id);
  final queue = ref.read(playerProvider).queue;
  final effectiveQueueIndex =
      queueIndex ?? queue.indexWhere((s) => s.id == song.id);
  final isInQueue = effectiveQueueIndex >= 0;

  // Build folder-aware playlist sub-entries for the hover submenu (desktop only).
  final playlists = ref.read(libraryPlaylistsProvider);
  final folders = ref.read(libraryFoldersProvider);

  // IDs of playlists that belong to any folder.
  final folderedIds = {
    for (final f in folders)
      for (final id in f.playlistIds) id,
  };

  AppMenuEntry playlistEntry(LibraryPlaylist p) {
    final alreadyIn = p.songs.any((s) => s.id == song.id);
    return AppMenuEntry(
      icon: alreadyIn ? AppIcons.checkCircle : AppIcons.musicNote,
      label: p.name,
      color: alreadyIn ? AppColors.primary : null,
      onTap: () =>
          ref.read(libraryProvider.notifier).addSongsToPlaylist(p.id, [song]),
    );
  }

  final idToPlaylist = {for (final p in playlists) p.id: p};

  final playlistSubEntries = <AppMenuEntry>[
    // Folders first — each opens a sub-sub-menu with its playlists.
    for (final f in folders)
      AppMenuEntry(
        icon: AppIcons.folder,
        label: f.name,
        onTap: () {},
        subEntries: f.playlistIds
            .map((id) => idToPlaylist[id])
            .whereType<LibraryPlaylist>()
            .map(playlistEntry)
            .toList(),
      ),
    // Then playlists not in any folder.
    for (final p in playlists)
      if (!folderedIds.contains(p.id)) playlistEntry(p),
  ];

  final entries = <AppMenuEntry>[
    AppMenuEntry(
      icon: AppIcons.favourite,
      label: isLiked ? 'Unlike' : 'Like',
      color: isLiked ? AppColors.loveThemeColorFor(song.id) : null,
      onTap: () => ref.read(libraryProvider.notifier).toggleLiked(song),
    ),
    if (showAddToPlaylist || onRemoveFromPlaylist != null)
      AppMenuEntry(
        icon: onRemoveFromPlaylist != null
            ? AppIcons.removeCircleOutline
            : AppIcons.playlistAdd,
        label: onRemoveFromPlaylist != null
            ? 'Remove from playlist'
            : 'Add to playlist',
        // When removing from playlist, use a direct tap action.
        // When adding, show a hover submenu with the playlist list.
        onTap: onRemoveFromPlaylist ?? () {},
        subEntries: onRemoveFromPlaylist == null ? playlistSubEntries : null,
      ),
    AppMenuEntry(
      icon: isInQueue ? AppIcons.removeCircleOutline : AppIcons.queueMusic,
      label: isInQueue ? 'Remove from queue' : 'Add to queue',
      onTap: () {
        if (isInQueue) {
          ref
              .read(playerProvider.notifier)
              .removeFromQueue(effectiveQueueIndex);
        } else {
          ref.read(playerProvider.notifier).addToQueue(song);
        }
      },
    ),
    if (!isLocalSong)
      AppMenuEntry(
        icon: isDownloaded ? AppIcons.checkCircle : AppIcons.download,
        label: isDownloaded ? 'Remove download' : 'Download',
        onTap: () {
          if (isDownloaded) {
            ref.read(downloadServiceProvider).removeDownload(song.id);
          } else {
            ref.read(downloadServiceProvider).enqueue(song);
          }
        },
      ),
    const AppMenuEntry.divider(),
    AppMenuEntry(
      icon: AppIcons.artist,
      label: 'Go to Artist',
      showChevron: true,
      onTap: () {
        final page = LibraryPlaylistScreen.artist(
          artistName: song.artist,
          thumbnailUrl: song.thumbnailUrl,
          browseId: song.artistBrowseId,
        );
        if (pushDetail != null) {
          pushDetail(page);
        } else {
          navigator.push(appPageRoute<void>(builder: (_) => page));
        }
      },
    ),
    AppMenuEntry(
      icon: AppIcons.album,
      label: 'Go to Album',
      showChevron: true,
      onTap: () {
        final page = LibraryPlaylistScreen.album(
          songTitle: song.title,
          artistName: song.artist,
          thumbnailUrl: song.thumbnailUrl,
          browseId: song.albumBrowseId,
          name: song.albumName,
          songId: song.id,
        );
        if (pushDetail != null) {
          pushDetail(page);
        } else {
          navigator.push(appPageRoute<void>(builder: (_) => page));
        }
      },
    ),
    for (final extra in extraOptions)
      AppMenuEntry(icon: extra.icon, label: extra.label, onTap: extra.onTap),
  ];

  showAdaptiveMenu(
    context,
    title: song.title,
    entries: entries,
    anchorRect: effectiveRect,
    forceDesktop: true,
  );
}

bool _isDesktop() {
  return defaultTargetPlatform == TargetPlatform.macOS ||
      defaultTargetPlatform == TargetPlatform.windows ||
      defaultTargetPlatform == TargetPlatform.linux;
}

Rect? _rectFromContext(BuildContext context) {
  final obj = context.findRenderObject();
  if (obj is RenderBox && obj.hasSize) {
    return obj.localToGlobal(Offset.zero) & obj.size;
  }
  return null;
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
                        fontSize: AppFontSize.xl,
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
            color: Colors.white.withValues(alpha: 0.08),
            height: 1,
          ),
          const SizedBox(height: AppSpacing.md),
          _QuickActionRow(
            songId: song.id,
            isDownloaded: isDownloaded,
            isLocalSong: isLocalSong,
            isLiked: isLiked,
            showPlaylist: showAddToPlaylist || onRemoveFromPlaylist != null,
            isRemoveFromPlaylist: onRemoveFromPlaylist != null,
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
          SheetOptionTile(
            icon:
                isInQueue ? AppIcons.removeCircleOutline : AppIcons.queueMusic,
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
    required this.showPlaylist,
    this.isRemoveFromPlaylist = false,
    this.onDownload,
    required this.onPlaylist,
    required this.onLiked,
  });

  final String songId;
  final bool isDownloaded;
  final bool isLocalSong;
  final bool isLiked;
  final bool showPlaylist;
  final bool isRemoveFromPlaylist;
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
                      : AppColors.textSecondary,
                  label: 'Download',
                  isActive: isDownloaded,
                  onTap: onDownload ?? () {},
                ),
        ),
        if (showPlaylist)
          Expanded(
            child: _QuickActionButton(
              icon: isRemoveFromPlaylist
                  ? AppIcons.removeCircleOutline
                  : AppIcons.playlistAdd,
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
                      : AppColors.glassWhite,
                  border: Border.all(
                    color: isActive
                        ? AppColors.primary.withValues(alpha: 0.35)
                        : AppColors.glassBorder,
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
                style: const TextStyle(
                  color: AppColors.textSecondary,
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
