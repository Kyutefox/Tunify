import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart';

import 'package:tunify_database/tunify_database.dart';

import 'package:tunify/data/models/song.dart';
import 'package:tunify_logger/tunify_logger.dart';
import 'package:tunify/features/settings/music_stream_manager.dart';
import 'package:tunify/features/settings/stream_cache_service.dart';

/// Lifecycle state of a single download operation.
enum DownloadStatus {
  queued,
  downloading,
  completed,
  failed,
}

/// A single entry in the download queue, tracking progress and error state.
class DownloadEntry {
  final Song song;
  final DownloadStatus status;
  final String? errorMessage;
  final int? expectedBytes;
  final int? downloadedBytes;
  final double? speedBytesPerSecond;

  const DownloadEntry({
    required this.song,
    required this.status,
    this.errorMessage,
    this.expectedBytes,
    this.downloadedBytes,
    this.speedBytesPerSecond,
  });

  DownloadEntry copyWith({
    Song? song,
    DownloadStatus? status,
    String? errorMessage,
    int? expectedBytes,
    int? downloadedBytes,
    double? speedBytesPerSecond,
  }) {
    return DownloadEntry(
      song: song ?? this.song,
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
      expectedBytes: expectedBytes ?? this.expectedBytes,
      downloadedBytes: downloadedBytes ?? this.downloadedBytes,
      speedBytesPerSecond: speedBytesPerSecond ?? this.speedBytesPerSecond,
    );
  }
}

/// Manages a persistent download queue with a concurrency cap of [maxConcurrent] simultaneous downloads.
///
/// Stream URLs are resolved via [MusicStreamManager]; downloaded files are saved to
/// [DownloadStore] and their IDs propagated via [onDownloadedIdsChanged].
/// Progress is emitted via [ChangeNotifier] and throttled to avoid excessive rebuilds.
class DownloadService extends ChangeNotifier {
  /// Maximum number of songs downloading simultaneously.
  static const int maxConcurrent = 2;

  DownloadService({
    MusicStreamManager? streamManager,
    StreamCacheService? streamCache,
    void Function(List<String> ids)? onDownloadedIdsChanged,
  })  : _streamManager = streamManager ?? MusicStreamManager(),
        _streamCache = streamCache ?? StreamCacheService(),
        _onDownloadedIdsChanged = onDownloadedIdsChanged {
    _loadDownloaded();
  }

  final DownloadStore _store = DownloadStore();
  final MusicStreamManager _streamManager;
  final StreamCacheService _streamCache;
  final void Function(List<String> ids)? _onDownloadedIdsChanged;

  void _notifyDownloadedIdsChanged() {
    final ids = _downloadedSongs.map((s) => s.id).toList();
    _onDownloadedIdsChanged?.call(ids);
  }

  final List<DownloadEntry> _queue = [];
  final Set<String> _activeIds = {};
  final Set<String> _cancelledIds = {};
  final Map<String, String> _pathBySongId = {};
  final Map<String, int> _lastProgressBytes = {};
  final Map<String, DateTime> _lastProgressTime = {};
  bool _loaded = false;

  List<DownloadEntry> get queue => List.unmodifiable(_queue);
  Set<String> get activeIds => Set.unmodifiable(_activeIds);
  bool get isLoaded => _loaded;

  Set<String> _downloadedIds = {};
  Set<String> get downloadedIds => Set.unmodifiable(_downloadedIds);

  List<Song> _downloadedSongs = [];
  List<Song> get downloadedSongs => List.unmodifiable(_downloadedSongs);

  Future<void> _loadDownloaded() async {
    try {
      final maps = await _store.getDownloadedSongs();
      _downloadedSongs = maps
          .map(_safeSongFromStoredJson)
          .whereType<Song>()
          .toList(growable: false);
      _downloadedIds = _downloadedSongs.map((s) => s.id).toSet();
      for (final s in _downloadedSongs) {
        final path = await _store.getPath(s.id);
        if (path != null) _pathBySongId[s.id] = path;
      }
      _loaded = true;
      notifyListeners();
    } catch (e) {
      logError('failed to load downloaded: $e', tag: 'DownloadService');
      _loaded = true;
      notifyListeners();
    }
  }

