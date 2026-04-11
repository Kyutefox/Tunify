import 'package:tunify/v2/core/constants/app_spacing.dart';

/// [TrackSlimCard] metrics derived from the design grid.
abstract final class TrackSlimCardLayout {
  TrackSlimCardLayout._();

  static const double seekTrackHeight = 4;
  static const double nowPlayingDotSize = 8;

  /// Default row height (6.5 × 8px grid steps → 56).
  static double get defaultRowHeight => AppSpacing.xxxl + AppSpacing.md;

  static double get defaultThumbSize => defaultRowHeight;
}
