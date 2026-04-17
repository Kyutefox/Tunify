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
      ),
      const LibraryItem(
        id: 'p2',
        title: 'A Playlist',
        subtitle: 'Playlist',
        kind: LibraryItemKind.playlist,
        creatorName: LibraryKnownCreators.spotify,
      ),
      const LibraryItem(
        id: 'p3',
        title: 'M Playlist',
        subtitle: 'Playlist',
        kind: LibraryItemKind.playlist,
        creatorName: LibraryKnownCreators.damon98,
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
  });
}
