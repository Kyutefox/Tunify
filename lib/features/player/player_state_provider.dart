import 'dart:async';
import 'dart:io';

import 'package:hive_flutter/hive_flutter.dart';
import 'package:tunify/core/utils/platform_utils.dart';

import 'package:flutter/foundation.dart' show listEquals, setEquals;
import 'package:audio_service/audio_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart' as ja;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:tunify/core/constants/storage_keys.dart';
import 'package:tunify/data/models/song.dart';
import 'package:tunify/data/repositories/audio_repository.dart';
import 'package:tunify/features/settings/music_stream_manager.dart';
import 'package:tunify/features/player/audio/audio_player_service.dart';
import 'package:tunify/features/player/audio/crossfade_engine.dart';
import 'package:tunify/features/player/audio/audio_handler.dart';
import 'package:tunify_logger/tunify_logger.dart';

import 'package:tunify/data/models/library_playlist.dart' show ShuffleMode;
import 'package:tunify/features/device/device_music_provider.dart';
import 'package:tunify/features/downloads/download_provider.dart';
import 'package:tunify/features/home/home_state_provider.dart';
import 'package:tunify/features/library/library_provider.dart';
import 'package:tunify_database/tunify_database.dart' show PlaybackSettingKeys;

import 'package:tunify/data/repositories/database_repository.dart';
import 'package:tunify/features/settings/playback_tracker.dart';
import 'package:tunify/features/settings/stream_cache_service.dart';
import 'package:tunify/features/player/playback_position_provider.dart';

/// Maximum queue size to prevent unbounded growth and O(n) equality checks
const int _kMaxQueueSize = 50;

enum PlayerStatus {
  idle,
  loading,
  playing,
  paused,
  buffering,
  error,
}

class PlayerState {
  final PlayerStatus status;
  final Song? currentSong;
  final List<Song> queue;
  final int currentIndex;
  final Duration? duration;
  final String? error;
  final bool isShuffleEnabled;
  final PlayerRepeatMode repeatMode;
  final double volume;
  final StreamQuality quality;
  final int bitrate;
  final bool isNormalizationEnabled;
  /// IDs of songs appended to the queue by Smart Shuffle recommendations.
  final Set<String> smartShuffleSongIds;

  /// The shuffle mode of the source that is currently playing (playlist,
  /// downloads, etc.). [ShuffleMode.none] when nothing is active.
  final ShuffleMode activeShuffleMode;

  // Stored as nullable so Shorebird-patched builds that pre-date these fields
  // still get the correct safe default instead of a null-dereference crash.
  final bool? _isGaplessEnabled;
  final int? _crossfadeDurationSeconds;

  bool get isGaplessEnabled => _isGaplessEnabled ?? true;
  int get crossfadeDurationSeconds => _crossfadeDurationSeconds ?? 0;

  const PlayerState({
    this.status = PlayerStatus.idle,
    this.currentSong,
    this.queue = const [],
    this.currentIndex = -1,
    this.duration,
    this.error,
    this.isShuffleEnabled = false,
    this.repeatMode = PlayerRepeatMode.off,
    this.volume = 1.0,
    this.quality = StreamQuality.auto,
    this.bitrate = 0,
    this.isNormalizationEnabled = false,
    bool isGaplessEnabled = true,
    int crossfadeDurationSeconds = 0,
    this.smartShuffleSongIds = const {},
    this.activeShuffleMode = ShuffleMode.none,
  })  : _isGaplessEnabled = isGaplessEnabled,
        _crossfadeDurationSeconds = crossfadeDurationSeconds;

  bool get isPlaying => status == PlayerStatus.playing;
  bool get isLoading =>
      status == PlayerStatus.loading || status == PlayerStatus.buffering;
  bool get hasSong => currentSong != null;
  bool get hasQueue => queue.isNotEmpty;
  bool get canPlayNext => currentIndex < queue.length - 1;
  bool get canPlayPrevious => currentIndex > 0;

  // Progress calculation moved to UI layer using playbackPositionProvider
  // This prevents rebuilds on every position update

  PlayerState copyWith({
    PlayerStatus? status,
    Song? currentSong,
    List<Song>? queue,
    int? currentIndex,
    Duration? duration,
    String? error,
    bool? isShuffleEnabled,
    PlayerRepeatMode? repeatMode,
    double? volume,
    StreamQuality? quality,
    int? bitrate,
    bool? isNormalizationEnabled,
    bool? isGaplessEnabled,
    int? crossfadeDurationSeconds,
    Set<String>? smartShuffleSongIds,
    ShuffleMode? activeShuffleMode,
    bool clearSong = false,
    bool clearError = false,
    bool clearDuration = false,
    bool clearSmartShuffleIds = false,
  }) {
    return PlayerState(
      status: status ?? this.status,
      currentSong: clearSong ? null : (currentSong ?? this.currentSong),
      queue: queue ?? this.queue,
      currentIndex: currentIndex ?? this.currentIndex,
      duration: clearDuration ? null : (duration ?? this.duration),
      error: clearError ? null : (error ?? this.error),
      isShuffleEnabled: isShuffleEnabled ?? this.isShuffleEnabled,
      repeatMode: repeatMode ?? this.repeatMode,
      volume: volume ?? this.volume,
      quality: quality ?? this.quality,
      bitrate: bitrate ?? this.bitrate,
      isNormalizationEnabled:
          isNormalizationEnabled ?? this.isNormalizationEnabled,
      isGaplessEnabled: isGaplessEnabled ?? this.isGaplessEnabled,
      crossfadeDurationSeconds:
          crossfadeDurationSeconds ?? this.crossfadeDurationSeconds,
      smartShuffleSongIds:
          clearSmartShuffleIds ? const {} : (smartShuffleSongIds ?? this.smartShuffleSongIds),
      activeShuffleMode: activeShuffleMode ?? this.activeShuffleMode,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! PlayerState) return false;
    return status == other.status &&
        currentSong == other.currentSong &&
        listEquals(queue, other.queue) &&
        currentIndex == other.currentIndex &&
        duration == other.duration &&
        error == other.error &&
        isShuffleEnabled == other.isShuffleEnabled &&
        repeatMode == other.repeatMode &&
        volume == other.volume &&
        quality == other.quality &&
        bitrate == other.bitrate &&
        isNormalizationEnabled == other.isNormalizationEnabled &&
        isGaplessEnabled == other.isGaplessEnabled &&
        crossfadeDurationSeconds == other.crossfadeDurationSeconds &&
        setEquals(smartShuffleSongIds, other.smartShuffleSongIds) &&
        activeShuffleMode == other.activeShuffleMode;
  }

  @override
  // PERF: Replaced Object.hashAll(queue) (O(n) traversal per equality check)
  // with a fast discriminator: queue length + boundary element IDs. This
  // reduces hashCode cost from O(50) to O(1) for the common case where the
  // queue size didn't change. Full equality is still checked correctly via ==.
  int get hashCode => Object.hash(
        status,
        currentSong,
        queue.length,
        queue.isEmpty ? null : queue.first.id,
        queue.isEmpty ? null : queue.last.id,
        currentIndex,
        duration,
        isShuffleEnabled,
        repeatMode,
        volume,
        quality,
        bitrate,
        isNormalizationEnabled,
        isGaplessEnabled,
        crossfadeDurationSeconds,
        smartShuffleSongIds.length,
        activeShuffleMode,
      );
}

enum PlayerRepeatMode {
  off,
  all,
  one,
}

class PlayerNotifier extends Notifier<PlayerState> {
  // Service getters — read from providers on each access; safe for method calls.
  AudioRepository get _audioRepository => ref.read(audioRepositoryProvider);
  MusicStreamManager get _streamManager => ref.read(streamManagerProvider);
  CrossfadeEngine get _audioPlayer => ref.read(crossfadeEngineProvider);
  TunifyAudioHandler? get _audioHandler => ref.read(audioHandlerProvider);

  PlaybackTracker? _playbackTracker;
  bool _initialized = false;
  final List<StreamSubscription<dynamic>> _subscriptions = [];

  List<Song> _originalQueue = [];

  /// Original (pre-interleave) playlist songs kept for smart shuffle seed rotation.
  List<Song> _smartShufflePlaylistSongs = [];
  int _smartSeedIndex = 0;
  bool _smartShuffleRefilling = false;

  bool _disposed = false;
  bool _isTransitioning = false;

  /// Incremented each time a new song load preempts an in-flight transition.
  /// _syncPlaylistToQueue captures this at entry and bails out at each await
  /// checkpoint if the value has changed, preventing the old load from racing
  /// against and clobbering the new one.
  int _transitionGeneration = 0;
  bool _usingPlaylist = false;

  /// Number of queue items currently loaded in the just_audio playlist (max 5 initially).
  int _loadedPlaylistLength = 0;
  Timer? _positionSyncTimer;
  Timer? _playbackRecoveryTimer;
  Timer? _persistDebounceTimer;
  DateTime? _playRequestedAt;
  Duration? _playRequestedPosition;
  // Notification media item duration is derived from `just_audio` once it becomes
  // available; we cache the last values to avoid redundant MediaSession updates.
  String? _lastNotifiedSongId;
  int? _lastNotifiedDurationMs;
  // Normalization gain is fetched once per song to avoid redundant LUFS fetches.
  String? _lastNormalizationGainFetchedForSongId;

  bool _didPreExtend = false;

  /// Index of the next song for which a crossfade has been initiated.
  /// Prevents the position listener from starting multiple concurrent crossfades.
  /// Reset to -1 when a crossfade completes, is cancelled, or a new song starts.
  int _crossfadePreparedForIndex = -1;

  /// Index of the next song for which a secondary preload has been started.
  /// Prevents the position listener from issuing duplicate preload calls.
  /// Reset alongside [_crossfadePreparedForIndex].
  int _crossfadePreloadedForIndex = -1;

  /// True while [_beginTrueCrossfade] is in flight (resolving the source URL)
  /// but before [CrossfadeEngine.beginCrossfade] has been called.
  /// Guards the processingState=completed handler during that gap so the
  /// primary completing early doesn't trigger [_handleCompletion] and
  /// interrupt the in-flight setup.
  bool _crossfadeInFlight = false;

  /// Last position (ms) seen on macOS, used to detect when AVPlayer stalls
  /// at the real audio end while the inflated container duration hasn't elapsed.
  int? _macosLastPositionMs;

  /// Tracks which song id has already had its real duration fetched on macOS
  /// via the YouTube player API, to avoid duplicate network calls.
  String? _lastRealDurationFetchedForSongId;

  /// Tracks which song id has already triggered silent home refresh.
  String? _silentRefreshTriggeredForSongId;

  String? _lastQueueSource;
  String? _lastPlaylistId;

  @override
  PlayerState build() {
    if (!_initialized) {
      _initialized = true;
      _playbackTracker = PlaybackTracker(
        streamManager: ref.read(streamManagerProvider),
        enableTracking: true,
      );
      _initializeListeners();
      _wireAudioHandlerCallbacks();
      // AudioService.init() runs async after the first build, so the handler
      // is null here on iOS. Re-wire callbacks whenever the handler is set.
      ref.listen<TunifyAudioHandler?>(audioHandlerProvider, (_, handler) {
        if (handler != null) {
          _wireAudioHandlerCallbacks();
          // Push current song metadata to the handler immediately so the lock
          // screen shows artwork/title even if the song was already playing
          // before the handler finished initialising.
          final song = state.currentSong;
          if (song != null) _syncMediaNotification(song);
        }
      });
      _restoreLastSong();
      _restoreNormalization();
      _restorePlaybackSettings();
      ref.onDispose(dispose);
    }
    return PlayerState();
  }

  /// Returns the local file path for [songId] from downloads or device music,
  /// or null if not available locally.
  String? _resolveLocalPath(String songId) {
    try {
      final dlPath = ref.read(downloadServiceProvider).getLocalPath(songId);
      if (dlPath != null) return dlPath;
    } catch (e) {
      logWarning('Player: getLocalPath (downloads) failed: $e', tag: 'Player');
    }
    try {
      final deviceState = ref.read(deviceMusicProvider);
      if (deviceState.pathMap.isEmpty && !deviceState.isLoading) {
        ref.read(deviceMusicProvider.notifier).loadSongs();
      }
      return deviceState.pathMap[songId];
    } catch (e) {
      logWarning('Player: getLocalPath (device) failed: $e', tag: 'Player');
      return null;
    }
  }

