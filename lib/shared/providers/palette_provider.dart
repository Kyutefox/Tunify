import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:palette_generator/palette_generator.dart';

import '../../ui/theme/app_colors.dart';
import 'player_state_provider.dart';

/// Shared dominant-color provider driven by the currently playing song.
///
/// Consumed by [MiniPlayer], [DesktopPlayerBar], and [PlayerScreen] so the
/// album-art color bleeds consistently across all player surfaces.
final dominantColorProvider =
    NotifierProvider<_DominantColorNotifier, Color>(_DominantColorNotifier.new);

class _DominantColorNotifier extends Notifier<Color> {
  static const _cacheMax = 20;
  final Map<String, Color> _cache = {};
  String? _inflight;

  @override
  Color build() {
    ref.listen(currentSongProvider, (prev, next) {
      if (next?.thumbnailUrl != prev?.thumbnailUrl) {
        _extract(next?.thumbnailUrl);
      }
    });
    // Kick off extraction for the song that's already playing on first build.
    final url = ref.read(currentSongProvider)?.thumbnailUrl;
    if (url != null) _extract(url);
    return AppColors.primary;
  }

  Future<void> _extract(String? url) async {
    if (url == null) {
      state = AppColors.primary;
      return;
    }
    if (_cache.containsKey(url)) {
      state = _cache[url]!;
      return;
    }
    if (_inflight == url) return;
    _inflight = url;
    try {
      final gen = await PaletteGenerator.fromImageProvider(
        CachedNetworkImageProvider(url),
        size: const Size(200, 200),
      );
      final raw = gen.vibrantColor?.color ??
          gen.lightVibrantColor?.color ??
          gen.dominantColor?.color ??
          AppColors.primary;
      final boosted = _boost(raw);
      if (_cache.length >= _cacheMax) {
        _cache.remove(_cache.keys.first);
      }
      _cache[url] = boosted;
      state = boosted;
    } catch (_) {
      state = AppColors.primary;
    } finally {
      _inflight = null;
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
