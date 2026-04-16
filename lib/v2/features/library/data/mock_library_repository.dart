import 'package:tunify/v2/features/library/data/mock_library_data.dart';
import 'package:tunify/v2/features/library/data/mock_library_details_data.dart';
import 'package:tunify/v2/features/library/domain/entities/library_details.dart';
import 'package:tunify/v2/features/library/domain/entities/library_item.dart';
import 'package:tunify/v2/features/library/domain/repositories/library_repository.dart';

/// Mock implementation for v2 UI development.
final class MockLibraryRepository implements LibraryRepository {
  @override
  List<LibraryItem> get libraryItems => MockLibraryData.items;

  @override
  LibraryDetailsModel detailsFor(LibraryItem item) {
    return MockLibraryDetailsData.fromItem(item);
  }
}
