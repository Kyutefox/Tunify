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
  static const String prefsPlaybackSpeed = 'playback_speed';
  static const String prefsBassBoostLevel = 'bass_boost_level';
  /// Hive box key: persisted queue as JSON list (max 50 items).
  static const String hiveKeyQueue = 'queue';
  /// Hive box key: current index within the persisted queue.
  static const String hiveKeyQueueIndex = 'queue_index';
  /// Hive box key: active shuffle mode int (0=none, 2=smart).
  static const String hiveKeyActiveShuffleMode = 'active_shuffle_mode';
  /// Hive box key: list of smart-shuffle song IDs (✨ recs).
  static const String hiveKeySmartShuffleIds = 'smart_shuffle_ids';

}
