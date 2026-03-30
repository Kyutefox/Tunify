import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:tunify_logger/tunify_logger.dart';

import 'package:tunify/data/models/library_playlist.dart';
import 'package:tunify/data/models/song.dart';
import 'package:tunify/data/repositories/database_repository.dart';
import 'package:tunify/features/library/library_provider.dart';

/// Format options for playlist export.
enum PlaylistExportFormat {
  m3u,
  json,
}

extension PlaylistExportFormatX on PlaylistExportFormat {
  String get label => switch (this) {
        PlaylistExportFormat.m3u => 'M3U',
        PlaylistExportFormat.json => 'JSON',
      };
  String get extension => switch (this) {
        PlaylistExportFormat.m3u => 'm3u',
        PlaylistExportFormat.json => 'json',
      };
  String get mimeType => switch (this) {
        PlaylistExportFormat.m3u => 'audio/x-mpegurl',
        PlaylistExportFormat.json => 'application/json',
      };
}

/// Result of an import or export operation.
class PlaylistIOResult {
  const PlaylistIOResult.success(this.message) : error = null;
  const PlaylistIOResult.failure(this.error) : message = null;

  final String? message;
  final String? error;

  bool get isSuccess => error == null;
}

/// Parsed playlist from an import operation — before it is saved to the DB.
class ParsedPlaylist {
  const ParsedPlaylist({
    required this.name,
    required this.tracks,
  });

  final String name;
  final List<ParsedTrack> tracks;
}

/// A single track entry parsed from an M3U or JSON file.
class ParsedTrack {
  const ParsedTrack({
    required this.title,
    required this.artist,
    this.durationSeconds,
    this.ytVideoId,
    this.thumbnailUrl,
  });

  final String title;
  final String artist;
  final int? durationSeconds;
  /// YouTube video ID — present when importing from a Tunify JSON export.
  final String? ytVideoId;
  final String? thumbnailUrl;
}

/// Handles importing and exporting playlists in M3U and JSON formats.
class PlaylistIOService {
  const PlaylistIOService(this._repo);

  final DatabaseRepository _repo;

  // ── Export ───────────────────────────────────────────────────────────────────

  /// Exports [playlists] in [format] via the native save-file dialog.
  ///
  /// JSON: all playlists bundled into one file.
  /// M3U: one file per playlist — the user gets a save dialog per playlist.
  Future<PlaylistIOResult> exportPlaylists(
    List<LibraryPlaylist> playlists,
    PlaylistExportFormat format,
  ) async {
    try {
      final tmpDir = await getTemporaryDirectory();
      final timestamp = _timestamp();

      if (format == PlaylistExportFormat.json) {
        return await _exportJson(playlists, tmpDir, timestamp);
      } else {
        return await _exportM3u(playlists, tmpDir, timestamp);
      }
    } catch (e, st) {
      logError('Export failed: $e\n$st', tag: 'PlaylistIOService');
      return PlaylistIOResult.failure('Export failed: $e');
    }
  }

  Future<PlaylistIOResult> _exportJson(
    List<LibraryPlaylist> playlists,
    Directory tmpDir,
    String timestamp,
  ) async {
    final payload = {
      'tunify_export_version': 1,
      'exportedAt': DateTime.now().toUtc().toIso8601String(),
      'playlists': playlists.map((pl) => pl.toJson()).toList(),
    };
    final jsonStr = const JsonEncoder.withIndent('  ').convert(payload);
    final bytes = utf8.encode(jsonStr);
    final fileName = playlists.length == 1
        ? 'tunify_${_sanitize(playlists.first.name)}_$timestamp.json'
        : 'tunify_playlists_$timestamp.json';

    final savedPath = await FilePicker.platform.saveFile(
      dialogTitle: 'Save Playlist Export',
      fileName: fileName,
      type: FileType.custom,
      allowedExtensions: ['json'],
      bytes: bytes,
    );

    if (savedPath == null) return PlaylistIOResult.failure('Save cancelled');

    final count = playlists.length;
    return PlaylistIOResult.success(
        '$count playlist${count == 1 ? '' : 's'} saved to $savedPath');
  }

