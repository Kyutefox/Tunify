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

  /// Reads the full entry (songs + imageUrl) from Hive.
  /// Returns null if missing or TTL expired — caller should fetch from API.
  Future<CacheEntry?> getEntryFromCache(String id) async {
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
    final songs = tracksRaw
        .map((t) => Song.fromJson(Map<String, dynamic>.from(t as Map)))
        .toList();
    final paletteRaw = map['paletteColor'] as int?;
    return CacheEntry(
      songs: songs,
      cachedAt: cachedAt,
      imageUrl: map['imageUrl'] as String?,
      paletteColor: paletteRaw != null ? Color(paletteRaw) : null,
    );
  }

  /// Returns songs for [id] from Hive, or null if missing / expired.
  Future<List<Song>?> getSongs(String id) async {
    return (await getEntryFromCache(id))?.songs;
  }

  /// Stores [songs], [imageUrl], and [paletteColor] for [id] in Hive.
  void put(String id, List<Song> songs, {Color? paletteColor, String? imageUrl}) {
    final now = DateTime.now();
    _getBox().then((box) {
      box.put(id, {
        'tracks': songs.map((s) => s.toJson()).toList(),
        'cachedAt': now.toUtc().toIso8601String(),
        if (imageUrl != null) 'imageUrl': imageUrl,
        if (paletteColor != null) 'paletteColor': paletteColor.toARGB32(),
      });
    }).ignore();
  }

  /// Updates just the palette color for an existing Hive entry.
  void updatePalette(String id, Color paletteColor) {
    _getBox().then((box) {
      final raw = box.get(id);
      if (raw == null) return;
      final map = Map<String, dynamic>.from(raw as Map);
      map['paletteColor'] = paletteColor.toARGB32();
      box.put(id, map);
    }).ignore();
  }

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
