import 'dart:async';
import 'dart:math';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:palette_generator/palette_generator.dart';

import 'package:tunify/ui/widgets/collection_detail_scaffold.dart';
import 'package:tunify/ui/widgets/loading_error_scaffold.dart';
import 'package:tunify/ui/widgets/pages/search_page.dart';
import 'package:tunify/ui/widgets/button.dart';
import 'package:tunify/ui/widgets/sheet.dart';
import 'package:tunify/ui/widgets/confirm_dialog.dart';
import 'package:tunify/ui/widgets/back_title_app_bar.dart';
import 'package:tunify/ui/widgets/input_field.dart';
import 'package:tunify/ui/widgets/empty_list_message.dart';
import 'package:tunify/ui/widgets/items/song_list_tile.dart';
import 'package:tunify/ui/widgets/items/now_playing_indicator.dart';
import 'package:tunify/ui/widgets/items/multi_download_button.dart';
import '../home/home_shared.dart';
import 'package:tunify/core/constants/app_icons.dart';
import 'package:tunify/data/models/library_album.dart';
import 'package:tunify/data/models/library_artist.dart';
import 'package:tunify/data/models/library_playlist.dart';
import 'package:tunify/data/models/playlist.dart';
import 'package:tunify/data/models/song.dart';
import 'package:tunify/features/settings/content_settings_provider.dart';
import 'package:tunify/features/home/home_state_provider.dart';
import 'package:tunify/features/library/library_provider.dart';
import 'package:tunify/features/player/player_state_provider.dart';
import 'package:tunify/ui/theme/app_colors.dart';
import 'package:tunify/ui/theme/design_tokens.dart';
import 'package:tunify/ui/theme/app_routes.dart';
import 'package:tunify/core/utils/string_utils.dart';
import '../player/song_options_sheet.dart';
import 'package:tunify/ui/widgets/items/mini_player.dart';
import 'package:tunify_logger/tunify_logger.dart';

enum CollectionType { playlist, album, artist }

// ─── Helpers ─────────────────────────────────────────────────────────────────

String _formatDuration(List<Song> songs) {
  if (songs.isEmpty) return '';
  final ms = songs.fold<int>(0, (s, e) => s + e.duration.inMilliseconds);
  final d = Duration(milliseconds: ms);
  final h = d.inHours;
  final m = d.inMinutes.remainder(60);
  return h > 0 ? '${h}h ${m}min' : '${m}min';
}

Widget _thumbPlaceholder({double size = 48}) => Container(
      width: size, height: size,
      color: AppColors.surfaceLight,
      child: Center(child: AppIcon(icon: AppIcons.musicNote, color: AppColors.textMuted, size: 24)),
    );

// ─── Screen ───────────────────────────────────────────────────────────────────

class LibraryPlaylistScreen extends ConsumerStatefulWidget {
  const LibraryPlaylistScreen({super.key, required this.playlistId})
      : remotePlaylist = null, albumSongTitle = null, albumArtistName = null,
        albumThumbnailUrl = null, albumBrowseId = null, albumName = null,
        albumSongId = null, collectionType = CollectionType.playlist;

  const LibraryPlaylistScreen.remote({super.key, required Playlist playlist})
      : playlistId = '', remotePlaylist = playlist,
        albumSongTitle = null, albumArtistName = null, albumThumbnailUrl = null,
        albumBrowseId = null, albumName = null, albumSongId = null,
        collectionType = CollectionType.playlist;

  const LibraryPlaylistScreen.album({
    super.key,
    required String songTitle,
    required String artistName,
    required String thumbnailUrl,
    String? browseId, String? name, String? songId,
  })  : playlistId = '', remotePlaylist = null,
        albumSongTitle = songTitle, albumArtistName = artistName,
        albumThumbnailUrl = thumbnailUrl, albumBrowseId = browseId,
        albumName = name, albumSongId = songId,
        collectionType = CollectionType.album;

  const LibraryPlaylistScreen.artist({
    super.key,
    required String artistName,
    required String thumbnailUrl,
    String? browseId,
  })  : playlistId = '', remotePlaylist = null,
        albumSongTitle = null, albumArtistName = null,
        albumThumbnailUrl = thumbnailUrl, albumBrowseId = browseId,
        albumName = artistName, albumSongId = null,
        collectionType = CollectionType.artist;

  final String playlistId;
  final Playlist? remotePlaylist;
  final CollectionType collectionType;
  final String? albumSongTitle, albumArtistName, albumThumbnailUrl;
  final String? albumBrowseId, albumName, albumSongId;

  bool get _isAlbum => collectionType == CollectionType.album;
  bool get _isArtist => collectionType == CollectionType.artist;
  bool get _isRemotePlaylist => remotePlaylist != null;

  @override
  ConsumerState<LibraryPlaylistScreen> createState() => _LibraryPlaylistScreenState();
}

class _LibraryPlaylistScreenState extends ConsumerState<LibraryPlaylistScreen> {
  LibraryPlaylist? _remoteAsLocal;
  bool _remoteLoading = false;
  String? _remoteError;
  bool _addingToLibrary = false;
  String? _resolvedBrowseId;
  String? _albumSubtitle;
  Color? _paletteColor;
  String? _lastPaletteUrl;
  LibraryPlaylist? _localPlaylistCache;
  bool _importedFetchTriggered = false;

  bool get _isRemote =>
      widget._isRemotePlaylist || widget._isAlbum || widget._isArtist || _isImportedLocal;

  bool get _isImportedLocal =>
      !widget._isRemotePlaylist && !widget._isAlbum && !widget._isArtist &&
      _localPlaylistCache?.isImported == true;

  @override
  void initState() {
    super.initState();
    if (widget._isRemotePlaylist) _fetchRemoteTracks();
    if (widget._isAlbum) _fetchAlbumTracks();
    if (widget._isArtist) _fetchArtistTracks();
  }

  // ── Fetch helpers ────────────────────────────────────────────────────────

  void _setLoading() => setState(() { _remoteLoading = true; _remoteError = null; });
  void _setError(Object e) { if (mounted) setState(() { _remoteError = e.toString(); _remoteLoading = false; }); }

  LibraryPlaylist _makePlaylist({
    required String id, required String name, String description = '',
    required List<Song> songs, String? imageUrl, String? browseId,
    DateTime? createdAt,
  }) => LibraryPlaylist(
    id: id, name: name, description: description,
    createdAt: createdAt ?? DateTime.now(), updatedAt: DateTime.now(),
    songs: songs, customImageUrl: imageUrl, isImported: true, browseId: browseId,
  );

