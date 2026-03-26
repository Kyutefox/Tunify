import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tunify/features/player/player_state_provider.dart';

/// End time (UTC) when the sleep timer will stop playback, or end-of-track mode.
/// UI can compute remaining as endTime.difference(DateTime.now()).
class SleepTimerState {
  const SleepTimerState({this.endTime, this.endOfTrack = false});

  final DateTime? endTime;
  /// End-of-track mode; nullable for backwards compatibility (e.g. after hot reload).
  final bool? endOfTrack;

  bool get isActive => endTime != null || (endOfTrack == true);

  /// Remaining time; null if no timer, end-of-track mode, or already expired.
  Duration? get remaining {
    if (endTime == null) return null;
    final r = endTime!.difference(DateTime.now());
    return r.isNegative ? Duration.zero : r;
  }
}

/// Controls the sleep timer: either a fixed-duration countdown or end-of-track mode.
///
/// Pauses the player when the countdown expires or when [checkEndOfTrack]
/// detects that the current track is within 1 second of ending.
class SleepTimerNotifier extends Notifier<SleepTimerState> {
  Timer? _sleepTimer;
  Timer? _tickTimer;

  @override
  SleepTimerState build() {
    ref.listen<PlayerState>(playerProvider, (_, next) {
      checkEndOfTrack(next);
    });
    return const SleepTimerState();
  }

  void setTimer(Duration duration) {
    _cancelTimers();
    final end = DateTime.now().add(duration);
    state = SleepTimerState(endTime: end, endOfTrack: false);
    _sleepTimer = Timer(duration, _onTimerFired);
    _tickTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (state.endTime == null) return;
      state = SleepTimerState(endTime: state.endTime, endOfTrack: state.endOfTrack);
    });
  }

  void setEndOfTrack() {
    _cancelTimers();
    state = const SleepTimerState(endOfTrack: true);
  }

  void _onTimerFired() {
    _cancelTimers();
    state = const SleepTimerState();
    ref.read(playerProvider.notifier).pause();
  }

  void cancel() {
    _cancelTimers();
    state = const SleepTimerState();
  }

  /// Called when player state changes; pauses at end of current track if endOfTrack is set.
  void checkEndOfTrack(PlayerState player) {
    if (state.endOfTrack != true) return;
    final duration = player.duration;
    if (duration == null || duration.inMilliseconds <= 0) return;
    final position = player.position;
    if (position >= duration - const Duration(seconds: 1)) {
      cancel();
      ref.read(playerProvider.notifier).pause();
    }
  }

  void _cancelTimers() {
    _sleepTimer?.cancel();
    _tickTimer?.cancel();
    _sleepTimer = null;
    _tickTimer = null;
  }
}

final sleepTimerProvider =
    NotifierProvider<SleepTimerNotifier, SleepTimerState>(SleepTimerNotifier.new);
