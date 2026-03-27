import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:tunify/data/models/library_album.dart';
import 'package:tunify/data/models/library_artist.dart';
import 'package:tunify/data/models/library_folder.dart';
import 'package:tunify/data/models/library_playlist.dart';
import 'package:tunify/data/models/song.dart';
import 'package:tunify/data/repositories/database_repository.dart';
import 'package:tunify_logger/tunify_logger.dart';
import 'package:tunify/core/utils/result.dart';
import 'package:tunify/features/auth/auth_provider.dart';

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
class LibraryState {
  const LibraryState({
    this.playlists = const [],
    this.folders = const [],
    this.sortOrder = LibrarySortOrder.recent,
    this.viewMode = LibraryViewMode.list,
    this.searchQuery = '',
    this.downloadedShuffleMode = ShuffleMode.none,
    this.downloadsSortOrder = PlaylistTrackSortOrder.customOrder,
    this.followedArtists = const [],
    this.followedAlbums = const [],
  });

  final List<LibraryPlaylist> playlists;
  final List<LibraryFolder> folders;
  final LibrarySortOrder sortOrder;
  final LibraryViewMode viewMode;
  final String searchQuery;
  final ShuffleMode downloadedShuffleMode;
  /// Convenience getter — true when any downloaded shuffle is active.
  bool get downloadedShuffleEnabled => downloadedShuffleMode != ShuffleMode.none;
  final PlaylistTrackSortOrder downloadsSortOrder;
  final List<LibraryArtist> followedArtists;
  final List<LibraryAlbum> followedAlbums;

  // ── Liked helpers ───────────────────────────────────────────────────────────

  LibraryPlaylist get likedPlaylist => playlists.firstWhere(
      (p) => p.id == 'liked',
      orElse: () => LibraryPlaylist(
          id: 'liked', name: 'Liked Songs',
          createdAt: DateTime(2000), updatedAt: DateTime.now(), songs: []));

  List<Song> get likedSongs => likedPlaylist.songs;

  /// O(1) membership test used by like-buttons throughout the app.
  Set<String> get likedSongIds => likedSongs.map((s) => s.id).toSet();

  // ── Sorted views ────────────────────────────────────────────────────────────

  List<LibraryPlaylist> get sortedPlaylists {
    var list = playlists.where((p) => p.id != 'liked').toList();
    if (searchQuery.trim().isNotEmpty) {
      final q = searchQuery.trim().toLowerCase();
      list = list.where((p) => p.name.toLowerCase().contains(q)).toList();
    }
    switch (sortOrder) {
      case LibrarySortOrder.recent:
        list.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      case LibrarySortOrder.recentlyAdded:
        list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      case LibrarySortOrder.alphabetical:
        list.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    }
    return [...list.where((p) => p.isPinned), ...list.where((p) => !p.isPinned)];
  }

  List<LibraryFolder> get sortedFolders {
    var list = List<LibraryFolder>.from(folders);
    if (searchQuery.trim().isNotEmpty) {
      final q = searchQuery.trim().toLowerCase();
      list = list.where((f) => f.name.toLowerCase().contains(q)).toList();
    }
    list.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return [...list.where((f) => f.isPinned), ...list.where((f) => !f.isPinned)];
  }

  LibraryState copyWith({
    List<LibraryPlaylist>? playlists,
    List<LibraryFolder>? folders,
    LibrarySortOrder? sortOrder,
    LibraryViewMode? viewMode,
    String? searchQuery,
    ShuffleMode? downloadedShuffleMode,
    PlaylistTrackSortOrder? downloadsSortOrder,
    List<LibraryArtist>? followedArtists,
    List<LibraryAlbum>? followedAlbums,
  }) => LibraryState(
    playlists: playlists ?? this.playlists,
    folders: folders ?? this.folders,
    sortOrder: sortOrder ?? this.sortOrder,
    viewMode: viewMode ?? this.viewMode,
    searchQuery: searchQuery ?? this.searchQuery,
    downloadedShuffleMode: downloadedShuffleMode ?? this.downloadedShuffleMode,
    downloadsSortOrder: downloadsSortOrder ?? this.downloadsSortOrder,
    followedArtists: followedArtists ?? this.followedArtists,
    followedAlbums: followedAlbums ?? this.followedAlbums,
  );
}

