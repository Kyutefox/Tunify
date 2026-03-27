import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:palette_generator/palette_generator.dart';

import 'package:tunify/features/library/collection_track_cache.dart';
import 'package:tunify/ui/screens/shared/collection/collection_detail_scaffold.dart';
import 'package:tunify/ui/widgets/common/loading_error_scaffold.dart';
import 'package:tunify/ui/screens/shared/search/search_page.dart';
import 'package:tunify/ui/widgets/common/button.dart';
import 'package:tunify/ui/widgets/common/sheet.dart';
import 'package:tunify/ui/widgets/common/confirm_dialog.dart';
import 'package:tunify/ui/widgets/common/back_title_app_bar.dart';
import 'package:tunify/ui/widgets/common/input_field.dart';
import 'package:tunify/ui/widgets/common/empty_list_message.dart';
import 'package:tunify/ui/widgets/library/song_list_tile.dart';
import 'package:tunify/ui/widgets/player/now_playing_indicator.dart';
import 'package:tunify/ui/widgets/player/multi_download_button.dart';
import 'package:tunify/ui/screens/shared/home/home_shared.dart';
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
import 'package:tunify/features/downloads/download_provider.dart';
import 'package:tunify/features/device/device_music_provider.dart';
import 'package:tunify/ui/theme/app_colors.dart';
import 'package:tunify/ui/theme/design_tokens.dart';
import 'package:tunify/ui/theme/app_routes.dart';
import 'package:tunify/core/utils/string_utils.dart';
import '../player/song_options_sheet.dart';
import 'library_downloaded_content.dart';
import 'package:tunify/ui/widgets/player/mini_player.dart';
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

