import 'package:tunify/v2/core/network/tunify_api_client.dart';
import 'package:tunify/v2/features/library/data/library_browse_gateway.dart';
import 'package:tunify/v2/features/library/data/library_details_mapper.dart';
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
      LibraryItemKind.podcast => LibraryYtmBrowseKind.podcast,
      _ => LibraryYtmBrowseKind.playlist,
    };
  }

  @override
  Future<LibraryDetailsModel> loadDetails(LibraryItem item) async {
    if (item.ytmBrowseId == null || item.ytmBrowseId!.isEmpty) {
      throw ArgumentError(
        'LibraryItem.ytmBrowseId must be set for browse details',
      );
    }
    final browseKind = _browseKind(item);
    final browseData = await _gateway.loadFullCollection(
      browseKind: browseKind,
      browseId: item.ytmBrowseId!,
      params: item.ytmParams,
    );
    return libraryDetailsFromBrowse(
      item: item,
      tracks: browseData.tracks,
      meta: browseData.meta,
      browseRecommendationShelves: browseData.recommendationShelves,
    );
  }
}
