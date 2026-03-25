import 'dart:convert';

import 'package:sqflite/sqflite.dart';

/// SQLite insert operations. All create/insert logic lives in this controller.
class SqliteCreateController {
  SqliteCreateController();

  /// Inserts default settings rows during database creation (onCreate).
  Future<void> runOnCreate(Database db) async {
    await db.insert('settings', {'key': 'sort_order', 'value': 'recent'});
    await db.insert('settings', {'key': 'view_mode', 'value': 'list'});
    await db.insert('settings', {'key': 'liked_song_ids', 'value': '[]'});
    await db.insert('settings', {'key': 'recent_searches', 'value': '[]'});
    await db.insert('settings', {'key': 'downloaded_song_ids', 'value': '[]'});
  }

  /// Runs during schema upgrade (e.g. v1 → v2); adds missing settings keys if needed.
  Future<void> runOnUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      final r = await db.query('settings', where: 'key = ?', whereArgs: ['recent_searches']);
      if (r.isEmpty) await db.insert('settings', {'key': 'recent_searches', 'value': '[]'});
      final d = await db.query('settings', where: 'key = ?', whereArgs: ['downloaded_song_ids']);
      if (d.isEmpty) await db.insert('settings', {'key': 'downloaded_song_ids', 'value': '[]'});
    }
  }

  /// Inserts or replaces playlists in the playlists table within [txn].
  Future<void> insertPlaylists(Transaction txn, List<dynamic> playlists) async {
    for (final p in playlists) {
      final map = p as Map<String, dynamic>;
      await txn.insert('playlists', {
        'id': map['id'],
        'name': map['name'],
        'description': map['description'] ?? '',
        'sort_order': map['sort_order'] ?? 'customOrder',
        'songs': jsonEncode(map['songs'] ?? []),
        'created_at': map['created_at'],
        'updated_at': map['updated_at'],
        'custom_image_url': map['custom_image_url'],
        'is_imported': (map['is_imported'] == true) ? 1 : 0,
        'browse_id': map['browse_id'],
        'cached_palette_color': map['cached_palette_color'],
        'is_saved': 1,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }
  }

  /// Inserts or replaces folders in the folders table within [txn].
  Future<void> insertFolders(Transaction txn, List<dynamic> folders) async {
    for (final f in folders) {
      final map = f as Map<String, dynamic>;
      await txn.insert('folders', {
        'id': map['id'],
        'name': map['name'],
        'created_at': map['created_at'],
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }
  }

  /// Inserts folder–playlist junction rows for each folder in [folders] within [txn].
  Future<void> insertFolderPlaylists(Transaction txn, List<dynamic> folders) async {
    for (final f in folders) {
      final map = f as Map<String, dynamic>;
      final folderId = map['id'] as String;
      for (final pid in map['playlistIds'] as List<dynamic>? ?? []) {
        await txn.insert('folder_playlists', {'folder_id': folderId, 'playlist_id': pid.toString()});
      }
    }
  }

  /// Inserts or replaces a single setting [key]=[value] within [txn].
  Future<void> setSettingInTransaction(Transaction txn, String key, String value) async {
    await txn.insert('settings', {'key': key, 'value': value}, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  /// Inserts a playlist cache entry (INSERT OR IGNORE). Sets is_saved=0.
  Future<void> upsertPlaylistCache(
    Database db,
    String browseId,
    int? paletteColor,
    String? imageUrl,
  ) async {
    try {
      await db.insert('playlists', {
        'id': browseId,
        'name': browseId,
        'description': '',
        'sort_order': 'customOrder',
        'songs': '[]',
        'created_at': DateTime.now().toUtc().toIso8601String(),
        'updated_at': DateTime.now().toUtc().toIso8601String(),
        'custom_image_url': imageUrl,
        'is_imported': 0,
        'browse_id': browseId,
        'cached_palette_color': paletteColor,
        'is_saved': 0,
      }, conflictAlgorithm: ConflictAlgorithm.ignore);
    } catch (_) {}
  }

  /// Inserts or replaces collection track cache rows for [browseId].
  Future<void> upsertCollectionTracks(
    Database db,
    String browseId,
    List<Map<String, dynamic>> tracks,
  ) async {
    try {
      final now = DateTime.now().toUtc().toIso8601String();
      final batch = db.batch();
      batch.delete('collection_tracks', where: 'browse_id = ? AND is_saved = 0', whereArgs: [browseId]);
      for (var i = 0; i < tracks.length; i++) {
        batch.insert('collection_tracks', {
          'browse_id': browseId,
          'track_index': i,
          'track_data': jsonEncode(tracks[i]),
          'is_saved': 0,
          'cached_at': now,
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }
      await batch.commit(noResult: true);
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
      await db.insert('stream_url_cache', {
        'video_id': videoId,
        'url': url,
        'headers': jsonEncode(headers),
        'bitrate': bitrate,
        'quality': quality,
        'expires_at': expiresAt.toUtc().toIso8601String(),
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    } catch (_) {}
  }
}