List<Song> _sortBySortOrder(List<Song> songs, PlaylistTrackSortOrder order) {
  switch (order) {
    case PlaylistTrackSortOrder.title:
      return List<Song>.from(songs)
        ..sort(
            (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
    case PlaylistTrackSortOrder.recentlyAdded:
      return songs.reversed.toList();
    case PlaylistTrackSortOrder.customOrder:
      return List<Song>.from(songs);
  }
}

Widget _thumbPlaceholder({double size = 48}) => Container(
      width: size,
      height: size,
      color: AppColors.surfaceLight,
      child: Center(
          child: AppIcon(
              icon: AppIcons.musicNote, color: AppColors.textMuted, size: 24)),
    );

enum _PersistKind { playlist, album, artist }

// ─── Screen ───────────────────────────────────────────────────────────────────

class LibraryPlaylistScreen extends ConsumerStatefulWidget {
  const LibraryPlaylistScreen({super.key, required this.playlistId})
      : remotePlaylist = null,
        albumSongTitle = null,
        albumArtistName = null,
        albumThumbnailUrl = null,
        albumBrowseId = null,
        albumName = null,
        albumSongId = null,
        collectionType = CollectionType.playlist;

  const LibraryPlaylistScreen.remote({super.key, required Playlist playlist})
      : playlistId = '',
        remotePlaylist = playlist,
        albumSongTitle = null,
        albumArtistName = null,
        albumThumbnailUrl = null,
        albumBrowseId = null,
        albumName = null,
        albumSongId = null,
        collectionType = CollectionType.playlist;

  const LibraryPlaylistScreen.album({
    super.key,
    required String songTitle,
    required String artistName,
    required String thumbnailUrl,
    String? browseId,
    String? name,
    String? songId,
  })  : playlistId = '',
        remotePlaylist = null,
        albumSongTitle = songTitle,
        albumArtistName = artistName,
        albumThumbnailUrl = thumbnailUrl,
        albumBrowseId = browseId,
        albumName = name,
        albumSongId = songId,
        collectionType = CollectionType.album;

  const LibraryPlaylistScreen.artist({
    super.key,
    required String artistName,
    required String thumbnailUrl,
    String? browseId,
  })  : playlistId = '',
        remotePlaylist = null,
        albumSongTitle = null,
        albumArtistName = null,
        albumThumbnailUrl = thumbnailUrl,
        albumBrowseId = browseId,
        albumName = artistName,
        albumSongId = null,
        collectionType = CollectionType.artist;

  const LibraryPlaylistScreen.liked({super.key})
      : playlistId = 'liked',
        remotePlaylist = null,
        albumSongTitle = null,
        albumArtistName = null,
        albumThumbnailUrl = null,
        albumBrowseId = null,
        albumName = null,
        albumSongId = null,
        collectionType = CollectionType.playlist;

  const LibraryPlaylistScreen.downloads({super.key})
      : playlistId = 'downloads',
        remotePlaylist = null,
        albumSongTitle = null,
        albumArtistName = null,
        albumThumbnailUrl = null,
        albumBrowseId = null,
        albumName = null,
        albumSongId = null,
        collectionType = CollectionType.playlist;

  const LibraryPlaylistScreen.localFiles({super.key})
      : playlistId = 'localFiles',
        remotePlaylist = null,
        albumSongTitle = null,
        albumArtistName = null,
        albumThumbnailUrl = null,
        albumBrowseId = null,
        albumName = null,
        albumSongId = null,
        collectionType = CollectionType.playlist;

  final String playlistId;
  final Playlist? remotePlaylist;
  final CollectionType collectionType;
  final String? albumSongTitle, albumArtistName, albumThumbnailUrl;
  final String? albumBrowseId, albumName, albumSongId;

  bool get _isAlbum => collectionType == CollectionType.album;
  bool get _isArtist => collectionType == CollectionType.artist;
  bool get _isRemotePlaylist => remotePlaylist != null;

  @override
  ConsumerState<LibraryPlaylistScreen> createState() =>
      _LibraryPlaylistScreenState();
}

class _LibraryPlaylistScreenState extends ConsumerState<LibraryPlaylistScreen> {
  LibraryPlaylist? _remoteAsLocal;
  String? _remoteError;
  bool _addingToLibrary = false;
  String? _resolvedBrowseId;
  String? _albumSubtitle;
  Color? _paletteColor;
  String? _lastPaletteUrl;
  LibraryPlaylist? _localPlaylistCache;
  bool _importedFetchTriggered = false;

  bool get _isRemote =>
      widget._isRemotePlaylist ||
      widget._isAlbum ||
      widget._isArtist ||
      _isImportedLocal;

  bool get _isImportedLocal =>
      !widget._isRemotePlaylist &&
      !widget._isAlbum &&
      !widget._isArtist &&
      widget.playlistId != 'liked' &&
      widget.playlistId != 'downloads' &&
      widget.playlistId != 'localFiles' &&
      _localPlaylistCache?.isImported == true;

  @override
  void initState() {
    super.initState();
    // Synchronously pre-populate data from cache/DB so the first build
    // never shows a loading screen for already-available data.
    _initSync();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startAfterTransition();
    });
  }

  /// Runs synchronously in initState (before first build).
  /// Reads cache + DB to pre-populate _remoteAsLocal and _paletteColor
  /// so the first frame renders the full UI with no loading flash.
  void _initSync() {
    // Liked songs — always local, never needs loading
    if (widget.playlistId == 'liked') {
      return;
    }

    // Downloads — always local, never needs loading
    if (widget.playlistId == 'downloads') {
      return;
    }

    // Local Files — always local, never needs loading
    if (widget.playlistId == 'localFiles') {
      return;
    }

    // Remote playlist — no cache, show LoadingScaffold until Hive/network ready.
    if (widget._isRemotePlaylist) {
      return;
    }

    // Album — pre-load DB palette if available; LoadingScaffold until Hive/network ready.
    if (widget._isAlbum) {
      final browseId = widget.albumBrowseId;
      if (browseId != null) {
        final album = _readLibraryState()
            ?.followedAlbums
            .where((a) => a.id == browseId || a.browseId == browseId)
            .firstOrNull;
        if (album?.cachedPaletteColor != null) {
          _paletteColor = Color(album!.cachedPaletteColor!);
        }
      }
      return;
    }

    // Artist — pre-load DB palette if available; LoadingScaffold until Hive/network ready.
    if (widget._isArtist) {
      final browseId = widget.albumBrowseId;
      if (browseId != null) {
        final artist = _readLibraryState()
            ?.followedArtists
            .where((a) => a.id == browseId || a.browseId == browseId)
            .firstOrNull;
        if (artist?.cachedPaletteColor != null) {
          _paletteColor = Color(artist!.cachedPaletteColor!);
        }
      }
      return;
    }

    // Local playlist (user-created or imported) — never show loading screen.
    // ref is not available in initState so we defer data loading to postFrameCallback,
  }

  /// Safe read of library state — only callable after ref is available (post-initState).
  LibraryState? _readLibraryState() {
    try {
      return ref.read(libraryProvider);
    } catch (_) {
      return null;
    }
  }

  Future<void> _startAfterTransition() async {
    if (!mounted) return;
    // Liked songs — purely local, no fetching needed
    if (widget.playlistId == 'liked') return;
    // Downloads — purely local, no fetching needed
    if (widget.playlistId == 'downloads') return;

    // For imported local playlists: read from provider now that ref is available,
    // pre-populate palette and kick off the track fetch.
    if (!widget._isRemotePlaylist && !widget._isAlbum && !widget._isArtist) {
      final local = ref.read(libraryPlaylistByIdProvider(widget.playlistId));
      if (local != null) {
        _localPlaylistCache = local;
        if (local.isImported) {
          // Pre-populate palette from DB immediately
          if (_paletteColor == null && local.cachedPaletteColor != null) {
            setState(() => _paletteColor = Color(local.cachedPaletteColor!));
          }
          // Check cache — if hit, populate _remoteAsLocal right now (no loading)
          final browseId = local.browseId ?? local.id;
          final cached = await CollectionTrackCache.instance.getSongs(browseId);
          if (cached != null && _remoteAsLocal == null) {
            final cachedPalette =
                await CollectionTrackCache.instance.getPaletteColor(browseId);
            if (cachedPalette != null) {
              setState(() => _paletteColor = cachedPalette);
            }
            setState(() {
              _remoteAsLocal = _makePlaylist(
                id: local.id,
                name: local.name,
                description: local.description,
                songs: cached,
                imageUrl: CollectionTrackCache.instance
                        .getEntry(browseId)
                        ?.imageUrl ??
                    local.customImageUrl,
                browseId: browseId,
                createdAt: local.createdAt,
              );
            });
            _importedFetchTriggered = true;
            // Silent background refresh after transition — don't show loading
            _scheduleAfterTransition(
                () => _fetchImportedPlaylistTracks(silent: true));
            return;
          }
          // No cache — need to fetch (will show loading)
          if (!_importedFetchTriggered) {
            _importedFetchTriggered = true;
            _scheduleAfterTransition(_fetchImportedPlaylistTracks);
          }
          return;
        }
        // User-created playlist — just extract palette after transition
        if (_paletteColor == null) {
          _scheduleAfterTransition(() => _extractPalette(
              local.customImageUrl ?? local.songs.firstOrNull?.thumbnailUrl));
        }
      }
      return;
    }

    // Remote / album / artist:
    // Check Hive immediately (no transition delay) — it's ~10ms.
    // Cache hit: populates before the slide animation finishes, no LoadingScaffold seen.
    // Cache miss: LoadingScaffold stays until network fetch + palette are both done.
    _startFetches(silent: false);
  }

  void _scheduleAfterTransition(VoidCallback fn) {
    if (!mounted) return;
    final route = ModalRoute.of(context);
    if (route == null ||
        route.animation == null ||
        route.animation!.status == AnimationStatus.completed) {
      fn();
      return;
    }
    void listener(AnimationStatus status) {
      if (status == AnimationStatus.completed) {
        route.animation!.removeStatusListener(listener);
        if (mounted) fn();
      }
    }

    route.animation!.addStatusListener(listener);
  }

  void _startFetches({bool silent = false}) {
    if (widget._isRemotePlaylist) _fetchRemoteTracks(silent: silent);
    if (widget._isAlbum) _fetchAlbumTracks(silent: silent);
    if (widget._isArtist) _fetchArtistTracks(silent: silent);
  }

  void _setLoading() => setState(() {
        _remoteError = null;
      });
  void _setError(Object e) {
    if (mounted) {
      setState(() {
        _remoteError = e.toString();
      });
    }
  }

  LibraryPlaylist _makePlaylist({
    required String id,
    required String name,
    String description = '',
    required List<Song> songs,
    String? imageUrl,
    String? browseId,
    DateTime? createdAt,
  }) =>
      LibraryPlaylist(
        id: id,
        name: name,
        description: description,
        createdAt: createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
        songs: songs,
        customImageUrl: imageUrl,
        isImported: true,
        browseId: browseId,
      );

  Future<void> _fetchRemoteTracks({bool silent = false}) async {
    final pl = widget.remotePlaylist!;
    final entry = await CollectionTrackCache.instance.getEntryFromCache(pl.id);
    if (entry != null && mounted) {
      if (!silent || _remoteAsLocal == null) {
        if (_remoteAsLocal == null) {
          final imageUrl = pl.coverUrl.isEmpty ? entry.imageUrl : pl.coverUrl;
          setState(() {
            if (entry.paletteColor != null) _paletteColor = entry.paletteColor;
            _remoteAsLocal = _makePlaylist(
              id: pl.id,
              name: pl.title,
              description: pl.curatorName ?? pl.description,
              songs: entry.songs,
              imageUrl: imageUrl,
            );
          });
        }
      }
      if (_paletteColor == null) {
        _extractPalette(pl.coverUrl.isEmpty
            ? entry.songs.firstOrNull?.thumbnailUrl
            : pl.coverUrl);
      }
      return;
    }
    if (!silent) _setLoading();
    try {
      final result =
          await ref.read(streamManagerProvider).getCollectionTracks(pl.id);
      if (!mounted) return;
      final songs = result.tracks.map(Song.fromTrack).toList();
      final imageUrl = pl.coverUrl.isEmpty ? null : pl.coverUrl;
      CollectionTrackCache.instance.put(pl.id, songs, imageUrl: imageUrl);
      // Extract palette before revealing content so gradient is ready on first frame.
      final color = await _extractPaletteColor(
          imageUrl ?? songs.firstOrNull?.thumbnailUrl);
      if (!mounted) return;
      setState(() {
        if (color != null) _paletteColor = color;
        _remoteAsLocal = _makePlaylist(
          id: pl.id,
          name: pl.title,
          description: pl.curatorName ?? pl.description,
          songs: songs,
          imageUrl: imageUrl,
        );
      });
      if (color != null) {
        CollectionTrackCache.instance.updatePalette(pl.id, color);
      }
    } catch (e) {
      if (!silent) _setError(e);
    }
  }

  Future<void> _fetchAlbumTracks({bool silent = false}) async {
    try {
      final sm = ref.read(streamManagerProvider);
      _resolvedBrowseId = widget.albumBrowseId;
      if (_resolvedBrowseId == null && widget.albumSongId != null) {
        if (!silent) _setLoading();
        final full = await sm
            .getSongFromPlayer(widget.albumSongId!)
            .timeout(const Duration(seconds: 10), onTimeout: () => null);
        _resolvedBrowseId = full?.albumBrowseId;
      }
      if (_resolvedBrowseId == null) {
        if (!silent) _setLoading();
        final r = await sm.searchResolveBrowseIds(
            '${widget.albumSongTitle} ${widget.albumArtistName}'.trim());
        _resolvedBrowseId = r.albumBrowseId;
      }
      if (_resolvedBrowseId == null) throw Exception('Could not find album');

      // BrowseId resolved — check Hive before deciding to show loading.
      final entry = await CollectionTrackCache.instance.getEntryFromCache(_resolvedBrowseId!);
      if (entry != null && mounted) {
        if (!silent || _remoteAsLocal == null) {
          setState(() {
            if (entry.paletteColor != null) _paletteColor = entry.paletteColor;
            _albumSubtitle = widget.albumArtistName;
            _remoteAsLocal = _makePlaylist(
              id: _resolvedBrowseId!,
              name: widget.albumName ?? widget.albumSongTitle ?? '',
              description: widget.albumArtistName ?? '',
              songs: entry.songs,
              imageUrl: entry.imageUrl ?? widget.albumThumbnailUrl,
            );
          });
        }
        if (_paletteColor == null) {
          final isInLib = ref.read(libraryProvider).followedAlbums.any((a) =>
              a.id == _resolvedBrowseId || a.browseId == _resolvedBrowseId);
          _extractPalette(entry.imageUrl ?? widget.albumThumbnailUrl,
              persistId: isInLib ? _resolvedBrowseId : null,
              persistKind: isInLib ? _PersistKind.album : null);
        }
        return;
      }
      if (!silent) _setLoading();

      final result = await sm.getCollectionTracks(_resolvedBrowseId!);
      if (!mounted) return;
      final meta = result.metadata.hasData ? result.metadata : null;
      final songs = result.tracks.map(Song.fromTrack).toList();
      final imageUrl = meta?.thumbnailUrl?.isNotEmpty == true
          ? meta!.thumbnailUrl
          : widget.albumThumbnailUrl;
      CollectionTrackCache.instance
          .put(_resolvedBrowseId!, songs, imageUrl: imageUrl);
      // Extract palette before revealing content so gradient is ready on first frame.
      final isInLib = ref.read(libraryProvider).followedAlbums.any(
          (a) => a.id == _resolvedBrowseId || a.browseId == _resolvedBrowseId);
      final color = _paletteColor ?? await _extractPaletteColor(imageUrl);
      if (!mounted) return;
      setState(() {
        if (color != null) _paletteColor = color;
        _albumSubtitle = meta?.subtitle ?? widget.albumArtistName;
        _remoteAsLocal = _makePlaylist(
          id: _resolvedBrowseId!,
          name: meta?.title ?? widget.albumName ?? widget.albumSongTitle ?? '',
          description: meta?.subtitle ?? widget.albumArtistName ?? '',
          songs: songs,
          imageUrl: imageUrl,
        );
      });
      if (color != null) {
        _persistPalette(color, _resolvedBrowseId!, _PersistKind.album);
      }
      if (isInLib && _resolvedBrowseId != null) {
        ref.read(libraryProvider.notifier).refreshAlbumMeta(
              _resolvedBrowseId!,
              title: meta?.title,
              artistName: meta?.subtitle ?? widget.albumArtistName,
              thumbnailUrl: imageUrl,
            );
      }
    } catch (e, s) {
      logError('Album load failed: $e\n$s', tag: 'AlbumScreen');
      if (!silent) _setError(e);
    }
  }

  Future<void> _fetchArtistTracks({bool silent = false}) async {
    if (!silent) _setLoading();
    try {
      final sm = ref.read(streamManagerProvider);
      _resolvedBrowseId = widget.albumBrowseId;
      if (_resolvedBrowseId == null) {
        final r = await sm.searchResolveBrowseIds(widget.albumName ?? '',
            preferredArtistName: widget.albumName);
        _resolvedBrowseId = r.artistBrowseId;
      }
      if (_resolvedBrowseId == null) throw Exception('Could not find artist');

      final entry =
          await CollectionTrackCache.instance.getEntryFromCache(_resolvedBrowseId!);
      if (entry != null && mounted) {
        // Cache hit — update if first load or non-silent refresh
        if (!silent || _remoteAsLocal == null) {
          if (_remoteAsLocal == null) {
            setState(() {
              if (entry.paletteColor != null) _paletteColor = entry.paletteColor;
              _remoteAsLocal = _makePlaylist(
                id: _resolvedBrowseId!,
                name: widget.albumName ?? '',
                songs: entry.songs,
                imageUrl: entry.imageUrl ?? widget.albumThumbnailUrl,
              );
            });
          }
          if (_paletteColor == null) {
            final isInLib = ref.read(libraryProvider).followedArtists.any((a) =>
                a.id == _resolvedBrowseId || a.browseId == _resolvedBrowseId);
            _extractPalette(
                entry.imageUrl ?? widget.albumThumbnailUrl,
                persistId: isInLib ? _resolvedBrowseId : null,
                persistKind: isInLib ? _PersistKind.artist : null);
          }
        }
        return;
      }

      final result = await sm.getCollectionTracks(_resolvedBrowseId!);
      if (!mounted) return;
      final meta = result.metadata.hasData ? result.metadata : null;
      final songs = result.tracks.map(Song.fromTrack).toList();
      final imageUrl = meta?.thumbnailUrl?.isNotEmpty == true
          ? meta!.thumbnailUrl
          : widget.albumThumbnailUrl;
      CollectionTrackCache.instance
          .put(_resolvedBrowseId!, songs, imageUrl: imageUrl);
      // Extract palette before revealing content so gradient is ready on first frame.
      final isInLib = ref.read(libraryProvider).followedArtists.any(
          (a) => a.id == _resolvedBrowseId || a.browseId == _resolvedBrowseId);
      final color = _paletteColor ?? await _extractPaletteColor(imageUrl);
      if (!mounted) return;
      setState(() {
        if (color != null) _paletteColor = color;
        _remoteAsLocal = _makePlaylist(
          id: _resolvedBrowseId!,
          name: meta?.title ?? widget.albumName ?? '',
          songs: songs,
          imageUrl: imageUrl,
        );
      });
      if (color != null) {
        _persistPalette(color, _resolvedBrowseId!, _PersistKind.artist);
      }
      if (isInLib && _resolvedBrowseId != null) {
        ref.read(libraryProvider.notifier).refreshArtistMeta(
              _resolvedBrowseId!,
              name: meta?.title,
              thumbnailUrl: imageUrl,
            );
      }
    } catch (e, s) {
      logError('Artist load failed: $e\n$s', tag: 'ArtistScreen');
      if (!silent) _setError(e);
    }
  }

  Future<void> _fetchImportedPlaylistTracks({bool silent = false}) async {
    final local = _localPlaylistCache;
    if (local == null) {
      logWarning('_fetchImportedPlaylistTracks: _localPlaylistCache is null',
          tag: 'PlaylistScreen');
      return;
    }
    final browseId = local.browseId ?? local.id;

    // Cache hit — populate without loading screen
    final cached = await CollectionTrackCache.instance.getSongs(browseId);
    if (cached != null) {
      if (!mounted) return;
      final cachedPalette =
          await CollectionTrackCache.instance.getPaletteColor(browseId);
      if (cachedPalette != null && _paletteColor == null) {
        setState(() => _paletteColor = cachedPalette);
      }
      if (_remoteAsLocal == null) {
        setState(() {
          _remoteAsLocal = _makePlaylist(
            id: local.id,
            name: local.name,
            description: local.description,
            songs: cached,
            imageUrl:
                CollectionTrackCache.instance.getEntry(browseId)?.imageUrl ??
                    local.customImageUrl,
            browseId: browseId,
            createdAt: local.createdAt,
          );
        });
      }
      if (cachedPalette == null) {
        _extractPalette(
            local.customImageUrl ?? cached.firstOrNull?.thumbnailUrl,
            persistId: local.id,
            persistKind: _PersistKind.playlist);
      }
      return;
    }

    // No cache — fresh fetch
    logInfo(
        'Fetching imported playlist tracks: id=${local.id} browseId=$browseId',
        tag: 'PlaylistScreen');
    if (!silent) _setLoading();
    try {
      final result =
          await ref.read(streamManagerProvider).getCollectionTracks(browseId);
      if (!mounted) return;
      final meta = result.metadata.hasData ? result.metadata : null;
      final songs = result.tracks.map(Song.fromTrack).toList();
      logInfo('Fetched ${songs.length} songs for imported playlist ${local.id}',
          tag: 'PlaylistScreen');
      final imageUrl = meta?.thumbnailUrl?.isNotEmpty == true
          ? meta!.thumbnailUrl
          : local.customImageUrl;
      CollectionTrackCache.instance.put(browseId, songs, imageUrl: imageUrl);
      // Extract palette before revealing content so gradient is ready on first frame.
      final color = _paletteColor ??
          await _extractPaletteColor(
              imageUrl ?? songs.firstOrNull?.thumbnailUrl);
      if (!mounted) return;
      setState(() {
        if (color != null) _paletteColor = color;
        _remoteAsLocal = _makePlaylist(
          id: local.id,
          name: meta?.title ?? local.name,
          description: meta?.subtitle ?? local.description,
          songs: songs,
          imageUrl: imageUrl,
          browseId: browseId,
          createdAt: local.createdAt,
        );
      });
      if (color != null) {
        _persistPalette(color, local.id, _PersistKind.playlist);
      }
      ref.read(libraryProvider.notifier).refreshPlaylistMeta(
            local.id,
            name: meta?.title,
            description: meta?.subtitle,
            imageUrl: meta?.thumbnailUrl?.isNotEmpty == true
                ? meta!.thumbnailUrl
                : null,
          );
    } catch (e, s) {
      logError('_fetchImportedPlaylistTracks failed: $e\n$s',
          tag: 'PlaylistScreen');
      if (!silent) _setError(e);
    }
  }

  Future<void> _extractPalette(String? imageUrl,
      {String? persistId, _PersistKind? persistKind}) async {
    final color = await _extractPaletteColor(imageUrl);
    if (color == null || !mounted) return;
    setState(() => _paletteColor = color);
    if (persistId != null && persistKind != null) {
      _persistPalette(color, persistId, persistKind);
    }
  }

  /// Extracts palette color and returns it without calling setState.
  /// Use this when you need the color before revealing content.
  Future<Color?> _extractPaletteColor(String? imageUrl) async {
    if (imageUrl == null || imageUrl.isEmpty || imageUrl == _lastPaletteUrl) {
      return null;
    }
    _lastPaletteUrl = imageUrl;
    try {
      final gen = await PaletteGenerator.fromImageProvider(
          CachedNetworkImageProvider(imageUrl),
          size: const Size(200, 200));
      final raw = gen.lightVibrantColor?.color ??
          gen.vibrantColor?.color ??
          gen.dominantColor?.color ??
          AppColors.primary;
      return PaletteTheme.toPaletteColor(raw);
    } catch (_) {
      return null;
    }
  }

  void _persistPalette(Color color, String id, _PersistKind kind) {
    CollectionTrackCache.instance.updatePalette(id, color);
    final value = color.toARGB32();
    switch (kind) {
      case _PersistKind.playlist:
        ref.read(libraryProvider.notifier).savePlaylistPaletteColor(id, value);
      case _PersistKind.album:
        ref.read(libraryProvider.notifier).saveAlbumPaletteColor(id, value);
      case _PersistKind.artist:
        ref.read(libraryProvider.notifier).saveArtistPaletteColor(id, value);
    }
  }

  Future<void> _addToLibrary() async {
    final playlist = _remoteAsLocal;
    if (playlist == null) return;
    setState(() => _addingToLibrary = true);
    if (widget._isAlbum) {
      await ref.read(libraryProvider.notifier).toggleFollowAlbum(LibraryAlbum(
            id: _resolvedBrowseId ??
                widget.albumBrowseId ??
                widget.albumName ??
                '',
            title: playlist.name,
            artistName: _albumSubtitle ?? widget.albumArtistName ?? '',
            thumbnailUrl:
                playlist.customImageUrl ?? widget.albumThumbnailUrl ?? '',
            browseId: _resolvedBrowseId ?? widget.albumBrowseId,
            followedAt: DateTime.now(),
          ));
    } else if (widget._isArtist) {
      await ref.read(libraryProvider.notifier).toggleFollowArtist(LibraryArtist(
            id: _resolvedBrowseId ??
                widget.albumBrowseId ??
                widget.albumName ??
                '',
            name: playlist.name,
            thumbnailUrl:
                playlist.customImageUrl ?? widget.albumThumbnailUrl ?? '',
            browseId: _resolvedBrowseId ?? widget.albumBrowseId,
            followedAt: DateTime.now(),
          ));
    } else {
      await ref.read(libraryProvider.notifier).addPlaylistToLibrary(
          playlist.copyWith(browseId: playlist.browseId ?? playlist.id));
    }
    if (mounted) setState(() => _addingToLibrary = false);
  }

  // ── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    // Keep local playlist cache fresh (watches provider for changes).
    // Do this BEFORE _isRemote / _isImportedLocal checks so they see the latest value.
    if (!widget._isRemotePlaylist && !widget._isAlbum && !widget._isArtist) {
      final local = ref.watch(libraryPlaylistByIdProvider(widget.playlistId));
      _localPlaylistCache = local;
    }

    // Downloads — build a synthetic playlist from the download service.
    if (widget.playlistId == 'downloads') {
      final songs = ref.watch(downloadServiceProvider).downloadedSongs;
      final showExplicit = ref.watch(showExplicitContentProvider);
      final sortOrder =
          ref.watch(libraryProvider.select((s) => s.downloadsSortOrder));
      final sortedSongs = _sortBySortOrder(songs, sortOrder);
      final filteredSongs = filterByExplicitSetting(sortedSongs, showExplicit);
      final hasSong = ref.watch(currentSongProvider) != null;
      const downloadsColor = Color(0xFF0EA5E9);
      return CollectionDetailScaffold(
        isEmpty: songs.isEmpty,
        paletteColor: downloadsColor,
        title: 'Downloads',
        headerExpandedChild: CollectionDetailExpandedContent(
          cover: _PlaylistCover(songs: songs, isDownloads: true),
          title: 'Downloads',
          subtitle: _buildCountDuration(songs),
        ),
        actionRow: _ActionRow(
          playlistId: 'downloads',
          songs: songs,
          filteredSongs: filteredSongs,
          isDownloads: true,
        ),
        playButton: _CollectionPlayButton(
          playlistId: 'downloads',
          songs: songs,
          filteredSongs: filteredSongs,
          queueSource: 'downloads',
          isDownloads: true,
        ),
        pills: songs.isEmpty
            ? null
            : _DownloadsPillRow(
                songs: songs,
                sortOrder: sortOrder,
              ),
        searchField: _SearchInPlaylistTap(
            songs: songs, playlistId: 'downloads', isDownloads: true),
        bodySlivers: [
          if (filteredSongs.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.xxl),
                  child: Text(
                    'Tap Download on a song to add it here.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.textMuted.withValues(alpha: 0.7),
                      fontSize: AppFontSize.base,
                    ),
                  ),
                ),
              ),
            )
          else
            SliverList(
                delegate: SliverChildBuilderDelegate(
              (context, i) {
                final song = filteredSongs[i];
                return _TrackTile(
                  song: song,
                  songs: sortedSongs,
                  playlistId: 'downloads',
                  queueSource: 'downloads',
                  isImported: false,
                  isDownloads: true,
                );
              },
              childCount: filteredSongs.length,
            )),
          const SliverToBoxAdapter(child: SizedBox(height: 160)),
        ],
        hasSong: hasSong,
        miniPlayerKey: const ValueKey('downloads-mini-player'),
      );
    }

    // Local Files — build a synthetic playlist from the device music provider.
    if (widget.playlistId == 'localFiles') {
      // Trigger load on first build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(deviceMusicProvider.notifier).loadSongs();
      });
      final deviceState = ref.watch(deviceMusicProvider);
      final songs = deviceState.songs;
      final showExplicit = ref.watch(showExplicitContentProvider);
      final sortOrder =
          ref.watch(libraryProvider.select((s) => s.downloadsSortOrder));
      final sortedSongs = _sortBySortOrder(songs, sortOrder);
      final filteredSongs = filterByExplicitSetting(sortedSongs, showExplicit);
      final hasSong = ref.watch(currentSongProvider) != null;
      const localFilesColor = Color(0xFFFF9F43);
      return CollectionDetailScaffold(
        isEmpty: songs.isEmpty,
        paletteColor: localFilesColor,
        title: 'Local Files',
        headerExpandedChild: CollectionDetailExpandedContent(
          cover: _PlaylistCover(songs: songs, isLocalFiles: true),
          title: 'Local Files',
          subtitle: _buildCountDuration(songs),
        ),
        actionRow: _ActionRow(
          playlistId: 'localFiles',
          songs: songs,
          filteredSongs: filteredSongs,
          isLocalFiles: true,
        ),
        playButton: _CollectionPlayButton(
          playlistId: 'localFiles',
          songs: songs,
          filteredSongs: filteredSongs,
          queueSource: 'localFiles',
          isLocalFiles: true,
        ),
        pills: songs.isEmpty
            ? null
            : _DownloadsPillRow(
                songs: songs,
                sortOrder: sortOrder,
              ),
        searchField: _SearchInPlaylistTap(
            songs: songs, playlistId: 'localFiles', isLocalFiles: true),
        bodySlivers: [
          if (!deviceState.hasPermission && songs.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.xxl),
                  child: Platform.isMacOS
                      ? _MacOSFolderPrompt(
                          isLoading: deviceState.isLoading,
                          error: deviceState.error,
                          onPick: () => ref
                              .read(deviceMusicProvider.notifier)
                              .pickMacOSFolder(),
                        )
                      : Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Permission required to access local files',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color:
                                    AppColors.textMuted.withValues(alpha: 0.7),
                                fontSize: AppFontSize.base,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            AppButton(
                              label: 'Grant Permission',
                              onPressed: () => ref
                                  .read(deviceMusicProvider.notifier)
                                  .loadSongs(),
                            ),
                          ],
                        ),
                ),
              ),
            )
          else if (songs.isNotEmpty && Platform.isMacOS)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: kSheetHorizontalPadding, vertical: 8),
                child: Row(
                  children: [
                    Icon(Icons.folder_outlined,
                        size: 14, color: AppColors.textSecondary),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        deviceState.macOSMusicFolder ?? '',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: AppFontSize.xs,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => ref
                          .read(deviceMusicProvider.notifier)
                          .pickMacOSFolder(),
                      child: Text(
                        'Change',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: AppFontSize.xs,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else if (filteredSongs.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.xxl),
                  child: Text(
                    deviceState.isLoading
                        ? 'Loading...'
                        : 'No local files found',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.textMuted.withValues(alpha: 0.7),
                      fontSize: AppFontSize.base,
                    ),
                  ),
                ),
              ),
            )
          else
            SliverList(
                delegate: SliverChildBuilderDelegate(
              (context, i) {
                final song = filteredSongs[i];
                return _TrackTile(
                  song: song,
                  songs: sortedSongs,
                  playlistId: 'localFiles',
                  queueSource: 'localFiles',
                  isImported: false,
                  isLocalFiles: true,
                );
              },
              childCount: filteredSongs.length,
            )),
          const SliverToBoxAdapter(child: SizedBox(height: 160)),
        ],
        hasSong: hasSong,
        miniPlayerKey: const ValueKey('localFiles-mini-player'),
      );
    }

    if (_isRemote) {
      if (_remoteError != null && _remoteAsLocal == null) {
        return ErrorScaffold(
          message: widget._isArtist
              ? 'Failed to load artist'
              : widget._isAlbum
                  ? 'Failed to load album'
                  : 'Failed to load playlist',
          onRetry: widget._isArtist
              ? _fetchArtistTracks
              : widget._isAlbum
                  ? _fetchAlbumTracks
                  : _isImportedLocal
                      ? _fetchImportedPlaylistTracks
                      : _fetchRemoteTracks,
        );
      }
      if (_remoteAsLocal == null) return const LoadingScaffold();
    }

    final playlist = _isRemote
        ? _remoteAsLocal
        : widget.playlistId == 'liked'
            ? ref.watch(libraryProvider.select((s) => s.likedPlaylist))
            : ref.watch(libraryPlaylistByIdProvider(widget.playlistId));

    if (playlist == null) {
      // Local playlist not found in DB — show loading briefly while provider initialises
      return const LoadingScaffold();
    }

    final isInLibrary = _isRemote
        ? (_isImportedLocal
            ? true
            : widget._isAlbum
                ? ref.watch(libraryProvider.select(
                    (s) => s.followedAlbums.any((a) => a.id == playlist.id)))
                : widget._isArtist
                    ? ref.watch(libraryProvider.select((s) =>
                        s.followedArtists.any((a) => a.id == playlist.id)))
                    : ref.watch(libraryProvider.select(
                        (s) => s.playlists.any((p) => p.id == playlist.id))))
        : true;

    final isImported = _isRemote || playlist.isImported;
    final songs = playlist.sortedSongs;
    final hasSong = ref.watch(currentSongProvider) != null;
    final filteredSongs =
        filterByExplicitSetting(songs, ref.watch(showExplicitContentProvider));

    final coverUrl = _isRemote
        ? (_isImportedLocal
            ? _remoteAsLocal?.customImageUrl
            : isInLibrary
                ? playlist.customImageUrl
                : widget.remotePlaylist?.coverUrl ?? widget.albumThumbnailUrl)
        : playlist.customImageUrl;

    final isLiked = playlist.id == 'liked';

    return CollectionDetailScaffold(
      isEmpty: songs.isEmpty,
      paletteColor: isLiked
          ? const Color(0xFFE91E8C)
          : (songs.isEmpty ? const Color(0xFF404040) : _paletteColor),
      title: isLiked ? 'Liked Songs' : playlist.name.capitalized,
      headerExpandedChild: CollectionDetailExpandedContent(
        cover: isLiked
            ? _PlaylistCover(songs: songs, isLiked: true)
            : _PlaylistCover(
                songs: songs, imageUrl: coverUrl, isCircle: widget._isArtist),
        title: isLiked ? 'Liked Songs' : playlist.name.capitalized,
        subtitle: _buildSubtitle(playlist),
      ),
      actionRow: _ActionRow(
        playlistId: playlist.id,
        songs: songs,
        filteredSongs: filteredSongs,
        disableShuffle: _isRemote && !isInLibrary,
        showLibraryStatus: !isLiked && isImported,
        isInLibrary: isInLibrary,
        onAddToLibrary: _addToLibrary,
        addingToLibrary: _addingToLibrary,
      ),
      playButton: _CollectionPlayButton(
        playlistId: playlist.id,
        songs: songs,
        filteredSongs: filteredSongs,
        disableShuffle: _isRemote && !isInLibrary,
        queueSource:
            isLiked ? 'liked' : (widget._isAlbum ? 'album' : 'playlist'),
      ),
      pills: (widget._isAlbum || widget._isArtist || isImported)
          ? null
          : _PlaylistPillRow(
              playlistId: widget.playlistId.isNotEmpty
                  ? widget.playlistId
                  : playlist.id,
              playlist: playlist,
              onPlaylistUpdated: () => setState(() {}),
              showNameDetails: !isLiked,
              isEmpty: songs.isEmpty,
            ),
      searchField: _SearchInPlaylistTap(songs: songs, playlistId: playlist.id),
      bodySlivers: [
        if (filteredSongs.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xxl),
                child: Text(
                  songs.isEmpty
                      ? (isLiked
                          ? 'Your liked songs will appear here.'
                          : isImported || widget._isAlbum || widget._isArtist
                              ? 'Nothing here yet — check back soon'
                              : 'Your playlist is empty.\nAdd songs to get started.')
                      : 'No songs match your filter',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textMuted.withValues(alpha: 0.7),
                    fontSize: AppFontSize.base,
                  ),
                ),
              ),
            ),
          )
        else
          SliverList(
              delegate: SliverChildBuilderDelegate(
            (context, i) {
              final song = filteredSongs[i];
              return _TrackTile(
                song: song,
                songs: songs,
                playlistId: playlist.id,
                queueSource: isLiked
                    ? 'liked'
                    : (widget._isAlbum ? 'album' : 'playlist'),
                isImported: isImported,
              );
            },
            childCount: filteredSongs.length,
          )),
        const SliverToBoxAdapter(child: SizedBox(height: 160)),
      ],
      hasSong: hasSong,
      miniPlayerKey: ValueKey('${playlist.id}-mini-player'),
    );
  }

  Widget _buildSubtitle(LibraryPlaylist playlist) {
    final muted = TextStyle(
        color: AppColors.textMuted.withValues(alpha: 0.9),
        fontSize: AppFontSize.base);
    final countDuration = Row(children: [
      Text(
          '${playlist.songs.length} ${playlist.songs.length == 1 ? 'song' : 'songs'}',
          style: muted),
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
          Text(artistLine,
              style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: AppFontSize.xl,
                  fontWeight: FontWeight.w500)),
        const SizedBox(height: AppSpacing.sm),
        countDuration,
      ],
    );
  }

  Widget _buildCountDuration(List<Song> songs) {
    final muted = TextStyle(
        color: AppColors.textMuted.withValues(alpha: 0.9),
        fontSize: AppFontSize.base);
    return Row(children: [
      Text('${songs.length} ${songs.length == 1 ? 'song' : 'songs'}',
          style: muted),
      if (songs.isNotEmpty) ...[
        Text(' • ', style: muted),
        Text(_formatDuration(songs), style: muted),
      ],
    ]);
  }
}

