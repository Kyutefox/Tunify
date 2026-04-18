/// Large podcast promo card dimensions (shared layout tokens).
abstract final class PodcastPromoLayout {
  PodcastPromoLayout._();

  static const double cardCornerRadius = 16;

  /// Tighter radius on compact playlist promos (closer to Spotify “shelf hero”).
  static const double compactPlaylistCardCornerRadius = 14;

  static const double coverSize = 118;

  /// Folded `track_shelf_promo` mosaic — square (1:1), same aspect as album/playlist art.
  static const double trackShelfCoverSize = 88;

  /// Primary play on compact playlist promo.
  static const double compactPlaylistPlayOuter = 48;
  static const double compactPlaylistPlayInner = 22;

  static const double playButtonOuter = 42;
  static const double playButtonInner = 32;

  /// Title line height ratio (26px line / 24px font).
  static const double titleLineHeightRatio = 26 / 24;

  /// Title letter spacing (tight, per Figma).
  static const double titleLetterSpacing = -0.55;

  /// Card vertical padding (Figma: 24px — md + sm + xs on 8px grid).
  static const double verticalPadding = 24;

  /// Compact playlist promo — horizontal insets.
  static const double compactPlaylistPaddingH = 16;

  /// Compact playlist promo — vertical insets.
  static const double compactPlaylistPaddingV = 14;

  /// Gap between title block and action row (compact playlist).
  static const double compactPlaylistTitleToActionsGap = 12;

  /// Title letter-tightening for compact playlist (Spotify-style).
  static const double compactPlaylistTitleLetterSpacing = -0.35;

  /// Gap between episode description and action row.
  static const double descriptionToActionsGap = 24;
}
