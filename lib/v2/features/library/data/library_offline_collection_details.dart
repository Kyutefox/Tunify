import 'package:tunify/v2/core/constants/app_colors.dart';
import 'package:tunify/v2/features/library/domain/entities/library_details.dart';
import 'package:tunify/v2/features/library/domain/entities/library_item.dart';
import 'package:tunify/v2/features/library/domain/library_playlist_management_pills.dart';

/// Your Episodes placeholder when there is no YouTube browse id.
/// Liked Songs uses [loadLikedSongsPlaylistDetailsFromApi] instead.
LibraryDetailsModel libraryStaticSystemPlaylistDetails(LibraryItem item) {
  return LibraryDetailsModel(
    type: LibraryDetailsType.staticPlaylist,
    item: item,
    searchHint: 'Find in Your Episodes',
    title: item.title,
    subtitlePrimary: '3 episodes',
    tracks: const [
      LibraryDetailsTrack(
        title: 'Episode 12 — The one about music',
        subtitle: 'Today · 42 min',
      ),
      LibraryDetailsTrack(
        title: 'Episode 11 — Behind the scenes',
        subtitle: 'Mar 2 · 38 min',
      ),
      LibraryDetailsTrack(
        title: 'Episode 10 — Listener mail',
        subtitle: 'Feb 18 · 51 min',
      ),
    ],
    gradientTop: AppColors.yourEpisodesDetailGradient,
    showSortButton: true,
    showAddRow: true,
  );
}

/// User-owned or unknown local rows without [LibraryItem.ytmBrowseId].
LibraryDetailsModel libraryOfflinePlaylistShell(LibraryItem item) {
  return LibraryDetailsModel(
    type: LibraryDetailsType.playlist,
    item: item,
    searchHint: 'Find on this page',
    title: item.title,
    subtitlePrimary: item.creatorName ?? 'Playlist',
    collectionStatInfo: 'No tracks yet',
    typeSubtitle: 'Playlist',
    tracks: const [],
    heroImageUrl: item.imageUrl,
    gradientTop: AppColors.libraryPlaylistGradientTop,
    chips: libraryPlaylistShowsManagementPills(item)
        ? LibraryPlaylistManagementChips.ordered
        : const <String>[],
  );
}
