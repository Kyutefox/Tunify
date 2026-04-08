import 'package:supabase_flutter/supabase_flutter.dart';

import '../constants/storage_keys.dart';
import 'supabase_mappers.dart';

/// Supabase read operations. All fetch/get logic lives in this controller.
class SupabaseGetController {
  SupabaseGetController(this._client);

  final SupabaseClient _client;

  /// Fetches full library (playlists, folders, liked songs, settings) for [userId].
  Future<Map<String, dynamic>?> fetchLibraryData(String userId) async {
    try {
      final playlistsRows = await _client
          .from(StorageKeys.supabaseUserPlaylists)
          .select()
          .eq('user_id', userId);
      final tracksRows = await _client
          .from(StorageKeys.supabaseUserPlaylistTracks)
          .select()
          .eq('user_id', userId)
          .order('playlist_id')
          .order('position');
      final folderRows = await _client
          .from(StorageKeys.supabaseUserFolders)
          .select()
          .eq('user_id', userId);
      final junctionRows = await _client
          .from(StorageKeys.supabaseUserFolderPlaylists)
          .select()
          .eq('user_id', userId);
      final settingsRow = await _client
          .from(StorageKeys.supabaseUserLibrary)
          .select()
          .eq('user_id', userId)
          .maybeSingle();
      final likedRows = await _client
          .from(StorageKeys.supabaseUserLikedSongs)
          .select()
          .eq('user_id', userId)
          .order('position');
      final shuffleRows = await _client
          .from(StorageKeys.supabaseUserPlaylistShuffle)
          .select()
          .eq('user_id', userId);
      final followedArtistRows = await _client
          .from(StorageKeys.supabaseUserFollowedArtists)
          .select()
          .eq('user_id', userId)
          .order('followed_at');
      final followedAlbumRows = await _client
          .from(StorageKeys.supabaseUserFollowedAlbums)
          .select()
          .eq('user_id', userId)
          .order('followed_at');

      final folderIdToPlaylistIds = <String, List<String>>{};
      for (final r in junctionRows as List) {
        final map = Map<String, dynamic>.from(r as Map);
        final fid = map['folder_id'] as String?;
        final pid = map['playlist_id'] as String?;
        if (fid != null && pid != null) {
          folderIdToPlaylistIds.putIfAbsent(fid, () => []).add(pid);
        }
      }

      final playlistIdToTracks = <String, List<Map<String, dynamic>>>{};
      for (final r in tracksRows as List) {
        final map = Map<String, dynamic>.from(r as Map);
        final pid = map['playlist_id'] as String?;
        if (pid != null) {
          playlistIdToTracks
              .putIfAbsent(pid, () => [])
              .add(SupabaseMappers.trackRowToSongMap(map));
        }
      }

      final shuffleMap = <String, bool>{};
      for (final r in shuffleRows as List) {
        final map = Map<String, dynamic>.from(r as Map);
        final pid = map['playlist_id'] as String?;
        if (pid != null) {
          shuffleMap[pid] = map['shuffle_enabled'] as bool? ?? false;
        }
      }

      final playlists = <Map<String, dynamic>>[];
      for (final r in playlistsRows as List) {
        final map = Map<String, dynamic>.from(r as Map);
        final id = map['id'] as String?;
        if (id == null) continue;
        final tracks = playlistIdToTracks[id] ?? [];
        final createdAt = map['created_at'] as String? ?? '';
        final updatedAt = map['updated_at'] as String? ?? createdAt;
        playlists.add({
          'id': id,
          'name': map['name'] ?? '',
          'description': map['description'] ?? '',
          'sort_order': map['sort_order'] ?? 'customOrder',
          'songs': tracks,
          'created_at': createdAt,
          'updated_at': updatedAt,
          'custom_image_url': map['custom_image_url'],
          'is_pinned': map['is_pinned'] as bool? ?? false,
          'shuffleEnabled': shuffleMap[id] ?? false,
        });
      }

      final folders = <Map<String, dynamic>>[];
      for (final r in folderRows as List) {
        final map = Map<String, dynamic>.from(r as Map);
        final id = map['id'] as String?;
        if (id == null) continue;
        folders.add({
          'id': id,
          'name': map['name'] ?? '',
          'created_at': map['created_at'],
          'is_pinned': map['is_pinned'] as bool? ?? false,
          'playlistIds': folderIdToPlaylistIds[id] ?? [],
        });
      }

      var sortOrder = 'recent';
      var viewMode = 'list';
      var likedShuffleEnabled = false;
      var downloadedShuffleEnabled = false;
      if (settingsRow != null) {
        final s = Map<String, dynamic>.from(settingsRow);
        sortOrder = s['sort_order'] as String? ?? 'recent';
        viewMode = s['view_mode'] as String? ?? 'list';
        likedShuffleEnabled = s['liked_shuffle'] as bool? ?? false;
        downloadedShuffleEnabled = s['downloaded_shuffle'] as bool? ?? false;
      }

      final likedSongs = (likedRows as List)
          .map((r) => SupabaseMappers.trackRowToSongMap(
              Map<String, dynamic>.from(r as Map)))
          .toList();
      final playlistShuffles = <String, dynamic>{};
      for (final p in playlists) {
        if (p['shuffleEnabled'] == true) {
          playlistShuffles[p['id'] as String] = true;
        }
      }

      final followedArtists = (followedArtistRows as List).map((r) {
        final m = Map<String, dynamic>.from(r as Map);
        return {
          'id': m['artist_id'] ?? '',
          'name': m['name'] ?? '',
          'thumbnailUrl': m['thumbnail_url'] ?? '',
          'browseId': m['browse_id'],
          'followedAt': m['followed_at']?.toString(),
        };
      }).toList();

      final followedAlbums = (followedAlbumRows as List).map((r) {
        final m = Map<String, dynamic>.from(r as Map);
        return {
          'id': m['album_id'] ?? '',
          'title': m['title'] ?? '',
          'artistName': m['artist_name'] ?? '',
          'thumbnailUrl': m['thumbnail_url'] ?? '',
          'browseId': m['browse_id'],
          'followedAt': m['followed_at']?.toString(),
        };
      }).toList();

      return {
        'playlists': playlists,
        'folders': folders,
        'likedSongs': likedSongs,
        'sortOrder': sortOrder,
        'viewMode': viewMode,
        'likedShuffleEnabled': likedShuffleEnabled,
        'downloadedShuffleEnabled': downloadedShuffleEnabled,
        'playlistShuffles': playlistShuffles,
        'followedArtists': followedArtists,
        'followedAlbums': followedAlbums,
      };
    } catch (_) {
      return null;
    }
  }

