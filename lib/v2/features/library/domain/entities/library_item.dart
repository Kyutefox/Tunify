import 'package:flutter/foundation.dart';

/// Type of content in the library.
enum LibraryItemKind {
  playlist,
  artist,
  album,
  podcast,
  folder,
}

/// Primary filter categories for the library pill row (Figma order).
enum LibraryFilter {
  all,
  playlists,
  folders,
  podcasts,
  albums,
  artists,
}

/// Secondary sub-filters shown when [LibraryFilter.playlists] is active.
enum LibraryPlaylistSubFilter {
  none,
  byYou,
  bySpotify,
}

/// View mode toggle for library content.
enum LibraryViewMode { list, grid }

/// Sort criteria for library items.
enum LibrarySortMode { recents, recentlyAdded, alphabetical, creator }

/// System artwork types for fixed library items (gradient + icon).
enum SystemArtworkType {
  likedSongs,
  yourEpisodes,
}

/// A single library entry (playlist, artist, album, podcast).
@immutable
class LibraryItem {
  const LibraryItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.kind,
    this.imageUrl,
    this.isPinned = false,
    this.creatorName,
    this.systemArtwork,
    this.ytmBrowseId,
    this.ytmParams,
    this.isUserOwnedPlaylist = false,
    this.isRemoteCatalogPlaylist = false,
    this.isInServerLibrary = false,
    this.updatedAtMs = 0,
    this.isEphemeralHomeTrackShelf = false,
    this.homeTrackVideoIds = const [],
    this.homeTrackTitles = const [],
    this.homeTrackSubtitles = const [],
  });

  final String id;
  final String title;
  final String subtitle;
  final LibraryItemKind kind;
  final String? imageUrl;
  final bool isPinned;
  final String? creatorName;

  /// When set, renders a fixed gradient + icon instead of a network image.
  final SystemArtworkType? systemArtwork;

  /// When set (e.g. home/search), details load via Tunify `POST /v1/browse` instead of mock data.
  final String? ytmBrowseId;
  final String? ytmParams;

  /// User-created local playlist (`playlist_kind` user, not a saved remote catalog row).
  final bool isUserOwnedPlaylist;

  /// Saved YouTube Music playlist (`is_remote_playlist` on the server).
  final bool isRemoteCatalogPlaylist;

  /// Row came from `GET /v1/library/playlists` (already persisted for this user).
  final bool isInServerLibrary;

  /// Server `updated_at_ms` (playlist / folder row). Used to stack pins: older first, newest last.
  final int updatedAtMs;

  /// Home folded track-shelf promo: details are built from [homeTrackVideoIds], not YTM browse.
  final bool isEphemeralHomeTrackShelf;

  /// YouTube Music video ids from the home API (order matches the shelf).
  final List<String> homeTrackVideoIds;

  /// Optional titles per [homeTrackVideoIds] index (from home feed when provided).
  final List<String> homeTrackTitles;

  /// Optional subtitles per [homeTrackVideoIds] (e.g. artist line).
  final List<String> homeTrackSubtitles;
}
