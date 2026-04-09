import 'package:tunify_source_youtube_music/constants/youtube_constants.dart';

/// Shared HTTP header helpers used by YouTube Music and YouTube Direct clients.
///
/// These methods centralise common header construction so that crawler‑style
/// requests stay consistent with the real web clients and can be updated in
/// one place if YouTube changes expectations.
class SharedHeaders {
  SharedHeaders._();

  static const Map<String, String> _accept = {
    'Accept': '*/*',
    'Accept-Language': 'en-US,en;q=0.9',
  };

  /// Base headers for JSON API requests, including content type, [`Accept`]
  /// and origin fields.
  static Map<String, String> apiHeaders(String origin, String referer) => {
        'Content-Type': 'application/json',
        ..._accept,
        'Origin': origin,
        'Referer': referer,
        'User-Agent': YtConstants.innertubeUserAgent,
      };

  /// Headers for YouTube Music InnerTube calls against [YtConstants.innertubeHost].
  ///
  /// Note: `X-YouTube-Client-Version` is not included here and is instead
  /// injected per request by [YTMusicClient.post] using the dynamically
  /// discovered client version.
  static Map<String, String> get ytMusicApi => {
        ...apiHeaders(YtConstants.originMusic, YtConstants.originMusicSlash),
        'X-YouTube-Client-Name': YtConstants.innertubeClientName,
      };

  /// Headers for YouTube web (non‑music) InnerTube calls against
  /// [YtConstants.webPlayerHost].
  static Map<String, String> get ytDirectApi =>
      apiHeaders(YtConstants.originYoutube, YtConstants.originYoutubeSlash);

  /// Default headers for raw `googlevideo.com` stream playback.
  ///
  /// A `User-Agent` is intentionally omitted so callers can choose an
  /// appropriate value for their environment.
  static Map<String, String> get streamHeaders => {
        ..._accept,
        'Origin': YtConstants.originYoutube,
        'Referer': YtConstants.originYoutubeSlash,
      };

  /// Fallback headers for YouTube playback when the caller does not provide
  /// any, including a mobile Android `User-Agent`.
  static Map<String, String> get youtubePlaybackHeaders => {
        'User-Agent': YtConstants.androidPlaybackUserAgent,
        ..._accept,
        'Origin': YtConstants.originYoutube,
        'Referer': YtConstants.originYoutubeSlash,
      };
}
