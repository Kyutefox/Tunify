import 'package:tunify/v2/core/network/tunify_api_client.dart';

/// Tunify `GET` / `POST /v1/library/collection` — saved albums, playlists, followed artists.
class LibraryCollectionGateway {
  LibraryCollectionGateway({required TunifyApiClient api}) : _api = api;

  final TunifyApiClient _api;

  Future<bool> fetchInLibrary({
    required String target,
    required String browseId,
  }) async {
    final map = await _api.getJson(
      '/v1/library/collection',
      withAuth: true,
      query: {
        'target': target,
        'browse_id': browseId,
      },
    );
    final v = map['in_library'];
    return v is bool ? v : false;
  }

  Future<bool> mutate({
    required String op,
    required String target,
    required String browseId,
    String? title,
    String? coverUrl,
    String? description,
  }) async {
    final body = <String, dynamic>{
      'op': op,
      'target': target,
      'browse_id': browseId,
      if (title != null && title.trim().isNotEmpty) 'title': title.trim(),
      if (coverUrl != null && coverUrl.trim().isNotEmpty)
        'cover_url': coverUrl.trim(),
      if (description != null && description.trim().isNotEmpty)
        'description': description.trim(),
    };
    final map = await _api.postJson(
      '/v1/library/collection',
      body,
      withAuth: true,
    );
    final v = map['in_library'];
    return v is bool ? v : false;
  }
}
