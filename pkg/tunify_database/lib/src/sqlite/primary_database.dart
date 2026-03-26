import 'dart:convert';

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
  static const int _version = 5;

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
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
    return _db!;
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      create table if not exists playlists (
        id text primary key,
        name text not null,
        description text not null default '',
        sort_order text not null default 'customOrder',
        songs text not null default '[]',
        created_at text not null,
        updated_at text not null,
        custom_image_url text,
        is_imported integer not null default 0,
        browse_id text,
        cached_palette_color integer,
        is_saved integer not null default 1,
        remote_track_count integer
      )
    ''');
    await db.execute('''
      create table if not exists folders (
        id text primary key,
        name text not null,
        created_at text not null
      )
    ''');
    await db.execute('''
      create table if not exists folder_playlists (
        folder_id text not null,
        playlist_id text not null,
        primary key (folder_id, playlist_id),
        foreign key (folder_id) references folders(id) on delete cascade,
        foreign key (playlist_id) references playlists(id) on delete cascade
      )
    ''');
    await db.execute('''
      create table if not exists settings (
        key text primary key,
        value text not null
      )
    ''');
    await db.execute('''
      create table if not exists stream_url_cache (
        video_id   text primary key,
        url        text not null,
        headers    text not null default '{}',
        bitrate    integer not null default 0,
        quality    text not null default '',
        expires_at text not null
      )
    ''');
    await db.execute('''
      create table if not exists collection_tracks (
        browse_id   text not null,
        track_index integer not null,
        track_data  text not null,
        is_saved    integer not null default 0,
        cached_at   text not null,
        primary key (browse_id, track_index)
      )
    ''');
    await _createController.runOnCreate(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db
          .execute('ALTER TABLE playlists ADD COLUMN custom_image_url TEXT');
      await _createController.runOnUpgrade(db, oldVersion, newVersion);
    }
    if (oldVersion < 3) {
      await db.execute(
          'ALTER TABLE playlists ADD COLUMN is_imported INTEGER NOT NULL DEFAULT 0');
      await db.execute('ALTER TABLE playlists ADD COLUMN browse_id TEXT');
      await db.execute(
          'ALTER TABLE playlists ADD COLUMN cached_palette_color INTEGER');
    }
    if (oldVersion < 4) {
      await db.execute(
          'ALTER TABLE playlists ADD COLUMN is_saved INTEGER NOT NULL DEFAULT 1');
      await db.execute('''
        create table if not exists stream_url_cache (
          video_id   text primary key,
          url        text not null,
          headers    text not null default '{}',
          bitrate    integer not null default 0,
          quality    text not null default '',
          expires_at text not null
        )
      ''');
      await db.execute('''
        create table if not exists collection_tracks (
          browse_id   text not null,
          track_index integer not null,
          track_data  text not null,
          is_saved    integer not null default 0,
          cached_at   text not null,
          primary key (browse_id, track_index)
        )
      ''');
    }
    if (oldVersion < 5) {
      await db.execute(
          'ALTER TABLE playlists ADD COLUMN remote_track_count INTEGER');
    }
  }

  /// Loads full library (playlists, folders, liked songs, sort/view and shuffle settings).
  Future<Map<String, dynamic>> loadLibraryData() async =>
      _getController.loadLibraryData();

  /// Persists library data in a single transaction (replaces playlists/folders not in [data]).
  Future<void> saveLibraryData(Map<String, dynamic> data) async {
    final db = await _getDb();
    final playlists = data['playlists'] as List<dynamic>? ?? [];
    final folders = data['folders'] as List<dynamic>? ?? [];
    final likedSongs = data['likedSongs'] as List<dynamic>? ?? [];

    await db.transaction((txn) async {
      final currentIds =
          playlists.map((p) => (p as Map)['id'] as String).toSet();
      final currentFolderIds =
          folders.map((f) => (f as Map)['id'] as String).toSet();

      await _deleteController.deletePlaylistsNotIn(txn, currentIds);
      await _deleteController.deleteFoldersNotIn(txn, currentFolderIds);
      await _deleteController.deleteAllFolderPlaylists(txn);

      await _createController.insertPlaylists(txn, playlists);
      await _createController.insertFolders(txn, folders);
      await _createController.insertFolderPlaylists(txn, folders);

      await _createController.setSettingInTransaction(
          txn, 'sort_order', data['sortOrder']?.toString() ?? 'recent');
      await _createController.setSettingInTransaction(
          txn, 'view_mode', data['viewMode']?.toString() ?? 'list');
      await _createController.setSettingInTransaction(
          txn, 'liked_song_ids', jsonEncode(likedSongs));
      await _createController.setSettingInTransaction(txn, 'liked_shuffle',
          (data['likedShuffleEnabled'] == true).toString());
      await _createController.setSettingInTransaction(txn, 'downloaded_shuffle',
          (data['downloadedShuffleEnabled'] == true).toString());
      await _createController.setSettingInTransaction(
          txn, 'playlist_shuffles', jsonEncode(data['playlistShuffles'] ?? {}));
      await _createController.setSettingInTransaction(
          txn, 'followed_artists', jsonEncode(data['followedArtists'] ?? []));
      await _createController.setSettingInTransaction(
          txn, 'followed_albums', jsonEncode(data['followedAlbums'] ?? []));
      final pinnedP = playlists
          .where((p) => (p as Map)['is_pinned'] == true)
          .map((p) => (p as Map)['id'].toString())
          .toList();
      final pinnedF = folders
          .where((f) => (f as Map)['is_pinned'] == true)
          .map((f) => (f as Map)['id'].toString())
          .toList();
      await _createController.setSettingInTransaction(
          txn, 'pinned_playlist_ids', jsonEncode(pinnedP));
      await _createController.setSettingInTransaction(
          txn, 'pinned_folder_ids', jsonEncode(pinnedF));
    });
  }

  static const int _maxRecentlyPlayed = 50;

  /// Loads recently played songs (up to [_maxRecentlyPlayed]).
  Future<List<Map<String, dynamic>>> loadRecentlyPlayed() async =>
      _getController.loadRecentlyPlayed();

  /// Saves recently played list (truncated to [_maxRecentlyPlayed]).
  Future<void> saveRecentlyPlayed(List<Map<String, dynamic>> songs) async {
    final limited = songs.take(_maxRecentlyPlayed).toList();
    await setSetting('recently_played', jsonEncode(limited));
  }

  /// Returns the value for [key] from the settings table, or null if missing.
  Future<String?> getSetting(String key) async =>
      _getController.getSetting(key);

  /// Persists a single setting [key] = [value].
  Future<void> setSetting(String key, String value) async {
    await _updateController.setSetting(key, value);
  }

  /// Loads recent search queries (up to 20).
  Future<List<String>> loadRecentSearches() async =>
      _getController.loadRecentSearches();

  /// Saves recent searches (truncated to 20).
  Future<void> saveRecentSearches(List<String> queries) async {
    await setSetting('recent_searches', jsonEncode(queries.take(20).toList()));
  }

  /// Loads the set of downloaded song IDs.
  Future<List<String>> loadDownloadedSongIds() async =>
      _getController.loadDownloadedSongIds();

  /// Saves the list of downloaded song IDs.
  Future<void> saveDownloadedSongIds(List<String> ids) async {
    await setSetting('downloaded_song_ids', jsonEncode(ids));
  }

  /// Loads YT personalization (visitor_data, api_key, client_version).
  Future<Map<String, dynamic>> loadYtPersonalization() async =>
      _getController.loadYtPersonalization();

  /// Saves YT personalization keys present in [data].
  Future<void> saveYtPersonalization(Map<String, dynamic> data) async {
    if (data.containsKey('visitor_data')) {
      await setSetting(
          'yt_visitor_data', data['visitor_data']?.toString() ?? '');
    }
    if (data.containsKey('api_key')) {
      await setSetting('yt_api_key', data['api_key']?.toString() ?? '');
    }
    if (data.containsKey('client_version')) {
      await setSetting(
          'yt_client_version', data['client_version']?.toString() ?? '');
    }
  }

  /// Closes the database connection.
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
    await _createController.upsertPlaylistCache(
        db, browseId, paletteColor, imageUrl);
  }

  Future<int?> getPlaylistPaletteColor(String browseId) async =>
      _getController.getPlaylistPaletteColor(browseId);

  Future<void> clearCacheOnlyPlaylists() async {
    final db = await _getDb();
    await _deleteController.clearCacheOnlyPlaylists(db);
  }

  // ── Collection Track Cache ────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>?> getCollectionTracks(
          String browseId) async =>
      _getController.getCollectionTracks(browseId);

  Future<void> upsertCollectionTracks(
      String browseId, List<Map<String, dynamic>> tracks) async {
    final db = await _getDb();
    await _createController.upsertCollectionTracks(db, browseId, tracks);
  }

  Future<void> deleteCollectionTracks(String browseId) async {
    final db = await _getDb();
    await _deleteController.deleteCollectionTracks(db, browseId);
  }

  Future<void> clearCacheOnlyCollectionTracks() async {
    final db = await _getDb();
    await _deleteController.clearCacheOnlyCollectionTracks(db);
  }
}
