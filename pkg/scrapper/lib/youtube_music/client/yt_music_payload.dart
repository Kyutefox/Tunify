import 'package:scrapper/constants/youtube_constants.dart';
import 'package:scrapper/youtube_music/client/yt_music_headers.dart';

/// Helpers for constructing request payloads for the YouTube Music
/// InnerTube API.
class YTMusicPayload {
  /// Builds a `context` block suitable for most YouTube Music InnerTube
  /// requests.
  ///
  /// Locale fields [hl] and [gl] as well as [visitorData] and
  /// [clientVersion] are only included when non‑empty, allowing YouTube
  /// to infer sensible defaults from the caller's IP when omitted.
  static Map<String, dynamic> buildContext({
    String? hl,
    String? gl,
    String? visitorData,
    String? clientVersion,
  }) {
    final client = <String, dynamic>{
      'clientName': YtConstants.innertubeClientName,
      // Always include a version — fall back to the hardcoded stable value so
      // YouTube routes the request correctly even before the live fetch completes.
      'clientVersion': (clientVersion != null && clientVersion.isNotEmpty)
          ? clientVersion
          : YtConstants.innertubeClientVersionFallback,
      'userAgent': YTMusicHeaders.userAgent,
    };
    // Only include locale fields when we have real values from the HTML fetch.
    // Omitting them lets YouTube infer locale from IP — better than hardcoding.
    if (hl != null && hl.isNotEmpty) client['hl'] = hl;
    if (gl != null && gl.isNotEmpty) client['gl'] = gl;
    if (visitorData != null && visitorData.isNotEmpty) {
      client['visitorData'] = visitorData;
    }
    return {
      'client': client,
      'request': {
        'internalExperimentFlags': <dynamic>[],
        'useSsl': true,
      },
      'user': {
        'lockedSafetyMode': false,
      },
    };
  }

  /// Builds a base InnerTube payload containing only the `context` block.
  ///
  /// Callers are expected to add endpoint‑specific fields to the returned
  /// map before sending it via [YTMusicClient.post].
  static Map<String, dynamic> buildBasePayload({
    String? hl,
    String? gl,
    String? visitorData,
    String? clientVersion,
  }) {
    return {
      'context': buildContext(
        hl: hl,
        gl: gl,
        visitorData: visitorData,
        clientVersion: clientVersion,
      ),
    };
  }
}
