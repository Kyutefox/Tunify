import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tunify/v2/features/library/data/mock_library_repository.dart';
import 'package:tunify/v2/features/library/domain/entities/library_item.dart';
import 'package:tunify/v2/features/library/domain/library_items_query.dart';
import 'package:tunify/v2/features/library/domain/repositories/library_repository.dart';

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
    if (filter == state.filter) {
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