  Future<PlaylistIOResult> _exportM3u(
    List<LibraryPlaylist> playlists,
    Directory tmpDir,
    String timestamp,
  ) async {
    int saved = 0;

    for (final pl in playlists) {
      final buf = StringBuffer();
      buf.writeln('#EXTM3U');
      buf.writeln('#PLAYLIST:${pl.name}');
      for (final song in pl.sortedSongs) {
        final secs = song.duration.inSeconds;
        buf.writeln('#EXTINF:$secs,${song.artist} - ${song.title}');
        buf.writeln('https://music.youtube.com/watch?v=${song.id}');
      }
      final bytes = utf8.encode(buf.toString());
      final fileName = 'tunify_${_sanitize(pl.name)}_$timestamp.m3u';

      final savedPath = await FilePicker.platform.saveFile(
        dialogTitle: 'Save "${pl.name}" as M3U',
        fileName: fileName,
        type: FileType.custom,
        allowedExtensions: ['m3u'],
        bytes: bytes,
      );

      if (savedPath != null) saved++;
    }

    if (saved == 0) return PlaylistIOResult.failure('Save cancelled');
    return PlaylistIOResult.success(
        '$saved playlist${saved == 1 ? '' : 's'} saved as M3U');
  }

  // ── Import ───────────────────────────────────────────────────────────────────

