import 'package:scrapper/constants/youtube_constants.dart';
import 'package:scrapper/shared/shared_headers.dart';

/// Convenience accessors for HTTP headers used by the YouTube Music API.
class YTMusicHeaders {
  /// User‑agent string that mimics the desktop YouTube Music web client.
  static String get userAgent => YtConstants.innertubeUserAgent;

  /// Base headers for InnerTube POST requests against [YtConstants.innertubeHost].
  ///
  /// These headers deliberately exclude `X-YouTube-Client-Version`, which is
  /// applied per request by [YTMusicClient] so that dynamic client versions
  /// from [VisitorDataFetcher] can be honoured.
  static Map<String, String> get baseHeaders => SharedHeaders.ytMusicApi;
}