  /// Determines if auto-fill queue should run for the given [source]/[playlistId].
  ///
  /// Always true for a single song (source == null or 'autoqueue').
  /// For playlists/liked/downloads: only true when shuffle mode is [ShuffleMode.smart].
  /// Interleaves [recs] into [playlistSongs]: inserts one recommended song after
  /// every [interval] playlist songs. Tracks that don't fit are dropped
  /// (the refill mechanism will add more later).
  List<Song> _interleaveSmartRecs(List<Song> playlistSongs, List<Song> recs,
      {int interval = 2}) {
    final result = <Song>[];
    int recIndex = 0;
    int playlistCount = 0;
    for (final song in playlistSongs) {
      result.add(song);
      playlistCount++;
      if (playlistCount % interval == 0 && recIndex < recs.length) {
        result.add(recs[recIndex++]);
      }
    }
    return result;
  }

  /// Triggered on each song advance when smart shuffle is active.
  /// If fewer than 2 ✨ recommended songs remain ahead in the queue, fetches a
  /// fresh batch (seeded from a rotating playlist song) and interleaves them in.
  Future<void> _maybeRefillSmartShuffle() async {
    if (_smartShuffleRefilling) return;
    if (state.activeShuffleMode != ShuffleMode.smart) return;

    final currentIdx = state.currentIndex;
    final queue = state.queue;
    final smartIds = state.smartShuffleSongIds;

    // Count unplayed ✨ songs still ahead.
    final unplayedSmart = currentIdx + 1 < queue.length
        ? queue.sublist(currentIdx + 1).where((s) => smartIds.contains(s.id)).length
        : 0;
    if (unplayedSmart >= 2) return;

    if (_smartShufflePlaylistSongs.isEmpty) return;

    _smartShuffleRefilling = true;
    try {
      // Rotate seed through original playlist songs for varied recommendations.
      final seed =
          _smartShufflePlaylistSongs[_smartSeedIndex % _smartShufflePlaylistSongs.length];
      _smartSeedIndex++;

      final tracks = await _streamManager.getRecommendedQueue(
        seed.id,
        maxResults: 8,
      );
      if (tracks.isEmpty) return;

      // Re-check state — song may have changed while we were awaiting.
      if (state.activeShuffleMode != ShuffleMode.smart) return;
      final freshQueue = state.queue;
      final freshIdx = state.currentIndex;
      final existingIds = freshQueue.map((s) => s.id).toSet();

      final freshRecs = tracks
          .map(Song.fromTrack)
          .where((s) => !existingIds.contains(s.id))
          .toList();
      if (freshRecs.isEmpty) return;

      final songsAhead = freshIdx + 1 < freshQueue.length
          ? freshQueue.sublist(freshIdx + 1)
          : <Song>[];
      final interleaved = _interleaveSmartRecs(songsAhead, freshRecs);

      final newSmartIds = interleaved
          .where((s) => !existingIds.contains(s.id))
          .map((s) => s.id)
          .toSet();

      final newQueue = [
        ...freshQueue.sublist(0, freshIdx + 1),
        ...interleaved,
      ];

      // Trim queue to prevent unbounded growth
      final trimmedQueue = newQueue.length > _kMaxQueueSize
          ? newQueue.sublist(0, _kMaxQueueSize)
          : newQueue;

      state = state.copyWith(
        queue: trimmedQueue,
        smartShuffleSongIds: {...state.smartShuffleSongIds, ...newSmartIds},
      );
      _applyQueueInvariant();
    } catch (e) {
      logWarning('Player: _maybeRefillSmartShuffle failed: $e', tag: 'Player');
    } finally {
      _smartShuffleRefilling = false;
    }
  }

  ShuffleMode _readActiveShuffleMode(String? source, String? playlistId) {
    final lib = ref.read(libraryProvider);
    return switch (source) {
      'playlist' =>
        lib.playlists.where((p) => p.id == playlistId).firstOrNull?.shuffleMode ??
            ShuffleMode.none,
      'downloads' || 'device' => lib.downloadedShuffleMode,
      'liked' => lib.likedPlaylist.shuffleMode,
      _ => ShuffleMode.none,
    };
  }

  Future<bool> _shouldFillQueue(String? source, String? playlistId) async {
    if (source == null || source == 'autoqueue') return true;
    final lib = ref.read(libraryProvider);
    switch (source) {
      case 'playlist':
        final p = lib.playlists.where((p) => p.id == playlistId).firstOrNull;
        return p?.shuffleMode == ShuffleMode.smart;
      case 'downloads':
      case 'device':
        return lib.downloadedShuffleMode == ShuffleMode.smart;
      case 'liked':
        return lib.likedPlaylist.shuffleMode == ShuffleMode.smart;
      default:
        return false;
    }
  }

  void _wireAudioHandlerCallbacks() {
    final handler = _audioHandler;
    if (handler == null) return;
    handler.onPlay = () => togglePlayPause();
    handler.onPause = () => pause();
    handler.onSkipNext = () => playNext();
    handler.onSkipPrevious = () => playPrevious();
    handler.onStop = () {
      pause();
      final handler = _audioHandler;
      handler?.playbackState.add(
        handler.playbackState.value.copyWith(
          processingState: AudioProcessingState.idle,
          playing: false,
        ),
      );
    };
    handler.onSeek = (pos) => seekTo(pos);
  }

  void _syncMediaNotification(Song song) {
    // `song.duration` often comes from the feed and may be a placeholder.
    // Prefer the real duration from just_audio if it is already known.
    final audioDur = _audioPlayer.duration;
    final stateDur =
        (state.duration != null && state.duration!.inMilliseconds > 0)
            ? state.duration
            : null;
    final Duration effectiveDuration = audioDur ?? stateDur ?? song.duration;
    _audioHandler?.setCurrentMediaItem(
      id: song.id,
      title: song.title,
      artist: song.artist,
      artUri: Uri.parse(song.thumbnailUrl),
      duration: effectiveDuration,
    );
    _lastNotifiedSongId = song.id;
    _lastNotifiedDurationMs = effectiveDuration.inMilliseconds;
  }

  void _maybeUpdateNotificationDuration(Song song, Duration duration) {
    final ms = duration.inMilliseconds;
    if (ms <= 0) return;
    if (_lastNotifiedSongId == song.id && _lastNotifiedDurationMs == ms) return;
    _audioHandler?.setCurrentMediaItem(
      id: song.id,
      title: song.title,
      artist: song.artist,
      artUri: Uri.parse(song.thumbnailUrl),
      duration: duration,
    );
    _lastNotifiedSongId = song.id;
    _lastNotifiedDurationMs = ms;
  }

  /// When a song's stored duration is unknown (zero), write the real duration
  /// back to the library so it shows correctly in playlists and liked songs.
  void _maybeUpdateLibrarySongDuration(Song song, Duration realDuration) {
    if (song.duration.inMilliseconds > 0) return; // already has a real duration
    if (realDuration.inMilliseconds <= 0) return;
    // PERF: Replaced N separate setPlaylistSongs() calls (one per matching
    // playlist) with a single patchSongDuration() that emits ONE state update.
    // Previously each call triggered a full libraryProvider rebuild cascade,
    // causing all library-subscribed widgets to rebuild N times.
    ref
        .read(libraryProvider.notifier)
        .patchSongDuration(song.id, realDuration);
  }

  void _maybeFetchAndApplyNormalizationGain(Song song) {
    if (!state.isNormalizationEnabled) return;
    if (_lastNormalizationGainFetchedForSongId == song.id) return;

    _lastNormalizationGainFetchedForSongId = song.id;

    logInfo(
      'Player: normalization gain fetch start song=${song.id}',
      tag: 'Player',
    );

    _streamManager.getLoudnessDbForVideo(song.id).then((fromYt) {
      final gainDb = fromYt != null ? kLufsTargetDb - fromYt : null;
      if (fromYt != null) {
        logInfo(
          'Player: normalization computed songId=${song.id} fromYt=${fromYt.toStringAsFixed(2)} gainDb=${gainDb!.toStringAsFixed(2)}',
          tag: 'Player',
        );
      }
      // Guard: song may have changed while the fetch was in-flight.
      if (state.currentSong?.id != song.id) {
        // The fetch may be for the crossfade-incoming song — forward to secondary.
        if (_audioPlayer.isCrossfading && gainDb != null) {
          unawaited(_audioPlayer.setSecondaryNormalizationGainDb(gainDb));
        }
        return;
      }
      if (gainDb != null) {
        logInfo(
          'Player: normalization gain applied song=${song.id} gainDb=${gainDb.toStringAsFixed(2)}',
          tag: 'Player',
        );
        _audioPlayer.setNormalizationGainDb(gainDb);
      } else {
        logWarning(
          'Player: normalization gain not available song=${song.id}',
          tag: 'Player',
        );
      }
    });
  }

  /// On macOS, AVPlayer reads duration from the YouTube DASH container's mvhd
  /// atom (segment allocation size, e.g. 600 s) rather than the actual audio.
  /// This fetches the real duration from YouTube's player API (lengthSeconds)
  /// and overwrites state.duration with the correct value.
  /// No-op on other platforms. Deduped per song id.
  void _maybeFetchRealDurationOnMacOS(Song song) {
    if (!Platform.isMacOS) return;
    if (_lastRealDurationFetchedForSongId == song.id) return;
    _lastRealDurationFetchedForSongId = song.id;

    _streamManager.getSongFromPlayer(song.id).then((fetched) {
      if (fetched == null) return;
      final realDur = fetched.duration;
      if (realDur.inMilliseconds <= 0) return;
      // Guard: song may have changed while the fetch was in-flight.
      if (state.currentSong?.id != song.id) return;
      logInfo(
        'Player: macOS real duration fetched song=${song.id} '
        'dur=${realDur.inMilliseconds}ms',
        tag: 'Player',
      );
      state = state.copyWith(duration: realDur);
      _maybeUpdateNotificationDuration(song, realDur);
    }).catchError((Object e) {
      logWarning(
        'Player: macOS real duration fetch failed song=${song.id}: $e',
        tag: 'Player',
      );
    });
  }

  Future<void> _restoreLastSong() async {
    try {
      final box = await Hive.openBox<dynamic>('player_state');
      final prefs = await SharedPreferences.getInstance();
      final Object? songEntry = box.get('song');

      final song = songEntry is Map
          ? Song.fromJson(Map<String, dynamic>.from(songEntry))
          : null;
      if (song != null && state.currentSong == null) {
        final posMs = prefs.getInt(StorageKeys.prefsLastPlayedPositionMs) ?? 0;
        final durMs = prefs.getInt(StorageKeys.prefsLastPlayedDurationMs) ?? 0;
        
        // Restore position to dedicated provider
        if (posMs > 0) {
          ref.read(playbackPositionProvider.notifier).update(Duration(milliseconds: posMs));
        }
        
        state = state.copyWith(
          queue: [song],
          currentIndex: 0,
          status: PlayerStatus.paused,
          duration: durMs > 0 ? Duration(milliseconds: durMs) : null,
        );
        _applyQueueInvariant();
      }
    } catch (e) {
      logWarning('Player: _restoreLastSong failed: $e', tag: 'Player');
    }
  }

  /// Keeps currentIndex in range and currentSong in sync with queue[currentIndex].
  void _applyQueueInvariant() {
    final q = state.queue;
    if (q.isEmpty) {
      if (state.currentIndex != -1 || state.currentSong != null) {
        state = state.copyWith(currentIndex: -1, clearSong: true);
      }
      return;
    }
    final idx = state.currentIndex.clamp(0, q.length - 1);
    final songAtIdx = q[idx];
    if (idx != state.currentIndex || state.currentSong?.id != songAtIdx.id) {
      state = state.copyWith(currentIndex: idx, currentSong: songAtIdx);
    }
  }

