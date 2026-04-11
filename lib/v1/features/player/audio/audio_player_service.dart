import 'dart:async';
import 'dart:io';

import 'package:tunify/v1/core/utils/platform_utils.dart';
import 'dart:math' as math;

import 'package:audio_session/audio_session.dart';
import 'package:just_audio/just_audio.dart';
import 'package:tunify/v1/core/utils/app_log.dart';

import 'package:tunify_source_youtube_music/tunify_source_youtube_music.dart';

/// Thin wrapper over [AudioPlayer] (just_audio) that:
/// - Configures the audio session for music playback.
/// - Applies platform-appropriate settings (iOS uses a single AVPlayer source;
///   Android uses [setAudioSources] for queue playback).
/// - Manages [AndroidLoudnessEnhancer] and iOS volume scaling for normalization.
/// - Re-exposes player streams through broadcast [StreamController]s so the app
///   can subscribe multiple times without `StreamAlreadySubscribed` errors.
class AudioPlayerService {
  late AudioPlayer _player;
  AndroidLoudnessEnhancer? _loudnessEnhancer;
  AndroidEqualizer? _equalizer;
  bool _normalizationEnabled = false;
  double _bassBoostLevel = 0.0; // 0.0–1.0
  late final Future<AudioSession> _audioSessionReady;
  // Whether this instance is a secondary crossfade player.
  // Secondary players share the primary's audio focus and must never call
  // session.setActive(true) — doing so triggers requestAudioFocus which can
  // deliver AUDIOFOCUS_LOSS to the primary, causing the Android MediaCodec
  // resource manager to reclaim the primary's decoder mid-crossfade.
  final bool _isCrossfadePlayer;

  final StreamController<Duration> _positionController =
      StreamController<Duration>.broadcast();
  final StreamController<Duration?> _durationController =
      StreamController<Duration?>.broadcast();
  final StreamController<PlayerState> _playerStateController =
      StreamController<PlayerState>.broadcast();

  StreamSubscription<Duration>? _positionSub;
  StreamSubscription<Duration?>? _durationSub;
  StreamSubscription<PlayerState>? _playerStateSub;

  /// Creates a primary [AudioPlayerService] that owns audio-session management.
  AudioPlayerService() : _isCrossfadePlayer = false {
    _initPlayer(handleInterruptions: true);
    _audioSessionReady = _configureAudioSession();
    _forwardFrom(_player);
  }

  /// Creates a secondary [AudioPlayerService] for use inside [CrossfadeEngine].
  ///
  /// The secondary player intentionally skips all audio-session and audio-focus
  /// management ([handleInterruptions] is disabled, [session.setActive] is never
  /// called). This prevents the AUDIOFOCUS_LOSS event that would otherwise be
  /// delivered to the primary player when the secondary calls requestAudioFocus,
  /// which in turn causes the Android MediaCodec resource manager to reclaim the
  /// primary's decoder and break the in-flight crossfade.
  AudioPlayerService.forCrossfade() : _isCrossfadePlayer = true {
    _initPlayer(handleInterruptions: false);
    // Reuse the already-configured, already-active session — no configure() or
    // setActive() calls needed (and must not be made).
    _audioSessionReady = AudioSession.instance;
    _forwardFrom(_player);
  }

  void _initPlayer({required bool handleInterruptions}) {
    if (Platform.isAndroid) {
      _loudnessEnhancer = AndroidLoudnessEnhancer();
      _loudnessEnhancer!.setEnabled(false);
      _equalizer = AndroidEqualizer();
      _equalizer!.setEnabled(false);
      _player = AudioPlayer(
        handleInterruptions: handleInterruptions,
        audioPipeline: AudioPipeline(
          androidAudioEffects: [_loudnessEnhancer!, _equalizer!],
        ),
      );
    } else {
      _player = AudioPlayer(handleInterruptions: handleInterruptions);
    }
  }

