import 'music_source.dart';

/// Opaque track identity for stream resolution; [source] selects the catalog (YouTube Music).
class TrackRef {
  const TrackRef({required this.source, required this.id});

  final MusicSource source;

  /// Canonical id in that catalog (YouTube watch / video id).
  final String id;

  factory TrackRef.youtubeMusic(String videoId) {
    return TrackRef(source: MusicSource.youtubeMusic, id: videoId);
  }

  /// Stable cross-source cache key (`<source>:<id>`).
  String get sourceSafeKey => '${source.name}:$id';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TrackRef && other.source == source && other.id == id;

  @override
  int get hashCode => Object.hash(source, id);
}
