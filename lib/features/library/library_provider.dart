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

/// Sort order for the library playlist and folder lists.
enum LibrarySortOrder {
  /// Most recently played first (sorted by [LibraryPlaylist.updatedAt]).
  recent,
  /// Most recently created first (sorted by [LibraryPlaylist.createdAt]).
  recentlyAdded,
  alphabetical,
}

/// Serialization helpers for [LibrarySortOrder].
extension LibrarySortOrderX on LibrarySortOrder {
  String get label {
    switch (this) {
      case LibrarySortOrder.recent:
        return 'Recently played';
      case LibrarySortOrder.recentlyAdded:
        return 'Recently added';
      case LibrarySortOrder.alphabetical:
        return 'Alphabetical';
    }
  }

  static LibrarySortOrder fromString(String s) {
    switch (s) {
      case 'recentlyAdded':
        return LibrarySortOrder.recentlyAdded;
      case 'alphabetical':
        return LibrarySortOrder.alphabetical;
      default:
        return LibrarySortOrder.recent;
    }
  }

  String get value {
    switch (this) {
      case LibrarySortOrder.recent:
        return 'recent';
      case LibrarySortOrder.recentlyAdded:
        return 'recentlyAdded';
      case LibrarySortOrder.alphabetical:
        return 'alphabetical';
    }
  }
}

/// Layout mode for the library screen's playlist/folder list.
enum LibraryViewMode {
  list,
  grid,
}

extension LibraryViewModeX on LibraryViewMode {
  String get value => this == LibraryViewMode.grid ? 'grid' : 'list';
  static LibraryViewMode fromString(String s) =>
      s == 'grid' ? LibraryViewMode.grid : LibraryViewMode.list;
}

/// Immutable snapshot of the user's library: playlists, folders, liked songs,
/// followed artists/albums, and display preferences (sort, view mode, search query).
class LibraryState {
  final List<LibraryPlaylist> playlists;
  final List<LibraryFolder> folders;
  final List<Song> likedSongs;
  final LibrarySortOrder sortOrder;
  final LibraryViewMode viewMode;
  final String searchQuery;
  final bool likedShuffleEnabled;
  final bool downloadedShuffleEnabled;
  final List<LibraryArtist> followedArtists;
  final List<LibraryAlbum> followedAlbums;

  LibraryState({
    this.playlists = const [],
    this.folders = const [],
    this.likedSongs = const [],
    this.sortOrder = LibrarySortOrder.recent,
    this.viewMode = LibraryViewMode.list,
    this.searchQuery = '',
    this.likedShuffleEnabled = false,
    this.downloadedShuffleEnabled = false,
    this.followedArtists = const [],
    this.followedAlbums = const [],
  });

  /// O(1) membership test for like-button selectors in the player and mini-player.
  late final Set<String> likedSongIds = likedSongs.map((s) => s.id).toSet();

