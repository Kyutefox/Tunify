import 'package:tunify/v2/features/home/data/home_api_mapper.dart';
import 'package:tunify/v2/features/home/domain/entities/home_block.dart';
import 'package:tunify/v2/features/library/domain/entities/library_browse_recommendation_shelf.dart';

/// Maps Tunify browse `recommendation_shelves` into the same [HomeCarouselSection] shape as home.
///
/// [FeedItem] tracks are omitted here: [HomeCarouselShelf] navigation assumes browse IDs, not
/// watch/video IDs (same limitation as mixed home carousels).
abstract final class LibraryBrowseRecommendationCarouselMapper {
  static HomeCarouselSection? toCarouselSection(
    LibraryBrowseRecommendationShelf shelf,
  ) {
    if (shelf.title.isEmpty || shelf.isEmptyForCarousel) {
      return null;
    }
    final items = <Map<String, dynamic>>[];

    for (final p in shelf.playlists) {
      items.add({
        'kind': 'playlist',
        'value': {
          'id': p.id,
          'title': p.title,
          if (p.subtitle != null && p.subtitle!.isNotEmpty)
            'subtitle': p.subtitle,
          if (p.artworkUrl != null && p.artworkUrl!.isNotEmpty)
            'artwork_url': p.artworkUrl,
        },
      });
    }
    for (final a in shelf.artists) {
      items.add({
        'kind': 'artist',
        'value': {
          'id': a.id,
          'name': a.name,
          if (a.artworkUrl != null && a.artworkUrl!.isNotEmpty)
            'artwork_url': a.artworkUrl,
        },
      });
    }
    for (final al in shelf.albums) {
      items.add({
        'kind': 'album',
        'value': {
          'id': al.id,
          'title': al.title,
          if (al.subtitle != null && al.subtitle!.isNotEmpty)
            'subtitle': al.subtitle,
          if (al.artworkUrl != null && al.artworkUrl!.isNotEmpty)
            'artwork_url': al.artworkUrl,
        },
      });
    }

    if (items.isEmpty) {
      return null;
    }

    final sectionId =
        'browse_rec_${shelf.title.hashCode}_${items.length}_${items.first['kind']}';
    return HomeApiMapper.carouselSectionFromKindValueItems(
      id: sectionId,
      title: shelf.title,
      items: items,
    );
  }
}
