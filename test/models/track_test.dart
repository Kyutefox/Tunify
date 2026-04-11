import 'package:flutter_test/flutter_test.dart';
import 'package:tunify/v1/data/models/track.dart';

void main() {
  group('Track', () {
    test('equality is based on id', () {
      const a = Track(
        id: 'id1',
        title: 'A',
        artist: 'Art',
        thumbnailUrl: '',
        duration: Duration.zero,
      );
      const b = Track(
        id: 'id1',
        title: 'B',
        artist: 'Other',
        thumbnailUrl: 'x',
        duration: Duration(minutes: 1),
      );
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('durationFormatted returns MM:SS', () {
      const t = Track(
        id: 'x',
        title: 'x',
        artist: 'x',
        thumbnailUrl: '',
        duration: Duration(minutes: 2, seconds: 9),
      );
      expect(t.durationFormatted, '02:09');
    });

    test('copyWith preserves unspecified fields', () {
      const t = Track(
        id: 'i',
        title: 'Title',
        artist: 'Artist',
        thumbnailUrl: '',
        duration: Duration.zero,
      );
      final c = t.copyWith(title: 'New Title');
      expect(c.id, 'i');
      expect(c.title, 'New Title');
      expect(c.artist, 'Artist');
    });
  });
}