  static bool _queueIdsEqual(List<Song>? a, List<Song>? b) {
    if (a == null && b == null) return true;
    if (a == null || b == null || a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i].id != b[i].id) return false;
    }
    return true;
  }

  Future<void> _persistPlaybackState() async {
    if (_disposed) return;
    if (!_hasLoadedSource) return;
    try {
      final song = state.currentSong;
      if (song == null) return;
      final posMs = ref.read(playbackPositionProvider).inMilliseconds;
      final durMs = state.duration?.inMilliseconds ?? 0;
      if (posMs == 0 && durMs == 0) return;
      final box = await Hive.openBox<dynamic>('player_state');
      final prefs = await SharedPreferences.getInstance();
      final futures = <Future>[
        box.put('song', song.toJson()),
        prefs.setInt(StorageKeys.prefsLastPlayedPositionMs, posMs),
        prefs.setInt(StorageKeys.prefsLastPlayedDurationMs, durMs),
      ];
      if (_lastQueueSource != null) {
        futures.add(prefs.setString(
            StorageKeys.prefsLastQueueSource, _lastQueueSource!));
      }
      if (_lastPlaylistId != null) {
        futures.add(
            prefs.setString(StorageKeys.prefsLastPlaylistId, _lastPlaylistId!));
      }
      await Future.wait(futures);
    } catch (e) {
      logWarning('Player: _persistPlaybackState failed: $e', tag: 'Player');
    }
  }

  /// Clears any legacy local stream cache pref (no server cache).
  Future<void> clearPersistentStreamCache() async {
    try {
      const legacyKey = 'persistent_stream_cache';
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(legacyKey);
    } catch (e) {
      logWarning('Player: clearPersistentStreamCache failed: $e',
          tag: 'Player');
    }
  }

  PlayerStatus _statusFromJustAudio(ja.PlayerState playerState,
      {required bool hasSong}) {
    // Prefer the stream-provided state over querying the player again.
    if (playerState.processingState == ja.ProcessingState.loading) {
      return PlayerStatus.buffering;
    }
    if (playerState.processingState == ja.ProcessingState.buffering) {
      // Buffering may occur both while playing and paused.
      return PlayerStatus.buffering;
    }
    if (playerState.playing &&
        playerState.processingState == ja.ProcessingState.ready) {
      return PlayerStatus.playing;
    }
    // processingState.ready but not playing => paused/idle.
    return hasSong ? PlayerStatus.paused : PlayerStatus.idle;
  }

  bool get _pendingPlay {
    final t = _playRequestedAt;
    if (t == null) return false;
    return DateTime.now().difference(t) < const Duration(seconds: 2);
  }

  void _applyStatusFromPlayerState(ja.PlayerState playerState) {
    final newStatus = _statusFromJustAudio(playerState, hasSong: state.hasSong);

    // During playlist rebuilds we want to keep the UI in a stable loading/buffering
    // state, but we MUST still allow the "now playing" transition through.
    if (_isTransitioning) {
      if (newStatus != PlayerStatus.playing &&
          newStatus != PlayerStatus.buffering) {
        return;
      }
    }

    // Avoid flipping to paused too early right after a play request.
    if (_pendingPlay && newStatus == PlayerStatus.paused) return;

    if (state.status != newStatus) {
      state = state.copyWith(status: newStatus);
    }

    if (newStatus == PlayerStatus.playing && _hasLoadedSource) {
      // Playback is confirmed; any cold-start recovery is no longer needed.
      _playbackRecoveryTimer?.cancel();
      _playRequestedAt = null;
      _playRequestedPosition = null;
      _startPositionSyncTimer();
    } else if (!_pendingPlay) {
      _stopPositionSyncTimer();
    }
  }

  void _initializeListeners() {
    _subscriptions.add(_audioPlayer.playerStateStream.listen((playerState) {
      if (playerState.processingState == ja.ProcessingState.completed) {
        // CrossfadeEngine is managing this transition — it will call
        // _onCrossfadeSwapComplete which handles all state updates.
        // Also block if _beginTrueCrossfade is still resolving the source URL
        // (_crossfadeInFlight=true but isCrossfading still false).
        if (_audioPlayer.isCrossfading || _crossfadeInFlight) return;
        // Only treat as "track finished" when we actually reached the end (had duration and played to end).
        // just_audio can emit completed with 00:00/00:00 on load failure or initial state; then we must not
        // run _handleCompletion() or we get stuck at 00:00 with pause.
        final pos = _audioPlayer.position;
        final dur = _audioPlayer.duration ?? state.duration;
        final hadRealDuration = dur != null && dur.inMilliseconds > 0;
        final reachedEnd =
            hadRealDuration && pos.inMilliseconds >= dur.inMilliseconds - 800;
        logDebug(
          'Player: processingState=completed '
          'isCrossfading=${_audioPlayer.isCrossfading} '
          'pos=${pos.inMilliseconds}ms dur=${dur?.inMilliseconds}ms '
          'reachedEnd=$reachedEnd usingPlaylist=$_usingPlaylist '
          'canPlayNext=${state.canPlayNext} currentSong="${state.currentSong?.title}"',
          tag: 'Player',
        );
        if (reachedEnd ||
            (_usingPlaylist && state.canPlayNext && hadRealDuration)) {
          state = state.copyWith(
            status: PlayerStatus.paused,
            duration: dur,
          );
          _handleCompletion();
          return;
        }
        // Completed but no real duration (e.g. initial load or failed stream). Ignore so we don't
        // overwrite loading/playing with paused and leave the user stuck at 00:00.
        return;
      }

      _applyStatusFromPlayerState(playerState);
    }));

    DateTime? lastPositionUpdate;
    _subscriptions.add(_audioPlayer.positionStream.listen((position) {
      if (!_hasLoadedSource) return;

      final now = DateTime.now();
      if (lastPositionUpdate == null ||
          now.difference(lastPositionUpdate!) >
              const Duration(milliseconds: 500)) {
        lastPositionUpdate = now;
        Future.microtask(() {
          // Re-check inside microtask: _hasLoadedSource may have been cleared
          // between when this was scheduled and when it runs (song transition
          // race), which would apply a stale position to the new song.
          if (!_hasLoadedSource) return;
          // Extra safety: if we ever get stuck in loading/buffering but audio is
          // actually playing, promote to playing on the first progress tick.
          if ((state.status == PlayerStatus.loading ||
                  state.status == PlayerStatus.buffering) &&
              _audioPlayer.isPlaying) {
            state = state.copyWith(status: PlayerStatus.playing);
          }
          ref.read(playbackPositionProvider.notifier).update(position);

          // ── Trigger silent home refresh after 15 seconds of playback ──
          if (state.isPlaying &&
              _silentRefreshTriggeredForSongId != state.currentSong?.id &&
              position.inSeconds >= 15) {
            _silentRefreshTriggeredForSongId = state.currentSong?.id;
            ref.read(homeProvider.notifier).triggerSilentRefresh();
          }

          // ── macOS: trigger completion when position reaches state.duration ──
          // AVPlayer continues playing silence after the real audio ends because
          // the container duration is inflated. Two triggers:
          // 1) Position reaches state.duration (works when duration was clamped).
          // 2) Position stops advancing for 2 s while still "playing" (catches
          //    the placeholder-duration case where we couldn't clamp).
          if (Platform.isMacOS &&
              !_audioPlayer.isCrossfading &&
              !_crossfadeInFlight &&
              state.isPlaying) {
            final dur = state.duration;
            final reachedDuration = dur != null &&
                dur.inMilliseconds > 0 &&
                position.inMilliseconds >= dur.inMilliseconds - 800;
            final positionStalled = _macosLastPositionMs != null &&
                position.inMilliseconds == _macosLastPositionMs &&
                _macosLastPositionMs! > 0;
            _macosLastPositionMs = position.inMilliseconds;
            if (reachedDuration || positionStalled) {
              logDebug(
                'Player: macOS completion trigger '
                '(reachedDuration=$reachedDuration stalled=$positionStalled) '
                'pos=${position.inMilliseconds}ms dur=${dur?.inMilliseconds}ms',
                tag: 'Player',
              );
              state =
                  state.copyWith(status: PlayerStatus.paused);
              _macosLastPositionMs = null;
              _handleCompletion();
              return;
            }
          } else {
            _macosLastPositionMs = null;
          }

          // ── Gapless: proactively extend playlist 30 s before end on Android ──
          // Skip when crossfade is enabled — the crossfade engine loads the next
          // song on a separate player. Extending the ConcatenatingAudioSource here
          // would cause ExoPlayer to auto-advance to the next track at the natural
          // song boundary, playing two simultaneous instances of the same song
          // while the crossfade secondary is also ramping in.
          // macOS uses AVFoundation (single-source like iOS), not ExoPlayer CAS.
          if (Platform.isAndroid &&
              state.isGaplessEnabled &&
              state.crossfadeDurationSeconds == 0 &&
              _usingPlaylist &&
              !_didPreExtend) {
            final dur = state.duration;
            if (dur != null && dur.inSeconds > 0) {
              final remaining = dur - position;
              if (remaining.inSeconds <= 30 && remaining >= Duration.zero) {
                _didPreExtend = true;
                final nextIdx = state.currentIndex + 1;
                if (nextIdx < state.queue.length &&
                    nextIdx >= _loadedPlaylistLength) {
                  unawaited(_extendPlaylistTo(nextIdx));
                }
              }
            }
          }

          // ── True Crossfade: preload + trigger ──────────────────────────────
          final crossfadeSecs = state.crossfadeDurationSeconds;
          if (crossfadeSecs > 0 &&
              state.isPlaying &&
              state.canPlayNext &&
              !_audioPlayer.isCrossfading) {
            final dur = state.duration;
            if (dur != null && dur.inMilliseconds > 0) {
              final remaining = dur - position;
              final nextIdx = state.currentIndex + 1;

              // Pre-load: resolve & buffer Song B early so ExoPlayer is ready
              // by the time the fade window opens. Lead time = crossfadeSecs + 10s
              // (e.g., 22 s before end for a 12 s crossfade).
              final preloadLeadSecs = crossfadeSecs + 10;
              if (remaining <= Duration(seconds: preloadLeadSecs) &&
                  remaining > Duration(seconds: crossfadeSecs) &&
                  _crossfadePreloadedForIndex != nextIdx) {
                _crossfadePreloadedForIndex = nextIdx;
                unawaited(_preloadCrossfadeSecondary(nextIdx));
              }

              // Begin the actual fade ramp at crossfadeSecs before end.
              if (remaining <= Duration(seconds: crossfadeSecs) &&
                  remaining > Duration.zero &&
                  _crossfadePreparedForIndex != nextIdx) {
                _crossfadePreparedForIndex = nextIdx;
                unawaited(_beginTrueCrossfade(nextIdx, crossfadeSecs));
              }
            }
          }

          // Debounce persistence to avoid writing to disk every 500ms.
          _persistDebounceTimer?.cancel();
          _persistDebounceTimer = Timer(
            const Duration(seconds: 5),
            _persistPlaybackState,
          );
        });
      }
    }));

    _subscriptions.add(_audioPlayer.durationStream.listen((duration) {
      // Don't gate on _hasLoadedSource: just_audio may emit duration during the
      // initial setAudioSources call, before we flip _hasLoadedSource=true.
      if (!state.hasSong) return;

      if (duration != null && duration.inMilliseconds > 0) {
        Future.microtask(() {
          // On macOS, AVPlayer reports the bogus container duration (e.g. 600s).
          // Block it entirely — _maybeFetchRealDurationOnMacOS will set the
          // correct value once the YouTube player API responds, keeping the UI
          // at --:-- until then instead of showing a wrong number.
          if (Platform.isMacOS) return;
          state = state.copyWith(duration: duration);
          final song = state.currentSong;
          if (song != null) {
            _maybeUpdateNotificationDuration(song, duration);
            // Persist real duration back to library if the stored value is unknown.
            _maybeUpdateLibrarySongDuration(song, duration);
          }
          _persistPlaybackState();
        });
      }
    }));

    // Playlist mode: sync current index/song when just_audio advances (e.g. track completed).
    _subscriptions.add(_audioPlayer.currentIndexStream.listen((int? idx) {
      if (idx == null || !_usingPlaylist || state.queue.isEmpty) return;
      if (idx < 0 || idx >= state.queue.length) return;
      // CrossfadeEngine is driving this transition via onSwapComplete callback.
      // Bail here to prevent a double state-update from ConcatenatingAudioSource
      // auto-advancing in parallel with the crossfade swap.
      if (_audioPlayer.isCrossfading) return;
      final song = state.queue[idx];
      // currentIndexStream can re-emit the same index when the sequence changes
      // (e.g. when we append items). Don't reset progress unless the track changed.
      logDebug(
        'currentIndexStream: idx=$idx song="${song.title}" '
        'prevIdx=${state.currentIndex}',
        tag: 'Crossfade',
      );
      final sameTrack =
          idx == state.currentIndex && state.currentSong?.id == song.id;
      if (sameTrack) {
        // Never seed duration from song.duration (the 3:00 placeholder) on any platform.
        // durationStream (Android/iOS) and _maybeFetchRealDurationOnMacOS (macOS)
        // will set the correct value once available.
        _maybeFetchAndApplyNormalizationGain(song);
        _maybeFetchRealDurationOnMacOS(song);
        return;
      }

      state = state.copyWith(
        currentIndex: idx,
        currentSong: song,
        clearDuration: true,
      );
      _syncMediaNotification(song);
      ref.read(homeProvider.notifier).addToRecentlyPlayed(song);
      unawaited(_persistPlaybackState());
      unawaited(_prefetchUpcoming(idx));
      unawaited(_initializePlaybackTracking(song.id));
      _maybeFetchAndApplyNormalizationGain(song);
      _maybeFetchRealDurationOnMacOS(song);

      // Reset gapless pre-extend flag for the new track.
      _didPreExtend = false;

      // Progressively refill smart shuffle recs when running low.
      if (state.activeShuffleMode == ShuffleMode.smart) {
        unawaited(_maybeRefillSmartShuffle());
      }
    }));
  }

  static ja.LoopMode _toLoopMode(PlayerRepeatMode mode) {
    switch (mode) {
      case PlayerRepeatMode.off:
        return ja.LoopMode.off;
      case PlayerRepeatMode.one:
        // just_audio handles single-track looping natively.
        return ja.LoopMode.one;
      case PlayerRepeatMode.all:
        // Do NOT use ja.LoopMode.all — just_audio would loop its own internal
        // playlist (capped at 5 items), not the full app queue. Keep the
        // player in LoopMode.off so ProcessingState.completed fires at the
        // end of each track and _handleCompletion() can advance through the
        // full queue and wrap around correctly.
        return ja.LoopMode.off;
    }
  }

  void _reconcileStatusFromPlayer() {
    if (!_hasLoadedSource || !state.hasSong) return;
    _applyStatusFromPlayerState(_audioPlayer.player.playerState);
  }

  /// Resolves queue to AudioSources, sets the just_audio playlist, and optionally starts playback.
  Future<void> _syncPlaylistToQueue(
      {bool shouldPlay = false, bool isRetry = false}) async {
    // Prevent concurrent calls — if a load is already in progress, the new
    // call would interrupt it causing an infinite "Loading interrupted" loop.
    // Callers that preempt the current transition (playSong, playNext/Prev on iOS)
    // must increment _transitionGeneration and reset _isTransitioning before
    // calling here, which bypasses this guard and causes the stale call to bail.
    if (_isTransitioning && !isRetry) {
      logWarning('Player: _syncPlaylistToQueue skipped (already transitioning)',
          tag: 'Player');
      return;
    }
    final myGeneration = _transitionGeneration;

    final queue = state.queue;
    if (queue.isEmpty) {
      _usingPlaylist = false;
      _loadedPlaylistLength = 0;
      return;
    }
    final index = state.currentIndex.clamp(0, queue.length - 1);
    final position = ref.read(playbackPositionProvider);

    // If we're already using a playlist for this exact queue and we are not
    // explicitly asked to play, there is nothing to do.
    if (_usingPlaylist &&
        _hasLoadedSource &&
        _queueIdsEqual(queue, state.queue) &&
        !shouldPlay) {
      return;
    }

    // iOS: AVQueuePlayer preloads adjacent items concurrently. Fetching multiple
    // YouTube stream URLs at once causes multi-second hangs in setAudioSources.
    // Trim the queue to start at the current song and load only 1 item so
    // just_audio index 0 == app queue index 0 == current song. Additional items
    // are appended lazily by _extendPlaylistTo when playNext() is called.
    final List<Song> effectiveQueue;
    final int effectiveIndex;
    if (((isApplePlatform) ||
            state.crossfadeDurationSeconds > 0) &&
        index > 0) {
      // Apple platforms (iOS, macOS): AVQueuePlayer single-source mode always
      // starts at index 0. Android+crossfade: maxItems=1, so toResolve=[queue[0..0]]
      // but effectiveIndex could be >0 after a swap — rebase to avoid RangeError.
      effectiveQueue = queue.sublist(index);
      effectiveIndex = 0;
      // Rebase so state.currentIndex=0 matches just_audio's index=0.
      state = state.copyWith(queue: effectiveQueue, currentIndex: 0);
    } else {
      effectiveQueue = queue;
      effectiveIndex = index;
    }

    _isTransitioning = true;
    state = state.copyWith(status: PlayerStatus.loading, clearError: true);

    try {
      const resolveTimeout = Duration(seconds: 20);
      // iOS: resolve only the primary song to avoid concurrent YouTube URL
      // fetches that block setAudioSources for 5–10 seconds.
      // Android + crossfade: limit to 1 item so ExoPlayer cannot auto-advance
      // the ConcatenatingAudioSource at the natural song boundary while the
      // CrossfadeEngine secondary is ramping in. With multiple items loaded,
      // ExoPlayer starts its own gapless pre-render ~3–4 s before the boundary
      // (decoder switch visible in the log), fires a currentIndexStream re-emit,
      // and can slip past the isCrossfading guard during the secondary-load
      // window — corrupting the crossfade state. A 1-item playlist prevents
      // any auto-advance; ProcessingState.completed at song end is blocked by
      // the isCrossfading guard, and _extendPlaylistTo / _handleCompletion
      // provide the correct fallback if the crossfade itself fails.
      final maxItems = ((isApplePlatform) ||
              state.crossfadeDurationSeconds > 0)
          ? 1
          : 5;
      final toResolve = effectiveQueue.take(maxItems).toList();
      final sources = <ja.AudioSource>[];

      // Resolve upcoming items concurrently so we don't serialize N×network latency.
      // Uses resolveForPlayback which checks cache first - if cache exists, playback starts instantly.
      final futures = List.generate(toResolve.length, (i) async {
        try {
          final resolved = await _audioRepository
              .resolveForPlayback(toResolve[i])
              .timeout(resolveTimeout,
                  onTimeout: () => throw TimeoutException('Resolve timed out'));

          if (resolved is ResolvedAudioSourceStream) {
            _audioRepository.startBackgroundCacheDownload(
              toResolve[i].id,
              resolved.url,
              resolved.headers,
            );
          }

          return (
            resolved: resolved,
            source: _audioRepository.toAudioSource(resolved)
          );
        } catch (e) {
          logWarning(
              'Player: resolveForPlayback failed for ${toResolve[i].id}: $e',
              tag: 'Player');
          return null;
        }
      });

      final resolvedResults = await Future.wait(futures);

      // Bail if a newer song selection preempted this load while we were fetching URLs.
      if (_transitionGeneration != myGeneration) return;

      // If the primary song failed to resolve, surface an error immediately.
      if (resolvedResults.isEmpty || resolvedResults[effectiveIndex] == null) {
        logError(
            'Player: Primary song failed to resolve, cannot start playback',
            tag: 'Player');
        state = state.copyWith(
            status: PlayerStatus.error, error: 'Failed to load song');
        return;
      }

      // Check if primary song has cache with resume position - verify position is actually cached
      if (position > Duration.zero) {
        final primaryResult = resolvedResults[effectiveIndex];
        if (primaryResult != null) {
          final resolved = primaryResult.resolved;
          if (resolved is ResolvedAudioSourceFile &&
              resolved.kind == AudioSourceKind.streamCached) {
            final cacheInfo = await _audioRepository
                .getCacheInfo(toResolve[effectiveIndex].id);
            if (cacheInfo.isComplete) {
              log('Player: cache is complete (${cacheInfo.cachedBytes} bytes), using file directly',
                  tag: 'Player');
            } else {
              final isPositionCached = await _audioRepository.isPositionCached(
                toResolve[effectiveIndex].id,
                position,
                state.duration,
              );
              if (!isPositionCached) {
                log('Player: cache incomplete and position not cached, falling back to URL',
                    tag: 'Player');
                await _reloadCurrentSongFromUrl(position);
                _isTransitioning = false;
                return;
              }
            }
          }
        }
      }

      // Build the sources list, tracking the adjusted index (some items may be skipped).
      int initialIndex = 0;
      for (int i = 0; i < resolvedResults.length; i++) {
        final result = resolvedResults[i];
        if (result != null) {
          if (i == effectiveIndex) initialIndex = sources.length;
          sources.add(result.source);
        }
      }

      if (sources.isEmpty) {
        logError('Player: No audio sources resolved, playback cannot start',
            tag: 'Player');
        _isTransitioning = false;
        return;
      }
      initialIndex = initialIndex.clamp(0, sources.length - 1);

      await _audioPlayer.setPlaylist(
        sources,
        initialIndex: initialIndex,
      );

      // Bail if preempted during setPlaylist (which can block for several seconds on iOS).
      if (_transitionGeneration != myGeneration) return;

      _audioPlayer.setLoopMode(_toLoopMode(state.repeatMode));
      _usingPlaylist = true;
      // On iOS and Android+crossfade, _loadedPlaylistLength = 1 so playNext()
      // triggers _extendPlaylistTo for the next song. On Android without crossfade,
      // all resolved items (up to 5) are already loaded for gapless playback.
      _loadedPlaylistLength = sources.length;
      _hasLoadedSource = true;
      final loadedSong = effectiveQueue[initialIndex];
      state = state.copyWith(
        currentIndex: initialIndex,
        currentSong: loadedSong,
        status: shouldPlay ? PlayerStatus.loading : PlayerStatus.paused,
      );
      unawaited(_cacheSongMetadata(loadedSong));
      _syncMediaNotification(state.currentSong!);
      if (shouldPlay) {
        _playRequestedAt = DateTime.now();
        _playRequestedPosition = _audioPlayer.position;
        try {
          await _audioPlayer.play();
        } catch (e) {
          logWarning('Player: _syncPlaylistToQueue play failed: $e',
              tag: 'Player');
        }
        _startPositionSyncTimer();
        unawaited(_schedulePlaybackRecovery());
      }
      unawaited(_prefetchUpcoming(initialIndex));
      unawaited(_initializePlaybackTracking(effectiveQueue[initialIndex].id));
    } catch (e) {
      final msg = e.toString();
      if (msg.contains('Loading interrupted')) {
        logWarning(
            'Player: _syncPlaylistToQueue (Loading interrupted), retrying once',
            tag: 'Player');
        _isTransitioning = false;
        unawaited(
            Future<void>.delayed(const Duration(milliseconds: 400), () async {
          if (state.queue.isEmpty) return;
          await _syncPlaylistToQueue(shouldPlay: shouldPlay, isRetry: true);
        }));
        return;
      }
      logError('Player: _syncPlaylistToQueue failed: $e', tag: 'Player');
      state = state.copyWith(
          status: PlayerStatus.error, error: 'Failed to load queue: $e');
    } finally {
      _isTransitioning = false;
      _reconcileStatusFromPlayer();
    }
  }

  /// On cold starts some devices report "ready" and UI flips to playing,
  /// but audio doesn't actually start until the user taps pause/play.
  /// This performs the same pause→play recovery automatically once.
  Future<void> _schedulePlaybackRecovery() async {
    _playbackRecoveryTimer?.cancel();
    _playbackRecoveryTimer = Timer(const Duration(milliseconds: 450), () async {
      // Only recover if the app still believes we should be playing.
      if (_disposed) return;
      if (!_hasLoadedSource) return;

      try {
        final ps = _audioPlayer.player.playerState;
        if (ps.playing) return; // already playing, no recovery.
        // Only recover when the player is fully ready but not playing.
        // If still buffering, audio is actively loading — interrupting it with
        // pause→play causes the 1-second reset by restarting the buffer pipeline.
        if (ps.processingState != ja.ProcessingState.ready) return;

        // If we already advanced playback since the request, nothing to do.
        final requestedPos = _playRequestedPosition;
        final currentPos = _audioPlayer.position;
        if (requestedPos != null) {
          final delta = currentPos - requestedPos;
          if (delta > const Duration(milliseconds: 250)) return;
        } else {
          if (currentPos > const Duration(milliseconds: 250)) return;
        }

        logInfo('Player: playback recovery – retry play', tag: 'Player');
        _playbackRecoveryTimer?.cancel();
        _playRequestedAt = null;
        _playRequestedPosition = null;
        // Skip pause(): the player is in ready+!playing (cold-start stuck state).
        // Calling play() alone is sufficient to unstick it, and avoids the
        // audible pause gap that pause→play introduces on normal playback paths.
        await _audioPlayer.play();
      } catch (e) {
        logWarning('Player: playback recovery failed: $e', tag: 'Player');
      }
    });
  }

  void _handleCompletion() {
    logDebug(
      'Player: _handleCompletion — repeatMode=${state.repeatMode} '
      'canPlayNext=${state.canPlayNext} usingPlaylist=$_usingPlaylist '
      'currentIndex=${state.currentIndex} queueLen=${state.queue.length}',
      tag: 'Player',
    );
    switch (state.repeatMode) {
      case PlayerRepeatMode.one:
        seekTo(Duration.zero);
        play();
        return;
      case PlayerRepeatMode.all:
        if (state.canPlayNext) {
          playNext();
        } else if (state.queue.isNotEmpty) {
          if (_usingPlaylist) {
            _audioPlayer.setPlaylistIndex(0).then((_) => _audioPlayer.play());
          } else {
            unawaited(_syncPlaylistToQueue(shouldPlay: true).then((_) async {
              await _audioPlayer.setPlaylistIndex(0);
              await _audioPlayer.play();
            }));
          }
        }
        return;
      case PlayerRepeatMode.off:
        if (state.canPlayNext) {
          playNext();
          return;
        }
        break;
    }

    // When starting from a single song, the smart "Up next" queue is loaded
    // in the background. If the song finishes before recommendations arrive,
    // completion fires while queue.length == 1, so canPlayNext is false and
    // playback stops. To avoid this race, kick off a one-shot queue fill and
    // advance if new tracks become available.
    final song = state.currentSong;
    if (song == null) return;
    if (state.queue.length <= 1) {
      unawaited(Future<void>(() async {
        await _loadQueueInBackground(song, playlistId: _lastPlaylistId);
        if (state.canPlayNext) {
          await playNext();
        }
      }));
    }
  }

  Future<void> _startPlaybackWithRecovery() async {
    _playRequestedAt = DateTime.now();
    _playRequestedPosition = _audioPlayer.position;
    state = state.copyWith(status: PlayerStatus.loading);
    try {
      await _audioPlayer.play();
    } catch (e) {
      logWarning('Player: _startPlaybackWithRecovery initial play failed: $e',
          tag: 'Player');
    }
    _syncPositionAndDurationFromPlayer();
    _startPositionSyncTimer();
    // Recovery check after 400ms to ensure playback actually started
    await Future<void>.delayed(const Duration(milliseconds: 400));
    _isTransitioning = false;
    _syncPositionAndDurationFromPlayer();
    try {
      if (!_audioPlayer.isPlaying && state.hasSong && state.isPlaying) {
        await _audioPlayer.play();
        logInfo('Player: recovery play executed', tag: 'Player');
      }
    } catch (e) {
      logWarning('Player: recovery play failed: $e', tag: 'Player');
    }
  }

  void _syncPositionAndDurationFromPlayer() {
    if (_disposed) return;
    if (!_hasLoadedSource) return;
    try {
      final pos = _audioPlayer.position;
      final dur = _audioPlayer.duration;
      ref.read(playbackPositionProvider.notifier).update(pos);

      // Update duration if available (macOS blocks container duration)
      final newDuration = Platform.isMacOS
          ? state.duration
          : (dur != null && dur.inMilliseconds > 0)
              ? dur
              : state.duration;
      
      if (newDuration != state.duration) {
        state = state.copyWith(duration: newDuration);
      }
    } catch (e) {
      logWarning('Player: _syncPositionAndDurationFromPlayer failed: $e',
          tag: 'Player');
    }
  }

  void _startPositionSyncTimer() {
    _stopPositionSyncTimer();
    // Sync immediately first, before starting the periodic timer
    // This ensures position updates quickly on first play
    _syncPositionAndDurationFromPlayer();
    _positionSyncTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => _syncPositionAndDurationFromPlayer(),
    );
  }

  void _stopPositionSyncTimer() {
    _positionSyncTimer?.cancel();
    _positionSyncTimer = null;
  }

  Future<void> playSong(
    Song song, {
    List<Song>? queue,
    String? playlistId,
    String? queueSource,
  }) async {
    _audioPlayer.cancelCrossfade();
    _resetCrossfadeIndices();
    _crossfadeInFlight = false;
    final effectiveNewQueue =
        (queue != null && queue.length > 1) ? queue : [song];
    if (state.currentSong?.id == song.id &&
        _queueIdsEqual(effectiveNewQueue, state.queue)) {
      _lastQueueSource = queueSource;
      _lastPlaylistId = playlistId;
      // If the audio source hasn't been loaded yet (e.g. restored from saved state),
      // we still need to load and play it instead of returning early.
      if (_hasLoadedSource) return;
    }

    _lastQueueSource = queueSource;
    _lastPlaylistId = playlistId;
    _originalQueue = [];
    _smartShufflePlaylistSongs = [];
    _smartSeedIndex = 0;
    _smartShuffleRefilling = false;
    // Guard position timer before the await below — without this, the 1-second
    // timer fires during _shouldFillQueue() and reads the old song's position
    // from _audioPlayer (which hasn't been reset yet), then _syncPlaylistToQueue
    // picks up that non-zero position as initialPosition for the new song.
    _hasLoadedSource = false;
    _macosLastPositionMs = null;
    _lastRealDurationFetchedForSongId = null;
    _silentRefreshTriggeredForSongId = null;
    state = state.copyWith(
      currentSong: song,
      queue: queue != null && queue.length > 1 ? queue : [song],
      currentIndex: queue != null && queue.length > 1
          ? queue.indexWhere((s) => s.id == song.id).clamp(0, queue.length - 1)
          : 0,
      isShuffleEnabled: false,
      clearError: true,
      clearSmartShuffleIds: true,
      activeShuffleMode: _readActiveShuffleMode(queueSource, playlistId),
    );
    _applyQueueInvariant();

    // Fill queue with recommendations in background; start playback immediately.
    // Single song: replace queue with recommendations.
    // Smart shuffle (full playlist queue): append recommendations after existing songs.
    final shouldFill = await _shouldFillQueue(queueSource, playlistId);
    if (shouldFill) {
      unawaited(_loadQueueInBackground(song, playlistId: playlistId));
    }

    // Record as recently played immediately. The currentIndexStream listener
    // skips the callback when the song hasn't changed (sameTrack guard), so
    // explicitly-started songs would otherwise never be recorded.
    ref.read(homeProvider.notifier).addToRecentlyPlayed(song);

    // An explicit user song selection must always win over any in-progress
    // transition (e.g. the previous song was still loading when the user tapped
    // a new one). Increment the generation so the stale load bails at its next
    // await checkpoint, then clear the guard so _syncPlaylistToQueue runs.
    _transitionGeneration++;
    _isTransitioning = false;
    await _syncPlaylistToQueue(shouldPlay: true);
  }

  Future<void> _loadQueueInBackground(Song song, {String? playlistId}) async {
    try {
      // Always pass null for smart shuffle: local playlist IDs (lib_xxx) are
      // not recognised by the YouTube Music API and produce empty results.
      final isSmartShuffleAppend = state.queue.length > 1;
      final isSmart = state.activeShuffleMode == ShuffleMode.smart;
      var tracks = await _streamManager.getRecommendedQueue(
        song.id,
        playlistId: (isSmartShuffleAppend || isSmart) ? null : playlistId,
        maxResults: 10,
      );

      if (tracks.isEmpty) return;

      final newQueue = tracks.map(Song.fromTrack).toList();

      if (state.currentSong?.id != song.id) return;

      // Smart shuffle with a full playlist queue: interleave recommendations
      // inline (1 rec per every 2 playlist songs, Spotify-style).
      if (state.queue.length > 1) {
        // Capture original playlist songs once for later seed rotation in refills.
        if (_smartShufflePlaylistSongs.isEmpty) {
          _smartShufflePlaylistSongs = List<Song>.from(state.queue);
        }

        final existingIds = state.queue.map((s) => s.id).toSet();
        final freshRecs =
            newQueue.where((s) => !existingIds.contains(s.id)).toList();
        if (freshRecs.isEmpty) return;

        // Interleave into songs ahead of the currently playing track.
        final currentIdx = state.currentIndex;
        final songsAhead = state.queue.sublist(currentIdx + 1);
        final interleaved = _interleaveSmartRecs(songsAhead, freshRecs);

        final newSmartIds = interleaved
            .where((s) => !existingIds.contains(s.id))
            .map((s) => s.id)
            .toSet();

        state = state.copyWith(
          queue: [
            ...state.queue.sublist(0, currentIdx + 1),
            ...interleaved,
          ],
          smartShuffleSongIds: {
            ...state.smartShuffleSongIds,
            ...newSmartIds,
          },
        );
        _applyQueueInvariant();
        return;
      }

      var index = newQueue.indexWhere((s) => s.id == song.id);
      if (index < 0) {
        newQueue.insert(0, song);
        index = 0;
      }

      // Preserve browse IDs that _playAtIndex may have already enriched via
      // getSongFromPlayer. _loadQueueInBackground runs concurrently (unawaited)
      // and can finish after _playAtIndex sets albumBrowseId/artistBrowseId,
      // so we must not clobber those fields with null values from fetchNext.
      var queueSong = newQueue[index];
      final priorSong = state.currentSong;
      if (priorSong != null && priorSong.id == queueSong.id) {
        queueSong = queueSong.copyWith(
          albumBrowseId: queueSong.albumBrowseId ?? priorSong.albumBrowseId,
          artistBrowseId: queueSong.artistBrowseId ?? priorSong.artistBrowseId,
          albumName: queueSong.albumName ?? priorSong.albumName,
        );
        // Also update the queue entry so navigation from song tiles is correct.
        newQueue[index] = queueSong;
      }

      // For smart shuffle single-song: mark all non-seed songs as ✨.
      final smartIdsForSingleSong = isSmart
          ? newQueue
              .where((s) => s.id != song.id)
              .map((s) => s.id)
              .toSet()
          : state.smartShuffleSongIds;

      // For single-song smart shuffle seed rotation, store the seed song.
      if (isSmart && _smartShufflePlaylistSongs.isEmpty) {
        _smartShufflePlaylistSongs = [song];
      }

      state = state.copyWith(
        queue: newQueue,
        currentIndex: index,
        currentSong: queueSong,
        smartShuffleSongIds: smartIdsForSingleSong,
      );
      _applyQueueInvariant();
      // Only sync the just_audio playlist when we already have an active
      // playback session. On cold start (restored paused song), we keep this
      // cheap so the mini player doesn't sit in a long loading state.
      if (state.isPlaying || _hasLoadedSource) {
        if (_usingPlaylist && _hasLoadedSource) {
          // Crossfade mode: never append items to the primary
          // ConcatenatingAudioSource. CrossfadeEngine loads the next track on
          // a dedicated secondary player. Adding items here lets ExoPlayer
          // auto-advance at the natural song boundary, bypassing the
          // isCrossfading guard and corrupting crossfade state.
          // On iOS/macOS the player is in single-source mode (setAudioSource).
          // addToPlaylist would cause just_audio to wrap sources in a
          // ConcatenatingAudioSource and emit the combined duration of the
          // current + next song, breaking the seek bar. Queue advance is
          // handled by _syncPlaylistToQueue reloading per song on those platforms.
          if (state.crossfadeDurationSeconds == 0 &&
              !isApplePlatform) {
            // Gapless mode (Android only): append upcoming songs directly to
            // avoid the brief audio gap that setPlaylist() would cause.
            const maxTotal = 5;
            final toAppend = newQueue
                .skip(_loadedPlaylistLength)
                .take((maxTotal - _loadedPlaylistLength).clamp(0, maxTotal))
                .toList();
            for (final s in toAppend) {
              if (!_hasLoadedSource || !_usingPlaylist) break;
              if (state.crossfadeDurationSeconds > 0) break;
              try {
                final src = await _audioRepository
                    .resolveToAudioSource(s)
                    .timeout(const Duration(seconds: 20));
                await _audioPlayer.addToPlaylist(src);
                _loadedPlaylistLength++;
              } catch (e) {
                logWarning(
                    'Player: _loadQueueInBackground append failed for ${s.id}: $e',
                    tag: 'Player');
              }
            }
          }
          unawaited(_prefetchUpcoming(index));
        } else {
          // Skip _syncPlaylistToQueue when crossfade mode already has the
          // current track loaded on the new primary — reloading would cancel
          // the active crossfade and interrupt playback.
          if (!(_hasLoadedSource && state.crossfadeDurationSeconds > 0)) {
            unawaited(_syncPlaylistToQueue(shouldPlay: state.isPlaying));
          }
        }
      }
    } catch (e) {
      logWarning('Player: _loadQueueInBackground failed: $e', tag: 'Player');
    }
  }

  void reorderQueue(int oldIndex, int newIndex) {
    if (oldIndex < 0 ||
        oldIndex >= state.queue.length ||
        newIndex < 0 ||
        newIndex >= state.queue.length ||
        oldIndex == newIndex) {
      return;
    }
    final queue = state.queue;
    final newQueue = List<Song>.from(queue);
    final item = newQueue.removeAt(oldIndex);
    final insertIndex = newIndex > oldIndex ? newIndex - 1 : newIndex;
    newQueue.insert(insertIndex, item);
    final currentId = state.currentSong?.id ?? queue[state.currentIndex].id;
    final newCurrentIndex = newQueue
        .indexWhere((s) => s.id == currentId)
        .clamp(0, newQueue.length - 1);
    state = state.copyWith(
      queue: newQueue,
      currentIndex: newCurrentIndex,
      currentSong: newQueue[newCurrentIndex],
    );
    _applyQueueInvariant();
    // Only call moveInPlaylist when both indices are within the loaded playlist
    // window. On Apple platforms (iOS/macOS) and crossfade mode, _loadedPlaylistLength
    // is always 1, so any drag between indices ≥ 1 would cause ConcatenatingAudioSource
    // to removeAt(n) on a 1-element list → RangeError (length): Invalid value: Only
    // valid value is 0: 1. The app-state queue is already updated above, so skipping
    // the player call is safe — the player is in single-source mode anyway.
    if (_usingPlaylist &&
        oldIndex < _loadedPlaylistLength &&
        insertIndex < _loadedPlaylistLength) {
      _audioPlayer.moveInPlaylist(oldIndex, insertIndex);
    }
  }

  Future<void> removeFromQueue(int index) async {
    final queue = state.queue;
    if (index < 0 || index >= queue.length) return;

    final isCurrent = index == state.currentIndex;
    final wasPlaying = _audioPlayer.isPlaying;
    final newQueue = List<Song>.from(queue)..removeAt(index);

    if (newQueue.isEmpty) {
      _stopPositionSyncTimer();
      await _audioPlayer.stop();
      _usingPlaylist = false;
      _loadedPlaylistLength = 0;
      _hasLoadedSource = false;
      state = state.copyWith(
        queue: const [],
        currentIndex: -1,
        clearSong: true,
      );
      return;
    }

    var newIndex = state.currentIndex;
    if (index < state.currentIndex) {
      newIndex = state.currentIndex - 1;
    } else if (index == state.currentIndex) {
      newIndex = index >= newQueue.length ? newQueue.length - 1 : index;
    }
    final newCurrentIndex = newIndex.clamp(0, newQueue.length - 1);

    // Only remove from the just_audio playlist if the item is within the
    // loaded window (first _loadedPlaylistLength items). Items beyond that
    // haven't been added to the player yet, so there's nothing to remove.
    if (_usingPlaylist && index < _loadedPlaylistLength) {
      try {
        await _audioPlayer.removeFromPlaylist(index);
        _loadedPlaylistLength--;
      } catch (e) {
        logWarning('Player: removeFromPlaylist($index) failed: $e',
            tag: 'Player');
      }
    }

    // Always update state so the UI reflects the removal regardless of
    // whether the just_audio playlist call succeeded.
    state = state.copyWith(
      queue: newQueue,
      currentIndex: newCurrentIndex,
      currentSong: newQueue[newCurrentIndex],
    );
    _applyQueueInvariant();

    if (isCurrent && _usingPlaylist) {
      await _audioPlayer.setPlaylistIndex(newCurrentIndex);
      if (wasPlaying) await _audioPlayer.play();
    }
  }

  /// Appends [song] to the end of the current queue without interrupting
  /// playback or triggering recommendation loading.
  ///
  /// If there is no active queue the song is played immediately instead.
  Future<void> addToQueue(Song song) async {
    final queue = state.queue;
    if (queue.isEmpty || state.currentSong == null) {
      await playSong(song);
      return;
    }

    final newQueue = [...queue, song];
    state = state.copyWith(queue: newQueue);

    // Append to the just_audio playlist if it has been set up.
    // iOS/macOS use single-source mode (setAudioSource). Calling addToPlaylist
    // causes just_audio to wrap into a ConcatenatingAudioSource and emit the
    // combined duration of both songs, breaking the seek bar. Queue advance is
    // handled by _syncPlaylistToQueue reloading per song on those platforms.
    if (_usingPlaylist &&
        _hasLoadedSource &&
        !isApplePlatform) {
      try {
        final source = await _audioRepository
            .resolveToAudioSource(song)
            .timeout(const Duration(seconds: 20),
                onTimeout: () => throw TimeoutException('Resolve timed out'));
        await _audioPlayer.addToPlaylist(source);
        _loadedPlaylistLength++;
      } catch (e) {
        logWarning('Player: addToQueue resolveToAudioSource failed: $e',
            tag: 'Player');
      }
    }
  }

  bool _hasLoadedSource = false;

  Future<void> togglePlayPause() async {
    // If we already have a loaded playlist, just toggle play/pause — don't rebuild.
    if (_usingPlaylist && _hasLoadedSource) {
      if (_audioPlayer.isPlaying) {
        await pause();
      } else {
        await play();
      }
      return;
    }

    if (_audioPlayer.isPlaying) {
      await pause();
      return;
    }

    if (state.hasSong) {
      final resumePos = ref.read(playbackPositionProvider);
      final pos = resumePos > Duration.zero ? resumePos : null;

      final localPath = _resolveLocalPath(state.currentSong!.id);
      if (localPath != null) {
        await _playLocalFile(state.currentSong!, localPath,
            resumePosition: pos);
        return;
      }

      await _syncPlaylistToQueue(shouldPlay: true);
      return;
    }

    await play();
  }

  Future<void> _playLocalFile(Song song, String localPath,
      {Duration? resumePosition}) async {
    _isTransitioning = true;
    state = state.copyWith(
      status: PlayerStatus.loading,
      clearError: true,
    );

    try {
      final source = await _audioRepository.resolveSource(song).timeout(
            const Duration(seconds: 30),
            onTimeout: () => throw TimeoutException('Resolve source timed out'),
          );
      if (source is! ResolvedAudioSourceFile) {
        _isTransitioning = false;
        await _syncPlaylistToQueue(shouldPlay: true);
        return;
      }
      _syncMediaNotification(song);
      unawaited(_audioPlayer.pause());
      await _audioRepository.applySource(
        source,
        _audioPlayer,
        initialPosition: resumePosition,
      );
      _hasLoadedSource = true;
      // Downloaded/device playback uses a local file path, so we must explicitly
      // fetch/apply LUFS normalization gain here (the stream playlist path
      // normally handles this via `currentIndexStream`).
      _maybeFetchAndApplyNormalizationGain(song);
      _maybeFetchRealDurationOnMacOS(song);
      if (resumePosition != null && resumePosition > Duration.zero) {
        await _audioPlayer.seek(resumePosition);
      }
      await _startPlaybackWithRecovery();
      ref.read(homeProvider.notifier).addToRecentlyPlayed(song);
    } catch (e) {
      logError('PlayLocal: FAILED ($e), falling back to stream', tag: 'Player');
      _isTransitioning = false;
      await _syncPlaylistToQueue(shouldPlay: true);
    }
  }

  Future<void> play() async {
    // First ensure audio source is loaded before playing
    if (!_hasLoadedSource) {
      logWarning('Player: play called but no source loaded, syncing first',
          tag: 'Player');
      await _syncPlaylistToQueue(shouldPlay: true);
      return;
    }

    _playRequestedAt = DateTime.now();
    _playRequestedPosition = _audioPlayer.position;
    state = state.copyWith(status: PlayerStatus.loading);
    try {
      await _audioPlayer.play();
      _startPositionSyncTimer();
    } catch (e) {
      logError('Player: play failed: $e', tag: 'Player');
      state = state.copyWith(
          status: PlayerStatus.paused, error: 'Failed to start playback');
    }
  }

  Future<void> pause() async {
    _stopPositionSyncTimer();
    _playRequestedAt = null;
    _resetCrossfadeIndices();
    _crossfadeInFlight = false;
    await _audioPlayer.pause();
    state = state.copyWith(status: PlayerStatus.paused);
    if (_hasLoadedSource) {
      try {
        final song = state.currentSong;
        if (song != null) {
          final box = await Hive.openBox<dynamic>('player_state');
          final prefs = await SharedPreferences.getInstance();
          await Future.wait([
            box.put('song', song.toJson()),
            prefs.setInt(StorageKeys.prefsLastPlayedPositionMs,
                _audioPlayer.position.inMilliseconds),
            prefs.setInt(
                StorageKeys.prefsLastPlayedDurationMs,
                _audioPlayer.duration?.inMilliseconds ??
                    state.duration?.inMilliseconds ??
                    0),
          ]);
        }
      } catch (e) {
        logWarning('Player: pause persist failed: $e', tag: 'Player');
      }
    }
  }

  Future<void> seekTo(Duration position) async {
    _resetCrossfadeIndices();
    _crossfadeInFlight = false;

    final song = state.currentSong;
    final duration = state.duration;

    if (song != null && duration != null && duration.inMilliseconds > 0) {
      final isDownloaded = _resolveLocalPath(song.id) != null;

      if (!isDownloaded) {
        final cacheInfo = await _audioRepository.getCacheInfo(song.id);
        if (cacheInfo.exists && !cacheInfo.isComplete) {
          final isPositionCached = await _audioRepository.isPositionCached(
            song.id,
            position,
            duration,
          );

          if (!isPositionCached) {
            log('Player: seekTo $position - position not cached, reloading from URL',
                tag: 'Player');
            await _reloadCurrentSongFromUrl(position);
            return;
          }
        }
      }
    }

    await _audioPlayer.seek(position);
    ref.read(playbackPositionProvider.notifier).update(position);
  }

  Future<void> _reloadCurrentSongFromUrl([Duration? seekPosition]) async {
    final song = state.currentSong;
    if (song == null) return;

    try {
      final streamData = await _streamManager.getStreamUrl(song.id);
      final url = streamData['stream_url'] as String;
      final headers = streamData['headers'] as Map<String, String>?;

      await _audioPlayer.playUrl(
        url,
        headers: headers,
        initialPosition: seekPosition,
      );

      _audioRepository.startBackgroundCacheDownload(song.id, url, headers);
      log('Player: reloaded from URL, caching continues in background',
          tag: 'Player');
    } catch (e) {
      logError('Player: _reloadCurrentSongFromUrl failed: $e', tag: 'Player');
    }
  }

  Future<void> playNext() async {
    if (!state.canPlayNext) return;
    _audioPlayer.cancelCrossfade();
    _resetCrossfadeIndices();
    _crossfadeInFlight = false;
    final nextIndex = state.currentIndex + 1;
    if (_usingPlaylist) {
      if (isApplePlatform) {
        // Apple platforms (iOS, macOS): single-source mode (no ConcatenatingAudioSource).
        // Update the current index first so _syncPlaylistToQueue loads the right song.
        _hasLoadedSource = false;
        _macosLastPositionMs = null;
        _lastRealDurationFetchedForSongId = null;
        _silentRefreshTriggeredForSongId = null;
        _transitionGeneration++;
        _isTransitioning = false;
        final nextSong = state.queue[nextIndex];
        state = state.copyWith(
          currentIndex: nextIndex,
          currentSong: nextSong,
          status: PlayerStatus.loading,
        );
        ref.read(homeProvider.notifier).addToRecentlyPlayed(nextSong);
        await _syncPlaylistToQueue(shouldPlay: true);
        return;
      }
      
      // Universal cache-aware logic for all platforms
      if (nextIndex < _loadedPlaylistLength) {
        final nextSong = state.queue[nextIndex];
        
        // Check if we have SIGNIFICANT cache that would provide clear benefit
        // Only rebuild if we have substantial cached data AND the current source is a stream
        // (i.e., we're upgrading from stream to cached file, not just rebuilding for no reason)
        final cacheInfo = await _audioRepository.getCacheInfo(nextSong.id);
        final hasSubstantialCache = cacheInfo.exists && cacheInfo.filePath != null && 
                                   (cacheInfo.isComplete || cacheInfo.cachedBytes >= (5 * 1024 * 1024)); // 5MB+ or complete
        
        // Additional check: only rebuild if we're confident the current source is a stream
        // This prevents unnecessary rebuilds when cache might not provide clear benefit
        var shouldRebuild = hasSubstantialCache;
        
        if (hasSubstantialCache) {
          // Check if the current playlist source is likely a stream (not already a file)
          // If we're in the first few songs and cache was recently added, it's likely upgrading
          final isLikelyUpgrading = nextIndex < 5 && cacheInfo.cachedBytes > (3 * 1024 * 1024); // 3MB+ in first 5 songs
          shouldRebuild = isLikelyUpgrading;
          
          logDebug('Player: playNext cache analysis for ${nextSong.id}: '
              'substantial=$hasSubstantialCache, likelyUpgrading=$isLikelyUpgrading, '
              'cachedBytes=${cacheInfo.cachedBytes}',
              tag: 'Player');
        }
        
        if (shouldRebuild) {
          logDebug('Player: playNext rebuilding playlist to use cached file for ${nextSong.id}', tag: 'Player');
          
          // Update state immediately to prevent UI glitch
          final oldState = state;
          state = state.copyWith(
            currentIndex: nextIndex,
            currentSong: nextSong,
            status: PlayerStatus.loading,
          );
          ref.read(homeProvider.notifier).addToRecentlyPlayed(nextSong);
          
          try {
            // Force playlist rebuild to use cached file instead of original stream
            _transitionGeneration++;
            _isTransitioning = false;
            _hasLoadedSource = false; // Force full re-resolution
            
            await _syncPlaylistToQueue(shouldPlay: true);
            return;
          } catch (e) {
            // Fallback to normal transition if rebuild fails
            logWarning('Player: Cache rebuild failed, using normal transition: $e', tag: 'Player');
            state = oldState.copyWith(currentIndex: nextIndex, currentSong: nextSong);
            await _audioPlayer.setPlaylistIndex(nextIndex);
            await _audioPlayer.play();
            state = state.copyWith(status: PlayerStatus.playing);
            return;
          }
        }
        
        // No substantial cache or not worth rebuilding, use normal instant playlist transition
        logDebug('Player: playNext using normal instant transition for ${nextSong.id}', tag: 'Player');
        state = state.copyWith(
          currentIndex: nextIndex,
          currentSong: nextSong,
        );
        await _audioPlayer.setPlaylistIndex(nextIndex);
        await _audioPlayer.play();
        return;
      }
      
      // just_audio playlist is only loaded with first 5 items; extend if we're going past.
      if (nextIndex >= _loadedPlaylistLength) {
        await _extendPlaylistTo(nextIndex);
      }
      if (nextIndex < _loadedPlaylistLength) {
        await _audioPlayer.setPlaylistIndex(nextIndex);
        await _audioPlayer.play();
      }
      return;
    }
    logDebug(
      'Player: playNext — no playlist, calling _syncPlaylistToQueue '
      'currentIndex=${state.currentIndex} nextIndex=$nextIndex',
      tag: 'Player',
    );
    await _syncPlaylistToQueue(shouldPlay: true);
    if (state.currentIndex != nextIndex) {
      await _audioPlayer.setPlaylistIndex(nextIndex);
      await _audioPlayer.play();
    }
  }

  Future<void> _extendPlaylistTo(int targetIndex) async {
    final queue = state.queue;
    if (targetIndex < 0 || targetIndex >= queue.length) return;
    if (targetIndex < _loadedPlaylistLength) return;

    _isTransitioning = true;
    state = state.copyWith(status: PlayerStatus.loading, clearError: true);
    try {
      const resolveTimeout = Duration(seconds: 20);
      const batchSize = 5;
      final start = _loadedPlaylistLength;
      final end = (targetIndex + batchSize).clamp(start, queue.length);
      final toResolve = queue.sublist(start, end);
      final futures = toResolve.map((song) async {
        try {
          return await _audioRepository.resolveToAudioSource(song).timeout(
              resolveTimeout,
              onTimeout: () => throw TimeoutException('Resolve timed out'));
        } catch (e) {
          logWarning('Player: resolveToAudioSource failed for ${song.id}: $e',
              tag: 'Player');
          return null;
        }
      });
      final sources =
          (await Future.wait(futures)).whereType<ja.AudioSource>().toList();
      for (final source in sources) {
        await _audioPlayer.addToPlaylist(source);
      }
      _loadedPlaylistLength += sources.length;
    } catch (e) {
      logError('Player: _extendPlaylistTo failed: $e', tag: 'Player');
      state = state.copyWith(
          status: PlayerStatus.error, error: 'Failed to load next: $e');
    } finally {
      _isTransitioning = false;
    }
  }

  Future<void> playPrevious() async {
    if (ref.read(playbackPositionProvider).inSeconds > 3) {
      await seekTo(Duration.zero);
      return;
    }
    if (!state.canPlayPrevious) return;
    _audioPlayer.cancelCrossfade();
    _resetCrossfadeIndices();
    _crossfadeInFlight = false;
    if (_usingPlaylist) {
      if (isApplePlatform) {
        // Apple platforms (iOS, macOS): single-source mode. Update index then reload.
        final prevIndex = state.currentIndex - 1;
        _hasLoadedSource = false;
        _macosLastPositionMs = null;
        _lastRealDurationFetchedForSongId = null;
        _silentRefreshTriggeredForSongId = null;
        _transitionGeneration++;
        _isTransitioning = false;
        state = state.copyWith(
          currentIndex: prevIndex,
          currentSong: state.queue[prevIndex],
          status: PlayerStatus.loading,
        );
        await _syncPlaylistToQueue(shouldPlay: true);
        return;
      }
      
      // Universal cache-aware logic for all platforms
      final prevIndex = state.currentIndex - 1;
      if (prevIndex >= 0 && prevIndex < _loadedPlaylistLength) {
        final prevSong = state.queue[prevIndex];
        
        // Check if we have SIGNIFICANT cache that would provide clear benefit
        // Only rebuild if we have substantial cached data AND the current source is a stream
        // (i.e., we're upgrading from stream to cached file, not just rebuilding for no reason)
        final cacheInfo = await _audioRepository.getCacheInfo(prevSong.id);
        final hasSubstantialCache = cacheInfo.exists && cacheInfo.filePath != null && 
                                   (cacheInfo.isComplete || cacheInfo.cachedBytes >= (5 * 1024 * 1024)); // 5MB+ or complete
        
        // Additional check: only rebuild if we're confident the current source is a stream
        // This prevents unnecessary rebuilds when cache might not provide clear benefit
        var shouldRebuild = hasSubstantialCache;
        
        if (hasSubstantialCache) {
          // Check if the current playlist source is likely a stream (not already a file)
          // If we're in the first few songs and cache was recently added, it's likely upgrading
          final isLikelyUpgrading = prevIndex < 5 && cacheInfo.cachedBytes > (3 * 1024 * 1024); // 3MB+ in first 5 songs
          shouldRebuild = isLikelyUpgrading;
          
          logDebug('Player: playPrevious cache analysis for ${prevSong.id}: '
              'substantial=$hasSubstantialCache, likelyUpgrading=$isLikelyUpgrading, '
              'cachedBytes=${cacheInfo.cachedBytes}',
              tag: 'Player');
        }
        
        if (shouldRebuild) {
          logDebug('Player: playPrevious rebuilding playlist to use cached file for ${prevSong.id}', tag: 'Player');
          
          // Update state immediately to prevent UI glitch
          final oldState = state;
          state = state.copyWith(
            currentIndex: prevIndex,
            currentSong: prevSong,
            status: PlayerStatus.loading,
          );
          
          try {
            // Force playlist rebuild to use cached file instead of original stream
            _transitionGeneration++;
            _isTransitioning = false;
            _hasLoadedSource = false; // Force full re-resolution
            
            await _syncPlaylistToQueue(shouldPlay: true);
            return;
          } catch (e) {
            // Fallback to normal transition if rebuild fails
            logWarning('Player: Cache rebuild failed, using normal transition: $e', tag: 'Player');
            state = oldState.copyWith(currentIndex: prevIndex, currentSong: prevSong);
            await _audioPlayer.setPlaylistIndex(prevIndex);
            await _audioPlayer.play();
            state = state.copyWith(status: PlayerStatus.playing);
            return;
          }
        }
        
        // No substantial cache or not worth rebuilding, use normal instant playlist transition
        logDebug('Player: playPrevious using normal instant transition for ${prevSong.id}', tag: 'Player');
        state = state.copyWith(
          currentIndex: prevIndex,
          currentSong: prevSong,
        );
        await _audioPlayer.setPlaylistIndex(prevIndex);
        await _audioPlayer.play();
        return;
      }
      
      await _audioPlayer.setPlaylistIndex(state.currentIndex - 1);
      await _audioPlayer.play();
      return;
    }
    await _syncPlaylistToQueue(shouldPlay: true);
    await _audioPlayer.setPlaylistIndex(state.currentIndex - 1);
    await _audioPlayer.play();
  }

  Future<void> _prefetchUpcoming(int fromIndex) async {
    final queue = state.queue;
    if (queue.isEmpty) return;

    const limit = 5;
    final upcomingSongs = <Song>[];
    for (var i = fromIndex + 1;
        i < queue.length && upcomingSongs.length < limit;
        i++) {
      upcomingSongs.add(queue[i]);
    }
    if (upcomingSongs.isEmpty) return;

    try {
      // Cache metadata for all upcoming songs
      await ref
          .read(downloadServiceProvider)
          .cacheSongMetadataBatch(upcomingSongs);

      // Check which songs are not yet cached and need audio downloading
      for (final song in upcomingSongs) {
        try {
          final cacheInfo = await _audioRepository.getCacheInfo(song.id);
          if (!cacheInfo.exists || !cacheInfo.isComplete) {
            final streamData = await _streamManager.getStreamUrl(song.id);
            final url = streamData['stream_url'] as String;
            final headers = streamData['headers'] as Map<String, String>?;
            _audioRepository.startBackgroundCacheDownload(
                song.id, url, headers);
          }
        } catch (e) {
          logWarning(
              'Player: _prefetchUpcoming cache warm failed for ${song.id}: $e',
              tag: 'Player');
        }
      }
    } catch (e) {
      logWarning('Player: _prefetchUpcoming failed: $e', tag: 'Player');
    }
  }

  /// Phase 1 of the crossfade pipeline: resolves the next song's audio source
  /// and pre-buffers it on a secondary player so ExoPlayer reaches STATE_READY
  /// before the fade window opens.
  ///
  /// Called ~([crossfadeSecs] + 10) s before the end of the current track.
  /// [CrossfadeEngine.beginCrossfade] detects the already-loaded secondary via
  /// [CrossfadeEngine.hasPreloadedSecondary] and reuses it, skipping the
  /// ExoPlayer init wait and making Song B audible from the first ramp tick.
  Future<void> _preloadCrossfadeSecondary(int nextIndex) async {
    if (nextIndex >= state.queue.length) return;
    final nextSong = state.queue[nextIndex];
    logDebug('Crossfade: preload → "${nextSong.title}" idx=$nextIndex',
        tag: 'Crossfade');
    try {
      final source =
          await _audioRepository.resolveToAudioSourceForCrossfade(nextSong);
      if (_disposed) return;
      if (state.crossfadeDurationSeconds == 0) return;
      if (_crossfadePreloadedForIndex != nextIndex) return;
      await _audioPlayer.preloadSecondary(
        source: source,
        normalizationEnabled: state.isNormalizationEnabled,
      );
    } catch (e) {
      logWarning('Crossfade: _preloadCrossfadeSecondary failed — $e',
          tag: 'Crossfade');
      _crossfadePreloadedForIndex = -1;
    }
  }

  /// Phase 2 of the crossfade pipeline: starts the simultaneous volume ramp.
  ///
  /// Called from the position stream listener when [crossfadeSecs] remain in
  /// the current track. If [CrossfadeEngine.hasPreloadedSecondary] is true the
  /// source URL resolve is skipped (already done in [_preloadCrossfadeSecondary])
  /// and the preloaded secondary is reused directly. Otherwise the source is
  /// resolved fresh and passed to [CrossfadeEngine.beginCrossfade] for
  /// fire-and-forget loading.
  ///
  /// [_crossfadeInFlight] is set synchronously at entry to block
  /// [_handleCompletion] during the async resolve window.
  Future<void> _beginTrueCrossfade(int nextIndex, int crossfadeSecs) async {
    if (nextIndex >= state.queue.length) return;
    final nextSong = state.queue[nextIndex];

    // Set synchronously so the processingState=completed handler doesn't call
    // _handleCompletion while we await the optional source URL fetch below.
    _crossfadeInFlight = true;

    logDebug(
      'Crossfade: begin → "${nextSong.title}" idx=$nextIndex secs=$crossfadeSecs',
      tag: 'Crossfade',
    );

    try {
      // Skip URL resolution when a secondary is already preloaded — the source
      // was resolved during _preloadCrossfadeSecondary. For streamed content this
      // avoids a redundant ~1 s API round-trip; beginCrossfade passes null source
      // and reuses the preloaded secondary directly.
      final ja.AudioSource? source = _audioPlayer.hasPreloadedSecondary
          ? null
          : await _audioRepository.resolveToAudioSourceForCrossfade(nextSong);

      if (_disposed) {
        _crossfadeInFlight = false;
        return;
      }
      // Bail if the user disabled crossfade, seeked, or changed song while the
      // optional source URL was being resolved.
      if (state.crossfadeDurationSeconds == 0) {
        _crossfadeInFlight = false;
        return;
      }
      if (_crossfadePreparedForIndex != nextIndex) {
        _crossfadeInFlight = false;
        return;
      }

      // Allow normalization gain to be fetched for the next song so it can be
      // applied to the secondary mid-ramp for a smooth loudness transition.
      _lastNormalizationGainFetchedForSongId = null;
      _maybeFetchAndApplyNormalizationGain(nextSong);

      final started = await _audioPlayer.beginCrossfade(
        source: source,
        crossfadeSecs: crossfadeSecs,
        normalizationEnabled: state.isNormalizationEnabled,
        onSwapComplete: () => _onCrossfadeSwapComplete(nextSong, nextIndex),
        // Invoked asynchronously if the secondary fails to load/play after the
        // ramp timer has already started (fire-and-forget load path).
        onSecondaryLoadFailed: () {
          logWarning(
            'Crossfade: secondary load failed mid-ramp — falling back',
            tag: 'Crossfade',
          );
          _resetCrossfadeIndices();
          // Primary may have completed while blocked by isCrossfading guard.
          if (_primaryHasReachedEnd()) _handleCompletion();
        },
      );

      // beginCrossfade owns the isCrossfading flag on success; on failure the
      // flag was never set. Either way the in-flight lock is no longer needed.
      _crossfadeInFlight = false;

      if (!started) {
        logWarning('Crossfade: beginCrossfade returned false — falling back',
            tag: 'Crossfade');
        _resetCrossfadeIndices();
        // Primary may have completed while blocked by _crossfadeInFlight.
        if (_primaryHasReachedEnd()) _handleCompletion();
      }
    } catch (e) {
      _crossfadeInFlight = false;
      logWarning('Crossfade: _beginTrueCrossfade failed — $e',
          tag: 'Crossfade');
      _resetCrossfadeIndices();
    }
  }

  /// Resets both crossfade index guards atomically.
  ///
  /// Always called together — splitting them risks one guard being stale while
  /// the other has already been cleared, opening a window for duplicate starts.
  void _resetCrossfadeIndices() {
    _crossfadePreparedForIndex = -1;
    _crossfadePreloadedForIndex = -1;
  }

  /// Returns `true` when the primary player's position has reached or passed
  /// the end of the track (within 800 ms to absorb platform clock jitter).
  ///
  /// Used as a fallback check after a crossfade failure or cancellation: if the
  /// primary already finished while [_crossfadeInFlight] or [isCrossfading]
  /// were blocking [_handleCompletion], we call it explicitly here.
  bool _primaryHasReachedEnd() {
    final pos = _audioPlayer.position;
    final dur = _audioPlayer.duration ?? state.duration;
    return dur != null &&
        dur.inMilliseconds > 0 &&
        pos.inMilliseconds >= dur.inMilliseconds - 800;
  }

  /// Invoked by [CrossfadeEngine] once the swap is complete.
  ///
  /// Updates all [PlayerNotifier] state to reflect the newly active song and
  /// resets crossfade / gapless tracking so the next transition starts clean.
  void _onCrossfadeSwapComplete(Song nextSong, int nextIndex) {
    if (_disposed) return;

    logDebug(
      'Crossfade: swap complete → "${nextSong.title}" idx=$nextIndex',
      tag: 'Crossfade',
    );

    _resetCrossfadeIndices();
    // The new primary was loaded as a single AudioSource (not a ConcatenatingAudioSource),
    // so the playlist tracking flags need to be reset to reflect this.
    _usingPlaylist = false;
    _hasLoadedSource = true;
    _loadedPlaylistLength = 1;
    _didPreExtend = false;
    _isTransitioning = false;
    // New song — clear the macOS real-duration lock so it gets re-fetched.
    _macosLastPositionMs = null;
    _lastRealDurationFetchedForSongId = null;
    _silentRefreshTriggeredForSongId = null;

    state = state.copyWith(
      currentIndex: nextIndex,
      currentSong: nextSong,
      // Never seed duration from song.duration (the 3:00 placeholder).
      // durationStream (Android/iOS) and _maybeFetchRealDurationOnMacOS (macOS)
      // will set the correct value once available.
      clearDuration: true,
      status: PlayerStatus.playing,
      clearError: true,
    );

    _syncMediaNotification(nextSong);
    ref.read(homeProvider.notifier).addToRecentlyPlayed(nextSong);
    unawaited(_persistPlaybackState());
    unawaited(_prefetchUpcoming(nextIndex));
    unawaited(_initializePlaybackTracking(nextSong.id));
    // Normalization for the new primary. If already fetched during the ramp,
    // _maybeFetchAndApplyNormalizationGain returns early (deduplicated).
    _maybeFetchAndApplyNormalizationGain(nextSong);
    _maybeFetchRealDurationOnMacOS(nextSong);
    // Restart the position sync timer so it reads from the new primary player.
    _startPositionSyncTimer();
  }

  void toggleShuffle() {
    final currentSong = state.currentSong;

    if (!state.isShuffleEnabled) {
      _originalQueue = List<Song>.from(state.queue);
      final shuffled = List<Song>.from(state.queue);

      if (currentSong != null) {
        shuffled.removeWhere((s) => s.id == currentSong.id);
        shuffled.shuffle();
        shuffled.insert(0, currentSong);
      } else {
        shuffled.shuffle();
      }

      state = state.copyWith(
        isShuffleEnabled: true,
        queue: shuffled,
        currentIndex: 0,
      );
      _applyQueueInvariant();
    } else {
      final restored = _originalQueue.isNotEmpty
          ? List<Song>.from(_originalQueue)
          : state.queue;
      final newIndex = currentSong != null
          ? restored.indexWhere((s) => s.id == currentSong.id)
          : 0;

      state = state.copyWith(
        isShuffleEnabled: false,
        queue: restored,
        currentIndex: newIndex >= 0 ? newIndex : 0,
      );
      _originalQueue = [];
      _applyQueueInvariant();
    }
  }

  void cycleRepeatMode() {
    final nextMode = PlayerRepeatMode
        .values[(state.repeatMode.index + 1) % PlayerRepeatMode.values.length];
    state = state.copyWith(repeatMode: nextMode);
    _audioPlayer.setLoopMode(_toLoopMode(nextMode));
  }

  void setVolume(double volume) {
    _audioPlayer.setVolume(volume);
    state = state.copyWith(volume: volume);
  }

  Future<void> _restoreNormalization() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      var enabled =
          prefs.getBool(StorageKeys.prefsVolumeNormalization) ?? false;
      logInfo(
        'Player: restoreNormalization prefEnabled=$enabled',
        tag: 'Player',
      );
      final settings =
          await ref.read(databaseRepositoryProvider).loadPlaybackSettings();
      if (settings.containsKey(PlaybackSettingKeys.volumeNormalization)) {
        enabled =
            settings[PlaybackSettingKeys.volumeNormalization] as bool? ?? false;
        await prefs.setBool(StorageKeys.prefsVolumeNormalization, enabled);
      }
      if (enabled) {
        await _audioPlayer.setNormalization(true);
        state = state.copyWith(isNormalizationEnabled: true);
      }
    } catch (e) {
      logWarning('Player: _restoreNormalization failed: $e', tag: 'Player');
    }
  }

  Future<void> _restorePlaybackSettings() async {
    try {
      final settings =
          await ref.read(databaseRepositoryProvider).loadPlaybackSettings();
      final gapless =
          settings[PlaybackSettingKeys.gaplessPlayback] as bool? ?? true;
      final crossfade =
          settings[PlaybackSettingKeys.crossfadeDurationSeconds] as int? ?? 0;
      state = state.copyWith(
        isGaplessEnabled: gapless,
        crossfadeDurationSeconds: crossfade,
      );
    } catch (e) {
      logWarning('Player: _restorePlaybackSettings failed: $e', tag: 'Player');
    }
  }

  Future<void> setGaplessPlayback(bool enabled) async {
    state = state.copyWith(isGaplessEnabled: enabled);
    try {
      await ref.read(databaseRepositoryProvider).savePlaybackSetting(
            PlaybackSettingKeys.gaplessPlayback,
            enabled,
          );
    } catch (e) {
      logWarning('Player: setGaplessPlayback persist failed: $e',
          tag: 'Player');
    }
  }

  Future<void> setCrossfadeDuration(int seconds) async {
    _audioPlayer.cancelCrossfade();
    _resetCrossfadeIndices();
    _crossfadeInFlight = false;
    state = state.copyWith(crossfadeDurationSeconds: seconds);
    try {
      await ref.read(databaseRepositoryProvider).savePlaybackSetting(
            PlaybackSettingKeys.crossfadeDurationSeconds,
            seconds,
          );
    } catch (e) {
      logWarning('Player: setCrossfadeDuration persist failed: $e',
          tag: 'Player');
    }
  }

  Future<void> setNormalization(bool enabled) async {
    await _audioPlayer.setNormalization(enabled);
    state = state.copyWith(isNormalizationEnabled: enabled);
    logInfo(
      'Player: setNormalization enabled=$enabled',
      tag: 'Player',
    );
    if (!enabled) {
      // Clear so toggling back on will re-fetch gain for the current track.
      _lastNormalizationGainFetchedForSongId = null;
    } else {
      // If user enables while a track is already playing, ensure we still
      // apply normalization gain for the current song.
      final song = state.currentSong;
      if (song != null) {
        _maybeFetchAndApplyNormalizationGain(song);
      }
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(StorageKeys.prefsVolumeNormalization, enabled);
      await ref.read(databaseRepositoryProvider).savePlaybackSetting(
          PlaybackSettingKeys.volumeNormalization, enabled);
    } catch (e) {
      logWarning('Player: setNormalization persist failed: $e', tag: 'Player');
    }
  }

  Future<List<Song>> searchSongs(String query) async {
    if (query.trim().isEmpty) return [];

    try {
      final tracks = await _streamManager.searchTracks(query);
      return tracks.map((t) => Song.fromTrack(t)).toList();
    } catch (e) {
      logWarning('Player: searchSongs failed: $e', tag: 'Player');
      return [];
    }
  }

  Future<void> _initializePlaybackTracking(String videoId) async {
    try {
      final session = await _playbackTracker!.initializePlayback(videoId);
      if (session != null) {
        _playbackTracker!.startTracking(videoId, session);
      }
    } catch (_) {
      // Tracking optional; ignore errors.
    }
  }

  Future<void> _cacheSongMetadata(Song song) async {
    try {
      await ref.read(downloadServiceProvider).cacheSongMetadata(song);
    } catch (_) {
      // Caching optional; ignore errors.
    }
  }

  void dispose() {
    _disposed = true;
    _stopPositionSyncTimer();
    _playbackRecoveryTimer?.cancel();
    _persistDebounceTimer?.cancel();

    _playRequestedAt = null;
    _playbackTracker?.dispose();
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
    _audioPlayer.dispose();
  }
}