  void _forwardFrom(AudioPlayer p) {
    _positionSub?.cancel();
    _durationSub?.cancel();
    _playerStateSub?.cancel();
    _positionSub = p.positionStream.listen(_positionController.add);
    _durationSub = p.durationStream.listen(_durationController.add);
    _playerStateSub = p.playerStateStream.listen(_playerStateController.add);
  }

  Future<AudioSession> _configureAudioSession() async {
    final session = await AudioSession.instance;
    await session.configure(AudioSessionConfiguration.music());
    return session;
  }

  Future<void> _ensureAudioSessionActive() async {
    // Secondary (crossfade) players must never request audio focus — the primary
    // holds it for the lifetime of the crossfade.
    if (_isCrossfadePlayer) return;
    final session = await _audioSessionReady;
    // Explicitly activating the session requests audio focus and prevents
    // silent playback on some devices after a cold start.
    await session.setActive(true);
  }

  AudioPlayer get player => _player;

  Stream<Duration> get positionStream => _positionController.stream;
  Stream<Duration?> get durationStream => _durationController.stream;
  Stream<Duration> get bufferedPositionStream => _player.bufferedPositionStream;
  Stream<PlayerState> get playerStateStream => _playerStateController.stream;
  Stream<int?> get currentIndexStream => _player.currentIndexStream;
  Stream<SequenceState?> get sequenceStateStream => _player.sequenceStateStream;
  bool get isPlaying => _player.playing;
  Duration get position => _player.position;
  Duration? get duration => _player.duration;

  Future<void> setPlaylist(
    List<AudioSource> items, {
    int initialIndex = 0,
    Duration? initialPosition,
  }) async {
    if (items.isEmpty) return;
    // Audio session must be configured before activating the native platform.
    await _audioSessionReady;
    if (isApplePlatform) {
      // Apple platforms (iOS, macOS): ConcatenatingAudioSource (AVQueuePlayer)
      // hangs even with a single item because AVQueuePlayer preloads adjacent
      // URLs concurrently. Use a plain setAudioSource (single AVPlayer) instead.
      // Queue navigation is handled by reloading via setPlaylist per song.
      await _player
          .setAudioSource(
            items[initialIndex],
            initialPosition: initialPosition,
          )
          .timeout(
            const Duration(seconds: 15),
            onTimeout: () => throw TimeoutException(
                'setAudioSource timed out on Apple platform'),
          );
    } else {
      await _player
          .setAudioSources(
            items,
            initialIndex: initialIndex,
            initialPosition: initialPosition,
          )
          .timeout(
            const Duration(seconds: 15),
            onTimeout: () =>
                throw TimeoutException('setAudioSources timed out'),
          );
    }
  }

  Future<void> setPlaylistIndex(
    int index, {
    Duration? position,
  }) async {
    await _player.seek(position ?? Duration.zero, index: index);
  }

  Future<void> addToPlaylist(AudioSource item) async {
    await _player.addAudioSource(item);
  }

  Future<void> removeFromPlaylist(int index) async {
    await _player.removeAudioSourceAt(index);
  }

  Future<void> moveInPlaylist(int from, int to) async {
    await _player.moveAudioSource(from, to);
  }

  Future<void> playUrl(String url,
      {Map<String, String>? headers, Duration? initialPosition}) async {
    final requestHeaders = (headers != null && headers.isNotEmpty)
        ? headers
        : SharedHeaders.youtubePlaybackHeaders;

    // On Apple platforms (iOS, macOS), no custom headers — AVURLAsset hangs
    // with Origin/Referer set. Signed YouTube URLs are self-authenticating.
    // Disable LockCachingAudioSource as it conflicts with our custom cache system
    // Use regular AudioSource.uri and let our cache handle the optimization
    final audioSource =
        AudioSource.uri(Uri.parse(url), headers: requestHeaders);

    await _audioSessionReady;
    await _player.setAudioSource(
      audioSource,
      initialPosition: initialPosition,
    );
  }

  Future<void> playFile(String filePath) async {
    await _audioSessionReady;
    await _player.setFilePath(filePath);
    await _ensureAudioSessionActive();
    await _player.play();
  }

  Future<void> setFileSource(String filePath) async {
    await _audioSessionReady;
    await _player.setFilePath(filePath);
  }

