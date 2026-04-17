import 'package:flutter/material.dart';
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
  });

  final String title;
  final String subtitle;
  final String? trailingValue;

  /// Per-track artwork (e.g. from YouTube Music). When null, row uses collection art.
  final String? thumbUrl;
}

class LibraryDetailsModel {
  const LibraryDetailsModel({
    required this.type,
    required this.item,
    required this.searchHint,
    required this.title,
    required this.subtitlePrimary,
    required this.subtitleSecondary,
    required this.statsLine,
    required this.tracks,
    this.heroImageUrl,
    this.gradientTop = const Color(0xFF4B6F95),
    this.chips = const <String>[],
    this.artistTabs = const <String>[],
    this.showSortButton = false,
    this.showAddRow = false,
    this.collectionDescription,
    this.ownerAvatarUrl,
    this.backgroundGradientMid,
    this.browseRecommendationShelves = const [],
  });

  final LibraryDetailsType type;
  final LibraryItem item;
  final String searchHint;
  final String title;
  final String subtitlePrimary;
  final String subtitleSecondary;
  final String statsLine;
  final List<LibraryDetailsTrack> tracks;
  final String? heroImageUrl;
  final Color gradientTop;
  final List<String> chips;
  final List<String> artistTabs;
  final bool showSortButton;
  final bool showAddRow;

  /// Long-form blurb from browse (playlist / album description). Not used for static playlists.
  final String? collectionDescription;

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
      subtitleSecondary: subtitleSecondary,
      statsLine: statsLine,
      tracks: tracks,
      heroImageUrl: heroImageUrl,
      gradientTop: gradientTop,
      chips: chips,
      artistTabs: artistTabs,
      showSortButton: showSortButton,
      showAddRow: showAddRow,
      collectionDescription: collectionDescription,
      ownerAvatarUrl: ownerAvatarUrl,
      backgroundGradientMid: backgroundGradientMid,
      browseRecommendationShelves: browseRecommendationShelves,
    );
  }
}
