import 'package:sqflite/sqflite.dart';

/// SQLite update/upsert operations. All update logic lives in this controller.
class SqliteUpdateController {
  SqliteUpdateController(this._getDb);

  final Future<Database> Function() _getDb;

  /// Inserts or replaces the setting [key] with [value].
  Future<void> setSetting(String key, String value) async {
    final db = await _getDb();
    await db.insert('settings', {'key': key, 'value': value}, conflictAlgorithm: ConflictAlgorithm.replace);
  }
}
