/// Centralised YouTube/InnerTube constants for hosts, client information and
/// default values used across the scrapper package.
class YtConstants {
  YtConstants._();

  // --- Hosts & origins ---
  static const String innertubeHost = 'https://music.youtube.com';
  static const String webPlayerHost = 'https://www.youtube.com';
  static const String originMusic = innertubeHost;
  static const String originMusicSlash = '$innertubeHost/';
  static const String originYoutube = webPlayerHost;
  static const String originYoutubeSlash = '$webPlayerHost/';

  // --- InnerTube (Music) ---
  static const String innertubeClientName = 'WEB_REMIX';
  static const String innertubeUserAgent =
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 '
      '(KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36';

  // --- Search filters ---
  /// InnerTube `params` value that filters search results to Songs only.
  static const String searchFilterSongs = 'EgWKAQIIAWoKEAkQBRAKEAMQBA%3D%3D';
  
  /// InnerTube `params` value that filters search results to Podcasts only.
  static const String searchFilterPodcasts = 'EgWKAQJQAWoSEAMQBBAFEBAQCRAKEBUQDhAR';
  
  /// InnerTube `params` value that filters search results to Episodes only.
  static const String searchFilterEpisodes = 'EgWKAQJQAWoSEAMQBBAFEBAQCRAKEBUQDhAR';
  
  /// InnerTube `params` value that filters search results to Audiobooks only.
  /// Note: Using same as podcasts filter for now - will update with correct value when available
  static const String searchFilterAudiobooks = 'EgWKAQJQAWoSEAMQBBAFEBAQCRAKEBUQDhAR';

  // --- Player ---
  static const int playerSignatureTimestamp = 20515;

  // --- Stream & cache ---
  static const Duration streamCacheDuration = Duration(hours: 3);
  static const int streamCacheMaxEntries = 100;

  // --- User agents ---
  static const String androidPlaybackUserAgent =
      'Mozilla/5.0 (Linux; Android 13) AppleWebKit/537.36 (KHTML, like Gecko) '
      'Chrome/120.0.0.0 Mobile Safari/537.36';
}
