import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import 'create.controller.dart';
import 'delete.controller.dart';
import 'get.controller.dart';
import 'update.controller.dart';

/// Primary app database (SQLite). All reads and writes go through this class.
/// Supabase sync runs in the background for logged-in users. Operations are
/// delegated to get/create/update/delete controllers.
class PrimaryDatabase {
  static const String _dbName = 'tunify_primary.db';
  static const int _version = 4;

  static final PrimaryDatabase _instance = PrimaryDatabase._internal();
  factory PrimaryDatabase() => _instance;
  PrimaryDatabase._internal() {
    _getController = SqliteGetController(_getDb);
    _createController = SqliteCreateController();
    _updateController = SqliteUpdateController(_getDb);
    _deleteController = SqliteDeleteController();
  }

  Database? _db;
  late final SqliteGetController _getController;
  late final SqliteCreateController _createController;
  late final SqliteUpdateController _updateController;
  late final SqliteDeleteController _deleteController;

  Future<Database> _getDb() async {
    if (_db != null && _db!.isOpen) return _db!;
    final dir = await getApplicationDocumentsDirectory();
    final path = join(dir.path, _dbName);
    _db = await openDatabase(
      path,
      version: _version,
      onConfigure: (db) async => db.execute('PRAGMA foreign_keys = ON'),
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
    return _db!;
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await _createPodcastTables(db);
    }
    if (oldVersion < 3) {
      await _addPinnedColumnsToPodcastTables(db);
    }
    if (oldVersion < 4) {
      await _createEpisodesForLaterTable(db);
    }
  }

  Future<void> _addPinnedColumnsToPodcastTables(Database db) async {
    await db.execute('''
      ALTER TABLE podcast_subscriptions ADD COLUMN is_pinned INTEGER NOT NULL DEFAULT 0
    ''');
    await db.execute('''
      ALTER TABLE saved_audiobooks ADD COLUMN is_pinned INTEGER NOT NULL DEFAULT 0
    ''');
  }

