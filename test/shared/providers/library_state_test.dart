import 'package:flutter_test/flutter_test.dart';
import 'package:tunify/data/models/library_playlist.dart';
import 'package:tunify/features/library/library_provider.dart';

void main() {
  group('LibraryState', () {
    test('sortedPlaylists pins first then sorts by sortOrder', () {
      final now = DateTime.now();
      final a = LibraryPlaylist(
        id: 'a',
        name: 'A',
        createdAt: now,
        updatedAt: now,
        isPinned: false,
      );
      final b = LibraryPlaylist(
        id: 'b',
        name: 'B',
        createdAt: now,
        updatedAt: now,
        isPinned: true,
      );
      final state = LibraryState(
          playlists: [a, b], sortOrder: LibrarySortOrder.alphabetical);
      final sorted = state.sortedPlaylists;
      expect(sorted.first.id, 'b');
      expect(sorted.last.id, 'a');
    });

    test('copyWith preserves unspecified fields', () {
      final state =
          LibraryState(searchQuery: 'hello', viewMode: LibraryViewMode.grid);
      final next = state.copyWith(searchQuery: '');
      expect(next.searchQuery, '');
      expect(next.viewMode, LibraryViewMode.grid);
    });
  });
}
