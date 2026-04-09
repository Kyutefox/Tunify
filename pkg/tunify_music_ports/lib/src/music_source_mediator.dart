import 'music_source.dart';
import 'music_stream_backend.dart';
import 'music_stream_resolve_context.dart';
import 'resolved_stream.dart';
import 'track_ref.dart';

/// Dispatches [resolveStream] to the [MusicStreamBackend] registered for [TrackRef.source].
///
/// Tunify wires a single backend: [MusicSource.youtubeMusic].
class MusicSourceMediator {
  MusicSourceMediator(Map<MusicSource, MusicStreamBackend> backends)
      : _backends = Map<MusicSource, MusicStreamBackend>.unmodifiable(
            Map<MusicSource, MusicStreamBackend>.from(backends));

  final Map<MusicSource, MusicStreamBackend> _backends;

  Future<ResolvedStream> resolveStream(
    TrackRef ref,
    MusicStreamResolveContext ctx,
  ) {
    final backend = _backends[ref.source];
    if (backend == null) {
      throw MusicStreamResolveException(
        'No stream backend registered for ${ref.source}',
      );
    }
    return backend.resolveStream(ref, ctx);
  }
}