  Future<void> _fetchRemoteTracks() async {
    _setLoading();
    try {
      final pl = widget.remotePlaylist!;
      final result = await ref.read(streamManagerProvider).getCollectionTracks(pl.id);
      if (!mounted) return;
      final songs = result.tracks.map(Song.fromTrack).toList();
      setState(() {
        _remoteAsLocal = _makePlaylist(
          id: pl.id, name: pl.title,
          description: pl.curatorName ?? pl.description,
          songs: songs,
          imageUrl: pl.coverUrl.isEmpty ? null : pl.coverUrl,
        );
        _remoteLoading = false;
      });
      _extractPalette(_remoteAsLocal?.customImageUrl ?? songs.firstOrNull?.thumbnailUrl);
    } catch (e) { _setError(e); }
  }

  Future<void> _fetchAlbumTracks() async {
    _setLoading();
    try {
      final sm = ref.read(streamManagerProvider);
      _resolvedBrowseId = widget.albumBrowseId;
      if (_resolvedBrowseId == null && widget.albumSongId != null) {
        final full = await sm.getSongFromPlayer(widget.albumSongId!)
            .timeout(const Duration(seconds: 10), onTimeout: () => null);
        _resolvedBrowseId = full?.albumBrowseId;
      }
      if (_resolvedBrowseId == null) {
        final r = await sm.searchResolveBrowseIds(
            '${widget.albumSongTitle} ${widget.albumArtistName}'.trim());
        _resolvedBrowseId = r.albumBrowseId;
      }
      if (_resolvedBrowseId == null) throw Exception('Could not find album');

      final result = await sm.getCollectionTracks(_resolvedBrowseId!);
      if (!mounted) return;
      final meta = result.metadata.hasData ? result.metadata : null;
      final songs = result.tracks.map(Song.fromTrack).toList();
      setState(() {
        _albumSubtitle = meta?.subtitle ?? widget.albumArtistName;
        _remoteAsLocal = _makePlaylist(
          id: _resolvedBrowseId!,
          name: meta?.title ?? widget.albumName ?? widget.albumSongTitle ?? '',
          description: meta?.subtitle ?? widget.albumArtistName ?? '',
          songs: songs,
          imageUrl: meta?.thumbnailUrl?.isNotEmpty == true
              ? meta!.thumbnailUrl : widget.albumThumbnailUrl,
        );
        _remoteLoading = false;
      });
      _extractPalette(_remoteAsLocal?.customImageUrl ?? widget.albumThumbnailUrl);
    } catch (e, s) { logError('Album load failed: $e\n$s', tag: 'AlbumScreen'); _setError(e); }
  }

  Future<void> _fetchArtistTracks() async {
    _setLoading();
    try {
      final sm = ref.read(streamManagerProvider);
      _resolvedBrowseId = widget.albumBrowseId;
      if (_resolvedBrowseId == null) {
        final r = await sm.searchResolveBrowseIds(
            widget.albumName ?? '', preferredArtistName: widget.albumName);
        _resolvedBrowseId = r.artistBrowseId;
      }
      if (_resolvedBrowseId == null) throw Exception('Could not find artist');

      final result = await sm.getCollectionTracks(_resolvedBrowseId!);
      if (!mounted) return;
      final meta = result.metadata.hasData ? result.metadata : null;
      final songs = result.tracks.map(Song.fromTrack).toList();
      setState(() {
        _albumSubtitle = null;
        _remoteAsLocal = _makePlaylist(
          id: _resolvedBrowseId!,
          name: meta?.title ?? widget.albumName ?? '',
          songs: songs,
          imageUrl: meta?.thumbnailUrl?.isNotEmpty == true
              ? meta!.thumbnailUrl : widget.albumThumbnailUrl,
        );
        _remoteLoading = false;
      });
      _extractPalette(_remoteAsLocal?.customImageUrl ?? widget.albumThumbnailUrl);
    } catch (e, s) { logError('Artist load failed: $e\n$s', tag: 'ArtistScreen'); _setError(e); }
  }

  Future<void> _fetchImportedPlaylistTracks() async {
    final local = _localPlaylistCache;
    if (local == null) return;
    final browseId = local.browseId ?? local.id;
    _setLoading();
    try {
      final result = await ref.read(streamManagerProvider).getCollectionTracks(browseId);
      if (!mounted) return;
      final meta = result.metadata.hasData ? result.metadata : null;
      final songs = result.tracks.map(Song.fromTrack).toList();
      setState(() {
        _remoteAsLocal = _makePlaylist(
          id: local.id,
          name: meta?.title ?? local.name,
          description: meta?.subtitle ?? local.description,
          songs: songs,
          imageUrl: meta?.thumbnailUrl?.isNotEmpty == true ? meta!.thumbnailUrl : local.customImageUrl,
          browseId: browseId,
          createdAt: local.createdAt,
        );
        _remoteLoading = false;
      });
      _extractPalette(_remoteAsLocal?.customImageUrl ?? songs.firstOrNull?.thumbnailUrl);
    } catch (e) { _setError(e); }
  }

  Future<void> _extractPalette(String? imageUrl) async {
    if (imageUrl == null || imageUrl.isEmpty || imageUrl == _lastPaletteUrl) return;
    _lastPaletteUrl = imageUrl;
    try {
      final gen = await PaletteGenerator.fromImageProvider(
        CachedNetworkImageProvider(imageUrl), size: const Size(200, 200));
      final raw = gen.lightVibrantColor?.color ?? gen.vibrantColor?.color ??
          gen.dominantColor?.color ?? AppColors.primary;
      final color = PaletteTheme.toPaletteColor(raw);
      if (mounted) setState(() => _paletteColor = color);
    } catch (_) {}
  }

