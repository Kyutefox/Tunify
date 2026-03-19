import 'package:sqflite/sqflite.dart';

/// SQLite delete operations. All delete logic lives in this controller.
class SqliteDeleteController {
  /// Deletes playlists whose id is not in [currentIds], within [txn].
  Future<void> deletePlaylistsNotIn(Transaction txn, Set<String> currentIds) async {
    final existing = await txn.query('playlists', columns: ['id']);
    for (final row in existing) {
      final id = row['id'] as String;
      if (!currentIds.contains(id)) await txn.delete('playlists', where: 'id = ?', whereArgs: [id]);
    }
  }

  /// Deletes folders whose id is not in [currentFolderIds] and their folder_playlists, within [txn].
  Future<void> deleteFoldersNotIn(Transaction txn, Set<String> currentFolderIds) async {
    final existingFolders = await txn.query('folders', columns: ['id']);
    for (final row in existingFolders) {
      final id = row['id'] as String;
      if (!currentFolderIds.contains(id)) {
        await txn.delete('folder_playlists', where: 'folder_id = ?', whereArgs: [id]);
        await txn.delete('folders', where: 'id = ?', whereArgs: [id]);
      }
    }
  }

  /// Deletes all rows from folder_playlists within [txn].
  Future<void> deleteAllFolderPlaylists(Transaction txn) async {
    await txn.delete('folder_playlists');
  }
}
