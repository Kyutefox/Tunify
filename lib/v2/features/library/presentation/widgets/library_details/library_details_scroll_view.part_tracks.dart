part of 'library_details_scroll_view.dart';

/// Same line as [EpisodeTile] `individualStat` — persist this on save so Your Episodes matches browse.
String _episodeDisplayStatLine(LibraryDetailsTrack track) {
  final durationText = track.durationText?.trim();
  if (durationText != null && durationText.isNotEmpty) {
    return '${track.subtitle} • $durationText';
  }
  return track.subtitle;
}

class _TrackRow extends ConsumerStatefulWidget {
  const _TrackRow({
    required this.index,
    required this.details,
    required this.track,
    required this.onRequestTrackOptions,
  });

  final int index;
  final LibraryDetailsModel details;
  final LibraryDetailsTrack track;
  final void Function(LibraryDetailsTrack track) onRequestTrackOptions;

  @override
  ConsumerState<_TrackRow> createState() => _TrackRowState();
}

class _TrackRowState extends ConsumerState<_TrackRow> {
  bool _addToLaterBusy = false;

  bool get _sheetAvailable => true;

  bool get _isPodcast => widget.details.item.kind == LibraryItemKind.podcast;

  @override
  Widget build(BuildContext context) {
    final isAlbum = widget.details.type == LibraryDetailsType.album;
    final track = widget.track;
    final membershipsAsync = ref.watch(
      trackPlaylistMembershipsProvider(track.videoId.trim()),
    );
    final episodesPlaylist = ref.watch(episodesPlaylistLibraryItemProvider);
    final isAddedToEpisodes = episodesPlaylist == null
        ? false
        : membershipsAsync.maybeWhen(
            data: (set) => set.contains(episodesPlaylist.id),
            orElse: () => false,
          );

    if (_isPodcast) {
      final individualStat = _episodeDisplayStatLine(track);

      return EpisodeTile(
        title: track.title,
        description: track.description ?? '',
        individualStat: individualStat,
        imageUrl: track.thumbUrl,
        isExplicit: track.isExplicit,
        onTap: () => _onTrackTap(track),
        onLongPress:
            _sheetAvailable ? () => widget.onRequestTrackOptions(track) : null,
        onMorePressed:
            _sheetAvailable ? () => widget.onRequestTrackOptions(track) : null,
        onLaterPressed:
            _addToLaterBusy ? null : () => _onToggleEpisodesForLater(track),
        isAddedToLater: isAddedToEpisodes,
        onDownloadPressed: () => _onDownload(track),
        onSharePressed: () => _onShare(track),
      );
    }

    return TrackTile(
      title: track.title,
      subtitle: track.subtitle,
      imageUrl: track.thumbUrl,
      isExplicit: track.isExplicit,
      showThumbnail: !isAlbum,
      onLongPress:
          _sheetAvailable ? () => widget.onRequestTrackOptions(track) : null,
      onMorePressed:
          _sheetAvailable ? () => widget.onRequestTrackOptions(track) : null,
      showMoreIcon: true,
      enableMoreIcon: _sheetAvailable,
    );
  }

  void _onTrackTap(LibraryDetailsTrack track) {
    // TODO: Implement play episode
  }

  Future<void> _onToggleEpisodesForLater(LibraryDetailsTrack track) async {
    final videoId = track.videoId.trim();
    if (videoId.isEmpty || _addToLaterBusy) {
      return;
    }
    final episodesPlaylist = ref.read(episodesPlaylistLibraryItemProvider);
    if (episodesPlaylist == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Your Episodes is unavailable right now.')),
      );
      return;
    }
    Set<String> memberships;
    try {
      memberships =
          await ref.read(trackPlaylistMembershipsProvider(videoId).future);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Could not update Your Episodes right now')),
      );
      return;
    }
    final isAdded = memberships.contains(episodesPlaylist.id);

    setState(() => _addToLaterBusy = true);
    try {
      final gw = ref.read(libraryWriteGatewayProvider);
      if (isAdded) {
        await gw.removeUserPlaylistTrack(
          playlistId: episodesPlaylist.id,
          trackId: videoId,
        );
      } else {
        await gw.addUserPlaylistTrack(
          playlistId: episodesPlaylist.id,
          trackId: videoId,
          title: track.title,
          subtitle: _episodeDisplayStatLine(track),
          description: track.description,
          artworkUrl: track.thumbUrl,
          durationMs: track.durationMs,
          artistBrowseIds: track.artistBrowseIds,
          albumBrowseId: track.albumBrowseId,
        );
      }
      if (!mounted) {
        return;
      }
      invalidateLibraryListCaches(ref);
      ref.invalidate(trackPlaylistMembershipsProvider(videoId));
      ref.invalidate(
        libraryDetailsProvider(LibraryDetailRequest(episodesPlaylist)),
      );
      ref.invalidate(
        libraryDetailsProvider(LibraryDetailRequest(widget.details.item)),
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isAdded ? 'Removed from Your Episodes' : 'Added to Your Episodes',
          ),
        ),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not update Your Episodes right now'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _addToLaterBusy = false);
      }
    }
  }

  void _onDownload(LibraryDetailsTrack track) {
    // TODO: Implement download
  }

  void _onShare(LibraryDetailsTrack track) {
    // TODO: Implement share
  }
}
