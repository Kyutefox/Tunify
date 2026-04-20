/// Browse header fields from the first YouTube Music `browse` response:
/// [musicResponsiveHeaderRenderer] for playlists/albums, or root
/// [musicImmersiveHeaderRenderer] for artist channels.
class PlaylistBrowseMeta {
  const PlaylistBrowseMeta({
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
  final String? curatorThumbnailUrl;

  /// Cover art URL for the collection itself (album cover, playlist cover, podcast cover).
  /// Populated from `collection_metadata.thumbnail_url` returned by the Rust backend.
  final String? collectionThumbnailUrl;

  /// Playlist/album subtitle (e.g. `Playlist • 2023`) or artist monthly
  /// listeners (e.g. `101M monthly audience`).
  final String? subtitle;

  /// Artist: [musicImmersiveHeaderRenderer.title] (canonical channel name).
  final String? channelTitle;

  /// Artist: square avatar from microformat, else immersive header thumbnail.
  final String? channelThumbnailUrl;

  /// Collection stat info (e.g. `1 song • 2 minutes, 59 seconds`) for albums/playlists.
  /// Null for artists.
  final String? collectionStatInfo;
}
