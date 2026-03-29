import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:palette_generator/palette_generator.dart';

import 'package:tunify/ui/theme/app_colors.dart';
import 'package:tunify/features/player/player_state_provider.dart';

/// Shared dominant-color provider driven by the currently playing song.
///
/// Consumed by [MiniPlayer], [DesktopPlayerBar], and [PlayerScreen] so the
/// album-art color bleeds consistently across all player surfaces.
///
/// ## Preloading
/// When the queue advances, the next song's palette is extracted into [_cache]
/// in the background via [_schedulePreload]. When that song actually becomes
/// current, [_extract] finds the color already in cache and emits synchronously
/// — no surfaceLight flash, no async frame miss.
final dominantColorProvider =
    NotifierProvider<_DominantColorNotifier, Color>(_DominantColorNotifier.new);

class _DominantColorNotifier extends Notifier<Color> {
  static const _cacheMax = 20;
  final Map<String, Color> _cache = {};

  /// URL of the in-flight *current-song* extraction. Guards against duplicate
  /// concurrent extractions for the active song.
  String? _inflight;

  /// URLs of in-flight *preload* extractions. Kept separate from [_inflight]
  /// so a preload can never block or clobber the current-song extraction path.
  final Set<String> _preloadInflight = {};

  @override
  Color build() {
    // ── Current song ────────────────────────────────────────────────────────
    ref.listen(currentSongProvider, (prev, next) {
      if (next?.thumbnailUrl != prev?.thumbnailUrl) {
        _extract(next?.thumbnailUrl);
      }
    });

    // ── Next-song preload ────────────────────────────────────────────────────
    // Mirrors the audio crossfade pre-load: when queue[currentIndex+1] becomes
    // known, extract its palette into cache so the color transition on song
    // change is instant. The select fires at most once per queue advance —
    // never on position ticks — so provider overhead is negligible.
    ref.listen(
      playerProvider.select((s) {
        final nextIdx = s.currentIndex + 1;
        return nextIdx < s.queue.length ? s.queue[nextIdx].thumbnailUrl : null;
      }),
      (_, nextUrl) {
        if (nextUrl != null && nextUrl.isNotEmpty) _schedulePreload(nextUrl);
      },
    );

    // Kick off extraction for the song that's already playing on first build.
    final url = ref.read(currentSongProvider)?.thumbnailUrl;
    if (url != null && url.isNotEmpty) _extract(url);
    // Return cached color immediately if available — avoids the surfaceLight
    // flash on first open when the palette has already been extracted.
    if (url != null && url.isNotEmpty && _cache.containsKey(url)) {
      return _cache[url]!;
    }
    return (url == null || url.isEmpty) ? Colors.white : AppColors.surfaceLight;
  }

  /// Extracts the palette for [url] and emits it as the new state.
  /// If [url] is already cached, emits synchronously (zero frame cost).
  Future<void> _extract(String? url) async {
    if (url == null || url.isEmpty) {
      state = Colors.white;
      return;
    }
    if (_cache.containsKey(url)) {
      state = _cache[url]!;
      return;
    }
    if (_inflight == url) return;
    _inflight = url;

    try {
      await _extractToCache(url);
      // Only emit if the color was successfully cached (extraction may fail).
      if (_cache.containsKey(url)) state = _cache[url]!;
    } catch (_) {
      // Keep current state on failure — don't flash to primary.
    } finally {
      _inflight = null;
    }
  }

  /// Schedules a background palette extraction for [url] without emitting state.
  ///
  /// No-op if the URL is already cached, currently being extracted as the
  /// active song, or already preloading. Both paths write the same cache entry
  /// so there is no race between preload and current-song extraction.
  void _schedulePreload(String url) {
    if (url.isEmpty) return;
    if (_cache.containsKey(url)) return;
    if (_preloadInflight.contains(url)) return;
    if (_inflight == url) return;
    _preloadInflight.add(url);
    _extractToCache(url).whenComplete(() => _preloadInflight.remove(url));
  }

  /// Core extraction: runs [PaletteGenerator] and writes [_boost]ed color to
  /// [_cache]. Never sets [state] — safe from both the current-song path and
  /// the preload path without risk of emitting stale colors.
  Future<void> _extractToCache(String url) async {
    try {
      final gen = await PaletteGenerator.fromImageProvider(
        CachedNetworkImageProvider(url),
        size: const Size(100, 100), // ~75% fewer pixels than 200×200
      );
      final raw = gen.vibrantColor?.color ??
          gen.lightVibrantColor?.color ??
          gen.dominantColor?.color ??
          AppColors.primary;
      if (_cache.length >= _cacheMax) _cache.remove(_cache.keys.first);
      _cache[url] = _boost(raw);
    } catch (_) {
      // Non-fatal — _extract() will retry when this URL becomes current.
    }
  }

  Color _boost(Color raw) {
    final hsl = HSLColor.fromColor(raw);
    return hsl
        .withLightness((hsl.lightness + 0.12).clamp(0.32, 0.68))
        .withSaturation((hsl.saturation + 0.15).clamp(0.0, 1.0))
        .toColor();
  }
}
