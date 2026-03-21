import 'dart:async';
import 'dart:math';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../components/shared/collection_detail_scaffold.dart';
import '../../components/ui/components_ui.dart';
import '../../../config/app_icons.dart';
import '../../../models/library_playlist.dart';
import '../../../models/song.dart';
import '../../../shared/providers/content_settings_provider.dart';
import '../../../shared/providers/home_state_provider.dart';
import '../../../shared/providers/library_provider.dart';
import '../../../shared/providers/player_state_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/design_tokens.dart';
import '../../../shared/utils/string_utils.dart';
import '../player/song_options_sheet.dart';

class LibraryPlaylistScreen extends ConsumerStatefulWidget {
  const LibraryPlaylistScreen({super.key, required this.playlistId});

  final String playlistId;

  @override
  ConsumerState<LibraryPlaylistScreen> createState() =>
      _LibraryPlaylistScreenState();
}

class _LibraryPlaylistScreenState extends ConsumerState<LibraryPlaylistScreen> {
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
    final playlist = ref.watch(libraryPlaylistByIdProvider(widget.playlistId));

    if (playlist == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: BackTitleAppBar(
          title: '',
          backgroundColor: AppColors.background,
        ),
        body: const Center(
          child: Text(
            'Playlist not found',
            style: TextStyle(color: AppColors.textMuted),
          ),
        ),
      );
    }

    final songs = playlist.sortedSongs;
    final isEmpty = songs.isEmpty;
    final hasSong = ref.watch(currentSongProvider) != null;
    final query = _searchController.text.trim().toLowerCase();
    final queryFiltered = query.isEmpty
        ? songs
        : songs
            .where((s) =>
                s.title.toLowerCase().contains(query) ||
                s.artist.toLowerCase().contains(query))
            .toList();
    final showExplicit = ref.watch(showExplicitContentProvider);
    final filteredSongs = filterByExplicitSetting(queryFiltered, showExplicit);

    final subtitle = Row(
      children: [
        Text(
          '${playlist.songs.length} ${playlist.songs.length == 1 ? 'song' : 'songs'}',
          style: TextStyle(
            color: AppColors.textMuted.withValues(alpha: 0.9),
            fontSize: 14,
          ),
        ),
        if (playlist.songs.isNotEmpty) ...[
          Text(
            ' • ',
            style: TextStyle(
              color: AppColors.textMuted.withValues(alpha: 0.9),
              fontSize: 14,
            ),
          ),
          Text(
            _formatPlaylistDuration(playlist.songs),
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
      emptyChild: SliverFillRemaining(
        child: _EmptyState(
          playlistId: widget.playlistId,
          playlistName: playlist.name.capitalized,
          onStartAdding: () {
            _openAddToPlaylistSheet(
              context,
              widget.playlistId,
              playlist.name,
              () => setState(() {}),
            );
          },
          onDeletePlaylist: () =>
              _deletePlaylistFromEmpty(context, playlist.name.capitalized),
        ),
      ),
      title: playlist.name.capitalized,
      headerExpandedChild: CollectionDetailExpandedContent(
        cover: _PlaylistCoverWithPalette(songs: songs),
        title: playlist.name.capitalized,
        subtitle: subtitle,
      ),
      actionRow: _PlaylistActionRow(
        playlistId: widget.playlistId,
        songs: songs,
        filteredSongs: filteredSongs,
      ),
      pills: _PlaylistPillRow(
        playlistId: widget.playlistId,
        playlist: playlist,
        onPlaylistUpdated: () => setState(() {}),
      ),
      searchField: _SearchInPlaylist(
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
                      : 'No matches for "$query" in this playlist',
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
                final originalIndex = songs.indexOf(song);
                return _TrackTile(
                  song: song,
                  index: originalIndex + 1,
                  songs: songs,
                  playlistId: widget.playlistId,
                );
              },
              childCount: filteredSongs.length,
            ),
          ),
        const SliverToBoxAdapter(child: SizedBox(height: 160)),
      ],
      hasSong: hasSong,
      miniPlayerKey: const ValueKey('playlist-mini-player'),
    );
  }

  static String _formatPlaylistDuration(List<Song> songs) {
    if (songs.isEmpty) return '';
    final totalMs = songs.fold<int>(
      0,
      (sum, s) => sum + s.duration.inMilliseconds,
    );
    final d = Duration(milliseconds: totalMs);
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    if (h > 0) return '${h}h ${m}min';
    return '${m}min';
  }

  Future<void> _deletePlaylistFromEmpty(
      BuildContext context, String playlistName) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Delete playlist?',
      message: '$playlistName will be removed from your library.',
      confirmLabel: 'Delete',
    );
    if (confirmed && mounted) {
      if (!context.mounted) return;
      Navigator.of(context).pop();
      await ref
          .read(libraryProvider.notifier)
          .deletePlaylist(widget.playlistId);
    }
  }
}

