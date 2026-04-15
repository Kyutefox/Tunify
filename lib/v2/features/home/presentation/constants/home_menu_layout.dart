/// Figma “Menu” frame — outer 390×844 (#121212), inner column 350 (#1F1F1F), overlay rgba(0,0,0,0.6).
abstract final class HomeMenuLayout {
  HomeMenuLayout._();

  static const double panelWidthPt = 390;
  static const double panelMinHeightPt = 844;

  static const double menuColumnWidthPt = 350;
  static const double menuVerticalPaddingPt = 60;
  static const double sectionGapPt = 16;
  static const double itemListGapPt = 26;

  static const double titleRowLeadingPadPt = 16;
  static const double titleRowTrailingPadPt = 40;
  static const double titleAvatarGapPt = 12;

  static const double avatarSizePt = 50;
  static const double avatarIconSizePt = 28;
  static const double menuItemRowHeightPt = 32;
  static const double menuItemIconGapPt = 8;
  static const double menuIconBoxPt = 32;
  static const double menuItemIconSizePt = 24;

  /// Outer shell width (phone frame).
  static double panelWidth(double screenWidth) =>
      screenWidth < panelWidthPt ? screenWidth : panelWidthPt;

  /// Inner “Menu” surface (Figma width 350); fills panel when narrower than 350.
  static double menuSurfaceWidth(double panelWidth) =>
      panelWidth < menuColumnWidthPt ? panelWidth : menuColumnWidthPt;
}
