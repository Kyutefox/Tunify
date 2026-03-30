import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart' as ja;
import 'package:rxdart/rxdart.dart';

import 'crossfade_engine.dart';

/// [BaseAudioHandler] implementation that bridges [audio_service] media controls
/// (lock-screen, notification, Android Auto) to the app's [CrossfadeEngine].
///
/// Also implements [MediaBrowserService] callbacks for Android Auto support,
/// exposing browsable content: Recent, Playlists, Albums, Artists.
///
/// Media control callbacks (play, pause, skip, seek, stop) are dispatched via
/// optional closure properties so [PlayerNotifier] can bind them at construction.
/// Playback state is broadcast to [audio_service] on every position or state change,
/// throttled to 500 ms for position updates to reduce background overhead.
///
/// Stream subscriptions are made against [CrossfadeEngine]'s forwarded broadcast
/// controllers, so they automatically reflect the active (post-swap) primary player
/// without any re-subscription after a crossfade transition.
class TunifyAudioHandler extends BaseAudioHandler with SeekHandler, QueueHandler {
  final CrossfadeEngine _engine;

  void Function()? onPlay;
  void Function()? onPause;
  void Function()? onSkipNext;
  void Function()? onSkipPrevious;
  void Function()? onStop;
  void Function(Duration position)? onSeek;

  /// Callback for Android Auto/CarPlay media browsing - provides playlists, albums, etc.
  Future<List<MediaItem>> Function()? onGetMediaLibrary;
  Future<void> Function(String mediaId)? onPlayFromMediaId;

  late final List<StreamSubscription<dynamic>> _subs;
  ja.PlayerState? _lastPlayerState;
  DateTime? _lastPositionBroadcastAt;

  TunifyAudioHandler(this._engine) {
    _subs = [
      _engine.playerStateStream.listen((s) {
        _lastPlayerState = s;
        _broadcastPlaybackState(s);
      }),
      // Keep notification progress in sync during background playback.
      // Throttled to 500 ms to avoid excessive background CPU wake-ups.
      _engine.positionStream.listen((_) {
        final s = _engine.player.playerState;
        final now = DateTime.now();
        if (_lastPositionBroadcastAt != null &&
            now.difference(_lastPositionBroadcastAt!) <
                const Duration(milliseconds: 500)) {
          return;
        }
        _lastPositionBroadcastAt = now;
        _broadcastPlaybackState(s);
      }),
    ];
  }

  @override
  Future<void> play() async => onPlay?.call();

  @override
  Future<void> pause() async => onPause?.call();

  @override
  Future<void> skipToNext() async => onSkipNext?.call();

  @override
  Future<void> skipToPrevious() async => onSkipPrevious?.call();

  @override
  Future<void> seek(Duration position) async {
    onSeek?.call(position);
    // Broadcast immediately so the notification timer/seekbar updates on scrub.
    final s = _engine.player.playerState;
    _lastPlayerState = s;
    _broadcastPlaybackState(s);
  }

  @override
  Future<void> skipToQueueItem(int index) async {
    // Queue browsing for Android Auto - play by index
    if (queue.value.isNotEmpty && index >= 0 && index < queue.value.length) {
      final item = queue.value[index];
      await playFromMediaId(item.id);
    }
  }

  @override
  Future<void> playFromMediaId(String mediaId,
      [Map<String, dynamic>? extras]) async {
    onPlayFromMediaId?.call(mediaId);
  }

  @override
  Future<List<MediaItem>> getChildren(String parentMediaId,
      [Map<String, dynamic>? options]) async {
    // Android Auto media browsing hierarchy
    if (parentMediaId == MediaItemId.root) {
      return _getRootMenu();
    } else if (parentMediaId == MediaItemId.recentlyPlayed) {
      return onGetMediaLibrary?.call() ?? [];
    } else if (parentMediaId.startsWith(MediaItemId.playlistPrefix)) {
      // Return tracks for a specific playlist
      final playlistId = parentMediaId.replaceFirst(MediaItemId.playlistPrefix, '');
      return _getPlaylistTracks(playlistId);
    }
    return [];
  }

  @override
  ValueStream<Map<String, dynamic>> subscribeToChildren(String parentMediaId) {
    // Return stream - library updates handled via UI refresh
    final controller = BehaviorSubject<Map<String, dynamic>>.seeded({});
    return controller.stream as ValueStream<Map<String, dynamic>>;
  }