class _PlaylistCoverWithPalette extends StatelessWidget {
  const _PlaylistCoverWithPalette({required this.songs});

  final List<Song> songs;

  @override
  Widget build(BuildContext context) {
    const size = 200.0;
    if (songs.isEmpty) {
      return Center(
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          child: AppIcon(
            icon: AppIcons.musicNote,
            color: AppColors.textMuted,
            size: 64,
          ),
        ),
      );
    }

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
          padding: const EdgeInsets.all(4),
          child: _buildCoverContent(songs, size - 8),
        ),
      ),
    );
  }

  Widget _buildCoverContent(List<Song> songs, double size) {
    if (songs.length == 1) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: CachedNetworkImage(
          imageUrl: songs.first.thumbnailUrl,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorWidget: (_, __, ___) => _placeholder(size),
        ),
      );
    }
    final urls = songs.take(4).map((s) => s.thumbnailUrl).toList();
    const gap = 2.0;
    final cellSize = (size - gap) / 2;
    return SizedBox(
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
    );
  }

  Widget _coverImage(String? url, double s) {
    return SizedBox(
      width: s,
      height: s,
      child: url != null
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

class _PlaylistActionRow extends ConsumerWidget {
  const _PlaylistActionRow({
    required this.playlistId,
    required this.songs,
    required this.filteredSongs,
  });

  final String playlistId;
  final List<Song> songs;
  final List<Song> filteredSongs;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final canPlay = filteredSongs.isNotEmpty;
    // Use a select on libraryProvider so we watch the bool directly.
    // libraryPlaylistByIdProvider uses LibraryPlaylist.== (id-only), which
    // means Riverpod considers the object unchanged after a shuffle toggle and
    // the widget never rebuilds. Selecting the primitive bool avoids this.
    final shuffleEnabled = ref.watch(
      libraryProvider.select((s) => s.playlists
          .where((p) => p.id == playlistId)
          .firstOrNull
          ?.shuffleEnabled ??
          false),
    );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.base),
      child: Row(
        children: [
          MultiDownloadButton(songs: songs, size: 24, iconSize: 20),
          AppIconButton(
            icon: AppIcon(
              icon: AppIcons.shuffle,
              size: 24,
              color: shuffleEnabled
                  ? AppColors.primary
                  : AppColors.textMuted,
            ),
            onPressed: canPlay
                ? () {
                    ref
                        .read(libraryProvider.notifier)
                        .togglePlaylistShuffle(playlistId);
                  }
                : null,
            color: shuffleEnabled ? AppColors.primary : AppColors.textMuted,
          ),
          const Spacer(),
          GestureDetector(
            onTap: canPlay
                ? () {
                    final queue = shuffleEnabled
                        ? (List<Song>.from(filteredSongs)..shuffle(Random()))
                        : songs;
                    ref
                        .read(playerProvider.notifier)
                        .playSong(queue.first,
                            queue: queue,
                            playlistId: playlistId,
                            queueSource: 'playlist');
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

class _PlaylistPillRow extends ConsumerWidget {
  const _PlaylistPillRow({
    required this.playlistId,
    required this.playlist,
    required this.onPlaylistUpdated,
  });

  final String playlistId;
  final LibraryPlaylist playlist;
  final VoidCallback onPlaylistUpdated;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.base),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _PillButton(
              icon: AppIcons.add,
              label: 'Add',
              onTap: () => _openAddToPlaylistSheet(
                  context, playlistId, playlist.name, onPlaylistUpdated),
            ),
            const SizedBox(width: AppSpacing.sm),
            _PillButton(
              icon: AppIcons.edit,
              label: 'Edit',
              onTap: () => _openEditSheet(context, playlistId, playlist),
            ),
            const SizedBox(width: AppSpacing.sm),
            _PillButton(
              icon: AppIcons.sort,
              label: 'Sort',
              onTap: () => _openSortSheet(context, playlistId, playlist),
            ),
            const SizedBox(width: AppSpacing.sm),
            _PillButton(
              icon: AppIcons.editNote,
              label: 'Name & details',
              onTap: () =>
                  _openNameAndDetailsSheet(context, playlistId, playlist),
            ),
          ],
        ),
      ),
    );
  }
}

