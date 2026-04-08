import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tunify/ui/theme/design_tokens.dart';

class AppTokens {
  const AppTokens();
  static const _inst = AppTokens();
  static AppTokens of(BuildContext context) => _inst;

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

class ContentLayout {
  const ContentLayout({
    required this.cols,
    required this.maxWidth,
    required this.hPad,
  });

  final int cols;
  final double maxWidth;
  final double hPad;

  static ContentLayout of(
    BuildContext context,
    WidgetRef ref, {
    double itemWidth = 160,
    int minCols = 2,
    int maxCols = 5,
  }) {
    final hPad = 16.0;
    final screenW = MediaQuery.sizeOf(context).width;
    final maxWidth = screenW - hPad * 2;
    final cols = (maxWidth / itemWidth).floor().clamp(minCols, maxCols);
    return ContentLayout(cols: cols, maxWidth: maxWidth, hPad: hPad);
  }
}
