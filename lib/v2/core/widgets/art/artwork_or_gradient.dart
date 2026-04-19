import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:tunify/v2/core/constants/app_colors.dart';

/// Remote artwork when [imageUrl] is set; otherwise a neutral dark placeholder.
///
/// Loading shimmer is handled by [Skeletonizer] at the page level —
/// individual widgets don't need gradient placeholders.
class ArtworkOrGradient extends StatelessWidget {
  const ArtworkOrGradient({
    super.key,
    this.imageUrl,
    this.fallbackArgbColors = const [],
    this.fit = BoxFit.cover,
    this.alignment = Alignment.center,
  });

  final String? imageUrl;

  /// Kept for API compat but no longer rendered as a gradient.
  final List<int> fallbackArgbColors;
  final BoxFit fit;
  final Alignment alignment;

  static const _placeholder = ColoredBox(color: AppColors.darkSurface);

  @override
  Widget build(BuildContext context) {
    final url = imageUrl?.trim();
    if (url != null && url.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: url,
        fit: fit,
        alignment: alignment,
        fadeInDuration: const Duration(milliseconds: 150),
        // Optimize memory usage by caching at reasonable sizes
        maxWidthDiskCache: 800,
        maxHeightDiskCache: 800,
        placeholder: (_, __) => _placeholder,
        errorWidget: (_, __, ___) => _placeholder,
      );
    }
    return _placeholder;
  }
}