  /// Loads [source] directly on the underlying player, waiting for the audio
  /// session to be ready. Used by [CrossfadeEngine] to load the next track onto
  /// the secondary player without going through the playlist API.
  Future<void> setAudioSourceForCrossfade(AudioSource source) async {
    await _audioSessionReady;
    await _player.setAudioSource(source);
  }

  /// Starts playback on a secondary crossfade player **without** requesting
  /// audio focus. The primary player already holds focus; calling
  /// [_ensureAudioSessionActive] (i.e. [session.setActive(true)]) from the
  /// secondary would trigger [AUDIOFOCUS_LOSS] on the primary, causing
  /// just_audio to internally pause it and the Android MediaCodec resource
  /// manager to potentially reclaim the primary's hardware decoder.
  Future<void> playForCrossfade() async {
    // _audioSessionReady is AudioSession.instance for crossfade players, which
    // resolves immediately without calling configure() or setActive().
    await _audioSessionReady;
    await _player.play();
  }

  Future<void> pause() async {
    await _player.pause();
    if (_isCrossfadePlayer) return;
    try {
      final session = await _audioSessionReady;
      await session.setActive(false);
    } catch (_) {
      // Best-effort; don't block pause.
    }
  }

  Future<void> resume() async {
    await _ensureAudioSessionActive();
    await _player.play();
  }

  Future<void> play() async {
    await _ensureAudioSessionActive();
    await _player.play();
  }

  Future<void> togglePlayPause() async {
    if (_player.playing) {
      await pause();
    } else {
      await resume();
    }
  }

  Future<void> seek(Duration position) async => _player.seek(position);
  Future<void> stop() async {
    await _player.stop();
    if (_isCrossfadePlayer) return;
    try {
      final session = await _audioSessionReady;
      await session.setActive(false);
    } catch (_) {
      // Best-effort.
    }
  }

  void setLoopMode(LoopMode mode) => _player.setLoopMode(mode);

  Future<void> setSpeed(double speed) async {
    await _player.setSpeed(speed.clamp(0.25, 3.0));
  }

  Future<void> setVolume(double volume) async {
    await _player.setVolume(volume.clamp(0.0, 1.0));
  }

  bool get isNormalizationEnabled => _normalizationEnabled;

  /// Per-track loudness gain in dB, applied when normalization is enabled.
  ///
  /// Set via [setNormalizationGainDb] before or during playback. Targets –14 LUFS;
  /// defaults to 0.0 dB (no adjustment) until a LUFS value is fetched for the track.
  double _normalizationGainDb = 0.0;
  double _crossfadeVol = 1.0;

  Future<void> setNormalizationGainDb(double gainDb) async {
    _normalizationGainDb = gainDb;
    logInfo(
      'AudioPlayerService: setNormalizationGainDb gainDb=${gainDb.toStringAsFixed(2)} enabled=$_normalizationEnabled',
      tag: 'AudioPlayerService',
    );
    if (_normalizationEnabled) await _applyNormalizationGain(gainDb);
  }

  /// Applies [gainDb] to the platform-specific normalization pipeline.
  ///
  /// Android: sets target gain on [AndroidLoudnessEnhancer].
  /// Apple (iOS/macOS): maps dB to a linear volume scalar clamped to [0.05, 1.0].
  Future<void> _applyNormalizationGain(double gainDb) async {
    if (Platform.isAndroid && _loudnessEnhancer != null) {
      await _loudnessEnhancer!.setTargetGain(gainDb);
    } else if (isApplePlatform) {
      await _player.setVolume(
          (_dbToLinearVolume(gainDb) * _crossfadeVol).clamp(0.05, 1.0));
    }
  }

  /// Converts [db] (decibels) to a linear amplitude scalar (0.0–1.0+).
  /// Returns 0.0 for values at or below –40 dB to avoid near-zero instability.
  static double _dbToLinearVolume(double db) {
    if (db <= -40) return 0.0;
    return math.pow(10.0, db / 20.0).toDouble();
  }

