import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tunify/ui/theme/app_colors.dart';
import 'package:tunify/features/player/palette_service.dart';
import 'package:tunify/features/player/player_state_provider.dart';

/// Shared dominant-color provider driven by the currently playing song.
///
/// Consumed by [MiniPlayer], [DesktopPlayerBar], and [PlayerScreen] so the
/// album-art color bleeds consistently across all player surfaces.
///
/// Extraction and caching (memory + Hive) are fully delegated to
/// [PaletteService], which is the single source of truth shared with the
/// collection detail screens.
///
/// ## Preloading
/// When the queue advances, the next song's palette is prefetched via
/// [PaletteService.prefetch] so the color is ready before the song becomes
/// current — no surfaceLight flash, no async frame miss.
final dominantColorProvider =
    NotifierProvider<_DominantColorNotifier, Color>(_DominantColorNotifier.new);

class _DominantColorNotifier extends Notifier<Color> {
  final _svc = PaletteService.instance;

  @override
  Color build() {
    // ── Current song ────────────────────────────────────────────────────────
    ref.listen(currentSongProvider, (prev, next) {
      if (next?.thumbnailUrl != prev?.thumbnailUrl) {
        _extract(next?.thumbnailUrl);
      }
    });

    // ── Next-song preload ────────────────────────────────────────────────────
    ref.listen(
      playerProvider.select((s) {
        final nextIdx = s.currentIndex + 1;
        return nextIdx < s.queue.length ? s.queue[nextIdx].thumbnailUrl : null;
      }),
      (_, nextUrl) => _svc.prefetch(nextUrl),
    );

    // Kick off extraction for the song already playing on first build.
    final url = ref.read(currentSongProvider)?.thumbnailUrl;
    if (url != null && url.isNotEmpty) _extract(url);

    // Return from memory cache immediately if available — zero-frame cost.
    final cached = _svc.getCached(url);
    if (cached != null) return cached;
    return (url == null || url.isEmpty) ? Colors.white : AppColors.surfaceLight;
  }

  Future<void> _extract(String? url) async {
    if (url == null || url.isEmpty) {
      state = Colors.white;
      return;
    }
    // Synchronous memory hit — emit immediately.
    final cached = _svc.getCached(url);
    if (cached != null) {
      state = cached;
      return;
    }
    // Async path — Hive hit or full extraction via PaletteService.
    final color = await _svc.get(url);
    if (color != null) state = color;
  }
}
