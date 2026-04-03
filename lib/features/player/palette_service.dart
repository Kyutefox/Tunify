import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:palette_generator/palette_generator.dart';

import 'package:tunify/ui/theme/app_colors.dart';

/// Singleton palette extraction service.
///
/// - Single extraction algorithm used by the player, mini-player, desktop bar,
///   and all collection detail screens.
/// - Two-layer cache:
///     1. In-memory LRU (up to [_memCacheMax] entries) — zero-cost on hit.
///     2. Hive box keyed by image URL — survives app restarts.
/// - Deduplication: concurrent requests for the same URL share one extraction.
class PaletteService {
  PaletteService._();
  static final PaletteService instance = PaletteService._();

  static const _boxName = 'palette_cache';
  static const _memCacheMax = 40;

  Box<dynamic>? _box;
  final Map<String, Color> _mem = {};
  final Map<String, Future<Color?>> _inflight = {};

  // ── Hive ──────────────────────────────────────────────────────────────────

  Future<Box<dynamic>> _getBox() async {
    if (_box != null && _box!.isOpen) return _box!;
    _box = await Hive.openBox<dynamic>(_boxName);
    return _box!;
  }

  Future<Color?> _readHive(String url) async {
    final box = await _getBox();
    final raw = box.get(url);
    if (raw == null) return null;
    return Color(raw as int);
  }

  Future<void> _writeHive(String url, Color color) async {
    final box = await _getBox();
    await box.put(url, color.toARGB32());
  }

  // ── Public API ─────────────────────────────────────────────────────────────

  /// Returns the palette color for [url].
  ///
  /// Hit order: memory → Hive → extract.
  /// Concurrent calls for the same URL share one extraction future.
  Future<Color?> get(String? url) async {
    if (url == null || url.isEmpty) return null;

    // 1. Memory hit
    if (_mem.containsKey(url)) return _mem[url];

    // 2. Hive hit
    final persisted = await _readHive(url);
    if (persisted != null) {
      _putMem(url, persisted);
      return persisted;
    }

    // 3. Deduplicated extraction
    if (_inflight.containsKey(url)) return _inflight[url];
    final future = _extract(url);
    _inflight[url] = future;
    try {
      return await future;
    } finally {
      _inflight.remove(url);
    }
  }

  /// Synchronous memory-only lookup — returns null on miss (no Hive/network).
  Color? getCached(String? url) {
    if (url == null || url.isEmpty) return null;
    return _mem[url];
  }

  /// Warms the cache for [url] in the background without returning a value.
  void prefetch(String? url) {
    if (url == null || url.isEmpty) return;
    if (_mem.containsKey(url)) return;
    if (_inflight.containsKey(url)) return;
    get(url); // fire-and-forget
  }

  /// Extracts palette colors from up to 4 [urls] in parallel.
  /// Returns the most visually dominant/saturated color across all images,
  /// or null if all extractions fail.
  Future<Color?> getMulti(List<String?> urls) async {
    final valid = urls.where((u) => u != null && u.isNotEmpty).cast<String>().take(4).toList();
    if (valid.isEmpty) return null;
    if (valid.length == 1) return get(valid.first);

    final colors = await Future.wait(valid.map(get));
    final nonNull = colors.whereType<Color>().toList();
    if (nonNull.isEmpty) return null;
    if (nonNull.length == 1) return nonNull.first;

    // Pick the most saturated color as the primary.
    nonNull.sort((a, b) {
      final sa = HSLColor.fromColor(a).saturation;
      final sb = HSLColor.fromColor(b).saturation;
      return sb.compareTo(sa);
    });
    return nonNull.first;
  }

  /// Extracts palette colors from up to 4 [urls] in parallel and returns a
  /// [LinearGradient] built from the two most visually distinct extracted colors.
  /// Falls back to a single-color gradient if only one image succeeds.
  Future<LinearGradient?> getMultiGradient(List<String?> urls) async {
    final valid = urls.where((u) => u != null && u.isNotEmpty).cast<String>().take(4).toList();
    if (valid.isEmpty) return null;

    final colors = await Future.wait(valid.map(get));
    final nonNull = colors.whereType<Color>().toList();
    if (nonNull.isEmpty) return null;

    // Sort by saturation descending.
    nonNull.sort((a, b) {
      final sa = HSLColor.fromColor(a).saturation;
      final sb = HSLColor.fromColor(b).saturation;
      return sb.compareTo(sa);
    });

    final primary = nonNull.first;
    if (nonNull.length == 1) {
      // Single image — darken primary for second stop.
      final hsl = HSLColor.fromColor(primary);
      final darker = hsl.withLightness((hsl.lightness - 0.18).clamp(0.0, 1.0)).toColor();
      return LinearGradient(
        colors: [primary, darker],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    }

    // Pick a second color maximally different in hue from the primary.
    final primaryHue = HSLColor.fromColor(primary).hue;
    Color secondary = nonNull[1];
    double maxHueDiff = 0;
    for (final c in nonNull.skip(1)) {
      final hue = HSLColor.fromColor(c).hue;
      final diff = (hue - primaryHue).abs();
      final wrappedDiff = diff > 180 ? 360 - diff : diff;
      if (wrappedDiff > maxHueDiff) {
        maxHueDiff = wrappedDiff;
        secondary = c;
      }
    }

    return LinearGradient(
      colors: [primary, secondary],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }

  /// Clears both caches. Call on logout.
  Future<void> clear() async {
    _mem.clear();
    _inflight.clear();
    final box = await _getBox();
    await box.clear();
  }

  // ── Internals ──────────────────────────────────────────────────────────────

  Future<Color?> _extract(String url) async {
    try {
      final gen = await PaletteGenerator.fromImageProvider(
        CachedNetworkImageProvider(url),
        size: const Size(300, 300),
      );

      final dominant = gen.dominantColor?.color;
      final vibrant = gen.vibrantColor?.color;
      final Color raw;

      if (dominant != null) {
        final hsl = HSLColor.fromColor(dominant);
        // Blend vibrant in only when dominant is nearly greyscale.
        if (hsl.saturation < 0.15 && vibrant != null) {
          raw = Color.lerp(dominant, vibrant, 0.6)!;
        } else {
          raw = dominant;
        }
      } else {
        raw = vibrant ?? gen.mutedColor?.color ?? AppColors.primary;
      }

      final color = _boost(raw);
      _putMem(url, color);
      _writeHive(url, color).ignore();
      return color;
    } catch (_) {
      return null;
    }
  }

  void _putMem(String url, Color color) {
    if (_mem.length >= _memCacheMax) _mem.remove(_mem.keys.first);
    _mem[url] = color;
  }

  Color _boost(Color raw) {
    final hsl = HSLColor.fromColor(raw);
    return hsl
        .withLightness((hsl.lightness + 0.10).clamp(0.38, 0.78))
        .withSaturation((hsl.saturation + 0.20).clamp(0.0, 1.0))
        .toColor();
  }
}
