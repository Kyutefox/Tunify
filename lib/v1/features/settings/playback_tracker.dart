import 'dart:async';
import 'dart:math';

import 'package:tunify/v1/features/settings/music_stream_manager.dart';

/// Reports YouTube playback watchtime and play-start events so the platform
/// can credit the play toward artist royalties and personalization signals.
///
/// Call [initializePlayback] before playback starts to obtain a [PlaybackSession],
/// then [startTracking] once the player begins. Watchtime is reported every [_reportInterval].
class PlaybackTracker {
  Timer? _reportingTimer;
  PlaybackSession? _currentSession;
  final bool _enableTracking;
  final MusicStreamManager _streamManager;

  /// Interval at which watchtime reports are sent to YouTube's atrUrl endpoint.
  static const Duration _reportInterval = Duration(seconds: 30);

  PlaybackTracker({
    required MusicStreamManager streamManager,
    bool enableTracking = true,
  })  : _streamManager = streamManager,
        _enableTracking = enableTracking;

  /// Fetches the player response to extract tracking URLs and generates a CPN.
  ///
  /// The CPN (Client Playback Nonce) is generated before the player call so YouTube
  /// can correlate this play with all subsequent watchtime requests. Returns null
  /// when tracking is disabled or the player response contains no tracking data.
  Future<PlaybackSession?> initializePlayback(String videoId) async {
    if (!_enableTracking) return null;

    try {
      final cpn = _generateCpn();
      final result =
          await _streamManager.getPlayerResponseForTracking(videoId, cpn: cpn);
      final playbackTracking =
          result['playbackTracking'] as Map<String, dynamic>?;

      if (playbackTracking != null) {
        return PlaybackSession(
          videoId: videoId,
          cpn: cpn,
          videostatsPlaybackUrl: (playbackTracking['videostatsPlaybackUrl']
              as Map<String, dynamic>?)?['baseUrl'] as String?,
          videostatsWatchtimeUrl: (playbackTracking['videostatsWatchtimeUrl']
              as Map<String, dynamic>?)?['baseUrl'] as String?,
          atrUrl: playbackTracking['atrUrl']?['baseUrl'] as String?,
          ptrackingUrl: (playbackTracking['ptrackingUrl']
              as Map<String, dynamic>?)?['baseUrl'] as String?,
        );
      }
    } catch (_) {
      // Tracking is best-effort; missing data does not affect playback.
    }

    return null;
  }

  void startTracking(String videoId, PlaybackSession session) {
    if (!_enableTracking) return;

    stopTracking();
    _currentSession = session;

    _reportPlayback(0);

    if (session.videostatsPlaybackUrl != null) {
      _streamManager.reportPlaybackStart(
        session.videostatsPlaybackUrl!,
        session.cpn,
      );
    }

    if (session.ptrackingUrl != null) {
      _streamManager.reportPtracking(
        session.ptrackingUrl!,
        session.cpn,
      );
    }

    _reportingTimer = Timer.periodic(
      _reportInterval,
      (timer) => _reportPlayback(timer.tick * _reportInterval.inSeconds),
    );
  }

  void stopTracking() {
    _reportingTimer?.cancel();
    _reportingTimer = null;
    _currentSession = null;
  }

  Future<void> _reportPlayback(int playbackSeconds) async {
    final session = _currentSession;
    if (session == null) return;

    final futures = <Future<void>>[];
    if (session.atrUrl != null) {
      futures.add(_streamManager.reportPlaybackWatchtime(
        session.atrUrl!,
        session.cpn,
        playbackSeconds,
      ));
    }
    if (session.videostatsWatchtimeUrl != null &&
        session.videostatsWatchtimeUrl != session.atrUrl) {
      futures.add(_streamManager.reportPlaybackWatchtime(
        session.videostatsWatchtimeUrl!,
        session.cpn,
        playbackSeconds,
      ));
    }
    if (futures.isNotEmpty) await Future.wait(futures);
  }

  static final Random _rng = Random.secure();

  String _generateCpn() {
    const chars =
        'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_';
    return List.generate(16, (_) => chars[_rng.nextInt(chars.length)]).join();
  }

  void dispose() {
    stopTracking();
  }
}

/// Tracking URLs and CPN for a single playback session, obtained from the YouTube player response.
class PlaybackSession {
  final String videoId;
  final String cpn;
  final String? videostatsPlaybackUrl;
  final String? videostatsWatchtimeUrl;
  final String? atrUrl;
  final String? ptrackingUrl;

  const PlaybackSession({
    required this.videoId,
    required this.cpn,
    this.videostatsPlaybackUrl,
    this.videostatsWatchtimeUrl,
    this.atrUrl,
    this.ptrackingUrl,
  });
}