class _PillButton extends StatelessWidget {
  const _PillButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final List<List<dynamic>> icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            border: Border.all(
              color: AppColors.textMuted.withValues(alpha: 0.5),
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppIcon(icon: icon, size: 18, color: AppColors.textSecondary),
              const SizedBox(width: AppSpacing.xs),
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

void _openAddToPlaylistSheet(
  BuildContext context,
  String playlistId,
  String playlistName,
  VoidCallback onPlaylistUpdated,
) {
  FocusManager.instance.primaryFocus?.unfocus();
  showAppSheet(
    context,
    maxHeight: MediaQuery.of(context).size.height * 0.75,
    child: _AddToPlaylistSheetContent(
      playlistId: playlistId,
      playlistName: playlistName,
      onAdded: () {
        onPlaylistUpdated();
      },
    ),
  );
}

void _openEditSheet(
    BuildContext context, String playlistId, LibraryPlaylist playlist) {
  FocusManager.instance.primaryFocus?.unfocus();
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => _EditPlaylistSheet(
        playlistId: playlistId,
        playlist: playlist,
      ),
    ),
  );
}

void _openSortSheet(
    BuildContext context, String playlistId, LibraryPlaylist playlist) {
  FocusManager.instance.primaryFocus?.unfocus();
  showAppSheet(
    context,
    child: _SortPlaylistSheet(
      playlistId: playlistId,
      playlist: playlist,
    ),
  );
}

void _openNameAndDetailsSheet(
    BuildContext context, String playlistId, LibraryPlaylist playlist) {
  FocusManager.instance.primaryFocus?.unfocus();
  showAppSheet(
    context,
    maxHeight: MediaQuery.of(context).size.height * 0.6,
    child: _NameAndDetailsSheetContent(
      playlistId: playlistId,
      playlist: playlist,
    ),
  );
}

class _AddToPlaylistSheetContent extends ConsumerStatefulWidget {
  const _AddToPlaylistSheetContent({
    required this.playlistId,
    required this.playlistName,
    required this.onAdded,
  });

  final String playlistId;
  final String playlistName;
  final VoidCallback onAdded;

  @override
  ConsumerState<_AddToPlaylistSheetContent> createState() =>
      _AddToPlaylistSheetContentState();
}

