import 'dart:io';

import 'package:just_audio/just_audio.dart';

import '../../models/song.dart';
import '../../shared/services/music_stream_manager.dart';
import '../../shared/services/audio/crossfade_engine.dart';
import 'package:tunify_logger/tunify_logger.dart';
import '../../shared/services/stream_cache_service.dart';

/// Indicates how a resolved audio source is backed.
enum AudioSourceKind {
  /// Audio file from the device's local music library.
  local,

  /// Audio file from the app's downloads directory.
  downloaded,

  /// Audio bytes previously cached to disk — 0 ms buffering on next play.
  streamCached,

  /// Live stream URL; playback starts immediately while bytes cache to disk in background.
  stream,
}

/// Resolved playable source: either a file path or a stream URL.
sealed class ResolvedAudioSource {
  const ResolvedAudioSource();

  AudioSourceKind get kind;

  /// Local file path (device, download, or stream cache file); null when streaming.
  String? get filePath => null;

  /// Optional quality info for UI; set when source was resolved from stream.
  ({int bitrate, String quality})? get qualityInfo => null;
}

/// Play from a local file path (device, download, or stream cache).
class ResolvedAudioSourceFile extends ResolvedAudioSource {
  ResolvedAudioSourceFile(
    this.path, {
    this.sourceKind = AudioSourceKind.downloaded,
    this.qualityInfo,
  }) : super();

  final String path;
  final AudioSourceKind sourceKind;
  @override
  final ({int bitrate, String quality})? qualityInfo;

  @override
  AudioSourceKind get kind => sourceKind;

  @override
  String? get filePath => path;
}

/// Play from URL immediately; cache is filled in background for next play (Spotify-style).
class ResolvedAudioSourceStream extends ResolvedAudioSource {
  ResolvedAudioSourceStream({
    required this.url,
    this.headers,
    this.qualityInfo,
  }) : super();

  final String url;
  final Map<String, String>? headers;
  @override
  final ({int bitrate, String quality})? qualityInfo;

  @override
  AudioSourceKind get kind => AudioSourceKind.stream;
}

/// Entry point for the player: resolves to a single type (file path) for all sources.
/// File from device, file from downloads, or file from stream cache (bytes saved to disk).
/// Player always receives path → 0ms when playing from cache; cache can be reused for downloads.
class AudioRepository {
  AudioRepository({
    required MusicStreamManager streamManager,
    required StreamCacheService streamCache,
    required String? Function(String songId) getLocalPath,
  })  : _streamManager = streamManager,
        _streamCache = streamCache,
        _getLocalPath = getLocalPath;

  final MusicStreamManager _streamManager;
  final StreamCacheService _streamCache;
  final String? Function(String songId) _getLocalPath;

  /// Resolves the playable source for [song].
  /// 1) Local/download path if present. 2) Stream cache file if present (0ms) — unless
  ///    [skipStreamCache] is true (used for playlist sources where seeking must work).
  /// 3) Else returns stream URL so playback can start immediately; cache fills in background.
  Future<ResolvedAudioSource> resolveSource(
    Song song, {
    bool skipStreamCache = false,
  }) async {
    final stepSw = Stopwatch()..start();
    final path = _getLocalPath(song.id);
    if (path != null && path.isNotEmpty) {
      log('PlayFlow: resolveSource getLocalPath -> file (${stepSw.elapsedMilliseconds}ms)',
          tag: 'PlayFlow');
      return ResolvedAudioSourceFile(path,
          sourceKind: AudioSourceKind.downloaded);
    }
    log('PlayFlow: resolveSource getLocalPath -> null (${stepSw.elapsedMilliseconds}ms)',
        tag: 'PlayFlow');

    if (!skipStreamCache) {
      final cachePath = await _streamCache.getCacheFilePath(song.id);
      if (cachePath != null) {
        log('PlayFlow: resolveSource stream cache HIT (${stepSw.elapsedMilliseconds}ms)',
            tag: 'PlayFlow');
        return ResolvedAudioSourceFile(cachePath,
            sourceKind: AudioSourceKind.streamCached);
      }
    } else {
      log('PlayFlow: resolveSource stream cache skipped (playlist seek safety)',
          tag: 'PlayFlow');
    }

    log('PlayFlow: resolveSource getStreamUrl (play from URL, cache in background)',
        tag: 'PlayFlow');
    final streamData = await _streamManager.getStreamUrl(song.id);
    final url = streamData['stream_url'] as String;
    final headers = streamData['headers'] as Map<String, String>?;
    final bitrate = streamData['bitrate'] as int? ?? 0;
    final quality = streamData['quality'] as String? ?? 'medium';
    log('PlayFlow: resolveSource getStreamUrl done in ${stepSw.elapsedMilliseconds}ms',
        tag: 'PlayFlow');
    return ResolvedAudioSourceStream(
      url: url,
      headers: headers,
      qualityInfo: (bitrate: bitrate, quality: quality),
    );
  }

