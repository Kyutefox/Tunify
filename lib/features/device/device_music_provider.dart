import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:on_audio_query_pluse/on_audio_query.dart';

import 'package:tunify/data/models/song.dart';
import 'package:tunify_logger/tunify_logger.dart';

const _permChannel = MethodChannel('com.kyutefox.tunify/permissions');
const _localFilesChannel = MethodChannel('com.kyutefox.tunify/local_files');

/// Supported audio file extensions for macOS local file scanning.
const _audioExtensions = {
  '.mp3',
  '.m4a',
  '.aac',
  '.flac',
  '.wav',
  '.aiff',
  '.aif',
  '.ogg',
  '.opus',
  '.wma',
  '.alac',
  '.ape',
  '.dsf',
  '.dff',
};

/// State produced by [DeviceMusicNotifier]: permission status, loading flag, and the scanned song list.
class DeviceMusicState {
  final bool isLoading;
  final bool hasPermission;
  final bool permanentlyDenied;
  final List<Song> songs;
  final String? error;
  final String? macOSMusicFolder;

  final Map<String, String> pathMap;

  const DeviceMusicState({
    this.isLoading = false,
    this.hasPermission = false,
    this.permanentlyDenied = false,
    this.songs = const [],
    this.error,
    this.pathMap = const {},
    this.macOSMusicFolder,
  });

  DeviceMusicState copyWith({
    bool? isLoading,
    bool? hasPermission,
    bool? permanentlyDenied,
    List<Song>? songs,
    String? error,
    Map<String, String>? pathMap,
    bool clearError = false,
    String? macOSMusicFolder,
    bool clearMacOSMusicFolder = false,
  }) {
    return DeviceMusicState(
      isLoading: isLoading ?? this.isLoading,
      hasPermission: hasPermission ?? this.hasPermission,
      permanentlyDenied: permanentlyDenied ?? this.permanentlyDenied,
      songs: songs ?? this.songs,
      error: clearError ? null : (error ?? this.error),
      pathMap: pathMap ?? this.pathMap,
      macOSMusicFolder: clearMacOSMusicFolder
          ? null
          : (macOSMusicFolder ?? this.macOSMusicFolder),
    );
  }
}

/// Scans device storage for audio files.
///
/// • **Android**: uses [OnAudioQuery] with a runtime permission check via the
///   native `com.kyutefox.tunify/permissions` channel.
/// • **macOS**: uses a native `com.kyutefox.tunify/local_files` channel to show
///   `NSOpenPanel`, saves a security-scoped bookmark so the chosen folder
///   survives app restarts, then scans the folder recursively with `dart:io`.
/// • **Other platforms**: no-op (stays in initial state).
///
/// Song IDs are prefixed with `device_` to prevent collisions with stream IDs.
/// File paths are stored in [DeviceMusicState.pathMap] and used by [AudioRepository]
/// to play local tracks without fetching a remote stream URL.
class DeviceMusicNotifier extends Notifier<DeviceMusicState> {
  final OnAudioQuery _audioQuery = OnAudioQuery();

  @override
  DeviceMusicState build() {
    if (Platform.isMacOS) {
      _restoreMacOSFolder();
    }
    return const DeviceMusicState();
  }

  // ─── macOS ─────────────────────────────────────────────────────────────────

  /// Called at construction time. Tries to resolve a previously saved
  /// security-scoped bookmark via the native plugin. If one exists the folder
  /// is scanned immediately so songs are ready without user interaction.
  Future<void> _restoreMacOSFolder() async {
    try {
      final path =
          await _localFilesChannel.invokeMethod<String>('getSavedMusicFolder');
      if (path != null && path.isNotEmpty) {
        await _scanMacOSFolder(path);
      }
    } catch (e) {
      logWarning('DeviceMusic: could not restore macOS folder: $e',
          tag: 'DeviceMusic');
    }
  }