  /// Fetches remote playlist and folder state for incremental push comparison.
  Future<
      ({
        Map<String, String> playlistUpdatedAt,
        Map<String, String> folderName,
        Map<String, List<String>> folderPlaylistIds,
      })> fetchRemoteLibraryStateForCompare(String userId) async {
    final existingPlaylists = await _client
        .from(StorageKeys.supabaseUserPlaylists)
        .select('id, updated_at')
        .eq('user_id', userId);
    final remotePlaylistUpdatedAt = <String, String>{};
    for (final r in existingPlaylists as List<dynamic>) {
      final m = r as Map;
      final id = m['id'] as String?;
      if (id != null) {
        remotePlaylistUpdatedAt[id] = m['updated_at']?.toString() ?? '';
      }
    }

    final existingFolders = await _client
        .from(StorageKeys.supabaseUserFolders)
        .select('id, name')
        .eq('user_id', userId);
    final junctionRows = await _client
        .from(StorageKeys.supabaseUserFolderPlaylists)
        .select('folder_id, playlist_id')
        .eq('user_id', userId);
    final remoteFolderPlaylistIds = <String, List<String>>{};
    for (final r in junctionRows as List<dynamic>) {
      final m = r as Map;
      final fid = m['folder_id'] as String?;
      final pid = m['playlist_id'] as String?;
      if (fid != null && pid != null) {
        (remoteFolderPlaylistIds.putIfAbsent(fid, () => [])).add(pid);
      }
    }
    final remoteFolderName = <String, String>{};
    for (final r in existingFolders as List<dynamic>) {
      final m = r as Map;
      final id = m['id'] as String?;
      if (id != null) {
        remoteFolderName[id] = m['name']?.toString() ?? '';
      }
    }

    return (
      playlistUpdatedAt: remotePlaylistUpdatedAt,
      folderName: remoteFolderName,
      folderPlaylistIds: remoteFolderPlaylistIds
    );
  }

