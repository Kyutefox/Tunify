import 'dart:convert';
import 'package:http/http.dart' as http;

import 'package:scrapper/constants/youtube_constants.dart';
import 'package:scrapper/youtube_music/auth/yt_music_auth.dart';
import 'package:scrapper/youtube_music/client/yt_music_headers.dart';
import 'package:scrapper/youtube_music/client/yt_music_payload.dart';

/// Low-level HTTP client for the YouTube Music InnerTube API.
///
/// This wraps request construction, headers, cookies and dynamic configuration
/// such as `visitorData`, locales and client version.
class YTMusicClient {
  static String get host => YtConstants.innertubeHost;

  /// Optional callback invoked whenever a new `visitorData` token is observed
  /// in a response.
  final void Function(String? visitorData)? onVisitorDataReceived;
  String? _visitorData;
  final String? _apiKey;
  final String? _clientVersion;
  final String? _gl;
  final String? _hl;
  final YTMusicAuth? _auth;

  String? sessionCookies;

  /// Creates a new [YTMusicClient] instance with optional configuration
  /// values obtained from [VisitorDataFetcher] or another bootstrap source.
  ///
  /// When [visitorData], [apiKey], [clientVersion], [gl] or [hl] are empty
  /// strings they are treated as `null` so the client can fall back to
  /// server‑side defaults.
  YTMusicClient({
    this.onVisitorDataReceived,
    String? visitorData,
    String? apiKey,
    String? clientVersion,
    String? gl,
    String? hl,
    YTMusicAuth? auth,
    this.sessionCookies,
  })  : _visitorData = visitorData,
        _apiKey = apiKey?.isNotEmpty == true ? apiKey : null,
        _clientVersion =
            clientVersion?.isNotEmpty == true ? clientVersion : null,
        _gl = gl?.isNotEmpty == true ? gl : null,
        _hl = hl?.isNotEmpty == true ? hl : null,
        _auth = auth;

  String? get visitorData => _visitorData;
  String? get clientVersion => _clientVersion;

  /// Geographic locale reported by YouTube (for example `NP`).
  String? get gl => _gl;

  /// Language locale reported by YouTube (for example `en`).
  String? get hl => _hl;

  /// Updates the current `visitorData` token.
  void setVisitorData(String? value) {
    _visitorData = value?.isNotEmpty == true ? value : null;
  }

  /// Builds a minimal InnerTube `context` payload using the current client
  /// configuration.
  ///
  /// This is convenient for endpoints that expect only a generic context
  /// without additional fields.
  Map<String, dynamic> context() => YTMusicPayload.buildContext(
        hl: _hl,
        gl: _gl,
        visitorData: _visitorData,
        clientVersion: _clientVersion,
      );

  /// Builds a base request payload containing the standard [context] block.
  ///
  /// Callers can mutate the returned map to add endpoint‑specific fields
  /// before passing it to [post].
  Map<String, dynamic> basePayload() => YTMusicPayload.buildBasePayload(
        hl: _hl,
        gl: _gl,
        visitorData: _visitorData,
        clientVersion: _clientVersion,
      );

  /// Issues a POST request to the given InnerTube [endpoint] with the
  /// provided [body] and returns the decoded JSON payload.
  ///
  /// The [host] and [apiKey] parameters allow overriding the default
  /// [YtConstants.innertubeHost] or API key for special cases such as the
  /// web player host. The [body] map is cloned before being encoded so
  /// continuations and other fields can be safely removed or transformed.
  Future<Map<String, dynamic>> post(
    String endpoint,
    Map<String, dynamic> body, {
    String? host,
    String? apiKey,
  }) async {
    final requestBody = Map<String, dynamic>.from(body);

    final effectiveApiKey = apiKey ?? _apiKey;
    final query = <String, String>{
      'prettyPrint': 'false',
      if (effectiveApiKey != null) 'key': effectiveApiKey,
    };

    if (endpoint == 'browse') {
      final continuation = requestBody.remove('continuation') as String?;
      if (continuation != null && continuation.isNotEmpty) {
        query['continuation'] = continuation;
        query['ctoken'] = continuation;
        query['type'] = 'next';
      }
    }

    final uri = Uri.parse('${host ?? YTMusicClient.host}/youtubei/v1/$endpoint')
        .replace(queryParameters: query);

    final response = await http.post(
      uri,
      headers: {
        ...YTMusicHeaders.baseHeaders,
        if (_clientVersion != null) 'X-YouTube-Client-Version': _clientVersion,
        if (_visitorData != null) 'X-Goog-Visitor-Id': _visitorData!,
        if (sessionCookies != null && sessionCookies!.isNotEmpty)
          'Cookie': sessionCookies!,
        if (host != null) 'Origin': host,
        if (host != null) 'Referer': '$host/',
        if (_auth != null) ..._auth.headers,
      },
      body: jsonEncode(requestBody),
    );

    if (response.statusCode != 200) {
      throw Exception(
          'YouTube API Error ${response.statusCode}: ${response.body}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    _parseAndStoreVisitorData(data);
    return data;
  }

  void _parseAndStoreVisitorData(Map<String, dynamic> data) {
    try {
      final responseContext = data['responseContext'] as Map<String, dynamic>?;
      if (responseContext == null) return;
      final vd = responseContext['visitorData'] as String?;
      if (vd == null || vd.isEmpty || vd == _visitorData) return;
      _visitorData = vd;
      onVisitorDataReceived?.call(vd);
    } catch (_) {}
  }
}
