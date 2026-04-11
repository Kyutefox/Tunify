/// Figma “Menu - Library” chip metrics.
abstract final class FilterPillLayout {
  FilterPillLayout._();

  static const double height = 30;
  static const double horizontalPadding = 16;
  static const double verticalPadding = 7;
  static const double gapAfterClose = 8;
  static const double closeOuterSize = 30;
  static const double closeIconBox = 10;
  static const double closeStrokeWidth = 1.5;
  static const double cornerRadius = 16;

  /// Figma left chip `margin: 0 -16px` — overlap into the right segment.
  static const double segmentOverlap = 16;

  /// Secondary segment: extra left inset so the label clears the primary overlap.
  /// (Figma uses 24px left when selected vs 16px when not; we keep this inset in
  /// both states so text stays aligned.)
  static const double secondaryLeadingInset = 8;
}
