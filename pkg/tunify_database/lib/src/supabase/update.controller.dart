import 'package:supabase_flutter/supabase_flutter.dart';

import '../constants/storage_keys.dart' show PlaybackSettingKeys, StorageKeys;

/// Supabase update/upsert operations. All update logic lives in this controller.
class SupabaseUpdateController {
  SupabaseUpdateController(this._client);

  final SupabaseClient _client;

  /// Upserts library settings row for [userId] from [data].
  Future<void> upsertLibrarySettings(
      String userId, Map<String, dynamic> data) async {
    await _client.from(StorageKeys.supabaseUserLibrary).upsert({
      'user_id': userId,
      'sort_order': data['sortOrder'] ?? 'recent',
      'view_mode': data['viewMode'] ?? 'list',
      'liked_shuffle': data['likedShuffleEnabled'] == true,
      'downloaded_shuffle': data['downloadedShuffleEnabled'] == true,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }, onConflict: 'user_id');
  }

  /// Upserts a single playlist row for [userId] from [map].
  Future<void> upsertPlaylist(String userId, Map<String, dynamic> map) async {
    final pid = map['id'] as String?;
    if (pid == null) return;
    await _client.from(StorageKeys.supabaseUserPlaylists).upsert({
      'user_id': userId,
      'id': pid,
      'name': map['name'] ?? '',
      'description': map['description'] ?? '',
      'sort_order': map['sort_order'] ?? 'customOrder',
      'custom_image_url': map['custom_image_url'],
      'is_pinned': map['is_pinned'] == true,
      'created_at': map['created_at'],
      'updated_at': map['updated_at'],
    }, onConflict: 'user_id,id');
  }

  /// Upserts shuffle setting for [playlistId] under [userId].
  Future<void> upsertPlaylistShuffle(
      String userId, String playlistId, bool enabled) async {
    await _client.from(StorageKeys.supabaseUserPlaylistShuffle).upsert({
      'user_id': userId,
      'playlist_id': playlistId,
      'shuffle_enabled': enabled,
    }, onConflict: 'user_id,playlist_id');
  }

  /// Upserts a single folder row for [userId] from [map].
  Future<void> upsertFolder(String userId, Map<String, dynamic> map) async {
    final fid = map['id'] as String?;
    if (fid == null) return;
    await _client.from(StorageKeys.supabaseUserFolders).upsert({
      'user_id': userId,
      'id': fid,
      'name': map['name'] ?? '',
      'created_at': map['created_at'],
      'is_pinned': map['is_pinned'] == true,
    }, onConflict: 'user_id,id');
  }

  /// Upserts playback settings row for [userId] from [settings].
  Future<void> upsertPlaybackSettings(
      String userId, Map<String, dynamic> settings) async {
    await _client.from(StorageKeys.supabaseUserPlaybackSettings).upsert({
      'user_id': userId,
      'volume_normalization':
          settings[PlaybackSettingKeys.volumeNormalization] as bool? ?? false,
      'show_explicit_content':
          settings[PlaybackSettingKeys.showExplicitContent] as bool? ?? true,
      'smart_recommendation_shuffle':
          settings[PlaybackSettingKeys.smartRecommendationShuffle] as bool? ??
              true,
      'crossfade_duration_seconds':
          settings[PlaybackSettingKeys.crossfadeDurationSeconds] as int? ?? 0,
      'gapless_playback':
          settings[PlaybackSettingKeys.gaplessPlayback] as bool? ?? true,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }, onConflict: 'user_id');
  }

  /// Upserts YT personalization row for [userId] from [data].
  Future<void> upsertYtPersonalization(
      String userId, Map<String, dynamic> data) async {
    await _client.from(StorageKeys.supabaseYtPersonalization).upsert({
      'user_id': userId,
      'visitor_data': data['visitor_data']?.toString() ?? '',
      'api_key': data['api_key']?.toString(),
      'client_version': data['client_version']?.toString(),
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }, onConflict: 'user_id');
  }
}
