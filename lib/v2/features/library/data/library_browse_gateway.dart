import 'package:tunify/v2/core/network/tunify_api_client.dart';
import 'package:tunify/v2/core/utils/logger.dart';
import 'package:tunify/v2/features/library/data/library_browse_feed_track.dart';
import 'package:tunify/v2/features/library/domain/entities/library_browse_recommendation_shelf.dart';
import 'package:tunify/v2/features/library/domain/library_ytm_browse_kind.dart';
import 'package:tunify_source_youtube_music/models/playlist_browse_meta.dart';
import 'package:tunify_source_youtube_music/models/track.dart';
import 'package:tunify_source_youtube_music/youtube_music/formatters/browse_formatter.dart';

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

  /// Tunify server returns `{ raw, parsed }`; older servers may return bare InnerTube JSON.
  Future<
      ({
        List<Track> tracks,
        PlaylistBrowseMeta? meta,
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
    if (!_isBrowseEnvelope(first)) {
      return _legacyLoadFullCollection(
        browseKind: browseKind,
        browseId: browseId,
        root: first,
        maxTracks: maxTracks,
      );
    }

    final rawFirst = first['raw'] as Map<String, dynamic>? ?? const {};
    final parsedFirst =
        first['parsed'] as Map<String, dynamic>? ?? const <String, dynamic>{};

    // Use backend's parsed collection_metadata if available, otherwise fallback to raw extraction
    final collectionMetadata = parsedFirst['collection_metadata'] as Map<String, dynamic>?;
    PlaylistBrowseMeta? meta;
    if (collectionMetadata != null) {
      meta = PlaylistBrowseMeta(
        description: collectionMetadata['description'] as String?,
        curatorName: collectionMetadata['curator_name'] as String?,
        curatorThumbnailUrl: collectionMetadata['artist_avatar'] as String?,
        subtitle: collectionMetadata['subtitle'] as String?,
        collectionStatInfo: collectionMetadata['collection_stat_info'] as String?,
      );
    } else {
      meta = BrowseFormatter.extractCollectionBrowseMeta(rawFirst);
    }
    final shelves = _recommendationShelvesFromParsed(parsedFirst);

    final seen = <String>{};
    final all = <Track>[];

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

  Future<
      ({
        List<Track> tracks,
        PlaylistBrowseMeta? meta,
        List<LibraryBrowseRecommendationShelf> recommendationShelves,
      })> _legacyLoadFullCollection({
    required LibraryYtmBrowseKind browseKind,
    required String browseId,
    required Map<String, dynamic> root,
    required int maxTracks,
  }) async {
    // Check if root has parsed metadata from backend
    final collectionMetadata = root['collection_metadata'] as Map<String, dynamic>?;
    PlaylistBrowseMeta? meta;
    if (collectionMetadata != null) {
      meta = PlaylistBrowseMeta(
        description: collectionMetadata['description'] as String?,
        curatorName: collectionMetadata['curator_name'] as String?,
        curatorThumbnailUrl: collectionMetadata['artist_avatar'] as String?,
        subtitle: collectionMetadata['subtitle'] as String?,
        collectionStatInfo: collectionMetadata['collection_stat_info'] as String?,
      );
    } else {
      meta = BrowseFormatter.extractCollectionBrowseMeta(root);
    }

    var dataForTracks = root;
    if (browseKind == LibraryYtmBrowseKind.artist &&
        browseId.startsWith('UC')) {
      final topSongs = BrowseFormatter.extractArtistTopSongsBrowse(root);
      if (topSongs != null) {
        try {
          final fetched = await _rawBrowse(
            browseKind: browseKind,
            browseId: topSongs.browseId,
            params: topSongs.params,
          );
          dataForTracks = _isBrowseEnvelope(fetched)
              ? (fetched['raw'] as Map<String, dynamic>? ?? const {})
              : fetched;
        } on Object catch (e, st) {
          Logger.error(
            'Artist top songs browse failed; using channel root tracks',
            tag: 'LibraryBrowseGateway',
            error: e,
            stackTrace: st,
          );
        }
      }
    }

    final seen = <String>{};
    final all = <Track>[];

    void addFrom(Map<String, dynamic> data, int cap) {
      for (final t in BrowseFormatter.extractTracksFromBrowseData(
        data,
        maxResults: cap,
      )) {
        if (seen.add(t.id)) {
          all.add(t);
        }
      }
    }

    addFrom(dataForTracks, maxTracks);
    var next = BrowseFormatter.extractBrowseContinuationToken(dataForTracks);
    while (next != null && next.isNotEmpty && all.length < maxTracks) {
      try {
        final page =
            await _rawBrowse(browseKind: browseKind, continuation: next);
        final before = all.length;
        if (_isBrowseEnvelope(page)) {
          final parsed = page['parsed'] as Map<String, dynamic>? ??
              const <String, dynamic>{};
          for (final t in tracksFromBrowseParsed(parsed)) {
            if (seen.add(t.id)) {
              all.add(t);
            }
          }
          next = _trimmedContinuation(parsed);
        } else {
          addFrom(page, maxTracks - all.length);
          next = BrowseFormatter.extractBrowseContinuationToken(page);
        }
        if (all.length == before) {
          break;
        }
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
      recommendationShelves: const <LibraryBrowseRecommendationShelf>[],
    );
  }
}
