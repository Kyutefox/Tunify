import 'package:tunify/v2/features/library/domain/entities/library_item.dart';
import 'package:tunify/v2/features/library/domain/library_known_creators.dart';

/// Pure filtering and sorting for library items (no UI / IO).
abstract final class LibraryItemsQuery {
  LibraryItemsQuery._();

  static List<LibraryItem> apply({
    required List<LibraryItem> items,
    required LibraryFilter filter,
    required LibraryPlaylistSubFilter playlistSubFilter,
    required LibrarySortMode sortMode,
  }) {
    final filtered = _filter(items, filter, playlistSubFilter);
    return _sort(filtered, sortMode);
  }

  static List<LibraryItem> _filter(
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
        LibraryPlaylistSubFilter.byYou => result
            .where(
              (i) =>
                  i.creatorName == LibraryKnownCreators.you ||
                  i.creatorName == LibraryKnownCreators.damon98,
            )
            .toList(),
        LibraryPlaylistSubFilter.bySpotify => result
            .where((i) => i.creatorName == LibraryKnownCreators.spotify)
            .toList(),
      };
    }

    return result;
  }

  static List<LibraryItem> _sort(
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
}
