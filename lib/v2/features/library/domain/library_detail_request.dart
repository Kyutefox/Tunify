import 'package:flutter/foundation.dart';
import 'package:tunify/v2/features/library/domain/entities/library_item.dart';

/// Stable key for [libraryDetailsProvider] (supports items not present in the mock repo).
@immutable
final class LibraryDetailRequest {
  const LibraryDetailRequest(this.item);

  final LibraryItem item;

  @override
  bool operator ==(Object other) {
    return other is LibraryDetailRequest &&
        item.id == other.item.id &&
        item.ytmBrowseId == other.item.ytmBrowseId &&
        item.title == other.item.title &&
        item.kind == other.item.kind;
  }

  @override
  int get hashCode =>
      Object.hash(item.id, item.ytmBrowseId, item.title, item.kind);
}
