import 'dart:async';

import 'package:just_audio/just_audio.dart' as ja;
import 'package:tunify_logger/tunify_logger.dart';

import 'audio_player_service.dart';

/// Drives a true simultaneous crossfade between two [AudioPlayerService] instances.
///
/// ### How it works
/// One [AudioPlayerService] is always the **primary** — all normal playback
/// operations (play, pause, seek, playlist management) delegate to it.
///
/// When [beginCrossfade] is called:
/// 1. A fresh secondary [AudioPlayerService] is created and loaded with the next
///    song's resolved [AudioSource], started at volume 0.
/// 2. A 50 ms periodic timer ramps volumes simultaneously:
///    - primary:   1.0 → 0.0  (fade out)
///    - secondary: 0.0 → 1.0  (fade in)
/// 3. When the ramp finishes, secondary becomes the new primary:
///    - Stream controllers are re-wired (all existing subscribers continue
///      receiving events from the correct player — no re-subscription needed).
///    - The old primary is disposed **without** calling `session.setActive(false)`
///      so the active audio session is not interrupted.
///    - [onSwapComplete] is invoked so [PlayerNotifier] can update app state.
///
/// All destructive operations (pause, stop, seek, setPlaylist) call
/// [cancelCrossfade] first, ensuring the primary always plays cleanly.
class CrossfadeEngine {
  CrossfadeEngine(AudioPlayerService primary) : _primary = primary {
    _rewireStreams();
  }

  AudioPlayerService _primary;
  AudioPlayerService? _secondary;

  bool _isCrossfading = false;
  bool _disposed = false;
  Timer? _fadeTimer;

  // ─── Forwarded broadcast streams (always from the active primary) ─────────────

  final _positionController = StreamController<Duration>.broadcast();
  final _durationController = StreamController<Duration?>.broadcast();
  final _stateController = StreamController<ja.PlayerState>.broadcast();
  // currentIndexStream is forwarded through a controller so that _rewireStreams()
  // can atomically cut over to the new primary before _isCrossfading is cleared.
  // A raw getter (=> _primary.currentIndexStream) would still deliver events from
  // the old ConcatenatingAudioSource to PlayerNotifier after the swap, bypassing
  // the isCrossfading guard and causing a spurious double state-update.
  final _currentIndexController = StreamController<int?>.broadcast();

  StreamSubscription<Duration>? _positionSub;
  StreamSubscription<Duration?>? _durationSub;
  StreamSubscription<ja.PlayerState>? _stateSub;
  StreamSubscription<int?>? _currentIndexSub;

  // ─── Public streams ────────────────────────────────────────────────────────────

  Stream<Duration> get positionStream => _positionController.stream;
  Stream<Duration?> get durationStream => _durationController.stream;
  Stream<ja.PlayerState> get playerStateStream => _stateController.stream;

  Stream<Duration> get bufferedPositionStream =>
      _primary.bufferedPositionStream;
  Stream<int?> get currentIndexStream => _currentIndexController.stream;
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

  /// `true` while a crossfade ramp is actively running.
  bool get isCrossfading => _isCrossfading;

  // ─── Proxy methods (all delegate to primary) ──────────────────────────────────

  Future<void> play() => _primary.play();

  /// Cancels any in-progress crossfade, then pauses the primary.
  Future<void> pause() async {
    cancelCrossfade();
    await _primary.pause();
  }

  Future<void> resume() => _primary.resume();

  /// Cancels any in-progress crossfade, then stops the primary.
  Future<void> stop() async {
    cancelCrossfade();
    await _primary.stop();
  }

  /// Cancels any in-progress crossfade, then seeks the primary.
  /// The next crossfade window is recalculated from the new position.
  Future<void> seek(Duration position) async {
    cancelCrossfade();
    await _primary.seek(position);
  }

  Future<void> togglePlayPause() => _primary.togglePlayPause();
  Future<void> setVolume(double v) => _primary.setVolume(v);
  void setLoopMode(ja.LoopMode mode) => _primary.setLoopMode(mode);
  Future<void> setNormalization(bool enabled) =>
      _primary.setNormalization(enabled);
  Future<void> setNormalizationGainDb(double db) =>
      _primary.setNormalizationGainDb(db);

  /// Forwards a normalization gain to the **secondary** player while a
  /// crossfade is in progress. No-op when not crossfading.
  Future<void> setSecondaryNormalizationGainDb(double db) async {
    if (_isCrossfading) await _secondary?.setNormalizationGainDb(db);
  }

  /// Cancels any in-progress crossfade, then loads a new playlist on the primary.
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

  // ─── True crossfade ────────────────────────────────────────────────────────────

