import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:tunify/v2/core/widgets/art/mock_art_gradient.dart';

/// Remote artwork when [imageUrl] is set; otherwise [MockArtGradient] from [fallbackArgbColors].
class ArtworkOrGradient extends StatelessWidget {
  const ArtworkOrGradient({
    super.key,
    this.imageUrl,
    required this.fallbackArgbColors,
    this.fit = BoxFit.cover,
  });

  final String? imageUrl;
  final List<int> fallbackArgbColors;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    final url = imageUrl?.trim();
    if (url != null && url.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: url,
        fit: fit,
        fadeInDuration: const Duration(milliseconds: 150),
        placeholder: (_, __) => DecoratedBox(
          decoration: BoxDecoration(
            gradient: MockArtGradient.linearCover(fallbackArgbColors),
          ),
        ),
        errorWidget: (_, __, ___) => DecoratedBox(
          decoration: BoxDecoration(
            gradient: MockArtGradient.linearCover(fallbackArgbColors),
          ),
        ),
      );
    }
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: MockArtGradient.linearCover(fallbackArgbColors),
      ),
    );
  }
}