  Future<void> _addToLibrary() async {
    final playlist = _remoteAsLocal;
    if (playlist == null) return;
    setState(() => _addingToLibrary = true);
    if (widget._isAlbum) {
      await ref.read(libraryProvider.notifier).toggleFollowAlbum(LibraryAlbum(
        id: _resolvedBrowseId ?? widget.albumBrowseId ?? widget.albumName ?? '',
        title: playlist.name,
        artistName: _albumSubtitle ?? widget.albumArtistName ?? '',
        thumbnailUrl: playlist.customImageUrl ?? widget.albumThumbnailUrl ?? '',
        browseId: _resolvedBrowseId ?? widget.albumBrowseId,
        followedAt: DateTime.now(),
      ));
    } else if (widget._isArtist) {
      await ref.read(libraryProvider.notifier).toggleFollowArtist(LibraryArtist(
        id: _resolvedBrowseId ?? widget.albumBrowseId ?? widget.albumName ?? '',
        name: playlist.name,
        thumbnailUrl: playlist.customImageUrl ?? widget.albumThumbnailUrl ?? '',
        browseId: _resolvedBrowseId ?? widget.albumBrowseId,
        followedAt: DateTime.now(),
      ));
    } else {
      await ref.read(libraryProvider.notifier).addPlaylistToLibrary(
        playlist.copyWith(browseId: playlist.browseId ?? playlist.id));
    }
    if (mounted) setState(() => _addingToLibrary = false);
  }

  Future<void> _deletePlaylistFromEmpty(
      BuildContext context, String name, String id) async {
    final ok = await showConfirmDialog(context,
        title: 'Delete playlist?',
        message: '$name will be removed from your library.',
        confirmLabel: 'Delete');
    if (ok && mounted && context.mounted) {
      Navigator.of(context).pop();
      await ref.read(libraryProvider.notifier).deletePlaylist(id);
    }
  }

  // ── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    // Cache local playlist and trigger fetches
    if (!widget._isRemotePlaylist && !widget._isAlbum && !widget._isArtist) {
      final local = ref.watch(libraryPlaylistByIdProvider(widget.playlistId));
      _localPlaylistCache = local;
      if (local != null && local.isImported && !_importedFetchTriggered) {
        _importedFetchTriggered = true;
        WidgetsBinding.instance.addPostFrameCallback(
            (_) { if (mounted) { _fetchImportedPlaylistTracks(); } });
      } else if (local != null && !local.isImported && _paletteColor == null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) { _extractPalette(local.customImageUrl ??
              local.songs.firstOrNull?.thumbnailUrl); }
        });
      }
    }

    if (_isRemote) {
      if (_remoteLoading) return const LoadingScaffold();
      if (_remoteError != null) {
        return ErrorScaffold(
          message: widget._isArtist ? 'Failed to load artist'
              : widget._isAlbum ? 'Failed to load album' : 'Failed to load playlist',
          onRetry: widget._isArtist ? _fetchArtistTracks
              : widget._isAlbum ? _fetchAlbumTracks
              : _isImportedLocal ? _fetchImportedPlaylistTracks
              : _fetchRemoteTracks,
        );
      }
    }

    final playlist = _isRemote
        ? _remoteAsLocal
        : ref.watch(libraryPlaylistByIdProvider(widget.playlistId));

    if (playlist == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: BackTitleAppBar(title: '', backgroundColor: AppColors.background),
        body: const Center(child: Text('Playlist not found',
            style: TextStyle(color: AppColors.textMuted))),
      );
    }

    final isInLibrary = _isRemote
        ? (_isImportedLocal ? true
            : widget._isAlbum
                ? ref.watch(libraryProvider.select(
                    (s) => s.followedAlbums.any((a) => a.id == playlist.id)))
                : widget._isArtist
                    ? ref.watch(libraryProvider.select(
                        (s) => s.followedArtists.any((a) => a.id == playlist.id)))
                    : ref.watch(libraryProvider.select(
                        (s) => s.playlists.any((p) => p.id == playlist.id))))
        : true;

    final isImported = _isRemote || playlist.isImported;
    final songs = playlist.sortedSongs;
    final hasSong = ref.watch(currentSongProvider) != null;
    final filteredSongs = filterByExplicitSetting(
        songs, ref.watch(showExplicitContentProvider));

    final coverUrl = _isRemote
        ? (_isImportedLocal
            ? _remoteAsLocal?.customImageUrl
            : isInLibrary
                ? playlist.customImageUrl
                : widget.remotePlaylist?.coverUrl ?? widget.albumThumbnailUrl)
        : playlist.customImageUrl;

    return CollectionDetailScaffold(
      isEmpty: songs.isEmpty,
      paletteColor: _paletteColor,
      emptyChild: (isImported || widget._isAlbum)
          ? const SliverFillRemaining(
              child: Center(child: Text('No songs found',
                  style: TextStyle(color: AppColors.textMuted))))
          : SliverFillRemaining(
              child: _EmptyState(
                playlistId: playlist.id,
                playlistName: playlist.name.capitalized,
                onStartAdding: () => _openAddToPlaylistSheet(
                    context, playlist.id, playlist.name, () => setState(() {})),
                onDeletePlaylist: () => _deletePlaylistFromEmpty(
                    context, playlist.name.capitalized, playlist.id),
              )),
      title: playlist.name.capitalized,
      headerExpandedChild: CollectionDetailExpandedContent(
        cover: _PlaylistCover(songs: songs, imageUrl: coverUrl, isCircle: widget._isArtist),
        title: playlist.name.capitalized,
        subtitle: _buildSubtitle(playlist),
      ),
      actionRow: _PlaylistActionRow(
        playlistId: playlist.id,
        songs: songs,
        filteredSongs: filteredSongs,
        disableShuffle: _isRemote && !isInLibrary,
        showLibraryStatus: isImported,
        isInLibrary: isInLibrary,
        onAddToLibrary: _addToLibrary,
        addingToLibrary: _addingToLibrary,
        collectionType: widget.collectionType,
      ),
      playButton: _PlaylistPlayButton(
        playlistId: playlist.id,
        songs: songs,
        filteredSongs: filteredSongs,
        disableShuffle: _isRemote && !isInLibrary,
        collectionType: widget.collectionType,
      ),
      pills: (widget._isAlbum || widget._isArtist || isImported)
          ? null
          : _PlaylistPillRow(
              playlistId: widget.playlistId.isNotEmpty ? widget.playlistId : playlist.id,
              playlist: playlist,
              onPlaylistUpdated: () => setState(() {}),
            ),
      searchField: _SearchInPlaylistTap(songs: songs, playlistId: playlist.id),
      bodySlivers: [
        const SliverToBoxAdapter(child: CollectionTrackListHeader(showDurationColumn: true)),
        if (filteredSongs.isEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xxl),
              child: Center(child: Text('No songs',
                  style: TextStyle(color: AppColors.textMuted.withValues(alpha: 0.9),
                      fontSize: AppFontSize.base))),
            ),
          )
        else
          SliverList(delegate: SliverChildBuilderDelegate(
            (context, i) {
              final song = filteredSongs[i];
              return _TrackTile(
                song: song,
                index: songs.indexOf(song) + 1,
                songs: songs,
                playlistId: playlist.id,
                queueSource: widget._isAlbum ? 'album' : 'playlist',
                isImported: isImported,
              );
            },
            childCount: filteredSongs.length,
          )),
        const SliverToBoxAdapter(child: SizedBox(height: 160)),
      ],
      hasSong: hasSong,
      miniPlayerKey: const ValueKey('playlist-mini-player'),
    );
  }

  Widget _buildSubtitle(LibraryPlaylist playlist) {
    final muted = TextStyle(color: AppColors.textMuted.withValues(alpha: 0.9), fontSize: AppFontSize.base);
    final countDuration = Row(children: [
      Text('${playlist.songs.length} ${playlist.songs.length == 1 ? 'song' : 'songs'}', style: muted),
      if (playlist.songs.isNotEmpty) ...[
        Text(' • ', style: muted),
        Text(_formatDuration(playlist.songs), style: muted),
      ],
    ]);
    if (!widget._isAlbum) return countDuration;
    final artistLine = _albumSubtitle ?? widget.albumArtistName;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (artistLine != null)
          Text(artistLine, style: const TextStyle(
              color: AppColors.textSecondary, fontSize: AppFontSize.xl,
              fontWeight: FontWeight.w500)),
        const SizedBox(height: AppSpacing.sm),
        countDuration,
      ],
    );
  }
}