  Song? _safeSongFromStoredJson(Map<String, dynamic> json) {
    final normalized = Map<String, dynamic>.from(json);
    for (final key in const ['id', 'title', 'artist', 'thumbnailUrl']) {
      final value = normalized[key];
      if (value == null) {
        normalized[key] = '';
      } else if (value is! String) {
        normalized[key] = value.toString();
      }
    }
    final durationValue = normalized['durationMs'];
    if (durationValue is! int) {
      if (durationValue is num) {
        normalized['durationMs'] = durationValue.toInt();
      } else {
        normalized['durationMs'] = 0;
      }
    }
    try {
      final song = Song.fromJson(normalized);
      // Corrupt records without an ID cannot be tracked reliably.
      if (song.id.trim().isEmpty) return null;
      return song;
    } catch (e) {
      logWarning('DownloadService: skipping invalid stored song metadata: $e',
          tag: 'DownloadService');
      return null;
    }
  }

  bool isDownloaded(String songId) => _downloadedIds.contains(songId);

  String? getLocalPath(String songId) => _pathBySongId[songId];

  void enqueue(Song song) {
    if (_downloadedIds.contains(song.id)) return;
    if (_queue.any((e) => e.song.id == song.id)) return;
    if (_activeIds.contains(song.id)) return;

    _queue.add(DownloadEntry(song: song, status: DownloadStatus.queued));
    notifyListeners();
    _processQueue();
  }

  void enqueueAll(Iterable<Song> songs) {
    int added = 0;
    for (final song in songs) {
      if (_downloadedIds.contains(song.id)) continue;
      if (_queue.any((e) => e.song.id == song.id)) continue;
      if (_activeIds.contains(song.id)) continue;
      _queue.add(DownloadEntry(song: song, status: DownloadStatus.queued));
      added++;
    }
    if (added > 0) {
      notifyListeners();
      _processQueue();
    }
  }

  void cancelDownload(String songId) {
    final i = _queue.indexWhere((e) => e.song.id == songId);
    if (i < 0) return;
    final wasDownloading = _activeIds.contains(songId);
    _queue.removeAt(i);
    _lastProgressBytes.remove(songId);
    _lastProgressTime.remove(songId);
    if (wasDownloading) _cancelledIds.add(songId);
    notifyListeners();
  }

  Future<void> _processQueue() async {
    while (_activeIds.length < maxConcurrent && _queue.isNotEmpty) {
      final index = _queue.indexWhere((e) => e.status == DownloadStatus.queued);
      if (index < 0) break;

      final entry = _queue[index];
      if (_downloadedIds.contains(entry.song.id)) {
        _queue.removeAt(index);
        notifyListeners();
        continue;
      }

      _activeIds.add(entry.song.id);
      _queue[index] =
          DownloadEntry(song: entry.song, status: DownloadStatus.downloading);
      notifyListeners();

      _downloadOne(entry.song).then((_) {
        _activeIds.remove(entry.song.id);
        final i = _queue.indexWhere((e) => e.song.id == entry.song.id);
        if (i >= 0) _queue.removeAt(i);
        _processQueue();
        notifyListeners();
      }).catchError((Object e, StackTrace st) {
        logError('Download error in queue processing: $e\n$st',
            tag: 'DownloadService');
        _activeIds.remove(entry.song.id);
        notifyListeners();
      });
    }
  }

  static const int _progressNotifyEveryBytes = 262144;

  /// Progress notification is throttled to this interval to reduce widget rebuilds.
  static const int _progressNotifyEveryMs = 500;
  static const int _writeBufferSize = 262144;

