import 'music_source.dart';

/// Playable stream metadata returned by a [MusicStreamBackend].
class ResolvedStream {
  const ResolvedStream({
    required this.url,
    required this.bitrate,
    required this.qualityLabel,
    required this.headers,
    this.durationMs = 0,
    this.mimeType = '',
    this.transport = StreamTransport.http,
    this.localPath,
    this.source = MusicSource.youtubeMusic,
  });

  final String url;
  final int bitrate;

  /// Human-readable quality (e.g. Low / Medium / High) for UI and persistence.
  final String qualityLabel;
  final Map<String, String> headers;
  final int durationMs;
  final String mimeType;
  final StreamTransport transport;
  final String? localPath;
  final MusicSource source;
}

enum StreamTransport {
  http,
  localFile,
}

/// Thrown when stream resolution fails for the given [TrackRef].
class MusicStreamResolveException implements Exception {
  MusicStreamResolveException(this.message, {this.code});

  final String message;
  final String? code;

  @override
  String toString() => 'MusicStreamResolveException: $message';
}
