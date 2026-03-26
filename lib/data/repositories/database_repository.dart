import 'package:flutter_riverpod/flutter_riverpod.dart';

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
  String sortOrder,
  String viewMode,
  bool downloadedShuffleEnabled,
  String downloadsSortOrder,
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

  Future<void> saveAll({required LibraryData data, String? userId}) async {
    await _bridge.saveLibraryData(_libraryDataToRaw(data));
    _syncManager.requestSync();
  }

  Future<List<RecentlyPlayedSong>> loadRecentlyPlayed({String? userId}) async {
    final list = await _bridge.loadRecentlyPlayed();
    return list
        .map((m) => RecentlyPlayedSong(
              id: m['id'] as String? ?? '',
              title: m['title'] as String? ?? '',
              artist: m['artist'] as String? ?? '',
              thumbnailUrl: m['thumbnailUrl'] as String? ?? '',
              durationSeconds: m['durationSeconds'] as int? ??
                  (m['durationMs'] != null
                      ? (m['durationMs'] as int) ~/ 1000
                      : 0),
              lastPlayed: m['lastPlayed'] != null
                  ? DateTime.parse(m['lastPlayed'] as String)
                  : DateTime.now(),
            ))
        .toList();
  }

  Future<void> saveRecentlyPlayed(List<RecentlyPlayedSong> songs,
      {String? userId}) async {
    await _bridge.saveRecentlyPlayed(songs.map((s) => s.toJson()).toList());
    _syncManager.requestSync();
  }

  Future<String?> getSetting(String key) async => _bridge.getSetting(key);

  Future<void> setSetting(String key, String value) async {
    await _bridge.setSetting(key, value);
    _syncManager.requestSync();
  }

  Future<Map<String, dynamic>> loadPlaybackSettings() async =>
      _bridge.loadPlaybackSettings();

  Future<void> savePlaybackSetting(String key, dynamic value) async {
    await _bridge.savePlaybackSetting(key, value.toString());
    _syncManager.requestSync();
  }

  Future<List<String>> loadRecentSearches() async =>
      _bridge.loadRecentSearches();

  Future<void> saveRecentSearches(List<String> queries) async {
    await _bridge.saveRecentSearches(queries);
    _syncManager.requestSync();
  }

  Future<List<String>> loadDownloadedSongIds() async =>
      _bridge.loadDownloadedSongIds();

  Future<void> saveDownloadedSongIds(List<String> ids) async {
    await _bridge.saveDownloadedSongIds(ids);
    _syncManager.requestSync();
  }

  Future<Map<String, dynamic>> loadYtPersonalization() async =>
      _bridge.loadYtPersonalization();

  Future<void> saveYtPersonalization(Map<String, dynamic> data) async {
    await _bridge.saveYtPersonalization(data);
    _syncManager.requestSync();
  }

  Future<void> close() async => _bridge.close();

  Future<void> clearAllLocalData() async {
    await _bridge.saveLibraryData({
      'playlists': [],
      'folders': [],
      'sortOrder': 'dateAdded',
      'viewMode': 'grid',
      'downloadedShuffleEnabled': false,
      'downloadsSortOrder': 'dateAdded',
      'followedArtists': [],
      'followedAlbums': [],
    });
    await _bridge.saveRecentlyPlayed([]);
    await _bridge.saveRecentSearches([]);
    await _bridge.saveDownloadedSongIds([]);
    await _bridge.saveYtPersonalization({});
  }

  // ── Serialization ──────────────────────────────────────────────────────────

  LibraryData _rawToLibraryData(Map<String, dynamic> raw) {
    final playlistsRaw = raw['playlists'] as List<dynamic>? ?? [];
    final foldersRaw = raw['folders'] as List<dynamic>? ?? [];

    // One-time migration: liked songs were stored as a flat list under
    // 'likedSongs'. Inject them as the reserved 'liked' playlist if it isn't
    // already present, OR if it exists but is empty while the legacy array has data
    // (handles the case where a bad save wrote an empty 'liked' entry before migration ran).
    final likedRaw = raw['likedSongs'] as List<dynamic>? ?? [];
    final existingLiked =
        playlistsRaw.cast<Map>().where((p) => p['id'] == 'liked').firstOrNull;
    final likedSongsInPlaylist =
        (existingLiked?['songs'] as List<dynamic>? ?? []);
    final needsMigration = existingLiked == null ||
        (likedSongsInPlaylist.isEmpty && likedRaw.isNotEmpty);

    LibraryPlaylist? migratedLiked;
    if (needsMigration && likedRaw.isNotEmpty) {
      final likedShuffleEnabled = raw['likedShuffleEnabled'] as bool? ?? false;
      final songs = likedRaw.map((s) {
        final m = Map<String, dynamic>.from(s as Map);
        _migrateFallbackDuration(m);
        return Song.fromJson(m);
      }).toList();
      migratedLiked = LibraryPlaylist(
        id: 'liked',
        name: 'Liked Songs',
        createdAt: DateTime(2000),
        updatedAt: DateTime.now(),
        songs: songs,
        shuffleEnabled: likedShuffleEnabled,
      );
    }

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
        sortOrder:
            PlaylistTrackSortOrderX.fromString(m['sort_order'] as String?),
        shuffleEnabled: m['shuffleEnabled'] as bool? ?? false,
        isPinned: m['is_pinned'] as bool? ?? false,
        customImageUrl: m['custom_image_url'] as String?,
        isImported: m['is_imported'] as bool? ?? false,
        browseId: m['browse_id'] as String?,
        cachedPaletteColor: m['cached_palette_color'] as int?,
        remoteTrackCount: m['remote_track_count'] as int?,
      );
    }).toList();

    // When migrating, filter out any existing empty 'liked' entry before prepending the migrated one.
    final playlistsWithoutLiked = migratedLiked != null
        ? playlists.where((p) => p.id != 'liked').toList()
        : playlists;

    final allPlaylists = migratedLiked != null
        ? [migratedLiked, ...playlistsWithoutLiked]
        : playlists;

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

    final followedArtists = (raw['followedArtists'] as List<dynamic>? ?? [])
        .map((a) => LibraryArtist.fromJson(Map<String, dynamic>.from(a as Map)))
        .toList();

    final followedAlbums = (raw['followedAlbums'] as List<dynamic>? ?? [])
        .map((a) => LibraryAlbum.fromJson(Map<String, dynamic>.from(a as Map)))
        .toList();

    return (
      playlists: allPlaylists,
      folders: folders,
      sortOrder: raw['sortOrder'] as String? ?? 'recent',
      viewMode: raw['viewMode'] as String? ?? 'list',
      downloadedShuffleEnabled:
          raw['downloadedShuffleEnabled'] as bool? ?? false,
      downloadsSortOrder: raw['downloadsSortOrder'] as String? ?? 'customOrder',
      followedArtists: followedArtists,
      followedAlbums: followedAlbums,
    );
  }

  Map<String, dynamic> _libraryDataToRaw(LibraryData data) {
    return {
      'playlists': data.playlists
          .map((p) => {
                'id': p.id,
                'name': p.name,
                'description': p.description,
                'sort_order': p.sortOrder.value,
                // Imported playlists always re-fetch tracks — don't persist songs.
                // The 'liked' playlist is never imported, so its songs are always saved.
                'songs':
                    p.isImported ? [] : p.songs.map((s) => s.toJson()).toList(),
                'created_at': p.createdAt.toUtc().toIso8601String(),
                'updated_at': p.updatedAt.toUtc().toIso8601String(),
                'custom_image_url': p.customImageUrl,
                'is_pinned': p.isPinned,
                'shuffleEnabled': p.shuffleEnabled,
                'is_imported': p.isImported,
                'browse_id': p.browseId,
                'cached_palette_color': p.cachedPaletteColor,
                'remote_track_count': p.remoteTrackCount,
              })
          .toList(),
      'folders': data.folders
          .map((f) => {
                'id': f.id,
                'name': f.name,
                'created_at': f.createdAt.toUtc().toIso8601String(),
                'is_pinned': f.isPinned,
                'playlistIds': f.playlistIds,
              })
          .toList(),
      'sortOrder': data.sortOrder,
      'viewMode': data.viewMode,
      'downloadedShuffleEnabled': data.downloadedShuffleEnabled,
      'downloadsSortOrder': data.downloadsSortOrder,
      'followedArtists': data.followedArtists.map((a) => a.toJson()).toList(),
      'followedAlbums': data.followedAlbums.map((a) => a.toJson()).toList(),
    };
  }

  DateTime _parseDateTime(dynamic v) {
    if (v == null) return DateTime.now();
    if (v is String) return DateTime.tryParse(v) ?? DateTime.now();
    return DateTime.now();
  }

  /// Migrates songs stored with the old 3-minute fallback duration (180000ms)
  /// to Duration.zero so they display as "--:--" instead of "03:00".
  static void _migrateFallbackDuration(Map<String, dynamic> songMap) {
    const fallbackMs = 180000;
    if (songMap['durationMs'] == fallbackMs) songMap['durationMs'] = 0;
  }
}

final databaseBridgeProvider =
    Provider<DatabaseBridge>((ref) => DatabaseBridge());

class _HydrationProgressNotifier extends Notifier<bool> {
  @override
  bool build() => false;
  void set(bool value) => state = value;
}

/// True while a Supabase → SQLite hydration pull is in progress after login.
final databaseHydrationInProgressProvider =
    NotifierProvider<_HydrationProgressNotifier, bool>(_HydrationProgressNotifier.new);

final databaseRepositoryProvider = Provider<DatabaseRepository>((ref) {
  return DatabaseRepository(
    ref.watch(databaseBridgeProvider),
    ref.read(syncManagerProvider),
  );
});

final syncManagerProvider = Provider<SyncManager>((ref) {
  return SyncManager(bridge: ref.read(databaseBridgeProvider));
});
