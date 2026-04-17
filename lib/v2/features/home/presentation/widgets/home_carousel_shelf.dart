import 'package:flutter/material.dart';
import 'package:tunify/v2/core/constants/app_spacing.dart';
import 'package:tunify/v2/core/constants/app_border_radius.dart';
import 'package:tunify/v2/core/theme/app_text_styles.dart';
import 'package:tunify/v2/core/widgets/cards/album_shelf_card.dart';
import 'package:tunify/v2/core/widgets/cards/artist_shelf_card.dart';
import 'package:tunify/v2/core/widgets/buttons/tunify_press_feedback.dart';
import 'package:tunify/v2/features/home/domain/entities/home_block.dart';
import 'package:tunify/v2/features/home/presentation/constants/home_layout.dart';
import 'package:tunify/v2/features/library/domain/entities/library_item.dart';
import 'package:tunify/v2/features/library/presentation/navigation/open_library_detail.dart';
import 'package:tunify/v2/features/library/presentation/widgets/library_item_options_sheet.dart';

/// Horizontal carousel shelf (album / artist rows) using shared shelf cards.
class HomeCarouselShelf extends StatelessWidget {
  const HomeCarouselShelf({
    super.key,
    required this.section,
  });

  final HomeCarouselSection section;

  @override
  Widget build(BuildContext context) {
    final titleStyle = section.titleSize == HomeCarouselTitleSize.title22
        ? AppTextStyles.sectionTitle
        : AppTextStyles.featureHeading.copyWith(fontWeight: FontWeight.w700);

    final screenWidth = MediaQuery.sizeOf(context).width;
    final thumb = HomeLayout.carouselThumbSize(screenWidth - AppSpacing.lg);
    // Estimate row height: thumb + spacing + 2 lines of text.
    final estimatedHeight = thumb + AppSpacing.md + 36;

    return Padding(
      padding: EdgeInsets.only(
        bottom: HomeLayout.shelfTrailingAfterContent,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Text(
              section.title,
              style: titleStyle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(height: HomeLayout.shelfTitleToHorizontalRowGap),
          SizedBox(
            height: estimatedHeight,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.only(left: AppSpacing.lg),
              itemCount: section.items.length,
              addAutomaticKeepAlives: false,
              addRepaintBoundaries: true,
              separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.lg),
              itemBuilder: (context, index) {
                final item = section.items[index];

                final isArtist =
                    section.thumbKind == HomeCarouselThumbKind.circle94;
                final kind = isArtist
                    ? LibraryItemKind.artist
                    : _homeCarouselKindFromSubtitle(item.subtitle);

                final subtitle = switch (kind) {
                  LibraryItemKind.artist => 'Artist',
                  LibraryItemKind.album => 'Album',
                  LibraryItemKind.podcast => 'Podcast',
                  LibraryItemKind.playlist => 'Playlist',
                };

                final libraryItem = LibraryItem(
                  id: item.id,
                  title: item.title,
                  subtitle: subtitle,
                  kind: kind,
                  imageUrl: item.artworkUrl,
                  creatorName: 'Tunify',
                );

                return SizedBox(
                  width: thumb,
                  child: TunifyPressFeedback(
                    borderRadius: BorderRadius.circular(AppBorderRadius.subtle),
                    onTap: () {
                      if (kind == LibraryItemKind.podcast) {
                        return;
                      }
                      pushLibraryDetailFromHomeCarousel(
                        context,
                        browseId: item.id,
                        kind: kind,
                        title: item.title,
                        subtitle: subtitle,
                        imageUrl: item.artworkUrl,
                      );
                    },
                    onLongPress: () =>
                        showLibraryItemOptionsSheet(context, libraryItem),
                    child: isArtist
                        ? ArtistShelfCard(
                            thumbSize: thumb,
                            title: item.title,
                            mockArtArgbColors: item.imageColors,
                            artworkUrl: item.artworkUrl,
                          )
                        : AlbumShelfCard(
                            thumbSize: thumb,
                            title: item.title,
                            subtitle: item.subtitle,
                            imageBorderRadius: item.imageBorderRadius,
                            mockArtArgbColors: item.imageColors,
                            artworkUrl: item.artworkUrl,
                          ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

LibraryItemKind _homeCarouselKindFromSubtitle(String? subtitle) {
  final s = (subtitle ?? '').toLowerCase();
  if (s.contains('album')) return LibraryItemKind.album;
  if (s.contains('podcast')) return LibraryItemKind.podcast;
  if (s.contains('playlist')) return LibraryItemKind.playlist;
  return LibraryItemKind.playlist;
}
