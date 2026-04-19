import 'package:flutter/material.dart';
import 'package:tunify/v2/core/constants/app_colors.dart';
import 'package:tunify/v2/features/library/domain/entities/library_browse_recommendation_shelf.dart';
import 'package:tunify/v2/features/library/domain/entities/library_item.dart';

enum LibraryDetailsType {
  /// Liked Songs, Your Episodes, and other fixed system playlists.
  staticPlaylist,
  playlist,
  album,
  artist,
}

class LibraryDetailsTrack {
  const LibraryDetailsTrack({
    required this.title,
    required this.subtitle,
    this.trailingValue,
    this.thumbUrl,
    this.videoId = '',
    this.durationMs,
    this.description,
    this.durationText,
  });

  final String title;
  final String subtitle;
  final String? trailingValue;

  /// Per-track artwork (e.g. from YouTube Music). When null, row uses collection art.
  final String? thumbUrl;

  /// YouTube Music video id when known (browse / home). Empty for offline placeholders.
  final String videoId;

  /// Track length in milliseconds when known (browse).
  final int? durationMs;

  /// Episode description (for podcasts). Null for regular tracks.
  final String? description;

  /// Duration text (e.g., "1 hr 29 min") from the API response. Null for regular tracks.
  final String? durationText;
}

class LibraryDetailsModel {
  const LibraryDetailsModel({
    required this.type,
    required this.item,
    required this.searchHint,
    required this.title,
    required this.subtitlePrimary,
    required this.tracks,
    this.heroImageUrl,
    this.gradientTop = AppColors.libraryDefaultGradientTop,
    this.chips = const <String>[],
    this.artistTabs = const <String>[],
    this.showSortButton = false,
    this.showAddRow = false,
    this.collectionDescription,
    this.collectionStatInfo,
    this.typeSubtitle,
    this.ownerAvatarUrl,
    this.backgroundGradientMid,
    this.browseRecommendationShelves = const [],
  });

  final LibraryDetailsType type;
  final LibraryItem item;
  final String searchHint;
  final String title;
  final String subtitlePrimary;
  final List<LibraryDetailsTrack> tracks;
  final String? heroImageUrl;
  final Color gradientTop;
  final List<String> chips;
  final List<String> artistTabs;
  final bool showSortButton;
  final bool showAddRow;

  /// Long-form blurb from browse (playlist / album description). Not used for static playlists.
  final String? collectionDescription;

  /// Collection stat info (e.g. `1 song • 2 minutes, 59 seconds`) for albums/playlists.
  /// Null for artists.
  final String? collectionStatInfo;

  /// Type subtitle (e.g. `Album • 2026` or `Playlist • 2026`) for albums/playlists.
  /// Shown below owner info with globe icon. Null for artists.
  final String? typeSubtitle;

  /// Curator / owner facepile image from browse (playlist, album). When null, hero owner row uses icon.
  final String? ownerAvatarUrl;

  /// Optional mid gradient stop (from artwork palette). Null keeps a 3-stop gradient.
  final Color? backgroundGradientMid;

  /// Carousels from Tunify `POST /v1/browse` `parsed.recommendation_shelves` (YouTube Music provider).
  final List<LibraryBrowseRecommendationShelf> browseRecommendationShelves;

  bool get isStaticPlaylist => type == LibraryDetailsType.staticPlaylist;

  /// Same details with scaffold gradient colors replaced (after palette extraction).
  LibraryDetailsModel withBackgroundPalette({
    required Color gradientTop,
    Color? backgroundGradientMid,
  }) {
    return LibraryDetailsModel(
      type: type,
      item: item,
      searchHint: searchHint,
      title: title,
      subtitlePrimary: subtitlePrimary,
      tracks: tracks,
      heroImageUrl: heroImageUrl,
      gradientTop: gradientTop,
      chips: chips,
      artistTabs: artistTabs,
      showSortButton: showSortButton,
      showAddRow: showAddRow,
      collectionDescription: collectionDescription,
      collectionStatInfo: collectionStatInfo,
      typeSubtitle: typeSubtitle,
      ownerAvatarUrl: ownerAvatarUrl,
      backgroundGradientMid: backgroundGradientMid,
      browseRecommendationShelves: browseRecommendationShelves,
    );
  }
}
