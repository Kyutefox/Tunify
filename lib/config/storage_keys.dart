/// Centralized keys for SharedPreferences and Supabase table/column names.
/// Use these instead of string literals to avoid typos and simplify renames.
abstract final class StorageKeys {
  StorageKeys._();

  // ——— Supabase tables (normalized, row-wise; match migrations/supabase_schema.sql) ———
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

  // ——— SharedPreferences: YouTube InnerTube config ———
  static const String prefsYtApiKey = 'yt_api_key';
  static const String prefsYtClientVersion = 'yt_client_version';

  // ——— SharedPreferences: player ———
  static const String prefsLastPlayedSong = 'last_played_song';
  static const String prefsLastPlayedPositionMs = 'last_played_position_ms';
  static const String prefsLastPlayedDurationMs = 'last_played_duration_ms';
  static const String prefsLastQueueSource = 'last_queue_source';
  static const String prefsLastPlaylistId = 'last_playlist_id';
  static const String prefsVolumeNormalization = 'volume_normalization_enabled';

  // ——— SharedPreferences: home feed cache (on-disk for app start) ———
  static const String prefsHomeFeedCache = 'home_feed_cache';

  // ——— SharedPreferences: library cache (legacy) ———
  static const String prefsLibraryPlaylists = 'library_playlists';
  static const String prefsLibraryFolders = 'library_folders';
  static const String prefsLibraryLikedIds = 'library_liked_song_ids';
  static const String prefsLibrarySortOrder = 'library_sort_order';
  static const String prefsLibraryViewMode = 'library_view_mode';
}
