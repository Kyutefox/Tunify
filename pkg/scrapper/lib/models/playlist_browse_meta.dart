/// Playlist header fields from the first YouTube Music `browse` response
/// ([musicResponsiveHeaderRenderer]): editorial description, owner name, avatar
class PlaylistBrowseMeta {
  const PlaylistBrowseMeta({
    this.description,
    this.curatorName,
    this.curatorThumbnailUrl,
    this.subtitle,
    this.secondSubtitle,
  });

  final String? description;
  final String? curatorName;
  final String? curatorThumbnailUrl;
  /// Header line (e.g. `Playlist • 2023`).
  final String? subtitle;
  /// Stats line (e.g. `82 songs • 5 hours, 3 minutes` or views • tracks • duration).
  final String? secondSubtitle;
}
