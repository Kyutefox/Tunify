import 'dart:math';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:on_audio_query_pluse/on_audio_query.dart';

import 'package:tunify/data/models/library_playlist.dart' show ShuffleMode;
import 'package:tunify/ui/widgets/common/button.dart';
import 'package:tunify/ui/widgets/common/confirm_dialog.dart';
import 'package:tunify/ui/widgets/common/sheet.dart';
import 'package:tunify/ui/widgets/library/song_list_tile.dart';
import 'package:tunify/ui/widgets/player/now_playing_indicator.dart';
import 'package:tunify/core/constants/app_icons.dart';
import 'package:tunify/data/models/song.dart';
import 'package:tunify/features/settings/content_settings_provider.dart';
import 'package:tunify/features/device/device_music_provider.dart';
import 'package:tunify/features/downloads/download_provider.dart';
import 'package:tunify/features/library/library_provider.dart';
import 'package:tunify/features/player/player_state_provider.dart';
import 'package:tunify/ui/theme/app_colors.dart';
import 'package:tunify/ui/theme/design_tokens.dart';
import 'package:tunify/ui/theme/app_routes.dart';
import 'package:tunify/ui/widgets/common/back_title_app_bar.dart';
import '../player/song_options_sheet.dart';
import '../home/home_shared.dart';
import 'package:tunify/ui/widgets/common/empty_state_placeholder.dart';
import 'package:tunify/ui/theme/app_colors_scheme.dart';

/// Inline content for Library > Downloaded filter. Shows either library
/// downloads (Play all, Shuffle, Edit) or device music (Play all, Shuffle).
/// Respects global [viewMode] (grid/list) and [sortOrder].
class LibraryDownloadedContent extends ConsumerStatefulWidget {
  const LibraryDownloadedContent({
    super.key,
    required this.isLibraryMode,
    required this.viewMode,
    required this.sortOrder,
  });

  final bool isLibraryMode;
  final LibraryViewMode viewMode;
  final LibrarySortOrder sortOrder;

  @override
  ConsumerState<LibraryDownloadedContent> createState() =>
      _LibraryDownloadedContentState();
}

class _LibraryDownloadedContentState
    extends ConsumerState<LibraryDownloadedContent> {
  @override
  void initState() {
    super.initState();
    if (!widget.isLibraryMode) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(deviceMusicProvider.notifier).loadSongs();
      });
    }
  }

  @override
  void didUpdateWidget(LibraryDownloadedContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.isLibraryMode && oldWidget.isLibraryMode) {
      ref.read(deviceMusicProvider.notifier).loadSongs();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isLibraryMode) {
      return _LibraryDownloadedList(
        viewMode: widget.viewMode,
        sortOrder: widget.sortOrder,
      );
    }
    return _DeviceMusicList(
      viewMode: widget.viewMode,
      sortOrder: widget.sortOrder,
    );
  }
}