  /// Opens the file picker and parses the selected file.
  ///
  /// Supported formats: `.m3u`, `.m3u8`, `.json`.
  /// Returns the list of [ParsedPlaylist] objects — the caller is responsible
  /// for saving them to the library (so the user can confirm first).
  Future<({PlaylistIOResult result, List<ParsedPlaylist> playlists})>
      pickAndParse() async {
    try {
      final picked = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['m3u', 'm3u8', 'json'],
        allowMultiple: false,
      );

      if (picked == null || picked.files.isEmpty) {
        return (
          result: const PlaylistIOResult.failure('No file selected'),
          playlists: <ParsedPlaylist>[],
        );
      }

      final filePath = picked.files.single.path;
      if (filePath == null) {
        return (
          result: const PlaylistIOResult.failure(
              'Could not read the selected file'),
          playlists: <ParsedPlaylist>[],
        );
      }

      final ext = p.extension(filePath).toLowerCase();
      final content = await File(filePath).readAsString(encoding: utf8);

      if (ext == '.json') {
        final pls = _parseJson(content, p.basenameWithoutExtension(filePath));
        return (
          result: PlaylistIOResult.success(
              'Found ${pls.length} playlist${pls.length == 1 ? '' : 's'}'),
          playlists: pls,
        );
      } else {
        final pl =
            _parseM3u(content, p.basenameWithoutExtension(filePath));
        return (
          result: const PlaylistIOResult.success('Playlist parsed'),
          playlists: [pl],
        );
      }
    } catch (e, st) {
      logError('Import parse failed: $e\n$st', tag: 'PlaylistIOService');
      return (
        result: PlaylistIOResult.failure('Import failed: $e'),
        playlists: <ParsedPlaylist>[],
      );
    }
  }

  /// Saves [parsed] playlists to the library as new local playlists.
  ///
  /// Each [ParsedTrack] that carries a [ytVideoId] is saved directly.
  /// Tracks without an ID are stored with a placeholder id so the user can
  /// see the track list — future search-and-match can fill in the real IDs.
  /// After all playlists are written, calls [libraryNotifier].load() so the
  /// UI reflects the changes without requiring an app restart.
  Future<PlaylistIOResult> saveImportedPlaylists(
    List<ParsedPlaylist> parsed,
    LibraryNotifier libraryNotifier,
  ) async {
    try {
      for (final pl in parsed) {
        final now = DateTime.now();
        final newId = 'lib_${now.millisecondsSinceEpoch}';

        final songs = pl.tracks.map((t) {
          final id = t.ytVideoId ??
              'import_${(t.title + t.artist).hashCode.abs()}';
          return Song(
            id: id,
            title: t.title,
            artist: t.artist,
            thumbnailUrl: t.thumbnailUrl ?? '',
            duration: Duration(seconds: t.durationSeconds ?? 0),
          );
        }).toList();

        final playlist = LibraryPlaylist(
          id: newId,
          name: pl.name,
          createdAt: now,
          updatedAt: now,
          songs: songs,
        );

        await _repo.createPlaylist(playlist);
        if (songs.isNotEmpty) {
          await _repo.replacePlaylistSongs(newId, songs);
        }

        // Small delay to ensure unique millisecond-based IDs.
        await Future.delayed(const Duration(milliseconds: 2));
      }

      // Reload library state so UI reflects the imported playlists.
      await libraryNotifier.load();

      final count = parsed.length;
      return PlaylistIOResult.success(
          '$count playlist${count == 1 ? '' : 's'} imported to your library');
    } catch (e, st) {
      logError('Import save failed: $e\n$st', tag: 'PlaylistIOService');
      return PlaylistIOResult.failure('Import failed: $e');
    }
  }

  // ── Parsers ──────────────────────────────────────────────────────────────────

  /// Parses an M3U / M3U8 file. Handles `#EXTM3U`, `#EXTINF`, `#PLAYLIST`.
  ParsedPlaylist _parseM3u(String content, String fallbackName) {
    final lines = content.split('\n').map((l) => l.trim()).toList();
    final tracks = <ParsedTrack>[];
    String playlistName = fallbackName;

    String? pendingTitle;
    String? pendingArtist;
    int? pendingDuration;

    for (final line in lines) {
      if (line.isEmpty || line == '#EXTM3U') continue;

      if (line.startsWith('#PLAYLIST:')) {
        playlistName = line.substring('#PLAYLIST:'.length).trim();
        continue;
      }

      if (line.startsWith('#EXTINF:')) {
        final rest = line.substring('#EXTINF:'.length);
        final commaIdx = rest.indexOf(',');
        if (commaIdx >= 0) {
          pendingDuration = int.tryParse(rest.substring(0, commaIdx).trim());
          final titlePart = rest.substring(commaIdx + 1).trim();
          final dashIdx = titlePart.indexOf(' - ');
          if (dashIdx >= 0) {
            pendingArtist = titlePart.substring(0, dashIdx).trim();
            pendingTitle = titlePart.substring(dashIdx + 3).trim();
          } else {
            pendingTitle = titlePart;
            pendingArtist = '';
          }
        }
        continue;
      }

      if (line.startsWith('#')) continue;

      // This is a URI line.
      final ytId = _extractYtId(line);
      tracks.add(ParsedTrack(
        title: pendingTitle ?? _titleFromPath(line),
        artist: pendingArtist ?? '',
        durationSeconds: pendingDuration,
        ytVideoId: ytId,
      ));
      pendingTitle = null;
      pendingArtist = null;
      pendingDuration = null;
    }

    return ParsedPlaylist(name: playlistName, tracks: tracks);
  }

  /// Parses a Tunify JSON export file.
  List<ParsedPlaylist> _parseJson(String content, String fallbackName) {
    final Map<String, dynamic> root = json.decode(content) as Map<String, dynamic>;

    // Tunify export format: { playlists: [...] }
    if (root.containsKey('playlists')) {
      final raw = (root['playlists'] as List<dynamic>).cast<Map<String, dynamic>>();
      return raw.map((pl) {
        final songs = (pl['songs'] as List<dynamic>? ?? [])
            .cast<Map<String, dynamic>>();
        final tracks = songs.map((s) => ParsedTrack(
              title: s['title'] as String? ?? '',
              artist: s['artist'] as String? ?? '',
              durationSeconds: s['durationMs'] != null
                  ? ((s['durationMs'] as int) ~/ 1000)
                  : null,
              ytVideoId: s['id'] as String?,
              thumbnailUrl: s['thumbnailUrl'] as String?,
            )).toList();
        return ParsedPlaylist(
          name: pl['name'] as String? ?? fallbackName,
          tracks: tracks,
        );
      }).toList();
    }

    // Generic flat format: { name, tracks: [{title, artist, ...}] }
    if (root.containsKey('tracks')) {
      final raw = (root['tracks'] as List<dynamic>).cast<Map<String, dynamic>>();
      final tracks = raw.map((t) => ParsedTrack(
            title: t['title'] as String? ?? t['name'] as String? ?? '',
            artist: t['artist'] as String? ?? t['creator'] as String? ?? '',
            durationSeconds: t['duration'] as int?,
          )).toList();
      return [
        ParsedPlaylist(
            name: root['name'] as String? ?? fallbackName, tracks: tracks)
      ];
    }

    return [];
  }

  // ── Utilities ────────────────────────────────────────────────────────────────

  String? _extractYtId(String uri) {
    try {
      final u = Uri.parse(uri);
      if (u.host.contains('youtube.com') || u.host.contains('music.youtube.com')) {
        return u.queryParameters['v'];
      }
      if (u.host == 'youtu.be') {
        return u.pathSegments.isNotEmpty ? u.pathSegments.first : null;
      }
    } catch (_) {}
    return null;
  }

  String _titleFromPath(String uri) {
    try {
      return p.basenameWithoutExtension(Uri.parse(uri).path);
    } catch (_) {
      return uri;
    }
  }

  String _sanitize(String name) =>
      name.replaceAll(RegExp(r'[^\w\s-]'), '').trim().replaceAll(' ', '_');

  String _timestamp() => DateTime.now()
      .toIso8601String()
      .replaceAll(':', '-')
      .replaceAll('.', '-')
      .substring(0, 19);
}

final playlistIOServiceProvider = Provider<PlaylistIOService>((ref) {
  return PlaylistIOService(ref.read(databaseRepositoryProvider));
});
