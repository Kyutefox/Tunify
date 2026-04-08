import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tunify/data/models/audiobook.dart';
import 'package:tunify/data/models/library_playlist.dart';
import 'package:tunify/data/models/playback_position.dart';
import 'package:tunify/data/models/podcast.dart';
import 'package:tunify/data/models/song.dart';
import 'package:tunify/data/repositories/podcast_repository.dart';
import 'package:tunify/features/player/player_state_provider.dart';
import 'package:tunify_database/tunify_database.dart';

// ── Repository provider ───────────────────────────────────────────────────────

final podcastRepositoryProvider = Provider<PodcastRepository>((ref) {
  return PodcastRepository(DatabaseBridge());
});

// ── State ─────────────────────────────────────────────────────────────────────

class PodcastState {
  const PodcastState({
    this.subscriptions = const [],
    this.savedAudiobooks = const [],
    this.episodesForLater = const [],
    this.episodesForLaterSortOrder = PlaylistTrackSortOrder.recentlyAdded,
    this.positions = const {},
    this.isLoading = false,
  });

  final List<Podcast> subscriptions;
  final List<Audiobook> savedAudiobooks;
  final List<Song> episodesForLater;
  final PlaylistTrackSortOrder episodesForLaterSortOrder;
  final Map<String, PlaybackPosition> positions;
  final bool isLoading;

  bool isSubscribed(String podcastId) =>
      subscriptions.any((p) => p.id == podcastId);

  bool isAudiobookSaved(String audiobookId) =>
      savedAudiobooks.any((a) => a.id == audiobookId);

  PlaybackPosition? positionFor(String contentId, PlaybackContentType type) =>
      positions['${contentId}_${type.name}'];

  PodcastState copyWith({
    List<Podcast>? subscriptions,
    List<Audiobook>? savedAudiobooks,
    List<Song>? episodesForLater,
    PlaylistTrackSortOrder? episodesForLaterSortOrder,
    Map<String, PlaybackPosition>? positions,
    bool? isLoading,
  }) =>
      PodcastState(
        subscriptions: subscriptions ?? this.subscriptions,
        savedAudiobooks: savedAudiobooks ?? this.savedAudiobooks,
        episodesForLater: episodesForLater ?? this.episodesForLater,
        episodesForLaterSortOrder:
            episodesForLaterSortOrder ?? this.episodesForLaterSortOrder,
        positions: positions ?? this.positions,
        isLoading: isLoading ?? this.isLoading,
      );
}

// ── Notifier ──────────────────────────────────────────────────────────────────

class PodcastNotifier extends Notifier<PodcastState> {
  PodcastRepository get _repo => ref.read(podcastRepositoryProvider);

  @override
  PodcastState build() {
    // Initialize async after build completes
    Future.microtask(() => load());
    return const PodcastState(isLoading: true);
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true);
    final subs = await _repo.loadSubscriptions();
    final books = await _repo.loadSavedAudiobooks();
    final episodes = await _repo.loadEpisodesForLater();
    final positions = await _repo.loadAllPositions();

    // Load sort order from settings
    final bridge = DatabaseBridge();
    final sortOrderStr =
        await bridge.getSetting('episodes_for_later_sort_order');
    final sortOrder = sortOrderStr != null
        ? PlaylistTrackSortOrder.values.firstWhere(
            (e) => e.name == sortOrderStr,
            orElse: () => PlaylistTrackSortOrder.recentlyAdded,
          )
        : PlaylistTrackSortOrder.recentlyAdded;

