/// Single YouTube media stream (muxed, audio‑only, or video‑only).
class YouTubeStream {
  /// YouTube format tag identifying the stream variant.
  final int itag;

  /// Direct URL that can be used to download or play the stream.
  final String url;

  /// Human‑friendly quality name (for example `medium` or `high` for audio).
  final String? quality;

  /// Resolution label reported by YouTube (for example `1080p`).
  final String? qualityLabel;

  /// Nominal bitrate in kbps.
  final int? bitrate;

  /// MIME type string including container and codecs.
  final String mimeType;

  /// Video width in pixels, if available.
  final int? width;

  /// Video height in pixels, if available.
  final int? height;

  /// Stream duration, populated only when known.
  final Duration? duration;

  /// Content length in bytes, when reported by the manifest.
  final int? contentLength;

  /// Whether this stream carries audio only (no video track).
  final bool isAudioOnly;

  /// Creates a new [YouTubeStream] describing a single manifest format entry.
  YouTubeStream({
    required this.itag,
    required this.url,
    this.quality,
    this.qualityLabel,
    this.bitrate,
    required this.mimeType,
    this.width,
    this.height,
    this.duration,
    this.contentLength,
    this.isAudioOnly = false,
  });

  /// Serialises this stream to a JSON‑compatible map.
  ///
  /// This is useful for logging, persisting stream selections or returning
  /// stream metadata from an API layer.
  Map<String, dynamic> toJson() => {
        'itag': itag,
        'url': url,
        'quality': quality,
        'qualityLabel': qualityLabel,
        'bitrate': bitrate,
        'mimeType': mimeType,
        'width': width,
        'height': height,
        'durationMs': duration?.inMilliseconds,
        'contentLength': contentLength,
        'isAudioOnly': isAudioOnly,
      };
}
