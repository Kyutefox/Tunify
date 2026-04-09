/// Browse header fields from the first YouTube Music `browse` response:
/// [musicResponsiveHeaderRenderer] for playlists/albums, or root
/// [musicImmersiveHeaderRenderer] for artist channels.
class PlaylistBrowseMeta {
  const PlaylistBrowseMeta({
    this.description,
    this.curatorName,
    this.curatorThumbnailUrl,
    this.subtitle,
    this.secondSubtitle,
    this.channelTitle,
    this.channelThumbnailUrl,
  });

  final String? description;
  final String? curatorName;
  final String? curatorThumbnailUrl;

  /// Playlist/album subtitle (e.g. `Playlist • 2023`) or artist monthly
  /// listeners (e.g. `101M monthly audience`).
  final String? subtitle;

  /// Stats line (e.g. `82 songs • 5 hours, 3 minutes` or views • tracks • duration).
  final String? secondSubtitle;

  /// Artist: [musicImmersiveHeaderRenderer.title] (canonical channel name).
  final String? channelTitle;

  /// Artist: square avatar from microformat, else immersive header thumbnail.
  final String? channelThumbnailUrl;
}