  /// Shows `NSOpenPanel` so the user can pick a folder, then scans it.
  Future<void> pickMacOSFolder() async {
    if (state.isLoading) return;
    try {
      final path =
          await _localFilesChannel.invokeMethod<String>('pickMusicFolder');
      if (path == null || path.isEmpty) {
        // User cancelled the panel — leave state unchanged.
        return;
      }
      await _scanMacOSFolder(path);
    } on MissingPluginException {
      logWarning(
          'DeviceMusic: local_files channel not available on this platform',
          tag: 'DeviceMusic');
    } catch (e) {
      logError('DeviceMusic: pickMacOSFolder failed: $e', tag: 'DeviceMusic');
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to open folder: $e',
      );
    }
  }

  /// Clears the saved bookmark and resets state so the user can pick a
  /// different folder.
  Future<void> clearMacOSFolder() async {
    try {
      await _localFilesChannel.invokeMethod<void>('clearSavedMusicFolder');
    } catch (_) {}
    state = const DeviceMusicState();
  }

  /// Recursively walks [folderPath] and builds [DeviceMusicState.songs] /
  /// [DeviceMusicState.pathMap] from all audio files found.
  Future<void> _scanMacOSFolder(String folderPath) async {
    state = state.copyWith(
      isLoading: true,
      clearError: true,
      macOSMusicFolder: folderPath,
    );

    try {
      final dir = Directory(folderPath);
      if (!dir.existsSync()) {
        state = state.copyWith(
          isLoading: false,
          hasPermission: false,
          error: 'Folder not found: $folderPath',
        );
        return;
      }

      final songs = <Song>[];
      final pathMap = <String, String>{};

      final entities = dir.listSync(recursive: true, followLinks: false);
      for (final entity in entities) {
        if (entity is! File) continue;
        final path = entity.path;
        final ext = _extensionOf(path);
        if (!_audioExtensions.contains(ext)) continue;

        final name = _basenameWithoutExtension(path);
        final id = 'device_${path.hashCode.abs()}';

        // Best-effort metadata from the filename:
        // "Artist - Title" → split on first " - "
        String title = name;
        String artist = 'Unknown Artist';
        final dashIdx = name.indexOf(' - ');
        if (dashIdx > 0) {
          artist = name.substring(0, dashIdx).trim();
          title = name.substring(dashIdx + 3).trim();
        }

        songs.add(Song(
          id: id,
          title: title,
          artist: artist,
          thumbnailUrl: '',
          duration: Duration.zero, // duration unknown without metadata parsing
        ));
        pathMap[id] = path;
      }

      // Sort alphabetically by title for a consistent default order.
      songs.sort((a, b) => a.title.compareTo(b.title));

      state = state.copyWith(
        isLoading: false,
        hasPermission: true,
        songs: songs,
        pathMap: pathMap,
        macOSMusicFolder: folderPath,
      );

      logInfo(
          'DeviceMusic: scanned $folderPath — ${songs.length} audio files found',
          tag: 'DeviceMusic');
    } catch (e) {
      logError('DeviceMusic: _scanMacOSFolder failed: $e', tag: 'DeviceMusic');
      state = state.copyWith(
        isLoading: false,
        hasPermission: false,
        error: 'Failed to scan folder: $e',
      );
    }
  }

  // ─── Android ───────────────────────────────────────────────────────────────

  Future<void> loadSongs() async {
    if (Platform.isMacOS) {
      // macOS uses pickMacOSFolder() for user-triggered loads and
      // _restoreMacOSFolder() for automatic restore on init.
      // Calling loadSongs() on macOS re-scans the saved folder if one exists,
      // otherwise it's a no-op (the UI will show the "Choose Folder" prompt).
      if (state.macOSMusicFolder != null) {
        await _scanMacOSFolder(state.macOSMusicFolder!);
      } else {
        await _restoreMacOSFolder();
      }
      return;
    }

    if (!Platform.isAndroid) {
      // Non-Android, non-macOS platforms (Linux, Windows, iOS) — not supported.
      state = state.copyWith(isLoading: false, hasPermission: false);
      return;
    }

    if (state.isLoading) return;
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      bool hasPermission;
      try {
        hasPermission =
            await _permChannel.invokeMethod<bool>('checkAudioPermission') ??
                false;
      } catch (_) {
        hasPermission = await _audioQuery.permissionsStatus();
      }

      if (!hasPermission) {
        bool granted;
        try {
          granted =
              await _permChannel.invokeMethod<bool>('requestAudioPermission') ??
                  false;
        } catch (_) {
          granted = await _audioQuery.permissionsRequest();
        }
        if (!granted) {
          state = state.copyWith(
            isLoading: false,
            hasPermission: false,
            permanentlyDenied: true,
            error: 'Storage permission is required to access device music.',
          );
          return;
        }
      }

      state = state.copyWith(hasPermission: true);

      final deviceSongs = await _audioQuery.querySongs(
        sortType: SongSortType.DATE_ADDED,
        orderType: OrderType.DESC_OR_GREATER,
        uriType: UriType.EXTERNAL,
        ignoreCase: true,
      );

      final filtered = deviceSongs.where((s) =>
          s.duration != null &&
          s.duration! > 30000 && // > 30 seconds
          s.isMusic == true);

      final songs = <Song>[];
      final pathMap = <String, String>{};

      for (final s in filtered) {
        final id = 'device_${s.id}';
        final path = s.data;
        songs.add(Song(
          id: id,
          title: s.title,
          artist: s.artist ?? 'Unknown Artist',
          thumbnailUrl: '', // Device songs use artwork query instead
          duration: Duration(milliseconds: s.duration ?? 0),
        ));
        pathMap[id] = path;
      }

      state = state.copyWith(
        isLoading: false,
        songs: songs,
        pathMap: pathMap,
      );
    } catch (e) {
      logError('Error: $e', tag: 'DeviceMusic');
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load device music: $e',
      );
    }
  }

  // ─── Shared helpers ────────────────────────────────────────────────────────

  String? getLocalPath(String songId) => state.pathMap[songId];

  Future<void> openAppSettings() async {
    const channel = MethodChannel('com.kyutefox.tunify/settings');
    try {
      await channel.invokeMethod('openAppSettings');
    } catch (e) {
      logError('Could not open app settings: $e', tag: 'DeviceMusic');
    }
  }

  // ─── Private file-path utilities ───────────────────────────────────────────

  static String _extensionOf(String path) {
    final dot = path.lastIndexOf('.');
    if (dot < 0 || dot == path.length - 1) return '';
    return path.substring(dot).toLowerCase();
  }

  static String _basenameWithoutExtension(String path) {
    final sep = path.lastIndexOf(Platform.pathSeparator);
    var name = sep >= 0 ? path.substring(sep + 1) : path;
    final dot = name.lastIndexOf('.');
    if (dot > 0) name = name.substring(0, dot);
    return name;
  }
}

final deviceMusicProvider =
    NotifierProvider<DeviceMusicNotifier, DeviceMusicState>(DeviceMusicNotifier.new);
