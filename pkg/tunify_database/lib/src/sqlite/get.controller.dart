import 'dart:convert';

import 'package:sqflite/sqflite.dart';

/// SQLite read operations. All get/load logic lives in this controller.
class SqliteGetController {
  SqliteGetController(this._getDb);

  final Future<Database> Function() _getDb;

  /// Loads full library from playlist_info, playlist_songs, folders,
  /// folder_playlists and settings.
  Future<Map<String, dynamic>> loadLibraryData() async {
    final db = await _getDb();
    try {
      // Regular playlists only (not artist/album rows).
      final playlistRows = await db.query('playlist_info',
          where: 'is_saved = 1 AND is_artist = 0 AND is_album = 0',
          orderBy: 'updated_at DESC');
      final artistRows = await db.query('playlist_info',
          where: 'is_saved = 1 AND is_artist = 1',
          orderBy: 'created_at DESC');
      final albumRows = await db.query('playlist_info',
          where: 'is_saved = 1 AND is_album = 1',
          orderBy: 'created_at DESC');
      final songRows = await db.query('playlist_songs',
          orderBy: 'playlist_id, sort_order_sequence ASC');
      final folderRows = await db.query('folders', orderBy: 'name');
      final junctionRows = await db.query('folder_playlists');

      // Group songs by playlist_id, mapping DB columns → Song.fromJson keys.
      final songsByPlaylist = <String, List<Map<String, dynamic>>>{};
      for (final r in songRows) {
        final pid = r['playlist_id'] as String;
        songsByPlaylist.putIfAbsent(pid, () => []).add({
          'id': r['song_id'],
          'title': r['title'],
          'artist': r['artist'],
          'thumbnailUrl': r['cover_url'],
          'durationMs': r['duration_ms'],
          'isExplicit': (r['is_explicit'] as int? ?? 0) == 1,
          'artistBrowseId': r['artist_browse_id'],
          'albumBrowseId': r['album_browse_id'],
          'albumName': r['album_name'],
        });
      }

      final folderToPlaylists = <String, List<String>>{};
      for (final r in junctionRows) {
        final fid = r['folder_id'] as String;
        final pid = r['playlist_id'] as String;
        folderToPlaylists.putIfAbsent(fid, () => []).add(pid);
      }

      final playlists = playlistRows.map((r) {
        final id = r['id'] as String;
        return <String, dynamic>{
          'id': id,
          'name': r['name'],
          'description': r['description'] ?? '',
          'sort_order': r['sort_order'],
          'songs': songsByPlaylist[id] ?? [],
          'created_at': r['created_at'],
          'updated_at': r['updated_at'],
          'cover_url': r['cover_url'],
          'is_imported': (r['is_imported'] as int? ?? 0) == 1,
          'browse_id': r['browse_id'],
          'palette_color': r['palette_color'],
          'total_track_count_remote': r['total_track_count_remote'] as int?,
          'shuffle_enabled': r['shuffle_enabled'] as int? ?? 0,
          'is_pinned': (r['is_pinned'] as int? ?? 0) == 1,
          if (r['header_subtitle'] != null)
            'header_subtitle': r['header_subtitle'],
          if (r['header_second_subtitle'] != null)
            'header_second_subtitle': r['header_second_subtitle'],
        };
      }).toList();

      final folders = folderRows.map((r) {
        final id = r['id'] as String;
        return <String, dynamic>{
          'id': id,
          'name': r['name'],
          'created_at': r['created_at'],
          'is_pinned': (r['is_pinned'] as int? ?? 0) == 1,
          'playlistIds': folderToPlaylists[id] ?? [],
        };
      }).toList();

      final sortOrder = (await _getSetting(db, 'sort_order')) ?? 'recent';
      final viewMode = (await _getSetting(db, 'view_mode')) ?? 'list';
      final downloadedShuffleStr = await _getSetting(db, 'downloaded_shuffle');
      final downloadedShuffleMode = downloadedShuffleStr == 'true' ? 1
          : (downloadedShuffleStr == null || downloadedShuffleStr == 'false') ? 0
          : int.tryParse(downloadedShuffleStr) ?? 0;
      final downloadsSortOrder =
          (await _getSetting(db, 'downloads_sort_order')) ?? 'customOrder';

      // Map artist rows → LibraryArtist.fromJson compatible maps.
      final followedArtists = artistRows.map((r) => <String, dynamic>{
            'id': r['id'],
            'name': r['name'],
            'thumbnailUrl': r['cover_url'] ?? '',
            'browseId': r['browse_id'],
            'followedAt': r['created_at'],
            if (r['palette_color'] != null) 'cachedPaletteColor': r['palette_color'],
            'isPinned': (r['is_pinned'] as int? ?? 0) == 1,
          }).toList();

      // Map album rows → LibraryAlbum.fromJson compatible maps.
      final followedAlbums = albumRows.map((r) => <String, dynamic>{
            'id': r['id'],
            'title': r['name'],
            'artistName': r['description'] ?? '',
            'thumbnailUrl': r['cover_url'] ?? '',
            'browseId': r['browse_id'],
            'followedAt': r['created_at'],
            if (r['palette_color'] != null) 'cachedPaletteColor': r['palette_color'],
            'isPinned': (r['is_pinned'] as int? ?? 0) == 1,
          }).toList();

      return {
        'playlists': playlists,
        'folders': folders,
        'sortOrder': sortOrder,
        'viewMode': viewMode,
        'downloadedShuffleMode': downloadedShuffleMode,
        'downloadsSortOrder': downloadsSortOrder,
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
        'sortOrder': 'recent',
        'viewMode': 'list',
        'downloadedShuffleMode': 0,
        'downloadsSortOrder': 'customOrder',
        'followedArtists': <Map>[],
        'followedAlbums': <Map>[],
      };

  /// Loads recently played from the recently_played table.
  Future<List<Map<String, dynamic>>> loadRecentlyPlayed() async {
    try {
      final db = await _getDb();
      final rows = await db.query('recently_played', orderBy: 'last_played_at DESC');
      return rows.map((r) => <String, dynamic>{
        'id': r['song_id'],
        'title': r['title'],
        'artist': r['artist'],
        'thumbnailUrl': r['thumbnail_url'],
        'durationSeconds': r['duration_seconds'],
        'lastPlayed': r['last_played_at'],
      }).toList();
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

  /// Loads recent search queries from the recent_searches table.
  Future<List<String>> loadRecentSearches() async {
    try {
      final db = await _getDb();
      final rows = await db.query('recent_searches', orderBy: 'created_at DESC');
      return rows.map((r) => r['query'] as String).toList();
    } catch (_) {
      return [];
    }
  }

  /// Loads downloaded song IDs from the downloaded_song_ids table.
  Future<List<String>> loadDownloadedSongIds() async {
    try {
      final db = await _getDb();
      final rows = await db.query('downloaded_song_ids');
      return rows.map((r) => r['song_id'] as String).toList();
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

  /// Returns the palette_color for any playlist_info row with [browseId].
  Future<int?> getPlaylistPaletteColor(String browseId) async {
    try {
      final db = await _getDb();
      final rows = await db.query(
        'playlist_info',
        columns: ['palette_color'],
        where: 'browse_id = ?',
        whereArgs: [browseId],
        limit: 1,
      );
      if (rows.isEmpty) return null;
      return rows.first['palette_color'] as int?;
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
