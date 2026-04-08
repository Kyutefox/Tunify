import 'package:flutter_test/flutter_test.dart';
import 'package:tunify/data/models/library_folder.dart';
import 'package:tunify/data/models/library_playlist.dart';
import 'package:tunify/data/models/song.dart';
import 'package:tunify/features/library/library_provider.dart';

Song _song(String id) => Song(
      id: id,
      title: 'Track $id',
      artist: 'Artist',
      thumbnailUrl: '',
      duration: const Duration(minutes: 3),
    );

LibraryPlaylist _playlist({
  required String id,
  required String name,
  bool isPinned = false,
  DateTime? createdAt,
  DateTime? updatedAt,
}) {
  final fallback = DateTime(2024, 1, 1);
  return LibraryPlaylist(
    id: id,
    name: name,
    createdAt: createdAt ?? fallback,
    updatedAt: updatedAt ?? fallback,
    isPinned: isPinned,
  );
}

LibraryFolder _folder({
  required String id,
  required String name,
  bool isPinned = false,
}) {
  return LibraryFolder(
    id: id,
    name: name,
    createdAt: DateTime(2024, 1, 1),
    isPinned: isPinned,
  );
}

void main() {
  group('LibraryState.sortedPlaylists', () {
    test('sorts alphabetically', () {
      final state = LibraryState(
        playlists: [
          _playlist(id: '1', name: 'Zebra'),
          _playlist(id: '2', name: 'Apple'),
          _playlist(id: '3', name: 'Mango'),
        ],
        sortOrder: LibrarySortOrder.alphabetical,
      );
      final names = state.sortedPlaylists.map((p) => p.name).toList();
      expect(names, ['Apple', 'Mango', 'Zebra']);
    });

    test('sorts by most recently updated (recent)', () {
      final state = LibraryState(
        playlists: [
          _playlist(id: '1', name: 'Oldest', updatedAt: DateTime(2024, 1, 1)),
          _playlist(id: '2', name: 'Newest', updatedAt: DateTime(2024, 3, 1)),
          _playlist(id: '3', name: 'Middle', updatedAt: DateTime(2024, 2, 1)),
        ],
        sortOrder: LibrarySortOrder.recent,
      );
      final ids = state.sortedPlaylists.map((p) => p.id).toList();
      expect(ids, ['2', '3', '1']);
    });

    test('sorts by most recently created (recentlyAdded)', () {
      final state = LibraryState(
        playlists: [
          _playlist(id: '1', name: 'Old', createdAt: DateTime(2024, 1, 1)),
          _playlist(id: '2', name: 'New', createdAt: DateTime(2024, 3, 1)),
          _playlist(id: '3', name: 'Mid', createdAt: DateTime(2024, 2, 1)),
        ],
        sortOrder: LibrarySortOrder.recentlyAdded,
      );
      final ids = state.sortedPlaylists.map((p) => p.id).toList();
      expect(ids, ['2', '3', '1']);
    });

    test('filters by searchQuery (case-insensitive)', () {
      final state = LibraryState(
        playlists: [
          _playlist(id: '1', name: 'Rock Classics'),
          _playlist(id: '2', name: 'Jazz Vibes'),
          _playlist(id: '3', name: 'ROCK Anthems'),
        ],
        sortOrder: LibrarySortOrder.alphabetical,
        searchQuery: 'rock',
      );
      final ids = state.sortedPlaylists.map((p) => p.id).toList();
      expect(ids, containsAll(['1', '3']));
      expect(ids, isNot(contains('2')));
    });

    test('whitespace-only searchQuery shows all playlists', () {
      final state = LibraryState(
        playlists: [
          _playlist(id: '1', name: 'A'),
          _playlist(id: '2', name: 'B'),
        ],
        sortOrder: LibrarySortOrder.alphabetical,
        searchQuery: '   ',
      );
      expect(state.sortedPlaylists.length, 2);
    });
  });

  group('LibraryState.sortedFolders', () {
    test('always sorts alphabetically', () {
      final state = LibraryState(
        folders: [
          _folder(id: '1', name: 'Zebra'),
          _folder(id: '2', name: 'Apple'),
          _folder(id: '3', name: 'Mango'),
        ],
      );
      final names = state.sortedFolders.map((f) => f.name).toList();
      expect(names, ['Apple', 'Mango', 'Zebra']);
    });

    test('pinned folders appear first', () {
      final state = LibraryState(
        folders: [
          _folder(id: '1', name: 'Alpha'),
          _folder(id: '2', name: 'Beta', isPinned: true),
          _folder(id: '3', name: 'Gamma'),
        ],
      );
      expect(state.sortedFolders.first.id, '2');
    });

    test('filters by searchQuery', () {
      final state = LibraryState(
        folders: [
          _folder(id: '1', name: 'Work Music'),
          _folder(id: '2', name: 'Chill'),
          _folder(id: '3', name: 'Workout'),
        ],
        searchQuery: 'work',
      );
      final ids = state.sortedFolders.map((f) => f.id).toSet();
      expect(ids, containsAll(['1', '3']));
      expect(ids, isNot(contains('2')));
    });
  });

  group('LibraryState.likedSongIds', () {
    test('contains IDs of all liked songs', () {
      final state = LibraryState(playlists: [
        LibraryPlaylist(
          id: 'liked',
          name: 'Liked Songs',
          createdAt: DateTime(2024),
          updatedAt: DateTime(2024),
          songs: [_song('s1'), _song('s2'), _song('s3')],
        ),
      ]);
      expect(state.likedSongIds, {'s1', 's2', 's3'});
    });

    test('returns empty set when no liked songs', () {
      final state = LibraryState();
      expect(state.likedSongIds, isEmpty);
    });

    test('membership test is O(1) and correct', () {
      final state = LibraryState(playlists: [
        LibraryPlaylist(
          id: 'liked',
          name: 'Liked Songs',
          createdAt: DateTime(2024),
          updatedAt: DateTime(2024),
          songs: [_song('s1')],
        ),
      ]);
      expect(state.likedSongIds.contains('s1'), isTrue);
      expect(state.likedSongIds.contains('s99'), isFalse);
    });
  });

  group('LibrarySortOrder serialization', () {
    test('value round-trips through fromString', () {
      for (final order in LibrarySortOrder.values) {
        expect(LibrarySortOrderX.fromString(order.value), order);
      }
    });

    test('unknown string defaults to recent', () {
      expect(LibrarySortOrderX.fromString('unknown'), LibrarySortOrder.recent);
    });
  });

  group('LibraryViewMode serialization', () {
    test('value round-trips through fromString', () {
      for (final mode in LibraryViewMode.values) {
        expect(LibraryViewModeX.fromString(mode.value), mode);
      }
    });
  });
}
