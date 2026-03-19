import 'package:youtube_explode_dart/youtube_explode_dart.dart';

import 'package:scrapper/models/youtube_stream.dart';
import 'package:scrapper/youtube_direct/formatters/stream_formatter.dart';

/// Low‑level wrapper around `youtube_explode_dart` for fetching stream manifests.
class StreamsApi {
  YoutubeExplode? _ytExplode;

  /// List of YouTube API clients to impersonate when requesting manifests.
  final List<YoutubeApiClient> apiClients;

  /// Creates a new [StreamsApi] that will use the provided [apiClients] when
  /// talking to YouTube. By default it uses [YoutubeApiClient.androidVr].
  StreamsApi({
    this.apiClients = const [YoutubeApiClient.androidVr],
  });

  YoutubeExplode get _yt {
    _ytExplode ??= YoutubeExplode();
    return _ytExplode!;
  }

  /// Fetches all available muxed, video‑only and audio‑only streams for
  /// the given [videoId].
  ///
  /// In case of network or API errors an empty list is returned.
  Future<List<YouTubeStream>> fetchStreams(String videoId) async {
    try {
      final manifest = await _yt.videos.streamsClient.getManifest(
        VideoId(videoId),
        ytClients: apiClients,
      );
      return StreamFormatter.parseManifest(manifest);
    } catch (_) {
      return [];
    }
  }

  /// Fetches audio‑only streams for [videoId] and sorts them by bitrate
  /// in ascending order.
  Future<List<YouTubeStream>> fetchAudioStreams(String videoId) async {
    final all = await fetchStreams(videoId);
    return all.where((s) => s.isAudioOnly).toList()
      ..sort((a, b) => (a.bitrate ?? 0).compareTo(b.bitrate ?? 0));
  }

  /// Returns the highest‑bitrate audio‑only stream for [videoId], or `null`
  /// when no audio‑only formats are available.
  /// On iOS, prefers AAC/m4a streams since AVPlayer cannot play opus/WebM.
  Future<YouTubeStream?> fetchBestAudioStream(String videoId, {bool preferAac = false}) async {
    final audio = await fetchAudioStreams(videoId);
    if (audio.isEmpty) return null;

    if (preferAac) {
      // Prefer m4a/AAC streams (iOS AVPlayer compatible)
      final aacStreams = audio
          .where((s) => s.mimeType.contains('mp4') || s.mimeType.contains('m4a') || s.mimeType.contains('aac'))
          .toList();
      if (aacStreams.isNotEmpty) return aacStreams.last; // highest bitrate AAC
    }

    return audio.last;
  }

  /// Closes the underlying [YoutubeExplode] instance and frees resources.
  void dispose() {
    _ytExplode?.close();
    _ytExplode = null;
  }
}
