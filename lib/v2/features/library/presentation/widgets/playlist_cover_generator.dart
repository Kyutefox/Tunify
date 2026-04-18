import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:tunify/v2/core/constants/app_border_radius.dart';
import 'package:tunify/v2/core/constants/app_colors.dart';
import 'package:tunify/v2/features/library/domain/entities/library_details.dart';

/// Generates playlist cover artwork based on track count.
/// - 0 tracks: Icon-based placeholder
/// - 1 track: Full image cover
/// - 2+ tracks: 2x2 mosaic grid (fills cells in order, max 4 images shown)
class PlaylistCoverGenerator extends StatelessWidget {
  const PlaylistCoverGenerator({
    super.key,
    required this.tracks,
    required this.size,
    this.borderRadius,
    this.customImageUrl,
    this.isEmptyStateIcon = Icons.music_note,
  });

  final List<LibraryDetailsTrack> tracks;
  final double size;
  final BorderRadius? borderRadius;
  final String? customImageUrl;
  final IconData? isEmptyStateIcon;

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? BorderRadius.circular(AppBorderRadius.subtle);

    // Use custom image if provided
    if (customImageUrl != null && customImageUrl!.isNotEmpty) {
      return _buildImageCover(customImageUrl!, radius);
    }

    // Empty state - icon placeholder
    if (tracks.isEmpty) {
      return _buildEmptyState(radius);
    }

    // 1 track - full image
    if (tracks.length == 1) {
      final url = tracks.first.thumbUrl;
      if (url != null && url.isNotEmpty) {
        return _buildImageCover(url, radius);
      }
      return _buildEmptyState(radius);
    }

    // 2+ tracks - 2x2 mosaic grid
    return _buildMosaic(radius);
  }

  Widget _buildImageCover(String url, BorderRadius radius) {
    return ClipRRect(
      borderRadius: radius,
      child: CachedNetworkImage(
        imageUrl: url,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorWidget: (_, __, ___) => _buildEmptyState(radius),
      ),
    );
  }

  Widget _buildEmptyState(BorderRadius radius) {
    return ClipRRect(
      borderRadius: radius,
      child: Container(
        width: size,
        height: size,
        color: AppColors.midDark,
        child: Center(
          child: Icon(
            isEmptyStateIcon ?? Icons.music_note,
            color: AppColors.silver,
            size: size * 0.4,
          ),
        ),
      ),
    );
  }

  Widget _buildMosaic(BorderRadius radius) {
    const gap = 1.5;
    final cell = (size - gap) / 2;
    final urls = tracks.take(4).map((t) => t.thumbUrl).toList();

    return ClipRRect(
      borderRadius: radius,
      child: ClipRect(
        child: SizedBox(
          width: size,
          height: size,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  _buildCell(urls[0], cell),
                  SizedBox(width: gap),
                  _buildCell(urls.length > 1 ? urls[1] : null, cell),
                ],
              ),
              SizedBox(height: gap),
              Row(
                children: [
                  _buildCell(urls.length > 2 ? urls[2] : null, cell),
                  SizedBox(width: gap),
                  _buildCell(urls.length > 3 ? urls[3] : null, cell),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCell(String? url, double s) {
    if (url == null || url.isEmpty) {
      return _buildPlaceholderCell(s);
    }
    return CachedNetworkImage(
      imageUrl: url,
      width: s,
      height: s,
      fit: BoxFit.cover,
      errorWidget: (_, __, ___) => _buildPlaceholderCell(s),
    );
  }

  Widget _buildPlaceholderCell(double s) {
    return Container(
      width: s,
      height: s,
      color: AppColors.midDark,
      child: Center(
        child: Icon(
          Icons.music_note,
          color: AppColors.silver.withValues(alpha: 0.5),
          size: s * 0.4,
        ),
      ),
    );
  }
}
