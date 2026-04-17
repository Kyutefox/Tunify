import 'package:flutter/material.dart';
import 'package:tunify/v2/features/library/domain/entities/library_browse_recommendation_shelf.dart';
import 'package:tunify/v2/features/library/domain/entities/library_details.dart';
import 'package:tunify/v2/features/library/domain/entities/library_item.dart';
import 'package:tunify/v2/features/library/domain/library_playlist_management_pills.dart';
import 'package:tunify_source_youtube_music/models/playlist_browse_meta.dart';
import 'package:tunify_source_youtube_music/models/track.dart';

String? _nonEmptyUrl(String url) {
  final t = url.trim();
  return t.isEmpty ? null : t;
}

/// Prefer list/grid avatar — **same URL as [LibraryDetailMiniCover]**.
///
/// Do not run [upgradeThumbResolution] here: forcing `=w544-h544` on ggpht
/// URLs can change server-side framing (tight face crop) vs the library thumb.
String? _artistHeroImageUrl({
  required LibraryItem item,
  required PlaylistBrowseMeta? meta,
}) {
  final fromItem = _nonEmptyUrl(item.imageUrl ?? '');
  if (fromItem != null) {
    return fromItem;
  }
  final fromChannel = _nonEmptyUrl(meta?.channelThumbnailUrl ?? '');
  if (fromChannel != null) {
    return fromChannel;
  }
  return _nonEmptyUrl(meta?.curatorThumbnailUrl ?? '');
}

LibraryDetailsType _detailsType(LibraryItemKind kind) {
  return switch (kind) {
    LibraryItemKind.artist => LibraryDetailsType.artist,
    LibraryItemKind.album => LibraryDetailsType.album,
    _ => LibraryDetailsType.playlist,
  };
}

/// Builds [LibraryDetailsModel] after a Tunify `POST /v1/browse` load.
LibraryDetailsModel libraryDetailsFromRemoteBrowse({
  required LibraryItem item,
  required List<Track> tracks,
  PlaylistBrowseMeta? meta,
  List<LibraryBrowseRecommendationShelf> browseRecommendationShelves =
      const [],
}) {
  final type = _detailsType(item.kind);
  final rows = tracks
      .map(
        (t) => LibraryDetailsTrack(
          title: t.title,
          subtitle: t.artist,
          trailingValue: t.durationFormatted,
          thumbUrl: _nonEmptyUrl(t.thumbnailUrl),
        ),
      )
      .toList(growable: false);

  /// Artist immersive header often supplies a wide banner; library [item.imageUrl]
  /// is the same square avatar as grids and [LibraryDetailMiniCover].
  final String? heroUrl = type == LibraryDetailsType.artist
      ? _artistHeroImageUrl(item: item, meta: meta)
      : (meta?.curatorThumbnailUrl ??
          meta?.channelThumbnailUrl ??
          item.imageUrl);

  final title = (type == LibraryDetailsType.artist
          ? (meta?.channelTitle ?? item.title)
          : item.title)
      .trim();

  final typeLine = (meta?.subtitle ?? '').trim();
  final description = (meta?.description ?? '').trim();
  final collectionDescription = description.isEmpty ? null : description;
  final second = meta?.secondSubtitle?.trim();
  final statsLine =
      second != null && second.isNotEmpty ? second : '${tracks.length} songs';

  if (type == LibraryDetailsType.artist) {
    final subtitlePrimary = (meta?.subtitle ?? item.subtitle).trim();
    return LibraryDetailsModel(
      type: LibraryDetailsType.artist,
      item: item,
      searchHint: '',
      title: title,
      subtitlePrimary: subtitlePrimary,
      subtitleSecondary: '',
      collectionDescription: collectionDescription,
      statsLine: statsLine,
      tracks: rows,
      heroImageUrl: heroUrl,
      gradientTop: const Color(0xFF121212),
      artistTabs: const ['Music', 'Events', 'Merch'],
      browseRecommendationShelves: browseRecommendationShelves,
    );
  }

  final ownerLine =
      (meta?.curatorName ?? item.creatorName ?? item.subtitle).trim();
  final secondaryLine = typeLine.isNotEmpty ? typeLine : item.subtitle.trim();
  final ownerAvatarUrl = _nonEmptyUrl(
    meta?.curatorThumbnailUrl ?? meta?.channelThumbnailUrl ?? '',
  );

  return LibraryDetailsModel(
    type: type,
    item: item,
    searchHint: 'Find on this page',
    title: title,
    subtitlePrimary: ownerLine,
    subtitleSecondary: secondaryLine,
    collectionDescription: collectionDescription,
    ownerAvatarUrl: ownerAvatarUrl,
    statsLine: statsLine,
    tracks: rows,
    heroImageUrl: heroUrl,
    gradientTop: const Color(0xFF6589AE),
    chips: type == LibraryDetailsType.album
        ? const <String>[]
        : (libraryPlaylistShowsManagementPills(item)
            ? LibraryPlaylistManagementChips.ordered
            : const <String>[]),
    browseRecommendationShelves: browseRecommendationShelves,
  );
}