// ─── Cover ────────────────────────────────────────────────────────────────────

class _PlaylistCover extends StatelessWidget {
  const _PlaylistCover({required this.songs, this.imageUrl, this.isCircle = false});

  final List<Song> songs;
  final String? imageUrl;
  final bool isCircle;

  static const double _size = 200.0;

  @override
  Widget build(BuildContext context) {
    final shadow = BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 16, offset: const Offset(0, 6));

    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: AppSpacing.base),
          width: isCircle ? _size : null,
          height: isCircle ? _size : null,
          decoration: BoxDecoration(
            shape: isCircle ? BoxShape.circle : BoxShape.rectangle,
            borderRadius: isCircle ? null : BorderRadius.circular(AppRadius.sm),
            color: AppColors.surfaceLight.withValues(alpha: 0.6),
            boxShadow: [shadow],
          ),
          child: isCircle
              ? ClipOval(child: CachedNetworkImage(
                  imageUrl: imageUrl!, width: _size, height: _size, fit: BoxFit.cover,
                  errorWidget: (_, __, ___) => Container(color: AppColors.surfaceLight,
                      child: AppIcon(icon: AppIcons.person, color: AppColors.textMuted, size: 64))))
              : Padding(
                  padding: const EdgeInsets.all(4),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                    child: CachedNetworkImage(
                      imageUrl: imageUrl!, width: _size - 8, height: _size - 8, fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => _mosaic(songs, _size - 8)),
                  )),
        ),
      );
    }

    if (songs.isEmpty) {
      return Center(child: Container(
        width: _size, height: _size,
        decoration: BoxDecoration(color: AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(AppRadius.sm)),
        child: AppIcon(icon: AppIcons.musicNote, color: AppColors.textMuted, size: 64)));
    }

    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: AppSpacing.base),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          color: AppColors.surfaceLight.withValues(alpha: 0.6),
          boxShadow: [shadow],
        ),
        child: Padding(padding: const EdgeInsets.all(4), child: _mosaic(songs, _size - 8)),
      ),
    );
  }

  static Widget _mosaic(List<Song> songs, double size) {
    if (songs.length == 1) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: CachedNetworkImage(imageUrl: songs.first.thumbnailUrl,
            width: size, height: size, fit: BoxFit.cover,
            errorWidget: (_, __, ___) => _cell(null, size)));
    }
    final urls = songs.take(4).map((s) => s.thumbnailUrl).toList();
    const gap = 2.0;
    final cell = (size - gap) / 2;
    return SizedBox(width: size, height: size,
      child: Column(children: [
        Row(children: [_cell(urls.elementAtOrNull(0), cell), const SizedBox(width: gap), _cell(urls.elementAtOrNull(1), cell)]),
        const SizedBox(height: gap),
        Row(children: [_cell(urls.elementAtOrNull(2), cell), const SizedBox(width: gap), _cell(urls.elementAtOrNull(3), cell)]),
      ]));
  }

  static Widget _cell(String? url, double s) {
    return SizedBox(width: s, height: s,
      child: url != null
          ? Builder(builder: (ctx) {
              final px = (s * MediaQuery.devicePixelRatioOf(ctx)).round();
              return CachedNetworkImage(imageUrl: url, fit: BoxFit.cover,
                  memCacheWidth: px, memCacheHeight: px,
                  errorWidget: (_, __, ___) => _placeholder(s: s));
            })
          : _placeholder(s: s));
  }

  static Widget _placeholder({required double s}) => Container(
      width: s, height: s, color: AppColors.surfaceLight,
      child: AppIcon(icon: AppIcons.musicNote, color: AppColors.textMuted));
}

// ─── Action Row ───────────────────────────────────────────────────────────────

class _PlaylistActionRow extends ConsumerWidget {
  const _PlaylistActionRow({
    required this.playlistId, required this.songs, required this.filteredSongs,
    this.disableShuffle = false, this.showLibraryStatus = false,
    this.isInLibrary = true, this.onAddToLibrary, this.addingToLibrary = false,
    this.collectionType = CollectionType.playlist,
  });

  final String playlistId;
  final List<Song> songs, filteredSongs;
  final bool disableShuffle, showLibraryStatus, isInLibrary, addingToLibrary;
  final VoidCallback? onAddToLibrary;
  final CollectionType collectionType;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shuffleEnabled = disableShuffle ? false : ref.watch(
        libraryProvider.select((s) =>
            s.playlists.where((p) => p.id == playlistId).firstOrNull?.shuffleEnabled ?? false));
    return Padding(
      padding: const EdgeInsets.only(left: AppSpacing.sm, right: AppSpacing.base),
      child: Row(children: [
        AppIconButton(
          icon: AppIcon(icon: AppIcons.shuffle, size: 24,
              color: shuffleEnabled ? AppColors.primary : AppColors.textMuted),
          onPressed: filteredSongs.isNotEmpty && !disableShuffle
              ? () => ref.read(libraryProvider.notifier).togglePlaylistShuffle(playlistId)
              : null,
          size: 40, iconSize: 24,
          color: shuffleEnabled ? AppColors.primary : AppColors.textMuted,
        ),
        MultiDownloadButton(songs: songs, size: 24, iconSize: 20),
        if (showLibraryStatus)
          AppIconButton(
            icon: addingToLibrary
                ? const SizedBox(width: 22, height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.textMuted))
                : AppIcon(
                    icon: isInLibrary ? AppIcons.checkCircle : AppIcons.addCircleOutline,
                    size: 24, color: isInLibrary ? AppColors.primary : AppColors.textMuted),
            onPressed: (!isInLibrary && !addingToLibrary) ? onAddToLibrary : null,
            size: 40, iconSize: 24,
          ),
        const Spacer(),
        const SizedBox(width: 56, height: 56), // placeholder for docking play button
      ]),
    );
  }
}

