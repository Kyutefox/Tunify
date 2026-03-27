import 'package:sqflite/sqflite.dart';

/// SQLite update/upsert operations. All update logic lives in this controller.
class SqliteUpdateController {
  SqliteUpdateController(this._getDb);

  final Future<Database> Function() _getDb;

  /// Inserts or replaces the setting [key] with [value].
  Future<void> setSetting(String key, String value) async {
    final db = await _getDb();
    await db.insert('settings', {'key': key, 'value': value},
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  /// Updates specific columns on a playlist_info row.
  ///
  /// [fields] maps column names to values. Only the provided columns are
  /// written — no other rows or tables are touched.
  Future<void> updatePlaylistMeta(
      Database db, String id, Map<String, dynamic> fields) async {
    if (fields.isEmpty) return;
    final setClause = fields.keys.map((k) => '$k = ?').join(', ');
    await db.rawUpdate(
      'UPDATE playlist_info SET $setClause WHERE id = ?',
      [...fields.values, id],
    );
  }

  /// Updates the name of a single folder row.
  Future<void> updateFolderName(Database db, String id, String name) async {
    await db.update('folders', {'name': name},
        where: 'id = ?', whereArgs: [id]);
  }
}
