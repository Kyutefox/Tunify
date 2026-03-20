import 'dart:io';

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
    if (totalBytes < 1024 * 1024) return '${(totalBytes / 1024).toStringAsFixed(1)} KB';
    return '${(totalBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

/// Disk cache for stream audio bytes. When a song is played from URL, the stream
/// is downloaded to a cache file so the next play is 0ms (no re-buffering).
/// Cache files can also be used for downloads (copy to downloads instead of re-fetching).
class StreamCacheService {
  static const String _dirName = 'stream_cache';
  static const int _maxCacheSizeBytes = 500 * 1024 * 1024; // 500 MB
  static const int _cacheExpirationDays = 7;

  String? _cacheDirPath;
  final Set<String> _downloadsInProgress = {};

  Future<String> _getCacheDir() async {
    if (_cacheDirPath != null) return _cacheDirPath!;
    final dir = await getApplicationCacheDirectory();
    _cacheDirPath = join(dir.path, _dirName);
    final d = Directory(_cacheDirPath!);
    if (!await d.exists()) await d.create(recursive: true);
    return _cacheDirPath!;
  }

  /// Path to cached file for [songId] if it exists and is readable.
  Future<String?> getCacheFilePath(String songId) async {
    if (songId.isEmpty) return null;
    final dir = await _getCacheDir();
    // iOS and macOS use AVPlayer (AVFoundation), which cannot decode opus/webm.
    // Only serve m4a (AAC) cached files on Apple platforms — other formats would
    // cause a -11828 "Cannot Open" error. Android ExoPlayer handles all formats.
    final extensions = (Platform.isIOS || Platform.isMacOS)
        ? ['m4a']
        : ['audio', 'opus', 'webm', 'm4a'];
    for (final ext in extensions) {
      final path = join(dir, '$songId.$ext');
      final file = File(path);
      if (await file.exists() && await file.length() > 0) return path;
    }
    return null;
  }

  /// Starts downloading the stream to cache in the background. Does not block.
  /// Deduplicated per [songId]; if a download for [songId] is already in progress, this is a no-op.
  void downloadToCacheInBackground(
    String songId,
    String url,
    Map<String, String>? headers,
  ) {
    if (songId.isEmpty) return;
    if (_downloadsInProgress.contains(songId)) return;
    _downloadsInProgress.add(songId);
    downloadToCache(songId, url, headers).whenComplete(() {
      _downloadsInProgress.remove(songId);
    });
  }

  /// Downloads the stream from [url] with [headers] into the cache and returns the file path.
  /// Overwrites any existing cache file for [songId].
  Future<String> downloadToCache(
    String songId,
    String url,
    Map<String, String>? headers,
  ) async {
    final dir = await _getCacheDir();
    final ext = url.contains('m4a') ? 'm4a' : 'audio';
    final path = join(dir, '$songId.$ext');

    final client = http.Client();
    try {
      final request = http.Request('GET', Uri.parse(url));
      if (headers != null && headers.isNotEmpty) request.headers.addAll(headers);
      final response = await client.send(request);
      if (response.statusCode != 200 && response.statusCode != 206) {
        throw Exception('Stream cache HTTP ${response.statusCode}');
      }

      final file = File(path);
      final sink = file.openWrite();
      try {
        // Pipe stream directly to sink — no manual buffer copies needed.
        await response.stream.pipe(sink);
        // pipe() closes the sink on normal completion.
      } catch (e) {
        await sink.close();
        rethrow;
      }
      log('StreamCache: saved $songId to $path', tag: 'StreamCache');

      // Trim cache if needed after adding new file.
      await trimCacheIfNeeded();

      return path;
    } finally {
      client.close();
    }
  }

  /// Removes cached file for [songId] if present. Use after playback error to force refetch.
  Future<void> removeFromCache(String songId) async {
    final path = await getCacheFilePath(songId);
    if (path != null) {
      try {
        await File(path).delete();
        log('StreamCache: removed $songId', tag: 'StreamCache');
      } catch (e) {
        logWarning('StreamCache: removeFromCache delete failed: $e', tag: 'StreamCache');
      }
    }
  }