List<Song> _sortSongsByOrder(List<Song> songs, LibrarySortOrder order) {
  switch (order) {
    case LibrarySortOrder.alphabetical:
      return List<Song>.from(songs)
        ..sort(
            (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
    case LibrarySortOrder.recent:
    case LibrarySortOrder.recentlyAdded:
      return songs;
  }
}

class _LibraryDownloadedList extends ConsumerWidget {
  const _LibraryDownloadedList({
    required this.viewMode,
    required this.sortOrder,
  });

  final LibraryViewMode viewMode;
  final LibrarySortOrder sortOrder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final downloadService = ref.watch(downloadServiceProvider);
    final songs = downloadService.downloadedSongs;
    final showExplicit = ref.watch(showExplicitContentProvider);
    final filtered = filterByExplicitSetting(songs, showExplicit);
    final displaySongs = _sortSongsByOrder(filtered, sortOrder);
    final shuffleMode =
        ref.watch(libraryProvider.select((s) => s.downloadedShuffleMode));
    final shuffleEnabled = shuffleMode != ShuffleMode.none;

    if (displaySongs.isEmpty) {
      return SliverFillRemaining(
        child: EmptyStatePlaceholder(
          icon: AppIcon(
            icon: AppIcons.download,
            color: AppColorsScheme.of(context).textMuted,
            size: 48,
          ),
          title: 'No downloads yet',
          subtitle: 'Tap Download on a song in the player to add it here.',
        ),
      );
    }

    final actionRow = Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.base,
        vertical: AppSpacing.md,
      ),
      child: Row(
        children: [
          AppIconButton(
            icon: shuffleMode == ShuffleMode.smart
                ? SizedBox(
                    width: 22,
                    height: 22,
                    child: Stack(children: [
                      AppIcon(
                          icon: AppIcons.shuffle,
                          size: 22,
                          color: AppColors.primary),
                      const Positioned(
                        right: 0,
                        bottom: 0,
                        child: Icon(Icons.auto_awesome,
                            size: 9, color: AppColors.primary),
                      ),
                    ]),
                  )
                : AppIcon(
                    icon: AppIcons.shuffle,
                    size: 22,
                    color: shuffleEnabled
                        ? AppColors.primary
                        : AppColorsScheme.of(context).textMuted,
                  ),
            onPressed: () => showAppSheet(
              context,
              child: _DownloadsShuffleModeSheet(current: shuffleMode),
            ),
            size: 40,
            iconSize: 22,
          ),
          AppIconButton(
            icon: AppIcon(
              icon: AppIcons.edit,
              size: 22,
              color: AppColorsScheme.of(context).textMuted,
            ),
            onPressed: () => openEditDownloadedSheet(context, songs),
            size: 40,
            iconSize: 22,
          ),
          const Spacer(),
          PlayCircleButton(
            onTap: () {
              final queue = shuffleEnabled
                  ? (List<Song>.from(displaySongs)..shuffle(Random()))
                  : displaySongs;
              ref.read(playerProvider.notifier).playSong(
                    queue.first,
                    queue: queue,
                    queueSource: 'downloads',
                  );
            },
            size: 56,
            iconSize: 28,
          ),
        ],
      ),
    );

    if (viewMode == LibraryViewMode.grid) {
      return SliverList(
        delegate: SliverChildListDelegate([
          actionRow,
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            cacheExtent: 1000,
            addAutomaticKeepAlives: true,
            addRepaintBoundaries: true,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.base),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.82,
              crossAxisSpacing: AppSpacing.sm,
              mainAxisSpacing: AppSpacing.sm,
            ),
            itemCount: displaySongs.length,
            itemBuilder: (context, index) {
              final song = displaySongs[index];
              return _LibraryDownloadedGridCard(
                song: song,
                onTap: () => ref.read(playerProvider.notifier).playSong(
                      song,
                      queue: displaySongs,
                      queueSource: 'downloads',
                    ),
                onOptions: () =>
                    showSongOptionsSheet(context, song: song, ref: ref),
                onRemove: () => _confirmRemoveDownload(context, ref, song),
              );
            },
          ),
          const SizedBox(height: 160),
        ]),
      );
    }

    return SliverList(
      delegate: SliverChildListDelegate([
        actionRow,
        ...displaySongs.map((song) {
          return SongListTile(
            song: song,
            onTap: () {
              ref.read(playerProvider.notifier).playSong(
                    song,
                    queue: displaySongs,
                    queueSource: 'downloads',
                  );
            },
            subtitle: Row(
              children: [
                AppIcon(
                    icon: AppIcons.checkCircle,
                    color: AppColors.primary,
                    size: 14),
                const SizedBox(width: 4),
                Text(
                  'In device',
                  style: TextStyle(
                      color: AppColors.primary, fontSize: AppFontSize.sm),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    song.artist,
                    style: TextStyle(
                        color: AppColorsScheme.of(context).textMuted,
                        fontSize: AppFontSize.sm),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  song.durationFormatted,
                  style: TextStyle(
                    color: AppColorsScheme.of(context).textMuted,
                    fontSize: AppFontSize.md,
                  ),
                ),
                AppIconButton(
                  icon: AppIcon(
                      icon: AppIcons.moreVert,
                      color: AppColorsScheme.of(context).textMuted,
                      size: 20),
                  onPressedWithContext: (btnCtx) => showSongOptionsSheet(
                      context,
                      song: song,
                      ref: ref,
                      buttonContext: btnCtx),
                  size: 40,
                  iconSize: 20,
                  iconAlignment: Alignment.centerRight,
                ),
              ],
            ),
          );
        }),
        const SizedBox(height: 160),
      ]),
    );
  }
}

Future<void> _confirmRemoveDownload(
    BuildContext context, WidgetRef ref, Song song) async {
  final confirmed = await showConfirmDialog(
    context,
    title: 'Remove from device?',
    message:
        '${song.title} will be removed from this device. You can download it again later.',
    confirmLabel: 'Remove',
  );
  if (confirmed) {
    await ref.read(downloadServiceProvider).removeDownload(song.id);
  }
}

