import 'package:tunify_source_youtube_music/shared/shared_headers.dart';
import 'package:tunify_source_youtube_music/youtube_direct/api/streams_api.dart';
import 'package:tunify_music_ports/tunify_music_ports.dart';

/// Stateless InnerTube stream fetch for YouTube Music tracks.
///
/// Caching, Hive/SQLite persistence, and isolate scheduling live in the app layer.
class YoutubeMusicStreamBackend implements MusicStreamBackend {
  const YoutubeMusicStreamBackend();

  static String qualityLabelForBitrate(int bitrateKbps) {
    if (bitrateKbps >= 160) return 'High';
    if (bitrateKbps >= 80) return 'Medium';
    return 'Low';
  }

  @override
  Future<ResolvedStream> resolveStream(
    TrackRef ref,
    MusicStreamResolveContext ctx,
  ) async {
    if (ref.source != MusicSource.youtubeMusic) {
      throw ArgumentError.value(
        ref.source,
        'ref.source',
        'YoutubeMusicStreamBackend only supports MusicSource.youtubeMusic',
      );
    }

    final stream = await StreamsApi.fetchBestAudioStreamDirect(
      ref.id,
      preferAac: ctx.preferAac,
      visitorData: ctx.visitorData,
    );
    if (stream == null) {
      throw MusicStreamResolveException('No audio stream available for ${ref.id}');
    }
    final bitrate = stream.bitrate;
    if (bitrate == null) {
      throw MusicStreamResolveException('Stream for ${ref.id} has no bitrate');
    }
    return ResolvedStream(
      url: stream.url,
      bitrate: bitrate,
      qualityLabel: qualityLabelForBitrate(bitrate),
      headers: Map<String, String>.from(SharedHeaders.streamHeaders),
      durationMs: stream.duration?.inMilliseconds ?? 0,
      mimeType: stream.mimeType,
    );
  }
}
