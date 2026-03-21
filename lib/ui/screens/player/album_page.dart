import 'dart:math';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../components/shared/collection_detail_scaffold.dart';
import '../../components/ui/components_ui.dart';
import '../home/home_shared.dart';
import '../../../config/app_icons.dart';
import '../../../models/collection_result.dart';
import '../../../models/library_album.dart';
import '../../../models/song.dart';
import '../../../shared/providers/content_settings_provider.dart';
import '../../../shared/providers/library_provider.dart';
import '../../../shared/providers/player_state_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/design_tokens.dart';
import 'package:tunify_logger/tunify_logger.dart';
import 'song_options_sheet.dart';

class AlbumPage extends ConsumerStatefulWidget {
  const AlbumPage({
    super.key,
    required this.songTitle,
    required this.artistName,
    required this.thumbnailUrl,
    this.albumBrowseId,
    this.albumName,
    this.songId,
  });

  final String songTitle;
  final String artistName;
  final String thumbnailUrl;
  final String? albumBrowseId;
  final String? albumName;
  /// Video ID of the song — used to resolve albumBrowseId directly from the
  /// YouTube Music player API when it is not already present on the Song object.
  final String? songId;

  @override
  ConsumerState<AlbumPage> createState() => _AlbumPageState();
}

class _AlbumPageState extends ConsumerState<AlbumPage> {
  List<Song> _songs = [];
  bool _loading = true;
  String? _error;
  bool _shuffleEnabled = false;
  String? _browseId;
  CollectionMetadata? _metadata;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() => setState(() {}));
    _fetchAlbumSongs();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  Future<void> _fetchAlbumSongs() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final streamManager = ref.read(streamManagerProvider);
      _browseId ??= widget.albumBrowseId;

      // If albumBrowseId is missing (race-condition or API gap), try to resolve
      // it via the YouTube Music player API before falling back to text search.
      if (_browseId == null && widget.songId != null) {
        final fullSong = await streamManager
            .getSongFromPlayer(widget.songId!)
            .timeout(const Duration(seconds: 10), onTimeout: () => null);
        _browseId = fullSong?.albumBrowseId;
      }

      if (_browseId == null) {
        final query = '${widget.songTitle} ${widget.artistName}'.trim();
        final result = await streamManager.searchResolveBrowseIds(query);
        _browseId = result.albumBrowseId;
      }
      if (_browseId == null) {
        throw Exception('Could not find album');
      }
      final result = await streamManager.getCollectionTracks(_browseId!);
      if (!mounted) return;
      setState(() {
        _metadata = result.metadata.hasData ? result.metadata : null;
        _songs = result.tracks.map((t) => Song.fromTrack(t)).toList();
        _loading = false;
      });
    } catch (e, stack) {
      logError('Album load failed: $e\n$stack', tag: 'ArtistAlbum');
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  void _playAll() {
    final showExplicit = ref.read(showExplicitContentProvider);
    final toPlay = filterByExplicitSetting(_songs, showExplicit);
    if (toPlay.isEmpty) return;
    final queue =
        _shuffleEnabled ? (List<Song>.from(toPlay)..shuffle(Random())) : toPlay;
    ref.read(playerProvider.notifier).playSong(queue.first, queue: queue);
  }

  String _formatDuration(List<Song> songs) {
    if (songs.isEmpty) return '';
    final totalMs =
        songs.fold<int>(0, (sum, s) => sum + s.duration.inMilliseconds);
    final d = Duration(milliseconds: totalMs);
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    if (h > 0) return '${h}h ${m}min';
    return '${m}min';
  }

  @override
  Widget build(BuildContext context) {
    final hasSong = ref.watch(currentSongProvider) != null;
    final showExplicit = ref.watch(showExplicitContentProvider);
    final displaySongs = filterByExplicitSetting(_songs, showExplicit);
    final query = _searchController.text.trim().toLowerCase();
    final filteredSongs = query.isEmpty
        ? displaySongs
        : displaySongs
            .where((s) =>
                s.title.toLowerCase().contains(query) ||
                s.artist.toLowerCase().contains(query))
            .toList();

    if (_loading) return const LoadingScaffold();
    if (_error != null) {
      return ErrorScaffold(
        message: 'Failed to load album',
        onRetry: _fetchAlbumSongs,
      );
    }
    final albumTitle =
        _metadata?.title ?? widget.albumName ?? widget.songTitle;
    final albumSubtitle = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          _metadata?.subtitle ?? widget.artistName,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: AppFontSize.xl,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Text(
              '${displaySongs.length} ${displaySongs.length == 1 ? 'song' : 'songs'}',
              style: TextStyle(
                color: AppColors.textMuted.withValues(alpha: 0.9),
                fontSize: AppFontSize.base,
              ),
            ),
            if (displaySongs.isNotEmpty) ...[
              Text(
                ' • ',
                style: TextStyle(
                  color: AppColors.textMuted.withValues(alpha: 0.9),
                  fontSize: AppFontSize.base,
                ),
              ),
              Text(
                _formatDuration(displaySongs),
                style: TextStyle(
                  color: AppColors.textMuted.withValues(alpha: 0.9),
                  fontSize: AppFontSize.base,
                ),
              ),
            ],
          ],
        ),
      ],
    );

    return CollectionDetailScaffold(
      isEmpty: displaySongs.isEmpty,
      emptyChild: const SliverFillRemaining(
        child: Center(
          child: Text(
            'No songs found',
            style: TextStyle(color: AppColors.textMuted),
          ),
        ),
      ),
      title: albumTitle,
      headerExpandedChild: CollectionDetailExpandedContent(
        cover: _buildCover(),
        title: albumTitle,
        subtitle: albumSubtitle,
      ),
      actionRow: _buildActions(displaySongs),
      searchField: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.base),
        child: AppInputField(
          controller: _searchController,
          focusNode: _searchFocus,
          hintText: 'Search in this album',
          style: InputFieldStyle.filled,
          fillColor: AppColors.surfaceLight.withValues(alpha: 0.8),
          prefixIcon: AppIcon(
            icon: AppIcons.search,
            color: AppColors.textMuted.withValues(alpha: 0.9),
            size: 20,
          ),
          onChanged: (_) => setState(() {}),
        ),
      ),
      bodySlivers: displaySongs.isEmpty
          ? []
          : [
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
                          fontSize: AppFontSize.base,
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
                      return _AlbumTrackTile(
                        song: song,
                        index: index + 1,
                        songs: filteredSongs,
                      );
                    },
                    childCount: filteredSongs.length,
                  ),
                ),
              const SliverToBoxAdapter(child: SizedBox(height: 160)),
            ],
      hasSong: hasSong,
      miniPlayerKey: const ValueKey('album-mini-player'),
    );
  }

  String get _displayThumbnail => _metadata?.thumbnailUrl ?? widget.thumbnailUrl;

  Widget _buildCover() {
    const size = 200.0;
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
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.sm),
            child: CachedNetworkImage(
              imageUrl: _displayThumbnail,
              width: size,
              height: size,
              fit: BoxFit.cover,
              errorWidget: (_, __, ___) => Container(
                width: size,
                height: size,
                color: AppColors.surfaceLight,
                child: AppIcon(
                    icon: AppIcons.album, color: AppColors.textMuted, size: 64),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActions(List<Song> displaySongs) {
    final canPlay = displaySongs.isNotEmpty;
    final followedAlbums =
        ref.watch(libraryProvider.select((s) => s.followedAlbums));
    final albumId = _browseId ?? widget.albumBrowseId ?? widget.albumName ?? widget.songTitle;
    final isSaved = followedAlbums.any((a) => a.id == albumId);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.base),
      child: Row(
        children: [
          MultiDownloadButton(songs: displaySongs, size: 24, iconSize: 20),
          AppIconButton(
            icon: AppIcon(
              icon: AppIcons.shuffle,
              size: 24,
              color:
                  _shuffleEnabled ? AppColors.primary : AppColors.textMuted,
            ),
            onPressed: canPlay
                ? () => setState(() => _shuffleEnabled = !_shuffleEnabled)
                : null,
          ),
          AppIconButton(
            icon: AppIcon(
              icon: isSaved ? AppIcons.checkCircle : AppIcons.addCircleOutline,
              size: 24,
              color: isSaved ? AppColors.primary : AppColors.textMuted,
            ),
            onPressed: () {
              final album = LibraryAlbum(
                id: albumId,
                title: _metadata?.title ?? widget.albumName ?? widget.songTitle,
                artistName: _metadata?.subtitle ?? widget.artistName,
                thumbnailUrl: _displayThumbnail,
                browseId: _browseId ?? widget.albumBrowseId,
                followedAt: DateTime.now(),
              );
              ref.read(libraryProvider.notifier).toggleFollowAlbum(album);
            },
          ),
          const Spacer(),
          PlayCircleButton(
            onTap: canPlay ? _playAll : () {},
            size: 56,
            iconSize: 32,
          ),
        ],
      ),
    );
  }
}

class _AlbumTrackTile extends ConsumerWidget {
  const _AlbumTrackTile({
    required this.song,
    required this.index,
    required this.songs,
  });

  final Song song;
  final int index;
  final List<Song> songs;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SongListTile(
      song: song,
      index: index,
      showIndexIndicator: false,
      onTap: () {
        ref.read(playerProvider.notifier).playSong(song, queue: songs);
      },
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            song.durationFormatted,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: AppFontSize.md,
            ),
          ),
          AppIconButton(
            icon: AppIcon(
              icon: AppIcons.moreVert,
              color: AppColors.textMuted,
              size: 20,
            ),
            onPressedWithContext: (btnCtx) => showSongOptionsSheet(context, song: song, ref: ref, buttonContext: btnCtx),
            size: 40,
            iconSize: 20,
          ),
        ],
      ),
    );
  }
}
