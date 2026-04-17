import 'package:flutter/foundation.dart';

/// Type of content in the library.
enum LibraryItemKind {
  playlist,
  artist,
  album,
  podcast,
}

/// Primary filter categories for the library pill row (Figma order).
enum LibraryFilter {
  all,
  playlists,
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

  /// User-created playlist (mock: [LibraryKnownCreators.you] rows; wired from library).
  final bool isUserOwnedPlaylist;
}
