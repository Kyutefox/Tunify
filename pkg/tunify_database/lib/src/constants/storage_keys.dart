/// Supabase table names; must match migrations/supabase_schema.sql.
abstract final class StorageKeys {
  StorageKeys._();
  static const String supabaseUserLibrary = 'user_library_settings';
  static const String supabaseUserRecentlyPlayed = 'user_recently_played';
  static const String supabaseUserPlaylists = 'user_playlists';
  static const String supabaseUserPlaylistTracks = 'user_playlist_tracks';
  static const String supabaseUserFolders = 'user_folders';
  static const String supabaseUserFolderPlaylists = 'user_folder_playlists';
  static const String supabaseUserLikedSongs = 'user_liked_songs';
  static const String supabaseUserPlaylistShuffle = 'user_playlist_shuffle';
  static const String supabaseUserPlaybackSettings = 'user_playback_settings';
  static const String supabaseUserRecentSearches = 'user_recent_searches';
  static const String supabaseYtPersonalization = 'yt_personalization';
  static const String supabaseUserDownloadedSongs = 'user_downloaded_songs';
  static const String supabaseUserFollowedArtists = 'user_followed_artists';
  static const String supabaseUserFollowedAlbums = 'user_followed_albums';
}

/// Playback setting keys (stored in SQLite settings table and Supabase).
abstract final class PlaybackSettingKeys {
  PlaybackSettingKeys._();
  static const String volumeNormalization = 'volume_normalization_enabled';
  static const String showExplicitContent = 'show_explicit_content';
  static const String smartRecommendationShuffle = 'smart_recommendation_shuffle';
  static const String crossfadeDurationSeconds = 'crossfade_duration_seconds';
  static const String gaplessPlayback = 'gapless_playback';
}
