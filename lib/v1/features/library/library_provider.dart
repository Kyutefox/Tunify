import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tunify/v1/data/models/library_album.dart';
import 'package:tunify/v1/data/models/library_artist.dart';
import 'package:tunify/v1/data/models/library_folder.dart';
import 'package:tunify/v1/data/models/library_playlist.dart';
import 'package:tunify/v1/data/models/song.dart';
import 'package:tunify/v1/data/repositories/database_repository.dart';
import 'package:tunify/v1/features/podcast/podcast_provider.dart';
import 'package:tunify/v1/core/utils/app_log.dart';
import 'package:tunify/v1/core/utils/result.dart';

// ── Sort / view enums ─────────────────────────────────────────────────────────

enum LibrarySortOrder { recent, recentlyAdded, alphabetical }

extension LibrarySortOrderX on LibrarySortOrder {
  String get label => switch (this) {
        LibrarySortOrder.recent => 'Recently played',
        LibrarySortOrder.recentlyAdded => 'Recently added',
        LibrarySortOrder.alphabetical => 'Alphabetical',
      };

  String get value => switch (this) {
        LibrarySortOrder.recent => 'recent',
        LibrarySortOrder.recentlyAdded => 'recentlyAdded',
        LibrarySortOrder.alphabetical => 'alphabetical',
      };

  static LibrarySortOrder fromString(String s) => switch (s) {
        'recentlyAdded' => LibrarySortOrder.recentlyAdded,
        'alphabetical' => LibrarySortOrder.alphabetical,
        _ => LibrarySortOrder.recent,
      };
}

enum LibraryViewMode { list, grid }

extension LibraryViewModeX on LibraryViewMode {
  String get value => this == LibraryViewMode.grid ? 'grid' : 'list';
  static LibraryViewMode fromString(String s) =>
      s == 'grid' ? LibraryViewMode.grid : LibraryViewMode.list;
}

// ── State ─────────────────────────────────────────────────────────────────────

/// Immutable snapshot of the user's library.
///
/// Liked songs live in [playlists] as the reserved playlist with id `'liked'`.
// PERF: LibraryState no longer has a const constructor because late final fields
// (likedSongIds) are incompatible with const. The heap cost of LibraryState()
// is negligible compared to the Set allocation savings from late final.
class LibraryState {
  LibraryState({
    this.isLoading = true,
    this.playlists = const [],
    this.folders = const [],
    this.sortOrder = LibrarySortOrder.recent,
    this.viewMode = LibraryViewMode.list,
    this.searchQuery = '',
    this.downloadedShuffleMode = ShuffleMode.none,
    this.recentlyPlayedShuffleMode = ShuffleMode.none,
    this.downloadsSortOrder = PlaylistTrackSortOrder.customOrder,
    this.followedArtists = const [],
    this.followedAlbums = const [],
  });

  final bool isLoading;
  final List<LibraryPlaylist> playlists;
  final List<LibraryFolder> folders;
  final LibrarySortOrder sortOrder;
  final LibraryViewMode viewMode;
  final String searchQuery;
  final ShuffleMode downloadedShuffleMode;

  /// Convenience getter — true when any downloaded shuffle is active.
  bool get downloadedShuffleEnabled =>
      downloadedShuffleMode != ShuffleMode.none;
  final ShuffleMode recentlyPlayedShuffleMode;

  /// Convenience getter — true when any recently played shuffle is active.
  bool get recentlyPlayedShuffleEnabled =>
      recentlyPlayedShuffleMode != ShuffleMode.none;
  final PlaylistTrackSortOrder downloadsSortOrder;
  final List<LibraryArtist> followedArtists;
  final List<LibraryAlbum> followedAlbums;

  // ── Liked helpers ───────────────────────────────────────────────────────────

