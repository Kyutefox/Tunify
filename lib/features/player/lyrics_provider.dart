import 'package:flutter_riverpod/legacy.dart';

import 'package:tunify/data/models/lyrics_result.dart';
import 'package:tunify/features/settings/music_stream_manager.dart';
import 'package:tunify/features/player/player_state_provider.dart';

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
class LyricsNotifier extends StateNotifier<LyricsState> {
  final MusicStreamManager _streamManager;
  String? _currentVideoId;

  LyricsNotifier(this._streamManager) : super(LyricsState.initial);

  /// Fetches lyrics for [videoId], skipping the request if lyrics are already loaded for that ID.
  Future<void> fetchForVideo(String videoId) async {
    if (videoId == _currentVideoId && state.hasLyrics) return;

    _currentVideoId = videoId;
    state = const LyricsState(isLoading: true);

    try {
      final result = await _streamManager.getLyrics(videoId);
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
    StateNotifierProvider<LyricsNotifier, LyricsState>((ref) {
  final streamManager = ref.watch(streamManagerProvider);
  return LyricsNotifier(streamManager);
});