  void _updateEntryProgress(
      String songId, int? expectedBytes, int downloadedBytes) {
    final i = _queue.indexWhere((e) => e.song.id == songId);
    if (i < 0) return;
    final e = _queue[i];
    double? speed;
    final now = DateTime.now();
    final lastBytes = _lastProgressBytes[songId];
    final lastTime = _lastProgressTime[songId];
    if (lastTime != null &&
        lastBytes != null &&
        now.difference(lastTime).inMilliseconds > 0) {
      final sec = now.difference(lastTime).inMilliseconds / 1000.0;
      if (sec > 0) speed = (downloadedBytes - lastBytes) / sec;
    }
    _lastProgressBytes[songId] = downloadedBytes;
    _lastProgressTime[songId] = now;
    _queue[i] = e.copyWith(
      expectedBytes: expectedBytes ?? e.expectedBytes,
      downloadedBytes: downloadedBytes,
      speedBytesPerSecond: speed,
    );
    notifyListeners();
  }

  Future<void> _downloadOne(Song song) async {
    try {
      final streamData = await _streamManager.getStreamUrl(song.id);
      final streamUrl = streamData['stream_url'] as String?;
      final headers = streamData['headers'] as Map<String, String>? ?? {};

      if (streamUrl == null || streamUrl.isEmpty) {
        throw Exception('No stream URL');
      }

      final dirPath = await DownloadStore.downloadDirectory;
      final dir = Directory(dirPath);
      if (!await dir.exists()) await dir.create(recursive: true);

      final ext = streamUrl.contains('m4a') ? 'm4a' : 'webm';
      final path = join(dirPath, '${song.id}.$ext');

      // Check if song has cached data - optimize download if available
      final cacheInfo = await _streamCache.getCacheInfo(song.id);

      if (cacheInfo.exists && cacheInfo.filePath != null) {
        log('DownloadService: ${song.id} has cached data (${cacheInfo.cachedBytes} bytes), optimizing download',
            tag: 'DownloadService');
        await _downloadWithCache(song, cacheInfo, streamUrl, headers, path);
      } else {
        await _downloadFull(song, streamUrl, headers, path);
      }

      // Check cancellation after download
      if (_cancelledIds.contains(song.id)) {
        try {
          await File(path).delete();
        } catch (e) {
          logWarning('DownloadService: delete cancelled file failed: $e',
              tag: 'DownloadService');
        }
        _activeIds.remove(song.id);
        _cancelledIds.remove(song.id);
        _lastProgressBytes.remove(song.id);
        _lastProgressTime.remove(song.id);
        return;
      }

      final songJson = song.toJson();
      if ((songJson['durationMs'] as int? ?? 0) == 0) {
        final streamDurationMs = streamData['durationMs'] as int? ?? 0;
        if (streamDurationMs > 0) songJson['durationMs'] = streamDurationMs;
      }
      await _store.saveDownload(song.id, path, songJson);
      _downloadedIds.add(song.id);
      _pathBySongId[song.id] = path;
      _downloadedSongs.insert(0, song);
      _notifyDownloadedIdsChanged();
      notifyListeners();
    } catch (e, st) {
      // Check if this was a cancellation
      if (e.toString().contains('Download cancelled')) {
        log('DownloadService: ${song.id} download was cancelled',
            tag: 'DownloadService');
        // Don't mark as failed - just clean up and don't add to downloads
        _activeIds.remove(song.id);
        _lastProgressBytes.remove(song.id);
        _lastProgressTime.remove(song.id);
        return;
      }
      logError('download failed ${song.id}: $e\n$st', tag: 'DownloadService');
      _lastError = e.toString();
      final i = _queue.indexWhere((entry) => entry.song.id == song.id);
      if (i >= 0) {
        _queue[i] = DownloadEntry(
          song: song,
          status: DownloadStatus.failed,
          errorMessage: e.toString(),
        );
      }
      notifyListeners();
    }
  }

