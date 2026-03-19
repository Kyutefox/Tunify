import 'package:youtube_explode_dart/youtube_explode_dart.dart';

import 'package:scrapper/models/youtube_stream.dart';

/// Helpers to convert a `StreamManifest` into typed [YouTubeStream] objects.
class StreamFormatter {
  /// Flattens a [manifest] into a list of muxed, video‑only and audio‑only
  /// [YouTubeStream]s.
  ///
  /// The resulting list keeps the underlying order from the manifest while
  /// attaching derived properties such as human‑readable quality labels.
  static List<YouTubeStream> parseManifest(StreamManifest manifest) {
    final streams = <YouTubeStream>[];

    for (final s in [...manifest.muxed, ...manifest.videoOnly]) {
      final kbps = s.bitrate.kiloBitsPerSecond.round();
      streams.add(YouTubeStream(
        itag: s.tag,
        url: s.url.toString(),
        quality: s.videoQuality.name,
        qualityLabel: s.qualityLabel,
        bitrate: kbps,
        mimeType: s.codec.mimeType,
        width: s.videoResolution.width.round(),
        height: s.videoResolution.height.round(),
        duration: null,
        contentLength: null,
        isAudioOnly: false,
      ));
    }

    for (final s in manifest.audioOnly) {
      final kbps = s.bitrate.kiloBitsPerSecond.round();
      streams.add(YouTubeStream(
        itag: s.tag,
        url: s.url.toString(),
        quality: _categorizeAudioQuality(kbps),
        qualityLabel: '${kbps}kbps',
        bitrate: kbps,
        mimeType: s.codec.mimeType,
        width: null,
        height: null,
        duration: null,
        contentLength: null,
        isAudioOnly: true,
      ));
    }

    return streams;
  }

  static String _categorizeAudioQuality(int kbps) {
    if (kbps <= 80) return 'low';
    if (kbps <= 160) return 'medium';
    return 'high';
  }
}
