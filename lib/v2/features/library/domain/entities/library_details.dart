import 'package:flutter/material.dart';
import 'package:tunify/v2/features/library/domain/entities/library_item.dart';

enum LibraryDetailsType {
  /// Liked Songs, Your Episodes, and other fixed system playlists.
  staticPlaylist,
  playlist,
  artist,
}

class LibraryDetailsTrack {
  const LibraryDetailsTrack({
    required this.title,
    required this.subtitle,
    this.trailingValue,
  });

  final String title;
  final String subtitle;
  final String? trailingValue;
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

  bool get isStaticPlaylist => type == LibraryDetailsType.staticPlaylist;
}