// ─── Play Button ──────────────────────────────────────────────────────────────

class _PlaylistPlayButton extends ConsumerWidget {
  const _PlaylistPlayButton({
    required this.playlistId, required this.songs, required this.filteredSongs,
    required this.disableShuffle, required this.collectionType,
  });

  final String playlistId;
  final List<Song> songs, filteredSongs;
  final bool disableShuffle;
  final CollectionType collectionType;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shuffleEnabled = disableShuffle ? false : ref.watch(
        libraryProvider.select((s) =>
            s.playlists.where((p) => p.id == playlistId).firstOrNull?.shuffleEnabled ?? false));
    return PlayCircleButton(
      onTap: filteredSongs.isNotEmpty ? () {
        final queue = shuffleEnabled
            ? (List<Song>.from(filteredSongs)..shuffle(Random()))
            : songs;
        ref.read(playerProvider.notifier).playSong(queue.first, queue: queue,
            playlistId: playlistId,
            queueSource: collectionType == CollectionType.album ? 'album' : 'playlist');
      } : () {},
      size: 48, iconSize: 28,
    );
  }
}

// ─── Pills ────────────────────────────────────────────────────────────────────

class _PlaylistPillRow extends ConsumerWidget {
  const _PlaylistPillRow({
    required this.playlistId, required this.playlist, required this.onPlaylistUpdated,
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
        child: Row(children: [
          _Pill(icon: AppIcons.add, label: 'Add',
              onTap: () => _openAddToPlaylistSheet(context, playlistId, playlist.name, onPlaylistUpdated)),
          const SizedBox(width: AppSpacing.sm),
          _Pill(icon: AppIcons.edit, label: 'Edit',
              onTap: () => _openEditSheet(context, playlistId, playlist)),
          const SizedBox(width: AppSpacing.sm),
          _Pill(icon: AppIcons.sort, label: 'Sort',
              onTap: () => _openSortSheet(context, playlistId, playlist)),
          const SizedBox(width: AppSpacing.sm),
          _Pill(icon: AppIcons.editNote, label: 'Name & details',
              onTap: () => _openNameAndDetailsSheet(context, playlistId, playlist)),
        ]),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.icon, required this.label, required this.onTap});
  final List<List<dynamic>> icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.textMuted.withValues(alpha: 0.5)),
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          AppIcon(icon: icon, size: 18, color: AppColors.textSecondary),
          const SizedBox(width: AppSpacing.xs),
          Text(label, style: const TextStyle(color: AppColors.textSecondary,
              fontSize: AppFontSize.md, fontWeight: FontWeight.w500)),
        ]),
      ),
    );
  }
}

// ─── Sheet openers ────────────────────────────────────────────────────────────

void _openAddToPlaylistSheet(BuildContext context, String playlistId,
    String playlistName, VoidCallback onUpdated) {
  FocusManager.instance.primaryFocus?.unfocus();
  showAppSheet(context,
      maxHeight: MediaQuery.of(context).size.height * 0.75,
      child: _AddToPlaylistSheet(
          playlistId: playlistId, playlistName: playlistName, onAdded: onUpdated));
}

void _openEditSheet(BuildContext context, String playlistId, LibraryPlaylist playlist) {
  FocusManager.instance.primaryFocus?.unfocus();
  Navigator.of(context).push(appPageRoute<void>(
      builder: (_) => _EditPlaylistSheet(playlistId: playlistId, playlist: playlist)));
}

void _openSortSheet(BuildContext context, String playlistId, LibraryPlaylist playlist) {
  FocusManager.instance.primaryFocus?.unfocus();
  showAppSheet(context,
      child: _SortPlaylistSheet(playlistId: playlistId, playlist: playlist));
}

void _openNameAndDetailsSheet(BuildContext context, String playlistId, LibraryPlaylist playlist) {
  FocusManager.instance.primaryFocus?.unfocus();
  showAppSheet(context,
      maxHeight: MediaQuery.of(context).size.height * 0.6,
      child: _NameAndDetailsSheet(playlistId: playlistId, playlist: playlist));
}

// ─── Add-to-playlist sheet ────────────────────────────────────────────────────

class _AddToPlaylistSheet extends ConsumerStatefulWidget {
  const _AddToPlaylistSheet({
    required this.playlistId, required this.playlistName, required this.onAdded,
  });
  final String playlistId, playlistName;
  final VoidCallback onAdded;

  @override
  ConsumerState<_AddToPlaylistSheet> createState() => _AddToPlaylistSheetState();
}

