import 'package:tunify/v2/core/constants/app_spacing.dart';

/// Slim grid tile (card row).
class HomeSlimTile {
  const HomeSlimTile({
    required this.id,
    required this.title,
    required this.thumbColors,
    this.showNowPlayingIndicator = false,
    this.showMoreMenu = false,
    this.showSeekBar = false,
    this.seekProgress = 0.35,
  });

  final String id;
  final String title;
  final List<int> thumbColors;
  final bool showNowPlayingIndicator;
  final bool showMoreMenu;
  final bool showSeekBar;
  final double seekProgress;
}

/// “Card recommended” hero row (Figma).
class HomeHeroRecommended {
  const HomeHeroRecommended({
    required this.sectionLabel,
    required this.sectionTitle,
    required this.cardTitle,
    required this.cardSubtitle,
    required this.avatarColors,
    required this.squareArtColors,
  });

  final String sectionLabel;
  final String sectionTitle;
  final String cardTitle;
  final String cardSubtitle;
  final List<int> avatarColors;
  final List<int> squareArtColors;
}

class HomeCarouselItem {
  const HomeCarouselItem({
    required this.id,
    required this.title,
    this.subtitle,
    required this.imageColors,
    this.imageBorderRadius = 0,
  });

  final String id;
  final String title;
  final String? subtitle;
  final List<int> imageColors;

  /// 0 = square, 8 = rounded square, 9999 = circle (94×94).
  final double imageBorderRadius;
}

enum HomeCarouselTitleSize {
  /// Title 4 — 22px / 26px, letter-spacing -0.55
  title22,

  /// Body 1 bold — 18px / 22px, letter-spacing -0.2
  title18,
}

enum HomeCarouselThumbKind {
  /// Square / rounded-square art; size from [HomeLayout.carouselThumbSize].
  square147,

  /// Same art size as [square147], circular clip; label under art.
  circle94,
}

class HomeCarouselSection {
  const HomeCarouselSection({
    required this.id,
    required this.title,
    required this.titleSize,
    required this.thumbKind,
    required this.items,
    this.sectionTopPadding = AppSpacing.xl,
    this.titleToCarouselGap = AppSpacing.lg,
  });

  final String id;
  final String title;
  final HomeCarouselTitleSize titleSize;
  final HomeCarouselThumbKind thumbKind;
  final List<HomeCarouselItem> items;

  /// Figma: 24 or 16 top padding on “Carousel orizzontale”.
  final double sectionTopPadding;

  /// Figma: 16 or 18 gap between title row and carousel.
  final double titleToCarouselGap;
}

sealed class HomeBlock {
  const HomeBlock();
}

class HomeSlimGridBlock extends HomeBlock {
  const HomeSlimGridBlock({required this.tiles}) : super();

  final List<HomeSlimTile> tiles;
}

class HomeHeroRecommendedBlock extends HomeBlock {
  const HomeHeroRecommendedBlock(this.hero) : super();

  final HomeHeroRecommended hero;
}

class HomeCarouselBlock extends HomeBlock {
  const HomeCarouselBlock(this.section) : super();

  final HomeCarouselSection section;
}

/// Large podcast / show promo card (Figma “Card podcat”).
class HomePodcastPromo {
  const HomePodcastPromo({
    required this.id,
    required this.title,
    required this.showSubtitle,
    required this.episodeDescription,
    required this.coverColors,
    required this.backgroundColor,
  });

  final String id;
  final String title;
  final String showSubtitle;
  final String episodeDescription;
  final List<int> coverColors;
  /// ARGB (e.g. `0xFF324B5C`) — feature-level accent, not in DESIGN.md core palette.
  final int backgroundColor;
}

class HomePodcastPromoBlock extends HomeBlock {
  const HomePodcastPromoBlock(this.promo) : super();

  final HomePodcastPromo promo;
}