// ─── Cover ────────────────────────────────────────────────────────────────────

class _PlaylistCover extends StatelessWidget {
  const _PlaylistCover(
      {required this.songs,
      this.imageUrl,
      this.isCircle = false,
      this.isLiked = false,
      this.isDownloads = false,
      this.isLocalFiles = false});

  final List<Song> songs;
  final String? imageUrl;
  final bool isCircle;
  final bool isLiked;
  final bool isDownloads;
  final bool isLocalFiles;

  static const double _size = 200.0;

  @override
  Widget build(BuildContext context) {
    final shadow = BoxShadow(
        color: Colors.black.withValues(alpha: 0.3),
        blurRadius: 16,
        offset: const Offset(0, 6));

    // Downloads — always show gradient icon cover
    if (isDownloads) {
      return Center(
        child: Container(
          width: _size,
          height: _size,
          decoration: BoxDecoration(
            gradient: AppColors.downloadGradient,
            borderRadius: BorderRadius.circular(AppRadius.sm),
            boxShadow: [
              BoxShadow(
                  color: const Color(0xFF0EA5E9).withValues(alpha: 0.35),
                  blurRadius: 20,
                  offset: const Offset(0, 6))
            ],
          ),
          child: Center(
              child: AppIcon(
                  icon: AppIcons.download, color: Colors.white, size: 56)),
        ),
      );
    }

    // Local Files — always show gradient icon cover
    if (isLocalFiles) {
      return Center(
        child: Container(
          width: _size,
          height: _size,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFFF9F43), Color(0xFFFF6B35)],
            ),
            borderRadius: BorderRadius.circular(AppRadius.sm),
            boxShadow: [
              BoxShadow(
                  color: const Color(0xFFFF9F43).withValues(alpha: 0.35),
                  blurRadius: 20,
                  offset: const Offset(0, 6))
            ],
          ),
          child: Center(
              child: AppIcon(
                  icon: AppIcons.folder, color: Colors.white, size: 56)),
        ),
      );
    }

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
              ? ClipOval(
                  child: CachedNetworkImage(
                      imageUrl: imageUrl!,
                      width: _size,
                      height: _size,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => Container(
                          color: AppColors.surfaceLight,
                          child: AppIcon(
                              icon: AppIcons.person,
                              color: AppColors.textMuted,
                              size: 64))))
              : Padding(
                  padding: const EdgeInsets.all(4),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                    child: CachedNetworkImage(
                        imageUrl: imageUrl!,
                        width: _size - 8,
                        height: _size - 8,
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => _mosaic(songs, _size - 8)),
                  )),
        ),
      );
    }

    if (songs.isEmpty) {
      if (isLiked) {
        return Center(
          child: Container(
            width: _size,
            height: _size,
            decoration: BoxDecoration(
              gradient: AppColors.loveThemeGradientFor('liked_songs'),
              borderRadius: BorderRadius.circular(AppRadius.sm),
              boxShadow: [
                BoxShadow(
                    color: const Color(0xFFE91E8C).withValues(alpha: 0.35),
                    blurRadius: 20,
                    offset: const Offset(0, 6))
              ],
            ),
            child: const Center(
                child: FavouriteIcon(
                    isLiked: true, size: 56, fillColor: Colors.white)),
          ),
        );
      }
      return Center(
          child: Container(
              width: _size,
              height: _size,
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(AppRadius.sm),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withValues(alpha: 0.25),
                      blurRadius: 16,
                      offset: const Offset(0, 6))
                ],
              ),
              child: Center(
                  child: AppIcon(
                      icon: AppIcons.musicNote,
                      color: AppColors.textMuted,
                      size: 64))));
    }

    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: AppSpacing.base),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          color: AppColors.surfaceLight.withValues(alpha: 0.6),
          boxShadow: [shadow],
        ),
        child: Padding(
            padding: const EdgeInsets.all(4), child: _mosaic(songs, _size - 8)),
      ),
    );
  }

  static Widget _mosaic(List<Song> songs, double size) {
    if (songs.length == 1) {
      return ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          child: CachedNetworkImage(
              imageUrl: songs.first.thumbnailUrl,
              width: size,
              height: size,
              fit: BoxFit.cover,
              errorWidget: (_, __, ___) => _cell(null, size)));
    }
    final urls = songs.take(4).map((s) => s.thumbnailUrl).toList();
    const gap = 2.0;
    final cell = (size - gap) / 2;
    return SizedBox(
        width: size,
        height: size,
        child: Column(children: [
          Row(children: [
            _cell(urls.elementAtOrNull(0), cell),
            const SizedBox(width: gap),
            _cell(urls.elementAtOrNull(1), cell)
          ]),
          const SizedBox(height: gap),
          Row(children: [
            _cell(urls.elementAtOrNull(2), cell),
            const SizedBox(width: gap),
            _cell(urls.elementAtOrNull(3), cell)
          ]),
        ]));
  }

  static Widget _cell(String? url, double s) {
    return SizedBox(
        width: s,
        height: s,
        child: url != null
            ? Builder(builder: (ctx) {
                final px = (s * MediaQuery.devicePixelRatioOf(ctx)).round();
                return CachedNetworkImage(
                    imageUrl: url,
                    fit: BoxFit.cover,
                    memCacheWidth: px,
                    memCacheHeight: px,
                    errorWidget: (_, __, ___) => _placeholder(s: s));
              })
            : _placeholder(s: s));
  }

  static Widget _placeholder({required double s}) => Container(
      width: s,
      height: s,
      color: AppColors.surfaceLight,
      child: AppIcon(icon: AppIcons.musicNote, color: AppColors.textMuted));
}