// ── Notifier ──────────────────────────────────────────────────────────────────

/// Manages all library mutations. All writes optimistically update in-memory
/// state then persist to SQLite via targeted operations. A background
/// [SyncManager] handles Supabase sync.
class LibraryNotifier extends Notifier<LibraryState> {
  DatabaseRepository get _repo => ref.read(databaseRepositoryProvider);
  User? get _user => ref.read(currentUserProvider);

  @override
  LibraryState build() {
    load();
    return const LibraryState();
  }

  Future<void> onAuthChanged(User? user) => load();

  Future<void> load() async {
    final result = await Result.guard(() => _repo.loadAll(userId: _user?.id));
    result.when(
      ok: (data) => state = state.copyWith(
        playlists: data.playlists,
        folders: data.folders,
        sortOrder: LibrarySortOrderX.fromString(data.sortOrder),
        viewMode: LibraryViewModeX.fromString(data.viewMode),
        downloadedShuffleMode: data.downloadedShuffleMode,
        downloadsSortOrder: PlaylistTrackSortOrderX.fromString(data.downloadsSortOrder),
        followedArtists: data.followedArtists,
        followedAlbums: data.followedAlbums,
      ),
      err: (e) => logWarning('Library: load failed: $e', tag: 'Library'),
    );
  }

  // ── Preferences ─────────────────────────────────────────────────────────────

