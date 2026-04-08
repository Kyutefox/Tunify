import 'package:supabase_flutter/supabase_flutter.dart';

import 'create.controller.dart';
import 'delete.controller.dart';
import 'get.controller.dart';
import 'supabase_mappers.dart';
import 'update.controller.dart';

/// Remote Supabase API used for pull-on-login and background sync. All app
/// reads/writes go to SQLite via the bridge; this class only fetches from and
/// pushes to Supabase. Delegates to get/create/update/delete controllers.
class SupabaseRemote {
  SupabaseRemote() {
    final client = Supabase.instance.client;
    _getController = SupabaseGetController(client);
    _createController = SupabaseCreateController(client);
    _updateController = SupabaseUpdateController(client);
    _deleteController = SupabaseDeleteController(client);
  }

  late final SupabaseGetController _getController;
  late final SupabaseCreateController _createController;
  late final SupabaseUpdateController _updateController;
  late final SupabaseDeleteController _deleteController;

  /// Fetches full library for [userId] from Supabase.
  Future<Map<String, dynamic>?> fetchLibraryData(String userId) async =>
      _getController.fetchLibraryData(userId);

  /// Pushes library [data] to Supabase for [userId] (incremental playlists/folders, full replace liked).
  Future<void> pushLibraryData(String userId, Map<String, dynamic> data) async {
    try {
      await _updateController.upsertLibrarySettings(userId, data);

      final playlists = data['playlists'] as List<dynamic>? ?? [];
      final localPlaylistIds = playlists
          .map((p) => (p as Map)['id'] as String?)
          .whereType<String>()
          .toSet();
      final remote =
          await _getController.fetchRemoteLibraryStateForCompare(userId);
      final existingIds = remote.playlistUpdatedAt.keys.toList();

      for (final id in existingIds) {
        if (localPlaylistIds.contains(id)) continue;
        await _deleteController.deletePlaylist(userId, id);
      }

      for (final p in playlists) {
        final map = p as Map<String, dynamic>;
        final pid = map['id'] as String?;
        if (pid == null) continue;
        final localUpdatedAt = map['updated_at']?.toString() ?? '';
        final remoteUpdatedAt = remote.playlistUpdatedAt[pid];
        final isNew = remoteUpdatedAt == null;
        final isChanged = !isNew && remoteUpdatedAt != localUpdatedAt;
        if (!isNew && !isChanged) continue;

        await _updateController.upsertPlaylist(userId, map);
        await _deleteController.deletePlaylistTracks(userId, pid);
        final songs = (map['songs'] as List<dynamic>? ?? [])
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
        await _createController.insertPlaylistTracks(userId, pid, songs);
        await _updateController.upsertPlaylistShuffle(
            userId, pid, map['shuffleEnabled'] == true);
      }

      final folders = data['folders'] as List<dynamic>? ?? [];
      final localFolderIds = folders
          .map((f) => (f as Map)['id'] as String?)
          .whereType<String>()
          .toSet();
      final existingFolderIds = remote.folderName.keys.toList();

      for (final id in existingFolderIds) {
        if (localFolderIds.contains(id)) continue;
        await _deleteController.deleteFolder(userId, id);
      }

      for (final f in folders) {
        final map = f as Map<String, dynamic>;
        final fid = map['id'] as String?;
        if (fid == null) continue;
        final localName = map['name']?.toString() ?? '';
        final localPids = (map['playlistIds'] as List<dynamic>? ?? [])
            .map((e) => e.toString())
            .toList();
        final remoteName = remote.folderName[fid];
        final remotePids = remote.folderPlaylistIds[fid] ?? [];
        final isNew = remoteName == null;
        final isChanged = !isNew &&
            (remoteName != localName ||
                !SupabaseMappers.listEquals(remotePids, localPids));
        if (!isNew && !isChanged) continue;

        await _updateController.upsertFolder(userId, map);
        await _deleteController.deleteFolderPlaylists(userId, fid);
        final pids = (map['playlistIds'] as List<dynamic>? ?? [])
            .map((e) => e.toString())
            .toList();
        await _createController.insertFolderPlaylists(userId, fid, pids);
      }

      final likedSongs = data['likedSongs'] as List<dynamic>? ?? [];
      await _deleteController.deleteAllLikedSongs(userId);
      if (likedSongs.isNotEmpty) {
        final rows =
            likedSongs.map((s) => Map<String, dynamic>.from(s as Map)).toList();
        await _createController.insertLikedSongs(userId, rows);
      }

      final followedArtists = data['followedArtists'] as List<dynamic>? ?? [];
      await _deleteController.deleteAllFollowedArtists(userId);
      if (followedArtists.isNotEmpty) {
        final rows = followedArtists
            .map((a) => Map<String, dynamic>.from(a as Map))
            .toList();
        await _createController.insertFollowedArtists(userId, rows);
      }

      final followedAlbums = data['followedAlbums'] as List<dynamic>? ?? [];
      await _deleteController.deleteAllFollowedAlbums(userId);
      if (followedAlbums.isNotEmpty) {
        final rows = followedAlbums
            .map((a) => Map<String, dynamic>.from(a as Map))
            .toList();
        await _createController.insertFollowedAlbums(userId, rows);
      }
    } catch (_) {}
  }

  /// Fetches recently played for [userId].
  Future<List<Map<String, dynamic>>?> fetchRecentlyPlayed(
          String userId) async =>
      _getController.fetchRecentlyPlayed(userId);

  /// Replaces recently played for [userId] with [songs].
  Future<void> pushRecentlyPlayed(
      String userId, List<Map<String, dynamic>> songs) async {
    try {
      await _deleteController.deleteAllRecentlyPlayed(userId);
      await _createController.insertRecentlyPlayed(userId, songs);
    } catch (_) {}
  }

  /// Fetches playback settings for [userId].
  Future<Map<String, dynamic>?> fetchPlaybackSettings(String userId) async =>
      _getController.fetchPlaybackSettings(userId);

  /// Pushes playback [settings] for [userId].
  Future<void> pushPlaybackSettings(
          String userId, Map<String, dynamic> settings) async =>
      _updateController.upsertPlaybackSettings(userId, settings);

  /// Fetches recent searches for [userId].
  Future<List<String>?> fetchRecentSearches(String userId) async =>
      _getController.fetchRecentSearches(userId);

  /// Replaces recent searches for [userId] with [queries].
  Future<void> pushRecentSearches(String userId, List<String> queries) async {
    try {
      await _deleteController.deleteAllRecentSearches(userId);
      await _createController.insertRecentSearches(userId, queries);
    } catch (_) {}
  }

  /// Fetches downloaded song IDs for [userId].
  Future<List<String>?> fetchDownloadedSongIds(String userId) async =>
      _getController.fetchDownloadedSongIds(userId);

  /// Replaces downloaded song IDs for [userId] with [ids].
  Future<void> pushDownloadedSongIds(String userId, List<String> ids) async {
    try {
      await _deleteController.deleteAllDownloadedSongIds(userId);
      await _createController.insertDownloadedSongIds(userId, ids);
    } catch (_) {}
  }

  /// Fetches YT personalization for [userId].
  Future<Map<String, dynamic>?> fetchYtPersonalization(String userId) async =>
      _getController.fetchYtPersonalization(userId);

  /// Pushes YT personalization [data] for [userId].
  Future<void> pushYtPersonalization(
          String userId, Map<String, dynamic> data) async =>
      _updateController.upsertYtPersonalization(userId, data);
}
