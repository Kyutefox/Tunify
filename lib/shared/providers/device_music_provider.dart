import 'package:flutter/services.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:on_audio_query_pluse/on_audio_query.dart';

import '../../models/song.dart';
import 'package:tunify_logger/tunify_logger.dart';

const _permChannel = MethodChannel('com.kyutefox.tunify/permissions');

/// State produced by [DeviceMusicNotifier]: permission status, loading flag, and the scanned song list.
class DeviceMusicState {
  final bool isLoading;
  final bool hasPermission;
  final bool permanentlyDenied;
  final List<Song> songs;
  final String? error;

  final Map<String, String> pathMap;

  const DeviceMusicState({
    this.isLoading = false,
    this.hasPermission = false,
    this.permanentlyDenied = false,
    this.songs = const [],
    this.error,
    this.pathMap = const {},
  });

  DeviceMusicState copyWith({
    bool? isLoading,
    bool? hasPermission,
    bool? permanentlyDenied,
    List<Song>? songs,
    String? error,
    Map<String, String>? pathMap,
    bool clearError = false,
  }) {
    return DeviceMusicState(
      isLoading: isLoading ?? this.isLoading,
      hasPermission: hasPermission ?? this.hasPermission,
      permanentlyDenied: permanentlyDenied ?? this.permanentlyDenied,
      songs: songs ?? this.songs,
      error: clearError ? null : (error ?? this.error),
      pathMap: pathMap ?? this.pathMap,
    );
  }
}

/// Scans device storage for audio files using [OnAudioQuery], requesting
/// runtime permission via a native method channel before querying.
///
/// Song IDs are prefixed with `device_` to prevent collisions with stream IDs.
/// File paths are stored in [DeviceMusicState.pathMap] and used by [AudioRepository]
/// to play local tracks without fetching a remote stream URL.
class DeviceMusicNotifier extends StateNotifier<DeviceMusicState> {
  final OnAudioQuery _audioQuery = OnAudioQuery();

  DeviceMusicNotifier() : super(const DeviceMusicState());

  Future<void> loadSongs() async {
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

  String? getLocalPath(String songId) => state.pathMap[songId];

  Future<void> openAppSettings() async {
    const channel = MethodChannel('com.kyutefox.tunify/settings');
    try {
      await channel.invokeMethod('openAppSettings');
    } catch (e) {
      logError('Could not open app settings: $e', tag: 'DeviceMusic');
    }
  }
}

final deviceMusicProvider =
    StateNotifierProvider<DeviceMusicNotifier, DeviceMusicState>((ref) {
  return DeviceMusicNotifier();
});
