import 'package:http/http.dart' as http;

import 'package:tunify_source_youtube_music/constants/youtube_constants.dart';
import 'package:tunify_source_youtube_music/shared/shared_headers.dart';
import 'package:tunify_source_youtube_music/youtube_music/client/yt_music_client.dart';
import 'package:tunify_source_youtube_music/youtube_music/formatters/player_formatter.dart';

/// Wrapper around the YouTube Music `player` endpoint and related tracking
/// URLs.
class PlayerApi {
  final YTMusicClient _client;

  /// Creates a new [PlayerApi] bound to the provided [client].
  PlayerApi({required YTMusicClient client}) : _client = client;

  /// Fetches and parses the `player` response for the given [videoId].
  ///
  /// The optional [cpn] (client playback nonce) is forwarded so that YouTube
  /// can correlate player responses with stats tracking calls. When the
  /// primary music player response does not contain loudness information this
  /// method performs a fallback request against [YtConstants.webPlayerHost]
  /// and merges any loudness values that can be found.
  ///
  /// The returned map contains a `track` entry, a `metadata` map and any
  /// `playbackTracking` block from the raw response when available. On error
  /// an empty map is returned.
  Future<Map<String, dynamic>> fetchPlayer(String videoId,
      {String? cpn}) async {
    try {
      final payload = _client.basePayload();
      payload['videoId'] = videoId;
      payload['contentCheckOk'] = true;
      payload['racyCheckOk'] = true;
      if (cpn != null && cpn.isNotEmpty) payload['cpn'] = cpn;
      payload['playbackContext'] = {
        'contentPlaybackContext': {
          'signatureTimestamp': YtConstants.playerSignatureTimestamp,
          'html5Preference': 'HTML5_PREF_WANTS',
        }
      };

      final data = await _client.post('player', payload);
      final result = PlayerFormatter.parsePlayerResponse(data);

      final tracking = data['playbackTracking'] as Map<String, dynamic>?;
      if (tracking != null) {
        result['playbackTracking'] = tracking;
      }

      if (result['metadata']?['loudnessDb'] == null) {
        final webData = await _fetchWebPlayer(videoId);
        if (webData != null) {
          final webResult = PlayerFormatter.parsePlayerResponse(webData);
          if (webResult['metadata']?['loudnessDb'] != null) {
            result['metadata']['loudnessDb'] =
                webResult['metadata']['loudnessDb'];
          }
        }
      }

      return result;
    } catch (e) {
      return {};
    }
  }

  Future<Map<String, dynamic>?> _fetchWebPlayer(String videoId) async {
    try {
      final payload = _client.basePayload();
      payload['videoId'] = videoId;
      return await _client.post(
        'player',
        payload,
        host: YtConstants.webPlayerHost,
      );
    } catch (_) {
      return null;
    }
  }

  /// Reports accumulated playback watch‑time to YouTube's stats endpoint.
  ///
  /// The [atrUrl] and [cpn] are taken from the `playbackTracking` section of
  /// a player response. [playbackSeconds] indicates the elapsed playback
  /// duration, and [lengthSeconds] can be supplied to report the total track
  /// length. When [visitorData], [sessionCookies] or [clientVersion] are
  /// provided they are forwarded as headers to better match browser traffic.
  static Future<void> reportWatchtime(
    String atrUrl,
    String cpn,
    int playbackSeconds, {
    String? visitorData,
    String? sessionCookies,
    String? clientVersion,
    int? lengthSeconds,
  }) async {
    try {
      final uri = Uri.parse(atrUrl);
      final params = Map<String, String>.from(uri.queryParameters);
      params['cpn'] = cpn;
      params['et'] = playbackSeconds.toString();
      params['st'] = '0';
      params['state'] = 'playing';
      if (lengthSeconds != null) params['len'] = lengthSeconds.toString();
      params['ver'] = '2';
      params['c'] = YtConstants.innertubeClientName;
      if (clientVersion != null) params['cver'] = clientVersion;
      final fullUrl = uri.replace(queryParameters: params);
      await http.get(fullUrl,
          headers: _trackingHeaders(visitorData, sessionCookies));
    } catch (_) {}
  }

  /// Reports the start of playback using `videostatsPlaybackUrl`.
  ///
  /// This call mirrors the browser behaviour where `len=0` signals that
  /// playback has just started. Optional [visitorData], [sessionCookies] and
  /// [clientVersion] are forwarded as headers for better parity with the web
  /// client.
  static Future<void> reportPlaybackStart(
    String videostatsPlaybackUrl,
    String cpn, {
    String? visitorData,
    String? sessionCookies,
    String? clientVersion,
  }) async {
    try {
      final uri = Uri.parse(videostatsPlaybackUrl);
      final params = Map<String, String>.from(uri.queryParameters);
      params['cpn'] = cpn;
      params['len'] = '0';
      params['ver'] = '2';
      params['c'] = YtConstants.innertubeClientName;
      if (clientVersion != null) params['cver'] = clientVersion;
      final fullUrl = uri.replace(queryParameters: params);
      await http.get(fullUrl,
          headers: _trackingHeaders(visitorData, sessionCookies));
    } catch (_) {}
  }

  /// Reports `ptracking` events for a playback session.
  ///
  /// The [ptrackingUrl] and [cpn] parameters come from the `player` response.
  /// Optional [visitorData] and [sessionCookies] are forwarded as HTTP
  /// headers.
  static Future<void> reportPtracking(
    String ptrackingUrl,
    String cpn, {
    String? visitorData,
    String? sessionCookies,
  }) async {
    try {
      final uri = Uri.parse(ptrackingUrl);
      final params = Map<String, String>.from(uri.queryParameters);
      params['cpn'] = cpn;
      final fullUrl = uri.replace(queryParameters: params);
      await http.get(fullUrl,
          headers: _trackingHeaders(visitorData, sessionCookies));
    } catch (_) {}
  }

  static Map<String, String> _trackingHeaders(
          String? visitorData, String? sessionCookies) =>
      {
        ...SharedHeaders.youtubePlaybackHeaders,
        'Referer': YtConstants.originMusicSlash,
        'Origin': YtConstants.originMusic,
        if (visitorData != null && visitorData.isNotEmpty)
          'X-Goog-Visitor-Id': visitorData,
        if (sessionCookies != null && sessionCookies.isNotEmpty)
          'Cookie': sessionCookies,
      };
}