// ─── Liked Songs helpers (edit / add sheets) ─────────────────────────────────

void _openAddSongsSheet(BuildContext context, String playlistId,
    {String? playlistName, VoidCallback? onAdded}) {
  FocusManager.instance.primaryFocus?.unfocus();
  showAppSheet(context,
      maxHeight: MediaQuery.of(context).size.height * 0.75,
      child: _AddSongsSheet(playlistId: playlistId, onAdded: onAdded));
}

void _openEditSongsSheet(
    BuildContext context, String playlistId, List<Song> initialSongs) {
  FocusManager.instance.primaryFocus?.unfocus();
  Navigator.of(context).push(appPageRoute<void>(
      builder: (_) =>
          _EditSongsSheet(playlistId: playlistId, initialSongs: initialSongs)));
}

// ─── Action Row (shared: playlist + liked) ────────────────────────────────────

class _ActionRow extends ConsumerWidget {
  const _ActionRow({
    required this.playlistId,
    required this.songs,
    required this.filteredSongs,
    this.disableShuffle = false,
    this.showLibraryStatus = false,
    this.isInLibrary = true,
    this.onAddToLibrary,
    this.addingToLibrary = false,
    this.isDownloads = false,
    this.isLocalFiles = false,
  });

  final String playlistId;
  final List<Song> songs, filteredSongs;
  final bool disableShuffle,
      showLibraryStatus,
      isInLibrary,
      addingToLibrary,
      isDownloads,
      isLocalFiles;
  final VoidCallback? onAddToLibrary;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shuffleEnabled = disableShuffle
        ? false
        : isDownloads || isLocalFiles
            ? ref.watch(downloadedShuffleProvider)
            : ref.watch(libraryProvider.select((s) =>
                s.playlists
                    .where((p) => p.id == playlistId)
                    .firstOrNull
                    ?.shuffleEnabled ??
                false));

