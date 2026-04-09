import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:tunify_source_youtube_music/tunify_source_youtube_music.dart' as scrapper;
import 'package:tunify/data/models/audio_quality.dart';
import 'package:tunify/data/models/stream_quality.dart';
import 'package:tunify/features/music_backend/youtube_stream_fetch_isolate.dart';
import 'package:tunify_database/tunify_database.dart';
import 'package:tunify/core/utils/app_log.dart';
import 'package:tunify_music_ports/tunify_music_ports.dart';

/// YouTube stream URLs expire after ~6 hours. Cache entries use 5h30m TTL.
const Duration kYoutubeStreamUrlTtl = Duration(hours: 5, minutes: 30);
const int kMaxYoutubeStreamCacheEntries = 50;

class _CachedStream {
  _CachedStream(this.result) : expiresAt = DateTime.now().add(kYoutubeStreamUrlTtl);
  _CachedStream.withExpiry(this.result, this.expiresAt);

  final StreamResult result;
  final DateTime expiresAt;

  bool get isExpired => DateTime.now().isAfter(expiresAt);
}

/// LRU + Hive + SQLite on top of [scrapper.YoutubeMusicStreamBackend].
class CachingYoutubeMusicStreamBackend implements MusicStreamBackend {
  CachingYoutubeMusicStreamBackend({
    required DatabaseBridge? db,
    required ValueNotifier<StreamQuality> qualityNotifier,
  })  : _db = db,
        _qualityNotifier = qualityNotifier;

  final DatabaseBridge? _db;
  final ValueNotifier<StreamQuality> _qualityNotifier;

  final Map<String, _CachedStream> _streamCache = {};
  int _hits = 0;
  int _misses = 0;
  Box<dynamic>? _hiveBox;

  Map<String, int> get cacheStats => {'hits': _hits, 'misses': _misses};

  Future<void> init() async {
    await _restoreStreamUrlsFromHive();
  }

  Future<void> _restoreStreamUrlsFromHive() async {
    try {
      _hiveBox = await Hive.openBox<dynamic>('stream_urls');
      final box = _hiveBox!;
      final now = DateTime.now();
      final toDelete = <dynamic>[];
      for (final key in box.keys) {
        final entry = box.get(key);
        if (entry is! Map) continue;
        final expiresAtMs = entry['expiresAt'] as int?;
        if (expiresAtMs == null) {
          toDelete.add(key);
          continue;
        }
        final expiresAt = DateTime.fromMillisecondsSinceEpoch(expiresAtMs);
        if (now.isAfter(expiresAt)) {
          toDelete.add(key);
          continue;
        }
        final url = entry['url'] as String?;
        final bitrate = entry['bitrate'] as int? ?? 128;
        if (url == null || url.isEmpty) {
          toDelete.add(key);
          continue;
        }
        final audioQuality = bitrate >= 160
            ? AudioQuality.high
            : bitrate >= 80
                ? AudioQuality.medium
                : AudioQuality.low;
        final stream = AudioStream(
          url: url,
          bitrate: bitrate,
          quality: audioQuality,
          codec: 'opus',
          headers:
              Map<String, String>.from(scrapper.SharedHeaders.streamHeaders),
        );
        final result = StreamResult(
          trackId: key as String,
          highQuality: audioQuality == AudioQuality.high ? stream : null,
          mediumQuality: audioQuality == AudioQuality.medium ? stream : null,
          lowQuality: audioQuality == AudioQuality.low ? stream : null,
        );
        if (_streamCache.length < kMaxYoutubeStreamCacheEntries) {
          _streamCache[key] = _CachedStream.withExpiry(result, expiresAt);
        }
      }
      if (toDelete.isNotEmpty) await box.deleteAll(toDelete);
    } catch (e) {
      logWarning('CachingYoutubeMusicStreamBackend: restore Hive failed: $e',
          tag: 'PlayFlow');
    }
  }

  AudioQuality _audioQualityFromBitrate(int bitrate) {
    if (bitrate >= 160) return AudioQuality.high;
    if (bitrate >= 80) return AudioQuality.medium;
    return AudioQuality.low;
  }

  ResolvedStream _resolvedFromStreamResult(StreamResult result, String videoId) {
    final stream = result.best!;
    return ResolvedStream(
      url: stream.url,
      bitrate: stream.bitrate,
      qualityLabel: stream.quality.label,
      headers: stream.headers,
    );
  }

