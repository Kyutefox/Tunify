import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tunify/data/models/audiobook.dart';
import 'package:tunify/data/models/playback_position.dart';
import 'package:tunify/data/models/podcast.dart';
import 'package:tunify/data/models/track.dart';
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
    this.positions = const {},
    this.isLoading = false,
  });

  final List<Podcast> subscriptions;
  final List<Audiobook> savedAudiobooks;
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
    Map<String, PlaybackPosition>? positions,
    bool? isLoading,
  }) =>
      PodcastState(
        subscriptions: subscriptions ?? this.subscriptions,
        savedAudiobooks: savedAudiobooks ?? this.savedAudiobooks,
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
    final positions = await _repo.loadAllPositions();
    state = PodcastState(
      subscriptions: subs,
      savedAudiobooks: books,
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

  Future<void> clearPosition(
      String contentId, PlaybackContentType type) async {
    final key = '${contentId}_${type.name}';
    final updated = Map<String, PlaybackPosition>.from(state.positions);
    updated.remove(key);
    state = state.copyWith(positions: updated);
    await _repo.clearPosition(contentId, type);
  }
}

// ── Providers ─────────────────────────────────────────────────────────────────

final podcastProvider =
    NotifierProvider<PodcastNotifier, PodcastState>(PodcastNotifier.new);

final podcastSubscriptionsProvider = Provider<List<Podcast>>(
  (ref) => ref.watch(podcastProvider.select((s) => s.subscriptions)),
);

final savedAudiobooksProvider = Provider<List<Audiobook>>(
  (ref) => ref.watch(podcastProvider.select((s) => s.savedAudiobooks)),
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

final podcastEpisodesProvider =
    FutureProvider.family<List<Episode>, String>((ref, browseId) async {
  if (browseId.isEmpty) return [];
  final mgr = ref.watch(streamManagerProvider);
  
  // Use appropriate fetch method based on browseId type
  List<Track> tracks;
  if (browseId.startsWith('MPED')) {
    tracks = await mgr.fetchPodcastShowContent(browseId);
  } else if (browseId.startsWith('MPSPPL')) {
    tracks = await mgr.fetchPlaylistTracks(browseId);
  } else {
    tracks = await mgr.fetchPlaylistTracks(browseId);
  }
  
  return tracks
      .map((t) {
        // Parse date from artist field (contains date like "1d ago", "Mar 21")
        final dateStr = t.artist;
        return Episode(
          id: t.id,
          title: t.title,
          thumbnailUrl: t.thumbnailUrl,
          podcastTitle: null, // Could extract actual podcast name if available
          description: t.albumName, // Contains description
          publishedDate: dateStr, // Contains date like "1d ago", "Mar 21"
          durationSeconds: t.duration.inSeconds,
        );
      })
      .toList();
});
