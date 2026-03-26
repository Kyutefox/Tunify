import 'package:flutter_test/flutter_test.dart';
import 'package:tunify/data/models/library_playlist.dart';
import 'package:tunify/data/models/song.dart';

Song _song(String id, String title) => Song(
      id: id,
      title: title,
      artist: 'Test Artist',
      thumbnailUrl: 'https://example.com/thumb.jpg',
      duration: const Duration(minutes: 3),
    );

LibraryPlaylist _playlist({
  String id = 'p1',
  String name = 'Test Playlist',
  List<Song>? songs,
  PlaylistTrackSortOrder sortOrder = PlaylistTrackSortOrder.customOrder,
  bool isPinned = false,
}) {
  final now = DateTime(2024, 1, 1);
  return LibraryPlaylist(
    id: id,
    name: name,
    createdAt: now,
    updatedAt: now,
    songs: songs ?? [],
    sortOrder: sortOrder,
    isPinned: isPinned,
  );
}

void main() {
  group('LibraryPlaylist', () {
    group('sortedSongs', () {
      test('customOrder returns original insertion order', () {
        final songs = [_song('1', 'Zebra'), _song('2', 'Apple'), _song('3', 'Mango')];
        final p = _playlist(songs: songs, sortOrder: PlaylistTrackSortOrder.customOrder);
        expect(p.sortedSongs.map((s) => s.id).toList(), ['1', '2', '3']);
      });

      test('title sorts alphabetically case-insensitively', () {
        final songs = [_song('1', 'Zebra'), _song('2', 'apple'), _song('3', 'Mango')];
        final p = _playlist(songs: songs, sortOrder: PlaylistTrackSortOrder.title);
        expect(p.sortedSongs.map((s) => s.title).toList(), ['apple', 'Mango', 'Zebra']);
      });

      test('recentlyAdded reverses insertion order', () {
        final songs = [_song('1', 'First'), _song('2', 'Second'), _song('3', 'Third')];
        final p = _playlist(songs: songs, sortOrder: PlaylistTrackSortOrder.recentlyAdded);
        expect(p.sortedSongs.map((s) => s.id).toList(), ['3', '2', '1']);
      });

      test('sortedSongs does not mutate original songs list', () {
        final songs = [_song('1', 'Zebra'), _song('2', 'Apple')];
        final p = _playlist(songs: songs, sortOrder: PlaylistTrackSortOrder.title);
        final sorted = p.sortedSongs;
        sorted.clear();
        expect(p.songs.length, 2);
      });
    });

    group('trackCountLabel', () {
      test('returns "1 song" for single track', () {
        final p = _playlist(songs: [_song('1', 'Solo')]);
        expect(p.trackCountLabel, '1 song');
      });

      test('returns "N songs" for multiple tracks', () {
        final p = _playlist(songs: [_song('1', 'A'), _song('2', 'B')]);
        expect(p.trackCountLabel, '2 songs');
      });

      test('returns "0 songs" for empty playlist', () {
        final p = _playlist(songs: []);
        expect(p.trackCountLabel, '0 songs');
      });
    });

    group('JSON serialization', () {
      test('toJson / fromJson round-trip preserves all fields', () {
        final songs = [_song('s1', 'Track One')];
        final original = LibraryPlaylist(
          id: 'p42',
          name: 'My Playlist',
          description: 'A description',
          createdAt: DateTime.utc(2024, 6, 1),
          updatedAt: DateTime.utc(2024, 6, 2),
          songs: songs,
          sortOrder: PlaylistTrackSortOrder.title,
          shuffleEnabled: true,
          isPinned: true,
          customImageUrl: 'https://example.com/cover.jpg',
        );
        final decoded = LibraryPlaylist.fromJson(original.toJson());
        expect(decoded.id, original.id);
        expect(decoded.name, original.name);
        expect(decoded.description, original.description);
        expect(decoded.sortOrder, original.sortOrder);
        expect(decoded.shuffleEnabled, original.shuffleEnabled);
        expect(decoded.isPinned, original.isPinned);
        expect(decoded.customImageUrl, original.customImageUrl);
        expect(decoded.songs.length, 1);
        expect(decoded.songs.first.id, 's1');
      });

      test('missing optional fields use defaults', () {
        final json = {
          'id': 'p1',
          'name': 'Minimal',
          'createdAt': DateTime.utc(2024).toIso8601String(),
          'updatedAt': DateTime.utc(2024).toIso8601String(),
        };
        final p = LibraryPlaylist.fromJson(json);
        expect(p.description, '');
        expect(p.shuffleEnabled, false);
        expect(p.isPinned, false);
        expect(p.songs, isEmpty);
        expect(p.customImageUrl, isNull);
        expect(p.sortOrder, PlaylistTrackSortOrder.customOrder);
      });
    });

    group('equality', () {
      test('equal when id, songs.length, updatedAt, and sortOrder match', () {
        final now = DateTime(2024);
        final p1 = LibraryPlaylist(id: 'x', name: 'A', createdAt: now, updatedAt: now);
        final p2 = LibraryPlaylist(id: 'x', name: 'B', createdAt: now, updatedAt: now);
        expect(p1, equals(p2));
      });

      test('not equal when id differs', () {
        final now = DateTime(2024);
        final p1 = LibraryPlaylist(id: 'x', name: 'A', createdAt: now, updatedAt: now);
        final p2 = LibraryPlaylist(id: 'y', name: 'A', createdAt: now, updatedAt: now);
        expect(p1, isNot(equals(p2)));
      });

      test('not equal when updatedAt differs', () {
        final p1 = LibraryPlaylist(
            id: 'x', name: 'A', createdAt: DateTime(2024), updatedAt: DateTime(2024, 1, 1));
        final p2 = LibraryPlaylist(
            id: 'x', name: 'A', createdAt: DateTime(2024), updatedAt: DateTime(2024, 1, 2));
        expect(p1, isNot(equals(p2)));
      });
    });

    group('copyWith', () {
      test('preserves unspecified fields', () {
        final p = _playlist(name: 'Original', isPinned: true);
        final copy = p.copyWith(name: 'Updated');
        expect(copy.name, 'Updated');
        expect(copy.isPinned, true);
        expect(copy.id, p.id);
      });
    });
  });

  group('PlaylistTrackSortOrder serialization', () {
    test('fromString returns customOrder for unknown value', () {
      expect(PlaylistTrackSortOrderX.fromString('unknown'), PlaylistTrackSortOrder.customOrder);
    });

    test('fromString returns customOrder for null', () {
      expect(PlaylistTrackSortOrderX.fromString(null), PlaylistTrackSortOrder.customOrder);
    });

    test('value round-trips through fromString', () {
      for (final order in PlaylistTrackSortOrder.values) {
        expect(PlaylistTrackSortOrderX.fromString(order.value), order);
      }
    });
  });
}
