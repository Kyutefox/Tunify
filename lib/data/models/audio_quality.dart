/// User-selectable audio quality tier.
enum AudioQuality {
  low,

  medium,

  high,

  /// Automatically selects the highest available quality.
  auto,
}

extension AudioQualityExtension on AudioQuality {
  /// Human-readable label shown in the quality picker UI.
  String get label {
    switch (this) {
      case AudioQuality.low:
        return 'Low';
      case AudioQuality.medium:
        return 'Medium';
      case AudioQuality.high:
        return 'High';
      case AudioQuality.auto:
        return 'Auto';
    }
  }

}

/// A resolved audio stream URL with its codec, bitrate, and request headers.
class AudioStream {
  final String url;
  final int bitrate;
  final AudioQuality quality;
  final String codec;
  final Map<String, String> headers;

  const AudioStream({
    required this.url,
    required this.bitrate,
    required this.quality,
    required this.codec,
    this.headers = const {},
  });

  @override
  String toString() => 'AudioStream(${quality.label}: ${bitrate}kbps, $codec)';
}

/// Holds up to three quality variants of a resolved stream for a single track.
///
/// Streams expire after ~6 hours on YouTube's CDN; check [isExpired] before use.
class StreamResult {
  final String trackId;
  final AudioStream? lowQuality;
  final AudioStream? mediumQuality;
  final AudioStream? highQuality;
  final DateTime extractedAt;

  StreamResult({
    required this.trackId,
    this.lowQuality,
    this.mediumQuality,
    this.highQuality,
  }) : extractedAt = DateTime.now();

  /// Returns the best available stream for [quality], falling back to adjacent tiers.
  AudioStream? getStream(AudioQuality quality) {
    switch (quality) {
      case AudioQuality.high:
        return highQuality ?? mediumQuality ?? lowQuality;
      case AudioQuality.medium:
        return mediumQuality ?? lowQuality ?? highQuality;
      case AudioQuality.low:
        return lowQuality ?? mediumQuality ?? highQuality;
      case AudioQuality.auto:
        return mediumQuality ?? highQuality ?? lowQuality;
    }
  }

  /// Highest quality available regardless of user preference.
  AudioStream? get best => highQuality ?? mediumQuality ?? lowQuality;

  /// True when the stream URLs are older than 3 hours and likely expired on YouTube's CDN.
  bool get isExpired =>
      DateTime.now().difference(extractedAt) > const Duration(hours: 3);
}