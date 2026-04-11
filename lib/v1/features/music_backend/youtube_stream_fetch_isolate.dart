import 'package:flutter/foundation.dart';
import 'package:tunify_source_youtube_music/tunify_source_youtube_music.dart' as scrapper;
import 'package:tunify_music_ports/tunify_music_ports.dart';

/// Params for [fetchYoutubeMusicStreamInIsolate] (must be safe for [compute]).
class YoutubeStreamIsolateParams {
  const YoutubeStreamIsolateParams({
    required this.videoId,
    required this.preferAac,
    this.visitorData,
  });

  final String videoId;
  final bool preferAac;
  final String? visitorData;
}

/// Runs [YoutubeMusicStreamBackend.resolveStream] off the UI isolate.
Future<ResolvedStream?> fetchYoutubeMusicStreamInIsolate(
  YoutubeStreamIsolateParams params,
) {
  return compute(_youtubeStreamIsolateEntry, params);
}

Future<ResolvedStream?> _youtubeStreamIsolateEntry(
  YoutubeStreamIsolateParams p,
) async {
  try {
    const backend = scrapper.YoutubeMusicStreamBackend();
    return await backend.resolveStream(
      TrackRef.youtubeMusic(p.videoId),
      MusicStreamResolveContext(
        visitorData: p.visitorData,
        preferAac: p.preferAac,
      ),
    );
  } catch (_) {
    return null;
  }
}