class _LibraryDownloadedGridCard extends ConsumerWidget {
  const _LibraryDownloadedGridCard({
    required this.song,
    required this.onTap,
    required this.onOptions,
    required this.onRemove,
  });

  final Song song;
  final VoidCallback onTap;
  final VoidCallback onOptions;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isNowPlaying = ref.watch(currentSongProvider)?.id == song.id;
    final isActuallyPlaying = ref.watch(isPlayingProvider);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    decoration: isNowPlaying
                        ? BoxDecoration(
                            borderRadius: BorderRadius.circular(AppRadius.md),
                            border:
                                Border.all(color: AppColors.primary, width: 2),
                          )
                        : null,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      child: song.thumbnailUrl.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: song.thumbnailUrl,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity,
                              placeholder: (_, __) => PlaceholderArt(size: 120),
                              errorWidget: (_, __, ___) =>
                                  PlaceholderArt(size: 120),
                            )
                          : PlaceholderArt(size: 120),
                    ),
                  ),
                  if (isNowPlaying)
                    Positioned.fill(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        child: Container(
                          color: Colors.black.withValues(alpha: 0.5),
                          child: Center(
                            child: NowPlayingIndicator(
                              size: 28,
                              barCount: 3,
                              animate: isActuallyPlaying,
                            ),
                          ),
                        ),
                      ),
                    ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: Material(
                      color: AppColors.glassBlack,
                      borderRadius: BorderRadius.circular(AppRadius.full),
                      child: InkWell(
                        onTap: onOptions,
                        borderRadius: BorderRadius.circular(AppRadius.full),
                        child: Padding(
                          padding: const EdgeInsets.all(6),
                          child: AppIcon(
                            icon: AppIcons.moreVert,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              song.title,
              style: TextStyle(
                color: isNowPlaying
                    ? AppColors.accent
                    : AppColorsScheme.of(context).textPrimary,
                fontSize: AppFontSize.md,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              song.artist,
              style: TextStyle(
                color: AppColorsScheme.of(context).textMuted,
                fontSize: AppFontSize.xs,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _DeviceMusicList extends ConsumerWidget {
  const _DeviceMusicList({
    required this.viewMode,
    required this.sortOrder,
  });

  final LibraryViewMode viewMode;
  final LibrarySortOrder sortOrder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(deviceMusicProvider);
    final showExplicit = ref.watch(showExplicitContentProvider);
    final filtered = filterByExplicitSetting(state.songs, showExplicit);
    final displaySongs = _sortSongsByOrder(filtered, sortOrder);

    if (state.isLoading && state.songs.isEmpty) {
      return const SliverFillRemaining(
        child: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    if (!state.hasPermission && state.error != null) {
      return SliverFillRemaining(
        child: _DevicePermissionPrompt(
          permanentlyDenied: state.permanentlyDenied,
          onGrant: () => ref.read(deviceMusicProvider.notifier).loadSongs(),
          onOpenSettings: () =>
              ref.read(deviceMusicProvider.notifier).openAppSettings(),
        ),
      );
    }

    if (displaySongs.isEmpty) {
      return SliverFillRemaining(
        child: EmptyStatePlaceholder(
          icon: AppIcon(
            icon: AppIcons.musicNote,
            color: AppColorsScheme.of(context).textMuted,
            size: 48,
          ),
          title: 'No music found on device',
          actionLabel: 'Refresh',
          onAction: () => ref.read(deviceMusicProvider.notifier).loadSongs(),
        ),
      );
    }

    final actionRow = Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.base,
        vertical: AppSpacing.md,
      ),
      child: Row(
        children: [
          AppIconButton(
            icon: AppIcon(
              icon: AppIcons.shuffle,
              size: 22,
              color: AppColorsScheme.of(context).textMuted,
            ),
            onPressed: () {
              final shuffled = List<Song>.from(displaySongs)..shuffle(Random());
              ref.read(playerProvider.notifier).playSong(
                    shuffled.first,
                    queue: shuffled,
                    queueSource: 'device',
                  );
            },
            size: 40,
            iconSize: 22,
          ),
          const Spacer(),
          PlayCircleButton(
            onTap: () {
              ref.read(playerProvider.notifier).playSong(
                    displaySongs.first,
                    queue: displaySongs,
                    queueSource: 'device',
                  );
            },
            size: 56,
            iconSize: 28,
          ),
        ],
      ),
    );

    if (viewMode == LibraryViewMode.grid) {
      return SliverList(
        delegate: SliverChildListDelegate([
          actionRow,
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            cacheExtent: 1000,
            addAutomaticKeepAlives: true,
            addRepaintBoundaries: true,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.base),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.82,
              crossAxisSpacing: AppSpacing.sm,
              mainAxisSpacing: AppSpacing.sm,
            ),
            itemCount: displaySongs.length,
            itemBuilder: (context, index) {
              final song = displaySongs[index];
              final audioId =
                  int.tryParse(song.id.replaceFirst('device_', '')) ?? 0;
              return _DeviceMusicGridCard(
                song: song,
                audioId: audioId,
                onTap: () => ref.read(playerProvider.notifier).playSong(
                      song,
                      queue: displaySongs,
                      queueSource: 'device',
                    ),
                onOptions: () =>
                    showSongOptionsSheet(context, song: song, ref: ref),
              );
            },
          ),
          const SizedBox(height: 160),
        ]),
      );
    }

    return SliverList(
      delegate: SliverChildListDelegate([
        actionRow,
        ...displaySongs.map((song) {
          final audioId =
              int.tryParse(song.id.replaceFirst('device_', '')) ?? 0;
          return SongListTile(
            song: song,
            onTap: () {
              ref
                  .read(playerProvider.notifier)
                  .playSong(song, queue: displaySongs, queueSource: 'device');
            },
            thumbnail: ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.sm),
              child: SizedBox(
                width: 48,
                height: 48,
                child: QueryArtworkWidget(
                  id: audioId,
                  type: ArtworkType.AUDIO,
                  artworkBorder: BorderRadius.zero,
                  artworkWidth: 48,
                  artworkHeight: 48,
                  nullArtworkWidget: Container(
                    width: 48,
                    height: 48,
                    color: AppColorsScheme.of(context).surfaceLight,
                    child: Center(
                      child: AppIcon(
                        icon: AppIcons.musicNote,
                        color: AppColorsScheme.of(context).textMuted,
                        size: 22,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  song.durationFormatted,
                  style: TextStyle(
                    color: AppColorsScheme.of(context).textMuted,
                    fontSize: AppFontSize.sm,
                  ),
                ),
                AppIconButton(
                  icon: AppIcon(
                      icon: AppIcons.moreVert,
                      color: AppColorsScheme.of(context).textMuted,
                      size: 20),
                  onPressedWithContext: (btnCtx) => showSongOptionsSheet(
                      context,
                      song: song,
                      ref: ref,
                      buttonContext: btnCtx),
                  size: 40,
                  iconSize: 20,
                  iconAlignment: Alignment.centerRight,
                ),
              ],
            ),
          );
        }),
        const SizedBox(height: 160),
      ]),
    );
  }
}

class _DeviceMusicGridCard extends ConsumerWidget {
  const _DeviceMusicGridCard({
    required this.song,
    required this.audioId,
    required this.onTap,
    required this.onOptions,
  });

  final Song song;
  final int audioId;
  final VoidCallback onTap;
  final VoidCallback onOptions;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isNowPlaying = ref.watch(currentSongProvider)?.id == song.id;
    final isActuallyPlaying = ref.watch(isPlayingProvider);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    decoration: isNowPlaying
                        ? BoxDecoration(
                            borderRadius: BorderRadius.circular(AppRadius.md),
                            border:
                                Border.all(color: AppColors.primary, width: 2),
                          )
                        : null,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      child: QueryArtworkWidget(
                        id: audioId,
                        type: ArtworkType.AUDIO,
                        artworkBorder: BorderRadius.zero,
                        artworkWidth: 256,
                        artworkHeight: 256,
                        nullArtworkWidget: Container(
                          width: double.infinity,
                          height: double.infinity,
                          color: AppColorsScheme.of(context).surfaceLight,
                          child: Center(
                            child: AppIcon(
                              icon: AppIcons.musicNote,
                              color: AppColorsScheme.of(context).textMuted,
                              size: 32,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (isNowPlaying)
                    Positioned.fill(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        child: Container(
                          color: Colors.black.withValues(alpha: 0.5),
                          child: Center(
                            child: NowPlayingIndicator(
                              size: 28,
                              barCount: 3,
                              animate: isActuallyPlaying,
                            ),
                          ),
                        ),
                      ),
                    ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: Material(
                      color: AppColors.glassBlack,
                      borderRadius: BorderRadius.circular(AppRadius.full),
                      child: InkWell(
                        onTap: onOptions,
                        borderRadius: BorderRadius.circular(AppRadius.full),
                        child: Padding(
                          padding: const EdgeInsets.all(6),
                          child: AppIcon(
                            icon: AppIcons.moreVert,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              song.title,
              style: TextStyle(
                color: isNowPlaying
                    ? AppColors.accent
                    : AppColorsScheme.of(context).textPrimary,
                fontSize: AppFontSize.md,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              song.artist,
              style: TextStyle(
                color: AppColorsScheme.of(context).textMuted,
                fontSize: AppFontSize.xs,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _DevicePermissionPrompt extends StatelessWidget {
  const _DevicePermissionPrompt({
    required this.permanentlyDenied,
    required this.onGrant,
    required this.onOpenSettings,
  });

  final bool permanentlyDenied;
  final VoidCallback onGrant;
  final VoidCallback onOpenSettings;

  @override
  Widget build(BuildContext context) {
    return EmptyStatePlaceholder(
      icon: AppIcon(
        icon: AppIcons.folder,
        color: AppColorsScheme.of(context).textMuted,
        size: 48,
      ),
      title: 'Allow access to device music',
      subtitle: permanentlyDenied
          ? 'Permission was denied. Please enable it in Settings.'
          : 'Grant permission to see music stored on your device.',
      actionLabel: permanentlyDenied ? 'Open Settings' : 'Grant Permission',
      onAction: permanentlyDenied ? onOpenSettings : onGrant,
    );
  }
}

// ─── Edit Downloads Sheet ─────────────────────────────────────────────────────

void openEditDownloadedSheet(BuildContext context, List<Song> initialSongs) {
  Navigator.of(context).push(
    appPageRoute<void>(
      builder: (_) => _EditDownloadedSheet(initialSongs: initialSongs),
    ),
  );
}

class _EditDownloadedSheet extends ConsumerStatefulWidget {
  const _EditDownloadedSheet({required this.initialSongs});
  final List<Song> initialSongs;

  @override
  ConsumerState<_EditDownloadedSheet> createState() =>
      _EditDownloadedSheetState();
}

class _EditDownloadedSheetState extends ConsumerState<_EditDownloadedSheet> {
  late List<Song> _items;
  final Set<String> _pendingRemoveIds = {};

  @override
  void initState() {
    super.initState();
    _items = List<Song>.from(widget.initialSongs);
  }

  void _toggleRemove(Song song) {
    setState(() {
      if (_pendingRemoveIds.contains(song.id)) {
        _pendingRemoveIds.remove(song.id);
      } else {
        _pendingRemoveIds.add(song.id);
      }
    });
  }

  void _onReorder(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) newIndex -= 1;
      final song = _items.removeAt(oldIndex);
      _items.insert(newIndex, song);
    });
  }

  Future<void> _save() async {
    final toKeep =
        _items.where((s) => !_pendingRemoveIds.contains(s.id)).toList();
    final downloadService = ref.read(downloadServiceProvider);
    for (final song in _items.where((s) => _pendingRemoveIds.contains(s.id))) {
      await downloadService.removeDownload(song.id);
    }
    if (toKeep.isNotEmpty) {
      await downloadService.reorderDownloaded(toKeep);
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Downloads updated'),
            behavior: SnackBarBehavior.floating),
      );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColorsScheme.of(context).background,
      appBar: BackTitleAppBar(
        title: 'Edit Downloads',
        backgroundColor: AppColorsScheme.of(context).background,
        actions: [
          TextButton(
            onPressed: _save,
            child: const Text('Save',
                style: TextStyle(
                    color: AppColors.primary, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
      body: ReorderableListView.builder(
        buildDefaultDragHandles: false,
        cacheExtent: 1000,
        itemCount: _items.length,
        onReorder: _onReorder,
        itemBuilder: (context, index) {
          final song = _items[index];
          final marked = _pendingRemoveIds.contains(song.id);
          return ListTile(
            key: ValueKey(song.id),
            leading: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppIconButton(
                  icon: AppIcon(
                    icon: marked
                        ? AppIcons.removeCircle
                        : AppIcons.removeCircleOutline,
                    color: marked
                        ? AppColors.accentRed
                        : AppColorsScheme.of(context).textMuted,
                    size: 22,
                  ),
                  onPressed: () => _toggleRemove(song),
                  size: 40,
                  iconSize: 22,
                ),
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.xs),
                  child: CachedNetworkImage(
                    imageUrl: song.thumbnailUrl,
                    width: 48,
                    height: 48,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(
                        width: 48,
                        height: 48,
                        color: AppColorsScheme.of(context).surfaceLight,
                        child: Center(
                            child: AppIcon(
                                icon: AppIcons.musicNote,
                                color: AppColorsScheme.of(context).textMuted,
                                size: 24))),
                    errorWidget: (_, __, ___) => Container(
                        width: 48,
                        height: 48,
                        color: AppColorsScheme.of(context).surfaceLight,
                        child: Center(
                            child: AppIcon(
                                icon: AppIcons.musicNote,
                                color: AppColorsScheme.of(context).textMuted,
                                size: 24))),
                  ),
                ),
              ],
            ),
            title: Text(song.title,
                style: TextStyle(
                    color: marked
                        ? AppColorsScheme.of(context).textMuted
                        : AppColorsScheme.of(context).textPrimary,
                    decoration: marked ? TextDecoration.lineThrough : null)),
            subtitle: Text(song.artist,
                style: TextStyle(
                    color: AppColorsScheme.of(context).textMuted,
                    decoration: marked ? TextDecoration.lineThrough : null)),
            trailing: ReorderableDragStartListener(
              index: index,
              child: AppIcon(
                  icon: AppIcons.dragHandle,
                  color: AppColorsScheme.of(context).textMuted,
                  size: 22),
            ),
          );
        },
      ),
    );
  }
}

// ─── Downloads Shuffle Mode Sheet ─────────────────────────────────────────────

class _DownloadsShuffleModeSheet extends ConsumerWidget {
  const _DownloadsShuffleModeSheet({required this.current});
  final ShuffleMode current;

  void _set(BuildContext context, WidgetRef ref, ShuffleMode mode) {
    ref.read(libraryProvider.notifier).setDownloadedShuffleMode(mode);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(mainAxisSize: MainAxisSize.min, children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.base, AppSpacing.lg, AppSpacing.base, AppSpacing.md),
        child: Text('Shuffle',
            style: TextStyle(
                color: AppColorsScheme.of(context).textPrimary,
                fontSize: AppFontSize.xl,
                fontWeight: FontWeight.w700)),
      ),
      _ShuffleTile(
        label: 'Shuffle off',
        selected: current == ShuffleMode.none,
        isSmart: false,
        onTap: () => _set(context, ref, ShuffleMode.none),
      ),
      _ShuffleTile(
        label: 'Regular Shuffle',
        subtitle: 'Shuffle downloaded songs',
        selected: current == ShuffleMode.regular,
        isSmart: false,
        onTap: () => _set(context, ref, ShuffleMode.regular),
      ),
      _ShuffleTile(
        label: 'Smart Shuffle',
        subtitle: 'Shuffle + mix in recommended songs',
        selected: current == ShuffleMode.smart,
        isSmart: true,
        onTap: () => _set(context, ref, ShuffleMode.smart),
      ),
      const SizedBox(height: AppSpacing.xl),
    ]);
  }
}

class _ShuffleTile extends StatelessWidget {
  const _ShuffleTile({
    required this.label,
    required this.selected,
    required this.isSmart,
    required this.onTap,
    this.subtitle,
  });

  final String label;
  final String? subtitle;
  final bool selected;
  final bool isSmart;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final iconColor = selected
        ? AppColors.primary
        : AppColorsScheme.of(context).textSecondary;
    return ListTile(
      contentPadding:
          const EdgeInsets.symmetric(horizontal: AppSpacing.base, vertical: 4),
      leading: SizedBox(
        width: 24,
        height: 24,
        child: Stack(children: [
          AppIcon(icon: AppIcons.shuffle, size: 24, color: iconColor),
          if (isSmart)
            Positioned(
              right: 0,
              bottom: 0,
              child: Icon(Icons.auto_awesome, size: 10, color: iconColor),
            ),
        ]),
      ),
      title: Text(label,
          style: TextStyle(
              color: selected
                  ? AppColors.primary
                  : AppColorsScheme.of(context).textPrimary,
              fontWeight: selected ? FontWeight.w600 : FontWeight.normal)),
      subtitle: subtitle != null
          ? Text(subtitle!,
              style: TextStyle(
                  color: AppColorsScheme.of(context).textMuted,
                  fontSize: AppFontSize.sm))
          : null,
      trailing: selected
          ? AppIcon(icon: AppIcons.check, color: AppColors.primary, size: 24)
          : null,
      onTap: onTap,
    );
  }
}
