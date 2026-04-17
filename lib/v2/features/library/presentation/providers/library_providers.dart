import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tunify/v2/core/errors/failures.dart';
import 'package:tunify/v2/core/utils/image_palette_extractor.dart';
import 'package:tunify/v2/core/utils/logger.dart';
import 'package:tunify/v2/features/auth/presentation/providers/auth_providers.dart';
import 'package:tunify/v2/features/library/data/library_browse_details_repository_impl.dart';
import 'package:tunify/v2/features/library/data/mock_library_repository.dart';
import 'package:tunify/v2/features/library/domain/entities/library_details.dart';
import 'package:tunify/v2/features/library/domain/entities/library_item.dart';
import 'package:tunify/v2/features/library/domain/library_detail_palette_source.dart';
import 'package:tunify/v2/features/library/domain/library_detail_request.dart';
import 'package:tunify/v2/features/library/domain/library_items_query.dart';
import 'package:tunify/v2/features/library/domain/repositories/library_browse_details_repository.dart';
import 'package:tunify/v2/features/library/domain/repositories/library_repository.dart';
import 'package:tunify/v2/features/library/presentation/constants/library_strings.dart';

/// Immutable view-state for the library screen.
@immutable
class LibraryViewState {
  const LibraryViewState({
    this.filter = LibraryFilter.all,
    this.playlistSubFilter = LibraryPlaylistSubFilter.none,
    this.viewMode = LibraryViewMode.list,
    this.sortMode = LibrarySortMode.recents,
  });

  final LibraryFilter filter;
  final LibraryPlaylistSubFilter playlistSubFilter;
  final LibraryViewMode viewMode;
  final LibrarySortMode sortMode;

  LibraryViewState copyWith({
    LibraryFilter? filter,
    LibraryPlaylistSubFilter? playlistSubFilter,
    LibraryViewMode? viewMode,
    LibrarySortMode? sortMode,
  }) {
    return LibraryViewState(
      filter: filter ?? this.filter,
      playlistSubFilter: playlistSubFilter ?? this.playlistSubFilter,
      viewMode: viewMode ?? this.viewMode,
      sortMode: sortMode ?? this.sortMode,
    );
  }
}

/// Business logic for library filtering, sorting, and view toggling.
class LibraryController extends Notifier<LibraryViewState> {
  @override
  LibraryViewState build() => const LibraryViewState();

  void setFilter(LibraryFilter filter) {
    if (state.filter == filter) {
      state = state.copyWith(
        filter: LibraryFilter.all,
        playlistSubFilter: LibraryPlaylistSubFilter.none,
      );
      return;
    }
    state = state.copyWith(
      filter: filter,
      playlistSubFilter: LibraryPlaylistSubFilter.none,
    );
  }

  void clearFilter() {
    state = state.copyWith(
      filter: LibraryFilter.all,
      playlistSubFilter: LibraryPlaylistSubFilter.none,
    );
  }

  void setPlaylistSubFilter(LibraryPlaylistSubFilter sub) {
    if (sub == state.playlistSubFilter) {
      state = state.copyWith(playlistSubFilter: LibraryPlaylistSubFilter.none);
      return;
    }
    state = state.copyWith(playlistSubFilter: sub);
  }

  void toggleViewMode() {
    final next = state.viewMode == LibraryViewMode.list
        ? LibraryViewMode.grid
        : LibraryViewMode.list;
    state = state.copyWith(viewMode: next);
  }

  void setSortMode(LibrarySortMode mode) {
    state = state.copyWith(sortMode: mode);
  }
}

final libraryControllerProvider =
    NotifierProvider<LibraryController, LibraryViewState>(
  LibraryController.new,
);

/// Data access for library lists and detail models (swap implementation for real API).
final libraryRepositoryProvider = Provider<LibraryRepository>((ref) {
  return MockLibraryRepository();
});

/// Derived provider: filtered + sorted library items.
final libraryItemsProvider = Provider<List<LibraryItem>>((ref) {
  final viewState = ref.watch(libraryControllerProvider);
  final allItems = ref.watch(libraryRepositoryProvider).libraryItems;
  return LibraryItemsQuery.apply(
    items: allItems,
    filter: viewState.filter,
    playlistSubFilter: viewState.playlistSubFilter,
    sortMode: viewState.sortMode,
  );
});

/// Tunify browse-backed collection details (mock list repo stays separate).
final libraryBrowseDetailsRepositoryProvider =
    Provider<LibraryBrowseDetailsRepository>((ref) {
  return LibraryBrowseDetailsRepositoryImpl(
    api: ref.watch(tunifyApiClientProvider),
  );
});

Future<LibraryDetailsModel> _libraryDetailsWithResolvedPalette(
  LibraryDetailsModel details,
  LibraryItem item,
) async {
  try {
    final url = libraryDetailPaletteSourceUrl(item: item, details: details);
    if (url == null) {
      return details;
    }
    final palette = await ImagePaletteExtractor.fromNetworkUrl(url);
    if (palette == null) {
      return details;
    }
    return details.withBackgroundPalette(
      gradientTop: palette.gradientTop,
      backgroundGradientMid: palette.gradientMid,
    );
  } on Object catch (e, st) {
    Logger.error(
      'Palette resolution failed; using default gradient',
      tag: 'LibraryDetails',
      error: e,
      stackTrace: st,
    );
    return details;
  }
}

/// Mock details, or Tunify browse-backed details when [LibraryItem.ytmBrowseId] is set.
///
/// When a palette source URL exists, extraction runs before the future completes so the
/// first painted frame already uses artwork-derived gradients (no late palette flash).
final libraryDetailsProvider = FutureProvider.autoDispose
    .family<LibraryDetailsModel, LibraryDetailRequest>((ref, request) async {
  final item = request.item;
  final browseId = item.ytmBrowseId?.trim();
  final LibraryDetailsModel details;
  if (browseId == null || browseId.isEmpty) {
    details = ref.read(libraryRepositoryProvider).detailsFor(item);
  } else {
    try {
      details = await ref
          .read(libraryBrowseDetailsRepositoryProvider)
          .loadDetails(item);
    } on Object catch (e, st) {
      Logger.error(
        'Library browse failed',
        tag: 'LibraryDetails',
        error: e,
        stackTrace: st,
      );
      throw NetworkFailure(LibraryStrings.collectionDetailsLoadError);
    }
  }

  return _libraryDetailsWithResolvedPalette(details, item);
});
