import 'package:http/http.dart' as http;

import 'package:scrapper/constants/youtube_constants.dart';

/// Snapshot of configuration extracted from the YouTube Music web client.
///
/// This includes `visitorData`, API key, client version, cookies and
/// locale fields required to talk to the InnerTube API.
class SwJsData {
  /// Long‑form `VISITOR_DATA` token used for API calls.
  final String? visitorData;

  /// Shortened `VISITOR_DATA` token, when available.
  final String? shortVisitorData;

  /// InnerTube API key for the current web client.
  final String? apiKey;

  /// InnerTube client version for the current web client.
  final String? clientVersion;

  /// Session cookies collected during bootstrap.
  final String? sessionCookies;

  /// Geographic locale (GL) reported by YouTube (for example `US`).
  final String? gl;

  /// Language locale (HL) reported by YouTube (for example `en`).
  final String? hl;

  /// Creates an immutable snapshot of web bootstrap configuration.
  const SwJsData({
    this.visitorData,
    this.shortVisitorData,
    this.apiKey,
    this.clientVersion,
    this.sessionCookies,
    this.gl,
    this.hl,
  });
}

/// Helper for fetching and parsing YouTube Music bootstrap configuration.
///
/// This helper performs a two‑step, cookie‑aware fetch of the main page HTML
/// and extracts `visitorData`, API key, client version, cookies and locales.
class VisitorDataFetcher {
  static const String _mainPageUrl = YtConstants.innertubeHost;

  static const Map<String, String> _baseHeaders = {
    'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
    'Accept-Language': 'en-US,en;q=0.9',
    'User-Agent': YtConstants.innertubeUserAgent,
    'sec-fetch-dest': 'document',
    'sec-fetch-mode': 'navigate',
    'sec-fetch-site': 'none',
  };

  /// Fetches and parses configuration from the YouTube Music web client.
  ///
  /// The method emulates a browser visit to [YtConstants.innertubeHost],
  /// follows the initial cookie handshake when necessary and then parses the
  /// HTML for configuration fields. On error, an empty [SwJsData] snapshot is
  /// returned instead of throwing.
  static Future<SwJsData> fetch() async {
    try {
      final resp1 =
          await http.get(Uri.parse(_mainPageUrl), headers: _baseHeaders);
      if (resp1.statusCode != 200) return const SwJsData();

      final setCookieHeader1 = resp1.headers['set-cookie'] ?? '';
      final step1Cookies = _extractCookies(setCookieHeader1);
      final visitorInfoCookie = step1Cookies['VISITOR_INFO1_LIVE'];

      final String htmlBody;
      String? sessionCookies;

      if (visitorInfoCookie != null && visitorInfoCookie.isNotEmpty) {
        final step1CookieHeader =
            step1Cookies.entries.map((e) => '${e.key}=${e.value}').join('; ');
        final resp2 = await http.get(
          Uri.parse(_mainPageUrl),
          headers: {..._baseHeaders, 'Cookie': step1CookieHeader},
        );
        htmlBody = resp2.statusCode == 200 ? resp2.body : resp1.body;

        final setCookie2 = resp2.headers['set-cookie'] ?? '';
        final step2Cookies = _extractCookies(setCookie2);
        final allCookies = {...step1Cookies, ...step2Cookies};
        sessionCookies =
            allCookies.entries.map((e) => '${e.key}=${e.value}').join('; ');
      } else {
        htmlBody = resp1.body;
      }

      return _parse(htmlBody, sessionCookies: sessionCookies);
    } catch (_) {
      return const SwJsData();
    }
  }

  static Map<String, String> _extractCookies(String setCookieHeader) {
    final cookies = <String, String>{};
    final pattern = RegExp(
      r'(?:VISITOR_INFO1_LIVE|YSC|__Secure-ROLLOUT_TOKEN|VISITOR_PRIVACY_METADATA|__Secure-YNID)=([^;,\s]+)',
    );
    for (final m in pattern.allMatches(setCookieHeader)) {
      final full = m.group(0)!;
      final eq = full.indexOf('=');
      cookies[full.substring(0, eq)] = full.substring(eq + 1);
    }
    return cookies;
  }

  static SwJsData _parse(String body, {String? sessionCookies}) {
    try {
      String? visitorData;
      String? apiKey;
      String? clientVersion;
      String? gl;
      String? hl;

      final vdMatches =
          RegExp(r'"VISITOR_DATA"\s*:\s*"([^"]+)"').allMatches(body).toList();
      if (vdMatches.isNotEmpty) {
        vdMatches
            .sort((a, b) => a.group(1)!.length.compareTo(b.group(1)!.length));
        visitorData = vdMatches.first.group(1);
      }

      final keyMatch =
          RegExp(r'"INNERTUBE_API_KEY"\s*:\s*"([^"]+)"').firstMatch(body);
      if (keyMatch != null) apiKey = keyMatch.group(1);

      final verMatch = RegExp(r'"INNERTUBE_CLIENT_VERSION"\s*:\s*"([^"]+)"')
          .firstMatch(body);
      if (verMatch != null) clientVersion = verMatch.group(1);

      final glMatch = RegExp(r'"GL"\s*:\s*"([^"]+)"').firstMatch(body);
      if (glMatch != null) gl = glMatch.group(1);

      final hlMatch = RegExp(r'"HL"\s*:\s*"([^"]+)"').firstMatch(body);
      if (hlMatch != null) hl = hlMatch.group(1);

      return SwJsData(
        visitorData: visitorData?.isNotEmpty == true ? visitorData : null,
        shortVisitorData: visitorData?.isNotEmpty == true ? visitorData : null,
        apiKey: apiKey?.isNotEmpty == true ? apiKey : null,
        clientVersion: clientVersion?.isNotEmpty == true ? clientVersion : null,
        sessionCookies:
            sessionCookies?.isNotEmpty == true ? sessionCookies : null,
        gl: gl?.isNotEmpty == true ? gl : null,
        hl: hl?.isNotEmpty == true ? hl : null,
      );
    } catch (_) {
      return const SwJsData();
    }
  }
}
