import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tunify/data/models/song.dart';
import 'package:tunify/features/player/player_state_provider.dart';
import 'package:tunify/features/search/recent_search_provider.dart';

enum SearchFilter { all, songs, artists, albums }

/// A unique artist derived from song results.
class ArtistSearchResult {
  final String name;
  final String? browseId;
  final String thumbnailUrl;

  const ArtistSearchResult({
    required this.name,
    this.browseId,
    required this.thumbnailUrl,
  });
}

/// A unique album derived from song results.
class AlbumSearchResult {
  final String name;
  final String artist;
  final String? browseId;
  final String thumbnailUrl;

  const AlbumSearchResult({
    required this.name,
    required this.artist,
    this.browseId,
    required this.thumbnailUrl,
  });
}

/// Tracks the current search query, results, filter, and loading/error state.
class SearchState {
  final bool isLoading;
  final String? error;
  final List<Song> results;
  final String query;
  final SearchFilter filter;

  const SearchState({
    this.isLoading = false,
    this.error,
    this.results = const [],
    this.query = '',
    this.filter = SearchFilter.all,
  });

  /// Unique artists derived from [results], deduplicated by browseId then name.
  List<ArtistSearchResult> get artistResults {
    final seen = <String>{};
    final out = <ArtistSearchResult>[];
    for (final s in results) {
      final key = s.artistBrowseId ?? s.artist.toLowerCase();
      if (seen.add(key)) {
        out.add(ArtistSearchResult(
          name: s.artist,
          browseId: s.artistBrowseId,
          thumbnailUrl: s.thumbnailUrl,
        ));
      }
    }
    return out;
  }

  /// Unique albums derived from [results], deduplicated by browseId then name.
  /// Songs without an albumName are excluded.
  List<AlbumSearchResult> get albumResults {
    final seen = <String>{};
    final out = <AlbumSearchResult>[];
    for (final s in results) {
      final album = s.albumName;
      if (album == null || album.isEmpty) continue;
      final key = s.albumBrowseId ?? album.toLowerCase();
      if (seen.add(key)) {
        out.add(AlbumSearchResult(
          name: album,
          artist: s.artist,
          browseId: s.albumBrowseId,
          thumbnailUrl: s.thumbnailUrl,
        ));
      }
    }
    return out;
  }

  SearchState copyWith({
    bool? isLoading,
    String? error,
    List<Song>? results,
    String? query,
    SearchFilter? filter,
  }) {
    return SearchState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      results: results ?? this.results,
      query: query ?? this.query,
      filter: filter ?? this.filter,
    );
  }
}

/// Executes search queries through [PlayerNotifier], deduplicates identical
/// refetch attempts, and records successful queries in [recentSearchProvider].
class SearchNotifier extends Notifier<SearchState> {
  @override
  SearchState build() => const SearchState();

  Future<void> search(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      state = SearchState(filter: state.filter);
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

  void setFilter(SearchFilter filter) {
    state = state.copyWith(filter: filter);
  }
}

final searchProvider = NotifierProvider<SearchNotifier, SearchState>(SearchNotifier.new);