  /// Pre-loads [source] onto a secondary player without starting the fade timer.
  ///
  /// Call this ~10 s before the crossfade window so ExoPlayer has time to
  /// initialize its decoder and buffer enough data. When [beginCrossfade] is
  /// subsequently called it reuses the already-loaded secondary, meaning Song B
  /// is audible from the very first tick of the volume ramp.
  ///
  /// Safe to call when no crossfade is active. No-op if a crossfade is already
  /// in progress or a secondary is already preloaded.
  Future<void> preloadSecondary({
    required ja.AudioSource source,
    required bool normalizationEnabled,
  }) async {
    if (_disposed || _isCrossfading || _secondary != null) return;

    final secondary = AudioPlayerService.forCrossfade();
    _secondary = secondary;

    try {
      if (normalizationEnabled) {
        await secondary.setNormalization(true);
      }
      await secondary.applyCrossfadeVolume(0.0);
    } catch (e) {
      logWarning(
        'CrossfadeEngine: preload init failed — $e',
        tag: 'Crossfade',
      );
      secondary.dispose();
      _secondary = null;
      return;
    }

    // Fire-and-forget: give ExoPlayer time to reach STATE_READY before the
    // crossfade window opens. Errors here are non-fatal; beginCrossfade will
    // detect the failed secondary and fall back gracefully.
    secondary.setAudioSourceForCrossfade(source).catchError((Object e) {
      logWarning(
        'CrossfadeEngine: preload source failed — $e',
        tag: 'Crossfade',
      );
      if (!_disposed && !_isCrossfading && identical(_secondary, secondary)) {
        _secondary = null;
        secondary.dispose();
      }
    });

    logDebug('CrossfadeEngine: secondary preload started', tag: 'Crossfade');
  }

  /// Begins a true simultaneous crossfade.
  ///
  /// Creates a secondary [AudioPlayerService], loads [source] on it, starts
  /// playing at volume 0, then ramps primary 1→0 and secondary 0→1 over
  /// [crossfadeSecs] seconds. On completion the secondary becomes the new
  /// primary, streams are re-wired, and [onSwapComplete] is invoked.
  ///
  /// The fade timer starts immediately — secondary loading is fire-and-forget
  /// so ExoPlayer's STATE_READY wait does not delay the primary fade-out.
  /// If the secondary fails to load, [onSecondaryLoadFailed] is called so the
  /// caller can fall back to normal track completion handling.
  ///
  /// Returns `true` if the crossfade started successfully, `false` if another
  /// crossfade was already in progress.
  Future<bool> beginCrossfade({
    required ja.AudioSource source,
    required int crossfadeSecs,
    required bool normalizationEnabled,
    required void Function() onSwapComplete,
    void Function()? onSecondaryLoadFailed,
  }) async {
    if (_disposed || _isCrossfading) return false;

    // ── Set the flag BEFORE any async work ─────────────────────────────────
    // The primary player's ConcatenatingAudioSource may reach its natural end
    // while the secondary is loading (ExoPlayer codec init takes 1–3 s). Setting
    // _isCrossfading = true here ensures that the ProcessingState.completed and
    // currentIndexStream guards in PlayerNotifier fire immediately, preventing a
    // spurious _handleCompletion() call or state corruption during the load window.
    _isCrossfading = true;

    final AudioPlayerService secondary;
    final bool wasPreloaded = _secondary != null;

    if (wasPreloaded) {
      // Reuse the secondary that preloadSecondary() already created and loaded.
      // ExoPlayer has had extra time to reach STATE_READY, so Song B should be
      // audible from the first tick of the fade ramp.
      secondary = _secondary!;
      logDebug(
        'CrossfadeEngine: reusing preloaded secondary',
        tag: 'Crossfade',
      );
    } else {
      // No preload — create a fresh secondary. ExoPlayer will still need time
      // to initialize, so Song B may be silent for the first few seconds of the
      // ramp on slow devices. Use the dedicated crossfade constructor so it
      // skips audio-session management and does not steal audio focus from primary.
      secondary = AudioPlayerService.forCrossfade();
      _secondary = secondary;

      // Fast synchronous-ish setup (no network/IO waits).
      try {
        if (normalizationEnabled) {
          await secondary.setNormalization(true);
        }
        // Start at silence so the ramp has full range.
        await secondary.applyCrossfadeVolume(0.0);
      } catch (e) {
        logWarning(
          'CrossfadeEngine: secondary init failed — $e',
          tag: 'Crossfade',
        );
        secondary.dispose();
        _secondary = null;
        _isCrossfading = false;
        _primary.resetCrossfadeVolume().catchError((_) {});
        return false;
      }

      // Fire-and-forget: load the source without blocking the timer.
      secondary.setAudioSourceForCrossfade(source).then((_) {
        if (!_disposed && _secondary != null && _isCrossfading) {
          return secondary.playForCrossfade();
        }
      }).catchError((Object e) {
        logWarning(
          'CrossfadeEngine: secondary load/play failed — $e',
          tag: 'Crossfade',
        );
        if (!_disposed) {
          _fadeTimer?.cancel();
          _fadeTimer = null;
          _isCrossfading = false;
          final sec = _secondary;
          _secondary = null;
          sec?.dispose();
          _primary.resetCrossfadeVolume().catchError((_) {});
          onSecondaryLoadFailed?.call();
        }
      });
    }

    if (wasPreloaded) {
      // Source is already loaded (or very close to ready). Start playback now
      // so Song B is audible from the first volume tick. Errors are non-fatal;
      // the secondary will still ramp in when ExoPlayer becomes ready.
      secondary.playForCrossfade().catchError((Object e) {
        logWarning(
          'CrossfadeEngine: preloaded secondary play failed — $e',
          tag: 'Crossfade',
        );
        if (!_disposed) {
          _fadeTimer?.cancel();
          _fadeTimer = null;
          _isCrossfading = false;
          final sec = _secondary;
          _secondary = null;
          sec?.dispose();
          _primary.resetCrossfadeVolume().catchError((_) {});
          onSecondaryLoadFailed?.call();
        }
      });
    }

    // Start the fade timer immediately — do not wait for secondary to be ready.
    final totalMs = crossfadeSecs * 1000;
    final startTime = DateTime.now();

    _fadeTimer?.cancel();
    _fadeTimer =
        Timer.periodic(const Duration(milliseconds: 50), (timer) async {
      try {
        if (_disposed) {
          timer.cancel();
          return;
        }
        final elapsed = DateTime.now().difference(startTime).inMilliseconds;
        final t = (elapsed / totalMs).clamp(0.0, 1.0);

        // Drive both ramps in parallel for minimal latency skew.
        await Future.wait([
          _primary.applyCrossfadeVolume(1.0 - t),
          _secondary?.applyCrossfadeVolume(t) ?? Future.value(),
        ]);

        if (t >= 1.0) {
          timer.cancel();
          if (!_disposed) {
            // Schedule swap on the event loop, not inside the timer callback.
            Future.microtask(() => _completeSwap(onSwapComplete));
          }
        }
      } catch (e) {
        timer.cancel();
        logWarning(
          'CrossfadeEngine: fade timer error — cancelling crossfade. $e',
          tag: 'Crossfade',
        );
        _isCrossfading = false;
        final sec = _secondary;
        _secondary = null;
        sec?.dispose();
        _primary.resetCrossfadeVolume().catchError((_) {});
      }
    });

    logDebug(
      'CrossfadeEngine: crossfade ramp started — ${crossfadeSecs}s '
      '(isCrossfading=$_isCrossfading)',
      tag: 'Crossfade',
    );
    return true;
  }

