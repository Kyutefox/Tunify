/// User-visible copy for the library feature (single place per RULES.md theming guidance).
abstract final class LibraryStrings {
  LibraryStrings._();

  static const String yourLibrary = 'Your Library';
  static const String nothingHereTitle = 'Nothing here yet';
  static const String nothingHereBody =
      'Your saved music, podcasts, and playlists will appear here.';
  static const String follow = 'Follow';
  static const String following = 'Following';
  static const String popular = 'Popular';
  static const String addToThisPlaylist = 'Add to this playlist';
  static const String sort = 'Sort';
  static const String sortBy = 'Sort by';

  /// Shown when [libraryDetailsProvider] fails (network / parse); not raw exceptions.
  static const String collectionDetailsLoadError =
      'Could not load this collection. Check your connection and try again.';

  static const String searchYourLibraryHint = 'Find in Your Library';
  static const String searchFolderHint = 'Find in this folder';
  static const String searchNoResultsTitle = 'No results found';
  static const String searchNoResultsBody =
      'Check the spelling or try different keywords.';

  // ── Track row / options sheet (collection details) ──

  static const String trackRemoveFromPlaylistTitle = 'Remove from playlist?';
  static const String trackRemoveFromPlaylistConfirm = 'Remove';
  static const String trackRemovedFromPlaylist = 'Removed from playlist';
  static const String trackRemoveFromPlaylistFailed =
      'Could not remove track from playlist.';
  static const String trackAddToPlaylistSheetTitle = 'Add to playlist';
  static const String trackCreateUserPlaylistFirst =
      'Create a playlist in Your Library first.';
  static const String trackAddedToPlaylist = 'Added to playlist';
  static const String trackAddToPlaylistFailed =
      'Could not add track to playlist.';
  static const String trackLikeNotAvailableYet =
      'Like is not available here yet.';

  static String trackRemoveFromPlaylistBody(String trackTitle) =>
      '$trackTitle will be removed from this playlist.';
}
