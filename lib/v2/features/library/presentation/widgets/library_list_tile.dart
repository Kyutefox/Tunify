import 'package:flutter/material.dart';
import 'package:tunify/v2/core/constants/app_border_radius.dart';
import 'package:tunify/v2/core/constants/app_colors.dart';
import 'package:tunify/v2/core/constants/app_icons.dart';
import 'package:tunify/v2/core/constants/app_spacing.dart';
import 'package:tunify/v2/core/theme/app_text_styles.dart';
import 'package:tunify/v2/core/widgets/buttons/tunify_press_feedback.dart';
import 'package:tunify/v2/features/library/domain/entities/library_item.dart';
import 'package:tunify/v2/features/library/presentation/constants/library_layout.dart';
import 'package:tunify/v2/features/library/presentation/widgets/library_collection_artwork.dart';
import 'package:tunify/v2/features/library/presentation/widgets/library_item_options_sheet.dart';

/// Single row in the library list view (Figma Image 3).
///
/// 54×54 artwork (artists → circular), 15px title white, 13px subtitle silver,
/// green pin dot inline before subtitle for pinned items.
class LibraryListTile extends StatelessWidget {
  const LibraryListTile({
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
    final radius =
        isCircular ? LibraryLayout.listThumbSize / 2 : AppBorderRadius.subtle;

    return TunifyPressFeedback(
      borderRadius: BorderRadius.circular(AppBorderRadius.subtle),
      onTap: onTap,
      onLongPress: () => showLibraryItemOptionsSheet(
        context,
        item,
        libraryListScopeFolderId: libraryListScopeFolderId,
      ),
      child: SizedBox(
        height: LibraryLayout.listRowHeight,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: LibraryLayout.horizontalPadding,
          ),
          child: Row(
            children: [
              // ── Artwork thumbnail ──
              LibraryCollectionArtwork(
                item: item,
                size: LibraryLayout.listThumbSize,
                borderRadius: radius,
                loadTrackThumbnails: item.isUserOwnedPlaylist,
              ),
              const SizedBox(width: LibraryLayout.listThumbTextGap),

              // ── Title + subtitle ──
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      item.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.body,
                    ),
                    const SizedBox(height: LibraryLayout.listTitleSubtitleGap),
                    Row(
                      children: [
                        if (item.isPinned) ...[
                          const _PinIcon(),
                          const SizedBox(width: AppSpacing.sm),
                        ],
                        Flexible(
                          child: Text(
                            item.subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.caption,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Spotify-style green push-pin icon for pinned items.
class _PinIcon extends StatelessWidget {
  const _PinIcon();

  @override
  Widget build(BuildContext context) {
    return AppIcon(
      icon: AppIcons.pushPin,
      size: LibraryLayout.pinIconSize,
      color: AppColors.brandGreen,
    );
  }
}
