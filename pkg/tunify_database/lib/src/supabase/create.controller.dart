import 'package:supabase_flutter/supabase_flutter.dart';

import '../constants/storage_keys.dart';
import 'supabase_mappers.dart';

/// Supabase insert operations. All create/insert logic lives in this controller.
class SupabaseCreateController {
  SupabaseCreateController(this._client);

  final SupabaseClient _client;

  /// Inserts playlist track rows for [playlistId] under [userId].
  Future<void> insertPlaylistTracks(
      String userId, String playlistId, List<Map<String, dynamic>> rows) async {
    if (rows.isEmpty) return;
    final mapped = <Map<String, dynamic>>[];
    for (var i = 0; i < rows.length; i++) {
      mapped.add(
          SupabaseMappers.songMapToTrackRow(userId, playlistId, i, rows[i]));
    }
    await _client.from(StorageKeys.supabaseUserPlaylistTracks).insert(mapped);
  }

  /// Inserts folder–playlist junction rows for [folderId] under [userId].
  Future<void> insertFolderPlaylists(
      String userId, String folderId, List<String> playlistIds) async {
    for (final pid in playlistIds) {
      await _client.from(StorageKeys.supabaseUserFolderPlaylists).insert({
        'user_id': userId,
        'folder_id': folderId,
        'playlist_id': pid,
      });
    }
  }

  /// Inserts liked-songs rows for [userId] (replaces semantics: call after delete-all).
  Future<void> insertLikedSongs(
      String userId, List<Map<String, dynamic>> likedSongs) async {
    if (likedSongs.isEmpty) return;
    final rows = <Map<String, dynamic>>[];
    for (var i = 0; i < likedSongs.length; i++) {
      final s = Map<String, dynamic>.from(likedSongs[i]);
      final durMs = s['durationMs'] as int? ?? 0;
      rows.add({
        'user_id': userId,
        'song_id': s['id'] ?? '',
        'position': i,
        'title': s['title'] ?? '',
        'artist': s['artist'] ?? '',
        'thumbnail_url': s['thumbnailUrl'] ?? '',
        'duration_seconds': durMs ~/ 1000,
        'album_name': s['albumName'],
        'artist_browse_id': s['artistBrowseId'],
        'album_browse_id': s['albumBrowseId'],
        'is_explicit': s['isExplicit'] as bool? ?? false,
        'added_at': DateTime.now().toUtc().toIso8601String(),
      });
    }
    await _client.from(StorageKeys.supabaseUserLikedSongs).insert(rows);
  }

  /// Inserts recently-played rows for [userId] (up to 50).
  Future<void> insertRecentlyPlayed(
      String userId, List<Map<String, dynamic>> songs) async {
    if (songs.isEmpty) return;
    final rows = songs
        .take(50)
        .map((s) => {
              'user_id': userId,
              'song_id': s['id'],
              'played_at': s['lastPlayed'],
              'title': s['title'] ?? '',
              'artist': s['artist'] ?? '',
              'thumbnail_url': s['thumbnailUrl'] ?? '',
              'duration_seconds': s['durationSeconds'] ?? 0,
            })
        .toList();
    await _client.from(StorageKeys.supabaseUserRecentlyPlayed).insert(rows);
  }

  /// Inserts recent-search rows for [userId] (up to 20).
  Future<void> insertRecentSearches(String userId, List<String> queries) async {
    if (queries.isEmpty) return;
    final now = DateTime.now().toUtc().toIso8601String();
    final rows = queries
        .take(20)
        .map((q) => {'user_id': userId, 'query': q, 'searched_at': now})
        .toList();
    await _client.from(StorageKeys.supabaseUserRecentSearches).insert(rows);
  }

  /// Inserts downloaded-song rows for [userId].
  Future<void> insertDownloadedSongIds(String userId, List<String> ids) async {
    if (ids.isEmpty) return;
    final now = DateTime.now().toUtc().toIso8601String();
    final rows = ids
        .map((id) => {'user_id': userId, 'song_id': id, 'added_at': now})
        .toList();
    await _client.from(StorageKeys.supabaseUserDownloadedSongs).insert(rows);
  }

  /// Inserts followed-artist rows for [userId] (call after delete-all).
  Future<void> insertFollowedArtists(
      String userId, List<Map<String, dynamic>> artists) async {
    if (artists.isEmpty) return;
    final rows = artists
        .map((a) => {
              'user_id': userId,
              'artist_id': a['id'] ?? '',
              'name': a['name'] ?? '',
              'thumbnail_url': a['thumbnailUrl'] ?? '',
              'browse_id': a['browseId'],
              'followed_at':
                  a['followedAt'] ?? DateTime.now().toUtc().toIso8601String(),
            })
        .toList();
    await _client.from(StorageKeys.supabaseUserFollowedArtists).insert(rows);
  }

  /// Inserts followed-album rows for [userId] (call after delete-all).
  Future<void> insertFollowedAlbums(
      String userId, List<Map<String, dynamic>> albums) async {
    if (albums.isEmpty) return;
    final rows = albums
        .map((a) => {
              'user_id': userId,
              'album_id': a['id'] ?? '',
              'title': a['title'] ?? '',
              'artist_name': a['artistName'] ?? '',
              'thumbnail_url': a['thumbnailUrl'] ?? '',
              'browse_id': a['browseId'],
              'followed_at':
                  a['followedAt'] ?? DateTime.now().toUtc().toIso8601String(),
            })
        .toList();
    await _client.from(StorageKeys.supabaseUserFollowedAlbums).insert(rows);
  }
}
