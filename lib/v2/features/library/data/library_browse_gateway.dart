import 'package:tunify/v2/core/network/tunify_api_client.dart';
import 'package:tunify/v2/core/utils/logger.dart';
import 'package:tunify/v2/features/library/data/library_browse_feed_track.dart';
import 'package:tunify/v2/features/library/domain/entities/browse_meta.dart';
import 'package:tunify/v2/features/library/domain/entities/browse_track.dart';
import 'package:tunify/v2/features/library/domain/entities/library_browse_recommendation_shelf.dart';
import 'package:tunify/v2/features/library/domain/library_ytm_browse_kind.dart';

final class LibraryBrowseGateway {
  LibraryBrowseGateway({required TunifyApiClient api}) : _api = api;

  final TunifyApiClient _api;

  Future<Map<String, dynamic>> _rawBrowse({
    required LibraryYtmBrowseKind browseKind,
    String? browseId,
    String? params,
    String? continuation,
  }) {
    final body = <String, dynamic>{
      'browse_type': browseKind.name,
      if (browseId != null && browseId.trim().isNotEmpty)
        'browse_id': browseId.trim(),
      if (params != null && params.trim().isNotEmpty) 'params': params.trim(),
      if (continuation != null && continuation.trim().isNotEmpty)
        'continuation': continuation.trim(),
    };
    return _api.postJson('/v1/browse', body, withAuth: true);
  }

  static bool _isBrowseEnvelope(Map<String, dynamic> root) {
    return root.containsKey('raw') && root.containsKey('parsed');
  }

  static List<LibraryBrowseRecommendationShelf> _recommendationShelvesFromParsed(
    Map<String, dynamic>? parsed,
  ) {
    if (parsed == null) {
      return const [];
    }
    final list = parsed['recommendation_shelves'] as List<dynamic>? ?? const [];
    return list
        .whereType<Map<String, dynamic>>()
        .map(LibraryBrowseRecommendationShelf.fromJson)
        .where((s) => s.title.isNotEmpty)
        .toList(growable: false);
  }

  static String? _trimmedContinuation(Map<String, dynamic> parsed) {
    final raw = parsed['primary_continuation'];
    if (raw is! String) {
      return null;
    }
    final t = raw.trim();
    return t.isEmpty ? null : t;
  }

  Future<
      ({
        List<BrowseTrack> tracks,
        BrowseMeta? meta,
        List<LibraryBrowseRecommendationShelf> recommendationShelves,
      })> loadFullCollection({
    required LibraryYtmBrowseKind browseKind,
    required String browseId,
    String? params,
    int maxTracks = 5000,
  }) async {
    final first = await _rawBrowse(
      browseKind: browseKind,
      browseId: browseId,
      params: params,
    );
    final parsedFirst =
        first['parsed'] as Map<String, dynamic>? ?? const <String, dynamic>{};

    final collectionMetadata = parsedFirst['collection_metadata'] as Map<String, dynamic>?;
    final BrowseMeta? meta = collectionMetadata == null
        ? null
        : BrowseMeta(
            description: collectionMetadata['description'] as String?,
            curatorName: collectionMetadata['curator_name'] as String?,
            curatorThumbnailUrl: collectionMetadata['artist_avatar'] as String?,
            subtitle: collectionMetadata['subtitle'] as String?,
            collectionStatInfo: collectionMetadata['collection_stat_info'] as String?,
            collectionThumbnailUrl: collectionMetadata['thumbnail_url'] as String?,
          );
    final shelves = _recommendationShelvesFromParsed(parsedFirst);

    final seen = <String>{};
    final all = <BrowseTrack>[];

    void addParsedTracks(Map<String, dynamic> parsed) {
      for (final t in tracksFromBrowseParsed(parsed)) {
        if (seen.add(t.id)) {
          all.add(t);
        }
      }
    }

    addParsedTracks(parsedFirst);
    var next = _trimmedContinuation(parsedFirst);

    while (next != null && all.length < maxTracks) {
      try {
        final page = await _rawBrowse(
          browseKind: browseKind,
          continuation: next,
        );
        if (!_isBrowseEnvelope(page)) {
          break;
        }

        final parsed = page['parsed'] as Map<String, dynamic>? ??
            const <String, dynamic>{};
        final before = all.length;
        addParsedTracks(parsed);
        if (all.length == before) {
          break;
        }
        next = _trimmedContinuation(parsed);
      } on Object catch (e, st) {
        Logger.error(
          'Browse continuation page failed',
          tag: 'LibraryBrowseGateway',
          error: e,
          stackTrace: st,
        );
        break;
      }
    }

    return (
      tracks: all,
      meta: meta,
      recommendationShelves: shelves,
    );
  }
}
