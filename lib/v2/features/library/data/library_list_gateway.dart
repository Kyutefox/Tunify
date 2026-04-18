import 'package:tunify/v2/core/network/tunify_api_client.dart';
import 'package:tunify/v2/features/library/data/library_playlist_list_mapper.dart';
import 'package:tunify/v2/features/library/domain/entities/library_item.dart';

/// Fetches library rows from `GET /v1/library/playlists` (root or folder scope).
class LibraryListGateway {
  LibraryListGateway({required TunifyApiClient api}) : _api = api;

  final TunifyApiClient _api;

  Future<List<LibraryItem>> fetchLibraryItems({String? folderId}) async {
    final query = (folderId != null && folderId.trim().isNotEmpty)
        ? {'folder_id': folderId.trim()}
        : null;
    final map = await _api.getJson(
      '/v1/library/playlists',
      withAuth: true,
      query: query,
    );
    return LibraryPlaylistListMapper.parseLibraryPayload(map);
  }
}