    state = PodcastState(
      subscriptions: subs,
      savedAudiobooks: books,
      episodesForLater: episodes,
      episodesForLaterSortOrder: sortOrder,
      positions: positions,
      isLoading: false,
    );
  }

  Future<void> toggleSubscription(Podcast podcast) async {
    if (state.isSubscribed(podcast.id)) {
      state = state.copyWith(
        subscriptions:
            state.subscriptions.where((p) => p.id != podcast.id).toList(),
      );
      await _repo.unsubscribe(podcast.id);
    } else {
      state = state.copyWith(
        subscriptions: [podcast, ...state.subscriptions],
      );
      await _repo.subscribe(podcast);
    }
  }

  Future<void> toggleSavedAudiobook(Audiobook audiobook) async {
    if (state.isAudiobookSaved(audiobook.id)) {
      state = state.copyWith(
        savedAudiobooks:
            state.savedAudiobooks.where((a) => a.id != audiobook.id).toList(),
      );
      await _repo.removeSavedAudiobook(audiobook.id);
    } else {
      state = state.copyWith(
        savedAudiobooks: [audiobook, ...state.savedAudiobooks],
      );
      await _repo.saveAudiobook(audiobook);
    }
  }

  Future<void> savePosition(PlaybackPosition pos) async {
    final key = '${pos.contentId}_${pos.contentType.name}';
    final updated = Map<String, PlaybackPosition>.from(state.positions);
    updated[key] = pos;
    state = state.copyWith(positions: updated);
    await _repo.savePosition(pos);
  }

  Future<void> clearPosition(String contentId, PlaybackContentType type) async {
    final key = '${contentId}_${type.name}';
    final updated = Map<String, PlaybackPosition>.from(state.positions);
    updated.remove(key);
    state = state.copyWith(positions: updated);
    await _repo.clearPosition(contentId, type);
  }

  Future<void> togglePodcastPin(String podcastId) async {
    final idx = state.subscriptions.indexWhere((p) => p.id == podcastId);
    if (idx < 0) return;
    final podcast = state.subscriptions[idx];
    final updated = podcast.copyWith(isPinned: !podcast.isPinned);
    final newList = List<Podcast>.from(state.subscriptions)..removeAt(idx);
    if (updated.isPinned) {
      final insertAt = newList.where((p) => p.isPinned).length;
      newList.insert(insertAt, updated);
    } else {
      newList.insert(0, updated);
    }
    state = state.copyWith(subscriptions: newList);
    await _repo.updatePodcast(updated);
  }

  Future<void> toggleAudiobookPin(String audiobookId) async {
    final idx = state.savedAudiobooks.indexWhere((a) => a.id == audiobookId);
    if (idx < 0) return;
    final audiobook = state.savedAudiobooks[idx];
    final updated = audiobook.copyWith(isPinned: !audiobook.isPinned);
    final newList = List<Audiobook>.from(state.savedAudiobooks)..removeAt(idx);
    if (updated.isPinned) {
      final insertAt = newList.where((a) => a.isPinned).length;
      newList.insert(insertAt, updated);
    } else {
      newList.insert(0, updated);
    }
    state = state.copyWith(savedAudiobooks: newList);
    await _repo.updateAudiobook(updated);
  }

  Future<void> toggleEpisodeForLater(Song song) async {
    final isAlreadySaved = state.episodesForLater.any((s) => s.id == song.id);
    if (isAlreadySaved) {
      state = state.copyWith(
        episodesForLater:
            state.episodesForLater.where((s) => s.id != song.id).toList(),
      );
      await _repo.removeEpisodeForLater(song.id);
    } else {
      state = state.copyWith(
        episodesForLater: [song, ...state.episodesForLater],
      );
      await _repo.saveEpisodeForLater(song);
    }
  }

  Future<void> setEpisodesForLaterSortOrder(
      PlaylistTrackSortOrder order) async {
    state = state.copyWith(episodesForLaterSortOrder: order);
    // Persist sort order to settings
    final bridge = DatabaseBridge();
    await bridge.setSetting('episodes_for_later_sort_order', order.name);
  }

  Future<void> updateEpisodesForLaterOrder(List<Song> orderedEpisodes) async {
    final orderedIds = orderedEpisodes.map((s) => s.id).toList();
    state = state.copyWith(episodesForLater: orderedEpisodes);
    await _repo.updateEpisodesForLaterOrder(orderedIds);
  }
}

// ── Providers ─────────────────────────────────────────────────────────────────

final podcastProvider =
    NotifierProvider<PodcastNotifier, PodcastState>(PodcastNotifier.new);

final podcastSubscriptionsProvider = Provider<List<Podcast>>(
  (ref) {
    final subs = ref.watch(podcastProvider.select((s) => s.subscriptions));
    final sorted = List<Podcast>.from(subs);
    sorted.sort((a, b) {
      if (a.isPinned && !b.isPinned) return -1;
      if (!a.isPinned && b.isPinned) return 1;
      return 0;
    });
    return sorted;
  },
);

final savedAudiobooksProvider = Provider<List<Audiobook>>(
  (ref) {
    final books = ref.watch(podcastProvider.select((s) => s.savedAudiobooks));
    final sorted = List<Audiobook>.from(books);
    sorted.sort((a, b) {
      if (a.isPinned && !b.isPinned) return -1;
      if (!a.isPinned && b.isPinned) return 1;
      return 0;
    });
    return sorted;
  },
);

// ── Search providers ──────────────────────────────────────────────────────────

final podcastSearchResultsProvider =
    FutureProvider.family<List<Podcast>, String>((ref, query) async {
  if (query.trim().isEmpty) return [];
  final mgr = ref.watch(streamManagerProvider);
  final raw = await mgr.searchPodcasts(query);
  return raw
      .map((m) => Podcast(
            id: m['id'] as String,
            title: m['title'] as String,
            author: m['author'] as String?,
            thumbnailUrl: m['thumbnailUrl'] as String?,
            browseId: m['browseId'] as String?,
          ))
      .toList();
});

final audiobookSearchResultsProvider =
    FutureProvider.family<List<Audiobook>, String>((ref, query) async {
  if (query.trim().isEmpty) return [];
  final mgr = ref.watch(streamManagerProvider);
  final raw = await mgr.searchAudiobooks(query);
  return raw
      .map((m) => Audiobook(
            id: m['id'] as String,
            title: m['title'] as String,
            author: m['author'] as String?,
            thumbnailUrl: m['thumbnailUrl'] as String?,
            browseId: m['browseId'] as String?,
          ))
      .toList();
});
