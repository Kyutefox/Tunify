import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tunify/v2/core/constants/app_colors.dart';
import 'package:tunify/v2/core/constants/app_icons.dart';
import 'package:tunify/v2/core/widgets/art/artwork_or_gradient.dart';
import 'package:tunify/v2/features/library/domain/entities/library_details.dart';
import 'package:tunify/v2/features/library/domain/entities/library_item.dart';
import 'package:tunify/v2/features/library/presentation/providers/library_providers.dart';
import 'package:tunify/v2/features/library/presentation/widgets/playlist_cover_generator.dart';
import 'package:tunify/v2/features/library/presentation/widgets/system_artwork.dart';

/// Library / collection artwork: remote image, [SystemArtwork], or flat placeholder + icon.
///
/// Folders and coverless playlists use the same flat surface as [ArtworkOrGradient] with no URL —
/// no gradients here (those stay on static system playlists and detail scaffold palettes).
///
/// [preferredImageUrl] is checked before [item.imageUrl] (e.g. detail hero URL).
/// [tracks] can be provided to generate a mosaic cover for user-owned playlists.
/// [loadTrackThumbnails] can be set to true to automatically load track thumbnails for user-owned playlists.
class LibraryCollectionArtwork extends ConsumerWidget {
  const LibraryCollectionArtwork({
    super.key,
    required this.item,
    this.preferredImageUrl,
    required this.size,
    this.borderRadius = 4,
    this.tracks,
    this.loadTrackThumbnails = false,
  });

  final LibraryItem item;

  /// When set (e.g. [LibraryDetailsModel.heroImageUrl]), used before [item.imageUrl].
  final String? preferredImageUrl;
  final double size;
  final double borderRadius;
  final List<LibraryDetailsTrack>? tracks;
  final bool loadTrackThumbnails;

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
  Widget build(BuildContext context, WidgetRef ref) {
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

    // Use cover generator for user-owned playlists when tracks are provided
    if (item.isUserOwnedPlaylist) {
      if (tracks != null) {
        return PlaylistCoverGenerator(
          tracks: tracks!,
          size: size,
          borderRadius: BorderRadius.circular(borderRadius),
          customImageUrl: _effectiveUrl(),
        );
      }
      
      // Load track thumbnails for library list/grid
      if (loadTrackThumbnails) {
        final thumbnailsAsync = ref.watch(playlistTrackThumbnailsProvider(item.id));
        return thumbnailsAsync.when(
          data: (thumbnails) {
            final trackList = thumbnails.map((url) => LibraryDetailsTrack(
              title: '',
              subtitle: '',
              thumbUrl: url,
              videoId: '',
              durationMs: 0,
            )).toList();
            
            return PlaylistCoverGenerator(
              tracks: trackList,
              size: size,
              borderRadius: BorderRadius.circular(borderRadius),
              customImageUrl: _effectiveUrl(),
            );
          },
          loading: () => _buildDefaultCover(),
          error: (_, __) => _buildDefaultCover(),
        );
      }
    }

    return _buildDefaultCover();
  }

  Widget _buildDefaultCover() {
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