  Future<void> _createEpisodesForLaterTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS episodes_for_later (
        id               TEXT PRIMARY KEY,
        title            TEXT NOT NULL,
        artist           TEXT NOT NULL DEFAULT '',
        thumbnail_url    TEXT,
        duration_seconds INTEGER NOT NULL DEFAULT 0,
        saved_at         TEXT NOT NULL
      )
    ''');
  }

  Future<void> _createPodcastTables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS podcast_subscriptions (
        id            TEXT PRIMARY KEY,
        title         TEXT NOT NULL,
        author        TEXT NOT NULL DEFAULT '',
        thumbnail_url TEXT,
        browse_id     TEXT,
        subscribed_at TEXT NOT NULL,
        is_pinned     INTEGER NOT NULL DEFAULT 0
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS playback_positions (
        content_id       TEXT NOT NULL,
        content_type     TEXT NOT NULL,
        position_seconds INTEGER NOT NULL DEFAULT 0,
        duration_seconds INTEGER NOT NULL DEFAULT 0,
        completed        INTEGER NOT NULL DEFAULT 0,
        last_played_at   TEXT NOT NULL,
        PRIMARY KEY (content_id, content_type)
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS saved_audiobooks (
        id            TEXT PRIMARY KEY,
        title         TEXT NOT NULL,
        author        TEXT NOT NULL DEFAULT '',
        thumbnail_url TEXT,
        browse_id     TEXT,
        saved_at      TEXT NOT NULL,
        is_pinned     INTEGER NOT NULL DEFAULT 0
      )
    ''');
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS playlist_info (
        id                       TEXT PRIMARY KEY,
        name                     TEXT NOT NULL,
        description              TEXT NOT NULL DEFAULT '',
        sort_order               TEXT NOT NULL DEFAULT 'customOrder',
        cover_url                TEXT,
        is_imported              INTEGER NOT NULL DEFAULT 0,
        browse_id                TEXT,
        palette_color            INTEGER,
        is_saved                 INTEGER NOT NULL DEFAULT 1,
        total_track_count_remote INTEGER,
        shuffle_enabled          INTEGER NOT NULL DEFAULT 0,
        is_pinned                INTEGER NOT NULL DEFAULT 0,
        is_artist                INTEGER NOT NULL DEFAULT 0,
        is_album                 INTEGER NOT NULL DEFAULT 0,
        created_at               TEXT NOT NULL,
        updated_at               TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS playlist_songs (
        row_id              INTEGER PRIMARY KEY AUTOINCREMENT,
        playlist_id         TEXT NOT NULL REFERENCES playlist_info(id) ON DELETE CASCADE,
        song_id             TEXT NOT NULL,
        title               TEXT NOT NULL,
        artist              TEXT NOT NULL,
        cover_url           TEXT NOT NULL DEFAULT '',
        duration_ms         INTEGER NOT NULL DEFAULT 0,
        is_explicit         INTEGER NOT NULL DEFAULT 0,
        artist_browse_id    TEXT,
        album_browse_id     TEXT,
        album_name          TEXT,
        sort_order_sequence INTEGER NOT NULL DEFAULT 0
      )
    ''');
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_playlist_songs_playlist
        ON playlist_songs(playlist_id, sort_order_sequence)
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS folders (
        id         TEXT PRIMARY KEY,
        name       TEXT NOT NULL,
        is_pinned  INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS recently_played (
        song_id          TEXT PRIMARY KEY,
        title            TEXT NOT NULL,
        artist           TEXT NOT NULL,
        thumbnail_url    TEXT NOT NULL DEFAULT '',
        duration_seconds INTEGER NOT NULL DEFAULT 0,
        last_played_at   TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS recent_searches (
        query      TEXT PRIMARY KEY,
        created_at TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS downloaded_song_ids (
        song_id TEXT PRIMARY KEY
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS folder_playlists (
        folder_id   TEXT NOT NULL,
        playlist_id TEXT NOT NULL,
        PRIMARY KEY (folder_id, playlist_id),
        FOREIGN KEY (folder_id)   REFERENCES folders(id)       ON DELETE CASCADE,
        FOREIGN KEY (playlist_id) REFERENCES playlist_info(id) ON DELETE CASCADE
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS settings (
        key   TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS stream_url_cache (
        video_id   TEXT PRIMARY KEY,
        url        TEXT NOT NULL,
        headers    TEXT NOT NULL DEFAULT '{}',
        bitrate    INTEGER NOT NULL DEFAULT 0,
        quality    TEXT NOT NULL DEFAULT '',
        expires_at TEXT NOT NULL
      )
    ''');
    await _createController.runOnCreate(db);
    await _createPodcastTables(db);
  }


  /// Loads full library (playlists, folders, settings).
  Future<Map<String, dynamic>> loadLibraryData() async =>
      _getController.loadLibraryData();

  /// Persists library data in a single transaction.
  Future<void> saveLibraryData(Map<String, dynamic> data) async {
    final db = await _getDb();
    final playlists = data['playlists'] as List<dynamic>? ?? [];
    final folders = data['folders'] as List<dynamic>? ?? [];
    final artistsRaw = data['followedArtists'] as List<dynamic>? ?? [];
    final albumsRaw = data['followedAlbums'] as List<dynamic>? ?? [];

    // Convert artist/album entries to playlist_info row maps.
    final artistRows = artistsRaw.map((a) {
      final m = Map<String, dynamic>.from(a as Map);
      final now = m['followedAt'] as String? ?? DateTime.now().toUtc().toIso8601String();
      return <String, dynamic>{
        'id': m['id'],
        'name': m['name'] ?? '',
        'description': '',
        'sort_order': 'customOrder',
        'cover_url': m['thumbnailUrl'],
        'is_imported': false,
        'browse_id': m['browseId'],
        'palette_color': m['cachedPaletteColor'],
        'is_saved': true,
        'total_track_count_remote': null,
        'shuffle_enabled': false,
        'is_pinned': false,
        'is_artist': true,
        'is_album': false,
        'created_at': now,
        'updated_at': now,
        'songs': <dynamic>[],
      };
    }).toList();

    final albumRows = albumsRaw.map((a) {
      final m = Map<String, dynamic>.from(a as Map);
      final now = m['followedAt'] as String? ?? DateTime.now().toUtc().toIso8601String();
      return <String, dynamic>{
        'id': m['id'],
        'name': m['title'] ?? '',
        'description': m['artistName'] ?? '',
        'sort_order': 'customOrder',
        'cover_url': m['thumbnailUrl'],
        'is_imported': false,
        'browse_id': m['browseId'],
        'palette_color': m['cachedPaletteColor'],
        'is_saved': true,
        'total_track_count_remote': null,
        'shuffle_enabled': false,
        'is_pinned': false,
        'is_artist': false,
        'is_album': true,
        'created_at': now,
        'updated_at': now,
        'songs': <dynamic>[],
      };
    }).toList();

    final allRows = [...playlists, ...artistRows, ...albumRows];

    await db.transaction((txn) async {
      final currentIds =
          allRows.map((p) => (p as Map)['id'] as String).toSet();
      final currentFolderIds =
          folders.map((f) => (f as Map)['id'] as String).toSet();

      await _deleteController.deletePlaylistsNotIn(txn, currentIds);
      await _deleteController.deleteFoldersNotIn(txn, currentFolderIds);
      await _deleteController.deleteAllFolderPlaylists(txn);

      await _createController.upsertPlaylists(txn, allRows);
      await _createController.insertFolders(txn, folders);
      await _createController.insertFolderPlaylists(txn, folders);

      await _createController.setSettingInTransaction(
          txn, 'sort_order', data['sortOrder']?.toString() ?? 'recent');
      await _createController.setSettingInTransaction(
          txn, 'view_mode', data['viewMode']?.toString() ?? 'list');
      await _createController.setSettingInTransaction(txn,
          'downloaded_shuffle', (data['downloadedShuffleMode'] as int? ?? 0).toString());
      await _createController.setSettingInTransaction(txn,
          'downloads_sort_order', data['downloadsSortOrder']?.toString() ?? 'customOrder');

    });
  }

  // ── Playlist surgical ops ─────────────────────────────────────────────────

  /// Inserts a new playlist (metadata only, no songs). Ignored if id exists.
  Future<void> createPlaylist(Map<String, dynamic> data) async {
    final db = await _getDb();
    await _createController.insertPlaylist(db, data);
  }

  /// Deletes a playlist by id. CASCADE removes its songs and folder memberships.
  Future<void> deletePlaylist(String id) async {
    final db = await _getDb();
    await _deleteController.deletePlaylist(db, id);
  }

  /// Updates specific columns on a single playlist_info row.
  /// Only the columns included in [fields] are written.
  Future<void> updatePlaylistMeta(
      String id, Map<String, dynamic> fields) async {
    final db = await _getDb();
    await _updateController.updatePlaylistMeta(db, id, fields);
  }

  /// Replaces all songs for [playlistId] and updates its updated_at timestamp.
  /// Only playlist_songs for this one playlist are touched.
  Future<void> replacePlaylistSongs(
    String playlistId,
    List<Map<String, dynamic>> songs,
    String updatedAt,
  ) async {
    final db = await _getDb();
    await db.transaction((txn) async {
      await _createController.replaceSongsInTransaction(txn, playlistId, songs);
      await txn.rawUpdate(
        'UPDATE playlist_info SET updated_at = ? WHERE id = ?',
        [updatedAt, playlistId],
      );
    });
  }

  // ── Folder surgical ops ───────────────────────────────────────────────────

  /// Inserts a new folder. Ignored if id exists.
  Future<void> createFolder(Map<String, dynamic> data) async {
    final db = await _getDb();
    await _createController.insertSingleFolder(db, data);
  }

  /// Deletes a folder by id. CASCADE removes its folder_playlists rows.
  Future<void> deleteFolder(String id) async {
    final db = await _getDb();
    await _deleteController.deleteFolder(db, id);
  }

  /// Renames a folder.
  Future<void> renameFolder(String id, String name) async {
    final db = await _getDb();
    await _updateController.updateFolderName(db, id, name);
  }

  /// Adds a playlist to a folder's junction table.
  Future<void> addPlaylistToFolder(String folderId, String playlistId) async {
    final db = await _getDb();
    await _createController.insertSingleFolderPlaylist(db, folderId, playlistId);
  }

  /// Removes a playlist from a folder's junction table.
  Future<void> removePlaylistFromFolder(
      String folderId, String playlistId) async {
    final db = await _getDb();
    await _deleteController.deleteFolderPlaylistEntry(db, folderId, playlistId);
  }

  // ── Artist / Album surgical ops ───────────────────────────────────────────

  /// Inserts a followed artist as a playlist_info row (INSERT OR IGNORE).
  /// [map] must use LibraryArtist.toJson() keys.
  Future<void> insertArtist(Map<String, dynamic> map) async {
    final db = await _getDb();
    await _createController.insertArtist(db, map);
  }

  /// Inserts a followed album as a playlist_info row (INSERT OR IGNORE).
  /// [map] must use LibraryAlbum.toJson() keys.
  Future<void> insertAlbum(Map<String, dynamic> map) async {
    final db = await _getDb();
    await _createController.insertAlbum(db, map);
  }

  /// Deletes a followed artist or album row by [id].
  /// Reuses deletePlaylist since artist/album rows live in playlist_info.
  Future<void> deleteArtistOrAlbum(String id) async {
    final db = await _getDb();
    await _deleteController.deletePlaylist(db, id);
  }

  static const int _maxRecentlyPlayed = 50;

  Future<List<Map<String, dynamic>>> loadRecentlyPlayed() async =>
      _getController.loadRecentlyPlayed();

  Future<void> saveRecentlyPlayed(List<Map<String, dynamic>> songs) async {
    final db = await _getDb();
    final limited = songs.take(_maxRecentlyPlayed).toList();
    await _createController.replaceRecentlyPlayed(db, limited);
  }

  Future<String?> getSetting(String key) async =>
      _getController.getSetting(key);

  Future<void> setSetting(String key, String value) async =>
      _updateController.setSetting(key, value);

  Future<List<String>> loadRecentSearches() async =>
      _getController.loadRecentSearches();

  Future<void> saveRecentSearches(List<String> queries) async {
    final db = await _getDb();
    await _createController.replaceRecentSearches(db, queries.take(20).toList());
  }

  Future<List<String>> loadDownloadedSongIds() async =>
      _getController.loadDownloadedSongIds();

  Future<void> saveDownloadedSongIds(List<String> ids) async {
    final db = await _getDb();
    await _createController.replaceDownloadedSongIds(db, ids);
  }

  Future<void> updatePinnedFolderIds(List<String> ids) async {
    final db = await _getDb();
    await _updateController.updatePinnedFolderIds(db, ids);
  }

  Future<Map<String, dynamic>> loadYtPersonalization() async =>
      _getController.loadYtPersonalization();

  Future<void> saveYtPersonalization(Map<String, dynamic> data) async {
    if (data.containsKey('visitor_data')) {
      await setSetting('yt_visitor_data', data['visitor_data']?.toString() ?? '');
    }
    if (data.containsKey('api_key')) {
      await setSetting('yt_api_key', data['api_key']?.toString() ?? '');
    }
    if (data.containsKey('client_version')) {
      await setSetting('yt_client_version', data['client_version']?.toString() ?? '');
    }
  }

  Future<void> close() async {
    if (_db != null) {
      await _db!.close();
      _db = null;
    }
  }

  // ── Stream URL Cache ──────────────────────────────────────────────────────

  Future<Map<String, dynamic>?> getStreamUrlCache(String videoId) async =>
      _getController.getStreamUrlCache(videoId);

  Future<void> upsertStreamUrlCache(
    String videoId,
    String url,
    Map<String, String> headers,
    int bitrate,
    String quality,
    DateTime expiresAt,
  ) async {
    final db = await _getDb();
    await _createController.upsertStreamUrlCache(
        db, videoId, url, headers, bitrate, quality, expiresAt);
  }

  Future<void> deleteStreamUrlCache(String videoId) async {
    final db = await _getDb();
    await _deleteController.deleteStreamUrlCache(db, videoId);
  }

  Future<void> clearExpiredStreamUrlCache() async {
    final db = await _getDb();
    await _deleteController.clearExpiredStreamUrlCache(db);
  }

  Future<void> clearAllStreamUrlCache() async {
    final db = await _getDb();
    await _deleteController.clearAllStreamUrlCache(db);
  }

  Future<void> trimStreamUrlCacheIfNeeded() async {
    final db = await _getDb();
    await _deleteController.trimStreamUrlCacheIfNeeded(db);
  }

  // ── Playlist Cache ────────────────────────────────────────────────────────

  Future<void> upsertPlaylistCache(
      String browseId, int? paletteColor, String? imageUrl) async {
    final db = await _getDb();
    await _createController.upsertPlaylistCache(db, browseId, paletteColor, imageUrl);
  }

  Future<int?> getPlaylistPaletteColor(String browseId) async =>
      _getController.getPlaylistPaletteColor(browseId);

  Future<void> clearCacheOnlyPlaylists() async {
    final db = await _getDb();
    await _deleteController.clearCacheOnlyPlaylists(db);
  }

  // ── Podcast Subscriptions ─────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> loadPodcastSubscriptions() async {
    final db = await _getDb();
    return db.query('podcast_subscriptions', orderBy: 'subscribed_at DESC');
  }

  Future<void> upsertPodcastSubscription(Map<String, dynamic> data) async {
    final db = await _getDb();
    await db.insert('podcast_subscriptions', data,
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> deletePodcastSubscription(String id) async {
    final db = await _getDb();
    await db.delete('podcast_subscriptions', where: 'id = ?', whereArgs: [id]);
  }

  // ── Saved Audiobooks ──────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> loadSavedAudiobooks() async {
    final db = await _getDb();
    return db.query('saved_audiobooks', orderBy: 'saved_at DESC');
  }

  Future<void> upsertSavedAudiobook(Map<String, dynamic> data) async {
    final db = await _getDb();
    await db.insert('saved_audiobooks', data,
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> deleteSavedAudiobook(String id) async {
    final db = await _getDb();
    await db.delete('saved_audiobooks', where: 'id = ?', whereArgs: [id]);
  }

  // ── Episodes For Later ────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> loadEpisodesForLater() async {
    final db = await _getDb();
    return db.query('episodes_for_later', orderBy: 'saved_at DESC');
  }

  Future<void> upsertEpisodeForLater(Map<String, dynamic> data) async {
    final db = await _getDb();
    await db.insert('episodes_for_later', data,
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> deleteEpisodeForLater(String id) async {
    final db = await _getDb();
    await db.delete('episodes_for_later', where: 'id = ?', whereArgs: [id]);
  }

  // ── Playback Positions ────────────────────────────────────────────────────

  Future<Map<String, dynamic>?> getPlaybackPosition(
      String contentId, String contentType) async {
    final db = await _getDb();
    final rows = await db.query(
      'playback_positions',
      where: 'content_id = ? AND content_type = ?',
      whereArgs: [contentId, contentType],
      limit: 1,
    );
    return rows.isEmpty ? null : rows.first;
  }

  Future<List<Map<String, dynamic>>> loadAllPlaybackPositions() async {
    final db = await _getDb();
    return db.query('playback_positions', orderBy: 'last_played_at DESC');
  }

  Future<void> upsertPlaybackPosition(Map<String, dynamic> data) async {
    final db = await _getDb();
    await db.insert('playback_positions', data,
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> deletePlaybackPosition(
      String contentId, String contentType) async {
    final db = await _getDb();
    await db.delete('playback_positions',
        where: 'content_id = ? AND content_type = ?',
        whereArgs: [contentId, contentType]);
  }

}
