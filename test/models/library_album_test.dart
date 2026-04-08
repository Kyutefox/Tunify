import 'package:flutter_test/flutter_test.dart';
import 'package:tunify/data/models/library_album.dart';

LibraryAlbum _album({String id = 'al1', String title = 'Test Album'}) {
  return LibraryAlbum(
    id: id,
    title: title,
    artistName: 'Test Artist',
    thumbnailUrl: 'https://example.com/album.jpg',
    browseId: 'browse_$id',
    followedAt: DateTime.utc(2024, 1, 1),
  );
}

void main() {
  group('LibraryAlbum', () {
    group('JSON serialization', () {
      test('toJson / fromJson round-trip preserves all fields', () {
        final original = LibraryAlbum(
          id: 'al42',
          title: 'OK Computer',
          artistName: 'Test Artist',
          thumbnailUrl: 'https://example.com/album.jpg',
          browseId: 'browse_al42',
          followedAt: DateTime.utc(2024, 1, 1),
          isPinned: true,
        );
        final decoded = LibraryAlbum.fromJson(original.toJson());
        expect(decoded.id, original.id);
        expect(decoded.title, original.title);
        expect(decoded.artistName, original.artistName);
        expect(decoded.thumbnailUrl, original.thumbnailUrl);
        expect(decoded.browseId, original.browseId);
        expect(decoded.isPinned, original.isPinned);
      });

      test('missing optional fields use defaults', () {
        final json = {
          'id': 'al1',
          'followedAt': DateTime.utc(2024).toIso8601String(),
        };
        final a = LibraryAlbum.fromJson(json);
        expect(a.title, '');
        expect(a.artistName, '');
        expect(a.thumbnailUrl, '');
        expect(a.browseId, isNull);
      });

      test('missing followedAt defaults to a valid DateTime', () {
        final json = {'id': 'al1', 'title': 'Album'};
        final a = LibraryAlbum.fromJson(json);
        expect(a.followedAt, isNotNull);
      });
    });

    group('equality', () {
      test('equal when IDs match regardless of other fields', () {
        final a1 = LibraryAlbum(
            id: 'x',
            title: 'Album A',
            artistName: 'Artist',
            thumbnailUrl: '',
            followedAt: DateTime(2024));
        final a2 = LibraryAlbum(
            id: 'x',
            title: 'Album B',
            artistName: 'Other',
            thumbnailUrl: 'diff',
            followedAt: DateTime(2025));
        expect(a1, equals(a2));
      });

      test('not equal when IDs differ', () {
        final a1 = _album(id: 'x');
        final a2 = _album(id: 'y');
        expect(a1, isNot(equals(a2)));
      });

      test('hashCode is consistent with equality', () {
        final a1 = _album(id: 'x');
        final a2 = _album(id: 'x', title: 'Different Title');
        expect(a1.hashCode, equals(a2.hashCode));
      });
    });
  });
}
