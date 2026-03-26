import 'package:flutter/material.dart';
import 'package:tunify/data/models/song.dart';
import 'package:tunify_database/tunify_database.dart';

/// In-memory cache for remote collection tracks + palette metadata.
/// Keyed by browse/playlist ID. Lives for the app session — cleared on logout.
class CollectionTrackCache {
  CollectionTrackCache._();
  static final CollectionTrackCache instance = CollectionTrackCache._();

  final Map<String, CacheEntry> _cache = {};
  DatabaseBridge? _db;

  /// Injects the database reference. Call once at app startup.
  void init(DatabaseBridge db) {
    _db = db;
  }

  /// How long a cached entry stays fresh before a background refresh is triggered.
  static const Duration ttl = Duration(minutes: 30);

  /// Returns the full entry for [id], or null if not cached / expired.
  CacheEntry? getEntry(String id) {
    final entry = _cache[id];
    if (entry == null) return null;
    if (DateTime.now().difference(entry.cachedAt) > ttl) {
      _cache.remove(id);
      return null;
    }
    return entry;
  }

  /// Convenience: just the song list.
  Future<List<Song>?> getSongs(String id) async {
    // L1: in-memory check
    final entry = getEntry(id);
    if (entry != null) return entry.songs;
    // L2: SQLite check
    final rows = await _db?.getCollectionTracks(id);
    if (rows == null) return null;
    final songs = rows.map((r) => Song.fromJson(r)).toList();
    // Populate L1
    _cache[id] = CacheEntry(
      songs: songs,
      cachedAt: DateTime.now(),
    );
    return songs;
  }

  /// Convenience: just the palette color.
  Future<Color?> getPaletteColor(String id) async {
    // L1: in-memory check
    final entry = getEntry(id);
    if (entry?.paletteColor != null) return entry!.paletteColor;
    // L2: SQLite check
    final colorValue = await _db?.getPlaylistPaletteColor(id);
    if (colorValue == null) return null;
    return Color(colorValue);
  }

  /// Stores songs (and optionally palette + imageUrl) for [id].
  void put(String id, List<Song> songs, {Color? paletteColor, String? imageUrl}) {
    final existing = _cache[id];
    _cache[id] = CacheEntry(
      songs: songs,
      cachedAt: DateTime.now(),
      // Keep existing palette/image if not provided (e.g. songs refreshed before palette extracted)
      paletteColor: paletteColor ?? existing?.paletteColor,
      imageUrl: imageUrl ?? existing?.imageUrl,
    );
    // Persist to L2 SQLite
    final serialized = songs.map((s) => s.toJson()).toList();
    _db?.upsertCollectionTracks(id, serialized).ignore();
    if (paletteColor != null || imageUrl != null) {
      _db?.upsertPlaylistCache(id, paletteColor?.toARGB32(), imageUrl).ignore();
    }
  }

  /// Updates only the palette color for an already-cached entry.
  void updatePalette(String id, Color paletteColor) {
    final existing = _cache[id];
    if (existing == null) return;
    _cache[id] = CacheEntry(
      songs: existing.songs,
      cachedAt: existing.cachedAt,
      paletteColor: paletteColor,
      imageUrl: existing.imageUrl,
    );
  }

  /// Removes a single entry (force-refresh).
  void invalidate(String id) {
    _cache.remove(id);
    _db?.deleteCollectionTracks(id).ignore();
  }

  /// Clears all cached entries (call on logout).
  void clear() {
    _cache.clear();
    _db?.clearCacheOnlyPlaylists().ignore();
    _db?.clearCacheOnlyCollectionTracks().ignore();
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
