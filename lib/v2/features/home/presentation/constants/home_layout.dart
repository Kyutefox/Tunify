import 'package:flutter/material.dart';
import 'package:tunify/v2/core/constants/app_spacing.dart';

/// Home screen geometry and insets — built from [AppSpacing] only.
///
/// Non–grid multiples (e.g. carousel thumb width) stay in this feature file, not `core`.
abstract final class HomeLayout {
  HomeLayout._();

  /// Space **above** a shelf section title (carousel, hero, podcast promo, …).
  static double get shelfLeadingBeforeTitle => AppSpacing.xl;

  /// Space **below** shelf content before the next block (pairs with the next block’s
  /// [shelfLeadingBeforeTitle] so every boundary is `md + xl` from tokens only).
  static double get shelfTrailingAfterContent => AppSpacing.md;

  /// Space between the shelf title line and the horizontal card row (carousel / same stack).
  static double get shelfTitleToHorizontalRowGap => AppSpacing.lg;

  /// Pinned header padding (horizontal [AppSpacing.lg]).
  static EdgeInsets headerPadding(EdgeInsets safeArea) {
    final top = safeArea.top + AppSpacing.sm;
    return EdgeInsets.fromLTRB(
      AppSpacing.lg,
      top,
      AppSpacing.lg,
      AppSpacing.md,
    );
  }

  /// Top inset for the scroll view so content clears the pinned header.
  static double scrollContentTopOffset(EdgeInsets safeArea) {
    final p = headerPadding(safeArea);
    return p.top + profileAvatarDiameter + p.bottom;
  }

  /// Slim grid row (6.5 × 8px grid steps → 56).
  static double get slimRowHeight => AppSpacing.xxxl + AppSpacing.md;

  static double get slimThumbSize => slimRowHeight;

  /// Height of one Quick picks page: matches [HomeSlimGrid] top inset + tile rows + row gaps.
  static double quickPicksPageHeight(int visibleRows) {
    final rows = visibleRows < 1 ? 1 : visibleRows;
    final gap = AppSpacing.md;
    return AppSpacing.md + rows * slimRowHeight + (rows - 1) * gap;
  }

  static double get heroAvatarDiameter => AppSpacing.xxxl;

  /// Hero artwork width/height — tuned for mock layout (not on 8px grid).
  static const double heroPromoArtSize = 142;

  /// Carousel art — reference square 147 at [carouselDesignShelfInnerWidth] wide viewport.
  /// Artist (circle) and album/playlist (square) use the **same** scaled width/height; only clip differs.
  static const double carouselThumbLarge = 147;

  /// Reference inner shelf width (390pt frame minus 16pt leading gutter).
  static const double carouselDesignShelfInnerWidth = 374;

  /// Clamp carousel art so shelves stay usable on small / large phones (RULES: no magic in UI).
  static const double carouselThumbClampMin = 112;
  static const double carouselThumbClampMax = 168;

  /// Scales with shelf viewport — used for **both** square and circular carousel art.
  static double carouselThumbSize(double shelfViewportWidth) {
    final w = shelfViewportWidth * carouselThumbLarge / carouselDesignShelfInnerWidth;
    return w.clamp(carouselThumbClampMin, carouselThumbClampMax);
  }

  static double get profileAvatarDiameter => AppSpacing.xxl;

  static double get profileAvatarIconSize =>
      AppSpacing.lg + AppSpacing.sm - AppSpacing.xs;
}
