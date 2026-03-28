import 'dart:async';

import 'package:just_audio/just_audio.dart' as ja;
import 'package:tunify_logger/tunify_logger.dart';

import 'audio_player_service.dart';

/// Drives a true simultaneous crossfade between two [AudioPlayerService] instances.
///
/// ## Two-phase flow
///
/// **Phase 1 — Pre-load** ([preloadSecondary]):
/// Called ~10 s before the crossfade window opens. Creates a secondary
/// [AudioPlayerService] and fires [AudioPlayerService.setAudioSourceForCrossfade]
/// asynchronously, giving ExoPlayer/AVPlayer time to reach STATE_READY before
/// the ramp begins. The volume ramp does NOT start in this phase.
///
/// **Phase 2 — Crossfade** ([beginCrossfade]):
/// Called when [crossfadeSecs] remain in the current track. If a preloaded
/// secondary exists it is reused ([source] is ignored); otherwise a fresh
/// secondary is created with fire-and-forget loading. The 50 ms ramp timer
/// starts immediately regardless of secondary load state:
/// ```
///   primary:   1.0 → 0.0  (fade out)
///   secondary: 0.0 → 1.0  (fade in — audible once the player is buffered)
/// ```
/// When the ramp finishes the secondary becomes the new primary: stream
/// controllers are re-wired atomically, the old primary is disposed without
/// releasing audio focus, and [onSwapComplete] notifies [PlayerNotifier].
///
/// ## Thread safety
/// All operations run on the Dart event loop (single-threaded). [_isCrossfading]
/// is set synchronously before any `await` so the [ProcessingState.completed]
/// guard in [PlayerNotifier] fires immediately, preventing race conditions with
/// the position stream listener.
///
/// ## Cancellation
/// All destructive operations (pause, stop, seek, setPlaylist) call
/// [cancelCrossfade], which also discards any preloaded secondary.
class CrossfadeEngine {
  CrossfadeEngine(AudioPlayerService primary) : _primary = primary {
    _rewireStreams();
  }

  AudioPlayerService _primary;
  AudioPlayerService? _secondary;

  bool _isCrossfading = false;
  bool _disposed = false;
  Timer? _fadeTimer;

  // ─── Forwarded broadcast streams ───────────────────────────────────────────────
  //
  // Streams are forwarded through controllers rather than exposed as raw getters
  // so that _rewireStreams() can atomically cut over to the new primary during a
  // swap. A raw getter (e.g. `=> _primary.positionStream`) would still deliver
  // stale events from the old player after the swap — potentially bypassing
  // guards in PlayerNotifier and causing spurious state updates.

  final _positionController = StreamController<Duration>.broadcast();
  final _durationController = StreamController<Duration?>.broadcast();
  final _stateController = StreamController<ja.PlayerState>.broadcast();
  final _currentIndexController = StreamController<int?>.broadcast();

  StreamSubscription<Duration>? _positionSub;
  StreamSubscription<Duration?>? _durationSub;
  StreamSubscription<ja.PlayerState>? _stateSub;
  StreamSubscription<int?>? _currentIndexSub;

  // ─── Public streams ────────────────────────────────────────────────────────────

  Stream<Duration> get positionStream => _positionController.stream;
  Stream<Duration?> get durationStream => _durationController.stream;
  Stream<ja.PlayerState> get playerStateStream => _stateController.stream;
  Stream<int?> get currentIndexStream => _currentIndexController.stream;

  /// Not forwarded — always reflects the live primary player.
  /// [TunifyAudioHandler] reads this as a point-in-time value, not a persistent
  /// subscription, so it does not need to survive a primary swap.
  Stream<Duration> get bufferedPositionStream => _primary.bufferedPositionStream;

  /// Sequence state is not forwarded — only the primary CAS exposes it.
  Stream<ja.SequenceState?> get sequenceStateStream =>
      _primary.sequenceStateStream;

  // ─── Public state ──────────────────────────────────────────────────────────────

  /// The underlying [AudioPlayer] of the active primary service.
  /// Read by [TunifyAudioHandler] for direct position/duration/speed access.
  ja.AudioPlayer get player => _primary.player;

  bool get isPlaying => _primary.isPlaying;
  Duration get position => _primary.position;
  Duration? get duration => _primary.duration;
  bool get isNormalizationEnabled => _primary.isNormalizationEnabled;

  /// `true` while the volume ramp timer is actively running.
  bool get isCrossfading => _isCrossfading;

