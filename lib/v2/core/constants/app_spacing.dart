/// Spacing constants following 8px grid system
class AppSpacing {
  AppSpacing._();

  static const double xs = 2;
  static const double sm = 4;
  static const double md = 8;
  static const double smMd = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 48;

  // Component-specific sizes
  static const double checkboxSize = 24;
  static const double checkboxIconSize = 16;
  static const double checkboxBorderRadius = 4;

  /// Welcome screen logo diameter (xxxl + xl = 72).
  static const double welcomeLogoSize = xxxl + xl;

  /// Session avatar button diameter in the top navigation row.
  static const double navAvatarSize = 36;

  /// Session avatar fallback icon size.
  static const double navAvatarIconSize = 20;

  /// Search header height.
  static const double searchHeaderHeight = 60;

  /// Search header icon size.
  static const double searchHeaderIconSize = 18;

  /// Search clear button size.
  static const double searchClearButtonSize = 24;

  /// Search explore card title font size.
  static const double searchExploreCardTitleFontSize = 14;

  /// Search category card title font size.
  static const double searchCategoryCardTitleFontSize = 18;

  /// Search header collapsed title font size.
  static const double searchHeaderCollapsedTitleFontSize = 22;
}