  /// Fetches recently played songs for [userId] (up to 50).
  Future<List<Map<String, dynamic>>?> fetchRecentlyPlayed(String userId) async {
    try {
      final rows = await _client
          .from(StorageKeys.supabaseUserRecentlyPlayed)
          .select()
          .eq('user_id', userId)
          .order('played_at', ascending: false)
          .limit(50);
      return (rows as List).map((r) {
        final map = Map<String, dynamic>.from(r as Map);
        return {
          'id': map['song_id'],
          'title': map['title'] ?? '',
          'artist': map['artist'] ?? '',
          'thumbnailUrl': map['thumbnail_url'] ?? '',
          'durationSeconds': map['duration_seconds'] ?? 0,
          'lastPlayed': map['played_at'],
        };
      }).toList();
    } catch (_) {
      return null;
    }
  }

  /// Fetches playback settings for [userId].
  Future<Map<String, dynamic>?> fetchPlaybackSettings(String userId) async {
    try {
      final res = await _client
          .from(StorageKeys.supabaseUserPlaybackSettings)
          .select()
          .eq('user_id', userId)
          .maybeSingle();
      if (res == null) return null;
      return {
        PlaybackSettingKeys.volumeNormalization:
            res['volume_normalization'] as bool? ?? false,
        PlaybackSettingKeys.showExplicitContent:
            res['show_explicit_content'] as bool? ?? true,
        PlaybackSettingKeys.smartRecommendationShuffle:
            res['smart_recommendation_shuffle'] as bool? ?? true,
        PlaybackSettingKeys.crossfadeDurationSeconds:
            res['crossfade_duration_seconds'] as int? ?? 0,
        PlaybackSettingKeys.gaplessPlayback:
            res['gapless_playback'] as bool? ?? true,
      };
    } catch (_) {
      return null;
    }
  }

  /// Fetches recent search queries for [userId] (up to 20).
  Future<List<String>?> fetchRecentSearches(String userId) async {
    try {
      final rows = await _client
          .from(StorageKeys.supabaseUserRecentSearches)
          .select('query')
          .eq('user_id', userId)
          .order('searched_at', ascending: false)
          .limit(20);
      final list = rows as List<dynamic>?;
      if (list == null || list.isEmpty) return null;
      return list
          .map((r) => (r as Map)['query']?.toString())
          .where((s) => s != null && s.trim().isNotEmpty)
          .cast<String>()
          .toList();
    } catch (_) {
      return null;
    }
  }

  /// Fetches downloaded song IDs for [userId].
  Future<List<String>?> fetchDownloadedSongIds(String userId) async {
    try {
      final rows = await _client
          .from(StorageKeys.supabaseUserDownloadedSongs)
          .select('song_id')
          .eq('user_id', userId)
          .order('added_at', ascending: false);
      final list = rows as List<dynamic>?;
      if (list == null || list.isEmpty) return null;
      return list
          .map((r) => (r as Map)['song_id']?.toString())
          .where((s) => s != null && s.isNotEmpty)
          .cast<String>()
          .toList();
    } catch (_) {
      return null;
    }
  }

  /// Fetches YT personalization (visitor_data, api_key, client_version) for [userId].
  Future<Map<String, dynamic>?> fetchYtPersonalization(String userId) async {
    try {
      final res = await _client
          .from(StorageKeys.supabaseYtPersonalization)
          .select('visitor_data, api_key, client_version')
          .eq('user_id', userId)
          .maybeSingle();
      if (res == null) return null;
      return {
        'visitor_data': res['visitor_data']?.toString() ?? '',
        'api_key': res['api_key']?.toString(),
        'client_version': res['client_version']?.toString(),
      };
    } catch (_) {
      return null;
    }
  }
}
