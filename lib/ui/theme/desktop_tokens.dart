import 'package:flutter/widgets.dart';
import 'package:tunify/ui/shell/shell_context.dart';
import 'package:tunify/ui/theme/app_colors.dart';
import 'design_tokens.dart';

// ── Desktop-specific overrides ────────────────────────────────────────────────

abstract final class DesktopSpacing {
  static const double xs   = 6.0;
  static const double sm   = 10.0;
  static const double md   = 16.0;
  static const double base = 22.0;
  static const double lg   = 28.0;
  static const double xl   = 36.0;
  static const double xxl  = 48.0;
}

abstract final class DesktopFontSize {
  static const double micro = 11.0;
  static const double xs    = 12.0;
  static const double sm    = 13.0;
  static const double md    = 14.0;
  static const double base  = 15.0;
  static const double lg    = 16.0;
  static const double xl    = 17.0;
  static const double xxl   = 20.0;
  static const double h3    = 22.0;
  static const double h2    = 24.0;
  static const double h1    = 28.0;
}

abstract final class DesktopIconSize {
  static const double xs = 16.0;
  static const double sm = 18.0;
  static const double md = 22.0;
  static const double lg = 26.0;
  static const double xl = 32.0;
}

abstract final class DesktopButtonSize {
  static const double sm = 34.0;
  static const double md = 38.0;
  static const double lg = 44.0;
}

abstract final class DesktopLayout {
  static const double topBarHeight       = 64.0;
  static const double playerBarHeight    = 76.0;
  static const double sidebarWidth       = 340.0;
  static const double rightSidebarWidth  = 320.0;
  static const double playerArtSize      = 52.0;
  static const double navBtnSize         = 44.0;
  static const double homeBtnSize        = 44.0;
  static const double searchMaxWidth     = 420.0;
  static const double volumeSliderWidth  = 96.0;
  static const double rightTabBarHeight  = 56.0;
}

// ── Unified token accessor ────────────────────────────────────────────────────
//
// Usage in any widget (shared or desktop-only):
//
//   final t = AppTokens.of(context);
//   fontSize: t.titleSize
//   padding: EdgeInsets.all(t.spacing.base)
//   size: t.iconMd
//
// Mobile widgets that never call this are unaffected.

class _SpacingTokens {
  const _SpacingTokens({
    required this.xs,
    required this.sm,
    required this.md,
    required this.base,
    required this.lg,
    required this.xl,
    required this.xxl,
  });
  final double xs, sm, md, base, lg, xl, xxl;
}

class _FontTokens {
  const _FontTokens({
    required this.micro,
    required this.xs,
    required this.sm,
    required this.md,
    required this.base,
    required this.lg,
    required this.xl,
    required this.xxl,
    required this.h3,
    required this.h2,
    required this.h1,
  });
  final double micro, xs, sm, md, base, lg, xl, xxl, h3, h2, h1;
}

class _IconTokens {
  const _IconTokens({
    required this.xs,
    required this.sm,
    required this.md,
    required this.lg,
    required this.xl,
  });
  final double xs, sm, md, lg, xl;
}

class _ButtonTokens {
  const _ButtonTokens({
    required this.sm,
    required this.md,
    required this.lg,
  });
  final double sm, md, lg;
}

class _TypographyTokens {
  const _TypographyTokens({
    required this.titleWeight,
    required this.bodyWeight,
    required this.headingLetterSpacing,
    required this.bodyLineHeight,
    required this.secondaryColor,
    required this.mutedColor,
  });
  final FontWeight titleWeight;
  final FontWeight bodyWeight;
  final double headingLetterSpacing;
  final double bodyLineHeight;
  final Color secondaryColor;
  final Color mutedColor;
}

class AppTokens {
  const AppTokens._({
    required this.isDesktop,
    required this.spacing,
    required this.font,
    required this.icon,
    required this.button,
    required this.typography,
  });

  final bool isDesktop;
  final _SpacingTokens spacing;
  final _FontTokens font;
  final _IconTokens icon;
  final _ButtonTokens button;
  final _TypographyTokens typography;

  /// Shorthand for secondary text color (desktop: #888, mobile: #B3B3B3)
  Color get secondaryColor => typography.secondaryColor;
  /// Shorthand for muted text color (desktop: #666, mobile: #9E9E9E)
  Color get mutedColor => typography.mutedColor;

  static const AppTokens _mobile = AppTokens._(
    isDesktop: false,
    spacing: _SpacingTokens(
      xs:   AppSpacing.xs,
      sm:   AppSpacing.sm,
      md:   AppSpacing.md,
      base: AppSpacing.base,
      lg:   AppSpacing.lg,
      xl:   AppSpacing.xl,
      xxl:  AppSpacing.xxl,
    ),
    font: _FontTokens(
      micro: AppFontSize.micro,
      xs:    AppFontSize.xs,
      sm:    AppFontSize.sm,
      md:    AppFontSize.md,
      base:  AppFontSize.base,
      lg:    AppFontSize.lg,
      xl:    AppFontSize.xl,
      xxl:   AppFontSize.xxl,
      h3:    AppFontSize.h3,
      h2:    AppFontSize.h2,
      h1:    AppFontSize.h1,
    ),
    icon: _IconTokens(xs: 14, sm: 16, md: 20, lg: 24, xl: 28),
    button: _ButtonTokens(sm: 32, md: 40, lg: 48),
    typography: _TypographyTokens(
      titleWeight: FontWeight.w600,
      bodyWeight: FontWeight.w400,
      headingLetterSpacing: -0.3,
      bodyLineHeight: 1.3,
      secondaryColor: AppColors.textSecondary,
      mutedColor: AppColors.textMuted,
    ),
  );

  static const AppTokens _desktop = AppTokens._(
    isDesktop: true,
    spacing: _SpacingTokens(
      xs:   DesktopSpacing.xs,
      sm:   DesktopSpacing.sm,
      md:   DesktopSpacing.md,
      base: DesktopSpacing.base,
      lg:   DesktopSpacing.lg,
      xl:   DesktopSpacing.xl,
      xxl:  DesktopSpacing.xxl,
    ),
    font: _FontTokens(
      micro: DesktopFontSize.micro,
      xs:    DesktopFontSize.xs,
      sm:    DesktopFontSize.sm,
      md:    DesktopFontSize.md,
      base:  DesktopFontSize.base,
      lg:    DesktopFontSize.lg,
      xl:    DesktopFontSize.xl,
      xxl:   DesktopFontSize.xxl,
      h3:    DesktopFontSize.h3,
      h2:    DesktopFontSize.h2,
      h1:    DesktopFontSize.h1,
    ),
    icon: _IconTokens(
      xs: DesktopIconSize.xs,
      sm: DesktopIconSize.sm,
      md: DesktopIconSize.md,
      lg: DesktopIconSize.lg,
      xl: DesktopIconSize.xl,
    ),
    button: _ButtonTokens(
      sm: DesktopButtonSize.sm,
      md: DesktopButtonSize.md,
      lg: DesktopButtonSize.lg,
    ),
    typography: _TypographyTokens(
      titleWeight: FontWeight.w700,
      bodyWeight: FontWeight.w500,
      headingLetterSpacing: -0.8,
      bodyLineHeight: 1.45,
      secondaryColor: AppColors.desktopTextSecondary,
      mutedColor: AppColors.desktopTextMuted,
    ),
  );

  /// Returns the correct token set based on [ShellContext.isDesktopOf].
  static AppTokens of(BuildContext context) {
    return ShellContext.isDesktopOf(context) ? _desktop : _mobile;
  }
}