class _AddToPlaylistSheetState extends ConsumerState<_AddToPlaylistSheet> {
  final _searchCtrl = TextEditingController();
  List<Song> _results = [];
  bool _searching = false;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _search(String q) async {
    if (q.trim().isEmpty) { setState(() { _results = []; _searching = false; }); return; }
    setState(() => _searching = true);
    try {
      final r = await ref.read(playerProvider.notifier).searchSongs(q.trim());
      if (mounted) setState(() { _results = r; _searching = false; });
    } catch (_) {
      if (mounted) setState(() { _results = []; _searching = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final recent = ref.watch(recentlyPlayedProvider);
    final inIds = ref.watch(libraryProvider.select((s) =>
        s.playlists.where((x) => x.id == widget.playlistId).firstOrNull
            ?.songs.map((e) => e.id).toSet() ?? <String>{}));
    final showRecent = _searchCtrl.text.trim().isEmpty;
    final list = showRecent ? recent : _results;

    return Column(mainAxisSize: MainAxisSize.max, children: [
      GestureDetector(
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
        behavior: HitTestBehavior.translucent,
        child: Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: kSheetHorizontalPadding, vertical: AppSpacing.base),
          child: AppInputField(
            controller: _searchCtrl,
            hintText: 'Search YouTube Music',
            style: InputFieldStyle.filled,
            prefixIcon: AppIcon(icon: AppIcons.search, color: AppColors.textMuted, size: 20),
            suffixIcon: _searchCtrl.text.trim().isNotEmpty
                ? AppIconButton(
                    icon: AppIcon(icon: AppIcons.clear, size: 24, color: AppColors.textMuted),
                    onPressed: () { _searchCtrl.clear(); setState(() => _results = []); },
                    size: 40, iconSize: 24)
                : null,
            onChanged: (v) {
              setState(() {});
              _debounce?.cancel();
              _debounce = Timer(const Duration(milliseconds: 350),
                  () { if (mounted) _search(_searchCtrl.text); });
            },
            onSubmitted: _search,
          ),
        ),
      ),
      if (showRecent)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: kSheetHorizontalPadding),
          child: Align(alignment: Alignment.centerLeft,
              child: Text('Recently played', style: TextStyle(
                  color: AppColors.textMuted, fontSize: AppFontSize.sm,
                  fontWeight: FontWeight.w600))),
        ),
      const SizedBox(height: AppSpacing.sm),
      Expanded(child: _searching
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : list.isEmpty
              ? Center(child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: Text(
                    showRecent ? 'No recently played songs'
                        : _searchCtrl.text.trim().isEmpty
                            ? 'Type above to search for songs'
                            : 'No results for "${_searchCtrl.text.trim()}"',
                    style: const TextStyle(color: AppColors.textMuted),
                    textAlign: TextAlign.center)))
              : ListView.builder(
                  itemCount: list.length,
                  itemBuilder: (context, i) {
                    final song = list[i];
                    final inPlaylist = inIds.contains(song.id);
                    final isNowPlaying = ref.watch(currentSongProvider)?.id == song.id;
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: kSheetHorizontalPadding, vertical: 8),
                      leading: NowPlayingThumbnail(
                        isPlaying: isNowPlaying,
                        isActuallyPlaying: ref.watch(isPlayingProvider),
                        size: 48,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(AppRadius.xs),
                          child: CachedNetworkImage(imageUrl: song.thumbnailUrl,
                              width: 48, height: 48, fit: BoxFit.cover,
                              errorWidget: (_, __, ___) =>
                                  AppIcon(icon: AppIcons.musicNote, color: AppColors.textMuted, size: 28)),
                        ),
                      ),
                      title: Text(song.title, maxLines: 1, overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: isNowPlaying ? AppColors.accent : AppColors.textPrimary)),
                      subtitle: Text(song.artist, maxLines: 1, overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: AppColors.textMuted, fontSize: AppFontSize.sm)),
                      trailing: AppIconButton(
                        icon: AppIcon(
                          icon: inPlaylist ? AppIcons.checkCircle : AppIcons.addCircleOutline,
                          color: inPlaylist ? AppColors.primary : AppColors.textSecondary,
                          size: 24),
                        onPressed: () {
                          if (inPlaylist) {
                            ref.read(libraryProvider.notifier)
                                .removeSongFromPlaylist(widget.playlistId, song.id);
                          } else {
                            ref.read(libraryProvider.notifier)
                                .addSongsToPlaylist(widget.playlistId, [song]);
                          }
                          widget.onAdded();
                        },
                      ),
                    );
                  }),
      ),
    ]);
  }
}

// ─── Search in playlist ───────────────────────────────────────────────────────

class _SearchInPlaylistTap extends StatelessWidget {
  const _SearchInPlaylistTap({required this.songs, required this.playlistId});
  final List<Song> songs;
  final String playlistId;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.base),
      child: GestureDetector(
        onTap: () => Navigator.of(context).push(appPageRoute<void>(
            builder: (_) => _PlaylistSearchPage(songs: songs, playlistId: playlistId))),
        child: Container(
          height: 44,
          decoration: BoxDecoration(
              color: AppColors.surfaceLight.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(AppRadius.input)),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Row(children: [
            AppIcon(icon: AppIcons.search,
                color: AppColors.textMuted.withValues(alpha: 0.9), size: 20),
            const SizedBox(width: AppSpacing.sm),
            Text('Find in playlist', style: TextStyle(
                color: AppColors.textMuted.withValues(alpha: 0.9), fontSize: AppFontSize.base)),
          ]),
        ),
      ),
    );
  }
}

class _PlaylistSearchPage extends ConsumerStatefulWidget {
  const _PlaylistSearchPage({required this.songs, required this.playlistId});
  final List<Song> songs;
  final String playlistId;

  @override
  ConsumerState<_PlaylistSearchPage> createState() => _PlaylistSearchPageState();
}

class _PlaylistSearchPageState extends ConsumerState<_PlaylistSearchPage> {
  late final TextEditingController _ctrl;
  late final FocusNode _focus;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController()..addListener(() => setState(() {}));
    _focus = FocusNode();
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (mounted && _focus.canRequestFocus) _focus.requestFocus();
    });
  }

  @override
  void dispose() { _ctrl.dispose(); _focus.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final q = _ctrl.text.trim().toLowerCase();
    final hasSong = ref.watch(currentSongProvider) != null;
    final filtered = filterByExplicitSetting(
      q.isEmpty ? widget.songs
          : widget.songs.where((s) =>
              s.title.toLowerCase().contains(q) ||
              s.artist.toLowerCase().contains(q)).toList(),
      ref.watch(showExplicitContentProvider),
    );

    final body = q.isEmpty
        ? SearchPageEmptyState(
            icon: AppIcon(icon: AppIcons.search, size: 64, color: AppColors.textMuted),
            heading: 'Find in playlist', subheading: 'Search by song title or artist')
        : filtered.isEmpty
            ? EmptyListMessage(emptyLabel: 'matches', query: q,
                style: const TextStyle(color: AppColors.textSecondary,
                    fontSize: AppFontSize.lg, fontWeight: FontWeight.w600))
            : ListView.builder(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.only(bottom: AppSpacing.max),
                itemCount: filtered.length,
                itemBuilder: (_, i) => _TrackTile(
                  song: filtered[i], index: widget.songs.indexOf(filtered[i]) + 1,
                  songs: widget.songs, playlistId: widget.playlistId));

    final page = SharedSearchPage(
      controller: _ctrl, focusNode: _focus,
      onBack: () => Navigator.of(context).pop(),
      onClear: () => setState(() {}),
      hintText: 'Find in playlist', autofocus: false, body: body);

    if (!hasSong) return page;
    return Scaffold(
      backgroundColor: AppColors.background,
      resizeToAvoidBottomInset: false,
      body: SafeArea(bottom: false, child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: page),
          const MiniPlayer(key: ValueKey('playlist-search-mini-player')),
          SizedBox(height: MediaQuery.of(context).viewPadding.bottom),
        ])),
    );
  }
}

