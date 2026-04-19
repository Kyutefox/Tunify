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

  bool get _isPodcast => details.item.kind == LibraryItemKind.podcast;

  @override
  Widget build(BuildContext context) {
    final isAlbum = details.type == LibraryDetailsType.album;

    if (_isPodcast) {
      // Concatenate subtitle (timestamp) and durationText with dot separator
      final individualStat = track.durationText != null && track.durationText!.isNotEmpty
          ? '${track.subtitle} • ${track.durationText}'
          : track.subtitle;
      
      return EpisodeTile(
        title: track.title,
        description: track.description ?? '',
        individualStat: individualStat,
        imageUrl: track.thumbUrl,
        onTap: () => _onTrackTap(track),
        onLongPress: _sheetAvailable ? () => onRequestTrackOptions(track) : null,
        onMorePressed: _sheetAvailable ? () => onRequestTrackOptions(track) : null,
        onLaterPressed: () => _onAddToLater(track),
        onDownloadPressed: () => _onDownload(track),
        onSharePressed: () => _onShare(track),
      );
    }

    return TrackTile(
      title: track.title,
      subtitle: track.subtitle,
      imageUrl: track.thumbUrl,
      showThumbnail: !isAlbum,
      onLongPress: _sheetAvailable ? () => onRequestTrackOptions(track) : null,
      onMorePressed: _sheetAvailable ? () => onRequestTrackOptions(track) : null,
      showMoreIcon: true,
      enableMoreIcon: _sheetAvailable,
    );
  }

  void _onTrackTap(LibraryDetailsTrack track) {
    // TODO: Implement play episode
  }

  void _onAddToLater(LibraryDetailsTrack track) {
    // TODO: Implement add to later
  }

  void _onDownload(LibraryDetailsTrack track) {
    // TODO: Implement download
  }

  void _onShare(LibraryDetailsTrack track) {
    // TODO: Implement share
  }
}
