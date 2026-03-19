import 'package:supabase_flutter/supabase_flutter.dart';

import '../constants/storage_keys.dart';

/// Supabase delete operations. All delete logic lives in this controller.
class SupabaseDeleteController {
  SupabaseDeleteController(this._client);

  final SupabaseClient _client;

  /// Deletes playlist [playlistId] and its tracks and shuffle row for [userId].
  Future<void> deletePlaylist(String userId, String playlistId) async {
    await _client.from(StorageKeys.supabaseUserPlaylistTracks).delete().eq('user_id', userId).eq('playlist_id', playlistId);
    await _client.from(StorageKeys.supabaseUserPlaylistShuffle).delete().eq('user_id', userId).eq('playlist_id', playlistId);
    await _client.from(StorageKeys.supabaseUserPlaylists).delete().eq('user_id', userId).eq('id', playlistId);
  }

  /// Deletes folder [folderId] and its folder_playlists for [userId].
  Future<void> deleteFolder(String userId, String folderId) async {
    await _client.from(StorageKeys.supabaseUserFolderPlaylists).delete().eq('user_id', userId).eq('folder_id', folderId);
    await _client.from(StorageKeys.supabaseUserFolders).delete().eq('user_id', userId).eq('id', folderId);
  }

  /// Deletes all track rows for [playlistId] under [userId].
  Future<void> deletePlaylistTracks(String userId, String playlistId) async {
    await _client.from(StorageKeys.supabaseUserPlaylistTracks).delete().eq('user_id', userId).eq('playlist_id', playlistId);
  }

  /// Deletes all folder_playlist rows for [folderId] under [userId].
  Future<void> deleteFolderPlaylists(String userId, String folderId) async {
    await _client.from(StorageKeys.supabaseUserFolderPlaylists).delete().eq('user_id', userId).eq('folder_id', folderId);
  }

  /// Deletes all recently-played rows for [userId].
  Future<void> deleteAllRecentlyPlayed(String userId) async {
    await _client.from(StorageKeys.supabaseUserRecentlyPlayed).delete().eq('user_id', userId);
  }

  /// Deletes all recent-search rows for [userId].
  Future<void> deleteAllRecentSearches(String userId) async {
    await _client.from(StorageKeys.supabaseUserRecentSearches).delete().eq('user_id', userId);
  }

  /// Deletes all downloaded-song rows for [userId].
  Future<void> deleteAllDownloadedSongIds(String userId) async {
    await _client.from(StorageKeys.supabaseUserDownloadedSongs).delete().eq('user_id', userId);
  }

  /// Deletes all liked-songs rows for [userId].
  Future<void> deleteAllLikedSongs(String userId) async {
    await _client.from(StorageKeys.supabaseUserLikedSongs).delete().eq('user_id', userId);
  }

  /// Deletes all followed-artist rows for [userId].
  Future<void> deleteAllFollowedArtists(String userId) async {
    await _client.from(StorageKeys.supabaseUserFollowedArtists).delete().eq('user_id', userId);
  }

  /// Deletes all followed-album rows for [userId].
  Future<void> deleteAllFollowedAlbums(String userId) async {
    await _client.from(StorageKeys.supabaseUserFollowedAlbums).delete().eq('user_id', userId);
  }
}
