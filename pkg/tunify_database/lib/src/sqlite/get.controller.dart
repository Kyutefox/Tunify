import 'dart:convert';

import 'package:sqflite/sqflite.dart';

/// SQLite read operations. All get/load logic lives in this controller.
class SqliteGetController {
  SqliteGetController(this._getDb);

  final Future<Database> Function() _getDb;

  /// Loads full library from playlists, folders, folder_playlists and settings.
  Future<Map<String, dynamic>> loadLibraryData() async {
    final db = await _getDb();
    try {
      final playlistRows = await db.query('playlists',
          where: 'is_saved = 1', orderBy: 'updated_at DESC');
      final folderRows = await db.query('folders', orderBy: 'name');
      final junctionRows = await db.query('folder_playlists');

      final folderToPlaylists = <String, List<String>>{};
      for (final r in junctionRows) {
        final fid = r['folder_id'] as String;
        final pid = r['playlist_id'] as String;
        folderToPlaylists.putIfAbsent(fid, () => []).add(pid);
      }

      final playlists = playlistRows.map((r) {
        final songsJson = r['songs'] as String? ?? '[]';
        final songsList = jsonDecode(songsJson) as List<dynamic>?;
        return <String, dynamic>{
          'id': r['id'],
          'name': r['name'],
          'description': r['description'] ?? '',
          'sort_order': r['sort_order'],
          'songs': songsList ?? [],
          'created_at': r['created_at'],
          'updated_at': r['updated_at'],
          'custom_image_url': r['custom_image_url'],
          'is_imported': (r['is_imported'] as int? ?? 0) == 1,
          'browse_id': r['browse_id'],
          'cached_palette_color': r['cached_palette_color'],
          'remote_track_count': r['remote_track_count'] as int?,
        };
      }).toList();

      final pinnedPlaylistsStr =
          (await _getSetting(db, 'pinned_playlist_ids')) ?? '[]';
      final pinnedFoldersStr =
          (await _getSetting(db, 'pinned_folder_ids')) ?? '[]';
      final pinnedPlaylistIds =
          (jsonDecode(pinnedPlaylistsStr) as List<dynamic>?)
                  ?.cast<String>()
                  .toSet() ??
              <String>{};
      final pinnedFolderIds = (jsonDecode(pinnedFoldersStr) as List<dynamic>?)
              ?.cast<String>()
              .toSet() ??
          <String>{};
      final playlistShufflesRaw =
          (await _getSetting(db, 'playlist_shuffles')) ?? '{}';
      final playlistShuffles =
          (jsonDecode(playlistShufflesRaw) as Map<String, dynamic>?) ??
              <String, dynamic>{};

      for (final p in playlists) {
        p['is_pinned'] = pinnedPlaylistIds.contains(p['id']?.toString());
        p['shuffleEnabled'] = playlistShuffles[p['id']?.toString()] == true;
      }
      final folders = folderRows.map((r) {
        final id = r['id'] as String;
        return <String, dynamic>{
          'id': id,
          'name': r['name'],
          'created_at': r['created_at'],
          'is_pinned': pinnedFolderIds.contains(id),
          'playlistIds': folderToPlaylists[id] ?? [],
        };
      }).toList();

      final sortOrder = (await _getSetting(db, 'sort_order')) ?? 'recent';
      final viewMode = (await _getSetting(db, 'view_mode')) ?? 'list';
      final likedJson = (await _getSetting(db, 'liked_song_ids')) ?? '[]';
      final likedSongs = jsonDecode(likedJson) as List<dynamic>? ?? [];
      final likedShuffle = (await _getSetting(db, 'liked_shuffle')) == 'true';
      final downloadedShuffle =
          (await _getSetting(db, 'downloaded_shuffle')) == 'true';
      final followedArtistsJson =
          (await _getSetting(db, 'followed_artists')) ?? '[]';
      final followedAlbumsJson =
          (await _getSetting(db, 'followed_albums')) ?? '[]';
      final followedArtists =
          jsonDecode(followedArtistsJson) as List<dynamic>? ?? [];
      final followedAlbums =
          jsonDecode(followedAlbumsJson) as List<dynamic>? ?? [];

      return {
        'playlists': playlists,
        'folders': folders,
        'likedSongs': likedSongs,
        'sortOrder': sortOrder,
        'viewMode': viewMode,
        'likedShuffleEnabled': likedShuffle,
        'downloadedShuffleEnabled': downloadedShuffle,
        'playlistShuffles': playlistShuffles,
        'followedArtists': followedArtists,
        'followedAlbums': followedAlbums,
      };
    } catch (_) {
      return emptyLibraryData();
    }
  }

  /// Returns an empty library map (default structure when load fails).
  static Map<String, dynamic> emptyLibraryData() => {
        'playlists': <Map>[],
        'folders': <Map>[],
        'likedSongs': <Map>[],
        'sortOrder': 'recent',
        'viewMode': 'list',
        'likedShuffleEnabled': false,
        'downloadedShuffleEnabled': false,
        'playlistShuffles': <String, dynamic>{},
        'followedArtists': <Map>[],
        'followedAlbums': <Map>[],
      };

