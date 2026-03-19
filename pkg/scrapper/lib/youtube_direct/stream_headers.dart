import 'package:scrapper/shared/shared_headers.dart';

/// Convenience getter exposing default stream request headers for direct
/// `googlevideo.com` playback requests.
///
/// These headers intentionally omit a `User-Agent` so callers can provide
/// their own UA string when required.
Map<String, String> get streamHeaders => SharedHeaders.streamHeaders;

/// Convenience getter exposing default playback headers for YouTube video
/// requests, including an Android `User-Agent`.
///
/// This is useful when simulating the mobile YouTube client in tracking
/// or playback calls.
Map<String, String> get youtubePlaybackHeaders =>
    SharedHeaders.youtubePlaybackHeaders;