/// Provides the [CrossfadeEngine] singleton.
/// Always overridden in [ProviderScope] via [main.dart].
final crossfadeEngineProvider = Provider<CrossfadeEngine>((ref) {
  throw StateError(
    'crossfadeEngineProvider must be overridden in ProviderScope (see main.dart)',
  );
});

final audioPlayerServiceProvider = Provider<AudioPlayerService>((ref) {
  final service = AudioPlayerService();
  ref.onDispose(() => service.dispose());
  return service;
});

class _AudioHandlerNotifier extends Notifier<TunifyAudioHandler?> {
  @override
  TunifyAudioHandler? build() => null;

  void setHandler(TunifyAudioHandler handler) => state = handler;
}

final audioHandlerProvider =
    NotifierProvider<_AudioHandlerNotifier, TunifyAudioHandler?>(
        _AudioHandlerNotifier.new);

final playerProvider =
    NotifierProvider<PlayerNotifier, PlayerState>(PlayerNotifier.new);

final streamManagerProvider = Provider<MusicStreamManager>((ref) {
  return MusicStreamManager(
    onVisitorDataReceived: (String? visitorData) async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(kYtVisitorDataKey, visitorData ?? '');
      if (visitorData != null && visitorData.isNotEmpty) {
        try {
          final apiKey = prefs.getString(StorageKeys.prefsYtApiKey);
          final clientVersion =
              prefs.getString(StorageKeys.prefsYtClientVersion);
          await ref.read(databaseRepositoryProvider).saveYtPersonalization({
            'visitor_data': visitorData,
            if (apiKey != null && apiKey.isNotEmpty) 'api_key': apiKey,
            if (clientVersion != null && clientVersion.isNotEmpty)
              'client_version': clientVersion,
          });
        } catch (e) {
          logWarning('StreamManager: onVisitorDataReceived save failed: $e',
              tag: 'StreamManager');
        }
      }
    },
  );
});

