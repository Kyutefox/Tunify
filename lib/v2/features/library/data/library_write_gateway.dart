import 'package:tunify/v2/core/network/tunify_api_client.dart';
import 'package:tunify/v2/features/library/data/library_playlist_list_mapper.dart';
import 'package:tunify/v2/features/library/domain/entities/library_details.dart';
import 'package:tunify/v2/features/library/domain/entities/library_item.dart';

class LibraryWriteGateway {
  LibraryWriteGateway({required TunifyApiClient api}) : _api = api;

  final TunifyApiClient _api;

  String? _trailingFromDurationMs(Object? v) {
    if (v == null) {
      return null;
    }
    final ms = v is int ? v : (v as num).toInt();
    if (ms <= 0) {
      return null;
    }
    final totalSec = ms ~/ 1000;
    final m = totalSec ~/ 60;
    final s = totalSec % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  Future<Map<String, dynamic>> createFolder({required String name}) async {
    return _api.postJson(
      '/v1/library/folder',
      {'name': name},
      withAuth: true,
    );
  }

  Future<Map<String, dynamic>> createUserPlaylist({
    required String name,
    String? description,
    String? folderId,
  }) async {
    final body = <String, dynamic>{
      'name': name,
      if (description != null && description.trim().isNotEmpty)
        'description': description.trim(),
      if (folderId != null && folderId.trim().isNotEmpty)
        'folder_id': folderId.trim(),
    };
    return _api.postJson('/v1/library/playlist', body, withAuth: true);
  }

  /// Sets `is_pinned` on a `tunify_playlist` row or a library folder. Exactly one id must be set.
  Future<void> setLibraryPin({
    String? playlistId,
    String? folderId,
    required bool pinned,
  }) async {
    final pid = playlistId?.trim();
    final fid = folderId?.trim();
    final body = <String, dynamic>{
      'pinned': pinned,
      if (pid != null && pid.isNotEmpty) 'playlist_id': pid,
      if (fid != null && fid.isNotEmpty) 'folder_id': fid,
    };
    await _api.postJson('/v1/library/pin', body, withAuth: true);
  }

  Future<void> addPlaylistToFolder({
    required String folderId,
    required String playlistId,
  }) async {
    await _api.postJson(
      '/v1/library/folder/members',
      {
        'folder_id': folderId.trim(),
        'playlist_id': playlistId.trim(),
      },
      withAuth: true,
    );
  }

  /// Parses `item` from `CreateUserPlaylistResponse`.
  LibraryItem playlistItemFromCreateResponse(Map<String, dynamic> map) {
    final inner = map['item'];
    if (inner is! Map<String, dynamic>) {
      throw const FormatException('Missing item in create playlist response');
    }
    return LibraryPlaylistListMapper.playlistFromJson(inner);
  }

  /// Parses `folder` from `CreateLibraryFolderResponse`.
  LibraryItem folderItemFromCreateResponse(Map<String, dynamic> map) {
    final inner = map['folder'];
    if (inner is! Map<String, dynamic>) {
      throw const FormatException('Missing folder in create folder response');
    }
    return LibraryPlaylistListMapper.folderFromJson(inner);
  }

  /// Deletes a user-created playlist (`playlist_kind` user).
  Future<void> deleteUserPlaylist({required String playlistId}) async {
    await _api.deleteJson(
      '/v1/library/playlist',
      withAuth: true,
      query: {'playlist_id': playlistId.trim()},
    );
  }

  /// Deletes a library folder (playlists inside remain on the server).
  Future<void> deleteFolder({required String folderId}) async {
    await _api.deleteJson(
      '/v1/library/folder',
      withAuth: true,
      query: {'folder_id': folderId.trim()},
    );
  }

  /// Loads ordered tracks for a **user-owned** or **liked songs** playlist (`GET /v1/library/playlist/tracks`).
  Future<List<LibraryDetailsTrack>> fetchPlaylistTracks({
    required String playlistId,
  }) async {
    final map = await _api.getJson(
      '/v1/library/playlist/tracks',
      withAuth: true,
      query: {'playlist_id': playlistId.trim()},
    );
    final raw = map['tracks'];
    if (raw is! List<dynamic>) {
      return const [];
    }
    final out = <LibraryDetailsTrack>[];
    for (final e in raw.whereType<Map<String, dynamic>>()) {
      final id = (e['track_id'] as String?)?.trim() ?? '';
      if (id.isEmpty) {
        continue;
      }
      final title = (e['title'] as String?)?.trim() ?? 'Unknown';
      final sub = (e['subtitle'] as String?)?.trim() ?? '';
      final art = (e['artwork_url'] as String?)?.trim();
      final description = (e['description'] as String?)?.trim();
      final durationMs = e['duration_ms'] == null
          ? null
          : (e['duration_ms'] is int
              ? e['duration_ms'] as int
              : (e['duration_ms'] as num).toInt());
      final artistBrowseId = (e['artist_browse_id'] as String?)?.trim();
      final artistBrowseIds =
          (e['artist_browse_ids'] as List<dynamic>? ?? const [])
              .whereType<String>()
              .map((id) => id.trim())
              .where((id) => id.isNotEmpty)
              .toList(growable: false);
      final albumBrowseId = (e['album_browse_id'] as String?)?.trim();
      out.add(
        LibraryDetailsTrack(
          title: title,
          subtitle: sub,
          trailingValue: _trailingFromDurationMs(durationMs),
          thumbUrl: art == null || art.isEmpty ? null : art,
          videoId: id,
          durationMs: durationMs,
          artistBrowseId: artistBrowseId == null || artistBrowseId.isEmpty
              ? null
              : artistBrowseId,
          artistBrowseIds: artistBrowseIds,
          albumBrowseId: albumBrowseId == null || albumBrowseId.isEmpty
              ? null
              : albumBrowseId,
          description:
              description == null || description.isEmpty ? null : description,
        ),
      );
    }
    return out;
  }

  /// Playlist ids (user-owned + liked) that contain [trackId].
  Future<Set<String>> fetchTrackPlaylistMemberships({
    required String trackId,
  }) async {
    final map = await _api.getJson(
      '/v1/library/track/playlist_memberships',
      withAuth: true,
      query: {'track_id': trackId.trim()},
    );
    final raw = map['playlist_ids'];
    if (raw is! List<dynamic>) {
      return const {};
    }
    return raw
        .map((e) => e is String ? e.trim() : '')
        .where((s) => s.isNotEmpty)
        .toSet();
  }

  /// Whether [trackId] is present in the user's liked songs playlist.
  Future<bool> fetchTrackLiked({required String trackId}) async {
    final map = await _api.getJson(
      '/v1/library/liked/status',
      withAuth: true,
      query: {'track_id': trackId.trim()},
    );
    return map['liked'] == true;
  }

  /// Appends a track to a **user-owned** or **liked songs** Tunify playlist.
  Future<void> addUserPlaylistTrack({
    required String playlistId,
    required String trackId,
    required String title,
    String? subtitle,
    String? description,
    String? artworkUrl,
    int? durationMs,
    List<String> artistBrowseIds = const [],
    String? albumBrowseId,
  }) async {
    final normalizedArtistBrowseIds = artistBrowseIds
        .map((id) => id.trim())
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList(growable: false);
    final normalizedAlbumBrowseId = albumBrowseId?.trim();
    await _api.postJson(
      '/v1/library/playlist/tracks',
      {
        'playlist_id': playlistId.trim(),
        'track_id': trackId.trim(),
        'title': title.trim(),
        if (subtitle != null && subtitle.trim().isNotEmpty)
          'subtitle': subtitle.trim(),
        if (description != null && description.trim().isNotEmpty)
          'description': description.trim(),
        if (artworkUrl != null && artworkUrl.trim().isNotEmpty)
          'artwork_url': artworkUrl.trim(),
        if (durationMs != null) 'duration_ms': durationMs,
        if (normalizedArtistBrowseIds.isNotEmpty)
          'artist_browse_ids': normalizedArtistBrowseIds,
        if (normalizedAlbumBrowseId != null &&
            normalizedAlbumBrowseId.isNotEmpty)
          'album_browse_id': normalizedAlbumBrowseId,
      },
      withAuth: true,
    );
  }

  /// Removes a track from a **user-owned** or **liked songs** Tunify playlist.
  Future<void> removeUserPlaylistTrack({
    required String playlistId,
    required String trackId,
  }) async {
    await _api.deleteJson(
      '/v1/library/playlist/tracks',
      withAuth: true,
      query: {
        'playlist_id': playlistId.trim(),
        'track_id': trackId.trim(),
      },
    );
  }
}
