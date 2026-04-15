import 'package:tunify/v2/features/home/domain/entities/home_block.dart';
import 'package:tunify/v2/features/home/domain/entities/home_feed.dart';

/// Fake [HomeFeed] with placeholder text for [Skeletonizer].
///
/// Skeletonizer auto-generates bone shapes from the real widget tree;
/// we just need plausible text lengths so the bones look right.
class HomeFeedSkeleton {
  HomeFeedSkeleton._();

  static HomeFeed build() {
    return HomeFeed(
      blocks: [
        HomeSlimGridBlock(
          tiles: List.generate(
            8,
            (i) => HomeSlimTile(
              id: 'sk-s$i',
              title: 'Loading track title',
              thumbColors: const [],
            ),
          ),
        ),
        HomeHeroRecommendedBlock(
          HomeHeroRecommended(
            sectionLabel: 'Continue listening',
            sectionTitle: 'Loading artist name',
            cardTitle: 'Loading album',
            cardSubtitle: 'Loading artist',
            avatarColors: const [],
            squareArtColors: const [],
          ),
        ),
        HomeCarouselBlock(
          HomeCarouselSection(
            id: 'sk-c1',
            title: 'Jump back in',
            titleSize: HomeCarouselTitleSize.title22,
            thumbKind: HomeCarouselThumbKind.square147,
            items: List.generate(
              4,
              (i) => HomeCarouselItem(
                id: 'sk-c1-$i',
                title: 'Loading playlist',
                subtitle: 'Loading description text',
                imageColors: const [],
              ),
            ),
          ),
        ),
        HomeCarouselBlock(
          HomeCarouselSection(
            id: 'sk-c2',
            title: 'Your favorite artists',
            titleSize: HomeCarouselTitleSize.title18,
            thumbKind: HomeCarouselThumbKind.circle94,
            items: List.generate(
              4,
              (i) => HomeCarouselItem(
                id: 'sk-c2-$i',
                title: 'Loading artist',
                imageColors: const [],
                imageBorderRadius: 9999,
              ),
            ),
          ),
        ),
        HomeCarouselBlock(
          HomeCarouselSection(
            id: 'sk-c3',
            title: 'Made for you',
            titleSize: HomeCarouselTitleSize.title22,
            thumbKind: HomeCarouselThumbKind.square147,
            items: List.generate(
              4,
              (i) => HomeCarouselItem(
                id: 'sk-c3-$i',
                title: 'Loading playlist',
                subtitle: 'Loading description text',
                imageColors: const [],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
