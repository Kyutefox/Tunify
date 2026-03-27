import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:tunify/data/models/song.dart';

/// Hive-backed cache for remote collection tracks (imported playlists, artists, albums).
///
/// Two-source architecture:
///   - Hive  : persistent, 1-hour TTL (this class)
///   - SQLite: permanent library data  (playlist_songs table)
///
/// Only covers fetched-on-demand content — custom playlists and liked songs
/// are stored permanently in SQLite and never pass through here.
class CollectionTrackCache {
  CollectionTrackCache._();
  static final CollectionTrackCache instance = CollectionTrackCache._();

  static const _boxName = 'collection_tracks';
  static const Duration ttl = Duration(hours: 1);

  Box<dynamic>? _box;

  Future<Box<dynamic>> _getBox() async {
    if (_box != null && _box!.isOpen) return _box!;
    _box = await Hive.openBox<dynamic>(_boxName);
    return _box!;
  }

  /// Always returns null — no in-memory layer. Use [getSongs] for async access.
  /// Kept for call-site compatibility; callers that receive null will trigger
  /// the async fetch path which reads from Hive.
  CacheEntry? getEntry(String id) => null;

  /// Returns songs for [id] from Hive, or null if missing / expired.
  /// Null means the caller should fetch from the API and call [put].
  Future<List<Song>?> getSongs(String id) async {
    final box = await _getBox();
    final raw = box.get(id);
    if (raw == null) return null;

    final map = Map<String, dynamic>.from(raw as Map);
    final cachedAt = DateTime.tryParse(map['cachedAt'] as String? ?? '');
    if (cachedAt == null || DateTime.now().difference(cachedAt) > ttl) {
      await box.delete(id);
      return null;
    }

    final tracksRaw = map['tracks'] as List<dynamic>? ?? [];
    return tracksRaw
        .map((t) => Song.fromJson(Map<String, dynamic>.from(t as Map)))
        .toList();
  }

  /// Palette color is stored in SQLite via the library provider (updatePlaylistMeta).
  /// Returns null — callers fall back to the library state color.
  Future<Color?> getPaletteColor(String id) async => null;

  /// Stores [songs] (and optionally [imageUrl]) for [id] in Hive.
  void put(String id, List<Song> songs, {Color? paletteColor, String? imageUrl}) {
    final now = DateTime.now();
    _getBox().then((box) {
      box.put(id, {
        'tracks': songs.map((s) => s.toJson()).toList(),
        'cachedAt': now.toUtc().toIso8601String(),
        if (imageUrl != null) 'imageUrl': imageUrl,
      });
    }).ignore();
  }

  /// No-op — palette is persisted via updatePlaylistMeta in the library provider.
  void updatePalette(String id, Color paletteColor) {}

  /// Removes a single entry from Hive (forces a re-fetch on next open).
  void invalidate(String id) {
    _getBox().then((box) => box.delete(id)).ignore();
  }

  /// Clears all cached entries from Hive. Call on logout.
  Future<void> clear() async {
    final box = await _getBox();
    await box.clear();
  }
}

/// Kept for call-site compatibility. Always null when returned from [getEntry].
class CacheEntry {
  const CacheEntry({
    required this.songs,
    required this.cachedAt,
    this.paletteColor,
    this.imageUrl,
  });
  final List<Song> songs;
  final DateTime cachedAt;
  final Color? paletteColor;
  final String? imageUrl;
}
