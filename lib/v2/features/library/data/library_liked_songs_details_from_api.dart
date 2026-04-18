import 'package:tunify/v2/core/constants/app_colors.dart';
import 'package:tunify/v2/features/library/data/library_write_gateway.dart';
import 'package:tunify/v2/features/library/domain/entities/library_details.dart';
import 'package:tunify/v2/features/library/domain/entities/library_item.dart';
import 'package:tunify/v2/features/library/domain/library_playlist_management_pills.dart';
/// Loads Liked Songs rows from Tunify (`GET /v1/library/playlist/tracks`).
Future<LibraryDetailsModel> loadLikedSongsPlaylistDetailsFromApi({
  required LibraryItem item,
  required LibraryWriteGateway gateway,
}) async {
  final rows = await gateway.fetchPlaylistTracks(playlistId: item.id);
  final n = rows.length;
  final subtitlePrimary = n <= 0
      ? 'Playlist'
      : n == 1
          ? 'Playlist · 1 song'
          : 'Playlist · $n songs';
  return LibraryDetailsModel(
    type: LibraryDetailsType.staticPlaylist,
    item: item,
    searchHint: 'Find in Liked Songs',
    title: item.title,
    subtitlePrimary: subtitlePrimary,
    tracks: rows,
    gradientTop: AppColors.likedSongsDetailGradient,
    showSortButton: true,
    showAddRow: true,
  );
}

/// Loads user-owned playlist rows from Tunify (`GET /v1/library/playlist/tracks`).
/// Uses the same structure as libraryOfflinePlaylistShell but with actual tracks.
Future<LibraryDetailsModel> loadUserOwnedPlaylistDetailsFromApi({
  required LibraryItem item,
  required LibraryWriteGateway gateway,
}) async {
  final rows = await gateway.fetchPlaylistTracks(playlistId: item.id);
  final n = rows.length;
  final collectionStatInfo = n <= 0
      ? 'No tracks yet'
      : n == 1
          ? '1 song'
          : '$n songs';
  
  // Use the same structure as libraryOfflinePlaylistShell
  // Don't set heroImageUrl so the cover generator is used
  return LibraryDetailsModel(
    type: LibraryDetailsType.playlist,
    item: item,
    searchHint: 'Find on this page',
    title: item.title,
    subtitlePrimary: item.creatorName ?? 'Playlist',
    collectionStatInfo: collectionStatInfo,
    typeSubtitle: 'Playlist',
    tracks: rows,
    gradientTop: AppColors.libraryPlaylistGradientTop,
    chips: libraryPlaylistShowsManagementPills(item)
        ? LibraryPlaylistManagementChips.ordered
        : const <String>[],
  );
}
