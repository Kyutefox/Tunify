import 'music_stream_resolve_context.dart';
import 'resolved_stream.dart';
import 'track_ref.dart';

/// Resolves a [TrackRef] to a playable stream (URL, headers, optional local file) for the player.
abstract class MusicStreamBackend {
  Future<ResolvedStream> resolveStream(
    TrackRef ref,
    MusicStreamResolveContext ctx,
  );
}
