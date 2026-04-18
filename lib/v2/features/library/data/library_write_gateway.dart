import 'package:tunify/v2/core/network/tunify_api_client.dart';
import 'package:tunify/v2/features/library/data/library_playlist_list_mapper.dart';
import 'package:tunify/v2/features/library/domain/entities/library_item.dart';

class LibraryWriteGateway {
  LibraryWriteGateway({required TunifyApiClient api}) : _api = api;

  final TunifyApiClient _api;

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
      if (folderId != null && folderId.trim().isNotEmpty) 'folder_id': folderId.trim(),
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

  /// Appends a track to a **user-owned** Tunify playlist (`playlist_kind = user`).
  Future<void> addUserPlaylistTrack({
    required String playlistId,
    required String trackId,
    required String title,
    String? subtitle,
    String? artworkUrl,
    int? durationMs,
  }) async {
    await _api.postJson(
      '/v1/library/playlist/tracks',
      {
        'playlist_id': playlistId.trim(),
        'track_id': trackId.trim(),
        'title': title.trim(),
        if (subtitle != null && subtitle.trim().isNotEmpty) 'subtitle': subtitle.trim(),
        if (artworkUrl != null && artworkUrl.trim().isNotEmpty)
          'artwork_url': artworkUrl.trim(),
        if (durationMs != null) 'duration_ms': durationMs,
      },
      withAuth: true,
    );
  }

  /// Removes a track from a **user-owned** Tunify playlist.
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
