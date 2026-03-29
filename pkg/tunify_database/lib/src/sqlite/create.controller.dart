import 'dart:convert';

import 'package:sqflite/sqflite.dart';

/// SQLite insert operations. All create/insert logic lives in this controller.
class SqliteCreateController {
  SqliteCreateController();

  /// Seeds default settings rows on first database creation (onCreate).
  Future<void> runOnCreate(Database db) async {
    await db.insert('settings', {'key': 'sort_order', 'value': 'recent'});
    await db.insert('settings', {'key': 'view_mode', 'value': 'list'});
    await db.insert('settings', {'key': 'downloads_sort_order', 'value': 'customOrder'});
  }

  /// Upserts playlists into playlist_info and replaces their songs in playlist_songs.
  ///
  /// Each playlist map must use these keys:
  ///   id, name, description, sort_order, cover_url, is_imported, browse_id,
  ///   palette_color, total_track_count_remote, shuffle_enabled, is_pinned,
  ///   created_at, updated_at, songs (list of Song.toJson() maps).
  Future<void> upsertPlaylists(Transaction txn, List<dynamic> playlists) async {
    for (final p in playlists) {
      final map = p as Map<String, dynamic>;
      final id = map['id'] as String;

      await txn.insert(
        'playlist_info',
        {
          'id': id,
          'name': map['name'],
          'description': map['description'] ?? '',
          'sort_order': map['sort_order'] ?? 'customOrder',
          'cover_url': map['cover_url'],
          'is_imported': (map['is_imported'] == true) ? 1 : 0,
          'browse_id': map['browse_id'],
          'palette_color': map['palette_color'],
          'is_saved': 1,
          'total_track_count_remote': map['total_track_count_remote'],
          'shuffle_enabled': map['shuffle_enabled'] is int ? map['shuffle_enabled'] as int : ((map['shuffle_enabled'] == true) ? 1 : 0),
          'is_pinned': (map['is_pinned'] == true) ? 1 : 0,
          'is_artist': (map['is_artist'] == true) ? 1 : 0,
          'is_album': (map['is_album'] == true) ? 1 : 0,
          'created_at': map['created_at'],
          'updated_at': map['updated_at'],
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      // Replace all songs for this playlist (cascade handles nothing here — we
      // delete directly so imported playlists with songs=[] clear old rows).
      await txn.delete('playlist_songs', where: 'playlist_id = ?', whereArgs: [id]);

      final songs = map['songs'] as List<dynamic>? ?? [];
      for (var i = 0; i < songs.length; i++) {
        final s = songs[i] as Map<String, dynamic>;
        await txn.insert(
          'playlist_songs',
          {
            'playlist_id': id,
            'song_id': s['id'],
            'title': s['title'] ?? '',
            'artist': s['artist'] ?? '',
            'cover_url': s['thumbnailUrl'] ?? '',
            'duration_ms': s['durationMs'] ?? 0,
            'is_explicit': (s['isExplicit'] == true) ? 1 : 0,
            'artist_browse_id': s['artistBrowseId'],
            'album_browse_id': s['albumBrowseId'],
            'album_name': s['albumName'],
            'sort_order_sequence': i,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    }
  }

  /// Inserts or replaces folders in the folders table within [txn].
  Future<void> insertFolders(Transaction txn, List<dynamic> folders) async {
    for (final f in folders) {
      final map = f as Map<String, dynamic>;
      await txn.insert(
        'folders',
        {
          'id': map['id'],
          'name': map['name'],
          'is_pinned': (map['is_pinned'] == true) ? 1 : 0,
          'created_at': map['created_at'],
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  /// Inserts folder–playlist junction rows for each folder in [folders] within [txn].
  Future<void> insertFolderPlaylists(
      Transaction txn, List<dynamic> folders) async {
    for (final f in folders) {
      final map = f as Map<String, dynamic>;
      final folderId = map['id'] as String;
      for (final pid in map['playlistIds'] as List<dynamic>? ?? []) {
        await txn.insert('folder_playlists',
            {'folder_id': folderId, 'playlist_id': pid.toString()});
      }
    }
  }

  /// Inserts a single playlist_info row. Songs are not written.
  /// Uses INSERT OR IGNORE so an existing row is never clobbered.
  Future<void> insertPlaylist(Database db, Map<String, dynamic> map) async {
    await db.insert(
      'playlist_info',
      {
        'id': map['id'],
        'name': map['name'],
        'description': map['description'] ?? '',
        'sort_order': map['sort_order'] ?? 'customOrder',
        'cover_url': map['cover_url'],
        'is_imported': (map['is_imported'] == true) ? 1 : 0,
        'browse_id': map['browse_id'],
        'palette_color': map['palette_color'],
        'is_saved': 1,
        'total_track_count_remote': map['total_track_count_remote'],
        'shuffle_enabled': (map['shuffle_enabled'] == true) ? 1 : 0,
        'is_pinned': (map['is_pinned'] == true) ? 1 : 0,
        'is_artist': 0,
        'is_album': 0,
        'created_at': map['created_at'],
        'updated_at': map['updated_at'],
      },
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  /// Inserts a followed artist as a playlist_info row (INSERT OR IGNORE).
  Future<void> insertArtist(Database db, Map<String, dynamic> map) async {
    final now = map['followedAt'] as String? ?? DateTime.now().toUtc().toIso8601String();
    await db.insert(
      'playlist_info',
      {
        'id': map['id'],
        'name': map['name'] ?? '',
        'description': '',
        'sort_order': 'customOrder',
        'cover_url': map['thumbnailUrl'],
        'is_imported': 0,
        'browse_id': map['browseId'],
        'palette_color': map['cachedPaletteColor'],
        'is_saved': 1,
        'total_track_count_remote': null,
        'shuffle_enabled': 0,
        'is_pinned': 0,
        'is_artist': 1,
        'is_album': 0,
        'created_at': now,
        'updated_at': now,
      },
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  /// Inserts a followed album as a playlist_info row (INSERT OR IGNORE).
  Future<void> insertAlbum(Database db, Map<String, dynamic> map) async {
    final now = map['followedAt'] as String? ?? DateTime.now().toUtc().toIso8601String();
    await db.insert(
      'playlist_info',
      {
        'id': map['id'],
        'name': map['title'] ?? '',
        'description': map['artistName'] ?? '',
        'sort_order': 'customOrder',
        'cover_url': map['thumbnailUrl'],
        'is_imported': 0,
        'browse_id': map['browseId'],
        'palette_color': map['cachedPaletteColor'],
        'is_saved': 1,
        'total_track_count_remote': null,
        'shuffle_enabled': 0,
        'is_pinned': 0,
        'is_artist': 0,
        'is_album': 1,
        'created_at': now,
        'updated_at': now,
      },
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  /// Replaces all playlist_songs rows for [playlistId] within [txn].
  ///
  /// Deletes existing rows first, then inserts the new list with
  /// contiguous sort_order_sequence values. Does NOT touch playlist_info.
  Future<void> replaceSongsInTransaction(
      Transaction txn, String playlistId, List<Map<String, dynamic>> songs) async {
    await txn.delete('playlist_songs',
        where: 'playlist_id = ?', whereArgs: [playlistId]);
    for (var i = 0; i < songs.length; i++) {
      final s = songs[i];
      await txn.insert(
        'playlist_songs',
        {
          'playlist_id': playlistId,
          'song_id': s['id'],
          'title': s['title'] ?? '',
          'artist': s['artist'] ?? '',
          'cover_url': s['thumbnailUrl'] ?? '',
          'duration_ms': s['durationMs'] ?? 0,
          'is_explicit': (s['isExplicit'] == true) ? 1 : 0,
          'artist_browse_id': s['artistBrowseId'],
          'album_browse_id': s['albumBrowseId'],
          'album_name': s['albumName'],
          'sort_order_sequence': i,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  /// Inserts a single folder row (INSERT OR IGNORE).
  Future<void> insertSingleFolder(Database db, Map<String, dynamic> map) async {
    await db.insert(
      'folders',
      {
        'id': map['id'],
        'name': map['name'],
        'is_pinned': (map['is_pinned'] == true) ? 1 : 0,
        'created_at': map['created_at'],
      },
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  /// Replaces all recently_played rows with [songs].
  Future<void> replaceRecentlyPlayed(
      Database db, List<Map<String, dynamic>> songs) async {
    await db.delete('recently_played');
    for (final s in songs) {
      await db.insert(
        'recently_played',
        {
          'song_id': s['id'],
          'title': s['title'] ?? '',
          'artist': s['artist'] ?? '',
          'thumbnail_url': s['thumbnailUrl'] ?? '',
          'duration_seconds': s['durationSeconds'] ?? 0,
          'last_played_at': s['lastPlayed'] ?? DateTime.now().toUtc().toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  /// Replaces all recent_searches rows with [queries].
  Future<void> replaceRecentSearches(Database db, List<String> queries) async {
    await db.delete('recent_searches');
    final now = DateTime.now().toUtc().toIso8601String();
    for (final q in queries) {
      if (q.trim().isEmpty) continue;
      await db.insert(
        'recent_searches',
        {'query': q, 'created_at': now},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  /// Replaces all downloaded_song_ids rows with [ids].
  Future<void> replaceDownloadedSongIds(Database db, List<String> ids) async {
    await db.delete('downloaded_song_ids');
    for (final id in ids) {
      if (id.isEmpty) continue;
      await db.insert(
        'downloaded_song_ids',
        {'song_id': id},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  /// Inserts a single folder–playlist junction row.
  Future<void> insertSingleFolderPlaylist(
      Database db, String folderId, String playlistId) async {
    await db.insert(
      'folder_playlists',
      {'folder_id': folderId, 'playlist_id': playlistId},
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  /// Inserts or replaces a single setting [key]=[value] within [txn].
  Future<void> setSettingInTransaction(
      Transaction txn, String key, String value) async {
    await txn.insert('settings', {'key': key, 'value': value},
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  /// Inserts a cache-only playlist_info entry (INSERT OR IGNORE). Sets is_saved=0.
  Future<void> upsertPlaylistCache(
    Database db,
    String browseId,
    int? paletteColor,
    String? imageUrl,
  ) async {
    try {
      await db.insert(
        'playlist_info',
        {
          'id': browseId,
          'name': browseId,
          'description': '',
          'sort_order': 'customOrder',
          'cover_url': imageUrl,
          'is_imported': 0,
          'browse_id': browseId,
          'palette_color': paletteColor,
          'is_saved': 0,
          'shuffle_enabled': 0,
          'is_pinned': 0,
          'is_artist': 0,
          'is_album': 0,
          'created_at': DateTime.now().toUtc().toIso8601String(),
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    } catch (_) {}
  }

  /// Inserts or replaces a stream URL cache entry.
  Future<void> upsertStreamUrlCache(
    Database db,
    String videoId,
    String url,
    Map<String, String> headers,
    int bitrate,
    String quality,
    DateTime expiresAt,
  ) async {
    try {
      await db.insert(
        'stream_url_cache',
        {
          'video_id': videoId,
          'url': url,
          'headers': jsonEncode(headers),
          'bitrate': bitrate,
          'quality': quality,
          'expires_at': expiresAt.toUtc().toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (_) {}
  }
}