  /// Stops an in-progress crossfade without triggering [onSwapComplete].
  ///
  /// The primary player continues at full volume; the secondary is discarded.
  /// Safe to call even when no crossfade is active.
  void cancelCrossfade() {
    if (!_isCrossfading && _secondary == null) return;
    _fadeTimer?.cancel();
    _fadeTimer = null;
    _isCrossfading = false;

    final sec = _secondary;
    _secondary = null;
    // dispose() releases native resources without calling session.setActive(false),
    // so the primary's audio session remains uninterrupted.
    sec?.dispose();
    _primary.resetCrossfadeVolume().catchError((_) {});

    // Use logWarning so cancellations are always visible in release logs —
    // unexpected cancellations (e.g. from setPlaylist) are the primary failure
    // mode for crossfade and must be immediately diagnosable.
    logWarning('CrossfadeEngine: crossfade cancelled', tag: 'Crossfade');
  }

  // ─── Internal ──────────────────────────────────────────────────────────────────

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

    // ── Re-wire BEFORE clearing _isCrossfading ──────────────────────────────
    // This is the critical ordering: cancelling the old primary's subscriptions
    // first ensures that no stale events (ProcessingState.completed, idx advance
    // from ConcatenatingAudioSource) can escape through the forwarded controllers
    // and reach PlayerNotifier with the isCrossfading guard already lowered.
    _rewireStreams();

    // Now safe to clear the flag — all old-primary stream paths are already cut.
    _isCrossfading = false;

    // Guarantee full volume on the new primary (guards against float rounding).
    await _primary.resetCrossfadeVolume();

    // Dispose the old primary via dispose() — releases native audio resources
    // WITHOUT calling session.setActive(false), so the active session is kept.
    oldPrimary.dispose();

    logDebug(
      'CrossfadeEngine: swap complete — new primary active',
      tag: 'Crossfade',
    );
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
