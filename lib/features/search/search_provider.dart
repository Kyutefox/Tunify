import 'package:scrapper/scrapper.dart' as scrapper;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tunify/data/models/audiobook.dart';
import 'package:tunify/data/models/podcast.dart';
import 'package:tunify/data/models/song.dart';
import 'package:tunify/features/player/player_state_provider.dart';
import 'package:tunify/features/search/recent_search_provider.dart';

enum SearchFilter {
  all,
  songs,
  videos,
  albums,
  artists,
  podcasts,
  audiobooks,
  communityPlaylists,
  featuredPlaylists,
  profiles
}

// ── Typed result models ───────────────────────────────────────────────────────

class ArtistSearchResult {
  final String name;
  final String? browseId;
  final String thumbnailUrl;
  final String? subscriberCount;

  const ArtistSearchResult({
    required this.name,
    this.browseId,
    required this.thumbnailUrl,
    this.subscriberCount,
  });

  factory ArtistSearchResult.fromMap(Map<String, dynamic> m) =>
      ArtistSearchResult(
        name: m['name'] as String? ?? '',
        browseId: m['id'] as String?,
        thumbnailUrl: m['thumbnailUrl'] as String? ?? '',
        subscriberCount: m['subscriberCount'] as String?,
      );
}

class AlbumSearchResult {
  final String name;
  final String artist;
  final String? browseId;
  final String thumbnailUrl;
  final String? year;

  const AlbumSearchResult({
    required this.name,
    required this.artist,
    this.browseId,
    required this.thumbnailUrl,
    this.year,
  });

  factory AlbumSearchResult.fromMap(Map<String, dynamic> m) =>
      AlbumSearchResult(
        name: m['title'] as String? ?? '',
        artist: m['artist'] as String? ?? '',
        browseId: m['id'] as String?,
        thumbnailUrl: m['thumbnailUrl'] as String? ?? '',
        year: m['year'] as String?,
      );
}

class PlaylistSearchResult {
  final String title;
  final String author;
  final String? browseId;
  final String thumbnailUrl;
  final String? songCount;

  const PlaylistSearchResult({
    required this.title,
    required this.author,
    this.browseId,
    required this.thumbnailUrl,
    this.songCount,
  });

  factory PlaylistSearchResult.fromMap(Map<String, dynamic> m) =>
      PlaylistSearchResult(
        title: m['title'] as String? ?? '',
        author: m['author'] as String? ?? '',
        browseId: m['id'] as String?,
        thumbnailUrl: m['thumbnailUrl'] as String? ?? '',
        songCount: m['songCount'] as String?,
      );
}

class PodcastSearchResult {
  const PodcastSearchResult({
    required this.id,
    required this.title,
    this.author,
    this.thumbnailUrl,
    this.browseId,
  });

  final String id;
  final String title;
  final String? author;
  final String? thumbnailUrl;
  final String? browseId;

  factory PodcastSearchResult.fromPodcast(Podcast p) => PodcastSearchResult(
        id: p.id,
        title: p.title,
        author: p.author,
        thumbnailUrl: p.thumbnailUrl,
        browseId: p.browseId,
      );
}

class AudiobookSearchResult {
  const AudiobookSearchResult({
    required this.id,
    required this.title,
    this.author,
    this.thumbnailUrl,
    this.browseId,
  });

  final String id;
  final String title;
  final String? author;
  final String? thumbnailUrl;
  final String? browseId;

  factory AudiobookSearchResult.fromAudiobook(Audiobook a) =>
      AudiobookSearchResult(
        id: a.id,
        title: a.title,
        author: a.author,
        thumbnailUrl: a.thumbnailUrl,
        browseId: a.browseId,
      );
}

// ── SearchState ───────────────────────────────────────────────────────────────

/// Holds all typed results for every filter. Each filter's data is fetched
/// on first selection and cached for the life of the query.
class SearchState {
  final bool isLoading;

  /// True while a load-more page is being fetched (not an initial fetch).
  final bool isLoadingMore;
  final String? error;
  final String query;
  final SearchFilter filter;

  /// Songs filter results.
  final List<Song> songResults;

  /// Videos filter results (playable like songs).
  final List<Song> videoResults;

  /// Artists filter results (from the real Artists API endpoint).
  final List<ArtistSearchResult> artistResults;

  /// Albums filter results (from the real Albums API endpoint).
  final List<AlbumSearchResult> albumResults;