    return SizedBox(
      height: kCollectionActionRowHeight,
      child: Padding(
        padding:
            const EdgeInsets.only(left: AppSpacing.sm, right: AppSpacing.base),
        child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
          AppIconButton(
            icon: AppIcon(
                icon: AppIcons.shuffle,
                size: 24,
                color:
                    shuffleEnabled ? AppColors.primary : AppColors.textPrimary),
            onPressed: filteredSongs.isNotEmpty && !disableShuffle
                ? () => isDownloads || isLocalFiles
                    ? ref
                        .read(libraryProvider.notifier)
                        .toggleDownloadedShuffle()
                    : ref
                        .read(libraryProvider.notifier)
                        .togglePlaylistShuffle(playlistId)
                : null,
            size: 40,
            iconSize: 24,
          ),
          if (!isDownloads && !isLocalFiles)
            MultiDownloadButton(songs: songs, size: 24, iconSize: 20),
          if (showLibraryStatus)
            AppIconButton(
              icon: addingToLibrary
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: AppColors.textMuted))
                  : AppIcon(
                      icon: isInLibrary
                          ? AppIcons.checkCircle
                          : AppIcons.addCircleOutline,
                      size: 24,
                      color: isInLibrary
                          ? AppColors.primary
                          : AppColors.textPrimary),
              onPressed:
                  (!isInLibrary && !addingToLibrary) ? onAddToLibrary : null,
              size: 40,
              iconSize: 24,
            ),
          const Spacer(),
          const SizedBox(width: 56),
        ]),
      ),
    );
  }
}

