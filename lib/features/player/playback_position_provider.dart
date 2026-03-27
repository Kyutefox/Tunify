import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Separate provider for playback position to avoid rebuilding entire PlayerState.
/// Position updates happen frequently and should only rebuild widgets that display the position.
class PlaybackPositionNotifier extends Notifier<Duration> {
  @override
  Duration build() => Duration.zero;

  void update(Duration position) {
    state = position;
  }

  void reset() {
    state = Duration.zero;
  }
}

final playbackPositionProvider =
    NotifierProvider<PlaybackPositionNotifier, Duration>(
  PlaybackPositionNotifier.new,
);

/// Separate provider for buffered position
class BufferedPositionNotifier extends Notifier<Duration> {
  @override
  Duration build() => Duration.zero;

  void update(Duration position) {
    state = position;
  }

  void reset() {
    state = Duration.zero;
  }
}

final bufferedPositionProvider =
    NotifierProvider<BufferedPositionNotifier, Duration>(
  BufferedPositionNotifier.new,
);
