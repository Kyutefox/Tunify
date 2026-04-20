import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tunify/v2/core/constants/app_durations.dart';
import 'package:tunify/v2/core/errors/failures.dart';
import 'package:tunify/v2/features/auth/presentation/providers/auth_providers.dart';
import 'package:tunify/v2/features/search/data/repositories/search_repository_impl.dart';
import 'package:tunify/v2/features/search/domain/entities/search_models.dart';
import 'package:tunify/v2/features/search/domain/repositories/search_repository.dart';

final searchRepositoryProvider = Provider<SearchRepository>((ref) {
  return SearchRepositoryImpl(api: ref.watch(tunifyApiClientProvider));
});

@immutable
class SearchViewState {
  const SearchViewState({
    this.query = '',
    this.selectedFilter = SearchFilter.all,
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasSubmittedSearch = false,
    this.error,
    this.results,
    this.typingData,
  });

  final String query;
  final SearchFilter selectedFilter;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasSubmittedSearch;
  final Failure? error;
  final SearchResultsData? results;
  final SearchTypingData? typingData;

  bool get hasQuery => query.trim().isNotEmpty;

  SearchViewState copyWith({
    String? query,
    SearchFilter? selectedFilter,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasSubmittedSearch,
    Failure? error,
    bool clearError = false,
    SearchResultsData? results,
    SearchTypingData? typingData,
  }) {
    return SearchViewState(
      query: query ?? this.query,
      selectedFilter: selectedFilter ?? this.selectedFilter,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasSubmittedSearch: hasSubmittedSearch ?? this.hasSubmittedSearch,
      error: clearError ? null : (error ?? this.error),
      results: results ?? this.results,
      typingData: typingData ?? this.typingData,
    );
  }
}

class SearchController extends Notifier<SearchViewState> {
  Timer? _typingDebounce;

  @override
  SearchViewState build() {
    ref.onDispose(() => _typingDebounce?.cancel());
    return const SearchViewState();
  }

  void updateQueryDraft(String rawQuery) {
    final nextQuery = rawQuery.trimLeft();
    _typingDebounce?.cancel();
    state = state.copyWith(
      query: nextQuery,
      isLoading: false,
      isLoadingMore: false,
      hasSubmittedSearch: false,
      clearError: true,
      results: null,
      typingData: null,
    );
    final trimmed = nextQuery.trim();
    if (trimmed.isEmpty) {
      return;
    }
    _typingDebounce = Timer(AppDurations.typingDebounce, () {
      _loadTypingPreview(trimmed);
    });
  }

  void clearQuery() {
    _typingDebounce?.cancel();
    state = state.copyWith(
      query: '',
      isLoading: false,
      isLoadingMore: false,
      hasSubmittedSearch: false,
      clearError: true,
      results: null,
      typingData: null,
    );
  }

  Future<void> onFilterChanged(SearchFilter filter) async {
    _typingDebounce?.cancel();
    if (state.selectedFilter == filter) return;
    // Clear results immediately so old content can't remain visible while the
    // new filtered request is in-flight.
    state = state.copyWith(
      selectedFilter: filter,
      isLoading: true,
      isLoadingMore: false,
      clearError: true,
      results: null,
    );
    await _runSearch();
  }

  Future<void> submitSearch() async {
    _typingDebounce?.cancel();
    state = state.copyWith(hasSubmittedSearch: true);
    await _runSearch();
  }

  void hideSubmittedSearch() {
    state = state.copyWith(hasSubmittedSearch: false);
  }

