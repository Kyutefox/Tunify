import 'package:tunify/v2/features/library/domain/entities/library_item.dart';

/// `target` query/body value for `GET|POST /v1/library/collection`.
String? libraryCollectionApiTargetForItem(LibraryItem item) {
  if (item.isEphemeralHomeTrackShelf) {
    return null;
  }
  switch (item.kind) {
    case LibraryItemKind.album:
      return 'album';
    case LibraryItemKind.artist:
      return 'artist';
    case LibraryItemKind.playlist:
      if (item.systemArtwork != null) {
        return null;
      }
      return 'playlist';
    case LibraryItemKind.podcast:
      return null;
    case LibraryItemKind.episode:
      return null;
    case LibraryItemKind.folder:
      return null;
  }
}

/// Rows from `GET /v1/library/playlists` that can be pinned/unpinned (not static system shelves).
bool libraryItemSupportsPinToggle(LibraryItem item) {
  if (!item.isInServerLibrary) {
    return false;
  }
  if (item.systemArtwork != null) {
    return false;
  }
  return true;
}

/// Saved rows that can be linked into a library folder (server playlist id).
bool libraryItemSupportsFolderMembership(LibraryItem item) {
  if (!item.isInServerLibrary) {
    return false;
  }
  if (item.kind == LibraryItemKind.folder || item.kind == LibraryItemKind.podcast) {
    return false;
  }
  if (item.systemArtwork != null) {
    return false;
  }
  return true;
}

