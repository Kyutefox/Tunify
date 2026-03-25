import 'dart:convert';

import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

/// Local SQLite store for downloaded songs: file paths and song JSON.
/// Does not depend on app models; use [Map<String, dynamic>] for song data.
class DownloadStore {
  DownloadStore();

  static const String _dbName = 'downloads.db';
  static const int _version = 3;

  Database? _db;

  Future<Database> _getDb() async {
    if (_db != null && _db!.isOpen) return _db!;
    final dir = await getApplicationDocumentsDirectory();
    final path = join(dir.path, _dbName);
    _db = await openDatabase(
      path,
      version: _version,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
    return _db!;
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS downloads (
        song_id TEXT PRIMARY KEY,
        local_path TEXT NOT NULL,
        song_json TEXT NOT NULL,
        created_at TEXT NOT NULL,
        sort_order INTEGER NOT NULL DEFAULT 0
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS cached_songs (
        song_id TEXT PRIMARY KEY,
        song_json TEXT NOT NULL,
        created_at TEXT NOT NULL,
        last_accessed_at TEXT NOT NULL
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute(
        'ALTER TABLE downloads ADD COLUMN sort_order INTEGER NOT NULL DEFAULT 0',
      );
      final rows = await db.query('downloads', orderBy: 'created_at DESC');
      for (var i = 0; i < rows.length; i++) {
        await db.update(
          'downloads',
          {'sort_order': i},
          where: 'song_id = ?',
          whereArgs: [rows[i]['song_id']],
        );
      }
    }
    if (oldVersion < 3) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS cached_songs (
          song_id TEXT PRIMARY KEY,
          song_json TEXT NOT NULL,
          created_at TEXT NOT NULL,
          last_accessed_at TEXT NOT NULL
        )
      ''');
    }
  }

  /// Application documents subdirectory for downloaded audio files.
  static Future<String> get downloadDirectory async {
    final dir = await getApplicationDocumentsDirectory();
    return join(dir.path, 'downloaded_music');
  }

  /// Returns the local file path for [songId], or null if not stored.
  Future<String?> getPath(String songId) async {
    final db = await _getDb();
    final rows = await db.query(
      'downloads',
      columns: ['local_path'],
      where: 'song_id = ?',
      whereArgs: [songId],
    );
    if (rows.isEmpty) return null;
    return rows.first['local_path'] as String?;
  }

  /// Returns true if [songId] has a stored path.
  Future<bool> isDownloaded(String songId) async {
    final path = await getPath(songId);
    return path != null;
  }

  /// Returns all stored songs as raw JSON maps (order: sort_order, then created_at desc).
  Future<List<Map<String, dynamic>>> getDownloadedSongs() async {
    final db = await _getDb();
    final rows = await db.query(
      'downloads',
      orderBy: 'sort_order ASC, created_at DESC',
    );
    return rows.map((r) {
      final json = jsonDecode(r['song_json'] as String) as Map<String, dynamic>;
      return json;
    }).toList();
  }

  /// Inserts or replaces a download row. [songJson] is stored as-is (e.g. from app's Song.toJson()).
  Future<void> saveDownload(
      String songId, String localPath, Map<String, dynamic> songJson) async {
    final db = await _getDb();
    int sortOrder;
    final existing = await db.query(
      'downloads',
      columns: ['sort_order'],
      where: 'song_id = ?',
      whereArgs: [songId],
    );
    if (existing.isNotEmpty) {
      sortOrder = existing.first['sort_order'] as int;
    } else {
      final maxRow = await db.rawQuery(
        'SELECT COALESCE(MAX(sort_order), -1) + 1 AS next_order FROM downloads',
      );
      sortOrder = (maxRow.first['next_order'] as num?)?.toInt() ?? 0;
    }
    await db.insert(
      'downloads',
      {
        'song_id': songId,
        'local_path': localPath,
        'song_json': jsonEncode(songJson),
        'created_at': DateTime.now().toUtc().toIso8601String(),
        'sort_order': sortOrder,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Updates sort_order to match the order of [songIds].
  Future<void> setDownloadOrder(List<String> songIds) async {
    final db = await _getDb();
    for (var i = 0; i < songIds.length; i++) {
      await db.update(
        'downloads',
        {'sort_order': i},
        where: 'song_id = ?',
        whereArgs: [songIds[i]],
      );
    }
  }

  /// Removes the row for [songId].
  Future<void> removeDownload(String songId) async {
    final db = await _getDb();
    await db.delete('downloads', where: 'song_id = ?', whereArgs: [songId]);
  }

  /// Deletes all download rows and returns their local_path values (e.g. for file cleanup).
  Future<List<String>> clearAll() async {
    final db = await _getDb();
    final rows = await db.query('downloads', columns: ['local_path']);
    final paths = rows.map((r) => r['local_path'] as String).toList();
    await db.delete('downloads');
    return paths;
  }

  /// Closes the database connection.
  Future<void> close() async {
    if (_db != null) {
      await _db!.close();
      _db = null;
    }
  }

  /// Caches a song's metadata. Upserts if already exists, updates last_accessed_at.
  Future<void> cacheSongMetadata(
      String songId, Map<String, dynamic> songJson) async {
    final db = await _getDb();
    final now = DateTime.now().toUtc().toIso8601String();
    await db.insert(
      'cached_songs',
      {
        'song_id': songId,
        'song_json': jsonEncode(songJson),
        'created_at': now,
        'last_accessed_at': now,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Gets cached song metadata by songId. Returns null if not cached.
  Future<Map<String, dynamic>?> getCachedSongMetadata(String songId) async {
    final db = await _getDb();
    final rows = await db.query(
      'cached_songs',
      where: 'song_id = ?',
      whereArgs: [songId],
    );
    if (rows.isEmpty) return null;
    await db.update(
      'cached_songs',
      {'last_accessed_at': DateTime.now().toUtc().toIso8601String()},
      where: 'song_id = ?',
      whereArgs: [songId],
    );
    return jsonDecode(rows.first['song_json'] as String)
        as Map<String, dynamic>;
  }

  /// Gets cached song metadata for multiple songIds. Returns map of songId -> metadata.
  Future<Map<String, Map<String, dynamic>>> getCachedSongMetadataBatch(
      List<String> songIds) async {
    if (songIds.isEmpty) return {};
    final db = await _getDb();
    final placeholders = List.filled(songIds.length, '?').join(',');
    final rows = await db.query(
      'cached_songs',
      where: 'song_id IN ($placeholders)',
      whereArgs: songIds,
    );
    final now = DateTime.now().toUtc().toIso8601String();
    final result = <String, Map<String, dynamic>>{};
    for (final row in rows) {
      final songId = row['song_id'] as String;
      result[songId] =
          jsonDecode(row['song_json'] as String) as Map<String, dynamic>;
      await db.update(
        'cached_songs',
        {'last_accessed_at': now},
        where: 'song_id = ?',
        whereArgs: [songId],
      );
    }
    return result;
  }

  /// Removes a song from the cache.
  Future<void> removeCachedSong(String songId) async {
    final db = await _getDb();
    await db.delete('cached_songs', where: 'song_id = ?', whereArgs: [songId]);
  }

  /// Clears old cached songs (older than [maxAge]). Returns count of deleted entries.
  Future<int> clearOldCachedSongs(Duration maxAge) async {
    final db = await _getDb();
    final cutoff = DateTime.now().subtract(maxAge).toUtc().toIso8601String();
    final deleted = await db.delete(
      'cached_songs',
      where: 'last_accessed_at < ?',
      whereArgs: [cutoff],
    );
    return deleted;
  }

  /// Clears all cached songs.
  Future<void> clearAllCachedSongs() async {
    final db = await _getDb();
    await db.delete('cached_songs');
  }

  /// Gets count of cached songs.
  Future<int> getCachedSongsCount() async {
    final db = await _getDb();
    final result =
        await db.rawQuery('SELECT COUNT(*) as count FROM cached_songs');
    return (result.first['count'] as num?)?.toInt() ?? 0;
  }
}