  /// Downloads a song that has cached data - copies existing cache and downloads missing chunks.
  Future<void> _downloadWithCache(
    Song song,
    CacheInfo cacheInfo,
    String streamUrl,
    Map<String, String> headers,
    String targetPath,
  ) async {
    final cachedFile = File(cacheInfo.filePath!);

    // Check if cache file exists and has data
    if (!await cachedFile.exists()) {
      log('DownloadService: ${song.id} cache file does not exist, doing full download',
          tag: 'DownloadService');
      await _downloadFull(song, streamUrl, headers, targetPath);
      return;
    }

    final fileSize = await cachedFile.length();
    if (fileSize == 0) {
      log('DownloadService: ${song.id} cache file is empty, doing full download',
          tag: 'DownloadService');
      await _downloadFull(song, streamUrl, headers, targetPath);
      return;
    }

    // Check if we have totalBytes to determine if cache is complete
    // If totalBytes is null or 0, we can't verify completeness, so complete the download
    if (cacheInfo.totalBytes == null || cacheInfo.totalBytes == 0) {
      log('DownloadService: ${song.id} cache has no totalBytes info ($fileSize bytes), completing download',
          tag: 'DownloadService');
      await _completeCacheAndCopy(
          song, cacheInfo, streamUrl, headers, targetPath, cachedFile);
      return;
    }

    // If cached bytes equals total bytes, cache is complete - just copy
    if (cacheInfo.cachedBytes >= cacheInfo.totalBytes!) {
      log('DownloadService: ${song.id} cache is complete (${cacheInfo.cachedBytes} bytes), copying file',
          tag: 'DownloadService');
      _updateEntryProgress(song.id, cacheInfo.totalBytes, 0);
      await cachedFile.copy(targetPath);
      _updateEntryProgress(
          song.id, cacheInfo.totalBytes, cacheInfo.totalBytes!);
      return;
    }

    // Cache is partial - download missing chunks
    log('DownloadService: ${song.id} cache is partial (${cacheInfo.cachedBytes} bytes of $cacheInfo.totalBytes bytes), downloading remaining',
        tag: 'DownloadService');
    await _completeCacheAndCopy(
        song, cacheInfo, streamUrl, headers, targetPath, cachedFile);
  }

  /// Completes partial cache by downloading missing chunks, then copies to downloads.
  Future<void> _completeCacheAndCopy(
    Song song,
    CacheInfo cacheInfo,
    String streamUrl,
    Map<String, String> headers,
    String targetPath,
    File cachedFile,
  ) async {
    // Download missing chunks
    await _streamCache.startIncrementalDownload(
      song.id,
      streamUrl,
      headers,
      fromByte: cacheInfo.cachedBytes,
      onProgress: (downloaded, total) {
        _updateEntryProgress(song.id, total, downloaded);
      },
    );

    // Copy the now-complete cached file to downloads
    await cachedFile.copy(targetPath);
    log('DownloadService: ${song.id} download completed and copied to downloads',
        tag: 'DownloadService');
  }

