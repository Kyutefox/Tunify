import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tunify/v2/features/home/data/repositories/home_repository_impl.dart';
import 'package:tunify/v2/features/home/domain/entities/home_feed.dart';
import 'package:tunify/v2/features/home/domain/repositories/home_repository.dart';

final homeRepositoryProvider = Provider<HomeRepository>((ref) {
  return HomeRepositoryImpl();
});

final homeFeedProvider = FutureProvider<HomeFeed>((ref) async {
  final repo = ref.watch(homeRepositoryProvider);
  return repo.loadHomeFeed();
});

/// Which top-level library band is focused (home filter row).
enum HomeContentBand { all, music, podcasts }

/// Multi-segment filters: second segment starts hidden until the primary is used to expand it.
@immutable
class HomeFilterPillsState {
  const HomeFilterPillsState({
    this.band = HomeContentBand.all,
    this.musicSecondaryOn = false,
    this.podcastsSecondaryOn = false,
    this.musicSecondaryExpanded = false,
    this.podcastsSecondaryExpanded = false,
  });

  final HomeContentBand band;
  final bool musicSecondaryOn;
  final bool podcastsSecondaryOn;
  /// Trailing “Music” segment is visible (after animated reveal).
  final bool musicSecondaryExpanded;
  /// Trailing “Podcasts” segment is visible.
  final bool podcastsSecondaryExpanded;

  HomeFilterPillsState copyWith({
    HomeContentBand? band,
    bool? musicSecondaryOn,
    bool? podcastsSecondaryOn,
    bool? musicSecondaryExpanded,
    bool? podcastsSecondaryExpanded,
  }) {
    return HomeFilterPillsState(
      band: band ?? this.band,
      musicSecondaryOn: musicSecondaryOn ?? this.musicSecondaryOn,
      podcastsSecondaryOn: podcastsSecondaryOn ?? this.podcastsSecondaryOn,
      musicSecondaryExpanded: musicSecondaryExpanded ?? this.musicSecondaryExpanded,
      podcastsSecondaryExpanded:
          podcastsSecondaryExpanded ?? this.podcastsSecondaryExpanded,
    );
  }
}

class HomeFilterPillsNotifier extends Notifier<HomeFilterPillsState> {
  @override
  HomeFilterPillsState build() => const HomeFilterPillsState();

  void selectAll() {
    state = const HomeFilterPillsState();
  }

  void tapMusicPrimary() {
    if (state.band != HomeContentBand.music) {
      state = const HomeFilterPillsState(
        band: HomeContentBand.music,
        musicSecondaryOn: false,
        podcastsSecondaryOn: false,
        musicSecondaryExpanded: true,
        podcastsSecondaryExpanded: false,
      );
      return;
    }
    if (!state.musicSecondaryExpanded) {
      state = state.copyWith(musicSecondaryExpanded: true);
      return;
    }
    if (state.musicSecondaryOn) {
      state = state.copyWith(musicSecondaryOn: false);
      return;
    }
    state = state.copyWith(musicSecondaryExpanded: false);
  }

  void tapMusicSecondary() {
    if (!state.musicSecondaryExpanded) return;
    if (state.band != HomeContentBand.music) {
      state = const HomeFilterPillsState(
        band: HomeContentBand.music,
        musicSecondaryOn: true,
        podcastsSecondaryOn: false,
        musicSecondaryExpanded: true,
        podcastsSecondaryExpanded: false,
      );
      return;
    }
    state = state.copyWith(musicSecondaryOn: !state.musicSecondaryOn);
  }

  void tapPodcastsPrimary() {
    if (state.band != HomeContentBand.podcasts) {
      state = const HomeFilterPillsState(
        band: HomeContentBand.podcasts,
        musicSecondaryOn: false,
        podcastsSecondaryOn: false,
        musicSecondaryExpanded: false,
        podcastsSecondaryExpanded: true,
      );
      return;
    }
    if (!state.podcastsSecondaryExpanded) {
      state = state.copyWith(podcastsSecondaryExpanded: true);
      return;
    }
    if (state.podcastsSecondaryOn) {
      state = state.copyWith(podcastsSecondaryOn: false);
      return;
    }
    state = state.copyWith(podcastsSecondaryExpanded: false);
  }

  void tapPodcastsSecondary() {
    if (!state.podcastsSecondaryExpanded) return;
    if (state.band != HomeContentBand.podcasts) {
      state = const HomeFilterPillsState(
        band: HomeContentBand.podcasts,
        musicSecondaryOn: false,
        podcastsSecondaryOn: true,
        musicSecondaryExpanded: false,
        podcastsSecondaryExpanded: true,
      );
      return;
    }
    state = state.copyWith(podcastsSecondaryOn: !state.podcastsSecondaryOn);
  }
}

final homeFilterPillsProvider =
    NotifierProvider<HomeFilterPillsNotifier, HomeFilterPillsState>(
  HomeFilterPillsNotifier.new,
);