// ─── Play Button (shared: playlist + liked) ───────────────────────────────────

class _CollectionPlayButton extends ConsumerWidget {
  const _CollectionPlayButton({
    required this.playlistId,
    required this.songs,
    required this.filteredSongs,
    required this.queueSource,
    this.disableShuffle = false,
    this.isDownloads = false,
    this.isLocalFiles = false,
  });

  final String playlistId, queueSource;
  final List<Song> songs, filteredSongs;
  final bool disableShuffle, isDownloads, isLocalFiles;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shuffleEnabled = disableShuffle
        ? false
        : isDownloads || isLocalFiles
            ? ref.watch(downloadedShuffleProvider)
            : ref.watch(libraryProvider.select((s) =>
                s.playlists
                    .where((p) => p.id == playlistId)
                    .firstOrNull
                    ?.shuffleEnabled ??
                false));
    return PlayCircleButton(
      onTap: filteredSongs.isNotEmpty
          ? () {
              final queue = shuffleEnabled
                  ? (List<Song>.from(filteredSongs)..shuffle(Random()))
                  : songs;
              ref.read(playerProvider.notifier).playSong(queue.first,
                  queue: queue,
                  playlistId: playlistId,
                  queueSource: queueSource);
            }
          : () {},
      size: 56,
      iconSize: 28,
    );
  }
}

// ─── Downloads Pills ──────────────────────────────────────────────────────────

/// Shown on macOS when no music folder has been chosen yet (or on error).
/// Displays a friendly prompt with a button that calls [onPick].
class _MacOSFolderPrompt extends StatelessWidget {
  const _MacOSFolderPrompt({
    required this.onPick,
    this.isLoading = false,
    this.error,
  });

  final VoidCallback onPick;
  final bool isLoading;
  final String? error;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.folder_open_outlined,
          size: 48,
          color: AppColors.textMuted.withValues(alpha: 0.5),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          'Choose a music folder',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: AppFontSize.lg,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Select the folder on your Mac that contains\nyour local audio files.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.textMuted.withValues(alpha: 0.7),
            fontSize: AppFontSize.base,
          ),
        ),
        if (error != null) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            error!,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.accentRed,
              fontSize: AppFontSize.sm,
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.lg),
        isLoading
            ? const CircularProgressIndicator(color: AppColors.primary)
            : AppButton(
                label: 'Choose Folder…',
                onPressed: onPick,
              ),
      ],
    );
  }
}

class _DownloadsPillRow extends ConsumerWidget {
  const _DownloadsPillRow({required this.songs, required this.sortOrder});
  final List<Song> songs;
  final PlaylistTrackSortOrder sortOrder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.base),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(children: [
          _Pill(
            icon: AppIcons.edit,
            label: 'Edit',
            onTap: () => openEditDownloadedSheet(context, songs),
          ),
          const SizedBox(width: AppSpacing.sm),
          _Pill(
            icon: AppIcons.sort,
            label: 'Sort',
            onTap: () => _openDownloadsSortSheet(context, ref, sortOrder),
          ),
        ]),
      ),
    );
  }
}

void _openDownloadsSortSheet(
    BuildContext context, WidgetRef ref, PlaylistTrackSortOrder current) {
  FocusManager.instance.primaryFocus?.unfocus();
  showAppSheet(
    context,
    child: _DownloadsSortSheet(current: current),
  );
}

class _DownloadsSortSheet extends ConsumerWidget {
  const _DownloadsSortSheet({required this.current});
  final PlaylistTrackSortOrder current;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(mainAxisSize: MainAxisSize.min, children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.base, AppSpacing.lg, AppSpacing.base, AppSpacing.md),
        child: Text('Sort downloads',
            style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: AppFontSize.xl,
                fontWeight: FontWeight.w700)),
      ),
      _SortTile(
        label: 'Custom order',
        selected: current == PlaylistTrackSortOrder.customOrder,
        onTap: () async {
          await ref
              .read(libraryProvider.notifier)
              .setDownloadsSortOrder(PlaylistTrackSortOrder.customOrder);
          if (context.mounted) Navigator.pop(context);
        },
      ),
      _SortTile(
        label: 'Title',
        selected: current == PlaylistTrackSortOrder.title,
        onTap: () async {
          await ref
              .read(libraryProvider.notifier)
              .setDownloadsSortOrder(PlaylistTrackSortOrder.title);
          if (context.mounted) Navigator.pop(context);
        },
      ),
      _SortTile(
        label: 'Recently added',
        selected: current == PlaylistTrackSortOrder.recentlyAdded,
        onTap: () async {
          await ref
              .read(libraryProvider.notifier)
              .setDownloadsSortOrder(PlaylistTrackSortOrder.recentlyAdded);
          if (context.mounted) Navigator.pop(context);
        },
      ),
      const SizedBox(height: AppSpacing.xl),
    ]);
  }
}

// ─── Pills ────────────────────────────────────────────────────────────────────

class _PlaylistPillRow extends ConsumerWidget {
  const _PlaylistPillRow({
    required this.playlistId,
    required this.playlist,
    required this.onPlaylistUpdated,
    this.showNameDetails = true,
    this.isEmpty = false,
  });