  /// Community playlists filter results.
  final List<PlaylistSearchResult> playlistResults;

  /// Featured playlists filter results.
  final List<PlaylistSearchResult> featuredPlaylistResults;

  /// Podcasts filter results.
  final List<PodcastSearchResult> podcastResults;

  /// Audiobooks filter results.
  final List<AudiobookSearchResult> audiobookResults;

  /// Profiles filter results.
  final List<ArtistSearchResult> profileResults;

  /// Continuation tokens for each filter — null means no more pages.
  final Map<SearchFilter, String?> _continuations;

  /// Tracks which filters have already been fetched for the current query.
  final Set<SearchFilter> _fetched;

  const SearchState({
    this.isLoading = false,
    this.isLoadingMore = false,
    this.error,
    this.query = '',
    this.filter = SearchFilter.all,
    this.songResults = const [],
    this.videoResults = const [],
    this.artistResults = const [],
    this.albumResults = const [],
    this.playlistResults = const [],
    this.featuredPlaylistResults = const [],
    this.podcastResults = const [],
    this.audiobookResults = const [],
    this.profileResults = const [],
    Map<SearchFilter, String?> continuations = const {},
    Set<SearchFilter> fetched = const {},
  })  : _continuations = continuations,
        _fetched = fetched;

  bool isFetched(SearchFilter f) => _fetched.contains(f);
  String? continuationFor(SearchFilter f) => _continuations[f];

  /// Results shown for the [all] filter — songs only (matches YT Music behaviour).
  List<Song> get allResults => songResults;

  SearchState copyWith({
    bool? isLoading,
    bool? isLoadingMore,
    String? error,
    String? query,
    SearchFilter? filter,
    List<Song>? songResults,
    List<Song>? videoResults,
    List<ArtistSearchResult>? artistResults,
    List<AlbumSearchResult>? albumResults,
    List<PlaylistSearchResult>? playlistResults,
    List<PlaylistSearchResult>? featuredPlaylistResults,
    List<PodcastSearchResult>? podcastResults,
    List<AudiobookSearchResult>? audiobookResults,
    List<ArtistSearchResult>? profileResults,
    Map<SearchFilter, String?>? continuations,
    Set<SearchFilter>? fetched,
  }) {
    return SearchState(
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      error: error,
      query: query ?? this.query,
      filter: filter ?? this.filter,
      songResults: songResults ?? this.songResults,
      videoResults: videoResults ?? this.videoResults,
      artistResults: artistResults ?? this.artistResults,
      albumResults: albumResults ?? this.albumResults,
      playlistResults: playlistResults ?? this.playlistResults,
      featuredPlaylistResults:
          featuredPlaylistResults ?? this.featuredPlaylistResults,
      podcastResults: podcastResults ?? this.podcastResults,
      audiobookResults: audiobookResults ?? this.audiobookResults,
      profileResults: profileResults ?? this.profileResults,
      continuations: continuations ?? _continuations,
      fetched: fetched ?? _fetched,
    );
  }

  /// True when the currently selected filter has results to show.
  bool get hasResults {
    switch (filter) {
      case SearchFilter.all:
        return allResults.isNotEmpty;
      case SearchFilter.songs:
        return songResults.isNotEmpty;
      case SearchFilter.videos:
        return videoResults.isNotEmpty;
      case SearchFilter.artists:
        return artistResults.isNotEmpty;
      case SearchFilter.albums:
        return albumResults.isNotEmpty;
      case SearchFilter.podcasts:
        return podcastResults.isNotEmpty;
      case SearchFilter.audiobooks:
        return audiobookResults.isNotEmpty;
      case SearchFilter.communityPlaylists:
        return playlistResults.isNotEmpty;
      case SearchFilter.featuredPlaylists:
        return featuredPlaylistResults.isNotEmpty;
      case SearchFilter.profiles:
        return profileResults.isNotEmpty;
    }
  }
}

// ── SearchNotifier ────────────────────────────────────────────────────────────

/// Dispatches a real YouTube Music API call for each filter with proper
/// pagination via continuation tokens.
class SearchNotifier extends Notifier<SearchState> {
  @override
  SearchState build() => const SearchState();

  Future<void> search(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      state = SearchState(filter: state.filter);
      return;
    }
    if (state.query == trimmed && !state.isLoading) return;

