import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import 'package:tunify/data/models/library_album.dart';
import 'package:tunify/data/models/library_artist.dart';
import 'package:tunify/data/models/library_folder.dart';
import 'package:tunify/data/models/library_playlist.dart';
import 'package:tunify/data/models/recently_played_song.dart';
import 'package:tunify/data/models/song.dart';
import 'package:tunify_database/tunify_database.dart';

typedef LibraryData = ({
  List<LibraryPlaylist> playlists,
  List<LibraryFolder> folders,
  List<Song> likedSongs,
  String sortOrder,
  String viewMode,
  bool likedShuffleEnabled,
  bool downloadedShuffleEnabled,
  Map<String, bool> playlistShuffles,
  List<LibraryArtist> followedArtists,
  List<LibraryAlbum> followedAlbums,
});

/// Single source of truth: uses [DatabaseBridge] (SQLite). On login, call
/// [pullFromSupabase] once; background sync pushes to Supabase. All reads/writes
/// go through the bridge; write methods call [requestSync] after persisting.
class DatabaseRepository {
  DatabaseRepository(this._bridge, this._syncManager);
  final DatabaseBridge _bridge;
  final SyncManager _syncManager;

  Future<LibraryData> loadAll({String? userId}) async {
    final raw = await _bridge.loadLibraryData();
    return _rawToLibraryData(raw);
  }

  /// Saves library and requests a background sync.
  Future<void> saveAll({
    required LibraryData data,
    String? userId,
  }) async {
    await _bridge.saveLibraryData(_libraryDataToRaw(data));
    _syncManager.requestSync();
  }

  Future<List<RecentlyPlayedSong>> loadRecentlyPlayed({String? userId}) async {
    final list = await _bridge.loadRecentlyPlayed();
    return list.map((m) => RecentlyPlayedSong(
      id: m['id'] as String? ?? '',
      title: m['title'] as String? ?? '',
      artist: m['artist'] as String? ?? '',
      thumbnailUrl: m['thumbnailUrl'] as String? ?? '',
      durationSeconds: m['durationSeconds'] as int? ?? (m['durationMs'] != null ? (m['durationMs'] as int) ~/ 1000 : 0),
      lastPlayed: m['lastPlayed'] != null ? DateTime.parse(m['lastPlayed'] as String) : DateTime.now(),
    )).toList();
  }

  /// Saves recently played and requests a background sync.
  Future<void> saveRecentlyPlayed(
    List<RecentlyPlayedSong> songs, {
    String? userId,
  }) async {
    await _bridge.saveRecentlyPlayed(songs.map((s) => s.toJson()).toList());
    _syncManager.requestSync();
  }

  /// Reads a setting by [key].
  Future<String?> getSetting(String key) async => _bridge.getSetting(key);

  /// Writes [key]=[value] and requests a background sync.
  Future<void> setSetting(String key, String value) async {
    await _bridge.setSetting(key, value);
    _syncManager.requestSync();
  }

  Future<Map<String, dynamic>> loadPlaybackSettings() async => _bridge.loadPlaybackSettings();

  /// Saves one playback setting and requests a background sync.
  Future<void> savePlaybackSetting(String key, dynamic value) async {
    await _bridge.savePlaybackSetting(key, value.toString());
    _syncManager.requestSync();
  }

  Future<List<String>> loadRecentSearches() async => _bridge.loadRecentSearches();

  /// Saves recent searches and requests a background sync.
  Future<void> saveRecentSearches(List<String> queries) async {
    await _bridge.saveRecentSearches(queries);
    _syncManager.requestSync();
  }

  Future<List<String>> loadDownloadedSongIds() async => _bridge.loadDownloadedSongIds();

  /// Saves downloaded song IDs and requests a background sync.
  Future<void> saveDownloadedSongIds(List<String> ids) async {
    await _bridge.saveDownloadedSongIds(ids);
    _syncManager.requestSync();
  }

  Future<Map<String, dynamic>> loadYtPersonalization() async => _bridge.loadYtPersonalization();

  /// Saves YT personalization and requests a background sync.
  Future<void> saveYtPersonalization(Map<String, dynamic> data) async {
    await _bridge.saveYtPersonalization(data);
    _syncManager.requestSync();
  }

  Future<void> close() async => _bridge.close();

