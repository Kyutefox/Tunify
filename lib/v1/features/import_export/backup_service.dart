import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tunify/v1/core/utils/app_log.dart';

import 'package:tunify/v1/data/models/library_album.dart';
import 'package:tunify/v1/data/models/library_artist.dart';
import 'package:tunify/v1/data/models/library_folder.dart';
import 'package:tunify/v1/data/models/library_playlist.dart';
import 'package:tunify/v1/data/models/recently_played_song.dart';
import 'package:tunify/v1/data/repositories/database_repository.dart';

/// Version tag written into every backup file.
const _kBackupVersion = 1;

/// Result of a backup or restore operation.
class BackupResult {
  const BackupResult.success(this.message) : error = null;
  const BackupResult.failure(this.error) : message = null;

  final String? message;
  final String? error;

  bool get isSuccess => error == null;
}

/// Handles creating a full JSON backup of the library and restoring from one.
///
/// Backup format:
/// ```json
/// {
///   "version": 1,
///   "exportedAt": "<ISO-8601>",
///   "library": { ... full LibraryData as JSON ... }
/// }
/// ```
class BackupService {
  const BackupService(this._repo);

  final DatabaseRepository _repo;

  // ── Backup ──────────────────────────────────────────────────────────────────

  /// Serialises the entire library to JSON and opens a native save dialog
  /// so the user can choose where to store the file.
  Future<BackupResult> createBackup() async {
    try {
      final data = await _repo.loadAll();

      final recentlyPlayed = await _repo.loadRecentlyPlayed();
      final recentSearches = await _repo.loadRecentSearches();
      final ytPersonalization = await _repo.loadYtPersonalization();

      final payload = {
        'version': _kBackupVersion,
        'exportedAt': DateTime.now().toUtc().toIso8601String(),
        'library': {
          'playlists': data.playlists.map((p) => p.toJson()).toList(),
          'folders': data.folders.map((f) => f.toJson()).toList(),
          'sortOrder': data.sortOrder,
          'viewMode': data.viewMode,
          'downloadedShuffleMode': data.downloadedShuffleMode.index,
          'recentlyPlayedShuffleMode': data.recentlyPlayedShuffleMode.index,
          'downloadsSortOrder': data.downloadsSortOrder.toString(),
          'followedArtists':
              data.followedArtists.map((a) => a.toJson()).toList(),
          'followedAlbums': data.followedAlbums.map((a) => a.toJson()).toList(),
        },
        'recentlyPlayed': recentlyPlayed.map((s) => s.toJson()).toList(),
        'recentSearches': recentSearches,
        'ytPersonalization': ytPersonalization,
      };

      final json = const JsonEncoder.withIndent('  ').convert(payload);
      final bytes = utf8.encode(json);

      final timestamp = DateTime.now()
          .toIso8601String()
          .replaceAll(':', '-')
          .replaceAll('.', '-')
          .substring(0, 19);
      final fileName = 'tunify_backup_$timestamp.json';

      final savedPath = await FilePicker.saveFile(
        dialogTitle: 'Save Tunify Backup',
        fileName: fileName,
        type: FileType.custom,
        allowedExtensions: ['json'],
        bytes: bytes,
      );

      if (savedPath == null) {
        return const BackupResult.failure('Save cancelled');
      }
      return BackupResult.success('Backup saved to $savedPath');
    } catch (e, st) {
      logError('Backup failed: $e\n$st', tag: 'BackupService');
      return BackupResult.failure('Backup failed: $e');
    }
  }

  // ── Restore ─────────────────────────────────────────────────────────────────

  /// Opens a file picker so the user selects a `.json` backup file, then
  /// deserialises it and writes it back to the database.
  Future<BackupResult> restoreBackup() async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) {
        return const BackupResult.failure('No file selected');
      }

      final filePath = result.files.single.path;
      if (filePath == null) {
        return const BackupResult.failure('Could not read the selected file');
      }

      final raw = await File(filePath).readAsString();
      final Map<String, dynamic> payload =
          json.decode(raw) as Map<String, dynamic>;

      final version = payload['version'] as int? ?? 0;
      if (version > _kBackupVersion) {
        return const BackupResult.failure(
            'This backup was created by a newer version of Tunify. Please update the app.');
      }

      final libraryRaw = payload['library'] as Map<String, dynamic>? ?? {};
      final recentlyPlayedRaw = (payload['recentlyPlayed'] as List<dynamic>?)
              ?.cast<Map<String, dynamic>>() ??
          [];
      final recentSearchesRaw = (payload['recentSearches'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [];
      final ytPersonalization =
          (payload['ytPersonalization'] as Map<String, dynamic>?) ?? {};

      final libraryData = _parseLibraryData(libraryRaw);
      await _repo.saveAll(data: libraryData);
      await _repo.saveRecentlyPlayed(
        recentlyPlayedRaw.map(_parseRecentSong).toList(),
      );
      await _repo.saveRecentSearches(recentSearchesRaw);
      await _repo.saveYtPersonalization(ytPersonalization);

      return const BackupResult.success(
          'Library restored successfully. Restart the app to see all changes.');
    } catch (e, st) {
      logError('Restore failed: $e\n$st', tag: 'BackupService');
      return BackupResult.failure('Restore failed: $e');
    }
  }

  // ── Helpers ──────────────────────────────────────────────────────────────────

  LibraryData _parseLibraryData(Map<String, dynamic> raw) {
    final playlistsRaw =
        (raw['playlists'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();
    final foldersRaw =
        (raw['folders'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();
    final artistsRaw = (raw['followedArtists'] as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>();
    final albumsRaw = (raw['followedAlbums'] as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>();

    return (
      playlists: playlistsRaw.map(LibraryPlaylist.fromJson).toList(),
      folders: foldersRaw.map(LibraryFolder.fromJson).toList(),
      sortOrder: raw['sortOrder'] as String? ?? 'recent',
      viewMode: raw['viewMode'] as String? ?? 'list',
      downloadedShuffleMode:
          ShuffleModeX.fromInt(raw['downloadedShuffleMode'] as int?),
      recentlyPlayedShuffleMode:
          ShuffleModeX.fromInt(raw['recentlyPlayedShuffleMode'] as int?),
      downloadsSortOrder: raw['downloadsSortOrder'] as String? ?? 'customOrder',
      followedArtists: artistsRaw.map(LibraryArtist.fromJson).toList(),
      followedAlbums: albumsRaw.map(LibraryAlbum.fromJson).toList(),
    );
  }

  RecentlyPlayedSong _parseRecentSong(Map<String, dynamic> m) =>
      RecentlyPlayedSong.fromJson(m);
}

final backupServiceProvider = Provider<BackupService>((ref) {
  return BackupService(ref.read(databaseRepositoryProvider));
});
