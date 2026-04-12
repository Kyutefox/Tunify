/// Slim grid tile (card row).
class HomeSlimTile {
  const HomeSlimTile({
    required this.id,
    required this.title,
    required this.thumbColors,
    this.artworkUrl,
    this.showNowPlayingIndicator = false,
    this.showMoreMenu = false,
    this.showSeekBar = false,
    this.seekProgress = 0.35,
  });

  final String id;
  final String title;
  final List<int> thumbColors;
  /// When set (e.g. from `GET /v1/browse/home`), shown instead of [thumbColors] gradient.
  final String? artworkUrl;
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
    this.artworkUrl,
  });

  final String id;
  final String title;
  final String? subtitle;
  final List<int> imageColors;
  /// When set, shelf art loads from the network instead of [imageColors] only.
  final String? artworkUrl;

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
  });

  final String id;
  final String title;
  final HomeCarouselTitleSize titleSize;
  final HomeCarouselThumbKind thumbKind;
  final List<HomeCarouselItem> items;
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

/// Server-driven Quick picks (`HomePageResponse.quick_picks`): paged 2-column slim grid.
class HomeQuickPicksBlock extends HomeBlock {
  const HomeQuickPicksBlock({
    required this.title,
    this.subtitle,
    required this.tiles,
    required this.visibleColumns,
    required this.visibleRows,
  }) : super();

  final String title;
  final String? subtitle;
  final List<HomeSlimTile> tiles;
  final int visibleColumns;
  final int visibleRows;
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