  /// Loads recently played from settings (recently_played key).
  Future<List<Map<String, dynamic>>> loadRecentlyPlayed() async {
    try {
      final db = await _getDb();
      final json = await _getSetting(db, 'recently_played');
      if (json == null || json.isEmpty) return [];
      final list = jsonDecode(json) as List<dynamic>?;
      if (list == null) return [];
      return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } catch (_) {
      return [];
    }
  }

  /// Reads a single setting value by [key].
  Future<String?> getSetting(String key) async {
    try {
      final db = await _getDb();
      return await _getSetting(db, key);
    } catch (_) {
      return null;
    }
  }

  Future<String?> _getSetting(Database db, String key) async {
    final rows = await db.query('settings', where: 'key = ?', whereArgs: [key]);
    return rows.firstOrNull?['value'] as String?;
  }

  /// Loads recent search queries from settings (recent_searches key).
  Future<List<String>> loadRecentSearches() async {
    final raw = await getSetting('recent_searches');
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>?;
      return list
              ?.map((e) => e.toString())
              .where((s) => s.trim().isNotEmpty)
              .toList() ??
          [];
    } catch (_) {
      return [];
    }
  }

  /// Loads downloaded song IDs from settings (downloaded_song_ids key).
  Future<List<String>> loadDownloadedSongIds() async {
    final raw = await getSetting('downloaded_song_ids');
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>?;
      return list
              ?.map((e) => e.toString())
              .where((s) => s.isNotEmpty)
              .toList() ??
          [];
    } catch (_) {
      return [];
    }
  }

  /// Loads YT keys (yt_visitor_data, yt_api_key, yt_client_version) from settings.
  Future<Map<String, dynamic>> loadYtPersonalization() async {
    return {
      'visitor_data': await getSetting('yt_visitor_data') ?? '',
      'api_key': await getSetting('yt_api_key'),
      'client_version': await getSetting('yt_client_version'),
    };
  }

  /// Returns the cached_palette_color for any playlist row with [browseId].
  Future<int?> getPlaylistPaletteColor(String browseId) async {
    try {
      final db = await _getDb();
      final rows = await db.query(
        'playlists',
        columns: ['cached_palette_color'],
        where: 'browse_id = ?',
        whereArgs: [browseId],
        limit: 1,
      );
      if (rows.isEmpty) return null;
      return rows.first['cached_palette_color'] as int?;
    } catch (_) {
      return null;
    }
  }

  static const Duration _collectionTrackTtl = Duration(minutes: 30);

  /// Returns cached collection tracks for [browseId], or null if missing/expired.
  Future<List<Map<String, dynamic>>?> getCollectionTracks(
      String browseId) async {
    try {
      final db = await _getDb();
      final rows = await db.query(
        'collection_tracks',
        where: 'browse_id = ? AND is_saved = 0',
        whereArgs: [browseId],
        orderBy: 'track_index ASC',
      );
      if (rows.isEmpty) return null;
      final now = DateTime.now().toUtc();
      final allExpired = rows.every((r) {
        final cachedAt = DateTime.tryParse(r['cached_at'] as String? ?? '');
        if (cachedAt == null) return true;
        return now.difference(cachedAt) > _collectionTrackTtl;
      });
      if (allExpired) {
        await db.delete('collection_tracks',
            where: 'browse_id = ? AND is_saved = 0', whereArgs: [browseId]);
        return null;
      }
      return rows.map((r) {
        final trackDataJson = r['track_data'] as String? ?? '{}';
        return Map<String, dynamic>.from(jsonDecode(trackDataJson) as Map);
      }).toList();
    } catch (_) {
      return null;
    }
  }

  /// Returns cached stream URL for [videoId], or null if missing or expired.
  /// Deletes the expired row inline before returning null.
  Future<Map<String, dynamic>?> getStreamUrlCache(String videoId) async {
    try {
      final db = await _getDb();
      final rows = await db.query('stream_url_cache',
          where: 'video_id = ?', whereArgs: [videoId]);
      if (rows.isEmpty) return null;
      final row = rows.first;
      final expiresAt = DateTime.parse(row['expires_at'] as String);
      if (DateTime.now().toUtc().isAfter(expiresAt)) {
        await db.delete('stream_url_cache',
            where: 'video_id = ?', whereArgs: [videoId]);
        return null;
      }
      final headersJson = row['headers'] as String? ?? '{}';
      final headersMap = (jsonDecode(headersJson) as Map<String, dynamic>?)
              ?.map((k, v) => MapEntry(k, v.toString())) ??
          {};
      return {
        'url': row['url'] as String,
        'headers': headersMap,
        'bitrate': row['bitrate'] as int? ?? 0,
        'quality': row['quality'] as String? ?? '',
      };
    } catch (_) {
      return null;
    }
  }
}
