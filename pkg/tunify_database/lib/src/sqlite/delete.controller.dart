import 'package:sqflite/sqflite.dart';

/// SQLite delete operations. All delete logic lives in this controller.
class SqliteDeleteController {
  /// Deletes saved playlists whose id is not in [currentIds], within [txn].
  /// ON DELETE CASCADE removes corresponding playlist_songs rows automatically.
  Future<void> deletePlaylistsNotIn(
      Transaction txn, Set<String> currentIds) async {
    final existing = await txn
        .query('playlist_info', columns: ['id'], where: 'is_saved = 1');
    for (final row in existing) {
      final id = row['id'] as String;
      if (!currentIds.contains(id)) {
        await txn.delete('playlist_info',
            where: 'id = ? AND is_saved = 1', whereArgs: [id]);
      }
    }
  }

  /// Deletes folders whose id is not in [currentFolderIds] within [txn].
  /// folder_playlists rows are removed separately since we clear them wholesale.
  Future<void> deleteFoldersNotIn(
      Transaction txn, Set<String> currentFolderIds) async {
    final existingFolders = await txn.query('folders', columns: ['id']);
    for (final row in existingFolders) {
      final id = row['id'] as String;
      if (!currentFolderIds.contains(id)) {
        await txn
            .delete('folder_playlists', where: 'folder_id = ?', whereArgs: [id]);
        await txn.delete('folders', where: 'id = ?', whereArgs: [id]);
      }
    }
  }

  /// Deletes all rows from folder_playlists within [txn].
  Future<void> deleteAllFolderPlaylists(Transaction txn) async {
    await txn.delete('folder_playlists');
  }

  /// Deletes a single playlist by [id].
  /// ON DELETE CASCADE removes its playlist_songs and folder_playlists rows.
  Future<void> deletePlaylist(Database db, String id) async {
    await db.delete('playlist_info', where: 'id = ?', whereArgs: [id]);
  }

  /// Deletes a single folder by [id].
  /// ON DELETE CASCADE removes its folder_playlists rows.
  Future<void> deleteFolder(Database db, String id) async {
    await db.delete('folders', where: 'id = ?', whereArgs: [id]);
  }

  /// Removes a single playlist from a folder's junction table.
  Future<void> deleteFolderPlaylistEntry(
      Database db, String folderId, String playlistId) async {
    await db.delete('folder_playlists',
        where: 'folder_id = ? AND playlist_id = ?',
        whereArgs: [folderId, playlistId]);
  }

  /// Deletes the stream URL cache entry for [videoId].
  Future<void> deleteStreamUrlCache(Database db, String videoId) async {
    try {
      await db.delete('stream_url_cache',
          where: 'video_id = ?', whereArgs: [videoId]);
    } catch (_) {}
  }

  /// Deletes all expired stream URL cache entries (expires_at < now).
  Future<void> clearExpiredStreamUrlCache(Database db) async {
    try {
      final now = DateTime.now().toUtc().toIso8601String();
      await db
          .delete('stream_url_cache', where: 'expires_at < ?', whereArgs: [now]);
    } catch (_) {}
  }

  /// Deletes all stream URL cache entries.
  Future<void> clearAllStreamUrlCache(Database db) async {
    try {
      await db.delete('stream_url_cache');
    } catch (_) {}
  }

  /// Deletes all cache-only playlist_info rows (is_saved = 0).
  /// ON DELETE CASCADE removes their playlist_songs rows automatically.
  Future<void> clearCacheOnlyPlaylists(Database db) async {
    try {
      await db.delete('playlist_info', where: 'is_saved = ?', whereArgs: [0]);
    } catch (_) {}
  }

  /// Trims stream URL cache to 180 rows when count >= 200 (LRU by expires_at).
  Future<void> trimStreamUrlCacheIfNeeded(Database db) async {
    try {
      final count = Sqflite.firstIntValue(
            await db.rawQuery('SELECT COUNT(*) FROM stream_url_cache'),
          ) ??
          0;
      if (count < 200) return;
      final toDelete = count - 180;
      await db.rawDelete(
        'DELETE FROM stream_url_cache WHERE video_id IN '
        '(SELECT video_id FROM stream_url_cache ORDER BY expires_at ASC LIMIT ?)',
        [toDelete],
      );
    } catch (_) {}
  }
}