  LibraryData _rawToLibraryData(Map<String, dynamic> raw) {
    final playlistsRaw = raw['playlists'] as List<dynamic>? ?? [];
    final foldersRaw = raw['folders'] as List<dynamic>? ?? [];
    final likedRaw = raw['likedSongs'] as List<dynamic>? ?? [];

    final playlists = playlistsRaw.map((p) {
      final m = Map<String, dynamic>.from(p as Map);
      final songsList = m['songs'] as List<dynamic>? ?? [];
      return LibraryPlaylist(
        id: m['id'] as String,
        name: m['name'] as String? ?? '',
        description: m['description'] as String? ?? '',
        createdAt: _parseDateTime(m['created_at']),
        updatedAt: _parseDateTime(m['updated_at']),
        songs: songsList.map((s) {
          final sm = Map<String, dynamic>.from(s as Map);
          _migrateFallbackDuration(sm);
          return Song.fromJson(sm);
        }).toList(),
        sortOrder: PlaylistTrackSortOrderX.fromString(m['sort_order'] as String?),
        shuffleEnabled: m['shuffleEnabled'] as bool? ?? false,
        isPinned: m['is_pinned'] as bool? ?? false,
        customImageUrl: m['custom_image_url'] as String?,
        isImported: m['is_imported'] as bool? ?? false,
        browseId: m['browse_id'] as String?,
        cachedPaletteColor: m['cached_palette_color'] as int?,
      );
    }).toList();

    final folders = foldersRaw.map((f) {
      final m = Map<String, dynamic>.from(f as Map);
      final ids = m['playlistIds'] as List<dynamic>? ?? [];
      return LibraryFolder(
        id: m['id'] as String,
        name: m['name'] as String? ?? '',
        playlistIds: ids.map((e) => e.toString()).toList(),
        createdAt: _parseDateTime(m['created_at']),
        isPinned: m['is_pinned'] as bool? ?? false,
      );
    }).toList();

    final likedSongs = likedRaw.map((s) {
      final m = Map<String, dynamic>.from(s as Map);
      _migrateFallbackDuration(m);
      return Song.fromJson(m);
    }).toList();

    final shufflesRaw = raw['playlistShuffles'];
    final playlistShuffles = <String, bool>{};
    if (shufflesRaw is Map<String, dynamic>) {
      for (final e in shufflesRaw.entries) {
        playlistShuffles[e.key] = e.value == true;
      }
    }

    final followedArtistsRaw = raw['followedArtists'] as List<dynamic>? ?? [];
    final followedAlbumsRaw = raw['followedAlbums'] as List<dynamic>? ?? [];

    final followedArtists = followedArtistsRaw.map((a) {
      return LibraryArtist.fromJson(Map<String, dynamic>.from(a as Map));
    }).toList();

    final followedAlbums = followedAlbumsRaw.map((a) {
      return LibraryAlbum.fromJson(Map<String, dynamic>.from(a as Map));
    }).toList();

    return (
      playlists: playlists,
      folders: folders,
      likedSongs: likedSongs,
      sortOrder: raw['sortOrder'] as String? ?? 'recent',
      viewMode: raw['viewMode'] as String? ?? 'list',
      likedShuffleEnabled: raw['likedShuffleEnabled'] as bool? ?? false,
      downloadedShuffleEnabled: raw['downloadedShuffleEnabled'] as bool? ?? false,
      playlistShuffles: playlistShuffles,
      followedArtists: followedArtists,
      followedAlbums: followedAlbums,
    );
  }

  Map<String, dynamic> _libraryDataToRaw(LibraryData data) {
    return {
      'playlists': data.playlists.map((p) => {
        'id': p.id,
        'name': p.name,
        'description': p.description,
        'sort_order': p.sortOrder.value,
        // Remote-saved (imported) playlists always re-fetch — don't store songs
        'songs': p.isImported ? [] : p.songs.map((s) => s.toJson()).toList(),
        'created_at': p.createdAt.toUtc().toIso8601String(),
        'updated_at': p.updatedAt.toUtc().toIso8601String(),
        'custom_image_url': p.customImageUrl,
        'is_pinned': p.isPinned,
        'shuffleEnabled': p.shuffleEnabled,
        'is_imported': p.isImported,
        'browse_id': p.browseId,
        'cached_palette_color': p.cachedPaletteColor,
      }).toList(),
      'folders': data.folders.map((f) => {
        'id': f.id,
        'name': f.name,
        'created_at': f.createdAt.toUtc().toIso8601String(),
        'is_pinned': f.isPinned,
        'playlistIds': f.playlistIds,
      }).toList(),
      'likedSongs': data.likedSongs.map((s) => s.toJson()).toList(),
      'sortOrder': data.sortOrder,
      'viewMode': data.viewMode,
      'likedShuffleEnabled': data.likedShuffleEnabled,
      'downloadedShuffleEnabled': data.downloadedShuffleEnabled,
      'playlistShuffles': data.playlistShuffles,
      'followedArtists': data.followedArtists.map((a) => a.toJson()).toList(),
      'followedAlbums': data.followedAlbums.map((a) => a.toJson()).toList(),
    };
  }

  DateTime _parseDateTime(dynamic v) {
    if (v == null) return DateTime.now();
    if (v is String) return DateTime.tryParse(v) ?? DateTime.now();
    return DateTime.now();
  }

  /// Migrates songs that were stored with the old 3-minute fallback duration
  /// (180000ms) to Duration.zero so they display as "--:--" instead of "03:00".
  static void _migrateFallbackDuration(Map<String, dynamic> songMap) {
    const fallbackMs = 180000; // Duration(minutes: 3).inMilliseconds
    final durMs = songMap['durationMs'];
    if (durMs == fallbackMs) {
      songMap['durationMs'] = 0;
    }
  }
}

final databaseBridgeProvider = Provider<DatabaseBridge>((ref) => DatabaseBridge());

/// Signals that a Supabase → SQLite hydration pull is in progress after login.
///
/// While true, the app remains on the loading screen to prevent stale data
/// from appearing briefly before SQLite is populated.
final databaseHydrationInProgressProvider = StateProvider<bool>((ref) => false);

final databaseRepositoryProvider = Provider<DatabaseRepository>((ref) {
  return DatabaseRepository(
    ref.watch(databaseBridgeProvider),
    ref.read(syncManagerProvider),
  );
});

final syncManagerProvider = Provider<SyncManager>((ref) {
  return SyncManager(bridge: ref.read(databaseBridgeProvider));
});