class _AddToPlaylistSheetContentState
    extends ConsumerState<_AddToPlaylistSheetContent> {
  final TextEditingController _searchController = TextEditingController();
  List<Song> _searchResults = [];
  bool _isSearching = false;
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _runSearch(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }
    setState(() => _isSearching = true);
    try {
      final results =
          await ref.read(playerProvider.notifier).searchSongs(query.trim());
      if (mounted) {
        setState(() {
          _searchResults = results;
          _isSearching = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _searchResults = [];
          _isSearching = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final recentlyPlayed = ref.watch(recentlyPlayedProvider);
    // Watch playlist song ids so the list rebuilds when we add/remove (icon updates)
    final inPlaylistIds = ref.watch(libraryProvider.select((s) {
      final p = s.playlists.where((x) => x.id == widget.playlistId).firstOrNull;
      return p?.songs.map((e) => e.id).toSet() ?? <String>{};
    }));
    final showRecent = _searchController.text.trim().isEmpty;
    final list = showRecent ? recentlyPlayed : _searchResults;

    return Column(
      mainAxisSize: MainAxisSize.max,
      children: [
        GestureDetector(
          onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
          behavior: HitTestBehavior.translucent,
          child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: kSheetHorizontalPadding,
                vertical: AppSpacing.base,
              ),
              child: AppInputField(
                controller: _searchController,
                hintText: 'Search YouTube Music',
                style: InputFieldStyle.filled,
                prefixIcon: AppIcon(
                  icon: AppIcons.search,
                  color: AppColors.textMuted,
                  size: 20,
                ),
                suffixIcon: _searchController.text.trim().isNotEmpty
                    ? AppIconButton(
                        icon: AppIcon(
                          icon: AppIcons.clear,
                          size: 24,
                          color: AppColors.textMuted,
                        ),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchResults = []);
                        },
                        size: 40,
                        iconSize: 24,
                      )
                    : null,
                onChanged: (value) {
                  setState(() {});
                  _searchDebounce?.cancel();
                  _searchDebounce = Timer(
                    const Duration(milliseconds: 350),
                    () {
                      if (mounted) _runSearch(_searchController.text);
                    },
                  );
                },
                onSubmitted: _runSearch,
              ),
            ),
        ),
        if (showRecent)
          Padding(
                padding: const EdgeInsets.symmetric(horizontal: kSheetHorizontalPadding),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Recently played',
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
        const SizedBox(height: AppSpacing.sm),
        Expanded(
              child: _isSearching
                  ? const Center(child: CircularProgressIndicator())
                  : list.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(AppSpacing.xl),
                            child: Text(
                              showRecent
                                  ? 'No recently played songs'
                                  : _searchController.text.trim().isEmpty
                                      ? 'Type above to search for songs'
                                      : 'No results for "${_searchController.text.trim()}"',
                              style: TextStyle(color: AppColors.textMuted),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        )
                      : ListView.builder(
                          itemCount: list.length,
                          itemBuilder: (context, index) {
                            final song = list[index];
                            final isInPlaylist =
                                inPlaylistIds.contains(song.id);
                            final isNowPlaying =
                                ref.watch(currentSongProvider)?.id == song.id;
                            final isActuallyPlaying =
                                ref.watch(isPlayingProvider);
                            return ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: kSheetHorizontalPadding,
                                vertical: 8,
                              ),
                              leading: NowPlayingThumbnail(
                                isPlaying: isNowPlaying,
                                isActuallyPlaying: isActuallyPlaying,
                                size: 48,
                                child: ClipRRect(
                                  borderRadius:
                                      BorderRadius.circular(AppRadius.xs),
                                  child: CachedNetworkImage(
                                    imageUrl: song.thumbnailUrl,
                                    width: 48,
                                    height: 48,
                                    fit: BoxFit.cover,
                                    errorWidget: (_, __, ___) => AppIcon(
                                        icon: AppIcons.musicNote,
                                        color: AppColors.textMuted,
                                        size: 28),
                                  ),
                                ),
                              ),
                              title: Text(
                                song.title,
                                style: TextStyle(
                                    color: isNowPlaying
                                        ? AppColors.accent
                                        : AppColors.textPrimary),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: Text(
                                song.artist,
                                style: const TextStyle(
                                    color: AppColors.textMuted, fontSize: 12),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              trailing: AppIconButton(
                                icon: AppIcon(
                                  icon: isInPlaylist
                                      ? AppIcons.checkCircle
                                      : AppIcons.addCircleOutline,
                                  color: isInPlaylist
                                      ? AppColors.primary
                                      : AppColors.textSecondary,
                                  size: 24,
                                ),
                                onPressed: () {
                                  if (isInPlaylist) {
                                    ref
                                        .read(libraryProvider.notifier)
                                        .removeSongFromPlaylist(
                                            widget.playlistId, song.id);
                                  } else {
                                    ref
                                        .read(libraryProvider.notifier)
                                        .addSongsToPlaylist(
                                            widget.playlistId, [song]);
                                  }
                                  widget.onAdded();
                                },
                              ),
                            );
                          },
                        ),
            ),
      ],
    );
  }
}

