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

      return results.length > maxResults
          ? results.sublist(0, maxResults)
          : results;
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
  Future<Map<String, String?>> searchResolveBrowseIds(String query,
      {String? preferredArtistName}) async {
    try {
      final payload = _client.basePayload();
      payload['query'] = query;

      final data = await _client.post('search', payload);
      return SearchFormatter.parseBrowseIds(data,
          preferredArtistName: preferredArtistName);
    } catch (e) {
      return {'artistBrowseId': null, 'albumBrowseId': null};
    }
  }

  /// Fetches the first page of results for [params] filter and returns both
  /// the results and a continuation token for the next page.
  ///
  /// [parseResults] converts the raw response map into typed items.
  Future<({List<T> items, String? continuation})> searchPage<T>(
    String query,
    String params,
    List<T> Function(Map<String, dynamic>) parseResults,
  ) async {
    final payload = _client.basePayload();
    payload['query'] = query;
    payload['params'] = params;
    final data = await _client.post('search', payload);
    return (
      items: parseResults(data),
      continuation: SearchFormatter.extractContinuationToken(data),
    );
  }

  /// Fetches the next page of results using a [continuationToken] returned
  /// from a previous [searchPage] or [continuePage] call.
  Future<({List<T> items, String? continuation})> continuePage<T>(
    String continuationToken,
    List<T> Function(Map<String, dynamic>) parseResults,
  ) async {
    final payload = _client.basePayload();
    payload['continuation'] = continuationToken;
    final data = await _client.post('search', payload);
    return (
      items: parseResults(data),
      continuation: SearchFormatter.extractContinuationToken(data),
    );
  }

  /// Performs a search for videos matching [query].
  Future<List<Track>> searchVideos(String query, {int maxResults = 24}) async {
    try {
      final payload = _client.basePayload();
      payload['query'] = query;
      payload['params'] = YtConstants.searchFilterVideos;
      final data = await _client.post('search', payload);
      return SearchFormatter.parseVideoResults(data, maxResults: maxResults);
    } catch (e) {
      return [];
    }
  }

  /// Performs a search for albums matching [query].
  Future<List<Map<String, dynamic>>> searchAlbums(String query,
      {int maxResults = 24}) async {
    try {
      final payload = _client.basePayload();
      payload['query'] = query;
      payload['params'] = YtConstants.searchFilterAlbums;
      final data = await _client.post('search', payload);
      return SearchFormatter.parseAlbumResults(data, maxResults: maxResults);
    } catch (e) {
      return [];
    }
  }

  /// Performs a search for artists matching [query].
  Future<List<Map<String, dynamic>>> searchArtists(String query,
      {int maxResults = 24}) async {
    try {
      final payload = _client.basePayload();
      payload['query'] = query;
      payload['params'] = YtConstants.searchFilterArtists;
      final data = await _client.post('search', payload);
      return SearchFormatter.parseArtistResults(data, maxResults: maxResults);
    } catch (e) {
      return [];
    }
  }

  /// Performs a search for community playlists matching [query].
  Future<List<Map<String, dynamic>>> searchCommunityPlaylists(String query,
      {int maxResults = 24}) async {
    try {
      final payload = _client.basePayload();
      payload['query'] = query;
      payload['params'] = YtConstants.searchFilterCommunityPlaylists;
      final data = await _client.post('search', payload);
      return SearchFormatter.parsePlaylistResults(data, maxResults: maxResults);
    } catch (e) {
      return [];
    }
  }

  /// Performs a search for featured playlists matching [query].
  Future<List<Map<String, dynamic>>> searchFeaturedPlaylists(String query,
      {int maxResults = 24}) async {
    try {
      final payload = _client.basePayload();
      payload['query'] = query;
      payload['params'] = YtConstants.searchFilterFeaturedPlaylists;
      final data = await _client.post('search', payload);
      return SearchFormatter.parsePlaylistResults(data, maxResults: maxResults);
    } catch (e) {
      return [];
    }
  }

  /// Performs a search for profiles matching [query].
  Future<List<Map<String, dynamic>>> searchProfiles(String query,
      {int maxResults = 24}) async {
    try {
      final payload = _client.basePayload();
      payload['query'] = query;
      payload['params'] = YtConstants.searchFilterProfiles;
      final data = await _client.post('search', payload);
      return SearchFormatter.parseProfileResults(data, maxResults: maxResults);
    } catch (e) {
      return [];
    }
  }

  /// Performs a search for podcasts matching [query].
  ///
  /// The search is restricted to podcasts by using [YtConstants.searchFilterPodcasts].
  Future<List<Map<String, dynamic>>> searchPodcasts(String query,
      {int maxResults = 24}) async {
    try {
      final payload = _client.basePayload();
      payload['query'] = query;
      payload['params'] = YtConstants.searchFilterPodcasts;

      final data = await _client.post('search', payload);
      return SearchFormatter.parsePodcastResults(data, maxResults: maxResults);
    } catch (e) {
      return [];
    }
  }

  /// Performs a search for podcast episodes matching [query].
  ///
  /// The search is restricted to episodes by using [YtConstants.searchFilterEpisodes].
  Future<List<Map<String, dynamic>>> searchEpisodes(String query,
      {int maxResults = 24}) async {
    try {
      final payload = _client.basePayload();
      payload['query'] = query;
      payload['params'] = YtConstants.searchFilterEpisodes;

      final data = await _client.post('search', payload);
      return SearchFormatter.parseEpisodeResults(data, maxResults: maxResults);
    } catch (e) {
      return [];
    }
  }

  /// Performs a search for audiobooks matching [query].
  ///
  /// The search is restricted to audiobooks by using [YtConstants.searchFilterAudiobooks].
  Future<List<Map<String, dynamic>>> searchAudiobooks(String query,
      {int maxResults = 24}) async {
    try {
      final payload = _client.basePayload();
      payload['query'] = query;
      payload['params'] = YtConstants.searchFilterAudiobooks;

      final data = await _client.post('search', payload);
      return SearchFormatter.parseAudiobookResults(data,
          maxResults: maxResults);
    } catch (e) {
      return [];
    }
  }
}
