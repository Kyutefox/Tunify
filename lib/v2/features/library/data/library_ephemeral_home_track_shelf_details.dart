import 'package:tunify/v2/core/constants/app_colors.dart';
import 'package:tunify/v2/features/library/domain/entities/library_details.dart';
import 'package:tunify/v2/features/library/domain/entities/library_item.dart';

String _trackRowTitle(LibraryItem item, int index) {
  if (index < item.homeTrackTitles.length) {
    final t = item.homeTrackTitles[index].trim();
    if (t.isNotEmpty) {
      return t;
    }
  }
  return 'Unknown track';
}

String _trackRowSubtitle(LibraryItem item, int index) {
  if (index < item.homeTrackSubtitles.length) {
    return item.homeTrackSubtitles[index].trim();
  }
  return '';
}

/// Detail screen for a home folded track-list promo (video ids only, no browse id).
LibraryDetailsModel libraryEphemeralHomeTrackShelfDetails(LibraryItem item) {
  final ids = item.homeTrackVideoIds;
  final tracks = <LibraryDetailsTrack>[
    for (var i = 0; i < ids.length; i++)
      LibraryDetailsTrack(
        title: _trackRowTitle(item, i),
        subtitle: _trackRowSubtitle(item, i),
        thumbUrl: 'https://i.ytimg.com/vi/${ids[i]}/hqdefault.jpg',
        videoId: ids[i],
      ),
  ];
  final n = tracks.length;
  return LibraryDetailsModel(
    type: LibraryDetailsType.playlist,
    item: item,
    searchHint: 'Find in playlist',
    title: item.title,
    subtitlePrimary: 'Tunify',
    collectionStatInfo: n == 1 ? '1 song' : '$n songs',
    typeSubtitle: 'Playlist',
    tracks: tracks,
    heroImageUrl: item.imageUrl,
    gradientTop: AppColors.libraryPlaylistGradientTop,
    chips: const [],
  );
}