  /// Starts downloading the stream to cache in the background. Call after starting playback from URL.
  /// Deduplicated per [songId]; safe to call multiple times for the same song.
  void startBackgroundCacheDownload(
      String songId, String url, Map<String, String>? headers) {
    _streamCache.downloadToCacheInBackground(songId, url, headers);
  }

  /// Applies [source] to [player]: file path or URL (playback starts as soon as buffer has data).
  Future<void> applySource(
    ResolvedAudioSource source,
    CrossfadeEngine player, {
    Duration? initialPosition,
  }) async {
    if (source is ResolvedAudioSourceFile && source.filePath != null) {
      await player.setFileSource(source.filePath!);
      if (initialPosition != null && initialPosition > Duration.zero) {
        await player.seek(initialPosition);
      }
      return;
    }
    if (source is ResolvedAudioSourceStream) {
      await player.playUrl(source.url,
          headers: source.headers, initialPosition: initialPosition);
    }
  }

  /// Whether the song has a stream cache file on disk (0ms next play).
  Future<bool> hasStreamCacheFile(String songId) =>
      _streamCache.getCacheFilePath(songId).then((p) => p != null);

  /// Clear stream cache file for [songId] (e.g. after playback error to force re-download).
  Future<void> clearStreamCacheFor(String songId) async {
    _streamManager.clearCacheFor(songId);
    await _streamCache.removeFromCache(songId);
  }

  /// Resolves [song] to a just_audio [AudioSource] for use in a playlist.
  /// Stream cache files are skipped so ExoPlayer always uses LockCachingAudioSource
  /// (HTTP), which handles seeks correctly. [AudioSource.file] on a partial stream
  /// cache file causes [FileDataSourceException] on seek → crash loop.
  /// Starts background cache download when the source is a stream.
  Future<AudioSource> resolveToAudioSource(Song song) async {
    final resolved = await resolveSource(song, skipStreamCache: true);
    if (resolved is ResolvedAudioSourceStream) {
      startBackgroundCacheDownload(song.id, resolved.url, resolved.headers);
    }
    return _toJustAudioSource(resolved);
  }

  /// Resolves [song] to an [AudioSource] suitable for the [CrossfadeEngine]
  /// secondary player.
  ///
  /// Only uses a file path for fully-downloaded local files (device or
  /// downloads directory). Stream cache files are intentionally skipped:
  /// they are filled in the background while the current song plays, so at the
  /// moment a crossfade begins the cache file is only partially written.
  /// Handing a partial file to ExoPlayer causes [ProcessingState.completed] to
  /// fire mid-crossfade (the player reads EOF prematurely), which breaks the
  /// swap and triggers spurious [_handleCompletion] calls.
  ///
  /// For streamed content, a plain [AudioSource.uri] is used instead of
  /// LockCachingAudioSource to avoid ExoPlayer SimpleCache lock conflicts
  /// between the primary and secondary players sharing the same URL. Background
  /// stream-to-disk caching is still initiated so subsequent plays are fast.
  Future<AudioSource> resolveToAudioSourceForCrossfade(Song song) async {
    // Only use a file path for fully-downloaded content (skipStreamCache=true
    // means we won't return a potentially-partial stream cache file).
    final resolved = await resolveSource(song, skipStreamCache: true);

    if (resolved is ResolvedAudioSourceFile) {
      return AudioSource.file(resolved.path);
    }

    final s = resolved as ResolvedAudioSourceStream;
    // Start background caching (deduplicated per songId).
    startBackgroundCacheDownload(song.id, s.url, s.headers);
    // Plain URI — no LockCachingAudioSource — avoids cache-file conflicts.
    return AudioSource.uri(Uri.parse(s.url));
  }

  static AudioSource _toJustAudioSource(ResolvedAudioSource r) {
    if (r is ResolvedAudioSourceFile) {
      return AudioSource.file(r.path);
    }
    final s = r as ResolvedAudioSourceStream;
    // On iOS, use a plain URI with no custom headers. AVURLAsset hangs when
    // Origin/Referer headers are set (iOS HTTP stack treats them as restricted).
    // YouTube m4a CDN URLs are signed and self-authenticating — no headers needed.
    return Platform.isIOS
        ? AudioSource.uri(Uri.parse(s.url))
        // ignore: experimental_member_use
        : LockCachingAudioSource(Uri.parse(s.url), headers: s.headers ?? {});
  }
}
