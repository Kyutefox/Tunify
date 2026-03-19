import 'package:youtube_explode_dart/youtube_explode_dart.dart';

import 'package:scrapper/youtube_direct/api/streams_api.dart';

export 'api/streams_api.dart';
export 'formatters/stream_formatter.dart';
export 'stream_headers.dart';

final List<YoutubeApiClient> _defaultStreamClients = [
  YoutubeApiClient.androidVr,
];

/// High‑level entrypoint for direct YouTube stream extraction using
/// `youtube_explode_dart`.
class YoutubeDirect {
  /// API used to resolve manifests and convert them into [YouTubeStream]s.
  final StreamsApi streams;

  /// Creates a [YoutubeDirect] instance with optional custom [apiClients].
  ///
  /// When [apiClients] is omitted, a sensible default set that imitates
  /// common YouTube clients is used.
  YoutubeDirect({
    List<YoutubeApiClient>? apiClients,
  }) : streams = StreamsApi(apiClients: apiClients ?? _defaultStreamClients);

  /// Closes any underlying HTTP resources created by this instance.
  void dispose() {
    streams.dispose();
  }
}
