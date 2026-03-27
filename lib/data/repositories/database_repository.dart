import 'dart:convert';

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
  ShuffleMode downloadedShuffleMode,
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

  // ── Playlist surgical ops ─────────────────────────────────────────────────

  /// Inserts a new empty playlist row. No songs written.
  Future<void> createPlaylist(LibraryPlaylist p) async {
    await _bridge.createPlaylist(_playlistToRaw(p));
    _syncManager.requestSync();
  }

  /// Deletes a playlist. Cascade removes its songs and folder memberships.
  Future<void> deletePlaylist(String id) async {
    await _bridge.deletePlaylist(id);
    _syncManager.requestSync();
  }

  /// Updates specific metadata columns on one playlist.
  ///
  /// Only the non-null parameters are written. Pass [touchUpdatedAt] = false
  /// for background cache writes (palette color) that should not affect
  /// library sort order.
  Future<void> updatePlaylistMeta(
    String id, {
    String? name,
    String? description,
    PlaylistTrackSortOrder? sortOrder,
    ShuffleMode? shuffleMode,
    bool? isPinned,
    String? coverUrl,
    int? paletteColor,
    int? remoteTrackCount,
    bool touchUpdatedAt = true,
  }) async {
    final fields = <String, dynamic>{};
    if (name != null) fields['name'] = name;
    if (description != null) fields['description'] = description;
    if (sortOrder != null) fields['sort_order'] = sortOrder.value;
    if (shuffleMode != null) fields['shuffle_enabled'] = shuffleMode.index;
    if (isPinned != null) fields['is_pinned'] = isPinned ? 1 : 0;
    if (coverUrl != null) fields['cover_url'] = coverUrl;
    if (paletteColor != null) fields['palette_color'] = paletteColor;
    if (remoteTrackCount != null) fields['total_track_count_remote'] = remoteTrackCount;
    if (touchUpdatedAt) fields['updated_at'] = DateTime.now().toUtc().toIso8601String();
    if (fields.isEmpty) return;
    await _bridge.updatePlaylistMeta(id, fields);
    _syncManager.requestSync();
  }

  /// Replaces all songs for [playlistId]. Only that playlist's songs are written.
  Future<void> replacePlaylistSongs(String playlistId, List<Song> songs) async {
    final songMaps = songs.map((s) => s.toJson()).toList();
    final updatedAt = DateTime.now().toUtc().toIso8601String();
    await _bridge.replacePlaylistSongs(playlistId, songMaps, updatedAt);
    _syncManager.requestSync();
  }

  // ── Folder surgical ops ───────────────────────────────────────────────────

  Future<void> createFolder(LibraryFolder f) async {
    await _bridge.createFolder({
      'id': f.id,
      'name': f.name,
      'created_at': f.createdAt.toUtc().toIso8601String(),
    });
    _syncManager.requestSync();
  }

  Future<void> deleteFolder(String id) async {
    await _bridge.deleteFolder(id);
    _syncManager.requestSync();
  }

  Future<void> renameFolder(String id, String name) async {
    await _bridge.renameFolder(id, name);
    _syncManager.requestSync();
  }

  Future<void> addPlaylistToFolder(String folderId, String playlistId) async {
    await _bridge.addPlaylistToFolder(folderId, playlistId);
    _syncManager.requestSync();
  }

  Future<void> removePlaylistFromFolder(
      String folderId, String playlistId) async {
    await _bridge.removePlaylistFromFolder(folderId, playlistId);
    _syncManager.requestSync();
  }

  /// Saves the pinned folder IDs list to settings.
  Future<void> savePinnedFolderIds(List<String> ids) async {
    await _bridge.setSetting('pinned_folder_ids', jsonEncode(ids));
    _syncManager.requestSync();
  }

  // ── Followed artists / albums ─────────────────────────────────────────────

  Future<void> followArtist(LibraryArtist artist) async {
    await _bridge.insertArtist(artist.toJson());
    _syncManager.requestSync();
  }

  Future<void> unfollowArtist(String id) async {
    await _bridge.deleteArtistOrAlbum(id);
    _syncManager.requestSync();
  }

  Future<void> followAlbum(LibraryAlbum album) async {
    await _bridge.insertAlbum(album.toJson());
    _syncManager.requestSync();
  }

  Future<void> unfollowAlbum(String id) async {
    await _bridge.deleteArtistOrAlbum(id);
    _syncManager.requestSync();
  }

  Future<void> clearAllLocalData() async {
    await _bridge.saveLibraryData({
      'playlists': [],
      'folders': [],
      'sortOrder': 'dateAdded',
      'viewMode': 'grid',
      'downloadedShuffleMode': 0,
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

    final allPlaylists = playlistsRaw.map((p) {
      final m = Map<String, dynamic>.from(p as Map);
      final songsList = m['songs'] as List<dynamic>? ?? [];
      return LibraryPlaylist(
        id: m['id'] as String,
        name: m['name'] as String? ?? '',
        description: m['description'] as String? ?? '',
        createdAt: _parseDateTime(m['created_at']),
        updatedAt: _parseDateTime(m['updated_at']),
        songs: songsList
            .map((s) => Song.fromJson(Map<String, dynamic>.from(s as Map)))
            .toList(),
        sortOrder:
            PlaylistTrackSortOrderX.fromString(m['sort_order'] as String?),
        shuffleMode: ShuffleModeX.fromInt(m['shuffle_enabled']),
        isPinned: m['is_pinned'] as bool? ?? false,
        customImageUrl: m['cover_url'] as String?,
        isImported: m['is_imported'] as bool? ?? false,
        browseId: m['browse_id'] as String?,
        cachedPaletteColor: m['palette_color'] as int?,
        remoteTrackCount: m['total_track_count_remote'] as int?,
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
      downloadedShuffleMode:
          ShuffleModeX.fromInt(raw['downloadedShuffleMode'] as int?),
      downloadsSortOrder: raw['downloadsSortOrder'] as String? ?? 'customOrder',
      followedArtists: followedArtists,
      followedAlbums: followedAlbums,
    );
  }

  Map<String, dynamic> _playlistToRaw(LibraryPlaylist p) => {
        'id': p.id,
        'name': p.name,
        'description': p.description,
        'sort_order': p.sortOrder.value,
        // Imported playlists always re-fetch tracks — don't persist songs.
        'songs': p.isImported ? [] : p.songs.map((s) => s.toJson()).toList(),
        'created_at': p.createdAt.toUtc().toIso8601String(),
        'updated_at': p.updatedAt.toUtc().toIso8601String(),
        'cover_url': p.customImageUrl,
        'is_pinned': p.isPinned,
        'shuffle_enabled': p.shuffleMode.index,
        'is_imported': p.isImported,
        'browse_id': p.browseId,
        'palette_color': p.cachedPaletteColor,
        'total_track_count_remote': p.remoteTrackCount,
      };

  Map<String, dynamic> _libraryDataToRaw(LibraryData data) {
    return {
      'playlists': data.playlists.map(_playlistToRaw).toList(),
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
      'downloadedShuffleMode': data.downloadedShuffleMode.index,
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
