import 'package:flutter_test/flutter_test.dart';
import 'package:tunify/v2/features/library/domain/entities/library_item.dart';
import 'package:tunify/v2/features/library/domain/library_items_query.dart';
import 'package:tunify/v2/features/library/domain/library_known_creators.dart';

void main() {
  group('LibraryItemsQuery', () {
    final sample = <LibraryItem>[
      const LibraryItem(
        id: 'p1',
        title: 'Z Playlist',
        subtitle: 'Playlist',
        kind: LibraryItemKind.playlist,
        creatorName: LibraryKnownCreators.you,
        isUserOwnedPlaylist: true,
      ),
      const LibraryItem(
        id: 'p2',
        title: 'A Playlist',
        subtitle: 'Playlist',
        kind: LibraryItemKind.playlist,
        isRemoteCatalogPlaylist: true,
      ),
      const LibraryItem(
        id: 'p3',
        title: 'M Playlist',
        subtitle: 'Playlist',
        kind: LibraryItemKind.playlist,
        creatorName: LibraryKnownCreators.damon98,
        isUserOwnedPlaylist: true,
      ),
    ];

    test('byYou subfilter keeps You and Damon98 creators', () {
      final out = LibraryItemsQuery.apply(
        items: sample,
        filter: LibraryFilter.playlists,
        playlistSubFilter: LibraryPlaylistSubFilter.byYou,
        sortMode: LibrarySortMode.recents,
      );
      expect(out, hasLength(2));
      expect(out.map((e) => e.id).toSet(), {'p1', 'p3'});
    });

    test('folders filter keeps only folder rows', () {
      final mixed = <LibraryItem>[
        ...sample,
        const LibraryItem(
          id: 'f1',
          title: 'Mix',
          subtitle: 'Folder',
          kind: LibraryItemKind.folder,
          isInServerLibrary: true,
        ),
      ];
      final out = LibraryItemsQuery.apply(
        items: mixed,
        filter: LibraryFilter.folders,
        playlistSubFilter: LibraryPlaylistSubFilter.none,
        sortMode: LibrarySortMode.recents,
      );
      expect(out, hasLength(1));
      expect(out.single.id, 'f1');
    });

    test('bySpotify subfilter keeps only Spotify creator', () {
      final out = LibraryItemsQuery.apply(
        items: sample,
        filter: LibraryFilter.playlists,
        playlistSubFilter: LibraryPlaylistSubFilter.bySpotify,
        sortMode: LibrarySortMode.recents,
      );
      expect(out, hasLength(1));
      expect(out.single.id, 'p2');
    });

    test('alphabetical sort orders unpinned by title', () {
      final out = LibraryItemsQuery.apply(
        items: sample,
        filter: LibraryFilter.playlists,
        playlistSubFilter: LibraryPlaylistSubFilter.none,
        sortMode: LibrarySortMode.alphabetical,
      );
      expect(out.map((e) => e.title).toList(),
          ['A Playlist', 'M Playlist', 'Z Playlist']);
    });

    test(
        'all filter: pinned first in list order, then A–Z non-folders, then folders',
        () {
      final items = <LibraryItem>[
        const LibraryItem(
          id: 'f1',
          title: 'Zeta Folder',
          subtitle: 'Folder',
          kind: LibraryItemKind.folder,
          isInServerLibrary: true,
        ),
        const LibraryItem(
          id: 'p_mid',
          title: 'Bravo',
          subtitle: 'Playlist',
          kind: LibraryItemKind.playlist,
        ),
        const LibraryItem(
          id: 'p_pin',
          title: 'Zulu Pinned',
          subtitle: 'Playlist',
          kind: LibraryItemKind.playlist,
          isPinned: true,
        ),
        const LibraryItem(
          id: 'p_alpha',
          title: 'Alpha',
          subtitle: 'Playlist',
          kind: LibraryItemKind.playlist,
        ),
      ];
      final out = LibraryItemsQuery.apply(
        items: items,
        filter: LibraryFilter.all,
        playlistSubFilter: LibraryPlaylistSubFilter.none,
        sortMode: LibrarySortMode.alphabetical,
      );
      expect(out.map((e) => e.id).toList(), <String>[
        'p_pin',
        'p_alpha',
        'p_mid',
        'f1',
      ]);
    });

    test('pinned stack: older updatedAtMs above newer (append new pin below)', () {
      final items = <LibraryItem>[
        const LibraryItem(
          id: 'newer',
          title: 'B',
          subtitle: 'Playlist',
          kind: LibraryItemKind.playlist,
          isPinned: true,
          updatedAtMs: 300,
        ),
        const LibraryItem(
          id: 'older',
          title: 'A',
          subtitle: 'Playlist',
          kind: LibraryItemKind.playlist,
          isPinned: true,
          updatedAtMs: 100,
        ),
      ];
      final out = LibraryItemsQuery.apply(
        items: items,
        filter: LibraryFilter.all,
        playlistSubFilter: LibraryPlaylistSubFilter.none,
        sortMode: LibrarySortMode.alphabetical,
      );
      expect(out.map((e) => e.id).toList(), <String>['older', 'newer']);
    });
  });
}