  /// Downloads a song from scratch (no cache available).
  Future<void> _downloadFull(
    Song song,
    String streamUrl,
    Map<String, String> headers,
    String path,
  ) async {
    final client = http.Client();
    try {
      final request = http.Request('GET', Uri.parse(streamUrl));
      if (headers.isNotEmpty) request.headers.addAll(headers);
      request.headers['Range'] = 'bytes=0-';
      final response = await client.send(request);
      if (response.statusCode != 200 && response.statusCode != 206) {
        throw Exception('HTTP ${response.statusCode}');
      }
      final contentLength = response.contentLength;
      _updateEntryProgress(song.id, contentLength, 0);

      final file = File(path);
      final sink = file.openWrite();
      int downloaded = 0;
      int lastNotifiedAt = 0;
      DateTime? lastNotifiedTime;
      final List<int> writeBuffer = [];
      void flushBuffer() {
        if (writeBuffer.isEmpty) return;
        sink.add(Uint8List.fromList(writeBuffer));
        writeBuffer.clear();
      }

      await for (final chunk in response.stream) {
        if (_cancelledIds.contains(song.id)) {
          flushBuffer();
          await sink.flush();
          await sink.close();
          try {
            await file.delete();
          } catch (e) {
            logWarning('DownloadService: delete cancelled file failed: $e',
                tag: 'DownloadService');
          }
          _activeIds.remove(song.id);
          _cancelledIds.remove(song.id);
          _lastProgressBytes.remove(song.id);
          _lastProgressTime.remove(song.id);
          // Throw exception to skip saving to database
          throw Exception('Download cancelled');
        }
        writeBuffer.addAll(chunk);
        downloaded += chunk.length;
        if (writeBuffer.length >= _writeBufferSize) flushBuffer();
        final now = DateTime.now();
        final timeOk = lastNotifiedTime == null ||
            now.difference(lastNotifiedTime).inMilliseconds >=
                _progressNotifyEveryMs;
        if (timeOk &&
            downloaded - lastNotifiedAt >= _progressNotifyEveryBytes) {
          lastNotifiedAt = downloaded;
          lastNotifiedTime = now;
          _updateEntryProgress(song.id, null, downloaded);
        }
      }
      flushBuffer();
      await sink.close();
      _updateEntryProgress(song.id, contentLength ?? downloaded, downloaded);
      log('DownloadService: ${song.id} full download completed',
          tag: 'DownloadService');
    } finally {
      client.close();
    }
  }

  String? _lastError;
  String? get lastError {
    final e = _lastError;
    _lastError = null;
    return e;
  }

  Future<void> reorderDownloaded(List<Song> newOrder) async {
    await _store.setDownloadOrder(newOrder.map((s) => s.id).toList());
    await _loadDownloaded();
    _notifyDownloadedIdsChanged();
  }

  Future<void> removeDownload(String songId) async {
    final path = _pathBySongId[songId];
    if (path != null) {
      try {
        final file = File(path);
        if (await file.exists()) await file.delete();
      } catch (e) {
        logWarning('DownloadService: removeDownload delete failed: $e',
            tag: 'DownloadService');
      }
    }
    await _store.removeDownload(songId);
    _downloadedIds.remove(songId);
    _pathBySongId.remove(songId);
    _downloadedSongs.removeWhere((s) => s.id == songId);
    _notifyDownloadedIdsChanged();
    notifyListeners();
  }

  Future<void> clearAllDownloads() async {
    for (final id in _activeIds) {
      _cancelledIds.add(id);
    }
    _queue.clear();
    _activeIds.clear();
    _lastProgressBytes.clear();
    _lastProgressTime.clear();
    notifyListeners();
    final paths = await _store.clearAll();
    for (final path in paths) {
      try {
        final file = File(path);
        if (await file.exists()) {
          await file.delete();
        }
      } catch (e) {
        logWarning('DownloadService: clearAll delete failed: $e',
            tag: 'DownloadService');
      }
    }
    _downloadedIds.clear();
    _pathBySongId.clear();
    _downloadedSongs = [];
    _notifyDownloadedIdsChanged();
    notifyListeners();
  }

  @override
  void dispose() {
    _store.close();
    super.dispose();
  }

  Future<void> cacheSongMetadata(Song song) async {
    await _store.cacheSongMetadata(song.id, song.toJson());
  }

  Future<void> cacheSongMetadataBatch(List<Song> songs) async {
    for (final song in songs) {
      await _store.cacheSongMetadata(song.id, song.toJson());
    }
  }

  Future<Map<String, dynamic>?> getCachedSongMetadata(String songId) async {
    return _store.getCachedSongMetadata(songId);
  }

  Future<Map<String, Map<String, dynamic>>> getCachedSongMetadataBatch(
      List<String> songIds) async {
    return _store.getCachedSongMetadataBatch(songIds);
  }
}