  Future<void> setNormalization(bool enabled) async {
    _normalizationEnabled = enabled;
    if (Platform.isAndroid && _loudnessEnhancer != null) {
      await _loudnessEnhancer!.setEnabled(enabled);
      if (enabled) await _applyNormalizationGain(_normalizationGainDb);
    } else if (isApplePlatform) {
      await _applyNormalizationGain(enabled ? _normalizationGainDb : 0.0);
    }
    logInfo(
      'AudioPlayerService: setNormalization enabled=$enabled',
      tag: 'AudioPlayerService',
    );
  }

  /// Sets bass boost level (0.0 = off, 1.0 = max).
  ///
  /// Android: uses [AndroidEqualizer] to boost the two lowest frequency bands
  /// (60Hz and 230Hz) by up to +10 dB. The equalizer is disabled at level 0.
  /// iOS/macOS: not supported (no-op).
  Future<void> setBassBoost(double level) async {
    _bassBoostLevel = level.clamp(0.0, 1.0);
    if (!Platform.isAndroid || _equalizer == null) return;
    if (_bassBoostLevel == 0.0) {
      await _equalizer!.setEnabled(false);
      return;
    }
    final params = await _equalizer!.parameters;
    final bands = params.bands;
    if (bands.isEmpty) return;
    // Boost only the lowest two bands (sub-bass ~60Hz, bass ~230Hz).
    // Level 1.0 → +10 dB on sub-bass, +7 dB on bass.
    // Higher bands stay at 0 dB so only low frequencies are affected.
    final maxGainDb = params.maxDecibels; // typically +15.0
    final subBassGain = (10.0 * _bassBoostLevel).clamp(0.0, maxGainDb);
    final bassGain = (7.0 * _bassBoostLevel).clamp(0.0, maxGainDb);
    if (bands.isNotEmpty) await bands[0].setGain(subBassGain);
    if (bands.length > 1) await bands[1].setGain(bassGain);
    // Zero out remaining bands to avoid unintended coloration.
    for (int i = 2; i < bands.length; i++) {
      await bands[i].setGain(0.0);
    }
    await _equalizer!.setEnabled(true);
  }

  double get bassBoostLevel => _bassBoostLevel;

  /// Applies a crossfade volume multiplier (0.0–1.0) without affecting normalization.
  /// Android: sets player volume directly (normalization uses LoudnessEnhancer, not volume).
  /// Apple (iOS/macOS): multiplies with the current normalization scalar so both work together.
  void applyCrossfadeVolume(double vol) {
    _crossfadeVol = vol.clamp(0.0, 1.0);
    if (Platform.isAndroid) {
      _player.setVolume(_crossfadeVol);
    } else if (isApplePlatform) {
      final normVol = _normalizationEnabled
          ? _dbToLinearVolume(_normalizationGainDb).clamp(0.05, 1.0)
          : 1.0;
      // Allow true silence when the ramp drives vol to 0 (e.g. fade-out start
      // or secondary at ramp start). The 0.05 floor only applies when the ramp
      // scalar is non-zero — it prevents near-inaudible normalization gains from
      // disappearing entirely, not from silencing a deliberate fade.
      final effective = _crossfadeVol * normVol;
      _player
          .setVolume(_crossfadeVol == 0.0 ? 0.0 : effective.clamp(0.05, 1.0));
    }
  }

  /// Resets crossfade volume back to full (1.0).
  Future<void> resetCrossfadeVolume() async {
    _crossfadeVol = 1.0;
    if (Platform.isAndroid) {
      await _player.setVolume(1.0);
    } else if (isApplePlatform) {
      final normVol = _normalizationEnabled
          ? _dbToLinearVolume(_normalizationGainDb).clamp(0.05, 1.0)
          : 1.0;
      await _player.setVolume(normVol);
    }
  }

  void dispose() {
    _positionSub?.cancel();
    _durationSub?.cancel();
    _playerStateSub?.cancel();
    _positionController.close();
    _durationController.close();
    _playerStateController.close();
    _player.dispose();
  }
}
