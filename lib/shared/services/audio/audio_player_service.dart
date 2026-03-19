import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:audio_session/audio_session.dart';
import 'package:just_audio/just_audio.dart';
import 'package:tunify_logger/tunify_logger.dart';

import 'package:scrapper/scrapper.dart';

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
  bool _normalizationEnabled = false;
  late final Future<AudioSession> _audioSessionReady;

  final StreamController<Duration> _positionController =
      StreamController<Duration>.broadcast();
  final StreamController<Duration?> _durationController =
      StreamController<Duration?>.broadcast();
  final StreamController<PlayerState> _playerStateController =
      StreamController<PlayerState>.broadcast();

  StreamSubscription<Duration>? _positionSub;
  StreamSubscription<Duration?>? _durationSub;
  StreamSubscription<PlayerState>? _playerStateSub;

  AudioPlayerService() {
    if (Platform.isAndroid) {
      _loudnessEnhancer = AndroidLoudnessEnhancer();
      _loudnessEnhancer!.setEnabled(false);
      _player = AudioPlayer(
        handleInterruptions: true,
        audioPipeline: AudioPipeline(
          androidAudioEffects: [_loudnessEnhancer!],
        ),
        // Match old app: no useProxyForRequestHeaders (use just_audio default).
      );
    } else {
      _player = AudioPlayer(handleInterruptions: true);
    }
    _audioSessionReady = _configureAudioSession();
    _forwardFrom(_player);
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
    if (Platform.isIOS) {
      // iOS: ConcatenatingAudioSource (AVQueuePlayer) hangs even with a single
      // item because AVQueuePlayer preloads adjacent URLs concurrently. Use a
      // plain setAudioSource (single AVPlayer) instead. Queue navigation is
      // handled by reloading via setPlaylist for each song on iOS.
      await _player.setAudioSource(
        items[initialIndex],
        initialPosition: initialPosition,
      ).timeout(
        const Duration(seconds: 15),
        onTimeout: () => throw TimeoutException('setAudioSource timed out on iOS'),
      );
    } else {
      await _player.setAudioSources(
        items,
        initialIndex: initialIndex,
        initialPosition: initialPosition,
      ).timeout(
        const Duration(seconds: 15),
        onTimeout: () => throw TimeoutException('setAudioSources timed out'),
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
        : youtubePlaybackHeaders;

    // On iOS, no custom headers — AVURLAsset hangs with Origin/Referer set.
    // Signed YouTube URLs are self-authenticating and play without headers.
    final audioSource = Platform.isIOS
        ? AudioSource.uri(Uri.parse(url))
        // ignore: experimental_member_use
        : LockCachingAudioSource(Uri.parse(url), headers: requestHeaders);

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

  Future<void> pause() async {
    await _player.pause();
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
    try {
      final session = await _audioSessionReady;
      await session.setActive(false);
    } catch (_) {
      // Best-effort.
    }
  }

  void setLoopMode(LoopMode mode) => _player.setLoopMode(mode);

  Future<void> setVolume(double volume) async {
    await _player.setVolume(volume.clamp(0.0, 1.0));
  }

  bool get isNormalizationEnabled => _normalizationEnabled;

  /// Per-track loudness gain in dB, applied when normalization is enabled.
  ///
  /// Set via [setNormalizationGainDb] before or during playback. Targets –14 LUFS;
  /// defaults to 0.0 dB (no adjustment) until a LUFS value is fetched for the track.
  double _normalizationGainDb = 0.0;

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
  /// iOS: maps dB to a linear volume scalar clamped to [0.05, 1.0] to avoid silence.
  Future<void> _applyNormalizationGain(double gainDb) async {
    if (Platform.isAndroid && _loudnessEnhancer != null) {
      await _loudnessEnhancer!.setTargetGain(gainDb);
    } else if (Platform.isIOS) {
      await _player.setVolume(_dbToLinearVolume(gainDb).clamp(0.05, 1.0));
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
    } else if (Platform.isIOS) {
      await _applyNormalizationGain(enabled ? _normalizationGainDb : 0.0);
    }
    logInfo(
      'AudioPlayerService: setNormalization enabled=$enabled',
      tag: 'AudioPlayerService',
    );
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