    state = SearchState(query: trimmed, filter: state.filter, isLoading: true);
    await _fetchForFilter(trimmed, state.filter);
    // Only persist queries that produced at least one result.
    if (state.error == null && state.hasResults) {
      ref.read(recentSearchProvider.notifier).addQuery(trimmed);
    }
  }

  Future<void> setFilter(SearchFilter filter) async {
    state = state.copyWith(filter: filter);
    if (state.query.isEmpty) return;
    if (state.isFetched(filter)) return;
    state = state.copyWith(isLoading: true, error: null);
    await _fetchForFilter(state.query, filter);
  }

  /// Called when the user scrolls near the end of the current filter's list.
  Future<void> loadMore() async {
    final filter = state.filter;
    final token = state.continuationFor(filter);
    if (token == null || state.isLoading || state.isLoadingMore) return;

    state = state.copyWith(isLoadingMore: true);
    final player = ref.read(playerProvider.notifier);

    try {
      switch (filter) {
        case SearchFilter.all:
        case SearchFilter.songs:
          final page = await player.continueTrackSearch(token);
          final newConts = Map<SearchFilter, String?>.from(state._continuations)
            ..[SearchFilter.all] = page.continuation
            ..[SearchFilter.songs] = page.continuation;
          state = state.copyWith(
            isLoadingMore: false,
            songResults: [...state.songResults, ...page.items],
            continuations: newConts,
          );

        case SearchFilter.videos:
          final page = await player.continueTrackSearch(token);
          final newConts = Map<SearchFilter, String?>.from(state._continuations)
            ..[filter] = page.continuation;
          state = state.copyWith(
            isLoadingMore: false,
            videoResults: [...state.videoResults, ...page.items],
            continuations: newConts,
          );

        case SearchFilter.artists:
          final page = await player.continueMapSearch(
              token, scrapper.SearchFormatter.parseArtistResults);
          final newConts = Map<SearchFilter, String?>.from(state._continuations)
            ..[filter] = page.continuation;
          state = state.copyWith(
            isLoadingMore: false,
            artistResults: [
              ...state.artistResults,
              ...page.items.map(ArtistSearchResult.fromMap)
            ],
            continuations: newConts,
          );

        case SearchFilter.albums:
          final page = await player.continueMapSearch(
              token, scrapper.SearchFormatter.parseAlbumResults);
          final newConts = Map<SearchFilter, String?>.from(state._continuations)
            ..[filter] = page.continuation;
          state = state.copyWith(
            isLoadingMore: false,
            albumResults: [
              ...state.albumResults,
              ...page.items.map(AlbumSearchResult.fromMap)
            ],
            continuations: newConts,
          );

        case SearchFilter.communityPlaylists:
          final page = await player.continueMapSearch(
              token, scrapper.SearchFormatter.parsePlaylistResults);
          final newConts = Map<SearchFilter, String?>.from(state._continuations)
            ..[filter] = page.continuation;
          state = state.copyWith(
            isLoadingMore: false,
            playlistResults: [
              ...state.playlistResults,
              ...page.items.map(PlaylistSearchResult.fromMap)
            ],
            continuations: newConts,
          );

        case SearchFilter.featuredPlaylists:
          final page = await player.continueMapSearch(
              token, scrapper.SearchFormatter.parsePlaylistResults);
          final newConts = Map<SearchFilter, String?>.from(state._continuations)
            ..[filter] = page.continuation;
          state = state.copyWith(
            isLoadingMore: false,
            featuredPlaylistResults: [
              ...state.featuredPlaylistResults,
              ...page.items.map(PlaylistSearchResult.fromMap)
            ],
            continuations: newConts,
          );

        case SearchFilter.profiles:
          final page = await player.continueMapSearch(
              token, scrapper.SearchFormatter.parseProfileResults);
          final newConts = Map<SearchFilter, String?>.from(state._continuations)
            ..[filter] = page.continuation;
          state = state.copyWith(
            isLoadingMore: false,
            profileResults: [
              ...state.profileResults,
              ...page.items.map(ArtistSearchResult.fromMap)
            ],
            continuations: newConts,
          );
        case SearchFilter.podcasts:
        case SearchFilter.audiobooks:
          state = state.copyWith(isLoadingMore: false);
      }
    } catch (e) {
      state = state.copyWith(isLoadingMore: false);
    }
  }

  Future<void> _fetchForFilter(String query, SearchFilter filter) async {
    final player = ref.read(playerProvider.notifier);
    try {
      switch (filter) {
        case SearchFilter.all:
        case SearchFilter.songs:
          final page = await player.searchSongsPage(query);
          final newConts = Map<SearchFilter, String?>.from(state._continuations)
            ..[SearchFilter.all] = page.continuation
            ..[SearchFilter.songs] = page.continuation;
          state = state.copyWith(
            isLoading: false,
            songResults: page.items,
            continuations: newConts,
            fetched: {...state._fetched, SearchFilter.all, SearchFilter.songs},
          );

        case SearchFilter.videos:
          final page = await player.searchVideosPage(query);
          final newConts = Map<SearchFilter, String?>.from(state._continuations)
            ..[filter] = page.continuation;
          state = state.copyWith(
            isLoading: false,
            videoResults: page.items,
            continuations: newConts,
            fetched: {...state._fetched, filter},
          );

        case SearchFilter.artists:
          final page = await player.searchArtistsPage(query);
          final newConts = Map<SearchFilter, String?>.from(state._continuations)
            ..[filter] = page.continuation;
          state = state.copyWith(
            isLoading: false,
            artistResults: page.items.map(ArtistSearchResult.fromMap).toList(),
            continuations: newConts,
            fetched: {...state._fetched, filter},
          );

        case SearchFilter.albums:
          final page = await player.searchAlbumsPage(query);
          final newConts = Map<SearchFilter, String?>.from(state._continuations)
            ..[filter] = page.continuation;
          state = state.copyWith(
            isLoading: false,
            albumResults: page.items.map(AlbumSearchResult.fromMap).toList(),
            continuations: newConts,
            fetched: {...state._fetched, filter},
          );

        case SearchFilter.communityPlaylists:
          final page = await player.searchCommunityPlaylistsPage(query);
          final newConts = Map<SearchFilter, String?>.from(state._continuations)
            ..[filter] = page.continuation;
          state = state.copyWith(
            isLoading: false,
            playlistResults:
                page.items.map(PlaylistSearchResult.fromMap).toList(),
            continuations: newConts,
            fetched: {...state._fetched, filter},
          );

        case SearchFilter.featuredPlaylists:
          final page = await player.searchFeaturedPlaylistsPage(query);
          final newConts = Map<SearchFilter, String?>.from(state._continuations)
            ..[filter] = page.continuation;
          state = state.copyWith(
            isLoading: false,
            featuredPlaylistResults:
                page.items.map(PlaylistSearchResult.fromMap).toList(),
            continuations: newConts,
            fetched: {...state._fetched, filter},
          );

        case SearchFilter.profiles:
          final page = await player.searchProfilesPage(query);
          final newConts = Map<SearchFilter, String?>.from(state._continuations)
            ..[filter] = page.continuation;
          state = state.copyWith(
            isLoading: false,
            profileResults: page.items.map(ArtistSearchResult.fromMap).toList(),
            continuations: newConts,
            fetched: {...state._fetched, filter},
          );
        case SearchFilter.podcasts:
          final raw =
              await ref.read(streamManagerProvider).searchPodcasts(query);
          state = state.copyWith(
            isLoading: false,
            continuations: Map<SearchFilter, String?>.from(state._continuations)
              ..[filter] = null,
            podcastResults: raw
                .map((m) => Podcast(
                      id: m['id'] as String,
                      title: m['title'] as String,
                      author: m['author'] as String?,
                      thumbnailUrl: m['thumbnailUrl'] as String?,
                      browseId: m['browseId'] as String?,
                    ))
                .map(PodcastSearchResult.fromPodcast)
                .toList(),
            fetched: {...state._fetched, filter},
          );
        case SearchFilter.audiobooks:
          final raw =
              await ref.read(streamManagerProvider).searchAudiobooks(query);
          state = state.copyWith(
            isLoading: false,
            continuations: Map<SearchFilter, String?>.from(state._continuations)
              ..[filter] = null,
            audiobookResults: raw
                .map((m) => Audiobook(
                      id: m['id'] as String,
                      title: m['title'] as String,
                      author: m['author'] as String?,
                      thumbnailUrl: m['thumbnailUrl'] as String?,
                      browseId: m['browseId'] as String?,
                    ))
                .map(AudiobookSearchResult.fromAudiobook)
                .toList(),
            fetched: {...state._fetched, filter},
          );
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

final searchProvider =
    NotifierProvider<SearchNotifier, SearchState>(SearchNotifier.new);