  /// Returns the cache file path if it exists; callers can copy this file to downloads.
  Future<String?> getPathForCopy(String songId) => getCacheFilePath(songId);

  /// Get total cache size in bytes.
  Future<int> getCacheSizeBytes() async {
    try {
      final dir = await _getCacheDir();
      final cacheDir = Directory(dir);
      if (!await cacheDir.exists()) return 0;

      int totalSize = 0;
      await for (final entity in cacheDir.list()) {
        if (entity is File) {
          totalSize += await entity.length();
        }
      }
      return totalSize;
    } catch (e) {
      logWarning('StreamCache: getCacheSizeBytes failed: $e', tag: 'StreamCache');
      return 0;
    }
  }

  /// Get cache statistics (size, file count, old files count).
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
        if (entity is File) {
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

  /// Clear cache files older than [duration].
  Future<void> clearCacheOlderThan(Duration duration) async {
    try {
      final dir = await _getCacheDir();
      final cacheDir = Directory(dir);
      if (!await cacheDir.exists()) return;

      int deletedCount = 0;
      final cutoffDate = DateTime.now().subtract(duration);

      await for (final entity in cacheDir.list()) {
        if (entity is File) {
          final stat = await entity.stat();
          if (stat.modified.isBefore(cutoffDate)) {
            try {
              await entity.delete();
              deletedCount++;
            } catch (e) {
              logWarning('StreamCache: Failed to delete old file: $e', tag: 'StreamCache');
            }
          }
        }
      }

      logInfo('StreamCache: Deleted $deletedCount old cache files', tag: 'StreamCache');
    } catch (e) {
      logWarning('StreamCache: clearCacheOlderThan failed: $e', tag: 'StreamCache');
    }
  }

  /// Trim cache to fit within size limit using LRU (least-recently-used) eviction.
  /// Uses a single directory scan to compute size and select eviction candidates
  /// atomically, avoiding TOCTOU race conditions.
  Future<void> trimCacheIfNeeded() async {
    try {
      final dir = await _getCacheDir();
      final cacheDir = Directory(dir);
      if (!await cacheDir.exists()) return;

      // Single scan: collect all files with their stats and total size together.
      final fileEntries = <MapEntry<File, FileStat>>[];
      int totalSize = 0;

      await for (final entity in cacheDir.list()) {
        if (entity is File) {
          final stat = await entity.stat();
          totalSize += stat.size;
          fileEntries.add(MapEntry(entity, stat));
        }
      }

      if (totalSize <= _maxCacheSizeBytes) return;

      logInfo(
        'StreamCache: Cache size ($totalSize bytes) exceeds limit, trimming...',
        tag: 'StreamCache',
      );

      // Sort by access time — oldest accessed first (LRU eviction).
      fileEntries.sort((a, b) => a.value.accessed.compareTo(b.value.accessed));

      int deletedSize = 0;
      int deletedCount = 0;
      for (final entry in fileEntries) {
        if (totalSize - deletedSize <= (_maxCacheSizeBytes * 0.8).toInt()) break;

        try {
          final fileSize = entry.value.size;
          await entry.key.delete();
          deletedSize += fileSize;
          deletedCount++;
        } catch (e) {
          logWarning('StreamCache: Failed to delete file during trim: $e', tag: 'StreamCache');
        }
      }

      logInfo(
        'StreamCache: Trimmed cache by deleting $deletedCount files ($deletedSize bytes)',
        tag: 'StreamCache',
      );
    } catch (e) {
      logWarning('StreamCache: trimCacheIfNeeded failed: $e', tag: 'StreamCache');
    }
  }

  /// Clear all cache files.
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
            logWarning('StreamCache: Failed to delete file: $e', tag: 'StreamCache');
          }
        }
      }

      logInfo('StreamCache: Cleared all cache ($deletedCount files deleted)', tag: 'StreamCache');
    } catch (e) {
      logWarning('StreamCache: clearAllCache failed: $e', tag: 'StreamCache');
    }
  }
}
