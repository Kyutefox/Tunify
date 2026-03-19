import 'package:scrapper/constants/youtube_constants.dart';
import 'package:scrapper/models/track.dart';
import 'package:scrapper/youtube_music/client/yt_music_client.dart';
import 'package:scrapper/youtube_music/formatters/search_formatter.dart';

/// Wrapper around the YouTube Music `search` and suggestions endpoints.
class SearchApi {
  final YTMusicClient _client;

  /// Creates a new [SearchApi] bound to the provided [client].
  SearchApi({required YTMusicClient client}) : _client = client;

  /// Performs a search for song tracks matching [query].
  ///
  /// The search is restricted to songs by using [YtConstants.searchFilterSongs].
  /// Additional pages are requested via continuation tokens until
  /// [maxResults] tracks are collected or the server stops returning results.
  Future<List<Track>> searchMusic(String query, {int maxResults = 24}) async {
    try {
      final payload = _client.basePayload();
      payload['query'] = query;
      payload['params'] = YtConstants.searchFilterSongs;

      final data = await _client.post('search', payload);
      var results = SearchFormatter.parseSearchResults(data);

      String? token = SearchFormatter.extractContinuationToken(data);
      int safety = 0;
      while (token != null && results.length < maxResults && safety < 3) {
        safety++;
        final contPayload = _client.basePayload();
        contPayload['continuation'] = token;
        
        final contData = await _client.post('search', contPayload);
        final nextResults = SearchFormatter.parseSearchResults(contData);
        if (nextResults.isEmpty) break;
        
        results.addAll(nextResults);
        token = SearchFormatter.extractContinuationToken(contData);
      }

      return results.length > maxResults ? results.sublist(0, maxResults) : results;
    } catch (e) {
      return [];
    }
  }

  /// Returns search suggestions for the given [query] using the
  /// `music/get_search_suggestions` endpoint.
  ///
  /// In case of error, an empty list is returned.
  Future<List<String>> getSearchSuggestions(String query) async {
    try {
      final payload = _client.basePayload();
      payload['input'] = query;

      final data = await _client.post('music/get_search_suggestions', payload);
      return SearchFormatter.parseSuggestions(data);
    } catch (e) {
      return [];
    }
  }

  /// Resolves an artist or album name to matching browse IDs using a general
  /// search request.
  ///
  /// The returned map always contains `artistBrowseId` and `albumBrowseId`
  /// keys, whose values may be `null` when nothing relevant is found. When
  /// [preferredArtistName] is supplied, the formatter will try to favour
  /// matches whose artist text equals that name.
  Future<Map<String, String?>> searchResolveBrowseIds(String query, {String? preferredArtistName}) async {
    try {
      final payload = _client.basePayload();
      payload['query'] = query;

      final data = await _client.post('search', payload);
      return SearchFormatter.parseBrowseIds(data, preferredArtistName: preferredArtistName);
    } catch (e) {
      return {'artistBrowseId': null, 'albumBrowseId': null};
    }
  }
}