  Future<void> loadMore() async {
    final snapshot = state;
    final current = snapshot.results;
    if (snapshot.isLoading || snapshot.isLoadingMore || current == null) {
      return;
    }
    final continuation = current.continuation;
    if (continuation == null || continuation.isEmpty) {
      return;
    }

    state = state.copyWith(isLoadingMore: true, clearError: true);
    final result = await ref.read(searchRepositoryProvider).search(
          query: current.query,
          filter: snapshot.selectedFilter,
          continuation: continuation,
        );

    result.fold(
      (nextPage) {
        if (state.query.trim() != current.query ||
            state.selectedFilter != snapshot.selectedFilter) {
          state = state.copyWith(isLoadingMore: false);
          return;
        }
        final mergedItems = List<SearchResultItem>.from(current.items)
          ..addAll(nextPage.items);
        state = state.copyWith(
          isLoadingMore: false,
          clearError: true,
          results: current.copyWith(
            items: mergedItems,
            continuation: nextPage.continuation,
            clearTopResult: true,
            featuringItems: const [],
          ),
        );
      },
      (failure) {
        state = state.copyWith(
          isLoadingMore: false,
          error: failure,
        );
      },
    );
  }

  Future<void> retry() async => submitSearch();

  Future<void> _runSearch() async {
    final trimmed = state.query.trim();
    final requestedFilter = state.selectedFilter;
    if (trimmed.isEmpty) {
      state = state.copyWith(
        isLoading: false,
        isLoadingMore: false,
        hasSubmittedSearch: false,
        clearError: true,
        results: const SearchResultsData(
          query: '',
          selectedFilter: SearchFilter.all,
          topResult: null,
          featuringItems: [],
          items: [],
        ),
        typingData: null,
      );
      return;
    }

    state = state.copyWith(
      isLoading: true,
      isLoadingMore: false,
      clearError: true,
      results: null,
    );
    final result = await ref.read(searchRepositoryProvider).search(
          query: trimmed,
          filter: requestedFilter,
        );

    result.fold(
      (data) {
        // Prevent out-of-order request completions from overriding newer UI state.
        if (state.query.trim() != trimmed ||
            state.selectedFilter != requestedFilter) {
          return;
        }
        final recentCandidate =
            data.topResult ?? (data.items.isNotEmpty ? data.items.first : null);
        if (recentCandidate != null) {
          ref.read(searchRecentItemsProvider.notifier).push(recentCandidate);
        }
        state = state.copyWith(
          isLoading: false,
          isLoadingMore: false,
          clearError: true,
          results: data,
        );
      },
      (failure) {
        // Prevent out-of-order request completions from overriding newer UI state.
        if (state.query.trim() != trimmed ||
            state.selectedFilter != requestedFilter) {
          return;
        }
        state = state.copyWith(
          isLoading: false,
          isLoadingMore: false,
          error: failure,
        );
      },
    );
  }

  Future<void> _loadTypingPreview(String query) async {
    final currentQuery = state.query.trim();
    if (currentQuery != query || query.isEmpty) {
      return;
    }

    if (state.hasSubmittedSearch) {
      return;
    }

    state = state.copyWith(
      isLoading: true,
      isLoadingMore: false,
      clearError: true,
      results: null,
      typingData: null,
    );
    final result =
        await ref.read(searchRepositoryProvider).typingPreview(query: query);
    result.fold(
      (data) {
        if (state.query.trim() != query || state.hasSubmittedSearch) {
          return;
        }
        state = state.copyWith(
          typingData: data,
          isLoading: false,
          clearError: true,
        );
      },
      (failure) {
        if (state.query.trim() != query || state.hasSubmittedSearch) {
          return;
        }
        state = state.copyWith(
          isLoading: false,
          error: failure,
        );
      },
    );
  }
}

final searchControllerProvider =
    NotifierProvider<SearchController, SearchViewState>(SearchController.new);

class SearchRecentItemsNotifier extends Notifier<List<SearchResultItem>> {
  @override
  List<SearchResultItem> build() => const [];

  void push(SearchResultItem item) {
    final next = <SearchResultItem>[item];
    for (final existing in state) {
      if (existing.id == item.id && existing.kind == item.kind) {
        continue;
      }
      next.add(existing);
      if (next.length >= 8) break;
    }
    state = next;
  }

  void remove(String id) {
    state = state.where((e) => e.id != id).toList(growable: false);
  }

  void clear() {
    state = const [];
  }
}

final searchRecentItemsProvider =
    NotifierProvider<SearchRecentItemsNotifier, List<SearchResultItem>>(
  SearchRecentItemsNotifier.new,
);
