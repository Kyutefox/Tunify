/// Layout constants for the library screen (Figma Spotify iOS 2024).
abstract final class LibraryLayout {
  LibraryLayout._();

  /// List-view thumbnail size (artwork square).
  static const double listThumbSize = 68;

  /// List-view row height (thumb + vertical padding).
  static const double listRowHeight = 92;

  /// Gap between thumbnail and text content.
  static const double listThumbTextGap = 14;

  /// Vertical gap between title and subtitle in list rows.
  static const double listTitleSubtitleGap = 5;

  /// Grid cross-axis count (Figma shows 3 columns).
  static const int gridCrossAxisCount = 3;

  /// Grid horizontal spacing between items.
  static const double gridCrossAxisSpacing = 10;

  /// Grid vertical spacing between items.
  static const double gridMainAxisSpacing = 16;

  /// Child aspect ratio for grid tiles (width / height).
  /// Artwork is square; labels add ~40px below.
  static const double gridChildAspectRatio = 0.68;

  /// Pinned push-pin icon size.
  static const double pinIconSize = 14;

  /// Sort/view control bar height.
  static const double controlBarHeight = 32;

  /// Horizontal padding for library content.
  static const double horizontalPadding = 16;

  // ── Options bottom sheet ──

  /// Drag handle width.
  static const double sheetHandleWidth = 36;

  /// Drag handle height.
  static const double sheetHandleHeight = 4;

  /// Drag handle corner radius.
  static const double sheetHandleRadius = 2;

  /// Header artwork size inside the options sheet.
  static const double sheetArtworkSize = 48;

  /// Icon size for each option row.
  static const double sheetOptionIconSize = 24;

  /// Shadow gradient height between fixed header and scroll area.
  static const double headerShadowHeight = 6;

  /// Filter pills row (collapsed + expanded) vertical extent.
  static const double filterPillsRowHeight = 30;

  /// Main library screen title (Figma “Your Library”).
  static const double screenTitleFontSize = 22;
  static const double screenTitleLineHeight = 26 / 22;

  /// Grid ↔ list body transition.
  static const Duration gridListSwitchDuration = Duration(milliseconds: 250);

  /// Empty-state leading icon diameter.
  static const double emptyStateIconSize = 48;
}
