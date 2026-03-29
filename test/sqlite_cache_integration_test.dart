// ignore_for_file: avoid_print

import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite/sqflite.dart';
import 'package:tunify_database/src/sqlite/create.controller.dart';
import 'package:tunify_database/src/sqlite/delete.controller.dart';
import 'package:tunify_database/src/sqlite/get.controller.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

String _randomId(Random rng, {int length = 8}) {
  const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
  return List.generate(length, (_) => chars[rng.nextInt(chars.length)]).join();
}

String _randomUrl(Random rng) =>
    'https://example.com/stream/${_randomId(rng, length: 12)}.mp4';

Future<Database> _openTestDb() async {
  return openDatabase(
    inMemoryDatabasePath,
    version: 1,
    onCreate: (db, _) async {
      await db.execute('''
        CREATE TABLE playlist_info (
          id                       TEXT PRIMARY KEY,
          name                     TEXT NOT NULL,
          description              TEXT NOT NULL DEFAULT '',
          sort_order               TEXT NOT NULL DEFAULT 'customOrder',
          cover_url                TEXT,
          is_imported              INTEGER NOT NULL DEFAULT 0,
          browse_id                TEXT,
          palette_color            INTEGER,
          is_saved                 INTEGER NOT NULL DEFAULT 1,
          total_track_count_remote INTEGER,
          shuffle_enabled          INTEGER NOT NULL DEFAULT 0,
          is_pinned                INTEGER NOT NULL DEFAULT 0,
          is_artist                INTEGER NOT NULL DEFAULT 0,
          is_album                 INTEGER NOT NULL DEFAULT 0,
          created_at               TEXT NOT NULL,
          updated_at               TEXT NOT NULL
        )
      ''');
      await db.execute('''
        CREATE TABLE playlist_songs (
          row_id              INTEGER PRIMARY KEY AUTOINCREMENT,
          playlist_id         TEXT NOT NULL,
          song_id             TEXT NOT NULL,
          title               TEXT NOT NULL,
          artist              TEXT NOT NULL,
          cover_url           TEXT NOT NULL DEFAULT '',
          duration_ms         INTEGER NOT NULL DEFAULT 0,
          is_explicit         INTEGER NOT NULL DEFAULT 0,
          artist_browse_id    TEXT,
          album_browse_id     TEXT,
          album_name          TEXT,
          sort_order_sequence INTEGER NOT NULL DEFAULT 0
        )
      ''');
      await db.execute('''
        CREATE TABLE stream_url_cache (
          video_id TEXT PRIMARY KEY,
          url TEXT NOT NULL,
          headers TEXT NOT NULL DEFAULT '{}',
          bitrate INTEGER NOT NULL DEFAULT 0,
          quality TEXT NOT NULL DEFAULT '',
          expires_at TEXT NOT NULL
        )
      ''');
      await db.execute('''
        CREATE TABLE folders (
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL,
          created_at TEXT NOT NULL
        )
      ''');
      await db.execute('''
        CREATE TABLE folder_playlists (
          folder_id TEXT NOT NULL,
          playlist_id TEXT NOT NULL,
          PRIMARY KEY (folder_id, playlist_id)
        )
      ''');
      await db.execute('''
        CREATE TABLE settings (
          key TEXT PRIMARY KEY,
          value TEXT NOT NULL
        )
      ''');
    },
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  const iterations = 20;

  // ── P1: Stream URL cache round-trip ──────────────────────────────────────

  test('P1: stream URL cache round-trip', () async {
    final rng = Random(42);
    final db = await _openTestDb();
    final create = SqliteCreateController();
    final get = SqliteGetController(() async => db);

    for (var i = 0; i < iterations; i++) {
      final videoId = _randomId(rng);
      final url = _randomUrl(rng);
      final bitrate = rng.nextInt(320000) + 64000;
      final quality = ['low', 'medium', 'high'][rng.nextInt(3)];
      final expiresAt = DateTime.now().toUtc().add(const Duration(hours: 6));

      await create.upsertStreamUrlCache(
          db, videoId, url, {}, bitrate, quality, expiresAt);
      final result = await get.getStreamUrlCache(videoId);

      expect(result, isNotNull,
          reason: 'iteration $i: expected non-null result for videoId=$videoId');
      expect(result!['url'], equals(url),
          reason: 'iteration $i: url mismatch');
      expect(result['bitrate'], equals(bitrate),
          reason: 'iteration $i: bitrate mismatch');
      expect(result['quality'], equals(quality),
          reason: 'iteration $i: quality mismatch');
    }

    await db.close();
  });

  // ── P2: Expired stream URL entries return null ───────────────────────────

  test('P2: expired stream URL entries return null', () async {
    final rng = Random(43);
    final db = await _openTestDb();
    final create = SqliteCreateController();
    final get = SqliteGetController(() async => db);

    for (var i = 0; i < iterations; i++) {
      final videoId = _randomId(rng);
      final url = _randomUrl(rng);
      // expires_at in the past
      final expiresAt =
          DateTime.now().toUtc().subtract(Duration(seconds: rng.nextInt(3600) + 1));

      await create.upsertStreamUrlCache(db, videoId, url, {}, 128000, 'medium', expiresAt);
      final result = await get.getStreamUrlCache(videoId);

      expect(result, isNull,
          reason: 'iteration $i: expired entry should return null');

      // Row should be deleted
      final rows = await db.query('stream_url_cache',
          where: 'video_id = ?', whereArgs: [videoId]);
      expect(rows, isEmpty,
          reason: 'iteration $i: expired row should be deleted');
    }

    await db.close();
  });

  // ── P3: Stream URL cache trim ────────────────────────────────────────────

  test('P3: stream URL cache trim — count ≤ 180 after reaching ≥ 200', () async {
    final rng = Random(44);
    final db = await _openTestDb();
    final create = SqliteCreateController();
    final delete = SqliteDeleteController();

    // Insert 205 rows with varying expiry times so LRU ordering works
    for (var i = 0; i < 205; i++) {
      final videoId = 'vid_${i.toString().padLeft(4, '0')}';
      final expiresAt =
          DateTime.now().toUtc().add(Duration(minutes: i + 1));
      await create.upsertStreamUrlCache(
          db, videoId, _randomUrl(rng), {}, 128000, 'medium', expiresAt);
    }

    final countBefore = Sqflite.firstIntValue(
            await db.rawQuery('SELECT COUNT(*) FROM stream_url_cache')) ??
        0;
    expect(countBefore, equals(205));

    await delete.trimStreamUrlCacheIfNeeded(db);

    final countAfter = Sqflite.firstIntValue(
            await db.rawQuery('SELECT COUNT(*) FROM stream_url_cache')) ??
        0;
    expect(countAfter, lessThanOrEqualTo(180),
        reason: 'trim should bring count to ≤ 180');

    await db.close();
  });

  // ── P4: loadLibraryData returns only regular is_saved=1 playlists ────────

  test('P4: loadLibraryData returns only regular is_saved=1 playlists', () async {
    final rng = Random(45);

    for (var i = 0; i < iterations; i++) {
      final db = await _openTestDb();
      final localGet = SqliteGetController(() async => db);

      final savedCount = rng.nextInt(5) + 1; // 1..5
      final cacheCount = rng.nextInt(5) + 1; // 1..5
      final now = DateTime.now().toUtc().toIso8601String();

      // Insert regular library rows (is_saved=1, is_artist=0, is_album=0)
      for (var j = 0; j < savedCount; j++) {
        await db.insert('playlist_info', {
          'id': 'saved_${i}_$j',
          'name': 'Saved $j',
          'description': '',
          'sort_order': 'customOrder',
          'created_at': now,
          'updated_at': now,
          'is_imported': 0,
          'is_saved': 1,
          'shuffle_enabled': 0,
          'is_pinned': 0,
          'is_artist': 0,
          'is_album': 0,
        });
      }

      // Insert cache rows (is_saved=0) — should be excluded
      for (var j = 0; j < cacheCount; j++) {
        await db.insert('playlist_info', {
          'id': 'cache_${i}_$j',
          'name': 'Cache $j',
          'description': '',
          'sort_order': 'customOrder',
          'created_at': now,
          'updated_at': now,
          'is_imported': 0,
          'is_saved': 0,
          'shuffle_enabled': 0,
          'is_pinned': 0,
          'is_artist': 0,
          'is_album': 0,
        });
      }

      final result = await localGet.loadLibraryData();
      final playlists = result['playlists'] as List;

      expect(playlists.length, equals(savedCount),
          reason:
              'iteration $i: expected $savedCount playlists, got ${playlists.length}');

      await db.close();
    }
  });

  // ── P5: upsertPlaylistCache does not overwrite is_saved=1 rows ───────────

  test('P5: upsertPlaylistCache does not overwrite is_saved=1 library rows',
      () async {
    final rng = Random(46);
    final create = SqliteCreateController();

    for (var i = 0; i < iterations; i++) {
      final db = await _openTestDb();
      final browseId = _randomId(rng);
      final originalName = 'Library Playlist ${_randomId(rng)}';
      final now = DateTime.now().toUtc().toIso8601String();

      // Insert a library row (is_saved=1)
      await db.insert('playlist_info', {
        'id': browseId,
        'name': originalName,
        'description': 'original desc',
        'sort_order': 'customOrder',
        'created_at': now,
        'updated_at': now,
        'is_imported': 0,
        'browse_id': browseId,
        'is_saved': 1,
        'shuffle_enabled': 0,
        'is_pinned': 0,
        'is_artist': 0,
        'is_album': 0,
      });

      // Attempt to overwrite with cache entry
      await create.upsertPlaylistCache(db, browseId, 0xFF123456, 'https://img.example.com/cover.jpg');

      final rows = await db.query('playlist_info',
          where: 'id = ?', whereArgs: [browseId]);
      expect(rows.length, equals(1));
      expect(rows.first['is_saved'], equals(1),
          reason: 'iteration $i: is_saved should remain 1');
      expect(rows.first['name'], equals(originalName),
          reason: 'iteration $i: name should not be overwritten');

      await db.close();
    }
  });

  // ── P6: loadLibraryData separates artists and albums from playlists ───────

  test('P6: loadLibraryData separates artists and albums from regular playlists',
      () async {
    final rng = Random(47);

    for (var i = 0; i < iterations; i++) {
      final db = await _openTestDb();
      final localGet = SqliteGetController(() async => db);
      final now = DateTime.now().toUtc().toIso8601String();

      final playlistCount = rng.nextInt(3) + 1;
      final artistCount = rng.nextInt(3) + 1;
      final albumCount = rng.nextInt(3) + 1;

      for (var j = 0; j < playlistCount; j++) {
        await db.insert('playlist_info', {
          'id': 'pl_${i}_$j', 'name': 'Playlist $j', 'description': '',
          'sort_order': 'customOrder', 'created_at': now, 'updated_at': now,
          'is_imported': 0, 'is_saved': 1, 'shuffle_enabled': 0,
          'is_pinned': 0, 'is_artist': 0, 'is_album': 0,
        });
      }
      for (var j = 0; j < artistCount; j++) {
        await db.insert('playlist_info', {
          'id': 'ar_${i}_$j', 'name': 'Artist $j', 'description': '',
          'sort_order': 'customOrder', 'created_at': now, 'updated_at': now,
          'is_imported': 0, 'is_saved': 1, 'shuffle_enabled': 0,
          'is_pinned': 0, 'is_artist': 1, 'is_album': 0,
        });
      }
      for (var j = 0; j < albumCount; j++) {
        await db.insert('playlist_info', {
          'id': 'al_${i}_$j', 'name': 'Album $j', 'description': 'Artist Name',
          'sort_order': 'customOrder', 'created_at': now, 'updated_at': now,
          'is_imported': 0, 'is_saved': 1, 'shuffle_enabled': 0,
          'is_pinned': 0, 'is_artist': 0, 'is_album': 1,
        });
      }

      final result = await localGet.loadLibraryData();
      final playlists = result['playlists'] as List;
      final artists = result['followedArtists'] as List;
      final albums = result['followedAlbums'] as List;

      expect(playlists.length, equals(playlistCount),
          reason: 'iteration $i: expected $playlistCount regular playlists');
      expect(artists.length, equals(artistCount),
          reason: 'iteration $i: expected $artistCount followed artists');
      expect(albums.length, equals(albumCount),
          reason: 'iteration $i: expected $albumCount followed albums');

      await db.close();
    }
  });

  // ── P7: upsertPlaylists sets is_saved=1 ──────────────────────────────────

  test('P7: upsertPlaylists sets is_saved=1 on all written rows', () async {
    final rng = Random(50);
    final create = SqliteCreateController();

    for (var i = 0; i < iterations; i++) {
      final db = await _openTestDb();
      final now = DateTime.now().toUtc().toIso8601String();
      final count = rng.nextInt(5) + 1;

      final playlists = List.generate(count, (j) => {
            'id': 'pl_${i}_$j',
            'name': 'Playlist $j',
            'description': '',
            'sort_order': 'customOrder',
            'songs': <Map>[],
            'created_at': now,
            'updated_at': now,
            'is_imported': false,
            'browse_id': null,
            'palette_color': null,
            'cover_url': null,
            'total_track_count_remote': null,
            'shuffle_enabled': false,
            'is_pinned': false,
            'is_artist': false,
            'is_album': false,
          });

      await db.transaction((txn) async {
        await create.upsertPlaylists(txn, playlists);
      });

      final rows = await db.query('playlist_info');
      expect(rows.length, equals(count));
      for (final row in rows) {
        expect(row['is_saved'], equals(1),
            reason: 'iteration $i: all rows should have is_saved=1');
      }

      await db.close();
    }
  });

  // ── P8: Logout clears all cache-only data ────────────────────────────────

  test('P8: logout clears all cache-only data, preserves library rows',
      () async {
    final rng = Random(51);
    final create = SqliteCreateController();
    final delete = SqliteDeleteController();

    for (var i = 0; i < iterations; i++) {
      final db = await _openTestDb();
      final now = DateTime.now().toUtc().toIso8601String();

      final libCount = rng.nextInt(3) + 1;
      final cachePlaylistCount = rng.nextInt(3) + 1;
      final streamCount = rng.nextInt(5) + 1;

      // Insert library playlists (is_saved=1)
      for (var j = 0; j < libCount; j++) {
        await db.insert('playlist_info', {
          'id': 'lib_${i}_$j',
          'name': 'Library $j',
          'description': '',
          'sort_order': 'customOrder',
          'created_at': now,
          'updated_at': now,
          'is_imported': 0,
          'is_saved': 1,
          'shuffle_enabled': 0,
          'is_pinned': 0,
          'is_artist': 0,
          'is_album': 0,
        });
      }

      // Insert cache playlists (is_saved=0)
      for (var j = 0; j < cachePlaylistCount; j++) {
        await create.upsertPlaylistCache(db, 'cache_${i}_$j', null, null);
      }

      // Insert stream URL cache rows
      for (var j = 0; j < streamCount; j++) {
        await create.upsertStreamUrlCache(
          db,
          'vid_${i}_$j',
          _randomUrl(rng),
          {},
          128000,
          'medium',
          DateTime.now().toUtc().add(const Duration(hours: 5)),
        );
      }

      // Logout sequence
      await delete.clearCacheOnlyPlaylists(db);
      await delete.clearAllStreamUrlCache(db);

      // Verify: zero cache-only playlists
      final cachePlaylists = await db.query('playlist_info',
          where: 'is_saved = ?', whereArgs: [0]);
      expect(cachePlaylists, isEmpty,
          reason: 'iteration $i: no cache-only playlists should remain');

      // Verify: zero stream URL cache rows
      final streams = await db.query('stream_url_cache');
      expect(streams, isEmpty,
          reason: 'iteration $i: no stream URL cache rows should remain');

      // Verify: library rows preserved
      final libRows = await db.query('playlist_info',
          where: 'is_saved = ?', whereArgs: [1]);
      expect(libRows.length, equals(libCount),
          reason: 'iteration $i: library rows should be preserved');

      await db.close();
    }
  });

  // ── P9: sync guard — loadLibraryData returns only is_saved=1 playlists ───

  test('P9: sync guard — loadLibraryData returns only is_saved=1 playlists',
      () async {
    final rng = Random(49);

    for (var i = 0; i < iterations; i++) {
      final db = await _openTestDb();
      final localGet = SqliteGetController(() async => db);
      final now = DateTime.now().toUtc().toIso8601String();

      final savedCount = rng.nextInt(4) + 1;
      final cacheCount = rng.nextInt(4) + 1;

      for (var j = 0; j < savedCount; j++) {
        await db.insert('playlist_info', {
          'id': 'lib_${i}_$j',
          'name': 'Library $j',
          'description': '',
          'sort_order': 'customOrder',
          'created_at': now,
          'updated_at': now,
          'is_imported': 0,
          'is_saved': 1,
          'shuffle_enabled': 0,
          'is_pinned': 0,
          'is_artist': 0,
          'is_album': 0,
        });
      }

      for (var j = 0; j < cacheCount; j++) {
        await db.insert('playlist_info', {
          'id': 'cache_${i}_$j',
          'name': 'Cache $j',
          'description': '',
          'sort_order': 'customOrder',
          'created_at': now,
          'updated_at': now,
          'is_imported': 0,
          'is_saved': 0,
          'shuffle_enabled': 0,
          'is_pinned': 0,
          'is_artist': 0,
          'is_album': 0,
        });
      }

      final result = await localGet.loadLibraryData();
      final playlists = result['playlists'] as List;

      expect(playlists.length, equals(savedCount),
          reason:
              'iteration $i: push payload should contain only $savedCount is_saved=1 rows');

      await db.close();
    }
  });
}
