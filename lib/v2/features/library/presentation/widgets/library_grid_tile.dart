import 'package:flutter/material.dart';
import 'package:tunify/v2/core/constants/app_border_radius.dart';
import 'package:tunify/v2/core/constants/app_colors.dart';
import 'package:tunify/v2/core/constants/app_spacing.dart';
import 'package:tunify/v2/core/theme/app_text_styles.dart';
import 'package:tunify/v2/core/widgets/buttons/tunify_press_feedback.dart';
import 'package:tunify/v2/features/library/domain/entities/library_item.dart';
import 'package:tunify/v2/features/library/presentation/widgets/library_collection_artwork.dart';
import 'package:tunify/v2/features/library/presentation/widgets/library_item_options_sheet.dart';

/// Single cell in the library grid view (Figma Image 1 & 2).
///
/// Square artwork filling the available width (artists → circular clip),
/// title (white, bold 11px) and subtitle (silver 11px) below.
class LibraryGridTile extends StatelessWidget {
  const LibraryGridTile({
    super.key,
    required this.item,
    this.onTap,
    this.libraryListScopeFolderId,
  });

  final LibraryItem item;
  final VoidCallback? onTap;

  /// When set (folder screen), long-press invalidations refresh this folder list too.
  final String? libraryListScopeFolderId;

  @override
  Widget build(BuildContext context) {
    final isCircular = item.kind == LibraryItemKind.artist;

    return TunifyPressFeedback(
      borderRadius: BorderRadius.circular(AppBorderRadius.standard),
      onTap: onTap,
      onLongPress: () => showLibraryItemOptionsSheet(
        context,
        item,
        libraryListScopeFolderId: libraryListScopeFolderId,
      ),
      child: Column(
        crossAxisAlignment:
            isCircular ? CrossAxisAlignment.center : CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 1,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final size = constraints.maxWidth;
                final radius = isCircular ? size / 2 : AppBorderRadius.standard;

                return LibraryCollectionArtwork(
                  item: item,
                  size: size,
                  borderRadius: radius,
                  loadTrackThumbnails: item.isUserOwnedPlaylist,
                );
              },
            ),
          ),
          const SizedBox(height: AppSpacing.md - AppSpacing.xs),
          Text(
            item.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: isCircular ? TextAlign.center : TextAlign.left,
            style: AppTextStyles.small.copyWith(
              color: AppColors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (item.kind != LibraryItemKind.artist)
            Text(
              item.subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.micro,
            ),
          if (item.kind == LibraryItemKind.artist)
            Text(
              'Artist',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: AppTextStyles.micro,
            ),
        ],
      ),
    );
  }
}
