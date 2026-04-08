import 'package:flutter/widgets.dart';
import 'package:tunify/ui/theme/design_tokens.dart';

abstract final class DesktopSpacing {
  static const double xs = AppSpacing.xs;
  static const double sm = AppSpacing.sm;
  static const double md = AppSpacing.md;
  static const double base = AppSpacing.base;
  static const double lg = AppSpacing.lg;
  static const double xl = AppSpacing.xl;
  static const double xxl = AppSpacing.xxl;
}

abstract final class DesktopFontSize {
  static const double xs = AppFontSize.xs;
  static const double sm = AppFontSize.sm;
  static const double md = AppFontSize.md;
  static const double base = AppFontSize.base;
  static const double lg = AppFontSize.lg;
  static const double xl = AppFontSize.xl;
  static const double xxl = AppFontSize.xxl;
  static const double h3 = AppFontSize.h3;
  static const double h2 = AppFontSize.h2;
  static const double h1 = AppFontSize.h1;
  static const double display3 = AppFontSize.display3;
  static const double display2 = AppFontSize.display2;
  static const double display1 = AppFontSize.display1;
}

abstract final class DesktopIconSize {
  static const double xs = UISize.iconSm;
  static const double sm = UISize.iconMd;
  static const double md = UISize.iconLg;
}

abstract final class DesktopButtonSize {
  static const double sm = UISize.buttonHeightSm;
  static const double md = UISize.buttonHeightMd;
  static const double lg = UISize.buttonHeightLg;
}

class AppTokens {
  const AppTokens();
  static const _inst = AppTokens();
  static AppTokens of(BuildContext context) => _inst;

  bool get isDesktop => false;
  AppSpacingTokens get spacing => const AppSpacingTokens();
  AppFontTokens get font => const AppFontTokens();
  AppIconTokens get icon => const AppIconTokens();
  AppTypographyTokens get typography => const AppTypographyTokens();
  Color get mutedColor => const Color(0xFF8E8E93);
}

class AppSpacingTokens {
  const AppSpacingTokens();
  double get xs => AppSpacing.xs;
  double get sm => AppSpacing.sm;
  double get md => AppSpacing.md;
  double get base => AppSpacing.base;
  double get lg => AppSpacing.lg;
  double get xl => AppSpacing.xl;
  double get xxl => AppSpacing.xxl;
}

class AppFontTokens {
  const AppFontTokens();
  double get xs => AppFontSize.xs;
  double get sm => AppFontSize.sm;
  double get md => AppFontSize.md;
  double get base => AppFontSize.base;
  double get lg => AppFontSize.lg;
  double get xl => AppFontSize.xl;
  double get xxl => AppFontSize.xxl;
  double get h1 => AppFontSize.h1;
  double get h2 => AppFontSize.h2;
  double get h3 => AppFontSize.h3;
  double get display1 => AppFontSize.display1;
  double get display2 => AppFontSize.display2;
  double get display3 => AppFontSize.display3;
}

class AppIconTokens {
  const AppIconTokens();
  double get xs => UISize.iconSm;
  double get sm => UISize.iconMd;
  double get md => UISize.iconLg;
  double get lg => UISize.iconLg;
}

class AppTypographyTokens {
  const AppTypographyTokens();
  FontWeight get titleWeight => FontWeight.w600;
  double get bodyLineHeight => AppLineHeight.normal;
  double get headingLetterSpacingSm => AppLetterSpacing.heading;
}
