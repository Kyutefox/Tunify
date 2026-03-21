import 'dart:math';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:on_audio_query_pluse/on_audio_query.dart';

import '../../components/ui/components_ui.dart';
import '../../../config/app_icons.dart';
import '../../../models/song.dart';
import '../../../shared/providers/content_settings_provider.dart';
import '../../../shared/providers/device_music_provider.dart';
import '../../../shared/providers/download_provider.dart';
import '../../../shared/providers/library_provider.dart';
import '../../../shared/providers/player_state_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/design_tokens.dart';
import '../player/song_options_sheet.dart';
import '../home/home_shared.dart';
import 'library_downloaded_screen.dart';

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
        ..sort((a, b) =>
            a.title.toLowerCase().compareTo(b.title.toLowerCase()));
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
    final shuffleEnabled = ref.watch(downloadedShuffleProvider);

    if (displaySongs.isEmpty) {
      return SliverFillRemaining(
        child: EmptyStatePlaceholder(
          icon: AppIcon(
            icon: AppIcons.download,
            color: AppColors.textMuted,
            size: 48,
          ),
          title: 'No downloads yet',
          subtitle:
              'Tap Download on a song in the player to add it here.',
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
              color: shuffleEnabled
                  ? AppColors.primary
                  : AppColors.textMuted,
            ),
            onPressed: () {
              ref.read(libraryProvider.notifier).toggleDownloadedShuffle();
            },
            size: 40,
            iconSize: 22,
          ),
          AppIconButton(
            icon: AppIcon(
              icon: AppIcons.edit,
              size: 22,
              color: AppColors.textMuted,
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
                onOptions: () => showSongOptionsSheet(context, song: song, ref: ref),
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
                      color: AppColors.primary, fontSize: 12),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    song.artist,
                    style: const TextStyle(
                        color: AppColors.textMuted, fontSize: 12),
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
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 13,
                  ),
                ),
                AppIconButton(
                  icon: AppIcon(
                      icon: AppIcons.moreVert,
                      color: AppColors.textMuted,
                      size: 20),
                  onPressedWithContext: (btnCtx) =>
                      showSongOptionsSheet(context, song: song, ref: ref, buttonContext: btnCtx),
                  size: 40,
                  iconSize: 20,
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
        onLongPress: onOptions,
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
                            borderRadius:
                                BorderRadius.circular(AppRadius.md),
                            border: Border.all(
                                color: AppColors.accent, width: 2),
                          )
                        : null,
                    child: ClipRRect(
                      borderRadius:
                          BorderRadius.circular(AppRadius.md),
                      child: song.thumbnailUrl.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: song.thumbnailUrl,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity,
                              placeholder: (_, __) => PlaceholderArt(size: 120),
                              errorWidget: (_, __, ___) => PlaceholderArt(size: 120),
                            )
                          : PlaceholderArt(size: 120),
                    ),
                  ),
                  if (isNowPlaying)
                    Positioned.fill(
                      child: ClipRRect(
                        borderRadius:
                            BorderRadius.circular(AppRadius.md),
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
                    : AppColors.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              song.artist,
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 11,
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
    final filtered =
        filterByExplicitSetting(state.songs, showExplicit);
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
            color: AppColors.textMuted,
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
              color: AppColors.textMuted,
            ),
            onPressed: () {
              final shuffled = List<Song>.from(displaySongs)
                ..shuffle(Random());
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
                onOptions: () => showSongOptionsSheet(context, song: song, ref: ref),
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
              ref.read(playerProvider.notifier).playSong(song,
                  queue: displaySongs,
                  queueSource: 'device');
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
                    color: AppColors.surfaceLight,
                    child: Center(
                      child: AppIcon(
                        icon: AppIcons.musicNote,
                        color: AppColors.textMuted,
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
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12,
                  ),
                ),
                AppIconButton(
                  icon: AppIcon(
                      icon: AppIcons.moreVert,
                      color: AppColors.textMuted,
                      size: 20),
                  onPressedWithContext: (btnCtx) =>
                      showSongOptionsSheet(context, song: song, ref: ref, buttonContext: btnCtx),
                  size: 40,
                  iconSize: 20,
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
        onLongPress: onOptions,
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
                            borderRadius:
                                BorderRadius.circular(AppRadius.md),
                            border: Border.all(
                                color: AppColors.accent, width: 2),
                          )
                        : null,
                    child: ClipRRect(
                      borderRadius:
                          BorderRadius.circular(AppRadius.md),
                      child: QueryArtworkWidget(
                        id: audioId,
                        type: ArtworkType.AUDIO,
                        artworkBorder: BorderRadius.zero,
                        artworkWidth: 256,
                        artworkHeight: 256,
                        nullArtworkWidget: Container(
                          width: double.infinity,
                          height: double.infinity,
                          color: AppColors.surfaceLight,
                          child: Center(
                            child: AppIcon(
                              icon: AppIcons.musicNote,
                              color: AppColors.textMuted,
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
                        borderRadius:
                            BorderRadius.circular(AppRadius.md),
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
                    : AppColors.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              song.artist,
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 11,
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
        color: AppColors.textMuted,
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
