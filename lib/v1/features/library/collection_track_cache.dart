import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:tunify/v1/data/models/song.dart';

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
      description: map['description'] as String?,
      curatorName: map['curatorName'] as String?,
      curatorThumbnailUrl: map['curatorThumbnailUrl'] as String?,
      headerSubtitle: map['headerSubtitle'] as String?,
      headerSecondSubtitle: map['headerSecondSubtitle'] as String?,
      collectionTitle: map['collectionTitle'] as String?,
    );
  }

  /// Returns songs for [id] from Hive, or null if missing / expired.
  Future<List<Song>?> getSongs(String id) async {
    return (await getEntryFromCache(id))?.songs;
  }

  /// Stores [songs], image/palette, and optional header metadata for [id] in Hive.
  void put(
    String id,
    List<Song> songs, {
    Color? paletteColor,
    String? imageUrl,
    String? description,
    String? curatorName,
    String? curatorThumbnailUrl,
    String? headerSubtitle,
    String? headerSecondSubtitle,
    String? collectionTitle,
  }) {
    final now = DateTime.now();
    _getBox().then((box) {
      final prevRaw = box.get(id);
      final map = prevRaw != null
          ? Map<String, dynamic>.from(prevRaw as Map)
          : <String, dynamic>{};
      map['tracks'] = songs.map((s) => s.toJson()).toList();
      map['cachedAt'] = now.toUtc().toIso8601String();
      if (imageUrl != null) map['imageUrl'] = imageUrl;
      if (paletteColor != null) map['paletteColor'] = paletteColor.toARGB32();
      if (description != null) map['description'] = description;
      if (curatorName != null) map['curatorName'] = curatorName;
      if (curatorThumbnailUrl != null) {
        map['curatorThumbnailUrl'] = curatorThumbnailUrl;
      }
      if (headerSubtitle != null) map['headerSubtitle'] = headerSubtitle;
      if (headerSecondSubtitle != null) {
        map['headerSecondSubtitle'] = headerSecondSubtitle;
      }
      if (collectionTitle != null) {
        map['collectionTitle'] = collectionTitle;
      }
      box.put(id, map);
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
    this.description,
    this.curatorName,
    this.curatorThumbnailUrl,
    this.headerSubtitle,
    this.headerSecondSubtitle,
    this.collectionTitle,
  });
  final List<Song> songs;
  final DateTime cachedAt;
  final Color? paletteColor;
  final String? imageUrl;
  final String? description;
  final String? curatorName;
  final String? curatorThumbnailUrl;
  final String? headerSubtitle;
  final String? headerSecondSubtitle;

  /// Browse canonical name (e.g. artist channel title from immersive header).
  final String? collectionTitle;
}
