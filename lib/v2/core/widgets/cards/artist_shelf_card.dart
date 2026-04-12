import 'package:flutter/material.dart';
import 'package:tunify/v2/core/constants/app_colors.dart';
import 'package:tunify/v2/core/constants/app_spacing.dart';
import 'package:tunify/v2/core/theme/app_text_styles.dart';
import 'package:tunify/v2/core/widgets/art/artwork_or_gradient.dart';

/// Circular-art shelf tile (artists).
class ArtistShelfCard extends StatelessWidget {
  const ArtistShelfCard({
    super.key,
    required this.thumbSize,
    required this.title,
    required this.mockArtArgbColors,
    this.artworkUrl,
  });

  final double thumbSize;
  final String title;
  final List<int> mockArtArgbColors;
  final String? artworkUrl;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: thumbSize,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(thumbSize / 2),
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
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.small.copyWith(color: AppColors.white),
          ),
        ],
      ),
    );
  }
}
