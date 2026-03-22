import 'package:flutter_test/flutter_test.dart';
import 'package:tunify/data/models/song.dart';
import 'package:tunify/data/models/track.dart';

void main() {
  group('Song', () {
    final song = Song(
      id: 'id1',
      title: 'Title',
      artist: 'Artist',
      thumbnailUrl: 'https://example.com/thumb.jpg',
      duration: const Duration(minutes: 3, seconds: 45),
      artistBrowseId: 'browse1',
      albumName: 'Album',
      isExplicit: true,
    );

    test('equality is by value (freezed)', () {
      final same = Song(
        id: song.id,
        title: song.title,
        artist: song.artist,
        thumbnailUrl: song.thumbnailUrl,
        duration: song.duration,
        artistBrowseId: song.artistBrowseId,
        albumName: song.albumName,
        isExplicit: song.isExplicit,
      );
      expect(song, equals(same));
      expect(song.hashCode, equals(same.hashCode));
    });

    test('inequality when id differs', () {
      final other = Song(
        id: 'id2',
        title: song.title,
        artist: song.artist,
        thumbnailUrl: song.thumbnailUrl,
        duration: song.duration,
      );
      expect(song, isNot(equals(other)));
    });

    test('toJson and fromJson round-trip', () {
      final json = song.toJson();
      final restored = Song.fromJson(json);
      expect(restored.id, song.id);
      expect(restored.title, song.title);
      expect(restored.duration.inMilliseconds, song.duration.inMilliseconds);
      expect(restored.isExplicit, song.isExplicit);
    });

    test('toJsonString and fromJsonString round-trip', () {
      final str = song.toJsonString();
      final restored = Song.fromJsonString(str);
      expect(restored?.id, song.id);
      expect(restored?.title, song.title);
    });

    test('fromJsonString returns null for null or empty', () {
      expect(Song.fromJsonString(null), isNull);
      expect(Song.fromJsonString(''), isNull);
    });

    test('fromTrack maps Track to Song', () {
      final track = Track(
        id: 'tid',
        title: 'Track Title',
        artist: 'Track Artist',
        thumbnailUrl: 'https://thumb',
        duration: const Duration(seconds: 120),
        albumName: 'Album',
      );
      final fromTrack = Song.fromTrack(track);
      expect(fromTrack.id, track.id);
      expect(fromTrack.title, track.title);
      expect(fromTrack.duration, track.duration);
    });

    test('durationFormatted returns MM:SS', () {
      expect(
        Song(
          id: 'x',
          title: 'x',
          artist: 'x',
          thumbnailUrl: '',
          duration: const Duration(minutes: 3, seconds: 5),
        ).durationFormatted,
        '03:05',
      );
    });
  });
}
