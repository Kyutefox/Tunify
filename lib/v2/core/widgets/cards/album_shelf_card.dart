import 'package:flutter/material.dart';
import 'package:tunify/v2/core/constants/app_spacing.dart';
import 'package:tunify/v2/core/theme/app_text_styles.dart';
import 'package:tunify/v2/core/widgets/art/artwork_or_gradient.dart';

/// Square / rounded-square shelf tile (albums, playlists).
class AlbumShelfCard extends StatelessWidget {
  const AlbumShelfCard({
    super.key,
    required this.thumbSize,
    required this.title,
    this.subtitle,
    required this.imageBorderRadius,
    required this.mockArtArgbColors,
    this.artworkUrl,
  });

  final double thumbSize;
  final String title;
  final String? subtitle;
  final double imageBorderRadius;
  final List<int> mockArtArgbColors;
  final String? artworkUrl;

  @override
  Widget build(BuildContext context) {
    final radius = imageBorderRadius >= 999 ? thumbSize / 2 : imageBorderRadius;

    return SizedBox(
      width: thumbSize,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(radius),
            child: SizedBox(
              width: thumbSize,
              height: thumbSize,
              child: ArtworkOrGradient(
                imageUrl: artworkUrl,
                fallbackArgbColors: mockArtArgbColors,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.smallBold.copyWith(fontWeight: FontWeight.w500),
          ),
          if (subtitle != null)
            Text(
              subtitle!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.small,
            ),
        ],
      ),
    );
  }
}
