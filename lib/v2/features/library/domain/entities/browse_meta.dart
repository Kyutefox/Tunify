/// Browse header metadata returned by the Tunify `/v1/browse` `collection_metadata` field.
class BrowseMeta {
  const BrowseMeta({
    this.description,
    this.curatorName,
    this.curatorThumbnailUrl,
    this.subtitle,
    this.channelTitle,
    this.channelThumbnailUrl,
    this.collectionStatInfo,
    this.collectionThumbnailUrl,
  });

  final String? description;
  final String? curatorName;

  /// Artist avatar URL (album artist or playlist creator).
  final String? curatorThumbnailUrl;

  /// Subtitle line (e.g. `Playlist • 2024`, artist monthly listeners).
  final String? subtitle;

  /// Artist channel title (canonical name from immersive header).
  final String? channelTitle;

  /// Artist channel square avatar.
  final String? channelThumbnailUrl;

  /// Collection stat info (e.g. `12 songs • 45 minutes`).
  final String? collectionStatInfo;

  /// Cover art URL for the collection itself (album, playlist, podcast).
  final String? collectionThumbnailUrl;
}
