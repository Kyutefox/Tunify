import 'package:tunify/v2/core/network/tunify_api_client.dart';
import 'package:tunify/v2/core/utils/logger.dart';
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

  Future<({List<Track> tracks, PlaylistBrowseMeta? meta})> loadFullCollection({
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
    var meta = BrowseFormatter.extractCollectionBrowseMeta(first);

    var dataForTracks = first;
    if (browseKind == LibraryYtmBrowseKind.artist &&
        browseId.startsWith('UC')) {
      final topSongs = BrowseFormatter.extractArtistTopSongsBrowse(first);
      if (topSongs != null) {
        try {
          dataForTracks = await _rawBrowse(
            browseKind: browseKind,
            browseId: topSongs.browseId,
            params: topSongs.params,
          );
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
      for (final t in BrowseFormatter.extractTracksFromBrowseData(data,
          maxResults: cap)) {
        if (seen.add(t.id)) all.add(t);
      }
    }

    addFrom(dataForTracks, maxTracks);
    var next = BrowseFormatter.extractBrowseContinuationToken(dataForTracks);
    while (next != null && next.isNotEmpty && all.length < maxTracks) {
      try {
        final page =
            await _rawBrowse(browseKind: browseKind, continuation: next);
        final before = all.length;
        addFrom(page, maxTracks - all.length);
        if (all.length == before) break;
        next = BrowseFormatter.extractBrowseContinuationToken(page);
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

    return (tracks: all, meta: meta);
  }
}
