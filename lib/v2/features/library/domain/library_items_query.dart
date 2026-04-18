import 'package:tunify/v2/features/library/domain/entities/library_item.dart';
import 'package:tunify/v2/features/library/domain/library_known_creators.dart';

/// Pure filtering and sorting for library items (no UI / IO).
abstract final class LibraryItemsQuery {
  LibraryItemsQuery._();

  static bool _playlistIsByYou(LibraryItem i) {
    return i.systemArtwork != null ||
        i.isUserOwnedPlaylist ||
        i.creatorName == LibraryKnownCreators.you ||
        i.creatorName == LibraryKnownCreators.damon98;
  }

  /// Public for folder drill-in ("By you" pill) and other UI.
  static bool playlistIsByYou(LibraryItem i) => _playlistIsByYou(i);

  static bool _playlistIsEditorialRemote(LibraryItem i) {
    return i.isRemoteCatalogPlaylist ||
        i.creatorName == LibraryKnownCreators.spotify;
  }

  static List<LibraryItem> apply({
    required List<LibraryItem> items,
    required LibraryFilter filter,
    required LibraryPlaylistSubFilter playlistSubFilter,
    required LibrarySortMode sortMode,
  }) {
    final filtered = _filter(items, filter, playlistSubFilter);
    if (filter == LibraryFilter.all) {
      return _sortAllNoCategoryFilter(filtered, sortMode);
    }
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
      LibraryFilter.folders =>
        items.where((i) => i.kind == LibraryItemKind.folder).toList(),
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
        LibraryPlaylistSubFilter.byYou => result.where(_playlistIsByYou).toList(),
        LibraryPlaylistSubFilter.bySpotify =>
          result.where(_playlistIsEditorialRemote).toList(),
      };
    }

    return result;
  }

  /// "Your Library" with no category pill: pinned first (stack order, ignores sort mode),
  /// then unpinned non-folders (sorted), then unpinned folders (sorted).
  static List<LibraryItem> _sortAllNoCategoryFilter(
    List<LibraryItem> items,
    LibrarySortMode mode,
  ) {
    final pinned = items.where((i) => i.isPinned).toList();
    _sortPinnedAppendOrder(pinned);

    final unpinnedNonFolders = items
        .where((i) => !i.isPinned && i.kind != LibraryItemKind.folder)
        .toList();
    _sortUnpinnedSubsetInPlace(unpinnedNonFolders, mode);

    final unpinnedFolders = items
        .where((i) => !i.isPinned && i.kind == LibraryItemKind.folder)
        .toList();
    _sortUnpinnedSubsetInPlace(unpinnedFolders, mode);

    return [...pinned, ...unpinnedNonFolders, ...unpinnedFolders];
  }

  static List<LibraryItem> _sort(
    List<LibraryItem> items,
    LibrarySortMode mode,
  ) {
    final pinned = items.where((i) => i.isPinned).toList();
    _sortPinnedAppendOrder(pinned);
    final unpinned = List<LibraryItem>.from(
      items.where((i) => !i.isPinned),
    );
    _sortUnpinnedSubsetInPlace(unpinned, mode);
    return [...pinned, ...unpinned];
  }

  /// Pinned stack: static system shelves first, then by [LibraryItem.updatedAtMs]
  /// ascending so a **new** pin (larger `updated_at_ms` from the server) appears **below**
  /// items pinned earlier.
  static void _sortPinnedAppendOrder(List<LibraryItem> pinned) {
    pinned.sort(_comparePinnedStackOrder);
  }

  static int _comparePinnedStackOrder(LibraryItem a, LibraryItem b) {
    final aSystem = a.systemArtwork != null;
    final bSystem = b.systemArtwork != null;
    if (aSystem != bSystem) {
      return aSystem ? -1 : 1;
    }
    final byT = a.updatedAtMs.compareTo(b.updatedAtMs);
    if (byT != 0) {
      return byT;
    }
    return a.id.compareTo(b.id);
  }

  static void _sortUnpinnedSubsetInPlace(
    List<LibraryItem> unpinned,
    LibrarySortMode mode,
  ) {
    switch (mode) {
      case LibrarySortMode.recents:
        break;
      case LibrarySortMode.recentlyAdded:
        final reversed = unpinned.reversed.toList();
        unpinned
          ..clear()
          ..addAll(reversed);
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
  }

  /// Folder contents: no category filter; apply sort only.
  static List<LibraryItem> applyFolderContents({
    required List<LibraryItem> items,
    required LibrarySortMode sortMode,
  }) {
    return _sort(items, sortMode);
  }

  /// Client-side search over already-fetched library rows.
  static List<LibraryItem> filterItemsBySearchQuery(
    List<LibraryItem> items,
    String query,
  ) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) {
      return List<LibraryItem>.from(items);
    }
    return items.where((i) {
      if (i.title.toLowerCase().contains(q)) {
        return true;
      }
      if (i.subtitle.toLowerCase().contains(q)) {
        return true;
      }
      final c = i.creatorName?.toLowerCase();
      return c != null && c.contains(q);
    }).toList();
  }
}
