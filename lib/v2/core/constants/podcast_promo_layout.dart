/// Large podcast promo card dimensions (shared layout tokens).
abstract final class PodcastPromoLayout {
  PodcastPromoLayout._();

  static const double cardCornerRadius = 16;
  static const double coverSize = 118;
  static const double playButtonOuter = 42;
  static const double playButtonInner = 32;

  /// Title line height ratio (26px line / 24px font).
  static const double titleLineHeightRatio = 26 / 24;

  /// Title letter spacing (tight, per Figma).
  static const double titleLetterSpacing = -0.55;

  /// Card vertical padding (Figma: 24px — md + sm + xs on 8px grid).
  static const double verticalPadding = 24;

  /// Gap between episode description and action row.
  static const double descriptionToActionsGap = 24;
}
