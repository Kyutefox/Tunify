import 'package:tunify/v2/core/constants/app_border_radius.dart';
import 'package:tunify/v2/core/constants/app_spacing.dart';
import 'package:tunify/v2/features/home/domain/entities/home_block.dart';
import 'package:tunify/v2/features/home/domain/entities/home_feed.dart';

/// Static mock feed — mirrors Figma “Homepage” section order where [HomeBlock] types exist.
///
/// Figma Android XML often exports only the root `RelativeLayout` (e.g. 390×4572dp, `#121212`)
/// without children; row content still comes from the full frame / CSS spec.
class HomeFeedMock {
  HomeFeedMock._();

  static HomeFeed build() {
    return HomeFeed(
      blocks: [
        HomeSlimGridBlock(
          tiles: [
            const HomeSlimTile(
              id: 's1',
              title: 'OK Computer',
              thumbColors: [0xFF37474F, 0xFF263238],
              showNowPlayingIndicator: true,
            ),
            const HomeSlimTile(
              id: 's2',
              title: 'Song 2',
              thumbColors: [0xFF5C6BC0, 0xFF3949AB],
            ),
            const HomeSlimTile(
              id: 's3',
              title: 'Kula Shaker',
              thumbColors: [0xFF6D4C41, 0xFF3E2723],
            ),
            const HomeSlimTile(
              id: 's4',
              title: 'Viper',
              thumbColors: [0xFF00897B, 0xFF004D40],
              showMoreMenu: true,
            ),
            const HomeSlimTile(
              id: 's5',
              title: 'The Last Dinner Party',
              thumbColors: [0xFFAD1457, 0xFF6A1B9A],
            ),
            const HomeSlimTile(
              id: 's6',
              title: 'Entering the Body Problem',
              thumbColors: [0xFF455A64, 0xFF263238],
              showSeekBar: true,
              seekProgress: 0.36,
            ),
            const HomeSlimTile(
              id: 's7',
              title: 'Daily Drive',
              thumbColors: [0xFFE65100, 0xFFBF360C],
            ),
            const HomeSlimTile(
              id: 's8',
              title: 'On Repeat',
              thumbColors: [0xFF283593, 0xFF1A237E],
            ),
          ],
        ),
        HomeHeroRecommendedBlock(
          HomeHeroRecommended(
            sectionLabel: 'Continue listening',
            sectionTitle: 'Arctic Monkeys',
            cardTitle: 'AM',
            cardSubtitle: 'Arctic Monkeys',
            avatarColors: [0xFF37474F, 0xFF78909C],
            squareArtColors: [0xFF263238, 0xFF546E7A],
          ),
        ),
        HomeCarouselBlock(
          HomeCarouselSection(
            id: 'c1',
            title: 'Jump back in',
            titleSize: HomeCarouselTitleSize.title22,
            thumbKind: HomeCarouselThumbKind.square147,
            sectionTopPadding: AppSpacing.xl,
            titleToCarouselGap: AppSpacing.lg,
            items: [
              HomeCarouselItem(
                id: 'c1a',
                title: 'Daily Mix 1',
                subtitle: 'Weezer, Oasis, blur and more',
                imageColors: [0xFF3949AB, 0xFF1A237E],
              ),
              HomeCarouselItem(
                id: 'c1b',
                title: 'Rock Mix',
                subtitle: 'The Killers, Arctic Monkeys and more',
                imageColors: [0xFFB71C1C, 0xFF4E342E],
              ),
              HomeCarouselItem(
                id: 'c1c',
                title: 'Indie Mix',
                subtitle: 'The Strokes, Tame Impala and more',
                imageColors: [0xFF6A1B9A, 0xFF00838F],
              ),
            ],
          ),
        ),
        HomeCarouselBlock(
          HomeCarouselSection(
            id: 'c2',
            title: 'Your favorite artists',
            titleSize: HomeCarouselTitleSize.title18,
            thumbKind: HomeCarouselThumbKind.circle94,
            sectionTopPadding: AppSpacing.lg,
            titleToCarouselGap:
                AppSpacing.lg + AppSpacing.sm - AppSpacing.xs,
            items: [
              const HomeCarouselItem(
                id: 'c2a',
                title: 'Arctic Monkeys',
                imageColors: [0xFF424242, 0xFF212121],
                imageBorderRadius: 9999,
              ),
              const HomeCarouselItem(
                id: 'c2b',
                title: 'The Last Dinner Party',
                imageColors: [0xFF880E4F, 0xFF4A148C],
                imageBorderRadius: 9999,
              ),
              const HomeCarouselItem(
                id: 'c2c',
                title: 'Blur',
                imageColors: [0xFF1565C0, 0xFF0D47A1],
                imageBorderRadius: 9999,
              ),
              const HomeCarouselItem(
                id: 'c2d',
                title: 'Oasis',
                imageColors: [0xFF2E7D32, 0xFF1B5E20],
                imageBorderRadius: 9999,
              ),
            ],
          ),
        ),
        HomeCarouselBlock(
          HomeCarouselSection(
            id: 'c3',
            title: 'Made for you',
            titleSize: HomeCarouselTitleSize.title22,
            thumbKind: HomeCarouselThumbKind.square147,
            sectionTopPadding: AppSpacing.xl,
            titleToCarouselGap: AppSpacing.lg,
            items: [
              HomeCarouselItem(
                id: 'c3a',
                title: 'Discover Weekly',
                subtitle: 'Your weekly mixtape of fresh music',
                imageColors: [0xFF00695C, 0xFF004D40],
                imageBorderRadius: AppBorderRadius.comfortable,
              ),
              HomeCarouselItem(
                id: 'c3b',
                title: 'Release Radar',
                subtitle: 'Catch all the latest music from…',
                imageColors: [0xFFE65100, 0xFFBF360C],
                imageBorderRadius: AppBorderRadius.comfortable,
              ),
              HomeCarouselItem(
                id: 'c3c',
                title: 'Daily Mix 2',
                subtitle: 'Radiohead, Muse and more',
                imageColors: [0xFF5E35B1, 0xFF311B92],
                imageBorderRadius: AppBorderRadius.comfortable,
              ),
            ],
          ),
        ),
        HomeCarouselBlock(
          HomeCarouselSection(
            id: 'c4',
            title: 'Recently played',
            titleSize: HomeCarouselTitleSize.title22,
            thumbKind: HomeCarouselThumbKind.square147,
            sectionTopPadding: AppSpacing.xl,
            titleToCarouselGap: AppSpacing.lg,
            items: [
              HomeCarouselItem(
                id: 'c4a',
                title: 'This Is Arctic Monkeys',
                subtitle: 'Playlist',
                imageColors: [0xFF37474F, 0xFF78909C],
              ),
              HomeCarouselItem(
                id: 'c4b',
                title: 'OK Computer',
                subtitle: 'Album',
                imageColors: [0xFF455A64, 0xFF263238],
              ),
              HomeCarouselItem(
                id: 'c4c',
                title: 'The Dark Side of the Moon',
                subtitle: 'Album',
                imageColors: [0xFF5C6BC0, 0xFF1A237E],
              ),
            ],
          ),
        ),
        HomeCarouselBlock(
          HomeCarouselSection(
            id: 'c5',
            title: 'Your top mixes',
            titleSize: HomeCarouselTitleSize.title22,
            thumbKind: HomeCarouselThumbKind.square147,
            sectionTopPadding: AppSpacing.xl,
            titleToCarouselGap: AppSpacing.lg,
            items: [
              HomeCarouselItem(
                id: 'c5a',
                title: 'Daily Mix 3',
                subtitle: 'The Cure, Joy Division and more',
                imageColors: [0xFF6A1B9A, 0xFF4527A0],
              ),
              HomeCarouselItem(
                id: 'c5b',
                title: 'Daily Mix 4',
                subtitle: 'Daft Punk, Justice and more',
                imageColors: [0xFF00838F, 0xFF006064],
              ),
              HomeCarouselItem(
                id: 'c5c',
                title: 'Daily Mix 5',
                subtitle: 'Fleetwood Mac, Eagles and more',
                imageColors: [0xFFBF360C, 0xFF870000],
              ),
            ],
          ),
        ),
        HomeCarouselBlock(
          HomeCarouselSection(
            id: 'c6',
            title: 'More like Radiohead',
            titleSize: HomeCarouselTitleSize.title22,
            thumbKind: HomeCarouselThumbKind.square147,
            sectionTopPadding: AppSpacing.lg,
            titleToCarouselGap: AppSpacing.lg,
            items: [
              HomeCarouselItem(
                id: 'c6a',
                title: 'In Rainbows',
                subtitle: 'Album',
                imageColors: [0xFF37474F, 0xFF546E7A],
                imageBorderRadius: AppBorderRadius.comfortable,
              ),
              HomeCarouselItem(
                id: 'c6b',
                title: 'Kid A',
                subtitle: 'Album',
                imageColors: [0xFF263238, 0xFF455A64],
                imageBorderRadius: AppBorderRadius.comfortable,
              ),
              HomeCarouselItem(
                id: 'c6c',
                title: 'The Bends',
                subtitle: 'Album',
                imageColors: [0xFF3949AB, 0xFF283593],
                imageBorderRadius: AppBorderRadius.comfortable,
              ),
            ],
          ),
        ),
        HomeCarouselBlock(
          HomeCarouselSection(
            id: 'c7',
            title: 'Popular radio',
            titleSize: HomeCarouselTitleSize.title18,
            thumbKind: HomeCarouselThumbKind.circle94,
            sectionTopPadding: AppSpacing.lg,
            titleToCarouselGap:
                AppSpacing.lg + AppSpacing.sm - AppSpacing.xs,
            items: [
              const HomeCarouselItem(
                id: 'c7a',
                title: 'Rock Classics',
                imageColors: [0xFFB71C1C, 0xFF4E342E],
                imageBorderRadius: 9999,
              ),
              const HomeCarouselItem(
                id: 'c7b',
                title: 'Indie Pop',
                imageColors: [0xFF7B1FA2, 0xFF4A148C],
                imageBorderRadius: 9999,
              ),
              const HomeCarouselItem(
                id: 'c7c',
                title: 'Chill Hits',
                imageColors: [0xFF0277BD, 0xFF01579B],
                imageBorderRadius: 9999,
              ),
              const HomeCarouselItem(
                id: 'c7d',
                title: 'Hip-Hop Drive',
                imageColors: [0xFFF9A825, 0xFFF57F17],
                imageBorderRadius: 9999,
              ),
            ],
          ),
        ),
        HomeCarouselBlock(
          HomeCarouselSection(
            id: 'c8',
            title: 'Throwback',
            titleSize: HomeCarouselTitleSize.title22,
            thumbKind: HomeCarouselThumbKind.square147,
            sectionTopPadding: AppSpacing.xl,
            titleToCarouselGap: AppSpacing.lg,
            items: [
              HomeCarouselItem(
                id: 'c8a',
                title: 'I Love My ’90s Hip-Hop',
                subtitle: 'Playlist',
                imageColors: [0xFF5D4037, 0xFF3E2723],
              ),
              HomeCarouselItem(
                id: 'c8b',
                title: 'All Out 2000s',
                subtitle: 'Playlist',
                imageColors: [0xFF00695C, 0xFF004D40],
              ),
              HomeCarouselItem(
                id: 'c8c',
                title: 'Teen Angst',
                subtitle: 'Playlist',
                imageColors: [0xFFC62828, 0xFFAD1457],
              ),
            ],
          ),
        ),
        HomePodcastPromoBlock(
          HomePodcastPromo(
            id: 'p1',
            title: 'Song Exploder',
            showSubtitle: 'How music gets made',
            episodeDescription:
                'Wed · 42 min · Hrishikesh Hirway breaks down songs with the artists who made them — from demo to final mix.',
            coverColors: [0xFF37474F, 0xFF546E7A],
            backgroundColor: 0xFF324B5C,
          ),
        ),
        HomePodcastPromoBlock(
          HomePodcastPromo(
            id: 'p2',
            title: 'Dissect',
            showSubtitle: 'Long-form musical analysis',
            episodeDescription:
                'New season · Cole Cuchna digs deep into one album per season — themes, production, and story.',
            coverColors: [0xFF880E4F, 0xFF4A148C],
            backgroundColor: 0xFF92162A,
          ),
        ),
      ],
    );
  }
}
