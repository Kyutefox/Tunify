import 'package:tunify/v2/features/library/domain/entities/library_details.dart';
import 'package:tunify/v2/features/library/domain/entities/library_item.dart';

/// Remote collection details loaded via Tunify browse (implementation in `data/`).
abstract interface class LibraryBrowseDetailsRepository {
  /// Loads details for [item] using [LibraryItem.ytmBrowseId] (must be non-empty).
  Future<LibraryDetailsModel> loadDetailsForRemoteItem(LibraryItem item);
}
