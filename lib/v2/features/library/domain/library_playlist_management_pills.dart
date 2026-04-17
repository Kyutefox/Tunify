import 'package:tunify/v2/features/library/domain/entities/library_item.dart';
import 'package:tunify/v2/features/library/domain/library_known_creators.dart';

/// User-owned playlist management chip labels (order matches product spec).
abstract final class LibraryPlaylistManagementChips {
  static const String add = 'Add';
  static const String edit = 'Edit';
  static const String sort = 'Sort';
  static const String nameAndDetails = 'Name & details';

  static const List<String> ordered = <String>[
    add,
    edit,
    sort,
    nameAndDetails,
  ];
}

/// Whether the playlist detail screen should show owner action pills
/// (Add, Edit, Sort, Name & details).
///
/// True for mock "by you" playlists and any item marked [LibraryItem.isUserOwnedPlaylist]
/// (e.g. future library sync). Editorial / discovery playlists omit pills.
bool libraryPlaylistShowsManagementPills(LibraryItem item) {
  if (item.kind != LibraryItemKind.playlist) {
    return false;
  }
  if (item.systemArtwork != null) {
    return false;
  }
  if (item.isUserOwnedPlaylist) {
    return true;
  }
  final c = item.creatorName;
  return c == LibraryKnownCreators.you || c == LibraryKnownCreators.damon98;
}