  /// `true` when a secondary player has been preloaded but the ramp has not
  /// yet started. [PlayerNotifier] uses this to skip a redundant source-URL
  /// resolve in [beginCrossfade] when [preloadSecondary] already fetched it.
  bool get hasPreloadedSecondary => _secondary != null && !_isCrossfading;

  // ─── Proxy methods (all delegate to primary) ──────────────────────────────────

  Future<void> play() => _primary.play();

  /// Cancels any active crossfade or preload, then pauses the primary.
  Future<void> pause() async {
    cancelCrossfade();
    await _primary.pause();
  }

  Future<void> resume() => _primary.resume();

  /// Cancels any active crossfade or preload, then stops the primary.
  Future<void> stop() async {
    cancelCrossfade();
    await _primary.stop();
  }

  /// Cancels any active crossfade or preload, then seeks the primary.
  /// The next crossfade window is recalculated from the new position.
  Future<void> seek(Duration position) async {
    cancelCrossfade();
    await _primary.seek(position);
  }

  Future<void> togglePlayPause() => _primary.togglePlayPause();
  Future<void> setVolume(double v) => _primary.setVolume(v);
  Future<void> setSpeed(double speed) => _primary.setSpeed(speed);
  void setLoopMode(ja.LoopMode mode) => _primary.setLoopMode(mode);
  Future<void> setNormalization(bool enabled) =>
      _primary.setNormalization(enabled);
  Future<void> setNormalizationGainDb(double db) =>
      _primary.setNormalizationGainDb(db);

  /// Forwards a normalization gain to the secondary player when one exists.
  ///
  /// Applies during both the preload phase (secondary buffering, ramp not yet
  /// started) and the active ramp phase so the loudness transition is smooth
  /// from the very first volume tick.
  Future<void> setSecondaryNormalizationGainDb(double db) async {
    if (_secondary != null) await _secondary!.setNormalizationGainDb(db);
  }

  /// Cancels any active crossfade or preload, then loads a new playlist on the primary.
  Future<void> setPlaylist(
    List<ja.AudioSource> items, {
    int initialIndex = 0,
    Duration? initialPosition,
  }) async {
    cancelCrossfade();
    await _primary.setPlaylist(
      items,
      initialIndex: initialIndex,
      initialPosition: initialPosition,
    );
  }

  Future<void> setPlaylistIndex(int index, {Duration? position}) =>
      _primary.setPlaylistIndex(index, position: position);

  Future<void> addToPlaylist(ja.AudioSource item) =>
      _primary.addToPlaylist(item);

  Future<void> removeFromPlaylist(int index) =>
      _primary.removeFromPlaylist(index);

  Future<void> moveInPlaylist(int from, int to) =>
      _primary.moveInPlaylist(from, to);

  Future<void> playUrl(
    String url, {
    Map<String, String>? headers,
    Duration? initialPosition,
  }) =>
      _primary.playUrl(url, headers: headers, initialPosition: initialPosition);

  Future<void> setFileSource(String filePath) =>
      _primary.setFileSource(filePath);

  Future<void> playFile(String filePath) => _primary.playFile(filePath);

  // ─── Crossfade ─────────────────────────────────────────────────────────────────

  /// Phase 1: pre-loads [source] onto a secondary player without starting the
  /// fade timer.
  ///
  /// Call this ~10 s before [beginCrossfade] so ExoPlayer has time to reach
  /// STATE_READY. When [beginCrossfade] subsequently detects a preloaded
  /// secondary it reuses it and skips the init wait, making the next song
  /// audible from the very first volume tick of the ramp.
  ///
  /// No-op if a crossfade is already active or a secondary is already loaded.
  Future<void> preloadSecondary({
    required ja.AudioSource source,
    required bool normalizationEnabled,
  }) async {
    if (_disposed || _isCrossfading || _secondary != null) return;

    final secondary = AudioPlayerService.forCrossfade();
    _secondary = secondary;

    try {
      if (normalizationEnabled) await secondary.setNormalization(true);
      secondary.applyCrossfadeVolume(0.0);
    } catch (e) {
      logWarning('CrossfadeEngine: preload init failed — $e', tag: 'Crossfade');
      secondary.dispose();
      _secondary = null;
      return;
    }

    // Fire-and-forget: allow ExoPlayer to initialize its decoder and buffer data
    // before the fade window opens. Load failure is non-fatal — beginCrossfade
    // detects the invalid secondary via the identity check and falls back cleanly.
    secondary.setAudioSourceForCrossfade(source).catchError((Object e) {
      logWarning('CrossfadeEngine: preload source failed — $e', tag: 'Crossfade');
      if (!_disposed && !_isCrossfading && identical(_secondary, secondary)) {
        _secondary = null;
        secondary.dispose();
      }
    });

    logDebug('CrossfadeEngine: secondary preload started', tag: 'Crossfade');
  }

