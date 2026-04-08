import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tunify/data/models/song.dart';
import 'package:tunify/data/models/library_playlist.dart';
import 'package:tunify/features/home/home_state_provider.dart';
import 'package:tunify/features/downloads/download_provider.dart';
import 'package:tunify/features/library/library_provider.dart';
import 'package:tunify/features/player/audio/audio_handler.dart';
import 'package:tunify/features/player/player_state_provider.dart';
import 'package:tunify/features/player/playback_position_provider.dart';
import 'package:tunify_logger/tunify_logger.dart';

/// Provider that handles CarPlay method channel communication.
/// Listens for requests from the iOS CarPlay interface and provides
/// media items, playback control, and now playing updates.
final carPlayProvider = Provider<CarPlayService>((ref) {
  return CarPlayService(ref);
});

class CarPlayService {
  static const MethodChannel _channel = MethodChannel('com.tunify/carplay');
  final Ref _ref;
  StreamSubscription? _playbackSubscription;

  CarPlayService(this._ref) {
    _setupMethodChannel();
    _setupPlaybackListener();
  }

  void _setupMethodChannel() {
    _channel.setMethodCallHandler((call) async {
      try {
        switch (call.method) {
          case 'getMediaItems':
            final category = call.arguments as String?;
            return await _getMediaItems(category);
          case 'playFromMediaId':
            final mediaId = call.arguments as String?;
            if (mediaId != null) {
              await _playFromMediaId(mediaId);
            }
            return null;
          case 'getPlaylists':
            return _getPlaylists();
          default:
            return null;
        }
      } catch (e, st) {
        logError('CarPlay: Method call error: $e\n$st', tag: 'CarPlay');
        return null;
      }
    });
  }

  void _setupPlaybackListener() {
    // Listen to player state changes and send updates to CarPlay
    // when current song changes
    _ref.listen(playerProvider.select((s) => s.currentSong), (prev, next) {
      if (next != null) {
        _updateNowPlayingInfo();
      }
    });
  }

  void dispose() {
    _playbackSubscription?.cancel();
  }

  Future<List<Map<String, dynamic>>> _getMediaItems(String? category) async {
    final List<Song> songs;

    switch (category) {
      case MediaItemId.recentlyPlayed:
        songs = _ref.read(recentlyPlayedProvider);
      case MediaItemId.likedSongs:
        songs = _ref.read(libraryProvider).likedPlaylist.songs;
      case MediaItemId.downloads:
        songs = _ref.read(downloadServiceProvider).downloadedSongs;
      case MediaItemId.playlists:
        return _getPlaylists();
      default:
        // Return recently played as default
        songs = _ref.read(recentlyPlayedProvider);
    }

    return songs.map((song) => _songToMap(song)).toList();
  }

  List<Map<String, dynamic>> _getPlaylists() {
    final playlists = _ref.read(libraryProvider).playlists;
    return playlists
        .map((playlist) => {
              'id': '${MediaItemId.playlistPrefix}${playlist.id}',
              'title': playlist.name,
              'artist': '${playlist.songs.length} songs',
              'playable': false,
            })
        .toList();
  }

  Future<void> _playFromMediaId(String mediaId) async {
    Song? song;

    if (mediaId.startsWith(MediaItemId.playlistPrefix)) {
      final playlistId = mediaId.replaceFirst(MediaItemId.playlistPrefix, '');
      final libraryState = _ref.read(libraryProvider);
      LibraryPlaylist? playlist;
      for (final p in libraryState.playlists) {
        if (p.id == playlistId) {
          playlist = p;
          break;
        }
      }
      if (playlist != null && playlist.songs.isNotEmpty) {
        song = playlist.songs.first;
      }
    } else if (mediaId == MediaItemId.likedSongs) {
      final liked = _ref.read(libraryProvider).likedPlaylist.songs;
      if (liked.isNotEmpty) {
        song = liked.first;
      }
    } else if (mediaId == MediaItemId.downloads) {
      final downloads = _ref.read(downloadServiceProvider).downloadedSongs;
      if (downloads.isNotEmpty) {
        song = downloads.first;
      }
    } else if (mediaId == MediaItemId.recentlyPlayed) {
      final recent = _ref.read(recentlyPlayedProvider);
      if (recent.isNotEmpty) {
        song = recent.first;
      }
    } else {
      // Assume it's a song ID - search across all sources
      song = _findSongById(mediaId);
    }

    if (song != null) {
      await _ref.read(playerProvider.notifier).playSong(
            song,
            queueSource: 'carplay',
          );
    }
  }

  Song? _findSongById(String id) {
    // Search in liked songs
    final liked = _ref.read(libraryProvider).likedPlaylist.songs;
    for (final s in liked) {
      if (s.id == id) return s;
    }

    // Search in downloads
    final downloads = _ref.read(downloadServiceProvider).downloadedSongs;
    for (final s in downloads) {
      if (s.id == id) return s;
    }

    // Search in recently played
    final recent = _ref.read(recentlyPlayedProvider);
    for (final s in recent) {
      if (s.id == id) return s;
    }

    return null;
  }

  Map<String, dynamic> _songToMap(Song song) {
    return {
      'id': song.id,
      'title': song.title,
      'artist': song.artist,
      'artworkUrl': song.thumbnailUrl,
      'duration': song.duration.inSeconds,
      'playable': true,
    };
  }

  Future<void> _updateNowPlayingInfo() async {
    final playerState = _ref.read(playerProvider);
    final song = playerState.currentSong;
    if (song == null) return;

    try {
      await _channel.invokeMethod('updateNowPlaying', {
        'title': song.title,
        'artist': song.artist,
        'duration': song.duration.inSeconds,
        'elapsed': _ref.read(playbackPositionProvider).inSeconds,
        'isPlaying': playerState.isPlaying,
      });
    } catch (e) {
      // CarPlay might not be connected, ignore errors
      logDebug('CarPlay: Update now playing failed (not connected?): $e',
          tag: 'CarPlay');
    }
  }
}
