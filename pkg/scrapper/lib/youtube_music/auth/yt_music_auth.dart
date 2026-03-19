import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:scrapper/constants/youtube_constants.dart';

/// Authentication bundle for YouTube Music requests derived from a logged‑in
/// browser session.
///
/// The combination of [sapisid] and [cookie] is used to generate the
/// `SAPISIDHASH` authorization header required for authenticated InnerTube
/// calls against [YtConstants.innertubeHost].
class YTMusicAuth {
  /// Raw SAPISID value extracted from the browser cookies.
  final String sapisid;

  /// Full cookie header string to be sent with authenticated requests.
  final String cookie;

  /// Creates an immutable [YTMusicAuth] instance.
  const YTMusicAuth({required this.sapisid, required this.cookie});

  String get _authorizationHeader {
    final timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final input = '$timestamp $sapisid ${YtConstants.innertubeHost}';
    final hash = sha1.convert(utf8.encode(input));
    return 'SAPISIDHASH ${timestamp}_$hash';
  }

  /// HTTP headers that must be attached to authenticated InnerTube requests.
  ///
  /// Includes the computed `Authorization` header, the raw [cookie] value, and
  /// origin headers that mimic the logged‑in YouTube Music web client.
  Map<String, String> get headers => {
        'Authorization': _authorizationHeader,
        'Cookie': cookie,
        'X-Goog-AuthUser': '0',
        'X-Origin': YtConstants.innertubeHost,
      };
}
