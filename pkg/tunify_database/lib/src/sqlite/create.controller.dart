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
}
