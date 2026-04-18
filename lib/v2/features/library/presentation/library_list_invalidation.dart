import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tunify/v2/features/library/presentation/providers/library_providers.dart';

/// Refreshes root and (optionally) one folder list after writes.
void invalidateLibraryListCaches(WidgetRef ref, {String? folderId}) {
  ref.invalidate(libraryRemoteItemsProvider(null));
  if (folderId != null && folderId.trim().isNotEmpty) {
    ref.invalidate(libraryRemoteItemsProvider(folderId.trim()));
  }
}
