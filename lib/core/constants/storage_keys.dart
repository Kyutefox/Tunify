/// Centralized keys for SharedPreferences.
/// Use these instead of string literals to avoid typos and simplify renames.
abstract final class StorageKeys {
  StorageKeys._();

  // ——— SharedPreferences: YouTube InnerTube config ———
  static const String prefsYtApiKey = 'yt_api_key';
  static const String prefsYtClientVersion = 'yt_client_version';

  // ——— SharedPreferences: player ———
  static const String prefsLastPlayedPositionMs = 'last_played_position_ms';
  static const String prefsLastPlayedDurationMs = 'last_played_duration_ms';
  static const String prefsLastQueueSource = 'last_queue_source';
  static const String prefsLastPlaylistId = 'last_playlist_id';
  static const String prefsVolumeNormalization = 'volume_normalization_enabled';

  // ——— SharedPreferences: migration keys (read-once then deleted) ———
  /// Legacy home feed cache — read during Hive migration, then removed from SharedPreferences.
  static const String prefsHomeFeedCache = 'home_feed_cache';
  /// Legacy last-played song JSON — read during Hive migration, then removed from SharedPreferences.
  static const String prefsLastPlayedSong = 'last_played_song';
}
