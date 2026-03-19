import 'dart:math';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../components/shared/collection_detail_scaffold.dart';
import '../../components/ui/components_ui.dart';
import '../../../config/app_icons.dart';
import '../../../models/song.dart';
import '../../../shared/providers/content_settings_provider.dart';
import '../../../shared/providers/library_provider.dart';
import '../../../shared/providers/player_state_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/design_tokens.dart';
import '../player/song_options_sheet.dart';

class LibraryLikedSongsScreen extends ConsumerStatefulWidget {
  const LibraryLikedSongsScreen({super.key});

  @override
  ConsumerState<LibraryLikedSongsScreen> createState() =>
      _LibraryLikedSongsScreenState();
}

class _LibraryLikedSongsScreenState
    extends ConsumerState<LibraryLikedSongsScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final likedSongs = ref.watch(libraryProvider.select((s) => s.likedSongs));
    final query = _searchController.text.trim().toLowerCase();
    final queryFiltered = query.isEmpty
        ? likedSongs
        : likedSongs
            .where((s) =>
                s.title.toLowerCase().contains(query) ||
                s.artist.toLowerCase().contains(query))
            .toList();
    final showExplicit = ref.watch(showExplicitContentProvider);
    final filteredSongs = filterByExplicitSetting(queryFiltered, showExplicit);
    final isEmpty = likedSongs.isEmpty;
    final hasSong = ref.watch(currentSongProvider) != null;

    final subtitle = Row(
      children: [
        Text(
          '${likedSongs.length} ${likedSongs.length == 1 ? 'song' : 'songs'}',
          style: TextStyle(
            color: AppColors.textMuted.withValues(alpha: 0.9),
            fontSize: 14,
          ),
        ),
        if (likedSongs.isNotEmpty) ...[
          Text(
            ' • ',
            style: TextStyle(
              color: AppColors.textMuted.withValues(alpha: 0.9),
              fontSize: 14,
            ),
          ),
          Text(
            _formatDuration(likedSongs),
            style: TextStyle(
              color: AppColors.textMuted.withValues(alpha: 0.9),
              fontSize: 14,
            ),
          ),
        ],
      ],
    );

    return CollectionDetailScaffold(
      isEmpty: isEmpty,
      emptyChild: const SliverFillRemaining(
        child: _LikedEmptyState(),
      ),
      title: 'Liked Songs',
      headerExpandedChild: CollectionDetailExpandedContent(
        cover: _LikedCoverWithPalette(songs: likedSongs),
        title: 'Liked Songs',
        subtitle: subtitle,
      ),
      actionRow: _LikedActionRow(
        songs: likedSongs,
        filteredSongs: filteredSongs,
        onEdit: () => _openEditLikedSheet(context, likedSongs),
      ),
      searchField: _SearchInLiked(
        controller: _searchController,
        focusNode: _searchFocus,
        onChanged: () => setState(() {}),
      ),
      bodySlivers: [
        const SliverToBoxAdapter(
          child: CollectionTrackListHeader(showDurationColumn: true),
        ),
        if (filteredSongs.isEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xxl),
              child: Center(
                child: Text(
                  query.isEmpty
                      ? 'No songs'
                      : 'No matches for "$query"',
                  style: TextStyle(
                    color: AppColors.textMuted.withValues(alpha: 0.9),
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          )
        else
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final song = filteredSongs[index];
                final originalIndex = likedSongs.indexOf(song) + 1;
                return _LikedTrackTile(
                  song: song,
                  index: originalIndex,
                  filteredSongs: filteredSongs,
                );
              },
              childCount: filteredSongs.length,
            ),
          ),
        const SliverToBoxAdapter(child: SizedBox(height: 160)),
      ],
      hasSong: hasSong,
      miniPlayerKey: const ValueKey('liked-songs-mini-player'),
    );
  }

  static String _formatDuration(List<Song> songs) {
    if (songs.isEmpty) return '';
    final totalMs =
        songs.fold<int>(0, (sum, s) => sum + s.duration.inMilliseconds);
    final d = Duration(milliseconds: totalMs);
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    if (h > 0) return '${h}h ${m}min';
    return '${m}min';
  }
}

void _openEditLikedSheet(BuildContext context, List<Song> initialSongs) {
  FocusManager.instance.primaryFocus?.unfocus();
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => _EditLikedSheet(initialSongs: initialSongs),
    ),
  );
}

class _EditLikedSheet extends ConsumerStatefulWidget {
  const _EditLikedSheet({required this.initialSongs});

  final List<Song> initialSongs;

  @override
  ConsumerState<_EditLikedSheet> createState() => _EditLikedSheetState();
}

