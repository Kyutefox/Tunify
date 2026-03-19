import 'package:flutter_test/flutter_test.dart';
import 'package:tunify/models/library_folder.dart';

LibraryFolder _folder({
  String id = 'f1',
  String name = 'Test Folder',
  List<String>? playlistIds,
  bool isPinned = false,
}) {
  return LibraryFolder(
    id: id,
    name: name,
    playlistIds: playlistIds ?? [],
    createdAt: DateTime(2024, 1, 1),
    isPinned: isPinned,
  );
}

void main() {
  group('LibraryFolder', () {
    group('playlistCount', () {
      test('returns number of playlist IDs', () {
        final f = _folder(playlistIds: ['a', 'b', 'c']);
        expect(f.playlistCount, 3);
      });

      test('returns 0 for empty folder', () {
        final f = _folder(playlistIds: []);
        expect(f.playlistCount, 0);
      });
    });

    group('JSON serialization', () {
      test('toJson / fromJson round-trip preserves all fields', () {
        final original = LibraryFolder(
          id: 'f42',
          name: 'My Folder',
          playlistIds: ['p1', 'p2', 'p3'],
          createdAt: DateTime.utc(2024, 3, 15),
          isPinned: true,
        );
        final decoded = LibraryFolder.fromJson(original.toJson());
        expect(decoded.id, original.id);
        expect(decoded.name, original.name);
        expect(decoded.playlistIds, original.playlistIds);
        expect(decoded.isPinned, original.isPinned);
      });

      test('missing playlistIds defaults to empty list', () {
        final json = {
          'id': 'f1',
          'name': 'Minimal',
          'createdAt': DateTime.utc(2024).toIso8601String(),
        };
        final f = LibraryFolder.fromJson(json);
        expect(f.playlistIds, isEmpty);
        expect(f.isPinned, false);
      });

      test('fromJsonString returns null for null input', () {
        expect(LibraryFolder.fromJsonString(null), isNull);
      });

      test('fromJsonString returns null for empty string', () {
        expect(LibraryFolder.fromJsonString(''), isNull);
      });

      test('fromJsonString returns null for invalid JSON', () {
        expect(LibraryFolder.fromJsonString('not json'), isNull);
      });
    });

    group('equality', () {
      test('equal when id, name, and playlistIds are the same object', () {
        const ids = ['p1'];
        final f1 = _folder(id: 'x', name: 'A', playlistIds: ids);
        final f2 = _folder(id: 'x', name: 'A', playlistIds: ids);
        expect(f1, equals(f2));
      });

      test('not equal when id differs', () {
        final f1 = _folder(id: 'x', name: 'A');
        final f2 = _folder(id: 'y', name: 'A');
        expect(f1, isNot(equals(f2)));
      });

      test('not equal when name differs', () {
        final f1 = _folder(id: 'x', name: 'A');
        final f2 = _folder(id: 'x', name: 'B');
        expect(f1, isNot(equals(f2)));
      });

      test('not equal when playlistIds differ', () {
        final f1 = _folder(id: 'x', name: 'A', playlistIds: ['p1']);
        final f2 = _folder(id: 'x', name: 'A', playlistIds: ['p2']);
        expect(f1, isNot(equals(f2)));
      });
    });

    group('copyWith', () {
      test('preserves unspecified fields', () {
        final f = _folder(name: 'Original', isPinned: true, playlistIds: ['p1']);
        final copy = f.copyWith(name: 'Updated');
        expect(copy.name, 'Updated');
        expect(copy.isPinned, true);
        expect(copy.playlistIds, ['p1']);
        expect(copy.id, f.id);
      });
    });
  });
}
