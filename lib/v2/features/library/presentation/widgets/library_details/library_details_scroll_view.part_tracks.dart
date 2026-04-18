part of 'library_details_scroll_view.dart';

class _TrackRow extends StatelessWidget {
  const _TrackRow({
    required this.details,
    required this.track,
    required this.onRequestTrackOptions,
  });

  final LibraryDetailsModel details;
  final LibraryDetailsTrack track;
  final void Function(LibraryDetailsTrack track) onRequestTrackOptions;

  bool get _sheetAvailable =>
      track.videoId.trim().isNotEmpty || details.item.isUserOwnedPlaylist;

  @override
  Widget build(BuildContext context) {
    final type = details.type;
    final item = details.item;
    final showThumbnail = type != LibraryDetailsType.album;

    // For albums, use the collection artwork; for others, use track thumbnail
    final imageUrl = showThumbnail ? track.thumbUrl : item.imageUrl;

    return TrackTile(
      title: track.title,
      subtitle: track.subtitle,
      imageUrl: imageUrl,
      onLongPress: _sheetAvailable ? () => onRequestTrackOptions(track) : null,
      onMorePressed: _sheetAvailable ? () => onRequestTrackOptions(track) : null,
      showMoreIcon: true,
      enableMoreIcon: _sheetAvailable,
    );
  }
}