  LibraryPlaylist get likedPlaylist =>
      playlists.firstWhere((p) => p.id == 'liked',
          orElse: () => LibraryPlaylist(
              id: 'liked',
              name: 'Liked Songs',
              createdAt: DateTime(2000),
              updatedAt: DateTime.now(),
              songs: []));

  List<Song> get likedSongs => likedPlaylist.songs;

  /// O(1) membership test used by like-buttons throughout the app.
  ///
  /// PERF: `late final` computes and caches the Set once per [LibraryState]
  /// instance. Since the state is immutable, the Set is valid for the lifetime
  /// of this snapshot. Previously, every call (e.g. each song-list tile's
  /// select callback) created a new Set — O(n_liked) allocation per access.
  late final Set<String> likedSongIds =
      likedPlaylist.songs.map((s) => s.id).toSet();

  // ── Sorted views ────────────────────────────────────────────────────────────

  List<LibraryPlaylist> get sortedPlaylists {
    // PERF: Single-pass filter (replaces two chained .where().toList() calls).
    // toLowerCase() called once before the loop instead of per element.
    final query = searchQuery.trim();
    final hasQuery = query.isNotEmpty;
    final lowerQuery = hasQuery ? query.toLowerCase() : '';

    final list = playlists.where((p) {
      if (p.id == 'liked') return false;
      if (hasQuery && !p.name.toLowerCase().contains(lowerQuery)) return false;
      return true;
    }).toList();

    // Keep pinned order as-is (pin append order), sort only unpinned.
    final pinned = list.where((p) => p.isPinned).toList();
    final unpinned = list.where((p) => !p.isPinned).toList();
    switch (sortOrder) {
      case LibrarySortOrder.recent:
        unpinned.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      case LibrarySortOrder.recentlyAdded:
        unpinned.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      case LibrarySortOrder.alphabetical:
        unpinned.sort(
            (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    }
    return [...pinned, ...unpinned];
  }

  List<LibraryFolder> get sortedFolders {
    var list = List<LibraryFolder>.from(folders);
    if (searchQuery.trim().isNotEmpty) {
      final q = searchQuery.trim().toLowerCase();
      list = list.where((f) => f.name.toLowerCase().contains(q)).toList();
    }
    list.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return [
      ...list.where((f) => f.isPinned),
      ...list.where((f) => !f.isPinned)
    ];
  }

  LibraryState copyWith({
    bool? isLoading,
    List<LibraryPlaylist>? playlists,
    List<LibraryFolder>? folders,
    LibrarySortOrder? sortOrder,
    LibraryViewMode? viewMode,
    String? searchQuery,
    ShuffleMode? downloadedShuffleMode,
    ShuffleMode? recentlyPlayedShuffleMode,
    PlaylistTrackSortOrder? downloadsSortOrder,
    List<LibraryArtist>? followedArtists,
    List<LibraryAlbum>? followedAlbums,
  }) =>
      LibraryState(
        isLoading: isLoading ?? this.isLoading,
        playlists: playlists ?? this.playlists,
        folders: folders ?? this.folders,
        sortOrder: sortOrder ?? this.sortOrder,
        viewMode: viewMode ?? this.viewMode,
        searchQuery: searchQuery ?? this.searchQuery,
        downloadedShuffleMode:
            downloadedShuffleMode ?? this.downloadedShuffleMode,
        recentlyPlayedShuffleMode:
            recentlyPlayedShuffleMode ?? this.recentlyPlayedShuffleMode,
        downloadsSortOrder: downloadsSortOrder ?? this.downloadsSortOrder,
        followedArtists: followedArtists ?? this.followedArtists,
        followedAlbums: followedAlbums ?? this.followedAlbums,
      );
}

// ── Notifier ──────────────────────────────────────────────────────────────────

/// Manages all library mutations. All writes optimistically update in-memory
/// state then persist to SQLite via targeted operations. A background
/// [SyncManager] is a no-op placeholder unless remote sync is added later.
class LibraryNotifier extends Notifier<LibraryState> {
  DatabaseRepository get _repo => ref.read(databaseRepositoryProvider);

  @override
  LibraryState build() {
    load();
    return LibraryState();
  }

  Future<void> onAuthChanged() => load();

  Future<void> load() async {
    final result = await Result.guard(() => _repo.loadAll());
    result.when(
      ok: (data) => state = state.copyWith(
        isLoading: false,
        playlists: data.playlists,
        folders: data.folders,
        sortOrder: LibrarySortOrderX.fromString(data.sortOrder),
        viewMode: LibraryViewModeX.fromString(data.viewMode),
        downloadedShuffleMode: data.downloadedShuffleMode,
        recentlyPlayedShuffleMode: data.recentlyPlayedShuffleMode,
        downloadsSortOrder:
            PlaylistTrackSortOrderX.fromString(data.downloadsSortOrder),
        followedArtists: data.followedArtists,
        followedAlbums: data.followedAlbums,
      ),
      err: (e) {
        logWarning('Library: load failed: $e', tag: 'Library');
        state = state.copyWith(isLoading: false);
      },
    );
  }

  // ── Preferences ─────────────────────────────────────────────────────────────

  void setSearchQuery(String query) =>
      state = state.copyWith(searchQuery: query);

  void setSortOrder(LibrarySortOrder order) {
    state = state.copyWith(sortOrder: order);
    _repo.setSetting('sort_order', order.value);
  }

  void setViewMode(LibraryViewMode mode) {
    state = state.copyWith(viewMode: mode);
    _repo.setSetting('view_mode', mode.value);
  }

  // ── Liked songs ──────────────────────────────────────────────────────────────

  Future<void> toggleLiked(Song song) async {
    // Ensure the 'liked' playlist exists in state before mutating.
    final hasLiked = state.playlists.any((p) => p.id == 'liked');
    if (!hasLiked) {
      final now = DateTime.now();
      final liked = LibraryPlaylist(
          id: 'liked',
          name: 'Liked Songs',
          createdAt: DateTime(2000),
          updatedAt: now,
          songs: const []);
      state = state.copyWith(playlists: [liked, ...state.playlists]);
      await _repo.createPlaylist(liked);
    }
    final songs = List<Song>.from(state.likedPlaylist.songs);
    final idx = songs.indexWhere((s) => s.id == song.id);
    if (idx >= 0) {
      songs.removeAt(idx);
    } else {
      songs.add(song);
    }

    // Update state immediately so UI refreshes - optimized to avoid rebuilding entire list
    final likedIdx = state.playlists.indexWhere((p) => p.id == 'liked');
    if (likedIdx >= 0) {
      final updatedPlaylists = List<LibraryPlaylist>.from(state.playlists);
      updatedPlaylists[likedIdx] = updatedPlaylists[likedIdx].copyWith(
        songs: songs,
        updatedAt: DateTime.now(),
      );
      state = state.copyWith(playlists: updatedPlaylists);
    }

    await _replaceSongs('liked', songs);
  }

  // ── Shuffle ──────────────────────────────────────────────────────────────────

  void setDownloadedShuffleMode(ShuffleMode mode) {
    state = state.copyWith(downloadedShuffleMode: mode);
    _repo.setSetting('downloaded_shuffle', mode.index.toString());
  }

  void setRecentlyPlayedShuffleMode(ShuffleMode mode) {
    state = state.copyWith(recentlyPlayedShuffleMode: mode);
    _repo.setSetting('recently_played_shuffle', mode.index.toString());
  }

  Future<void> setPlaylistShuffleMode(
      String playlistId, ShuffleMode mode) async {
    state = state.copyWith(
        playlists: state.playlists
            .map((p) => p.id == playlistId ? p.copyWith(shuffleMode: mode) : p)
            .toList());
    await _repo.updatePlaylistMeta(playlistId,
        shuffleMode: mode, touchUpdatedAt: false);
  }

  // ── Playlists ────────────────────────────────────────────────────────────────

  Future<void> togglePlaylistPin(String playlistId) async {
    final playlistIdx = state.playlists.indexWhere((p) => p.id == playlistId);
    if (playlistIdx >= 0) {
      final current = state.playlists[playlistIdx];
      final newVal = !current.isPinned;
      final updated = current.copyWith(isPinned: newVal);
      final list = List<LibraryPlaylist>.from(state.playlists)
        ..removeAt(playlistIdx);
      if (newVal) {
        final insertAt = list.where((p) => p.isPinned).length;
        list.insert(insertAt, updated);
      } else {
        list.insert(0, updated);
      }
      state = state.copyWith(playlists: list);
      await _repo.updatePlaylistMeta(playlistId,
          isPinned: newVal, touchUpdatedAt: false);
      return;
    }

    final albumIdx = state.followedAlbums
        .indexWhere((a) => a.id == playlistId || a.browseId == playlistId);
    if (albumIdx >= 0) {
      await toggleAlbumPin(state.followedAlbums[albumIdx]);
      return;
    }

    final artistIdx = state.followedArtists
        .indexWhere((a) => a.id == playlistId || a.browseId == playlistId);
    if (artistIdx >= 0) {
      await toggleArtistPin(state.followedArtists[artistIdx]);
      return;
    }

    final podcasts = ref.read(podcastProvider).subscriptions;
    final podcastIdx = podcasts
        .indexWhere((p) => p.id == playlistId || p.browseId == playlistId);
    if (podcastIdx >= 0) {
      await ref
          .read(podcastProvider.notifier)
          .togglePodcastPin(podcasts[podcastIdx].id);
      return;
    }

    final audiobooks = ref.read(podcastProvider).savedAudiobooks;
    final audiobookIdx = audiobooks
        .indexWhere((a) => a.id == playlistId || a.browseId == playlistId);
    if (audiobookIdx >= 0) {
      await ref
          .read(podcastProvider.notifier)
          .toggleAudiobookPin(audiobooks[audiobookIdx].id);
      return;
    }

    logWarning('Library: togglePlaylistPin ignored unknown id=$playlistId',
        tag: 'Library');
  }

  Future<void> createPlaylist(String name) async {
    if (name.trim().isEmpty) return;
    final now = DateTime.now();
    final p = LibraryPlaylist(
      id: 'lib_${now.millisecondsSinceEpoch}',
      name: name.trim(),
      createdAt: now,
      updatedAt: now,
      songs: [],
    );
    state = state.copyWith(playlists: [p, ...state.playlists]);
    await _repo.createPlaylist(p);
  }

  Future<void> addPlaylistToLibrary(LibraryPlaylist playlist) async {
    if (state.playlists.any((p) => p.id == playlist.id)) return;
    final minimal = LibraryPlaylist(
      id: playlist.id,
      name: playlist.name,
      description: playlist.description,
      curatorName: playlist.curatorName,
      curatorThumbnailUrl: playlist.curatorThumbnailUrl,
      headerSubtitle: playlist.headerSubtitle,
      headerSecondSubtitle: playlist.headerSecondSubtitle,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      songs: const [],
      customImageUrl: playlist.customImageUrl,
      isImported: true,
      browseId: playlist.browseId ?? playlist.id,
      remoteTrackCount: playlist.songs.isNotEmpty
          ? playlist.songs.length
          : playlist.remoteTrackCount,
    );
    state = state.copyWith(playlists: [minimal, ...state.playlists]);
    await _repo.createPlaylist(minimal);
  }

  /// Exports a remote/imported playlist as a custom local playlist with all
  /// songs cloned and saved to the database. Unlike [addPlaylistToLibrary],
  /// this creates a new playlist with a unique ID and saves all songs locally
  /// so they don't need to be re-fetched.
  Future<String?> exportPlaylistToLibrary(LibraryPlaylist playlist) async {
    final now = DateTime.now();
    final newId = 'lib_${now.millisecondsSinceEpoch}';
    final exported = LibraryPlaylist(
      id: newId,
      name: playlist.name,
      description: playlist.description,
      curatorName: playlist.curatorName,
      curatorThumbnailUrl: playlist.curatorThumbnailUrl,
      headerSubtitle: playlist.headerSubtitle,
      headerSecondSubtitle: playlist.headerSecondSubtitle,
      createdAt: now,
      updatedAt: now,
      songs: List<Song>.from(playlist.songs),
      customImageUrl: playlist.customImageUrl,
      isImported: false,
      cachedPaletteColor: playlist.cachedPaletteColor,
    );
    state = state.copyWith(playlists: [exported, ...state.playlists]);
    await _repo.createPlaylist(exported);
    if (exported.songs.isNotEmpty) {
      await _repo.replacePlaylistSongs(newId, exported.songs);
    }
    return newId;
  }

  Future<void> deletePlaylist(String id) async {
    // Update in-memory folder state (DB cascade handles folder_playlists rows).
    state = state.copyWith(
      playlists: state.playlists.where((p) => p.id != id).toList(),
      folders: state.folders
          .map((f) => f.copyWith(
              playlistIds: f.playlistIds.where((pid) => pid != id).toList()))
          .toList(),
    );
    await _repo.deletePlaylist(id);
  }

  Future<void> updatePlaylist(String id,
      {String? name, String? description}) async {
    state = state.copyWith(
        playlists: state.playlists
            .map((p) => p.id != id
                ? p
                : p.copyWith(
                    name: name?.trim() ?? p.name,
                    description: description ?? p.description,
                    updatedAt: DateTime.now()))
            .toList());
    await _repo.updatePlaylistMeta(id,
        name: name?.trim(), description: description);
  }

  Future<void> setPlaylistSongs(String playlistId, List<Song> songs) async {
    state = state.copyWith(
        playlists: state.playlists
            .map((p) => p.id != playlistId
                ? p
                : p.copyWith(songs: songs, updatedAt: DateTime.now()))
            .toList());
    await _replaceSongs(playlistId, songs);
  }

  /// Updates [songId]'s duration across ALL playlists in a single state emit.
  ///
  /// PERF: Called by [PlayerNotifier._maybeUpdateLibrarySongDuration] instead
  /// of looping setPlaylistSongs() — reduces N libraryProvider state emissions
  /// (one per matching playlist) to exactly one, preventing widget rebuild
  /// cascades when a song appears in multiple playlists.
  void patchSongDuration(String songId, Duration realDuration) {
    bool anyChanged = false;
    final updatedPlaylists = state.playlists.map((playlist) {
      final idx = playlist.songs.indexWhere((s) => s.id == songId);
      if (idx == -1) return playlist;
      anyChanged = true;
      final updatedSongs = List<Song>.from(playlist.songs);
      updatedSongs[idx] = updatedSongs[idx].copyWith(duration: realDuration);
      return playlist.copyWith(songs: updatedSongs);
    }).toList();
    if (anyChanged) {
      state = state.copyWith(playlists: updatedPlaylists);
    }
  }

  Future<void> setPlaylistSortOrder(
      String playlistId, PlaylistTrackSortOrder order) async {
    state = state.copyWith(
        playlists: state.playlists
            .map((p) => p.id == playlistId ? p.copyWith(sortOrder: order) : p)
            .toList());
    await _repo.updatePlaylistMeta(playlistId,
        sortOrder: order, touchUpdatedAt: false);
  }

  Future<void> setDownloadsSortOrder(PlaylistTrackSortOrder order) async {
    state = state.copyWith(downloadsSortOrder: order);
    _repo.setSetting('downloads_sort_order', order.value);
  }

  Future<void> addSongsToPlaylist(String playlistId, List<Song> songs) async {
    late List<Song> newSongs;
    state = state.copyWith(
        playlists: state.playlists.map((p) {
      if (p.id != playlistId) return p;
      final existing = p.songs.map((s) => s.id).toSet();
      final toAdd = songs.where((s) => !existing.contains(s.id)).toList();
      newSongs = [...p.songs, ...toAdd];
      return p.copyWith(songs: newSongs, updatedAt: DateTime.now());
    }).toList());
    await _replaceSongs(playlistId, newSongs);
  }

  Future<void> removeSongFromPlaylist(String playlistId, String songId) async {
    late List<Song> newSongs;
    state = state.copyWith(
        playlists: state.playlists.map((p) {
      if (p.id != playlistId) return p;
      newSongs = p.songs.where((s) => s.id != songId).toList();
      return p.copyWith(songs: newSongs, updatedAt: DateTime.now());
    }).toList());
    await _replaceSongs(playlistId, newSongs);
  }

  Future<void> savePlaylistPaletteColor(
      String playlistId, int colorValue) async {
    state = state.copyWith(
        playlists: state.playlists
            .map((p) => p.id == playlistId
                ? p.copyWith(cachedPaletteColor: colorValue)
                : p)
            .toList());
    // Background cache write — does not update updatedAt to avoid reordering.
    await _repo.updatePlaylistMeta(playlistId,
        paletteColor: colorValue, touchUpdatedAt: false);
  }

  Future<void> refreshPlaylistMeta(String playlistId,
      {String? name, String? description, String? imageUrl}) async {
    final idx = state.playlists.indexWhere((p) => p.id == playlistId);
    if (idx < 0) return;
    final p = state.playlists[idx];
    final updated = List<LibraryPlaylist>.from(state.playlists)
      ..[idx] = p.copyWith(
        name: name ?? p.name,
        description: description ?? p.description,
        customImageUrl: imageUrl ?? p.customImageUrl,
      );
    state = state.copyWith(playlists: updated);
    // Background metadata refresh — does not update updatedAt.
    await _repo.updatePlaylistMeta(playlistId,
        name: name,
        description: description,
        coverUrl: imageUrl,
        touchUpdatedAt: false);
  }

  // ── Folders ──────────────────────────────────────────────────────────────────

  Future<void> toggleFolderPin(String folderId) async {
    state = state.copyWith(
        folders: state.folders
            .map(
                (f) => f.id == folderId ? f.copyWith(isPinned: !f.isPinned) : f)
            .toList());
    final pinnedIds =
        state.folders.where((f) => f.isPinned).map((f) => f.id).toList();
    await _repo.savePinnedFolderIds(pinnedIds);
  }

  Future<void> createFolder(String name) async {
    if (name.trim().isEmpty) return;
    final f = LibraryFolder(
      id: 'folder_${DateTime.now().millisecondsSinceEpoch}',
      name: name.trim(),
      playlistIds: [],
      createdAt: DateTime.now(),
    );
    state = state.copyWith(folders: [f, ...state.folders]);
    await _repo.createFolder(f);
  }

  Future<void> deleteFolder(String id) async {
    state = state.copyWith(
        folders: state.folders.where((f) => f.id != id).toList());
    await _repo.deleteFolder(id);
  }

  Future<void> renameFolder(String id, String newName) async {
    if (newName.trim().isEmpty) return;
    state = state.copyWith(
        folders: state.folders
            .map((f) => f.id == id ? f.copyWith(name: newName.trim()) : f)
            .toList());
    await _repo.renameFolder(id, newName.trim());
  }

  Future<void> addPlaylistToFolder(String folderId, String playlistId) async {
    state = state.copyWith(
        folders: state.folders.map((f) {
      if (f.id != folderId || f.playlistIds.contains(playlistId)) return f;
      return f.copyWith(playlistIds: [...f.playlistIds, playlistId]);
    }).toList());
    await _repo.addPlaylistToFolder(folderId, playlistId);
  }

  Future<void> removePlaylistFromFolder(
      String folderId, String playlistId) async {
    state = state.copyWith(
        folders: state.folders
            .map((f) => f.id != folderId
                ? f
                : f.copyWith(
                    playlistIds:
                        f.playlistIds.where((id) => id != playlistId).toList()))
            .toList());
    await _repo.removePlaylistFromFolder(folderId, playlistId);
  }

  // ── Artists & Albums ─────────────────────────────────────────────────────────

  Future<void> toggleFollowArtist(LibraryArtist artist) async {
    final list = List<LibraryArtist>.from(state.followedArtists);
    final idx = list.indexWhere((a) => a.id == artist.id);
    if (idx >= 0) {
      list.removeAt(idx);
      state = state.copyWith(
        followedArtists: list,
        folders: state.folders
            .map((f) => f.copyWith(
                playlistIds:
                    f.playlistIds.where((pid) => pid != artist.id).toList()))
            .toList(),
      );
      await _repo.unfollowArtist(artist.id);
    } else {
      list.add(artist);
      state = state.copyWith(followedArtists: list);
      await _repo.followArtist(artist);
    }
  }

  Future<void> toggleFollowAlbum(LibraryAlbum album) async {
    final list = List<LibraryAlbum>.from(state.followedAlbums);
    final idx = list.indexWhere((a) => a.id == album.id);
    if (idx >= 0) {
      list.removeAt(idx);
      state = state.copyWith(
        followedAlbums: list,
        folders: state.folders
            .map((f) => f.copyWith(
                playlistIds:
                    f.playlistIds.where((pid) => pid != album.id).toList()))
            .toList(),
      );
      await _repo.unfollowAlbum(album.id);
    } else {
      list.add(album);
      state = state.copyWith(followedAlbums: list);
      await _repo.followAlbum(album);
    }
  }

  Future<void> toggleAlbumPin(LibraryAlbum album) async {
    final next = !album.isPinned;
    final idx = state.followedAlbums.indexWhere((a) => a.id == album.id);
    if (idx < 0) return;
    final current = state.followedAlbums[idx];
    final updated = current.copyWith(isPinned: next);
    final list = List<LibraryAlbum>.from(state.followedAlbums)..removeAt(idx);
    if (next) {
      final insertAt = list.where((a) => a.isPinned).length;
      list.insert(insertAt, updated);
    } else {
      list.insert(0, updated);
    }
    state = state.copyWith(
      followedAlbums: list,
    );
    await _repo.updatePlaylistMeta(album.id, isPinned: next);
  }

  Future<void> toggleArtistPin(LibraryArtist artist) async {
    final next = !artist.isPinned;
    final idx = state.followedArtists.indexWhere((a) => a.id == artist.id);
    if (idx < 0) return;
    final current = state.followedArtists[idx];
    final updated = current.copyWith(isPinned: next);
    final list = List<LibraryArtist>.from(state.followedArtists)..removeAt(idx);
    if (next) {
      final insertAt = list.where((a) => a.isPinned).length;
      list.insert(insertAt, updated);
    } else {
      list.insert(0, updated);
    }
    state = state.copyWith(
      followedArtists: list,
    );
    await _repo.updatePlaylistMeta(artist.id, isPinned: next);
  }

  Future<void> saveAlbumPaletteColor(String albumId, int colorValue) async {
    state = state.copyWith(
        followedAlbums: state.followedAlbums
            .map((a) => a.id == albumId
                ? a.copyWith(cachedPaletteColor: colorValue)
                : a)
            .toList());
    await _repo.updatePlaylistMeta(albumId,
        paletteColor: colorValue, touchUpdatedAt: false);
  }

  Future<void> saveArtistPaletteColor(String artistId, int colorValue) async {
    state = state.copyWith(
        followedArtists: state.followedArtists
            .map((a) => a.id == artistId
                ? a.copyWith(cachedPaletteColor: colorValue)
                : a)
            .toList());
    await _repo.updatePlaylistMeta(artistId,
        paletteColor: colorValue, touchUpdatedAt: false);
  }

  Future<void> refreshAlbumMeta(String albumId,
      {String? title, String? artistName, String? thumbnailUrl}) async {
    final idx = state.followedAlbums
        .indexWhere((a) => a.id == albumId || a.browseId == albumId);
    if (idx < 0) return;
    final a = state.followedAlbums[idx];
    final updated = List<LibraryAlbum>.from(state.followedAlbums)
      ..[idx] = a.copyWith(
        title: title ?? a.title,
        artistName: artistName ?? a.artistName,
        thumbnailUrl: thumbnailUrl ?? a.thumbnailUrl,
      );
    state = state.copyWith(followedAlbums: updated);
    // description column stores artistName for album rows.
    await _repo.updatePlaylistMeta(albumId,
        name: title,
        description: artistName,
        coverUrl: thumbnailUrl,
        touchUpdatedAt: false);
  }

  Future<void> refreshArtistMeta(String artistId,
      {String? name, String? thumbnailUrl}) async {
    final idx = state.followedArtists
        .indexWhere((a) => a.id == artistId || a.browseId == artistId);
    if (idx < 0) return;
    final a = state.followedArtists[idx];
    final updated = List<LibraryArtist>.from(state.followedArtists)
      ..[idx] = a.copyWith(
          name: name ?? a.name, thumbnailUrl: thumbnailUrl ?? a.thumbnailUrl);
    state = state.copyWith(followedArtists: updated);
    await _repo.updatePlaylistMeta(artistId,
        name: name, coverUrl: thumbnailUrl, touchUpdatedAt: false);
  }

  // ── Private helpers ───────────────────────────────────────────────────────────

  /// Replaces songs for one playlist. Shared by all song mutation methods.
  Future<void> _replaceSongs(String playlistId, List<Song> songs) async {
    try {
      await _repo.replacePlaylistSongs(playlistId, songs);
    } catch (e) {
      logWarning('Library: replacePlaylistSongs failed: $e', tag: 'Library');
    }
  }
}

// ── Providers ─────────────────────────────────────────────────────────────────

final libraryProvider =
    NotifierProvider<LibraryNotifier, LibraryState>(LibraryNotifier.new);

final libraryPlaylistsProvider = Provider<List<LibraryPlaylist>>(
    (ref) => ref.watch(libraryProvider).sortedPlaylists);

final libraryFoldersProvider = Provider<List<LibraryFolder>>(
    (ref) => ref.watch(libraryProvider).sortedFolders);

final libraryLikedCountProvider =
    Provider<int>((ref) => ref.watch(libraryProvider).likedSongs.length);

final libraryPlaylistByIdProvider =
    Provider.family<LibraryPlaylist?, String>((ref, id) {
  return ref
      .watch(libraryProvider)
      .playlists
      .where((p) => p.id == id)
      .firstOrNull;
});

final libraryFolderByIdProvider =
    Provider.family<LibraryFolder?, String>((ref, id) {
  return ref
      .watch(libraryProvider)
      .folders
      .where((f) => f.id == id)
      .firstOrNull;
});

final likedShuffleProvider = Provider<bool>(
    (ref) => ref.watch(libraryProvider).likedPlaylist.shuffleEnabled);

final downloadedShuffleProvider = Provider<bool>(
    (ref) => ref.watch(libraryProvider).downloadedShuffleEnabled);

final downloadedShuffleModeProvider = Provider<ShuffleMode>(
    (ref) => ref.watch(libraryProvider).downloadedShuffleMode);

final recentlyPlayedShuffleProvider = Provider<bool>(
    (ref) => ref.watch(libraryProvider).recentlyPlayedShuffleEnabled);

final recentlyPlayedShuffleModeProvider = Provider<ShuffleMode>(
    (ref) => ref.watch(libraryProvider).recentlyPlayedShuffleMode);