// ─── Track tile ───────────────────────────────────────────────────────────────

class _TrackTile extends ConsumerWidget {
  const _TrackTile({
    required this.song, required this.index, required this.songs,
    required this.playlistId, this.queueSource = 'playlist', this.isImported = false,
  });
  final Song song;
  final int index;
  final List<Song> songs;
  final String playlistId, queueSource;
  final bool isImported;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SongListTile(
      song: song, index: index, showIndexIndicator: false,
      onTap: () => ref.read(playerProvider.notifier).playSong(song,
          queue: songs, playlistId: playlistId, queueSource: queueSource),
      trailing: Row(mainAxisSize: MainAxisSize.min, children: [
        Text(song.durationFormatted,
            style: const TextStyle(color: AppColors.textMuted, fontSize: AppFontSize.md)),
        AppIconButton(
          icon: AppIcon(icon: AppIcons.moreVert, color: AppColors.textMuted, size: 20),
          onPressedWithContext: (btnCtx) => showSongOptionsSheet(context,
              song: song, ref: ref, buttonContext: btnCtx,
              showAddToPlaylist: !isImported,
              onRemoveFromPlaylist: isImported ? null : () {
                ref.read(libraryProvider.notifier).removeSongFromPlaylist(playlistId, song.id);
                if (context.mounted) { ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Removed from playlist'),
                        behavior: SnackBarBehavior.floating)); }
              }),
          size: 40, iconSize: 20,
        ),
      ]),
    );
  }
}

// ─── Empty state ──────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.playlistId, required this.playlistName,
    required this.onStartAdding, required this.onDeletePlaylist,
  });
  final String playlistId, playlistName;
  final VoidCallback onStartAdding, onDeletePlaylist;

  @override
  Widget build(BuildContext context) {
    return Center(child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        AppIcon(icon: AppIcons.musicNote, size: 64,
            color: AppColors.textMuted.withValues(alpha: 0.5)),
        const SizedBox(height: AppSpacing.xl),
        const Text('No songs yet', style: TextStyle(color: AppColors.textPrimary,
            fontSize: AppFontSize.h3, fontWeight: FontWeight.w700)),
        const SizedBox(height: AppSpacing.sm),
        Text('Add songs from Now Playing (⋯ → Add to playlist) or from Search.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textMuted.withValues(alpha: 0.9),
                fontSize: AppFontSize.base)),
        const SizedBox(height: AppSpacing.xl),
        AppButton(label: 'Start adding songs',
            icon: AppIcon(icon: AppIcons.add, size: 20, color: AppColors.background),
            onPressed: onStartAdding,
            backgroundColor: AppColors.primary, foregroundColor: AppColors.background),
        const SizedBox(height: AppSpacing.lg),
        AppButton(label: 'Delete playlist', variant: AppButtonVariant.text,
            foregroundColor: AppColors.accentRed, onPressed: onDeletePlaylist),
      ]),
    ));
  }
}

// ─── Edit Playlist Sheet ──────────────────────────────────────────────────────

class _EditPlaylistSheet extends ConsumerStatefulWidget {
  const _EditPlaylistSheet({required this.playlistId, required this.playlist});
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

  void _toggleRemove(Song song) => setState(() {
        if (_pendingRemoveIds.contains(song.id)) {
          _pendingRemoveIds.remove(song.id);
        } else {
          _pendingRemoveIds.add(song.id);
        }
      });

  void _onReorder(int oldIndex, int newIndex) => setState(() {
        if (newIndex > oldIndex) newIndex -= 1;
        _items.insert(newIndex, _items.removeAt(oldIndex));
      });

  Future<void> _save() async {
    final toKeep = _items.where((s) => !_pendingRemoveIds.contains(s.id)).toList();
    await ref.read(libraryProvider.notifier).setPlaylistSongs(widget.playlistId, toKeep);
    if (mounted) {
      ref.invalidate(libraryPlaylistByIdProvider);
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Playlist updated'), behavior: SnackBarBehavior.floating));
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
            label: 'Save', variant: AppButtonVariant.text,
            foregroundColor: AppColors.primary, onPressed: _save, height: 40),
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
          return ListTile(
            key: ValueKey(song.id),
            leading: Row(mainAxisSize: MainAxisSize.min, children: [
              AppIconButton(
                icon: AppIcon(
                  icon: marked ? AppIcons.removeCircle : AppIcons.removeCircleOutline,
                  color: marked ? AppColors.accentRed : AppColors.textMuted, size: 22),
                onPressed: () => _toggleRemove(song), size: 40, iconSize: 22),
              NowPlayingThumbnail(
                isPlaying: isNowPlaying,
                isActuallyPlaying: ref.watch(isPlayingProvider),
                size: 48,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.xs),
                  child: CachedNetworkImage(
                    imageUrl: song.thumbnailUrl, width: 48, height: 48, fit: BoxFit.cover,
                    placeholder: (_, __) => _thumbPlaceholder(),
                    errorWidget: (_, __, ___) => _thumbPlaceholder()),
                ),
              ),
            ]),
            title: Text(song.title, style: TextStyle(
                color: marked ? AppColors.textMuted
                    : isNowPlaying ? AppColors.accent : AppColors.textPrimary,
                decoration: marked ? TextDecoration.lineThrough : null)),
            subtitle: Text(song.artist, style: TextStyle(
                color: AppColors.textMuted,
                decoration: marked ? TextDecoration.lineThrough : null)),
            trailing: ReorderableDragStartListener(
              index: index,
              child: AppIcon(icon: AppIcons.dragHandle, color: AppColors.textMuted, size: 22)),
          );
        },
      ),
    );
  }
}

// ─── Sort Sheet ───────────────────────────────────────────────────────────────