class _SearchInPlaylist extends StatelessWidget {
  const _SearchInPlaylist({
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
        hintText: 'Find in playlist',
        style: InputFieldStyle.filled,
        fillColor: AppColors.surfaceLight.withValues(alpha: 0.8),
        prefixIcon: AppIcon(
          icon: AppIcons.search,
          color: AppColors.textMuted.withValues(alpha: 0.9),
          size: 20,
        ),
        onChanged: (_) => onChanged(),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.playlistId,
    required this.playlistName,
    required this.onStartAdding,
    required this.onDeletePlaylist,
  });

  final String playlistId;
  final String playlistName;
  final VoidCallback onStartAdding;
  final VoidCallback onDeletePlaylist;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppIcon(
              icon: AppIcons.musicNote,
              size: 64,
              color: AppColors.textMuted.withValues(alpha: 0.5),
            ),
            const SizedBox(height: AppSpacing.xl),
            const Text(
              'No songs yet',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Add songs from Now Playing (⋯ → Add to playlist) or from Search.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textMuted.withValues(alpha: 0.9),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            AppButton(
              label: 'Start adding songs',
              icon: AppIcon(
                icon: AppIcons.add,
                size: 20,
                color: AppColors.background,
              ),
              onPressed: onStartAdding,
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.background,
            ),
            const SizedBox(height: AppSpacing.lg),
            AppButton(
              label: 'Delete playlist',
              variant: AppButtonVariant.text,
              foregroundColor: AppColors.accentRed,
              onPressed: onDeletePlaylist,
            ),
          ],
        ),
      ),
    );
  }
}

class _TrackTile extends ConsumerWidget {
  const _TrackTile({
    required this.song,
    required this.index,
    required this.songs,
    required this.playlistId,
  });

  final Song song;
  final int index;
  final List<Song> songs;
  final String playlistId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SongListTile(
      song: song,
      index: index,
      showIndexIndicator: false,
      onTap: () {
        ref.read(playerProvider.notifier).playSong(song,
            queue: songs,
            playlistId: playlistId,
            queueSource: 'playlist');
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
            onPressedWithContext: (btnCtx) => showSongOptionsSheet(
              context,
              song: song,
              ref: ref,
              buttonContext: btnCtx,
              showAddToPlaylist: false,
              onRemoveFromPlaylist: () {
                ref
                    .read(libraryProvider.notifier)
                    .removeSongFromPlaylist(playlistId, song.id);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Removed from playlist'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
            ),
            size: 40,
            iconSize: 20,
          ),
        ],
      ),
    );
  }
}


class _EditPlaylistSheet extends ConsumerStatefulWidget {
  const _EditPlaylistSheet({
    required this.playlistId,
    required this.playlist,
  });

  final String playlistId;
  final LibraryPlaylist playlist;

  @override
  ConsumerState<_EditPlaylistSheet> createState() => _EditPlaylistSheetState();
}

class _EditPlaylistSheetState extends ConsumerState<_EditPlaylistSheet> {
  late List<Song> _items;
  final Set<String> _pendingRemoveIds = {};

