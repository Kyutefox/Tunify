import 'package:flutter_test/flutter_test.dart';
import 'package:tunify/data/models/library_artist.dart';

LibraryArtist _artist({String id = 'a1', String name = 'Test Artist'}) {
  return LibraryArtist(
    id: id,
    name: name,
    thumbnailUrl: 'https://example.com/artist.jpg',
    browseId: 'browse_$id',
    followedAt: DateTime.utc(2024, 1, 1),
  );
}

void main() {
  group('LibraryArtist', () {
    group('JSON serialization', () {
      test('toJson / fromJson round-trip preserves all fields', () {
        final original = LibraryArtist(
          id: 'a42',
          name: 'Radiohead',
          thumbnailUrl: 'https://example.com/artist.jpg',
          browseId: 'browse_a42',
          followedAt: DateTime.utc(2024, 1, 1),
          isPinned: true,
        );
        final decoded = LibraryArtist.fromJson(original.toJson());
        expect(decoded.id, original.id);
        expect(decoded.name, original.name);
        expect(decoded.thumbnailUrl, original.thumbnailUrl);
        expect(decoded.browseId, original.browseId);
        expect(decoded.isPinned, original.isPinned);
      });

      test('missing optional fields use defaults', () {
        final json = {
          'id': 'a1',
          'followedAt': DateTime.utc(2024).toIso8601String(),
        };
        final a = LibraryArtist.fromJson(json);
        expect(a.name, '');
        expect(a.thumbnailUrl, '');
        expect(a.browseId, isNull);
      });

      test('missing followedAt defaults to a valid DateTime', () {
        final json = {'id': 'a1', 'name': 'Artist'};
        final a = LibraryArtist.fromJson(json);
        expect(a.followedAt, isNotNull);
      });
    });

    group('equality', () {
      test('equal when IDs match regardless of other fields', () {
        final a1 = LibraryArtist(
            id: 'x',
            name: 'Artist A',
            thumbnailUrl: '',
            followedAt: DateTime(2024));
        final a2 = LibraryArtist(
            id: 'x',
            name: 'Artist B',
            thumbnailUrl: 'different',
            followedAt: DateTime(2025));
        expect(a1, equals(a2));
      });

      test('not equal when IDs differ', () {
        final a1 = _artist(id: 'x');
        final a2 = _artist(id: 'y');
        expect(a1, isNot(equals(a2)));
      });

      test('hashCode is consistent with equality', () {
        final a1 = _artist(id: 'x');
        final a2 = _artist(id: 'x', name: 'Different Name');
        expect(a1.hashCode, equals(a2.hashCode));
      });
    });
  });
}
