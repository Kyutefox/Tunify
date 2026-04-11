import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tunify/v1/data/models/lyrics_result.dart';
import 'package:tunify/v1/features/player/player_state_provider.dart';

/// Lyrics fetch state: loading, loaded, or error.
class LyricsState {
  final LyricsResult? lyrics;
  final bool isLoading;
  final String? error;

  const LyricsState({this.lyrics, this.isLoading = false, this.error});

  static const initial = LyricsState();

  bool get hasLyrics => lyrics != null && !lyrics!.isEmpty;
}

/// Fetches and caches lyrics for the currently playing track.
///
/// Deduplicates in-flight requests: if [fetchForVideo] is called again with the
/// same [videoId] while lyrics are already loaded, no network call is made.
/// Stale responses from superseded requests are discarded via [_currentVideoId] checks.
class LyricsNotifier extends Notifier<LyricsState> {
  String? _currentVideoId;

  @override
  LyricsState build() => LyricsState.initial;

  /// Fetches lyrics for [videoId], skipping the request if lyrics are already loaded for that ID.
  Future<void> fetchForVideo(String videoId) async {
    if (videoId == _currentVideoId && state.hasLyrics) return;

    _currentVideoId = videoId;
    state = const LyricsState(isLoading: true);

    try {
      final result = await ref.read(streamManagerProvider).getLyrics(videoId);
      if (_currentVideoId != videoId) return;

      state = LyricsState(lyrics: result);
    } catch (e) {
      if (_currentVideoId != videoId) return;
      state = LyricsState(error: e.toString());
    }
  }

  void clear() {
    _currentVideoId = null;
    state = LyricsState.initial;
  }
}

final lyricsProvider =
    NotifierProvider<LyricsNotifier, LyricsState>(LyricsNotifier.new);
