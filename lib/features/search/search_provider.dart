import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:tunify/data/models/song.dart';
import 'package:tunify/features/player/player_state_provider.dart';
import 'package:tunify/features/search/recent_search_provider.dart';

/// Tracks the current search query, results, and loading/error state.
class SearchState {
  final bool isLoading;
  final String? error;
  final List<Song> results;
  final String query;

  const SearchState({
    this.isLoading = false,
    this.error,
    this.results = const [],
    this.query = '',
  });

  SearchState copyWith({
    bool? isLoading,
    String? error,
    List<Song>? results,
    String? query,
  }) {
    return SearchState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      results: results ?? this.results,
      query: query ?? this.query,
    );
  }
}

/// Executes search queries through [PlayerNotifier], deduplicates identical
/// refetch attempts, and records successful queries in [recentSearchProvider].
class SearchNotifier extends StateNotifier<SearchState> {
  final Ref ref;
  SearchNotifier(this.ref) : super(const SearchState());

  Future<void> search(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      state = const SearchState();
      return;
    }
    // Skip refetch when query is unchanged (e.g. user tapped input, opened sheet, dismissed keyboard).
    if (state.query == trimmed && !state.isLoading) {
      return;
    }
    state = state.copyWith(isLoading: true, error: null, query: trimmed);
    try {
      final results =
          await ref.read(playerProvider.notifier).searchSongs(trimmed);
      state = state.copyWith(isLoading: false, results: results, error: null);
      ref.read(recentSearchProvider.notifier).addQuery(trimmed);
    } catch (e) {
      state =
          state.copyWith(isLoading: false, error: e.toString(), results: []);
    }
  }
}

final searchProvider = StateNotifierProvider<SearchNotifier, SearchState>(
    (ref) => SearchNotifier(ref));
