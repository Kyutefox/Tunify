import 'track.dart';

/// Display metadata for a browsed playlist or album collection.
class CollectionMetadata {
  final String? title;
  final String? subtitle;
  final String? thumbnailUrl;

  const CollectionMetadata({
    this.title,
    this.subtitle,
    this.thumbnailUrl,
  });

  /// True when at least one non-empty metadata field is present.
  bool get hasData =>
      (title != null && title!.isNotEmpty) ||
      (subtitle != null && subtitle!.isNotEmpty) ||
      (thumbnailUrl != null && thumbnailUrl!.isNotEmpty);
}

/// Tracks resolved from a browsed playlist, album, or mood category.
class CollectionResult {
  final CollectionMetadata metadata;
  final List<Track> tracks;

  const CollectionResult({
    this.metadata = const CollectionMetadata(),
    this.tracks = const [],
  });
}