  void setSearchQuery(String query) => state = state.copyWith(searchQuery: query);

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
          id: 'liked', name: 'Liked Songs',
          createdAt: DateTime(2000), updatedAt: now, songs: const []);
      state = state.copyWith(playlists: [liked, ...state.playlists]);
      await _repo.createPlaylist(liked);
    }
    final songs = List<Song>.from(state.likedPlaylist.songs);
    final idx = songs.indexWhere((s) => s.id == song.id);
    if (idx >= 0) { songs.removeAt(idx); } else { songs.add(song); }
    await _replaceSongs('liked', songs);
  }

  // ── Shuffle ──────────────────────────────────────────────────────────────────

  void setDownloadedShuffleMode(ShuffleMode mode) {
    state = state.copyWith(downloadedShuffleMode: mode);
    _repo.setSetting('downloaded_shuffle', mode.index.toString());
  }

  Future<void> setPlaylistShuffleMode(String playlistId, ShuffleMode mode) async {
    state = state.copyWith(playlists: state.playlists.map((p) =>
        p.id == playlistId ? p.copyWith(shuffleMode: mode) : p).toList());
    await _repo.updatePlaylistMeta(playlistId,
        shuffleMode: mode, touchUpdatedAt: false);
  }

  // ── Playlists ────────────────────────────────────────────────────────────────

  Future<void> togglePlaylistPin(String playlistId) async {
    final newVal = !state.playlists
        .firstWhere((p) => p.id == playlistId)
        .isPinned;
    state = state.copyWith(playlists: state.playlists.map((p) =>
        p.id == playlistId ? p.copyWith(isPinned: newVal) : p).toList());
    await _repo.updatePlaylistMeta(playlistId,
        isPinned: newVal, touchUpdatedAt: false);
  }

  Future<void> createPlaylist(String name) async {
    if (name.trim().isEmpty) return;
    final now = DateTime.now();
    final p = LibraryPlaylist(
      id: 'lib_${now.millisecondsSinceEpoch}',
      name: name.trim(),
      createdAt: now, updatedAt: now, songs: [],
    );
    state = state.copyWith(playlists: [p, ...state.playlists]);
    await _repo.createPlaylist(p);
  }

  Future<void> addPlaylistToLibrary(LibraryPlaylist playlist) async {
    if (state.playlists.any((p) => p.id == playlist.id)) return;
    final minimal = LibraryPlaylist(
      id: playlist.id, name: playlist.name, description: playlist.description,
      createdAt: DateTime.now(), updatedAt: DateTime.now(), songs: const [],
      customImageUrl: playlist.customImageUrl,
      isImported: true, browseId: playlist.browseId ?? playlist.id,
      remoteTrackCount: playlist.songs.isNotEmpty
          ? playlist.songs.length
          : playlist.remoteTrackCount,
    );
    state = state.copyWith(playlists: [minimal, ...state.playlists]);
    await _repo.createPlaylist(minimal);
  }

  Future<void> deletePlaylist(String id) async {
    // Update in-memory folder state (DB cascade handles folder_playlists rows).
    state = state.copyWith(
      playlists: state.playlists.where((p) => p.id != id).toList(),
      folders: state.folders.map((f) => f.copyWith(
          playlistIds: f.playlistIds.where((pid) => pid != id).toList())).toList(),
    );
    await _repo.deletePlaylist(id);
  }

  Future<void> updatePlaylist(String id, {String? name, String? description}) async {
    state = state.copyWith(playlists: state.playlists.map((p) => p.id != id ? p :
        p.copyWith(
          name: name?.trim() ?? p.name,
          description: description ?? p.description,
          updatedAt: DateTime.now())).toList());
    await _repo.updatePlaylistMeta(id,
        name: name?.trim(), description: description);
  }

  Future<void> setPlaylistSongs(String playlistId, List<Song> songs) async {
    state = state.copyWith(playlists: state.playlists.map((p) => p.id != playlistId ? p :
        p.copyWith(songs: songs, updatedAt: DateTime.now())).toList());
    await _replaceSongs(playlistId, songs);
  }

  Future<void> setPlaylistSortOrder(String playlistId, PlaylistTrackSortOrder order) async {
    state = state.copyWith(playlists: state.playlists.map((p) =>
        p.id == playlistId ? p.copyWith(sortOrder: order) : p).toList());
    await _repo.updatePlaylistMeta(playlistId, sortOrder: order, touchUpdatedAt: false);
  }

  Future<void> setDownloadsSortOrder(PlaylistTrackSortOrder order) async {
    state = state.copyWith(downloadsSortOrder: order);
    _repo.setSetting('downloads_sort_order', order.value);
  }

  Future<void> addSongsToPlaylist(String playlistId, List<Song> songs) async {
    late List<Song> newSongs;
    state = state.copyWith(playlists: state.playlists.map((p) {
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
    state = state.copyWith(playlists: state.playlists.map((p) {
      if (p.id != playlistId) return p;
      newSongs = p.songs.where((s) => s.id != songId).toList();
      return p.copyWith(songs: newSongs, updatedAt: DateTime.now());
    }).toList());
    await _replaceSongs(playlistId, newSongs);
  }

  Future<void> savePlaylistPaletteColor(String playlistId, int colorValue) async {
    state = state.copyWith(playlists: state.playlists.map((p) =>
        p.id == playlistId ? p.copyWith(cachedPaletteColor: colorValue) : p).toList());
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
        name: name, description: description, coverUrl: imageUrl,
        touchUpdatedAt: false);
  }

  // ── Folders ──────────────────────────────────────────────────────────────────

  Future<void> toggleFolderPin(String folderId) async {
    state = state.copyWith(folders: state.folders.map((f) =>
        f.id == folderId ? f.copyWith(isPinned: !f.isPinned) : f).toList());
    final pinnedIds = state.folders
        .where((f) => f.isPinned)
        .map((f) => f.id)
        .toList();
    await _repo.savePinnedFolderIds(pinnedIds);
  }

  Future<void> createFolder(String name) async {
    if (name.trim().isEmpty) return;
    final f = LibraryFolder(
      id: 'folder_${DateTime.now().millisecondsSinceEpoch}',
      name: name.trim(), playlistIds: [], createdAt: DateTime.now(),
    );
    state = state.copyWith(folders: [f, ...state.folders]);
    await _repo.createFolder(f);
  }

  Future<void> deleteFolder(String id) async {
    state = state.copyWith(folders: state.folders.where((f) => f.id != id).toList());
    await _repo.deleteFolder(id);
  }

  Future<void> renameFolder(String id, String newName) async {
    if (newName.trim().isEmpty) return;
    state = state.copyWith(folders: state.folders.map((f) =>
        f.id == id ? f.copyWith(name: newName.trim()) : f).toList());
    await _repo.renameFolder(id, newName.trim());
  }

  Future<void> addPlaylistToFolder(String folderId, String playlistId) async {
    state = state.copyWith(folders: state.folders.map((f) {
      if (f.id != folderId || f.playlistIds.contains(playlistId)) return f;
      return f.copyWith(playlistIds: [...f.playlistIds, playlistId]);
    }).toList());
    await _repo.addPlaylistToFolder(folderId, playlistId);
  }

  Future<void> removePlaylistFromFolder(String folderId, String playlistId) async {
    state = state.copyWith(folders: state.folders.map((f) => f.id != folderId ? f :
        f.copyWith(playlistIds: f.playlistIds.where((id) => id != playlistId).toList())).toList());
    await _repo.removePlaylistFromFolder(folderId, playlistId);
  }

  // ── Artists & Albums ─────────────────────────────────────────────────────────

  Future<void> toggleFollowArtist(LibraryArtist artist) async {
    final list = List<LibraryArtist>.from(state.followedArtists);
    final idx = list.indexWhere((a) => a.id == artist.id);
    if (idx >= 0) {
      list.removeAt(idx);
      state = state.copyWith(followedArtists: list);
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
      state = state.copyWith(followedAlbums: list);
      await _repo.unfollowAlbum(album.id);
    } else {
      list.add(album);
      state = state.copyWith(followedAlbums: list);
      await _repo.followAlbum(album);
    }
  }

  Future<void> saveAlbumPaletteColor(String albumId, int colorValue) async {
    state = state.copyWith(followedAlbums: state.followedAlbums.map((a) =>
        a.id == albumId ? a.copyWith(cachedPaletteColor: colorValue) : a).toList());
    await _repo.updatePlaylistMeta(albumId,
        paletteColor: colorValue, touchUpdatedAt: false);
  }

  Future<void> saveArtistPaletteColor(String artistId, int colorValue) async {
    state = state.copyWith(followedArtists: state.followedArtists.map((a) =>
        a.id == artistId ? a.copyWith(cachedPaletteColor: colorValue) : a).toList());
    await _repo.updatePlaylistMeta(artistId,
        paletteColor: colorValue, touchUpdatedAt: false);
  }

  Future<void> refreshAlbumMeta(String albumId,
      {String? title, String? artistName, String? thumbnailUrl}) async {
    final idx = state.followedAlbums.indexWhere((a) => a.id == albumId || a.browseId == albumId);
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
        name: title, description: artistName, coverUrl: thumbnailUrl,
        touchUpdatedAt: false);
  }

  Future<void> refreshArtistMeta(String artistId,
      {String? name, String? thumbnailUrl}) async {
    final idx = state.followedArtists.indexWhere((a) => a.id == artistId || a.browseId == artistId);
    if (idx < 0) return;
    final a = state.followedArtists[idx];
    final updated = List<LibraryArtist>.from(state.followedArtists)
      ..[idx] = a.copyWith(name: name ?? a.name, thumbnailUrl: thumbnailUrl ?? a.thumbnailUrl);
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

final libraryPlaylistsProvider = Provider<List<LibraryPlaylist>>((ref) =>
    ref.watch(libraryProvider).sortedPlaylists);

final libraryFoldersProvider = Provider<List<LibraryFolder>>((ref) =>
    ref.watch(libraryProvider).sortedFolders);

final libraryLikedCountProvider = Provider<int>((ref) =>
    ref.watch(libraryProvider).likedSongs.length);

final libraryPlaylistByIdProvider =
    Provider.family<LibraryPlaylist?, String>((ref, id) {
  return ref.watch(libraryProvider).playlists
      .where((p) => p.id == id).firstOrNull;
});

final libraryFolderByIdProvider =
    Provider.family<LibraryFolder?, String>((ref, id) {
  return ref.watch(libraryProvider).folders
      .where((f) => f.id == id).firstOrNull;
});

final likedShuffleProvider = Provider<bool>((ref) =>
    ref.watch(libraryProvider).likedPlaylist.shuffleEnabled);

final downloadedShuffleProvider = Provider<bool>((ref) =>
    ref.watch(libraryProvider).downloadedShuffleEnabled);

final downloadedShuffleModeProvider = Provider<ShuffleMode>((ref) =>
    ref.watch(libraryProvider).downloadedShuffleMode);
