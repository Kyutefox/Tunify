import 'package:flutter/material.dart';
import 'package:tunify/v2/core/constants/app_colors.dart';
import 'package:tunify/v2/core/constants/app_icons.dart';
import 'package:tunify/v2/core/widgets/art/artwork_or_gradient.dart';
import 'package:tunify/v2/features/library/domain/entities/library_item.dart';
import 'package:tunify/v2/features/library/presentation/widgets/system_artwork.dart';

/// Library / collection artwork: remote image, [SystemArtwork], or flat placeholder + icon.
///
/// Folders and coverless playlists use the same flat surface as [ArtworkOrGradient] with no URL —
/// no gradients here (those stay on static system playlists and detail scaffold palettes).
///
/// [preferredImageUrl] is checked before [item.imageUrl] (e.g. detail hero URL).
class LibraryCollectionArtwork extends StatelessWidget {
  const LibraryCollectionArtwork({
    super.key,
    required this.item,
    this.preferredImageUrl,
    required this.size,
    this.borderRadius = 4,
  });

  final LibraryItem item;

  /// When set (e.g. [LibraryDetailsModel.heroImageUrl]), used before [item.imageUrl].
  final String? preferredImageUrl;
  final double size;
  final double borderRadius;

  String? _effectiveUrl() {
    final p = preferredImageUrl?.trim();
    if (p != null && p.isNotEmpty) {
      return p;
    }
    final i = item.imageUrl?.trim();
    if (i != null && i.isNotEmpty) {
      return i;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    if (item.systemArtwork != null) {
      return SystemArtwork(
        type: item.systemArtwork!,
        size: size,
        borderRadius: borderRadius,
      );
    }

    if (item.kind == LibraryItemKind.folder) {
      return _IconPlaceholderTile(
        size: size,
        borderRadius: borderRadius,
        icon: AppIcons.folder,
      );
    }

    final url = _effectiveUrl();
    if (url != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: SizedBox(
          width: size,
          height: size,
          child: ArtworkOrGradient(imageUrl: url),
        ),
      );
    }

    if (item.kind == LibraryItemKind.playlist) {
      return _IconPlaceholderTile(
        size: size,
        borderRadius: borderRadius,
        icon: AppIcons.playlist,
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: SizedBox(
        width: size,
        height: size,
        child: ArtworkOrGradient(imageUrl: null),
      ),
    );
  }
}

class _IconPlaceholderTile extends StatelessWidget {
  const _IconPlaceholderTile({
    required this.size,
    required this.borderRadius,
    required this.icon,
  });

  final double size;
  final double borderRadius;
  final List<List<dynamic>> icon;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: SizedBox(
        width: size,
        height: size,
        child: ColoredBox(
          color: AppColors.darkSurface,
          child: Center(
            child: AppIcon(
              icon: icon,
              color: AppColors.silver,
              size: size * 0.42,
            ),
          ),
        ),
      ),
    );
  }
}