  final String playlistId;
  final LibraryPlaylist playlist;
  final VoidCallback onPlaylistUpdated;
  final bool showNameDetails;
  final bool isEmpty;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.base),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(children: [
          _Pill(
              icon: AppIcons.add,
              label: 'Add',
              onTap: () => _openAddSongsSheet(context, playlistId,
                  playlistName: playlist.name, onAdded: onPlaylistUpdated)),
          if (!isEmpty) ...[
            const SizedBox(width: AppSpacing.sm),
            _Pill(
                icon: AppIcons.edit,
                label: 'Edit',
                onTap: () =>
                    _openEditSongsSheet(context, playlistId, playlist.songs)),
            const SizedBox(width: AppSpacing.sm),
            _Pill(
                icon: AppIcons.sort,
                label: 'Sort',
                onTap: () => _openSortSheet(context, playlistId, playlist)),
            if (showNameDetails) ...[
              const SizedBox(width: AppSpacing.sm),
              _Pill(
                  icon: AppIcons.editNote,
                  label: 'Name & details',
                  onTap: () =>
                      _openNameAndDetailsSheet(context, playlistId, playlist)),
            ],
          ],
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
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md, vertical: AppSpacing.sm),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.textMuted.withValues(alpha: 0.5)),
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          AppIcon(icon: icon, size: 18, color: AppColors.textSecondary),
          const SizedBox(width: AppSpacing.xs),
          Text(label,
              style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: AppFontSize.md,
                  fontWeight: FontWeight.w500)),
        ]),
      ),
    );
  }
}

// ─── Sheet openers ────────────────────────────────────────────────────────────

void _openSortSheet(
    BuildContext context, String playlistId, LibraryPlaylist playlist) {
  FocusManager.instance.primaryFocus?.unfocus();
  showAppSheet(context,
      child: _SortPlaylistSheet(playlistId: playlistId, playlist: playlist));
}

void _openNameAndDetailsSheet(
    BuildContext context, String playlistId, LibraryPlaylist playlist) {
  FocusManager.instance.primaryFocus?.unfocus();
  showAppSheet(context,
      maxHeight: MediaQuery.of(context).size.height * 0.6,
      child: _NameAndDetailsSheet(playlistId: playlistId, playlist: playlist));
}

// ─── Add songs sheet (shared: playlist + liked) ───────────────────────────────

class _AddSongsSheet extends ConsumerStatefulWidget {
  const _AddSongsSheet({required this.playlistId, this.onAdded});
  final String playlistId;
  final VoidCallback? onAdded;

  @override
  ConsumerState<_AddSongsSheet> createState() => _AddSongsSheetState();
}

class _AddSongsSheetState extends ConsumerState<_AddSongsSheet> {
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
    if (q.trim().isEmpty) {
      setState(() {
        _results = [];
        _searching = false;
      });
      return;
    }
    setState(() => _searching = true);
    try {
      final r = await ref.read(playerProvider.notifier).searchSongs(q.trim());
      if (mounted) {
        setState(() {
          _results = r;
          _searching = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _results = [];
          _searching = false;
        });
      }
    }
  }

  bool _isInPlaylist(Set<String> ids, String songId) => ids.contains(songId);

  @override
  Widget build(BuildContext context) {
    final isLiked = widget.playlistId == 'liked';
    final recent = ref.watch(recentlyPlayedProvider);
    final inIds = ref.watch(libraryProvider.select((s) =>
        s.playlists
            .where((x) => x.id == widget.playlistId)
            .firstOrNull
            ?.songs
            .map((e) => e.id)
            .toSet() ??
        <String>{}));
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
            prefixIcon: AppIcon(
                icon: AppIcons.search, color: AppColors.textMuted, size: 20),
            suffixIcon: _searchCtrl.text.trim().isNotEmpty
                ? AppIconButton(
                    icon: AppIcon(
                        icon: AppIcons.clear,
                        size: 24,
                        color: AppColors.textMuted),
                    onPressed: () {
                      _searchCtrl.clear();
                      setState(() => _results = []);
                    },
                    size: 40,
                    iconSize: 24)
                : null,
            onChanged: (v) {
              setState(() {});
              _debounce?.cancel();
              _debounce = Timer(const Duration(milliseconds: 350), () {
                if (mounted) _search(_searchCtrl.text);
              });
            },
            onSubmitted: _search,
          ),
        ),
      ),
      if (showRecent)
        Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: kSheetHorizontalPadding),
          child: Align(
              alignment: Alignment.centerLeft,
              child: Text('Recently played',
                  style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: AppFontSize.sm,
                      fontWeight: FontWeight.w600))),
        ),
      const SizedBox(height: AppSpacing.sm),
      Expanded(
        child: _searching
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.primary))
            : list.isEmpty
                ? Center(
                    child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.xl),
                        child: Text(
                            showRecent
                                ? 'No recently played songs'
                                : _searchCtrl.text.trim().isEmpty
                                    ? 'Type above to search for songs'
                                    : 'No results for "${_searchCtrl.text.trim()}"',
                            style: const TextStyle(color: AppColors.textMuted),
                            textAlign: TextAlign.center)))
                : ListView.builder(
                    itemCount: list.length,
                    itemBuilder: (context, i) {
                      final song = list[i];
                      final inPlaylist = _isInPlaylist(inIds, song.id);
                      final isNowPlaying =
                          ref.watch(currentSongProvider)?.id == song.id;
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: kSheetHorizontalPadding, vertical: 8),
                        leading: NowPlayingThumbnail(
                          isPlaying: isNowPlaying,
                          isActuallyPlaying: ref.watch(isPlayingProvider),
                          size: 48,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(AppRadius.xs),
                            child: CachedNetworkImage(
                                imageUrl: song.thumbnailUrl,
                                width: 48,
                                height: 48,
                                fit: BoxFit.cover,
                                errorWidget: (_, __, ___) => AppIcon(
                                    icon: AppIcons.musicNote,
                                    color: AppColors.textMuted,
                                    size: 28)),
                          ),
                        ),
                        title: Text(song.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                color: isNowPlaying
                                    ? AppColors.accent
                                    : AppColors.textPrimary)),
                        subtitle: Text(song.artist,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                color: AppColors.textMuted,
                                fontSize: AppFontSize.sm)),
                        trailing: AppIconButton(
                          icon: AppIcon(
                              icon: inPlaylist
                                  ? AppIcons.checkCircle
                                  : AppIcons.addCircleOutline,
                              color: inPlaylist
                                  ? AppColors.primary
                                  : AppColors.textSecondary,
                              size: 24),
                          onPressed: () {
                            if (isLiked) {
                              ref
                                  .read(libraryProvider.notifier)
                                  .toggleLiked(song);
                            } else if (inPlaylist) {
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
                            widget.onAdded?.call();
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
  const _SearchInPlaylistTap({
    required this.songs,
    required this.playlistId,
    this.isDownloads = false,
    this.isLocalFiles = false,
  });
  final List<Song> songs;
  final String playlistId;
  final bool isDownloads;
  final bool isLocalFiles;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.base),
      child: GestureDetector(
        onTap: () => Navigator.of(context).push(appPageRoute<void>(
            builder: (_) => _PlaylistSearchPage(
                  songs: songs,
                  playlistId: playlistId,
                  isDownloads: isDownloads,
                  isLocalFiles: isLocalFiles,
                ))),
        child: Container(
          height: 44,
          decoration: BoxDecoration(
              color: AppColors.surfaceLight.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(AppRadius.input)),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Row(children: [
            AppIcon(
                icon: AppIcons.search,
                color: AppColors.textMuted.withValues(alpha: 0.9),
                size: 20),
            const SizedBox(width: AppSpacing.sm),
            Text('Find in playlist',
                style: TextStyle(
                    color: AppColors.textMuted.withValues(alpha: 0.9),
                    fontSize: AppFontSize.base)),
          ]),
        ),
      ),
    );
  }
}

class _PlaylistSearchPage extends ConsumerStatefulWidget {
  const _PlaylistSearchPage({
    required this.songs,
    required this.playlistId,
    this.isDownloads = false,
    this.isLocalFiles = false,
  });
  final List<Song> songs;
  final String playlistId;
  final bool isDownloads;
  final bool isLocalFiles;

  @override
  ConsumerState<_PlaylistSearchPage> createState() =>
      _PlaylistSearchPageState();
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
  void dispose() {
    _ctrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final q = _ctrl.text.trim().toLowerCase();
    final hasSong = ref.watch(currentSongProvider) != null;
    final filtered = filterByExplicitSetting(
      q.isEmpty
          ? widget.songs
          : widget.songs
              .where((s) =>
                  s.title.toLowerCase().contains(q) ||
                  s.artist.toLowerCase().contains(q))
              .toList(),
      ref.watch(showExplicitContentProvider),
    );

    final body = q.isEmpty
        ? SearchPageEmptyState(
            icon: AppIcon(
                icon: AppIcons.search, size: 64, color: AppColors.textMuted),
            heading: 'Find in playlist',
            subheading: 'Search by song title or artist')
        : filtered.isEmpty
            ? EmptyListMessage(
                emptyLabel: 'matches',
                query: q,
                style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: AppFontSize.lg,
                    fontWeight: FontWeight.w600))
            : ListView.builder(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.only(bottom: AppSpacing.max),
                itemCount: filtered.length,
                itemBuilder: (_, i) => _TrackTile(
                    song: filtered[i],
                    songs: widget.songs,
                    playlistId: widget.playlistId,
                    isDownloads: widget.isDownloads,
                    isLocalFiles: widget.isLocalFiles));

    final page = SharedSearchPage(
        controller: _ctrl,
        focusNode: _focus,
        onBack: () => Navigator.of(context).pop(),
        onClear: () => setState(() {}),
        hintText: 'Find in playlist',
        autofocus: false,
        body: body);

