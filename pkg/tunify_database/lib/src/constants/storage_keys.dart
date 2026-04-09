/// Playback setting keys (stored in the SQLite settings table).
abstract final class PlaybackSettingKeys {
  PlaybackSettingKeys._();
  static const String volumeNormalization = 'volume_normalization_enabled';
  static const String showExplicitContent = 'show_explicit_content';
  static const String smartRecommendationShuffle =
      'smart_recommendation_shuffle';
  static const String crossfadeDurationSeconds = 'crossfade_duration_seconds';
  static const String gaplessPlayback = 'gapless_playback';
}