  @override
  void initState() {
    super.initState();
    _items = List<Song>.from(widget.playlist.songs);
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
    try {
      await ref
          .read(libraryProvider.notifier)
          .setPlaylistSongs(widget.playlistId, toKeep);
      if (mounted) {
        ref.invalidate(libraryPlaylistByIdProvider);
      }
    } catch (_) {
      // _persist() is already safe; this is defence-in-depth to ensure
      // the snackbar and pop always run even if an unexpected error occurs.
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Playlist updated'),
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
        title: 'Edit playlist',
        backgroundColor: AppColors.background,
        actions: [
          AppButton(
            label: 'Save',
            variant: AppButtonVariant.text,
            foregroundColor: AppColors.primary,
            onPressed: _save,
            height: 40,
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
                AppIconButton(
                  icon: AppIcon(
                    icon: marked
                        ? AppIcons.removeCircle
                        : AppIcons.removeCircleOutline,
                    color: marked ? AppColors.accentRed : AppColors.textMuted,
                    size: 22,
                  ),
                  onPressed: () => _toggleRemove(song),
                  size: 40,
                  iconSize: 22,
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


class _SortPlaylistSheet extends ConsumerWidget {
  const _SortPlaylistSheet({
    required this.playlistId,
    required this.playlist,
  });

  final String playlistId;
  final LibraryPlaylist playlist;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = playlist.sortOrder;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: kSheetHorizontalPadding,
                vertical: AppSpacing.xl,
              ),
              child: const Text(
                'Sort by',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            _SortTile(
              label: 'Custom order',
              selected: current == PlaylistTrackSortOrder.customOrder,
              onTap: () async {
                await ref.read(libraryProvider.notifier).setPlaylistSortOrder(
                    playlistId, PlaylistTrackSortOrder.customOrder);
                if (context.mounted) Navigator.pop(context);
              },
            ),
            _SortTile(
              label: 'Title',
              selected: current == PlaylistTrackSortOrder.title,
              onTap: () async {
                await ref.read(libraryProvider.notifier).setPlaylistSortOrder(
                    playlistId, PlaylistTrackSortOrder.title);
                if (context.mounted) Navigator.pop(context);
              },
            ),
            _SortTile(
              label: 'Recently added',
              selected: current == PlaylistTrackSortOrder.recentlyAdded,
              onTap: () async {
                await ref.read(libraryProvider.notifier).setPlaylistSortOrder(
                    playlistId, PlaylistTrackSortOrder.recentlyAdded);
                if (context.mounted) Navigator.pop(context);
              },
            ),
        const SizedBox(height: AppSpacing.lg),
      ],
    );
  }
}

class _SortTile extends StatelessWidget {
  const _SortTile({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
          horizontal: kSheetHorizontalPadding, vertical: 8),
      title: Text(label, style: const TextStyle(color: AppColors.textPrimary)),
      trailing: selected
          ? AppIcon(
              icon: AppIcons.check, color: AppColors.primary, size: 24)
          : null,
      onTap: onTap,
    );
  }
}


class _NameAndDetailsSheetContent extends ConsumerStatefulWidget {
  const _NameAndDetailsSheetContent({
    required this.playlistId,
    required this.playlist,
  });

  final String playlistId;
  final LibraryPlaylist playlist;

  @override
  ConsumerState<_NameAndDetailsSheetContent> createState() =>
      _NameAndDetailsSheetContentState();
}

class _NameAndDetailsSheetContentState
    extends ConsumerState<_NameAndDetailsSheetContent> {
  late TextEditingController _nameController;
  late TextEditingController _descController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.playlist.name);
    _descController = TextEditingController(text: widget.playlist.description);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;
    await ref.read(libraryProvider.notifier).updatePlaylist(
          widget.playlistId,
          name: name,
          description: _descController.text.trim(),
        );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Playlist updated'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.of(context).pop();
    }
  }

  Future<void> _deletePlaylist() async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Delete playlist?',
      message:
          '${widget.playlist.name.capitalized} will be removed from your library.',
      confirmLabel: 'Delete',
    );
    if (confirmed) {
      if (mounted) Navigator.of(context).popUntil((r) => r.isFirst);
      await ref
          .read(libraryProvider.notifier)
          .deletePlaylist(widget.playlistId);
    }
  }

  void _unfocus() => FocusManager.instance.primaryFocus?.unfocus();

  @override
  Widget build(BuildContext context) {
    final songs = widget.playlist.songs;
    const coverSize = 120.0;
    return GestureDetector(
      onTap: _unfocus,
      behavior: HitTestBehavior.translucent,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
              padding: const EdgeInsets.fromLTRB(
                  kSheetHorizontalPadding, AppSpacing.lg,
                  kSheetHorizontalPadding, AppSpacing.sm),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(width: 8),
                  AppIconButton(
                    icon: AppIcon(
                      icon: AppIcons.back,
                      size: 22,
                      color: AppColors.textPrimary,
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                    size: 40,
                    iconSize: 22,
                  ),
                  const Spacer(),
                  AppButton(
                    label: 'Save',
                    variant: AppButtonVariant.text,
                    foregroundColor: AppColors.primary,
                    onPressed: _save,
                    height: 40,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: kSheetHorizontalPadding),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    children: [
                      _NameDetailsCover(songs: songs, size: coverSize),
                      const SizedBox(height: AppSpacing.sm),
                      AppButton(
                        label: 'Change',
                        variant: AppButtonVariant.text,
                        foregroundColor: AppColors.textSecondary,
                        icon: AppIcon(
                          icon: AppIcons.edit,
                          size: 18,
                          color: AppColors.textSecondary,
                        ),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                  'Cover is based on the first songs in the playlist.'),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                        height: 40,
                      ),
                    ],
                  ),
                  const SizedBox(width: AppSpacing.xl),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        AppInputField(
                          controller: _nameController,
                          hintText: 'Name',
                          style: InputFieldStyle.filled,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        AppInputField(
                          controller: _descController,
                          hintText: 'Description',
                          style: InputFieldStyle.filled,
                          maxLines: 3,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),
            AppButton(
              label: 'Delete playlist',
              variant: AppButtonVariant.text,
              foregroundColor: AppColors.accentRed,
              onPressed: _deletePlaylist,
            ),
          ],
        ),
    );
  }
}

