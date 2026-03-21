import 'dart:math';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../components/shared/collection_detail_scaffold.dart';
import '../../components/ui/components_ui.dart';
import '../../../config/app_icons.dart';
import '../../../models/collection_result.dart';
import '../../../models/library_artist.dart';
import '../../../models/song.dart';
import '../../../shared/providers/content_settings_provider.dart';
import '../../../shared/providers/library_provider.dart';
import '../../../shared/providers/player_state_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/design_tokens.dart';
import 'package:tunify_logger/tunify_logger.dart';
import 'song_options_sheet.dart';

class ArtistPage extends ConsumerStatefulWidget {
  const ArtistPage({
    super.key,
    required this.artistName,
    required this.thumbnailUrl,
    this.artistBrowseId,
  });

  final String artistName;
  final String thumbnailUrl;
  final String? artistBrowseId;

  @override
  ConsumerState<ArtistPage> createState() => _ArtistPageState();
}

class _ArtistPageState extends ConsumerState<ArtistPage> {
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
    _fetchArtistSongs();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  Future<void> _fetchArtistSongs() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final streamManager = ref.read(streamManagerProvider);
      _browseId ??= widget.artistBrowseId;
      if (_browseId == null) {
        final result = await streamManager.searchResolveBrowseIds(
          widget.artistName,
          preferredArtistName: widget.artistName,
        );
        _browseId = result.artistBrowseId;
      }
      if (_browseId == null) {
        throw Exception('Could not find artist');
      }
      final result = await streamManager.getCollectionTracks(_browseId!);
      if (!mounted) return;
      setState(() {
        _metadata = result.metadata.hasData ? result.metadata : null;
        _songs = result.tracks.map((t) => Song.fromTrack(t)).toList();
        _loading = false;
      });
    } catch (e, stack) {
      logError('Artist load failed: $e\n$stack', tag: 'ArtistAlbum');
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
        message: 'Failed to load artist',
        onRetry: _fetchArtistSongs,
      );
    }
    final artistTitle = _metadata?.title ?? widget.artistName;
    final artistSubtitle = Text(
      '${displaySongs.length} ${displaySongs.length == 1 ? 'song' : 'songs'}',
      style: TextStyle(
        color: AppColors.textMuted.withValues(alpha: 0.9),
        fontSize: 14,
      ),
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
      title: artistTitle,
      headerExpandedChild: CollectionDetailExpandedContent(
        cover: _buildCover(),
        title: artistTitle,
        subtitle: artistSubtitle,
      ),
      actionRow: _buildActions(displaySongs),
      searchField: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.base),
        child: AppInputField(
          controller: _searchController,
          focusNode: _searchFocus,
          hintText: 'Search in this artist',
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
                      return _ArtistTrackTile(
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
      miniPlayerKey: const ValueKey('artist-mini-player'),
    );
  }

  String get _displayThumbnail => _metadata?.thumbnailUrl ?? widget.thumbnailUrl;

  Widget _buildCover() {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: AppSpacing.base),
        width: 200,
        height: 200,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.surfaceLight.withValues(alpha: 0.6),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ClipOval(
          child: CachedNetworkImage(
            imageUrl: _displayThumbnail,
            width: 200,
            height: 200,
            fit: BoxFit.cover,
            errorWidget: (_, __, ___) => Container(
              color: AppColors.surfaceLight,
              child: AppIcon(
                  icon: AppIcons.person, color: AppColors.textMuted, size: 64),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActions(List<Song> displaySongs) {
    final canPlay = displaySongs.isNotEmpty;
    final followedArtists =
        ref.watch(libraryProvider.select((s) => s.followedArtists));
    final artistId = _browseId ?? widget.artistBrowseId ?? widget.artistName;
    final isFollowed = followedArtists.any((a) => a.id == artistId);

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
                  _shuffleEnabled ? AppColors.accentGreen : AppColors.textMuted,
            ),
            onPressed: canPlay
                ? () => setState(() => _shuffleEnabled = !_shuffleEnabled)
                : null,
          ),
          AppIconButton(
            icon: AppIcon(
              icon: isFollowed
                  ? AppIcons.checkCircle
                  : AppIcons.addCircleOutline,
              size: 24,
              color: isFollowed ? AppColors.primary : AppColors.textMuted,
            ),
            onPressed: () {
              final artist = LibraryArtist(
                id: artistId,
                name: _metadata?.title ?? widget.artistName,
                thumbnailUrl: _displayThumbnail,
                browseId: _browseId ?? widget.artistBrowseId,
                followedAt: DateTime.now(),
              );
              ref.read(libraryProvider.notifier).toggleFollowArtist(artist);
            },
          ),
          const Spacer(),
          GestureDetector(
            onTap: canPlay ? _playAll : null,
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: canPlay
                    ? AppColors.accentGreen
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

class _ArtistTrackTile extends ConsumerWidget {
  const _ArtistTrackTile({
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
              fontSize: 13,
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
