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
        top: section.sectionTopPadding,
        bottom: AppSpacing.md,
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
          SizedBox(height: section.titleToCarouselGap),
          Padding(
            padding: const EdgeInsets.only(left: AppSpacing.lg),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final thumb = HomeLayout.carouselThumbSize(constraints.maxWidth);
                final shelfHeight = HomeLayout.carouselShelfHeight(thumb);

                return SizedBox(
                  height: shelfHeight,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: section.items.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(width: AppSpacing.lg),
                    itemBuilder: (context, index) {
                      final item = section.items[index];
                      if (isCircle) {
                        return ArtistShelfCard(
                          thumbSize: thumb,
                          title: item.title,
                          mockArtArgbColors: item.imageColors,
                        );
                      }
                      return AlbumShelfCard(
                        thumbSize: thumb,
                        title: item.title,
                        subtitle: item.subtitle,
                        imageBorderRadius: item.imageBorderRadius,
                        mockArtArgbColors: item.imageColors,
                      );
                    },
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
