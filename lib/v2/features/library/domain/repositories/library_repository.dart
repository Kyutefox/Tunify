import 'package:tunify/v2/features/library/domain/entities/library_details.dart';
import 'package:tunify/v2/features/library/domain/entities/library_item.dart';

/// Library catalogue and collection detail access (data source agnostic).
abstract interface class LibraryRepository {
  List<LibraryItem> get libraryItems;

  LibraryDetailsModel detailsFor(LibraryItem item);
}
