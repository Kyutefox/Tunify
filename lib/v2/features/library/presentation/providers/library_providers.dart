import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tunify/v2/features/library/data/mock_library_data.dart';
import 'package:tunify/v2/features/library/domain/entities/library_item.dart';

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

/// Derived provider: filtered + sorted library items.
final libraryItemsProvider = Provider<List<LibraryItem>>((ref) {
  final viewState = ref.watch(libraryControllerProvider);
  final allItems = MockLibraryData.items;

  final filtered = _applyFilter(
    allItems,
    viewState.filter,
    viewState.playlistSubFilter,
  );
  return _applySort(filtered, viewState.sortMode);
});

List<LibraryItem> _applyFilter(
  List<LibraryItem> items,
  LibraryFilter filter,
  LibraryPlaylistSubFilter subFilter,
) {
  var result = switch (filter) {
    LibraryFilter.all => items,
    LibraryFilter.playlists =>
      items.where((i) => i.kind == LibraryItemKind.playlist).toList(),
    LibraryFilter.artists =>
      items.where((i) => i.kind == LibraryItemKind.artist).toList(),
    LibraryFilter.albums =>
      items.where((i) => i.kind == LibraryItemKind.album).toList(),
    LibraryFilter.podcasts =>
      items.where((i) => i.kind == LibraryItemKind.podcast).toList(),
  };

  if (filter == LibraryFilter.playlists) {
    result = switch (subFilter) {
      LibraryPlaylistSubFilter.none => result,
      LibraryPlaylistSubFilter.byYou =>
        result.where((i) => i.creatorName == 'You' || i.creatorName == 'Damon98').toList(),
      LibraryPlaylistSubFilter.bySpotify =>
        result.where((i) => i.creatorName == 'Spotify').toList(),
    };
  }

  return result;
}

List<LibraryItem> _applySort(
  List<LibraryItem> items,
  LibrarySortMode mode,
) {
  final pinned = items.where((i) => i.isPinned).toList();
  final unpinned = List<LibraryItem>.from(
    items.where((i) => !i.isPinned),
  );

  switch (mode) {
    case LibrarySortMode.recents:
      break;
    case LibrarySortMode.recentlyAdded:
      final reversed = unpinned.reversed.toList();
      return [...pinned, ...reversed];
    case LibrarySortMode.alphabetical:
      unpinned.sort(
        (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()),
      );
    case LibrarySortMode.creator:
      unpinned.sort((a, b) {
        final ca = a.creatorName ?? a.title;
        final cb = b.creatorName ?? b.title;
        return ca.toLowerCase().compareTo(cb.toLowerCase());
      });
  }

  return [...pinned, ...unpinned];
}
