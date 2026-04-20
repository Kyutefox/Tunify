import 'package:tunify/v2/core/constants/app_colors.dart';
import 'package:tunify/v2/features/library/domain/entities/library_browse_recommendation_shelf.dart';
import 'package:tunify/v2/features/library/domain/entities/library_details.dart';
import 'package:tunify/v2/features/library/domain/entities/library_item.dart';
import 'package:tunify/v2/features/library/domain/library_playlist_management_pills.dart';
import 'package:tunify/v2/features/library/domain/entities/browse_meta.dart';
import 'package:tunify/v2/features/library/domain/entities/browse_track.dart';

String? _nonEmptyUrl(String url) {
  final t = url.trim();
  return t.isEmpty ? null : t;
}

/// Normalises or upgrades thumbnail URLs to a higher resolution where possible.
String _upgradeThumbResolution(String? url) {
  if (url == null || url.isEmpty) return '';
  if (url.contains('lh3.googleusercontent.com') ||
      url.contains('yt3.ggpht.com')) {
    return url.replaceAllMapped(
      RegExp(r'=w\d+-h\d+'),
      (_) => '=w544-h544',
    );
  }
  if (url.contains('i.ytimg.com')) {
    if (url.contains('/default.') ||
        url.contains('/mqdefault.') ||
        url.contains('/hqdefault.')) {
      return url.replaceAll(
        RegExp(r'/(default|mqdefault|hqdefault)\.'),
        '/maxresdefault.',
      );
    }
  }
  return url;
}

/// Prefer list/grid avatar — **same URL as [LibraryDetailMiniCover]**.
///
/// Do not run [upgradeThumbResolution] here: forcing `=w544-h544` on ggpht
/// URLs can change server-side framing (tight face crop) vs the library thumb.
String? _artistHeroImageUrl({
  required LibraryItem item,
  required BrowseMeta? meta,
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

/// Builds [LibraryDetailsModel] after a Tunify browse load.
LibraryDetailsModel libraryDetailsFromBrowse({
  required LibraryItem item,
  required List<BrowseTrack> tracks,
  BrowseMeta? meta,
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
          videoId: t.id,
          durationMs: t.duration.inMilliseconds,
          description: t.description,
          durationText: t.durationText,
        ),
      )
      .toList(growable: false);


  /// Artist immersive header often supplies a wide banner; library [item.imageUrl]
  /// is the same square avatar as grids and [LibraryDetailMiniCover].
  /// For all other types (album, playlist, podcast), prefer the fresh thumbnail
  /// extracted by the Rust backend over the potentially stale DB value.
  final String? heroUrl = type == LibraryDetailsType.artist
      ? _upgradeThumbResolution(_artistHeroImageUrl(item: item, meta: meta))
      : _nonEmptyUrl(_upgradeThumbResolution(meta?.collectionThumbnailUrl)) ?? item.imageUrl;


  final title = (type == LibraryDetailsType.artist
          ? (meta?.channelTitle ?? item.title)
          : item.title)
      .trim();

  final description = (meta?.description ?? '').trim();
  final collectionDescription = description.isEmpty ? null : description;

  if (type == LibraryDetailsType.artist) {
    final subtitlePrimary = (meta?.subtitle ?? item.subtitle).trim();
    return LibraryDetailsModel(
      type: LibraryDetailsType.artist,
      item: item,
      searchHint: '',
      title: title,
      subtitlePrimary: subtitlePrimary,
      collectionDescription: collectionDescription,
      collectionStatInfo: null,
      tracks: rows,
      heroImageUrl: heroUrl,
      gradientTop: AppColors.libraryArtistGradientTop,
      artistTabs: const ['Music', 'Events', 'Merch'],
      browseRecommendationShelves: browseRecommendationShelves,
    );
  }

  final ownerLine =
      (meta?.curatorName ?? item.creatorName ?? item.subtitle).trim();
  final ownerAvatarUrl = _nonEmptyUrl(
    meta?.curatorThumbnailUrl ?? '',
  );

  // For album/playlist, subtitle is the type info (e.g., "Album • 2026") shown below owner
  final typeSubtitle = meta?.subtitle?.trim();

  return LibraryDetailsModel(
    type: type,
    item: item,
    searchHint: 'Find on this page',
    title: item.title,
    subtitlePrimary: ownerLine,
    collectionDescription: collectionDescription,
    collectionStatInfo: meta?.collectionStatInfo,
    typeSubtitle: typeSubtitle,
    ownerAvatarUrl: ownerAvatarUrl,
    tracks: rows,
    heroImageUrl: heroUrl,
    gradientTop: AppColors.libraryPlaylistGradientTop,
    chips: type == LibraryDetailsType.album
        ? const <String>[]
        : (libraryPlaylistShowsManagementPills(item)
            ? LibraryPlaylistManagementChips.ordered
            : const <String>[]),
    browseRecommendationShelves: browseRecommendationShelves,
  );
}