  /// Phase 2: starts the simultaneous volume ramp.
  ///
  /// If [hasPreloadedSecondary] is true the preloaded secondary is reused and
  /// [source] may be null (it is ignored). Otherwise [source] must be non-null
  /// and a fresh secondary is created with fire-and-forget loading.
  ///
  /// The 50 ms ramp timer starts immediately so the primary begins fading out
  /// without waiting for ExoPlayer to finish buffering.
  ///
  /// Returns `true` on success, `false` if another crossfade is already active.
  /// [onSecondaryLoadFailed] is called if the async load/play fails mid-ramp so
  /// the caller can fall back to normal track-completion handling.
  Future<bool> beginCrossfade({
    ja.AudioSource? source,
    required int crossfadeSecs,
    required bool normalizationEnabled,
    required void Function() onSwapComplete,
    void Function()? onSecondaryLoadFailed,
  }) async {
    if (_disposed || _isCrossfading) return false;

    // Set synchronously before any await. If the primary's
    // ConcatenatingAudioSource reaches its natural end during async setup, the
    // ProcessingState.completed guard in PlayerNotifier fires immediately,
    // preventing spurious _handleCompletion calls.
    _isCrossfading = true;

    final AudioPlayerService secondary;
    final bool wasPreloaded = _secondary != null;

    if (wasPreloaded) {
      // Reuse the preloaded secondary — the source URL was already resolved and
      // ExoPlayer has had extra time to reach STATE_READY.
      secondary = _secondary!;
      logDebug('CrossfadeEngine: reusing preloaded secondary', tag: 'Crossfade');
    } else {
      assert(source != null, 'source is required when no secondary is preloaded');
      // Dedicated crossfade constructor skips audio-session management so the
      // secondary does not steal audio focus from the primary.
      secondary = AudioPlayerService.forCrossfade();
      _secondary = secondary;

      try {
        if (normalizationEnabled) await secondary.setNormalization(true);
        secondary.applyCrossfadeVolume(0.0);
      } catch (e) {
        logWarning(
            'CrossfadeEngine: secondary init failed — $e', tag: 'Crossfade');
        secondary.dispose();
        _secondary = null;
        _isCrossfading = false;
        _primary.resetCrossfadeVolume().catchError((_) {});
        return false;
      }

      // Fire-and-forget: ExoPlayer's STATE_READY wait (codec init + buffering)
      // can take 5–15 s. Loading asynchronously lets the ramp timer start
      // immediately; the secondary fades in from 0 → audible as it buffers.
      secondary.setAudioSourceForCrossfade(source!).then((_) {
        if (!_disposed && _secondary != null && _isCrossfading) {
          return secondary.playForCrossfade();
        }
      }).catchError((Object e) {
        logWarning('CrossfadeEngine: secondary load/play failed — $e',
            tag: 'Crossfade');
        if (!_disposed) _abortCrossfade(onFailed: onSecondaryLoadFailed);
      });
    }

    if (wasPreloaded) {
      // Source already loaded (or nearly ready). Start playback now so the
      // secondary is audible from the first ramp tick.
      secondary.playForCrossfade().catchError((Object e) {
        logWarning('CrossfadeEngine: preloaded secondary play failed — $e',
            tag: 'Crossfade');
        if (!_disposed) _abortCrossfade(onFailed: onSecondaryLoadFailed);
      });
    }

    final totalMs = crossfadeSecs * 1000;
    // PERF: Stopwatch.elapsedMilliseconds is cheaper than DateTime.now()
    // (avoids a syscall + object allocation on every tick).
    final sw = Stopwatch()..start();

    _fadeTimer?.cancel();
    // PERF: 50 ms tick (20fps) vs original 16 ms (60fps).
    // Volume fading at 20fps is perceptually identical to 60fps for audio,
    // and cuts platform-channel setVolume() calls from 60/s to 20/s during
    // the crossfade window, reducing method-channel pressure on the UI thread.
    _fadeTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      try {
        if (_disposed) {
          timer.cancel();
          return;
        }
        final t = (sw.elapsedMilliseconds / totalMs).clamp(0.0, 1.0);

        _primary.applyCrossfadeVolume(1.0 - t);
        _secondary?.applyCrossfadeVolume(t);

        if (t >= 1.0) {
          timer.cancel();
          sw.stop();
          if (!_disposed) {
            // Schedule the swap on the event loop — not inside the timer callback —
            // so async work in _completeSwap doesn't block the microtask queue.
            Future.microtask(() => _completeSwap(onSwapComplete));
          }
        }
      } catch (e) {
        timer.cancel();
        sw.stop();
        logWarning(
          'CrossfadeEngine: ramp timer error — aborting crossfade. $e',
          tag: 'Crossfade',
        );
        _abortCrossfade(onFailed: onSecondaryLoadFailed);
      }
    });

    logDebug('CrossfadeEngine: ramp started — ${crossfadeSecs}s',
        tag: 'Crossfade');
    return true;
  }

  /// Discards any active crossfade or preloaded secondary without triggering
  /// [onSwapComplete]. The primary continues at full volume.
  ///
  /// Safe to call even when no crossfade or preload is active.
  void cancelCrossfade() {
    if (!_isCrossfading && _secondary == null) return;
    final wasActiveRamp = _isCrossfading;
    _abortCrossfade();
    // Log at warning level so unexpected cancellations (e.g. triggered by
    // setPlaylist mid-crossfade) are always visible in release logs.
    logWarning(
      wasActiveRamp
          ? 'CrossfadeEngine: crossfade cancelled'
          : 'CrossfadeEngine: preload cancelled',
      tag: 'Crossfade',
    );
  }

  // ─── Private ───────────────────────────────────────────────────────────────────

  /// Tears down the secondary player and resets all crossfade/preload state.
  ///
  /// Called by [cancelCrossfade], error paths in [beginCrossfade], and the ramp
  /// timer error handler. [onFailed] is invoked after cleanup so callers can
  /// trigger fallback logic (e.g. [_handleCompletion] in [PlayerNotifier]).
  void _abortCrossfade({void Function()? onFailed}) {
    _fadeTimer?.cancel();
    _fadeTimer = null;
    _isCrossfading = false;
    final sec = _secondary;
    _secondary = null;
    // dispose() releases native resources without calling session.setActive(false),
    // so the primary's audio session remains uninterrupted.
    sec?.dispose();
    _primary.resetCrossfadeVolume().catchError((_) {});
    onFailed?.call();
  }

  Future<void> _completeSwap(void Function() onSwapComplete) async {
    logDebug(
      'CrossfadeEngine: _completeSwap entered — disposed=$_disposed '
      'isCrossfading=$_isCrossfading secondary=${_secondary != null} '
      'secState=${_secondary?.player.processingState}',
      tag: 'Crossfade',
    );
    if (_disposed || !_isCrossfading || _secondary == null) {
      logWarning(
        'CrossfadeEngine: _completeSwap bailed — disposed=$_disposed '
        'isCrossfading=$_isCrossfading secondary=${_secondary != null}',
        tag: 'Crossfade',
      );
      return;
    }

    final oldPrimary = _primary;
    _primary = _secondary!;
    _secondary = null;

    // Re-wire streams BEFORE clearing _isCrossfading. Cancelling the old
    // primary's subscriptions first ensures no stale events (e.g.
    // ProcessingState.completed, CAS index advance) escape through the forwarded
    // controllers to PlayerNotifier while the isCrossfading guard is still raised.
    _rewireStreams();

    // Safe to clear now — all old-primary stream paths are already cut.
    _isCrossfading = false;

    // Guarantee full volume on the new primary (guards against float rounding).
    await _primary.resetCrossfadeVolume();

    // dispose() releases native audio resources without session.setActive(false),
    // so the active audio session is preserved for the new primary.
    oldPrimary.dispose();

    logDebug('CrossfadeEngine: swap complete — new primary active',
        tag: 'Crossfade');
    onSwapComplete();
  }

  void _rewireStreams() {
    _positionSub?.cancel();
    _durationSub?.cancel();
    _stateSub?.cancel();
    _currentIndexSub?.cancel();

    _positionSub = _primary.positionStream.listen(_positionController.add);
    _durationSub = _primary.durationStream.listen(_durationController.add);
    _stateSub = _primary.playerStateStream.listen(_stateController.add);
    _currentIndexSub =
        _primary.currentIndexStream.listen(_currentIndexController.add);
  }

  void dispose() {
    _disposed = true;
    cancelCrossfade();
    _positionSub?.cancel();
    _durationSub?.cancel();
    _stateSub?.cancel();
    _currentIndexSub?.cancel();
    _positionController.close();
    _durationController.close();
    _stateController.close();
    _currentIndexController.close();
    _primary.dispose();
  }
}
