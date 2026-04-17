import 'package:flutter/material.dart';
import 'package:tunify/v2/core/constants/app_colors.dart';
import 'package:tunify/v2/core/widgets/art/artwork_or_gradient.dart';
import 'package:tunify/v2/features/library/domain/entities/library_item.dart';
import 'package:tunify/v2/features/library/presentation/constants/library_details_layout.dart';
import 'package:tunify/v2/features/library/presentation/widgets/system_artwork.dart';

/// Small artwork tile (track list, toolbar, docked action row).
class LibraryDetailMiniCover extends StatelessWidget {
  const LibraryDetailMiniCover({
    super.key,
    required this.item,
    this.imageUrlOverride,
    this.size = LibraryDetailsLayout.miniCoverDefaultSize,
    this.width,
    this.height,
    this.useCollectionImageWhenNoOverride = true,
  });

  final LibraryItem item;
  final String? imageUrlOverride;
  final double size;
  final double? width;
  final double? height;
  final bool useCollectionImageWhenNoOverride;

  @override
  Widget build(BuildContext context) {
    final r = LibraryDetailsLayout.miniCoverCornerRadius;
    final w = width ?? size;
    final h = height ?? size;
    final override = imageUrlOverride?.trim();
    final Widget child;
    if (override != null && override.isNotEmpty) {
      child = ArtworkOrGradient(imageUrl: override);
    } else if (item.systemArtwork != null) {
      final useRect = width != null || height != null;
      final sysSize = useRect ? (w < h ? w : h) : size;
      final artwork = SystemArtwork(
        type: item.systemArtwork!,
        size: sysSize,
        borderRadius: r,
      );
      child = useRect
          ? ColoredBox(
              color: AppColors.darkSurface,
              child: Center(child: artwork),
            )
          : artwork;
    } else if (useCollectionImageWhenNoOverride) {
      child = ArtworkOrGradient(imageUrl: item.imageUrl);
    } else {
      child = const ColoredBox(color: AppColors.darkSurface);
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(r),
      child: SizedBox(
        width: w,
        height: h,
        child: child,
      ),
    );
  }
}