class _NameDetailsCover extends StatelessWidget {
  const _NameDetailsCover({required this.songs, required this.size});

  final List<Song> songs;
  final double size;

  @override
  Widget build(BuildContext context) {
    if (songs.isEmpty) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        child: AppIcon(icon: AppIcons.musicNote, color: AppColors.textMuted),
      );
    }
    if (songs.length == 1) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: CachedNetworkImage(
          imageUrl: songs.first.thumbnailUrl,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorWidget: (_, __, ___) =>
              AppIcon(icon: AppIcons.musicNote, color: AppColors.textMuted),
        ),
      );
    }
    final urls = songs.take(4).map((s) => s.thumbnailUrl).toList();
    const gap = 2.0;
    final cellSize = (size - gap) / 2;
    return SizedBox(
      width: size,
      height: size,
      child: Column(
        children: [
          Row(
            children: [
              _cell(urls.isNotEmpty ? urls[0] : null, cellSize),
              SizedBox(width: gap),
              _cell(urls.length > 1 ? urls[1] : null, cellSize),
            ],
          ),
          const SizedBox(height: gap),
          Row(
            children: [
              _cell(urls.length > 2 ? urls[2] : null, cellSize),
              SizedBox(width: gap),
              _cell(urls.length > 3 ? urls[3] : null, cellSize),
            ],
          ),
        ],
      ),
    );
  }

  Widget _cell(String? url, double s) {
    return SizedBox(
      width: s,
      height: s,
      child: url != null
          ? CachedNetworkImage(
              imageUrl: url,
              fit: BoxFit.cover,
              errorWidget: (_, __, ___) => _place(s),
            )
          : _place(s),
    );
  }

  Widget _place(double s) {
    return Container(
      width: s,
      height: s,
      color: AppColors.surfaceLight,
      child: AppIcon(icon: AppIcons.musicNote, color: AppColors.textMuted),
    );
  }
}