  List<LibraryPlaylist> get sortedPlaylists {
    var list = List<LibraryPlaylist>.from(playlists);
    if (searchQuery.trim().isNotEmpty) {
      final q = searchQuery.trim().toLowerCase();
      list = list.where((p) => p.name.toLowerCase().contains(q)).toList();
    }
    switch (sortOrder) {
      case LibrarySortOrder.recent:
        list.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
        break;
      case LibrarySortOrder.recentlyAdded:
        list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case LibrarySortOrder.alphabetical:
        list.sort(
            (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        break;
    }
    final pinned = list.where((p) => p.isPinned).toList();
    final unpinned = list.where((p) => !p.isPinned).toList();
    return [...pinned, ...unpinned];
  }

  List<LibraryFolder> get sortedFolders {
    var list = List<LibraryFolder>.from(folders);
    if (searchQuery.trim().isNotEmpty) {
      final q = searchQuery.trim().toLowerCase();
      list = list.where((f) => f.name.toLowerCase().contains(q)).toList();
    }
    list.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    final pinned = list.where((f) => f.isPinned).toList();
    final unpinned = list.where((f) => !f.isPinned).toList();
    return [...pinned, ...unpinned];
  }

  LibraryState copyWith({
    List<LibraryPlaylist>? playlists,
    List<LibraryFolder>? folders,
    List<Song>? likedSongs,
    LibrarySortOrder? sortOrder,
    LibraryViewMode? viewMode,
    String? searchQuery,
    bool? likedShuffleEnabled,
    bool? downloadedShuffleEnabled,
    List<LibraryArtist>? followedArtists,
    List<LibraryAlbum>? followedAlbums,
  }) {
    return LibraryState(
      playlists: playlists ?? this.playlists,
      folders: folders ?? this.folders,
      likedSongs: likedSongs ?? this.likedSongs,
      sortOrder: sortOrder ?? this.sortOrder,
      viewMode: viewMode ?? this.viewMode,
      searchQuery: searchQuery ?? this.searchQuery,
      likedShuffleEnabled: likedShuffleEnabled ?? this.likedShuffleEnabled,
      downloadedShuffleEnabled:
          downloadedShuffleEnabled ?? this.downloadedShuffleEnabled,
      followedArtists: followedArtists ?? this.followedArtists,
      followedAlbums: followedAlbums ?? this.followedAlbums,
    );
  }
}

/// Manages all library mutations: create/delete/rename playlists and folders,
/// like/unlike songs, follow/unfollow artists and albums, and update display preferences.
///
/// All write methods optimistically update in-memory state before persisting
/// to SQLite via [DatabaseRepository]. A background [SyncManager] handles Supabase sync.
class LibraryNotifier extends Notifier<LibraryState> {
  DatabaseRepository get _repository => ref.read(databaseRepositoryProvider);

  User? get _user => ref.read(currentUserProvider);

  @override
  LibraryState build() {
    load();
    return LibraryState();
  }

  Future<void> onAuthChanged(User? user) async {
    await load();
  }

  Future<void> load() async {
    final userId = _user?.id;
    final result = await Result.guard(() => _repository.loadAll(userId: userId));
    result.when(
      ok: (data) {
        state = state.copyWith(
          playlists: data.playlists,
          folders: data.folders,
          likedSongs: data.likedSongs,
          sortOrder: LibrarySortOrderX.fromString(data.sortOrder),
          viewMode: LibraryViewModeX.fromString(data.viewMode),
          likedShuffleEnabled: data.likedShuffleEnabled,
          downloadedShuffleEnabled: data.downloadedShuffleEnabled,
          followedArtists: data.followedArtists,
          followedAlbums: data.followedAlbums,
        );
      },
      err: (e) {
        logWarning('Library: load failed: $e', tag: 'Library');
      },
    );
  }

  Future<void> _persist() async {
    final userId = _user?.id;
    try {
      await _repository.saveAll(
        data: (
          playlists: state.playlists,
          folders: state.folders,
          likedSongs: state.likedSongs,
          sortOrder: state.sortOrder.value,
          viewMode: state.viewMode.value,
          likedShuffleEnabled: state.likedShuffleEnabled,
          downloadedShuffleEnabled: state.downloadedShuffleEnabled,
          playlistShuffles: {
            for (final p in state.playlists)
              if (p.shuffleEnabled) p.id: true
          },
          followedArtists: state.followedArtists,
          followedAlbums: state.followedAlbums,
        ),
        userId: userId,
      );
    } catch (e) {
      // Non-fatal: in-memory state is already updated so the UI reflects the
      // change immediately. Logged for diagnostics; sync will retry on next write.
      logWarning('Library: _persist failed: $e', tag: 'Library');
    }
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void setSortOrder(LibrarySortOrder order) {
    state = state.copyWith(sortOrder: order);
    _persist();
  }

  void setViewMode(LibraryViewMode mode) {
    state = state.copyWith(viewMode: mode);
    _persist();
  }

  void toggleLikedShuffle() {
    state = state.copyWith(likedShuffleEnabled: !state.likedShuffleEnabled);
    _persist();
  }

  void toggleDownloadedShuffle() {
    state = state.copyWith(
        downloadedShuffleEnabled: !state.downloadedShuffleEnabled);
    _persist();
  }

  void togglePlaylistShuffle(String playlistId) {
    final updated = state.playlists.map((p) {
      if (p.id != playlistId) return p;
      return p.copyWith(shuffleEnabled: !p.shuffleEnabled);
    }).toList();
    state = state.copyWith(playlists: updated);
    _persist();
  }

  Future<void> togglePlaylistPin(String playlistId) async {
    final updated = state.playlists.map((p) {
      if (p.id != playlistId) return p;
      return p.copyWith(isPinned: !p.isPinned);
    }).toList();
    state = state.copyWith(playlists: updated);
    await _persist();
  }

  Future<void> toggleFolderPin(String folderId) async {
    final updated = state.folders.map((f) {
      if (f.id != folderId) return f;
      return f.copyWith(isPinned: !f.isPinned);
    }).toList();
    state = state.copyWith(folders: updated);
    await _persist();
  }

  Future<void> createPlaylist(String name) async {
    if (name.trim().isEmpty) return;
    final id = 'lib_${DateTime.now().millisecondsSinceEpoch}';
    final now = DateTime.now();
    final p = LibraryPlaylist(
      id: id,
      name: name.trim(),
      createdAt: now,
      updatedAt: now,
      songs: [],
    );
    final updated = [p, ...state.playlists];
    state = state.copyWith(playlists: updated);
    await _persist();
  }

  /// Saves a remote playlist reference into the library.
  /// Only stores id, name, description, browseId, and customImageUrl — no songs.
  /// Songs are always re-fetched fresh when the playlist is opened.
  Future<void> addPlaylistToLibrary(LibraryPlaylist playlist) async {
    if (state.playlists.any((p) => p.id == playlist.id)) return;
    final minimal = LibraryPlaylist(
      id: playlist.id,
      name: playlist.name,
      description: playlist.description,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      songs: const [],
      customImageUrl: playlist.customImageUrl,
      isImported: true,
      browseId: playlist.browseId ?? playlist.id,
    );
    state = state.copyWith(playlists: [minimal, ...state.playlists]);
    await _persist();
  }

  Future<void> deletePlaylist(String id) async {
    final updated = state.playlists.where((p) => p.id != id).toList();
    final foldersUpdated = state.folders.map((f) {
      return f.copyWith(
          playlistIds: f.playlistIds.where((pid) => pid != id).toList());
    }).toList();
    state = state.copyWith(playlists: updated, folders: foldersUpdated);
    await _persist();
  }

  Future<void> renamePlaylist(String id, String newName) async {
    if (newName.trim().isEmpty) return;
    final updated = state.playlists.map((p) {
      if (p.id != id) return p;
      return p.copyWith(name: newName.trim(), updatedAt: DateTime.now());
    }).toList();
    state = state.copyWith(playlists: updated);
    await _persist();
  }

  Future<void> updatePlaylist(String id,
      {String? name, String? description}) async {
    final updated = state.playlists.map((p) {
      if (p.id != id) return p;
      return p.copyWith(
        name: name?.trim() ?? p.name,
        description: description ?? p.description,
        updatedAt: DateTime.now(),
      );
    }).toList();
    state = state.copyWith(playlists: updated);
    await _persist();
  }

  Future<void> setPlaylistSongs(String playlistId, List<Song> songs) async {
    final updated = state.playlists.map((p) {
      if (p.id != playlistId) return p;
      return p.copyWith(songs: songs, updatedAt: DateTime.now());
    }).toList();
    state = state.copyWith(playlists: updated);
    await _persist();
  }

  Future<void> setPlaylistSortOrder(
      String playlistId, PlaylistTrackSortOrder order) async {
    final updated = state.playlists.map((p) {
      if (p.id != playlistId) return p;
      return p.copyWith(sortOrder: order);
    }).toList();
    state = state.copyWith(playlists: updated);
    await _persist();
  }

  Future<void> addSongsToPlaylist(String playlistId, List<Song> songs) async {
    final updated = state.playlists.map((p) {
      if (p.id != playlistId) return p;
      final existingIds = p.songs.map((s) => s.id).toSet();
      final toAdd = songs.where((s) => !existingIds.contains(s.id)).toList();
      return p.copyWith(
        songs: [...p.songs, ...toAdd],
        updatedAt: DateTime.now(),
      );
    }).toList();
    state = state.copyWith(playlists: updated);
    await _persist();
  }

  Future<void> removeSongFromPlaylist(String playlistId, String songId) async {
    final updated = state.playlists.map((p) {
      if (p.id != playlistId) return p;
      return p.copyWith(
        songs: p.songs.where((s) => s.id != songId).toList(),
        updatedAt: DateTime.now(),
      );
    }).toList();
    state = state.copyWith(playlists: updated);
    await _persist();
  }

  Future<void> createFolder(String name) async {
    if (name.trim().isEmpty) return;
    final id = 'folder_${DateTime.now().millisecondsSinceEpoch}';
    final f = LibraryFolder(
      id: id,
      name: name.trim(),
      playlistIds: [],
      createdAt: DateTime.now(),
    );
    final updated = [f, ...state.folders];
    state = state.copyWith(folders: updated);
    await _persist();
  }

  Future<void> deleteFolder(String id) async {
    final updated = state.folders.where((f) => f.id != id).toList();
    state = state.copyWith(folders: updated);
    await _persist();
  }

  Future<void> renameFolder(String id, String newName) async {
    if (newName.trim().isEmpty) return;
    final updated = state.folders.map((f) {
      if (f.id != id) return f;
      return f.copyWith(name: newName.trim());
    }).toList();
    state = state.copyWith(folders: updated);
    await _persist();
  }

  Future<void> addPlaylistToFolder(String folderId, String playlistId) async {
    final updated = state.folders.map((f) {
      if (f.id != folderId) return f;
      if (f.playlistIds.contains(playlistId)) return f;
      return f.copyWith(playlistIds: [...f.playlistIds, playlistId]);
    }).toList();
    state = state.copyWith(folders: updated);
    await _persist();
  }

  Future<void> removePlaylistFromFolder(
      String folderId, String playlistId) async {
    final updated = state.folders.map((f) {
      if (f.id != folderId) return f;
      return f.copyWith(
          playlistIds: f.playlistIds.where((id) => id != playlistId).toList());
    }).toList();
    state = state.copyWith(folders: updated);
    await _persist();
  }

  Future<void> toggleLiked(Song song) async {
    final list = List<Song>.from(state.likedSongs);
    final idx = list.indexWhere((s) => s.id == song.id);
    if (idx >= 0) {
      list.removeAt(idx);
    } else {
      list.add(song);
    }
    state = state.copyWith(likedSongs: list);
    await _persist();
  }

  Future<void> setLikedSongsOrder(List<Song> ordered) async {
    state = state.copyWith(likedSongs: ordered);
    await _persist();
  }

  Future<void> toggleFollowArtist(LibraryArtist artist) async {
    final list = List<LibraryArtist>.from(state.followedArtists);
    final idx = list.indexWhere((a) => a.id == artist.id);
    if (idx >= 0) {
      list.removeAt(idx);
    } else {
      list.add(artist);
    }
    state = state.copyWith(followedArtists: list);
    await _persist();
  }

  Future<void> toggleFollowAlbum(LibraryAlbum album) async {
    final list = List<LibraryAlbum>.from(state.followedAlbums);
    final idx = list.indexWhere((a) => a.id == album.id);
    if (idx >= 0) {
      list.removeAt(idx);
    } else {
      list.add(album);
    }
    state = state.copyWith(followedAlbums: list);
    await _persist();
  }
}

final libraryProvider =
    NotifierProvider<LibraryNotifier, LibraryState>(LibraryNotifier.new);

final libraryPlaylistsProvider = Provider<List<LibraryPlaylist>>((ref) {
  return ref.watch(libraryProvider).sortedPlaylists;
});

final libraryFoldersProvider = Provider<List<LibraryFolder>>((ref) {
  return ref.watch(libraryProvider).sortedFolders;
});

final libraryLikedCountProvider = Provider<int>((ref) {
  return ref.watch(libraryProvider).likedSongs.length;
});

final libraryPlaylistByIdProvider =
    Provider.family<LibraryPlaylist?, String>((ref, id) {
  final list = ref.watch(libraryProvider).playlists;
  final match = list.where((p) => p.id == id).toList();
  return match.isNotEmpty ? match.first : null;
});

final libraryFolderByIdProvider =
    Provider.family<LibraryFolder?, String>((ref, id) {
  final list = ref.watch(libraryProvider).folders;
  final match = list.where((f) => f.id == id).toList();
  return match.isNotEmpty ? match.first : null;
});

final likedShuffleProvider = Provider<bool>((ref) {
  return ref.watch(libraryProvider).likedShuffleEnabled;
});

final downloadedShuffleProvider = Provider<bool>((ref) {
  return ref.watch(libraryProvider).downloadedShuffleEnabled;
});
