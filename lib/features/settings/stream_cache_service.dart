import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:tunify/core/utils/platform_utils.dart';

import 'package:http/http.dart' as http;
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

import 'package:tunify_logger/tunify_logger.dart';

class CacheStats {
  final int totalBytes;
  final int fileCount;
  final int oldFilesCount;

  CacheStats({
    required this.totalBytes,
    required this.fileCount,
    required this.oldFilesCount,
  });

  String get formattedSize {
    if (totalBytes < 1024 * 1024) {
      return '${(totalBytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(totalBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

class CachedRange {
  final int start;
  final int end;
  CachedRange(this.start, this.end);

  int get length => end - start;
}

class CacheMetadata {
  final String songId;
  final int? totalBytes;
  final List<CachedRange> ranges;
  final DateTime lastModified;
  final bool isExplicitlyComplete;

  CacheMetadata({
    required this.songId,
    this.totalBytes,
    required this.ranges,
    required this.lastModified,
    this.isExplicitlyComplete = false,
  });

  bool get isComplete =>
      isExplicitlyComplete || (totalBytes != null && _isFullyCached());

  bool _isFullyCached() {
    if (ranges.isEmpty) return false;
    final sorted = List<CachedRange>.from(ranges)
      ..sort((a, b) => a.start.compareTo(b.start));
    int current = 0;
    for (final range in sorted) {
      if (range.start != current) return false;
      current = range.end;
    }
    return totalBytes != null && current >= totalBytes!;
  }

  bool isPositionCached(int bytePosition) {
    for (final range in ranges) {
      if (bytePosition >= range.start && bytePosition < range.end) {
        return true;
      }
    }
    return false;
  }

  int get cachedBytes {
    return ranges.fold(0, (sum, r) => sum + r.length);
  }

  Map<String, dynamic> toJson() => {
        'songId': songId,
        'totalBytes': totalBytes,
        'ranges': ranges.map((r) => {'start': r.start, 'end': r.end}).toList(),
        'lastModified': lastModified.toIso8601String(),
        'isExplicitlyComplete': isExplicitlyComplete,
      };

  factory CacheMetadata.fromJson(Map<String, dynamic> json) {
    return CacheMetadata(
      songId: json['songId'] as String,
      totalBytes: json['totalBytes'] as int?,
      ranges: (json['ranges'] as List?)
              ?.map((r) => CachedRange(r['start'] as int, r['end'] as int))
              .toList() ??
          [],
      lastModified: DateTime.parse(json['lastModified'] as String),
      isExplicitlyComplete: json['isExplicitlyComplete'] as bool? ?? false,
    );
  }
}

class StreamCacheService {
  static const String _dirName = 'stream_cache';
  static const String _metadataDir = 'cache_metadata';
  static const int _maxCacheSizeBytes = 500 * 1024 * 1024;
  static const int _cacheExpirationDays = 7;

  String? _cacheDirPath;
  String? _metadataDirPath;
  final Map<String, Completer<String>> _downloadsInProgress = {};

  Future<String> _getCacheDir() async {
    if (_cacheDirPath != null) return _cacheDirPath!;
    final dir = await getApplicationCacheDirectory();
    _cacheDirPath = join(dir.path, _dirName);
    final d = Directory(_cacheDirPath!);
    if (!await d.exists()) await d.create(recursive: true);
    return _cacheDirPath!;
  }

  Future<String> _getMetadataDir() async {
    if (_metadataDirPath != null) return _metadataDirPath!;
    final cacheDir = await _getCacheDir();
    _metadataDirPath = join(cacheDir, _metadataDir);
    final d = Directory(_metadataDirPath!);
    if (!await d.exists()) await d.create(recursive: true);
    return _metadataDirPath!;
  }

  String _getExtension(String url) {
    if (url.contains('.m4a')) return 'm4a';
    if (url.contains('.opus')) return 'opus';
    if (url.contains('.webm')) return 'webm';
    return 'audio';
  }

  Future<String?> getCacheFilePath(String songId) async {
    if (songId.isEmpty) return null;
    final dir = await _getCacheDir();
    final extensions = isApplePlatform
        ? ['m4a']
        : ['audio', 'opus', 'webm', 'm4a'];
    for (final ext in extensions) {
      final path = join(dir, '$songId.$ext');
      final file = File(path);
      if (await file.exists() && await file.length() > 0) return path;
    }
    return null;
  }

  Future<CacheMetadata?> _getMetadata(String songId) async {
    try {
      final metaDir = await _getMetadataDir();
      final metaPath = join(metaDir, '$songId.json');
      final file = File(metaPath);
      if (!await file.exists()) return null;
      final content = await file.readAsString();
      if (content.trim().isEmpty) return null;
      final json = jsonDecode(content) as Map<String, dynamic>;
      return CacheMetadata.fromJson(json);
    } catch (e) {
      logWarning('StreamCache: failed to read metadata for $songId: $e',
          tag: 'StreamCache');
      return null;
    }
  }

  Future<void> _saveMetadata(CacheMetadata metadata) async {
    try {
      final metaDir = await _getMetadataDir();
      final metaPath = join(metaDir, '${metadata.songId}.json');
      final content = StringBuffer();
      content.write('{');
      content.write('"songId":"${metadata.songId}",');
      content.write('"totalBytes":${metadata.totalBytes},');
      content.write('"ranges":[');
      for (int i = 0; i < metadata.ranges.length; i++) {
        final r = metadata.ranges[i];
        if (i > 0) content.write(',');
        content.write('{"start":${r.start},"end":${r.end}}');
      }
      content.write('],');
      content.write(
          '"lastModified":"${metadata.lastModified.toIso8601String()}",');
      content.write('"isExplicitlyComplete":${metadata.isExplicitlyComplete}');
      content.write('}');
      final jsonStr = content.toString();
      await File(metaPath).writeAsString(jsonStr);
      log('StreamCache: _saveMetadata SUCCESS ${metadata.songId} - ranges:${metadata.ranges.length} complete:${metadata.isExplicitlyComplete}',
          tag: 'StreamCache');
    } catch (e) {
      logWarning(
          'StreamCache: failed to save metadata for ${metadata.songId}: $e',
          tag: 'StreamCache');
    }
  }

  Future<void> _deleteMetadata(String songId) async {
    try {
      final metaDir = await _getMetadataDir();
      final metaPath = join(metaDir, '$songId.json');
      final file = File(metaPath);
      if (await file.exists()) await file.delete();
    } catch (e) {
      logWarning('StreamCache: failed to delete metadata for $songId: $e',
          tag: 'StreamCache');
    }
  }

  Future<CacheMetadata> _initCacheFile(
      String songId, String url, int? contentLength) async {
    final metadata = CacheMetadata(
      songId: songId,
      totalBytes: contentLength,
      ranges: [],
      lastModified: DateTime.now(),
    );
    await _saveMetadata(metadata);
    return metadata;
  }

  Future<CacheMetadata> _addCachedRange(
      String songId, int start, int end) async {
    final metadata = await _getMetadata(songId) ??
        CacheMetadata(
          songId: songId,
          ranges: [],
          lastModified: DateTime.now(),
        );
    final newRanges = List<CachedRange>.from(metadata.ranges);
    newRanges.add(CachedRange(start, end));
    final merged = _mergeRanges(newRanges);
    final newMetadata = CacheMetadata(
      songId: songId,
      totalBytes: metadata.totalBytes,
      ranges: merged,
      lastModified: DateTime.now(),
      isExplicitlyComplete: metadata.isExplicitlyComplete,
    );
    await _saveMetadata(newMetadata);
    log('StreamCache: _addCachedRange $songId [$start, $end) merged ${merged.length} ranges',
        tag: 'StreamCache');
    return newMetadata;
  }

  Future<CacheMetadata> _markComplete(String songId) async {
    final metadata = await _getMetadata(songId) ??
        CacheMetadata(
          songId: songId,
          ranges: [],
          lastModified: DateTime.now(),
        );
    final newMetadata = CacheMetadata(
      songId: songId,
      totalBytes: metadata.totalBytes,
      ranges: metadata.ranges,
      lastModified: DateTime.now(),
      isExplicitlyComplete: true,
    );
    await _saveMetadata(newMetadata);
    log('StreamCache: _markComplete $songId', tag: 'StreamCache');
    return newMetadata;
  }

  List<CachedRange> _mergeRanges(List<CachedRange> ranges) {
    if (ranges.isEmpty) return [];
    final sorted = List<CachedRange>.from(ranges)
      ..sort((a, b) => a.start.compareTo(b.start));
    final merged = <CachedRange>[];
    CachedRange current = sorted.first;
    for (int i = 1; i < sorted.length; i++) {
      final next = sorted[i];
      if (current.end >= next.start) {
        current = CachedRange(current.start, math.max(current.end, next.end));
      } else {
        merged.add(current);
        current = next;
      }
    }
    merged.add(current);
    return merged;
  }

  Future<void> downloadToCacheInBackground(
    String songId,
    String url,
    Map<String, String>? headers,
  ) async {
    if (songId.isEmpty) return;
    if (_downloadsInProgress.containsKey(songId)) return;
    final completer = Completer<String>();
    _downloadsInProgress[songId] = completer;
    _downloadToCache(songId, url, headers).then((path) {
      completer.complete(path);
    }).catchError((e) {
      completer.completeError(e);
    }).whenComplete(() {
      _downloadsInProgress.remove(songId);
    });
  }

  Future<String> _downloadToCache(
    String songId,
    String url,
    Map<String, String>? headers,
  ) async {
    final dir = await _getCacheDir();
    final ext = _getExtension(url);
    final path = join(dir, '$songId.$ext');

    final file = File(path);
    final exists = await file.exists();
    final metadata = exists ? await _getMetadata(songId) : null;

    if (exists && metadata != null && metadata.isComplete) {
      log('StreamCache: $songId already complete, skipping download',
          tag: 'StreamCache');
      return path;
    }

    final client = http.Client();
    try {
      final request = http.Request('GET', Uri.parse(url));
      if (headers != null && headers.isNotEmpty) {
        request.headers.addAll(headers);
      }

      int? totalBytes;
      int startByte = 0;

      if (exists && metadata != null && metadata.cachedBytes > 0) {
        startByte = metadata.cachedBytes;
        if (startByte > 0) {
          request.headers['Range'] = 'bytes=$startByte-';
        }
      }

      final response = await client.send(request);

      if (response.statusCode == 200) {
        totalBytes = int.tryParse(response.headers['content-length'] ?? '');
        if (totalBytes == null && metadata?.totalBytes != null) {
          totalBytes = metadata!.totalBytes;
        }
        if (startByte == 0) {
          await _initCacheFile(songId, url, totalBytes);
        }
        final sink = file.openWrite(mode: FileMode.writeOnlyAppend);
        int downloaded = startByte;
        try {
          await for (final chunk in response.stream) {
            sink.add(chunk);
            downloaded += chunk.length;
            if (downloaded % (1024 * 1024) < 1024) {
              log('StreamCache: $songId downloading ${(downloaded / (totalBytes ?? 1) * 100).toStringAsFixed(1)}%',
                  tag: 'StreamCache');
            }
          }
          await sink.close();
          final endByte = startByte + downloaded - (startByte > 0 ? 0 : 0);
          await _addCachedRange(songId, startByte, endByte);
        } catch (e) {
          await sink.close();
          await _addCachedRange(songId, startByte, downloaded);
          rethrow;
        }
      } else if (response.statusCode == 206) {
        final rangeHeader = response.headers['content-range'] ?? '';
        final totalMatch = RegExp(r'/(\d+)').firstMatch(rangeHeader);
        if (totalMatch != null && metadata?.totalBytes == null) {
          totalBytes = int.parse(totalMatch.group(1)!);
        } else {
          totalBytes = metadata?.totalBytes;
        }
        if (startByte == 0) {
          await _initCacheFile(songId, url, totalBytes);
        }
        final sink = file.openWrite(mode: FileMode.writeOnlyAppend);
        int downloaded = startByte;
        try {
          await for (final chunk in response.stream) {
            sink.add(chunk);
            downloaded += chunk.length;
          }
          await sink.close();
          await _addCachedRange(songId, startByte, downloaded);
        } catch (e) {
          await sink.close();
          await _addCachedRange(songId, startByte, downloaded);
          rethrow;
        }
      } else {
        throw Exception('StreamCache: HTTP ${response.statusCode} for $songId');
      }

      log('StreamCache: saved $songId to $path', tag: 'StreamCache');
      await _markComplete(songId);
      await trimCacheIfNeeded();
      return path;
    } finally {
      client.close();
    }
  }

  Future<void> startIncrementalDownload(
    String songId,
    String url,
    Map<String, String>? headers, {
    int? fromByte,
    void Function(int downloaded, int total)? onProgress,
  }) async {
    if (songId.isEmpty) return;

    final dir = await _getCacheDir();
    final ext = _getExtension(url);
    final path = join(dir, '$songId.$ext');
    final file = File(path);

    final existingMetadata = await _getMetadata(songId);
    final startByte = fromByte ?? (existingMetadata?.cachedBytes ?? 0);

    if (existingMetadata?.isComplete == true) {
      log('StreamCache: $songId already complete', tag: 'StreamCache');
      return;
    }

    final client = http.Client();
    try {
      final request = http.Request('GET', Uri.parse(Uri.parse(url).toString()));
      if (headers != null && headers.isNotEmpty) {
        request.headers.addAll(headers);
      }
      request.headers['Range'] = 'bytes=$startByte-';

      final response = await client.send(request);

      if (response.statusCode != 200 && response.statusCode != 206) {
        throw Exception('StreamCache: HTTP ${response.statusCode}');
      }

      int? totalBytes;
      if (response.headers['content-range'] != null) {
        final rangeHeader = response.headers['content-range']!;
        final totalMatch = RegExp(r'/(\d+)').firstMatch(rangeHeader);
        if (totalMatch != null) {
          totalBytes = int.parse(totalMatch.group(1)!);
        }
      }

      if (startByte == 0 && existingMetadata == null) {
        await _initCacheFile(songId, url, totalBytes);
      }

      final sink = file.openWrite(mode: FileMode.writeOnlyAppend);
      int downloaded = startByte;
      try {
        await for (final chunk in response.stream) {
          sink.add(chunk);
          downloaded += chunk.length;
          onProgress?.call(downloaded, totalBytes ?? 0);
        }
        await sink.close();
        await _addCachedRange(songId, startByte, downloaded);
        await _markComplete(songId);
        log('StreamCache: startIncrementalDownload complete $songId',
            tag: 'StreamCache');
      } catch (e) {
        await sink.close();
        await _addCachedRange(songId, startByte, downloaded);
        rethrow;
      }
    } finally {
      client.close();
    }
  }

  Future<CacheInfo> getCacheInfo(String songId) async {
    final path = await getCacheFilePath(songId);
    if (path == null) {
      log('StreamCache: getCacheInfo $songId - NOT FOUND (no file)',
          tag: 'StreamCache');
      return CacheInfo(
        songId: songId,
        exists: false,
        cachedBytes: 0,
        totalBytes: null,
        isComplete: false,
      );
    }

    final file = File(path);
    final fileSize = await file.length();
    final metadata = await _getMetadata(songId);

    int cachedBytes;
    bool isComplete;

    if (metadata != null && metadata.ranges.isNotEmpty) {
      cachedBytes =
          metadata.cachedBytes > fileSize ? fileSize : metadata.cachedBytes;
      isComplete = metadata.isComplete;
      log('StreamCache: getCacheInfo $songId - file:$fileSize bytes, ranges:${metadata.ranges.length}, isExplicitlyComplete:${metadata.isExplicitlyComplete}, isComplete:$isComplete',
          tag: 'StreamCache');
    } else if (fileSize > 0) {
      cachedBytes = fileSize;
      // When metadata is missing, we can't assume completion
      // Use a reasonable estimate based on typical song sizes
      // Most songs are 3-10MB, so treat <2MB as incomplete
      isComplete = fileSize >= (2 * 1024 * 1024); // 2MB threshold
      log('StreamCache: getCacheInfo $songId - file:$fileSize bytes, NO METADATA (${isComplete ? 'assuming complete' : 'assuming incomplete'})',
          tag: 'StreamCache');
    } else {
      cachedBytes = 0;
      isComplete = false;
      log('StreamCache: getCacheInfo $songId - file exists but empty',
          tag: 'StreamCache');
    }

    return CacheInfo(
      songId: songId,
      exists: true,
      filePath: path,
      cachedBytes: cachedBytes,
      totalBytes: metadata?.totalBytes ?? (isComplete ? fileSize : (5 * 1024 * 1024)), // 5MB estimate for incomplete files
      isComplete: isComplete,
    );
  }

  Future<bool> isPositionCached(
      String songId, Duration position, Duration? totalDuration) async {
    if (totalDuration == null || totalDuration.inMilliseconds == 0) {
      final info = await getCacheInfo(songId);
      return info.isComplete;
    }

    final metadata = await _getMetadata(songId);
    if (metadata == null || metadata.totalBytes == null) {
      final info = await getCacheInfo(songId);
      return info.isComplete;
    }

    final bytePosition = (position.inMilliseconds /
            totalDuration.inMilliseconds *
            metadata.totalBytes!)
        .round();
    return metadata.isPositionCached(bytePosition);
  }

  Future<List<int>> getUncachedRanges(
      String songId, Duration position, Duration duration) async {
    final metadata = await _getMetadata(songId);
    if (metadata == null || metadata.totalBytes == null) return [];

    final currentByte = (position.inMilliseconds /
            duration.inMilliseconds *
            metadata.totalBytes!)
        .round();
    final uncachedRanges = <int>[];

    int cursor = currentByte;
    for (final range in metadata.ranges) {
      if (cursor < range.start) {
        uncachedRanges.add(cursor);
        uncachedRanges.add(range.start);
      }
      cursor = math.max(cursor, range.end);
    }
    if (cursor < metadata.totalBytes!) {
      uncachedRanges.add(cursor);
      uncachedRanges.add(metadata.totalBytes!);
    }

    return uncachedRanges;
  }

  Future<void> removeFromCache(String songId) async {
    final path = await getCacheFilePath(songId);
    if (path != null) {
      try {
        await File(path).delete();
        await _deleteMetadata(songId);
        log('StreamCache: removed $songId', tag: 'StreamCache');
      } catch (e) {
        logWarning('StreamCache: removeFromCache delete failed: $e',
            tag: 'StreamCache');
      }
    }
  }

  Future<String?> getPathForCopy(String songId) => getCacheFilePath(songId);

  Future<int> getCacheSizeBytes() async {
    try {
      final dir = await _getCacheDir();
      final cacheDir = Directory(dir);
      if (!await cacheDir.exists()) return 0;

      int totalSize = 0;
      await for (final entity in cacheDir.list()) {
        if (entity is File && !entity.path.contains(_metadataDir)) {
          totalSize += await entity.length();
        }
      }
      return totalSize;
    } catch (e) {
      logWarning('StreamCache: getCacheSizeBytes failed: $e',
          tag: 'StreamCache');
      return 0;
    }
  }

  Future<CacheStats> getCacheStats() async {
    try {
      final dir = await _getCacheDir();
      final cacheDir = Directory(dir);
      if (!await cacheDir.exists()) {
        return CacheStats(totalBytes: 0, fileCount: 0, oldFilesCount: 0);
      }

      int totalSize = 0;
      int fileCount = 0;
      int oldFileCount = 0;
      final now = DateTime.now();
      final expirationDate = now.subtract(Duration(days: _cacheExpirationDays));

      await for (final entity in cacheDir.list()) {
        if (entity is File && !entity.path.contains(_metadataDir)) {
          fileCount++;
          final size = await entity.length();
          totalSize += size;

          final stat = await entity.stat();
          if (stat.modified.isBefore(expirationDate)) {
            oldFileCount++;
          }
        }
      }

      return CacheStats(
        totalBytes: totalSize,
        fileCount: fileCount,
        oldFilesCount: oldFileCount,
      );
    } catch (e) {
      logWarning('StreamCache: getCacheStats failed: $e', tag: 'StreamCache');
      return CacheStats(totalBytes: 0, fileCount: 0, oldFilesCount: 0);
    }
  }

  Future<void> clearCacheOlderThan(Duration duration) async {
    try {
      final dir = await _getCacheDir();
      final cacheDir = Directory(dir);
      if (!await cacheDir.exists()) return;

      int deletedCount = 0;
      final cutoffDate = DateTime.now().subtract(duration);

      await for (final entity in cacheDir.list()) {
        if (entity is File && !entity.path.contains(_metadataDir)) {
          final stat = await entity.stat();
          if (stat.modified.isBefore(cutoffDate)) {
            try {
              await entity.delete();
              final songId = entity.path.split('/').last.split('.').first;
              await _deleteMetadata(songId);
              deletedCount++;
            } catch (e) {
              logWarning('StreamCache: Failed to delete old file: $e',
                  tag: 'StreamCache');
            }
          }
        }
      }

      logInfo('StreamCache: Deleted $deletedCount old cache files',
          tag: 'StreamCache');
    } catch (e) {
      logWarning('StreamCache: clearCacheOlderThan failed: $e',
          tag: 'StreamCache');
    }
  }

  Future<void> trimCacheIfNeeded() async {
    try {
      final dir = await _getCacheDir();
      final cacheDir = Directory(dir);
      if (!await cacheDir.exists()) return;

      final fileEntries = <MapEntry<File, FileStat>>[];
      int totalSize = 0;

      await for (final entity in cacheDir.list()) {
        if (entity is File && !entity.path.contains(_metadataDir)) {
          final stat = await entity.stat();
          totalSize += stat.size;
          fileEntries.add(MapEntry(entity, stat));
        }
      }

      if (totalSize <= _maxCacheSizeBytes) return;

      logInfo(
          'StreamCache: Cache size ($totalSize bytes) exceeds limit, trimming...',
          tag: 'StreamCache');

      fileEntries.sort((a, b) => a.value.accessed.compareTo(b.value.accessed));

      int deletedSize = 0;
      int deletedCount = 0;
      for (final entry in fileEntries) {
        if (totalSize - deletedSize <= (_maxCacheSizeBytes * 0.8).toInt()) {
          break;
        }

        try {
          final fileSize = entry.value.size;
          final songId = entry.key.path.split('/').last.split('.').first;
          await entry.key.delete();
          await _deleteMetadata(songId);
          deletedSize += fileSize;
          deletedCount++;
        } catch (e) {
          logWarning('StreamCache: Failed to delete file during trim: $e',
              tag: 'StreamCache');
        }
      }

      logInfo(
          'StreamCache: Trimmed cache by deleting $deletedCount files ($deletedSize bytes)',
          tag: 'StreamCache');
    } catch (e) {
      logWarning('StreamCache: trimCacheIfNeeded failed: $e',
          tag: 'StreamCache');
    }
  }

  Future<void> clearAllCache() async {
    try {
      final dir = await _getCacheDir();
      final cacheDir = Directory(dir);
      if (!await cacheDir.exists()) return;

      int deletedCount = 0;

      await for (final entity in cacheDir.list()) {
        if (entity is File) {
          try {
            await entity.delete();
            deletedCount++;
          } catch (e) {
            logWarning('StreamCache: Failed to delete file: $e',
                tag: 'StreamCache');
          }
        }
      }

      logInfo('StreamCache: Cleared all cache ($deletedCount files deleted)',
          tag: 'StreamCache');
    } catch (e) {
      logWarning('StreamCache: clearAllCache failed: $e', tag: 'StreamCache');
    }
  }

  bool isDownloading(String songId) => _downloadsInProgress.containsKey(songId);
}

class CacheInfo {
  final String songId;
  final bool exists;
  final String? filePath;
  final int cachedBytes;
  final int? totalBytes;
  final bool isComplete;

  CacheInfo({
    required this.songId,
    required this.exists,
    this.filePath,
    required this.cachedBytes,
    this.totalBytes,
    required this.isComplete,
  });

  double get progress =>
      (totalBytes != null && totalBytes! > 0) ? cachedBytes / totalBytes! : 0.0;
}
