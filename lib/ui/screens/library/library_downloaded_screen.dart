import 'dart:math';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../components/ui/components_ui.dart';
import '../../../config/app_icons.dart';
import '../../../models/song.dart';
import '../../../shared/providers/content_settings_provider.dart';
import '../../../shared/providers/download_provider.dart';
import '../../../shared/providers/library_provider.dart';
import '../../../shared/providers/player_state_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_routes.dart';
import '../player/song_options_sheet.dart';
import '../../theme/design_tokens.dart';

class LibraryDownloadedScreen extends ConsumerWidget {
  const LibraryDownloadedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final downloadService = ref.watch(downloadServiceProvider);
    final songs = downloadService.downloadedSongs;
    final showExplicit = ref.watch(showExplicitContentProvider);
    final displaySongs = filterByExplicitSetting(songs, showExplicit);
    final hasSong = ref.watch(currentSongProvider) != null;
    final shuffleEnabled = ref.watch(downloadedShuffleProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const BackTitleAppBar(title: 'Downloaded'),
      body: displaySongs.isEmpty
          ? EmptyStatePlaceholder(
              icon: AppIcon(
                icon: AppIcons.download,
                color: AppColors.textMuted,
                size: 48,
              ),
              title: 'No downloads yet',
              subtitle:
                  'Tap Download on a song in the player to add it here.',
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.base,
                    vertical: AppSpacing.md,
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: AppIcon(
                          icon: AppIcons.shuffle,
                          size: 24,
                          color: shuffleEnabled
                              ? AppColors.primary
                              : AppColors.textMuted,
                        ),
                        onPressed: () {
                          ref
                              .read(libraryProvider.notifier)
                              .toggleDownloadedShuffle();
                        },
                        color: shuffleEnabled
                            ? AppColors.primary
                            : AppColors.textMuted,
                      ),
                      IconButton(
                        icon: AppIcon(
                          icon: AppIcons.edit,
                          size: 24,
                          color: AppColors.textMuted,
                        ),
                        onPressed: () =>
                            openEditDownloadedSheet(context, songs),
                        color: AppColors.textMuted,
                      ),
                      const Spacer(),
                      GestureDetector(
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
                        child: Container(
                          width: 56,
                          height: 56,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.primary,
                          ),
                          child: Center(
                            child: AppIcon(
                              icon: AppIcons.play,
                              color: Colors.white,
                              size: 32,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
                    itemCount: displaySongs.length,
                    itemBuilder: (context, index) {
                      final song = displaySongs[index];
                      return SongListTile(
                        song: song,
                        onTap: () {
                          ref.read(playerProvider.notifier).playSong(song,
                              queueSource: 'downloads');
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
                    },
                  ),
                ),
              ],
            ),
      bottomNavigationBar: hasSong
          ? const SafeArea(
              child: MiniPlayer(key: ValueKey('downloaded-mini-player')))
          : null,
    );
  }
}

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
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: BackTitleAppBar(
        title: 'Edit Downloads',
        backgroundColor: AppColors.background,
        actions: [
          TextButton(
            onPressed: _save,
            child: const Text(
              'Save',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: ReorderableListView.builder(
        buildDefaultDragHandles: false,
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
                IconButton(
                  icon: AppIcon(
                    icon: marked
                        ? AppIcons.removeCircle
                        : AppIcons.removeCircleOutline,
                    color: marked ? AppColors.accentRed : AppColors.textMuted,
                    size: 22,
                  ),
                  onPressed: () => _toggleRemove(song),
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
                      color: AppColors.surfaceLight,
                      child: Center(
                        child: AppIcon(
                          icon: AppIcons.musicNote,
                          color: AppColors.textMuted,
                          size: 24,
                        ),
                      ),
                    ),
                    errorWidget: (_, __, ___) => Container(
                      width: 48,
                      height: 48,
                      color: AppColors.surfaceLight,
                      child: Center(
                        child: AppIcon(
                          icon: AppIcons.musicNote,
                          color: AppColors.textMuted,
                          size: 24,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            title: Text(
              song.title,
              style: TextStyle(
                color: marked ? AppColors.textMuted : AppColors.textPrimary,
                decoration: marked ? TextDecoration.lineThrough : null,
              ),
            ),
            subtitle: Text(
              song.artist,
              style: TextStyle(
                color: AppColors.textMuted,
                decoration: marked ? TextDecoration.lineThrough : null,
              ),
            ),
            trailing: ReorderableDragStartListener(
              index: index,
              child: AppIcon(
                icon: AppIcons.dragHandle,
                color: AppColors.textMuted,
                size: 22,
              ),
            ),
          );
        },
      ),
    );
  }
}