  @override
  Future<ResolvedStream> resolveStream(
    TrackRef ref,
    MusicStreamResolveContext ctx,
  ) async {
    if (ref.source != MusicSource.youtubeMusic) {
      throw ArgumentError.value(ref.source, 'ref.source', 'Expected youtubeMusic');
    }
    final videoId = ref.id;
    final apiSw = Stopwatch()..start();
    try {
      final cached = _streamCache[videoId];
      if (cached != null && !cached.isExpired) {
        _hits++;
        final stream = cached.result.best;
        if (stream != null) {
          _streamCache.remove(videoId);
          _streamCache[videoId] = cached;
          log(
            'PlayFlow: getStreamUrl CACHE HIT videoId=$videoId (${apiSw.elapsedMilliseconds}ms)',
            tag: 'PlayFlow',
          );
          return _resolvedFromStreamResult(cached.result, videoId);
        }
      } else if (cached != null) {
        _streamCache.remove(videoId);
      }
      _misses++;
      log(
        'PlayFlow: getStreamUrl CACHE MISS videoId=$videoId calling InnerTube player API',
        tag: 'PlayFlow',
      );

      final sqliteCached = await _db?.getStreamUrlCache(videoId);
      if (sqliteCached != null) {
        log('PlayFlow: getStreamUrl SQLITE HIT videoId=$videoId', tag: 'PlayFlow');
        final url = sqliteCached['url'] as String;
        final headers = sqliteCached['headers'] as Map<String, String>? ?? {};
        final bitrate = sqliteCached['bitrate'] as int? ?? 0;
        final qualityLabel = sqliteCached['quality'] as String? ?? '';
        final audioQuality = _audioQualityFromBitrate(bitrate);
        final stream = AudioStream(
          url: url,
          bitrate: bitrate,
          quality: audioQuality,
          codec: 'opus',
          headers:
              Map<String, String>.from(scrapper.SharedHeaders.streamHeaders),
        );
        final result = StreamResult(
          trackId: videoId,
          highQuality: audioQuality == AudioQuality.high ? stream : null,
          mediumQuality: audioQuality == AudioQuality.medium ? stream : null,
          lowQuality: audioQuality == AudioQuality.low ? stream : null,
        );
        if (_streamCache.length >= kMaxYoutubeStreamCacheEntries) {
          _streamCache.remove(_streamCache.keys.first);
        }
        _streamCache[videoId] = _CachedStream(result);
        return ResolvedStream(
          url: url,
          bitrate: bitrate,
          qualityLabel: qualityLabel.isNotEmpty ? qualityLabel : audioQuality.label,
          headers: headers,
        );
      }

      final fetchT0 = apiSw.elapsedMilliseconds;

      final ytStream = await fetchYoutubeMusicStreamInIsolate(
        YoutubeStreamIsolateParams(
          videoId: videoId,
          preferAac: ctx.preferAac,
          visitorData: ctx.visitorData,
        ),
      );

      log(
        'PlayFlow: getStreamUrl InnerTube player API done in ${apiSw.elapsedMilliseconds - fetchT0}ms',
        tag: 'PlayFlow',
      );
      if (ytStream == null) {
        throw MusicStreamResolveException('No audio stream available for $videoId');
      }

      final bitrate = ytStream.bitrate;
      final quality = _audioQualityFromBitrate(bitrate);
      _qualityNotifier.value = streamQualityFromAudioQuality(quality);

      final stream = AudioStream(
        url: ytStream.url,
        bitrate: bitrate,
        quality: quality,
        codec: 'opus',
        headers: Map<String, String>.from(ytStream.headers),
      );
      final result = StreamResult(
        trackId: videoId,
        highQuality: quality == AudioQuality.high ? stream : null,
        mediumQuality: quality == AudioQuality.medium ? stream : null,
        lowQuality: quality == AudioQuality.low ? stream : null,
      );
      if (_streamCache.length >= kMaxYoutubeStreamCacheEntries) {
        _streamCache.remove(_streamCache.keys.first);
      }
      _streamCache[videoId] = _CachedStream(result);

      final expiresAt = DateTime.now().toUtc().add(kYoutubeStreamUrlTtl);
      _hiveBox?.put(videoId, {
        'url': ytStream.url,
        'bitrate': bitrate,
        'quality': quality.label,
        'expiresAt': expiresAt.millisecondsSinceEpoch,
      }).ignore();

      final db = _db;
      if (db != null) {
        db
            .trimStreamUrlCacheIfNeeded()
            .then((_) => db.upsertStreamUrlCache(
                  videoId,
                  ytStream.url,
                  Map<String, String>.from(scrapper.SharedHeaders.streamHeaders),
                  bitrate,
                  quality.label,
                  expiresAt,
                ))
            .ignore();
      }

      log(
        'PlayFlow: getStreamUrl total (fetch+cache) ${apiSw.elapsedMilliseconds}ms',
        tag: 'PlayFlow',
      );
      log(
        'PlayFlow: getStreamUrl mimeType=${ytStream.mimeType} bitrate=${bitrate}kbps',
        tag: 'PlayFlow',
      );

      return ResolvedStream(
        url: ytStream.url,
        bitrate: bitrate,
        qualityLabel: quality.label,
        headers: Map<String, String>.from(scrapper.SharedHeaders.streamHeaders),
        durationMs: ytStream.durationMs,
        mimeType: ytStream.mimeType,
      );
    } catch (e) {
      log(
        'PlayFlow: getStreamUrl FAILED after ${apiSw.elapsedMilliseconds}ms',
        tag: 'PlayFlow',
      );
      rethrow;
    }
  }

  StreamResult? getCached(String videoId) {
    final entry = _streamCache[videoId];
    if (entry == null || entry.isExpired) return null;
    return entry.result;
  }

  bool isCached(String videoId) {
    final entry = _streamCache[videoId];
    return entry != null && !entry.isExpired;
  }

  void putCached(String videoId, StreamResult result) {
    if (_streamCache.length >= kMaxYoutubeStreamCacheEntries) {
      _streamCache.remove(_streamCache.keys.first);
    }
    _streamCache[videoId] = _CachedStream(result);
  }

  void clearCacheFor(String videoId) {
    _streamCache.remove(videoId);
    _db?.deleteStreamUrlCache(videoId).ignore();
    _hiveBox?.delete(videoId).ignore();
  }

  void clearAll() {
    _streamCache.clear();
    _db?.clearAllStreamUrlCache().ignore();
    _hiveBox?.clear().ignore();
  }
}
