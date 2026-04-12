import 'package:flutter/material.dart';
import 'package:tunify/v2/core/constants/app_spacing.dart';
import 'package:tunify/v2/core/theme/app_text_styles.dart';
import 'package:tunify/v2/core/widgets/cards/album_shelf_card.dart';
import 'package:tunify/v2/core/widgets/cards/artist_shelf_card.dart';
import 'package:tunify/v2/features/home/domain/entities/home_block.dart';
import 'package:tunify/v2/features/home/presentation/constants/home_layout.dart';

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

    final isCircle = section.thumbKind == HomeCarouselThumbKind.circle94;

    return Padding(
      padding: EdgeInsets.only(
        bottom: HomeLayout.shelfTrailingAfterContent,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
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
          Padding(
            padding: const EdgeInsets.only(left: AppSpacing.lg),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final thumb = HomeLayout.carouselThumbSize(constraints.maxWidth);
                final gapW = AppSpacing.lg;
                final tiles = <Widget>[];
                for (var i = 0; i < section.items.length; i++) {
                  if (i > 0) {
                    tiles.add(SizedBox(width: gapW));
                  }
                  final item = section.items[i];
                  tiles.add(
                    SizedBox(
                      width: thumb,
                      child: isCircle
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
                }
                // Fixed [ListView] height + cross-axis centering left a tall empty band under
                // short subtitles, so shelf→shelf gaps looked huge vs Quick picks → first shelf.
                // Intrinsic row height matches the tallest tile in this shelf only.
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: tiles,
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
