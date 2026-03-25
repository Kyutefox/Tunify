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
        CREATE TABLE playlists (
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL,
          description TEXT NOT NULL DEFAULT '',
          sort_order TEXT NOT NULL DEFAULT 'customOrder',
          songs TEXT NOT NULL DEFAULT '[]',
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL,
          custom_image_url TEXT,
          is_imported INTEGER NOT NULL DEFAULT 0,
          browse_id TEXT,
          cached_palette_color INTEGER,
          is_saved INTEGER NOT NULL DEFAULT 1
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
        CREATE TABLE collection_tracks (
          browse_id TEXT NOT NULL,
          track_index INTEGER NOT NULL,
          track_data TEXT NOT NULL,
          is_saved INTEGER NOT NULL DEFAULT 0,
          cached_at TEXT NOT NULL,
          PRIMARY KEY (browse_id, track_index)
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

  // ── P4: loadLibraryData returns only is_saved=1 playlists ────────────────

  test('P4: loadLibraryData returns only is_saved=1 playlists', () async {
    final rng = Random(45);

    for (var i = 0; i < iterations; i++) {
      final db = await _openTestDb();
      final localGet = SqliteGetController(() async => db);

      final savedCount = rng.nextInt(5) + 1; // 1..5
      final cacheCount = rng.nextInt(5) + 1; // 1..5
      final now = DateTime.now().toUtc().toIso8601String();

      // Insert is_saved=1 rows
      for (var j = 0; j < savedCount; j++) {
        await db.insert('playlists', {
          'id': 'saved_${i}_$j',
          'name': 'Saved $j',
          'description': '',
          'sort_order': 'customOrder',
          'songs': '[]',
          'created_at': now,
          'updated_at': now,
          'is_imported': 0,
          'is_saved': 1,
        });
      }

      // Insert is_saved=0 rows
      for (var j = 0; j < cacheCount; j++) {
        await db.insert('playlists', {
          'id': 'cache_${i}_$j',
          'name': 'Cache $j',
          'description': '',
          'sort_order': 'customOrder',
          'songs': '[]',
          'created_at': now,
          'updated_at': now,
          'is_imported': 0,
          'is_saved': 0,
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
      await db.insert('playlists', {
        'id': browseId,
        'name': originalName,
        'description': 'original desc',
        'sort_order': 'customOrder',
        'songs': '[]',
        'created_at': now,
        'updated_at': now,
        'is_imported': 0,
        'browse_id': browseId,
        'is_saved': 1,
      });

      // Attempt to overwrite with cache entry
      await create.upsertPlaylistCache(db, browseId, 0xFF123456, 'https://img.example.com/cover.jpg');

      final rows = await db.query('playlists',
          where: 'id = ?', whereArgs: [browseId]);
      expect(rows.length, equals(1));
      expect(rows.first['is_saved'], equals(1),
          reason: 'iteration $i: is_saved should remain 1');
      expect(rows.first['name'], equals(originalName),
          reason: 'iteration $i: name should not be overwritten');

      await db.close();
    }
  });

  // ── P6: Collection track cache round-trip within TTL ─────────────────────

  test('P6: collection track cache round-trip within TTL', () async {
    final rng = Random(47);
    final create = SqliteCreateController();

    for (var i = 0; i < iterations; i++) {
      final db = await _openTestDb();
      final localGet = SqliteGetController(() async => db);
      final browseId = _randomId(rng);
      final trackCount = rng.nextInt(10) + 1; // 1..10

      final tracks = List.generate(trackCount, (j) => {
            'id': 'track_$j',
            'title': 'Track $j',
            'artist': 'Artist',
          });

      await create.upsertCollectionTracks(db, browseId, tracks);
      final result = await localGet.getCollectionTracks(browseId);

      expect(result, isNotNull,
          reason: 'iteration $i: expected non-null result');
      expect(result!.length, equals(trackCount),
          reason: 'iteration $i: expected $trackCount tracks, got ${result.length}');

      await db.close();
    }
  });

  // ── P7: Expired collection track entries return null ─────────────────────

  test('P7: expired collection track entries return null and are deleted',
      () async {
    final rng = Random(48);

    for (var i = 0; i < iterations; i++) {
      final db = await _openTestDb();
      final localGet = SqliteGetController(() async => db);
      final browseId = _randomId(rng);
      final trackCount = rng.nextInt(5) + 1;

      // Insert rows with cached_at 31+ minutes ago
      final expiredCachedAt = DateTime.now()
          .toUtc()
          .subtract(Duration(minutes: 31 + rng.nextInt(60)))
          .toIso8601String();

      for (var j = 0; j < trackCount; j++) {
        await db.insert('collection_tracks', {
          'browse_id': browseId,
          'track_index': j,
          'track_data': '{"id":"track_$j"}',
          'is_saved': 0,
          'cached_at': expiredCachedAt,
        });
      }

      final result = await localGet.getCollectionTracks(browseId);
      expect(result, isNull,
          reason: 'iteration $i: expired entries should return null');

      // Rows should be deleted
      final rows = await db.query('collection_tracks',
          where: 'browse_id = ?', whereArgs: [browseId]);
      expect(rows, isEmpty,
          reason: 'iteration $i: expired rows should be deleted');

      await db.close();
    }
  });

  // ── P8: loadLibraryData filter (sync guard) ───────────────────────────────

  test('P8: sync guard — loadLibraryData returns only is_saved=1 playlists',
      () async {
    final rng = Random(49);

    for (var i = 0; i < iterations; i++) {
      final db = await _openTestDb();
      final localGet = SqliteGetController(() async => db);
      final now = DateTime.now().toUtc().toIso8601String();

      final savedCount = rng.nextInt(4) + 1;
      final cacheCount = rng.nextInt(4) + 1;

      for (var j = 0; j < savedCount; j++) {
        await db.insert('playlists', {
          'id': 'lib_${i}_$j',
          'name': 'Library $j',
          'description': '',
          'sort_order': 'customOrder',
          'songs': '[]',
          'created_at': now,
          'updated_at': now,
          'is_imported': 0,
          'is_saved': 1,
        });
      }

      for (var j = 0; j < cacheCount; j++) {
        await db.insert('playlists', {
          'id': 'cache_${i}_$j',
          'name': 'Cache $j',
          'description': '',
          'sort_order': 'customOrder',
          'songs': '[]',
          'created_at': now,
          'updated_at': now,
          'is_imported': 0,
          'is_saved': 0,
        });
      }

      final result = await localGet.loadLibraryData();
      final playlists = result['playlists'] as List;

      // All returned playlists must be library rows (no is_saved field exposed,
      // but count must equal savedCount since filter is WHERE is_saved = 1)
      expect(playlists.length, equals(savedCount),
          reason:
              'iteration $i: push payload should contain only $savedCount is_saved=1 rows');

      await db.close();
    }
  });

  // ── P9: insertPlaylists sets is_saved=1 ──────────────────────────────────

  test('P9: insertPlaylists sets is_saved=1 on all written rows', () async {
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
            'songs': [],
            'created_at': now,
            'updated_at': now,
            'is_imported': false,
            'browse_id': null,
            'cached_palette_color': null,
          });

      await db.transaction((txn) async {
        await create.insertPlaylists(txn, playlists);
      });

      final rows = await db.query('playlists');
      expect(rows.length, equals(count));
      for (final row in rows) {
        expect(row['is_saved'], equals(1),
            reason: 'iteration $i: all rows should have is_saved=1');
      }

      await db.close();
    }
  });

  // ── P10: Logout clears all cache-only data ───────────────────────────────

  test('P10: logout clears all cache-only data, preserves library rows',
      () async {
    final rng = Random(51);
    final create = SqliteCreateController();
    final delete = SqliteDeleteController();

    for (var i = 0; i < iterations; i++) {
      final db = await _openTestDb();
      final now = DateTime.now().toUtc().toIso8601String();

      final libCount = rng.nextInt(3) + 1;
      final cachePlaylistCount = rng.nextInt(3) + 1;
      final cacheTrackBrowseIds = rng.nextInt(3) + 1;
      final streamCount = rng.nextInt(5) + 1;

      // Insert library playlists (is_saved=1)
      for (var j = 0; j < libCount; j++) {
        await db.insert('playlists', {
          'id': 'lib_${i}_$j',
          'name': 'Library $j',
          'description': '',
          'sort_order': 'customOrder',
          'songs': '[]',
          'created_at': now,
          'updated_at': now,
          'is_imported': 0,
          'is_saved': 1,
        });
      }

      // Insert cache playlists (is_saved=0)
      for (var j = 0; j < cachePlaylistCount; j++) {
        await create.upsertPlaylistCache(db, 'cache_${i}_$j', null, null);
      }

      // Insert collection tracks (is_saved=0)
      for (var j = 0; j < cacheTrackBrowseIds; j++) {
        await create.upsertCollectionTracks(
            db, 'browse_${i}_$j', [{'id': 'track_0'}]);
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
      await delete.clearCacheOnlyCollectionTracks(db);
      await delete.clearAllStreamUrlCache(db);

      // Verify: zero cache-only playlists
      final cachePlaylists = await db.query('playlists',
          where: 'is_saved = ?', whereArgs: [0]);
      expect(cachePlaylists, isEmpty,
          reason: 'iteration $i: no cache-only playlists should remain');

      // Verify: zero collection tracks
      final tracks = await db.query('collection_tracks',
          where: 'is_saved = ?', whereArgs: [0]);
      expect(tracks, isEmpty,
          reason: 'iteration $i: no cache-only collection tracks should remain');

      // Verify: zero stream URL cache rows
      final streams = await db.query('stream_url_cache');
      expect(streams, isEmpty,
          reason: 'iteration $i: no stream URL cache rows should remain');

      // Verify: library rows preserved
      final libRows = await db.query('playlists',
          where: 'is_saved = ?', whereArgs: [1]);
      expect(libRows.length, equals(libCount),
          reason: 'iteration $i: library rows should be preserved');

      await db.close();
    }
  });

  // ── P11: Migration preserves existing rows with is_saved=1 ───────────────

  test('P11: ALTER TABLE ADD COLUMN DEFAULT 1 sets is_saved=1 on existing rows',
      () async {
    final rng = Random(52);

    for (var i = 0; i < iterations; i++) {
      // Simulate a v3-style table (without is_saved column)
      final db = await openDatabase(
        inMemoryDatabasePath,
        version: 1,
        onCreate: (db, _) async {
          await db.execute('''
            CREATE TABLE playlists (
              id TEXT PRIMARY KEY,
              name TEXT NOT NULL,
              description TEXT NOT NULL DEFAULT '',
              sort_order TEXT NOT NULL DEFAULT 'customOrder',
              songs TEXT NOT NULL DEFAULT '[]',
              created_at TEXT NOT NULL,
              updated_at TEXT NOT NULL,
              custom_image_url TEXT,
              is_imported INTEGER NOT NULL DEFAULT 0,
              browse_id TEXT,
              cached_palette_color INTEGER
            )
          ''');
        },
      );

      final rowCount = rng.nextInt(5) + 1;
      final now = DateTime.now().toUtc().toIso8601String();

      // Insert rows into v3-style table
      for (var j = 0; j < rowCount; j++) {
        await db.insert('playlists', {
          'id': 'pl_${i}_$j',
          'name': 'Playlist $j',
          'description': '',
          'sort_order': 'customOrder',
          'songs': '[]',
          'created_at': now,
          'updated_at': now,
          'is_imported': 0,
        });
      }

      // Run the v3→v4 migration: ALTER TABLE ADD COLUMN with DEFAULT 1
      await db.execute(
          'ALTER TABLE playlists ADD COLUMN is_saved INTEGER NOT NULL DEFAULT 1');

      // Verify all rows have is_saved=1
      final rows = await db.query('playlists');
      expect(rows.length, equals(rowCount),
          reason: 'iteration $i: all rows should be preserved');
      for (final row in rows) {
        expect(row['is_saved'], equals(1),
            reason:
                'iteration $i: migrated row should have is_saved=1, got ${row['is_saved']}');
      }

      await db.close();
    }
  });
}
