import 'dart:async';

import 'package:just_audio/just_audio.dart';
import 'package:tunify/data/models/song.dart';
import 'package:tunify/features/settings/music_stream_manager.dart';
import 'package:tunify/features/settings/stream_cache_service.dart';
import 'package:tunify/features/player/audio/crossfade_engine.dart';
import 'package:tunify/core/utils/app_log.dart';
import 'package:tunify_music_ports/tunify_music_ports.dart';

enum AudioSourceKind {
  local,
  downloaded,
  streamCached,
  stream,
}

sealed class ResolvedAudioSource {
  const ResolvedAudioSource();
  AudioSourceKind get kind;
  String? get filePath => null;
  ({int bitrate, String quality})? get qualityInfo => null;
}

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

class ResolvedAudioSourceStream extends ResolvedAudioSource {
  ResolvedAudioSourceStream({
    required this.url,
    this.headers,
    this.qualityInfo,
    this.transport = StreamTransport.http,
    this.localPath,
  }) : super();

  final String url;
  final Map<String, String>? headers;
  @override
  final ({int bitrate, String quality})? qualityInfo;
  final StreamTransport transport;
  final String? localPath;

  @override
  AudioSourceKind get kind => AudioSourceKind.stream;
}

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

  String _cacheKeyForSong(Song song) => '${MusicSource.youtubeMusic.name}:${song.id}';

  Future<ResolvedAudioSource> resolveSource(Song song) async {
    final stepSw = Stopwatch()..start();

    final path = _getLocalPath(song.id);
    if (path != null && path.isNotEmpty) {
      log('PlayFlow: resolveSource getLocalPath -> file (${stepSw.elapsedMilliseconds}ms)',
          tag: 'PlayFlow');
      return ResolvedAudioSourceFile(path,
          sourceKind: AudioSourceKind.downloaded);
    }

    final cacheInfo = await _streamCache.getCacheInfo(_cacheKeyForSong(song));
    if (cacheInfo.exists && cacheInfo.filePath != null) {
      final hasEnoughData =
          cacheInfo.cachedBytes >= (2 * 1024 * 1024) ||
              cacheInfo.progress >= 0.30;

      if (hasEnoughData || cacheInfo.isComplete) {
        log(
            'PlayFlow: resolveSource cache HIT (${stepSw.elapsedMilliseconds}ms) progress: ${(cacheInfo.progress * 100).toStringAsFixed(1)}% '
            '(${hasEnoughData ? 'sufficient' : 'complete'})',
            tag: 'PlayFlow');
        return ResolvedAudioSourceFile(
          cacheInfo.filePath!,
          sourceKind: AudioSourceKind.streamCached,
        );
      }
    }

    log('PlayFlow: resolveSource cache MISS, fetching stream URL (${stepSw.elapsedMilliseconds}ms)',
        tag: 'PlayFlow');
    final streamData = await _streamManager.getBestStreamForSong(song);
    final localPath = streamData['stream_local_path'] as String?;
    final transport = ((streamData['transport'] as String?) ?? 'http') == 'localFile'
        ? StreamTransport.localFile
        : StreamTransport.http;
    if (transport == StreamTransport.localFile &&
        localPath != null &&
        localPath.isNotEmpty) {
      return ResolvedAudioSourceFile(
        localPath,
        sourceKind: AudioSourceKind.streamCached,
        qualityInfo: (
          bitrate: streamData['bitrate'] as int? ?? 0,
          quality: streamData['quality'] as String? ?? 'lossless',
        ),
      );
    }
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
      transport: transport,
      localPath: localPath,
    );
  }

  Future<ResolvedAudioSource> resolveForPlayback(Song song) async {
    final stepSw = Stopwatch()..start();
    final path = _getLocalPath(song.id);
    if (path != null && path.isNotEmpty) {
      log('PlayFlow: resolveForPlayback getLocalPath -> file (${stepSw.elapsedMilliseconds}ms)',
          tag: 'PlayFlow');
      return ResolvedAudioSourceFile(path,
          sourceKind: AudioSourceKind.downloaded);
    }

    final cacheInfo = await _streamCache.getCacheInfo(_cacheKeyForSong(song));

    log(
        'PlayFlow: resolveForPlayback cache check: exists=${cacheInfo.exists} '
        'bytes=${cacheInfo.cachedBytes} total=${cacheInfo.totalBytes} '
        'progress=${(cacheInfo.progress * 100).toStringAsFixed(1)}% '
        'complete=${cacheInfo.isComplete}',
        tag: 'PlayFlow');

    if (cacheInfo.exists && cacheInfo.filePath != null) {
      final hasEnoughData =
          cacheInfo.cachedBytes >= (2 * 1024 * 1024) ||
              cacheInfo.progress >= 0.30;

      log(
          'PlayFlow: resolveForPlayback cache decision: hasEnoughData=$hasEnoughData '
          '(bytes>=2MB: ${cacheInfo.cachedBytes >= 2 * 1024 * 1024}, '
          'progress>=30%: ${cacheInfo.progress >= 0.30})',
          tag: 'PlayFlow');

      if (hasEnoughData || cacheInfo.isComplete) {
        log(
            'PlayFlow: resolveForPlayback cache HIT (${stepSw.elapsedMilliseconds}ms) '
            'cached: ${cacheInfo.cachedBytes} bytes progress: ${(cacheInfo.progress * 100).toStringAsFixed(1)}% '
            '(${hasEnoughData ? 'sufficient' : 'complete'})',
            tag: 'PlayFlow');
        return ResolvedAudioSourceFile(
          cacheInfo.filePath!,
          sourceKind: AudioSourceKind.streamCached,
        );
      }
    }

    log('PlayFlow: resolveForPlayback cache MISS/insufficient, fetching stream URL (${stepSw.elapsedMilliseconds}ms)',
        tag: 'PlayFlow');
    final streamData = await _streamManager.getBestStreamForSong(song);
    final localPath = streamData['stream_local_path'] as String?;
    final transport = ((streamData['transport'] as String?) ?? 'http') == 'localFile'
        ? StreamTransport.localFile
        : StreamTransport.http;
    if (transport == StreamTransport.localFile &&
        localPath != null &&
        localPath.isNotEmpty) {
      return ResolvedAudioSourceFile(
        localPath,
        sourceKind: AudioSourceKind.streamCached,
        qualityInfo: (
          bitrate: streamData['bitrate'] as int? ?? 0,
          quality: streamData['quality'] as String? ?? 'lossless',
        ),
      );
    }
    final url = streamData['stream_url'] as String;
    final headers = streamData['headers'] as Map<String, String>?;
    final bitrate = streamData['bitrate'] as int? ?? 0;
    final quality = streamData['quality'] as String? ?? 'medium';

    log('PlayFlow: resolveForPlayback getStreamUrl done in ${stepSw.elapsedMilliseconds}ms',
        tag: 'PlayFlow');
    return ResolvedAudioSourceStream(
      url: url,
      headers: headers,
      qualityInfo: (bitrate: bitrate, quality: quality),
      transport: transport,
      localPath: localPath,
    );
  }

  void startBackgroundCacheDownload(
      String songId, String url, Map<String, String>? headers) {
    _streamCache.downloadToCacheInBackground(
      '${MusicSource.youtubeMusic.name}:$songId',
      url,
      headers,
    );
  }

  Future<void> startIncrementalDownload(
    String songId,
    String url,
    Map<String, String>? headers, {
    int? fromByte,
  }) async {
    _streamCache.startIncrementalDownload(
        '${MusicSource.youtubeMusic.name}:$songId', url, headers,
        fromByte: fromByte);
  }

  Future<CacheInfo> getCacheInfo(String songId) async {
    return _streamCache.getCacheInfo('${MusicSource.youtubeMusic.name}:$songId');
  }

  Future<bool> isPositionCached(
      String songId, Duration position, Duration? totalDuration) async {
    return _streamCache.isPositionCached(
      '${MusicSource.youtubeMusic.name}:$songId',
      position,
      totalDuration,
    );
  }

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

  Future<bool> hasStreamCacheFile(String songId) =>
      _streamCache
          .getCacheFilePath('${MusicSource.youtubeMusic.name}:$songId')
          .then((p) => p != null);

  Future<void> clearStreamCacheFor(String songId) async {
    _streamManager.clearCacheFor(songId);
    await _streamCache.removeFromCache('${MusicSource.youtubeMusic.name}:$songId');
  }

  Future<AudioSource> resolveToAudioSource(Song song) async {
    final resolved = await resolveSource(song);
    return _toJustAudioSource(resolved);
  }

  Future<AudioSource> resolveToAudioSourceForCrossfade(Song song) async {
    final resolved = await resolveSource(song);

    if (resolved is ResolvedAudioSourceFile) {
      return AudioSource.file(resolved.path);
    }

    final s = resolved as ResolvedAudioSourceStream;
    if (s.transport == StreamTransport.http) {
      startBackgroundCacheDownload(song.id, s.url, s.headers);
    }
    return AudioSource.uri(Uri.parse(s.url));
  }

  static AudioSource _toJustAudioSource(ResolvedAudioSource r) {
    if (r is ResolvedAudioSourceFile) {
      return AudioSource.file(r.path);
    }
    final s = r as ResolvedAudioSourceStream;
    // Disable LockCachingAudioSource as it conflicts with our custom cache system
    // Use regular AudioSource.uri and let our cache handle the optimization
    return AudioSource.uri(Uri.parse(s.url), headers: s.headers);
  }

  AudioSource toAudioSource(ResolvedAudioSource r) => _toJustAudioSource(r);

  Future<void> prefetchSongs(List<Song> songs) async {
    for (final song in songs) {
      final cacheInfo = await _streamCache.getCacheInfo(_cacheKeyForSong(song));
      if (!cacheInfo.exists || !cacheInfo.isComplete) {
        try {
          final streamData = await _streamManager.getBestStreamForSong(song);
          final url = streamData['stream_url'] as String;
          final headers = streamData['headers'] as Map<String, String>?;
          startBackgroundCacheDownload(song.id, url, headers);
        } catch (e) {
          logWarning('AudioRepository: prefetch failed for ${song.id}: $e',
              tag: 'AudioRepository');
        }
      }
    }
  }
}