  List<MediaItem> _getRootMenu() {
    return [
      MediaItem(
        id: MediaItemId.recentlyPlayed,
        title: 'Recently Played',
        playable: false,
        displaySubtitle: 'Songs you played recently',
      ),
      MediaItem(
        id: MediaItemId.likedSongs,
        title: 'Liked Songs',
        playable: false,
        displaySubtitle: 'Your favorite tracks',
      ),
      MediaItem(
        id: MediaItemId.downloads,
        title: 'Downloads',
        playable: false,
        displaySubtitle: 'Offline music',
      ),
    ];
  }

  Future<List<MediaItem>> _getPlaylistTracks(String playlistId) async {
    // This will be populated from the library provider via callback
    return onGetMediaLibrary?.call() ?? [];
  }

  /// Sets the current queue for Android Auto/CarPlay browsing
  void setQueue(List<MediaItem> items) {
    queue.add(items);
  }

  @override
  Future<void> stop() async {
    onStop?.call();
    playbackState.add(playbackState.value.copyWith(
      controls: [
        MediaControl.skipToPrevious,
        MediaControl.play,
        MediaControl.skipToNext,
      ],
      androidCompactActionIndices: const [0, 1, 2],
      processingState: AudioProcessingState.idle,
      playing: false,
    ));
  }

  /// Updates the [audio_service] [MediaItem] (notification title, artist, artwork)
  /// and resets the notification progress bar immediately on track change.
  void setCurrentMediaItem({
    required String id,
    required String title,
    required String artist,
    required Uri artUri,
    required Duration duration,
  }) {
    final item = MediaItem(
      id: id,
      title: title,
      artist: artist,
      artUri: artUri,
      duration: duration,
    );
    mediaItem.add(item);
    // Ensure notification progress resets immediately on track change.
    final s = _lastPlayerState ?? _engine.player.playerState;
    _broadcastPlaybackState(s);
  }

  /// Pushes the current playback state to [audio_service]'s [playbackState] stream.
  ///
  /// Clamps a near-end `completed` signal back to `ready` when the position has not
  /// genuinely reached the duration — just_audio can report `completed` briefly after
  /// a seek close to the track end.
  void _broadcastPlaybackState(ja.PlayerState playerState) {
    final playing = playerState.playing;
    final processingState = _mapProcessingState(playerState.processingState);
    final pos = _engine.player.position;
    final dur = _engine.player.duration;
    final effectiveProcessingState =
        (processingState == AudioProcessingState.completed &&
                dur != null &&
                dur.inMilliseconds > 0 &&
                pos.inMilliseconds < dur.inMilliseconds - 600)
            ? AudioProcessingState.ready
            : processingState;

    playbackState.add(playbackState.value.copyWith(
      controls: [
        MediaControl.skipToPrevious,
        if (playing) MediaControl.pause else MediaControl.play,
        MediaControl.skipToNext,
      ],
      systemActions: const {
        MediaAction.seek,
        MediaAction.seekForward,
        MediaAction.seekBackward,
      },
      androidCompactActionIndices: const [0, 1, 2],
      processingState: effectiveProcessingState,
      playing: playing,
      updatePosition: pos,
      bufferedPosition: _engine.player.bufferedPosition,
      speed: _engine.player.speed,
    ));
  }

  AudioProcessingState _mapProcessingState(ja.ProcessingState state) {
    switch (state) {
      case ja.ProcessingState.idle:
        return AudioProcessingState.idle;
      case ja.ProcessingState.loading:
        return AudioProcessingState.loading;
      case ja.ProcessingState.buffering:
        return AudioProcessingState.buffering;
      case ja.ProcessingState.ready:
        return AudioProcessingState.ready;
      case ja.ProcessingState.completed:
        return AudioProcessingState.completed;
    }
  }

  void dispose() {
    for (final sub in _subs) {
      sub.cancel();
    }
  }
}

/// Media ID constants for Android Auto/CarPlay browsing hierarchy
class MediaItemId {
  static const String root = '__ROOT__';
  static const String recentlyPlayed = '__RECENT__';
  static const String likedSongs = '__LIKED__';
  static const String downloads = '__DOWNLOADS__';
  static const String playlists = '__PLAYLISTS__';
  static const String albums = '__ALBUMS__';
  static const String artists = '__ARTISTS__';
  static const String playlistPrefix = 'playlist:';
  static const String albumPrefix = 'album:';
  static const String artistPrefix = 'artist:';
}
