import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:palette_generator/palette_generator.dart';
import 'package:tunify/v2/core/utils/logger.dart';

/// Dominant / vibrant colors derived from remote artwork for UI gradients.
final class ExtractedImagePalette {
  const ExtractedImagePalette({
    required this.gradientTop,
    this.gradientMid,
  });

  /// Top of the screen gradient (boosted for readability on dark UI).
  final Color gradientTop;

  /// Optional bridge color toward [nearBlack] (darker / muted from the same image).
  final Color? gradientMid;
}

/// Extracts a small palette from a network image using [PaletteGenerator].
abstract final class ImagePaletteExtractor {
  ImagePaletteExtractor._();

  /// Returns null if [url] is empty or extraction fails.
  static Future<ExtractedImagePalette?> fromNetworkUrl(String url) async {
    final trimmed = url.trim();
    if (trimmed.isEmpty) {
      return null;
    }
    try {
      final gen = await PaletteGenerator.fromImageProvider(
        CachedNetworkImageProvider(trimmed),
        size: const Size(112, 112),
      );
      final rawTop = gen.vibrantColor?.color ??
          gen.lightVibrantColor?.color ??
          gen.dominantColor?.color;
      if (rawTop == null) {
        return null;
      }
      final top = _boostTop(rawTop);
      final rawMid = gen.darkVibrantColor?.color ??
          gen.mutedColor?.color ??
          gen.dominantColor?.color;
      Color? mid;
      if (rawMid != null) {
        final m = _midStop(rawMid);
        if (m != top) {
          mid = m;
        }
      }
      return ExtractedImagePalette(gradientTop: top, gradientMid: mid);
    } on Object catch (e, st) {
      Logger.error(
        'Palette extraction failed (using default palette)',
        tag: 'ImagePaletteExtractor',
        error: e,
        stackTrace: st,
      );
      return null;
    }
  }

  static Color _boostTop(Color raw) {
    final hsl = HSLColor.fromColor(raw);
    return hsl
        .withLightness((hsl.lightness + 0.1).clamp(0.28, 0.62))
        .withSaturation((hsl.saturation + 0.12).clamp(0.0, 1.0))
        .toColor();
  }

  static Color _midStop(Color raw) {
    final hsl = HSLColor.fromColor(raw);
    return hsl
        .withLightness((hsl.lightness * 0.42).clamp(0.06, 0.28))
        .withSaturation((hsl.saturation * 0.85).clamp(0.15, 1.0))
        .toColor();
  }
}
