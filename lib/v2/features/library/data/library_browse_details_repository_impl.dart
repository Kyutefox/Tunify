import 'package:tunify/v2/core/network/tunify_api_client.dart';
import 'package:tunify/v2/features/library/data/library_browse_gateway.dart';
import 'package:tunify/v2/features/library/data/library_remote_details_mapper.dart';
import 'package:tunify/v2/features/library/domain/entities/library_details.dart';
import 'package:tunify/v2/features/library/domain/entities/library_item.dart';
import 'package:tunify/v2/features/library/domain/library_ytm_browse_kind.dart';
import 'package:tunify/v2/features/library/domain/repositories/library_browse_details_repository.dart';

/// [LibraryBrowseDetailsRepository] backed by [LibraryBrowseGateway] + browse mapper.
final class LibraryBrowseDetailsRepositoryImpl
    implements LibraryBrowseDetailsRepository {
  LibraryBrowseDetailsRepositoryImpl({required TunifyApiClient api})
      : _gateway = LibraryBrowseGateway(api: api);

  final LibraryBrowseGateway _gateway;

  static LibraryYtmBrowseKind _browseKind(LibraryItem item) {
    return switch (item.kind) {
      LibraryItemKind.artist => LibraryYtmBrowseKind.artist,
      LibraryItemKind.album => LibraryYtmBrowseKind.album,
      _ => LibraryYtmBrowseKind.playlist,
    };
  }

  @override
  Future<LibraryDetailsModel> loadDetailsForRemoteItem(LibraryItem item) async {
    final browseId = item.ytmBrowseId?.trim();
    if (browseId == null || browseId.isEmpty) {
      throw ArgumentError(
        'LibraryItem.ytmBrowseId must be set for remote browse details',
      );
    }
    final paramsRaw = item.ytmParams?.trim();
    final params = (paramsRaw == null || paramsRaw.isEmpty) ? null : paramsRaw;
    final loaded = await _gateway.loadFullCollection(
      browseKind: _browseKind(item),
      browseId: browseId,
      params: params,
    );
    return libraryDetailsFromRemoteBrowse(
      item: item,
      tracks: loaded.tracks,
      meta: loaded.meta,
    );
  }
}