final streamCacheServiceProvider = Provider<StreamCacheService>((ref) {
  return StreamCacheService();
});

final audioRepositoryProvider = Provider<AudioRepository>((ref) {
  final streamManager = ref.watch(streamManagerProvider);
  final streamCache = ref.watch(streamCacheServiceProvider);
  return AudioRepository(
    streamManager: streamManager,
    streamCache: streamCache,
    getLocalPath: (songId) {
      try {
        final dlPath = ref.read(downloadServiceProvider).getLocalPath(songId);
        if (dlPath != null) return dlPath;
      } catch (e) {
        logWarning('AudioRepository: getLocalPath (downloads) failed: $e',
            tag: 'AudioRepository');
      }
      try {
        final deviceState = ref.read(deviceMusicProvider);
        if (deviceState.pathMap.isEmpty && !deviceState.isLoading) {
          ref.read(deviceMusicProvider.notifier).loadSongs();
        }
        return deviceState.pathMap[songId];
      } catch (e) {
        logWarning('AudioRepository: getLocalPath (device) failed: $e',
            tag: 'AudioRepository');
        return null;
      }
    },
  );
});

final currentSongProvider = Provider<Song?>((ref) {
  return ref.watch(playerProvider).currentSong;
});

final isPlayingProvider = Provider<bool>((ref) {
  return ref.watch(playerProvider).isPlaying;
});
