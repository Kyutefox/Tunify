import 'package:tunify/v2/core/errors/exceptions.dart';
import 'package:tunify/v2/core/errors/failures.dart';
import 'package:tunify/v2/core/network/tunify_api_client.dart';
import 'package:tunify/v2/core/utils/result.dart';
import 'package:tunify/v2/features/search/data/search_api_mapper.dart';
import 'package:tunify/v2/features/search/domain/entities/search_models.dart';
import 'package:tunify/v2/features/search/domain/repositories/search_repository.dart';

class SearchRepositoryImpl implements SearchRepository {
  SearchRepositoryImpl({required TunifyApiClient api}) : _api = api;

  final TunifyApiClient _api;

  static const int _defaultLimit = 24;
  static const int _typingResultLimit = 10;
  static const int _typingSuggestionsLimit = 5;

  @override
  Future<Result<SearchTypingData>> typingPreview(
      {required String query}) async {
    try {
      final trimmedQuery = query.trim();
      if (trimmedQuery.isEmpty) {
        return Result.success(
          SearchTypingData(query: '', suggestions: [], items: []),
        );
      }
      final suggestions = await _fetchSuggestions(
        keyword: trimmedQuery,
        limit: _typingSuggestionsLimit,
      );
      final previewPage = await _fetchForFilter(
        keyword: trimmedQuery,
        backendFilter: 'songs',
        limit: _typingResultLimit,
      );
      return Result.success(
        SearchTypingData(
          query: trimmedQuery,
          suggestions: suggestions,
          items: previewPage.items,
        ),
      );
    } on ServerException catch (e) {
      return Result.failure(ServerFailure(e.message, code: e.code));
    } catch (e) {
      return Result.failure(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Result<SearchResultsData>> search({
    required String query,
    required SearchFilter filter,
    String? continuation,
  }) async {
    try {
      final trimmedQuery = query.trim();
      if (trimmedQuery.isEmpty) {
        return Result.success(
          SearchResultsData(
            query: '',
            selectedFilter: filter,
            topResult: null,
            featuringItems: const [],
            items: const [],
            continuation: null,
          ),
        );
      }

      if (filter == SearchFilter.all) {
        return _searchAll(trimmedQuery, continuation: continuation);
      }

      final page = await _fetchForFilter(
        keyword: trimmedQuery,
        backendFilter: _backendFilterFromUi(filter),
        limit: _defaultLimit,
        continuation: continuation,
      );

      final allowedKinds = _allowedKindsForFilter(filter);
      final filteredItems = page.items
          .where((item) => allowedKinds.contains(item.kind))
          .toList(growable: false);

      return Result.success(
        SearchResultsData(
          query: trimmedQuery,
          selectedFilter: filter,
          topResult: null, // "Following" top card should never appear.
          featuringItems: const [],
          items: filteredItems,
          continuation: page.continuation,
        ),
      );
    } on ServerException catch (e) {
      return Result.failure(ServerFailure(e.message, code: e.code));
    } catch (e) {
      return Result.failure(UnknownFailure(e.toString()));
    }
  }

  Future<Result<SearchResultsData>> _searchAll(
    String query, {
    String? continuation,
  }) async {
    // Backend has no "all" filter. Keep "All" faithful by using the default
    // search stream from songs instead of synthesizing mixed fake ordering.
    final page = await _fetchForFilter(
      keyword: query,
      backendFilter: 'songs',
      limit: _defaultLimit,
      continuation: continuation,
    );

    return Result.success(
      SearchResultsData(
        query: query,
        selectedFilter: SearchFilter.all,
        topResult: null,
        featuringItems: const [],
        items: page.items,
        continuation: page.continuation,
      ),
    );
  }

  Future<({List<SearchResultItem> items, String? continuation})>
      _fetchForFilter({
    required String keyword,
    required String backendFilter,
    required int limit,
    String? continuation,
  }) async {
    final queryMap = <String, String>{
      'keyword': keyword,
      'filter': backendFilter,
      'limit': '$limit',
    };
    if (continuation != null && continuation.isNotEmpty) {
      queryMap['continuation'] = continuation;
    }
    final json = await _api.getJson('/v1/browse/search', query: queryMap);
    final items = json['items'];
    if (items is! List<dynamic>) {
      return (items: const <SearchResultItem>[], continuation: null);
    }
    return (
      items: SearchApiMapper.fromItems(items),
      continuation: (json['continuation'] as String?)?.trim(),
    );
  }

  Set<SearchItemKind> _allowedKindsForFilter(SearchFilter filter) {
    return switch (filter) {
      SearchFilter.artists => const {
          SearchItemKind.artist,
          SearchItemKind.profile
        },
      SearchFilter.albums => const {SearchItemKind.album},
      SearchFilter.playlists => const {SearchItemKind.playlist},
      SearchFilter.songs => const {SearchItemKind.song},
      SearchFilter.podcasts => const {
          SearchItemKind.podcast,
          SearchItemKind.episode
        },
      SearchFilter.all => const {},
    };
  }

  Future<List<String>> _fetchSuggestions({
    required String keyword,
    required int limit,
  }) async {
    final json = await _api.getJson(
      '/v1/browse/search/suggestions',
      query: <String, String>{
        'keyword': keyword,
        'limit': '$limit',
      },
    );
    final raw = json['suggestions'];
    if (raw is! List<dynamic>) {
      return const [];
    }
    return raw
        .whereType<String>()
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .take(limit)
        .toList(growable: false);
  }

  String _backendFilterFromUi(SearchFilter filter) {
    return switch (filter) {
      SearchFilter.all => 'songs',
      SearchFilter.artists => 'artists',
      SearchFilter.albums => 'albums',
      SearchFilter.playlists => 'community_playlists',
      SearchFilter.songs => 'songs',
      SearchFilter.podcasts => 'podcasts',
    };
  }
}