class _SortPlaylistSheet extends ConsumerWidget {
  const _SortPlaylistSheet({required this.playlistId, required this.playlist});
  final String playlistId;
  final LibraryPlaylist playlist;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = playlist.sortOrder;
    return Column(mainAxisSize: MainAxisSize.min, children: [
      Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: kSheetHorizontalPadding, vertical: AppSpacing.xl),
        child: const Text('Sort by', style: TextStyle(
            color: AppColors.textPrimary, fontSize: AppFontSize.xxl,
            fontWeight: FontWeight.w700)),
      ),
      _SortTile(
        label: 'Custom order',
        selected: current == PlaylistTrackSortOrder.customOrder,
        onTap: () async {
          await ref.read(libraryProvider.notifier)
              .setPlaylistSortOrder(playlistId, PlaylistTrackSortOrder.customOrder);
          if (context.mounted) Navigator.pop(context);
        },
      ),
      _SortTile(
        label: 'Title',
        selected: current == PlaylistTrackSortOrder.title,
        onTap: () async {
          await ref.read(libraryProvider.notifier)
              .setPlaylistSortOrder(playlistId, PlaylistTrackSortOrder.title);
          if (context.mounted) Navigator.pop(context);
        },
      ),
      _SortTile(
        label: 'Recently added',
        selected: current == PlaylistTrackSortOrder.recentlyAdded,
        onTap: () async {
          await ref.read(libraryProvider.notifier)
              .setPlaylistSortOrder(playlistId, PlaylistTrackSortOrder.recentlyAdded);
          if (context.mounted) Navigator.pop(context);
        },
      ),
      const SizedBox(height: AppSpacing.lg),
    ]);
  }
}

class _SortTile extends StatelessWidget {
  const _SortTile({required this.label, required this.selected, required this.onTap});
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
          ? AppIcon(icon: AppIcons.check, color: AppColors.primary, size: 24)
          : null,
      onTap: onTap,
    );
  }
}

// ─── Name & Details Sheet ─────────────────────────────────────────────────────

class _NameAndDetailsSheet extends ConsumerStatefulWidget {
  const _NameAndDetailsSheet({required this.playlistId, required this.playlist});
  final String playlistId;
  final LibraryPlaylist playlist;

  @override
  ConsumerState<_NameAndDetailsSheet> createState() => _NameAndDetailsSheetState();
}

class _NameAndDetailsSheetState extends ConsumerState<_NameAndDetailsSheet> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _descCtrl;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.playlist.name);
    _descCtrl = TextEditingController(text: widget.playlist.description);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;
    await ref.read(libraryProvider.notifier).updatePlaylist(
        widget.playlistId, name: name, description: _descCtrl.text.trim());
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Playlist updated'), behavior: SnackBarBehavior.floating));
      Navigator.of(context).pop();
    }
  }

  Future<void> _delete() async {
    final ok = await showConfirmDialog(context,
        title: 'Delete playlist?',
        message: '${widget.playlist.name.capitalized} will be removed from your library.',
        confirmLabel: 'Delete');
    if (ok && mounted) {
      Navigator.of(context).popUntil((r) => r.isFirst);
      await ref.read(libraryProvider.notifier).deletePlaylist(widget.playlistId);
    }
  }

  @override
  Widget build(BuildContext context) {
    const coverSize = 120.0;
    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      behavior: HitTestBehavior.translucent,
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
              kSheetHorizontalPadding, AppSpacing.lg, kSheetHorizontalPadding, AppSpacing.sm),
          child: Row(children: [
            const SizedBox(width: 8),
            AppIconButton(
              icon: AppIcon(icon: AppIcons.back, size: 22, color: AppColors.textPrimary),
              onPressed: () => Navigator.of(context).pop(), size: 40, iconSize: 22),
            const Spacer(),
            AppButton(label: 'Save', variant: AppButtonVariant.text,
                foregroundColor: AppColors.primary, onPressed: _save, height: 40),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: kSheetHorizontalPadding),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Column(children: [
              _NameDetailsCover(songs: widget.playlist.songs, size: coverSize),
              const SizedBox(height: AppSpacing.sm),
              AppButton(
                label: 'Change', variant: AppButtonVariant.text,
                foregroundColor: AppColors.textSecondary,
                icon: AppIcon(icon: AppIcons.edit, size: 18, color: AppColors.textSecondary),
                onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Cover is based on the first songs in the playlist.'),
                        behavior: SnackBarBehavior.floating)),
                height: 40),
            ]),
            const SizedBox(width: AppSpacing.xl),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              AppInputField(controller: _nameCtrl, hintText: 'Name', style: InputFieldStyle.filled),
              const SizedBox(height: AppSpacing.md),
              AppInputField(controller: _descCtrl, hintText: 'Description',
                  style: InputFieldStyle.filled, maxLines: 3),
            ])),
          ]),
        ),
        const SizedBox(height: AppSpacing.xxl),
        AppButton(label: 'Delete playlist', variant: AppButtonVariant.text,
            foregroundColor: AppColors.accentRed, onPressed: _delete),
      ]),
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
        width: size, height: size,
        decoration: BoxDecoration(color: AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(AppRadius.sm)),
        child: AppIcon(icon: AppIcons.musicNote, color: AppColors.textMuted));
    }
    if (songs.length == 1) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: CachedNetworkImage(imageUrl: songs.first.thumbnailUrl,
            width: size, height: size, fit: BoxFit.cover,
            errorWidget: (_, __, ___) =>
                AppIcon(icon: AppIcons.musicNote, color: AppColors.textMuted)));
    }
    final urls = songs.take(4).map((s) => s.thumbnailUrl).toList();
    const gap = 2.0;
    final cell = (size - gap) / 2;
    return SizedBox(width: size, height: size,
      child: Column(children: [
        Row(children: [
          _cell(urls.elementAtOrNull(0), cell),
          SizedBox(width: gap),
          _cell(urls.elementAtOrNull(1), cell),
        ]),
        const SizedBox(height: gap),
        Row(children: [
          _cell(urls.elementAtOrNull(2), cell),
          SizedBox(width: gap),
          _cell(urls.elementAtOrNull(3), cell),
        ]),
      ]));
  }

  Widget _cell(String? url, double s) => SizedBox(width: s, height: s,
      child: url != null
          ? CachedNetworkImage(imageUrl: url, fit: BoxFit.cover,
              errorWidget: (_, __, ___) => _place(s))
          : _place(s));

  Widget _place(double s) => Container(width: s, height: s,
      color: AppColors.surfaceLight,
      child: AppIcon(icon: AppIcons.musicNote, color: AppColors.textMuted));
}