    if (!hasSong) return page;
    return Scaffold(
      backgroundColor: AppColors.background,
      resizeToAvoidBottomInset: false,
      body: SafeArea(
          bottom: false,
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
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
    required this.song,
    required this.songs,
    required this.playlistId,
    this.queueSource = 'playlist',
    this.isImported = false,
    this.isDownloads = false,
    this.isLocalFiles = false,
  });
  final Song song;
  final List<Song> songs;
  final String playlistId, queueSource;
  final bool isImported;
  final bool isDownloads;
  final bool isLocalFiles;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SongListTile(
      song: song,
      showIndexIndicator: false,
      onTap: () => ref.read(playerProvider.notifier).playSong(song,
          queue: songs, playlistId: playlistId, queueSource: queueSource),
      trailing: Row(mainAxisSize: MainAxisSize.min, children: [
        Text(song.durationFormatted,
            style: const TextStyle(
                color: AppColors.textMuted, fontSize: AppFontSize.md)),
        AppIconButton(
          icon: AppIcon(
              icon: AppIcons.moreVert, color: AppColors.textMuted, size: 20),
          onPressedWithContext: (btnCtx) => showSongOptionsSheet(context,
              song: song,
              ref: ref,
              buttonContext: btnCtx,
              showAddToPlaylist: !isImported && !isDownloads && !isLocalFiles,
              isDownloads: isDownloads,
              isLocalFiles: isLocalFiles,
              onRemoveFromPlaylist: isImported || isDownloads || isLocalFiles
                  ? null
                  : () {
                      ref
                          .read(libraryProvider.notifier)
                          .removeSongFromPlaylist(playlistId, song.id);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Removed from playlist'),
                                behavior: SnackBarBehavior.floating));
                      }
                    }),
          size: 40,
          iconSize: 20,
        ),
      ]),
    );
  }
}

// ─── Edit Songs Sheet (shared: playlist + liked) ──────────────────────────────

class _EditSongsSheet extends ConsumerStatefulWidget {
  const _EditSongsSheet({required this.playlistId, required this.initialSongs});
  final String playlistId;
  final List<Song> initialSongs;

  @override
  ConsumerState<_EditSongsSheet> createState() => _EditSongsSheetState();
}

class _EditSongsSheetState extends ConsumerState<_EditSongsSheet> {
  late List<Song> _items;
  final Set<String> _pendingRemoveIds = {};

  bool get _isLiked => widget.playlistId == 'liked';

  @override
  void initState() {
    super.initState();
    _items = List<Song>.from(widget.initialSongs);
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
    final toRemove = _pendingRemoveIds.length;
    if (_isLiked && toRemove > 0) {
      final confirmed = await showConfirmDialog(context,
          title: 'Remove $toRemove ${toRemove == 1 ? 'song' : 'songs'}?',
          message: 'These songs will be removed from your Liked Songs.',
          confirmLabel: 'Remove');
      if (!confirmed) return;
    }
    final toKeep =
        _items.where((s) => !_pendingRemoveIds.contains(s.id)).toList();
    await ref
        .read(libraryProvider.notifier)
        .setPlaylistSongs(widget.playlistId, toKeep);
    if (mounted) {
      if (!_isLiked) ref.invalidate(libraryPlaylistByIdProvider);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(_isLiked ? 'Liked Songs updated' : 'Playlist updated'),
          behavior: SnackBarBehavior.floating));
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: BackTitleAppBar(
        title: _isLiked ? 'Edit Liked Songs' : 'Edit playlist',
        backgroundColor: AppColors.background,
        actions: [
          AppButton(
              label: 'Save',
              variant: AppButtonVariant.text,
              foregroundColor: AppColors.primary,
              onPressed: _save,
              height: 40),
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
            leading: Row(mainAxisSize: MainAxisSize.min, children: [
              AppIconButton(
                  icon: _isLiked
                      ? FavouriteIcon(
                          isLiked: !marked,
                          songId: song.id,
                          size: 22,
                          emptyColor: AppColors.textMuted)
                      : AppIcon(
                          icon: marked
                              ? AppIcons.removeCircle
                              : AppIcons.removeCircleOutline,
                          color: marked
                              ? AppColors.accentRed
                              : AppColors.textMuted,
                          size: 22),
                  onPressed: () => _toggleRemove(song),
                  size: 40,
                  iconSize: 22),
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
                      placeholder: (_, __) => _thumbPlaceholder(),
                      errorWidget: (_, __, ___) => _thumbPlaceholder()),
                ),
              ),
            ]),
            title: Text(song.title,
                style: TextStyle(
                    color: marked
                        ? AppColors.textMuted
                        : isNowPlaying
                            ? AppColors.primary
                            : AppColors.textPrimary,
                    decoration: marked ? TextDecoration.lineThrough : null)),
            subtitle: Text(song.artist,
                style: TextStyle(
                    color: AppColors.textMuted,
                    decoration: marked ? TextDecoration.lineThrough : null)),
            trailing: ReorderableDragStartListener(
                index: index,
                child: AppIcon(
                    icon: AppIcons.dragHandle,
                    color: AppColors.textMuted,
                    size: 22)),
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
        child: const Text('Sort by',
            style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: AppFontSize.xxl,
                fontWeight: FontWeight.w700)),
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
          await ref
              .read(libraryProvider.notifier)
              .setPlaylistSortOrder(playlistId, PlaylistTrackSortOrder.title);
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
    ]);
  }
}

class _SortTile extends StatelessWidget {
  const _SortTile(
      {required this.label, required this.selected, required this.onTap});
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
  const _NameAndDetailsSheet(
      {required this.playlistId, required this.playlist});
  final String playlistId;
  final LibraryPlaylist playlist;

  @override
  ConsumerState<_NameAndDetailsSheet> createState() =>
      _NameAndDetailsSheetState();
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
    await ref.read(libraryProvider.notifier).updatePlaylist(widget.playlistId,
        name: name, description: _descCtrl.text.trim());
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Playlist updated'),
          behavior: SnackBarBehavior.floating));
      Navigator.of(context).pop();
    }
  }

  Future<void> _delete() async {
    final ok = await showConfirmDialog(context,
        title: 'Delete playlist?',
        message:
            '${widget.playlist.name.capitalized} will be removed from your library.',
        confirmLabel: 'Delete');
    if (ok && mounted) {
      Navigator.of(context).popUntil((r) => r.isFirst);
      await ref
          .read(libraryProvider.notifier)
          .deletePlaylist(widget.playlistId);
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
          padding: const EdgeInsets.fromLTRB(kSheetHorizontalPadding,
              AppSpacing.lg, kSheetHorizontalPadding, AppSpacing.sm),
          child: Row(children: [
            const SizedBox(width: 8),
            AppIconButton(
                icon: AppIcon(
                    icon: AppIcons.back,
                    size: 22,
                    color: AppColors.textPrimary),
                onPressed: () => Navigator.of(context).pop(),
                size: 40,
                iconSize: 22),
            const Spacer(),
            AppButton(
                label: 'Save',
                variant: AppButtonVariant.text,
                foregroundColor: AppColors.primary,
                onPressed: _save,
                height: 40),
          ]),
        ),
        Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: kSheetHorizontalPadding),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Column(children: [
              _NameDetailsCover(songs: widget.playlist.songs, size: coverSize),
              const SizedBox(height: AppSpacing.sm),
              AppButton(
                  label: 'Change',
                  variant: AppButtonVariant.text,
                  foregroundColor: AppColors.textSecondary,
                  icon: AppIcon(
                      icon: AppIcons.edit,
                      size: 18,
                      color: AppColors.textSecondary),
                  onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text(
                              'Cover is based on the first songs in the playlist.'),
                          behavior: SnackBarBehavior.floating)),
                  height: 40),
            ]),
            const SizedBox(width: AppSpacing.xl),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                  AppInputField(
                      controller: _nameCtrl,
                      hintText: 'Name',
                      style: InputFieldStyle.filled),
                  const SizedBox(height: AppSpacing.md),
                  AppInputField(
                      controller: _descCtrl,
                      hintText: 'Description',
                      style: InputFieldStyle.filled,
                      maxLines: 3),
                ])),
          ]),
        ),
        const SizedBox(height: AppSpacing.xxl),
        AppButton(
            label: 'Delete playlist',
            variant: AppButtonVariant.text,
            foregroundColor: AppColors.accentRed,
            onPressed: _delete),
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
          width: size,
          height: size,
          decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(AppRadius.sm)),
          child: AppIcon(icon: AppIcons.musicNote, color: AppColors.textMuted));
    }
    if (songs.length == 1) {
      return ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          child: CachedNetworkImage(
              imageUrl: songs.first.thumbnailUrl,
              width: size,
              height: size,
              fit: BoxFit.cover,
              errorWidget: (_, __, ___) => AppIcon(
                  icon: AppIcons.musicNote, color: AppColors.textMuted)));
    }
    final urls = songs.take(4).map((s) => s.thumbnailUrl).toList();
    const gap = 2.0;
    final cell = (size - gap) / 2;
    return SizedBox(
        width: size,
        height: size,
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

  Widget _cell(String? url, double s) => SizedBox(
      width: s,
      height: s,
      child: url != null
          ? CachedNetworkImage(
              imageUrl: url,
              fit: BoxFit.cover,
              errorWidget: (_, __, ___) => _place(s))
          : _place(s));

  Widget _place(double s) => Container(
      width: s,
      height: s,
      color: AppColors.surfaceLight,
      child: AppIcon(icon: AppIcons.musicNote, color: AppColors.textMuted));
}