class _EditLikedSheetState extends ConsumerState<_EditLikedSheet> {
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
    await ref.read(libraryProvider.notifier).setLikedSongsOrder(toKeep);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Liked Songs updated'),
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
        title: 'Edit Liked Songs',
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
          final isNowPlaying = ref.watch(currentSongProvider)?.id == song.id;
          final isActuallyPlaying = ref.watch(isPlayingProvider);
          return ListTile(
            key: ValueKey(song.id),
            leading: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: FavouriteIcon(
                    isLiked: marked,
                    songId: song.id,
                    size: 22,
                    emptyColor: AppColors.textMuted,
                  ),
                  onPressed: () => _toggleRemove(song),
                ),
                NowPlayingThumbnail(
                  isPlaying: isNowPlaying,
                  isActuallyPlaying: isActuallyPlaying,
                  size: 48,
                  child: ClipRRect(
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
                ),
              ],
            ),
            title: Text(
              song.title,
              style: TextStyle(
                color: marked
                    ? AppColors.textMuted
                    : isNowPlaying
                        ? AppColors.accent
                        : AppColors.textPrimary,
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

class _LikedEmptyState extends StatelessWidget {
  const _LikedEmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Center(
                child: FavouriteIcon(
                  isLiked: true,
                  size: 48,
                  gradient: AppColors.loveThemeGradientFor('liked_songs'),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            const Text(
              'No liked songs yet',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Tap the heart on any song to add it here',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textMuted.withValues(alpha: 0.9),
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LikedCoverWithPalette extends StatelessWidget {
  const _LikedCoverWithPalette({required this.songs});

  final List<Song> songs;

  @override
  Widget build(BuildContext context) {
    const size = 200.0;
    if (songs.isEmpty) {
      return Center(
        child: Container(
          width: size,
          height: size,
          margin: const EdgeInsets.symmetric(horizontal: AppSpacing.base),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.primary.withValues(alpha: 0.3),
                AppColors.secondary.withValues(alpha: 0.2),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          child: Center(
            child: FavouriteIcon(
              isLiked: true,
              size: 48,
            ),
          ),
        ),
      );
    }

    final urls = songs.take(4).map((s) => s.thumbnailUrl).toList();
    const gap = 4.0;
    final cellSize = (size - gap) / 2;

    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: AppSpacing.base),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          color: AppColors.surfaceLight.withValues(alpha: 0.6),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(gap / 2),
          child: SizedBox(
            width: size,
            height: size,
            child: Column(
              children: [
                Row(
                  children: [
                    _coverImage(urls.isNotEmpty ? urls[0] : null, cellSize),
                    const SizedBox(width: gap),
                    _coverImage(urls.length > 1 ? urls[1] : null, cellSize),
                  ],
                ),
                const SizedBox(height: gap),
                Row(
                  children: [
                    _coverImage(urls.length > 2 ? urls[2] : null, cellSize),
                    const SizedBox(width: gap),
                    _coverImage(urls.length > 3 ? urls[3] : null, cellSize),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _coverImage(String? url, double s) {
    return SizedBox(
      width: s,
      height: s,
      child: url != null && url.isNotEmpty
          ? CachedNetworkImage(
              imageUrl: url,
              fit: BoxFit.cover,
              errorWidget: (_, __, ___) => _placeholder(s),
            )
          : _placeholder(s),
    );
  }

  Widget _placeholder(double s) {
    return Container(
      width: s,
      height: s,
      color: AppColors.surfaceLight,
      child: AppIcon(icon: AppIcons.musicNote, color: AppColors.textMuted),
    );
  }
}

class _LikedActionRow extends ConsumerWidget {
  const _LikedActionRow({
    required this.songs,
    required this.filteredSongs,
    required this.onEdit,
  });

  final List<Song> songs;
  final List<Song> filteredSongs;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final canPlay = filteredSongs.isNotEmpty;
    final shuffleEnabled = ref.watch(likedShuffleProvider);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.base),
      child: Row(
        children: [
          IconButton(
            icon: AppIcon(
              icon: AppIcons.shuffle,
              size: 24,
              color:
                  shuffleEnabled ? AppColors.primary : AppColors.textMuted,
            ),
            onPressed: canPlay
                ? () {
                    ref.read(libraryProvider.notifier).toggleLikedShuffle();
                  }
                : null,
            color: shuffleEnabled ? AppColors.primary : AppColors.textMuted,
          ),
          IconButton(
            icon: AppIcon(
              icon: AppIcons.edit,
              size: 24,
              color: AppColors.textMuted,
            ),
            onPressed: onEdit,
            color: AppColors.textMuted,
          ),
          MultiDownloadButton(songs: songs, size: 24, iconSize: 20),
          const Spacer(),
          GestureDetector(
            onTap: canPlay
                ? () {
                    final queue = shuffleEnabled
                        ? (List<Song>.from(songs)..shuffle(Random()))
                        : songs;
                    ref
                        .read(playerProvider.notifier)
                        .playSong(queue.first,
                            queue: queue,
                            queueSource: 'liked');
                  }
                : null,
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: canPlay
                    ? AppColors.primary
                    : AppColors.textMuted.withValues(alpha: 0.3),
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
    );
  }
}

class _SearchInLiked extends StatelessWidget {
  const _SearchInLiked({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.base),
      child: AppInputField(
        controller: controller,
        focusNode: focusNode,
        hintText: 'Search in Liked Songs',
        style: InputFieldStyle.filled,
        fillColor: AppColors.surfaceLight.withValues(alpha: 0.6),
        prefixIcon: AppIcon(
          icon: AppIcons.search,
          color: AppColors.textMuted.withValues(alpha: 0.8),
          size: 20,
        ),
        onChanged: (_) => onChanged(),
      ),
    );
  }
}

class _LikedTrackTile extends ConsumerWidget {
  const _LikedTrackTile({
    required this.song,
    required this.index,
    required this.filteredSongs,
  });

  final Song song;
  final int index;
  final List<Song> filteredSongs;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SongListTile(
      song: song,
      index: index,
      showIndexIndicator: false,
      onTap: () {
        ref.read(playerProvider.notifier).playSong(song,
            queue: filteredSongs,
            queueSource: 'liked');
      },
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
              size: 20,
            ),
            onPressed: () => showSongOptionsSheet(context, song: song),
            size: 40,
            iconSize: 20,
          ),
        ],
      ),
    );
  }
}
