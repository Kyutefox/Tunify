import 'package:flutter/material.dart';
import 'app_colors.dart';

// ─── Font size scale ──────────────────────────────────────────────────────────
// 10 · 11 · 12 · 13 · 14 · 15 · 16 · 18 · 20 · 22 · 24 · 28 · 36 · 48 · 56
// One-off sizes (17, 26, 30, 32) are NOT in the scale — use the nearest step.

abstract final class AppFontSize {
  static const double micro  = 10.0; // timestamps, badges
  static const double xs     = 11.0; // nav labels, captions
  static const double sm     = 12.0; // secondary captions, error text
  static const double md     = 13.0; // list subtitles, labels
  static const double base   = 14.0; // body text
  static const double lg     = 15.0; // list tile titles, settings rows
  static const double xl     = 16.0; // button labels, prominent body
  static const double xxl    = 18.0; // screen titles, app bar
  static const double h3     = 20.0; // section headings
  static const double h2     = 22.0; // sheet headings
  static const double h1     = 24.0; // page headings
  static const double display3 = 28.0; // collection titles
  static const double display2 = 36.0; // large display
  static const double display1 = 48.0; // hero display
  static const double hero     = 56.0; // welcome screen
}

// ─── Letter spacing ───────────────────────────────────────────────────────────
abstract final class AppLetterSpacing {
  /// Tight — large display text (≥ 24px)
  static const double display = -0.5;
  /// Snug — headings (18–22px)
  static const double heading = -0.3;
  /// Normal — body / titles (13–16px)
  static const double normal  = 0.0;
  /// Wide — uppercase labels / caps
  static const double label   = 1.2;
}

// ─── Line height ──────────────────────────────────────────────────────────────
abstract final class AppLineHeight {
  /// Tight — display / hero text
  static const double tight   = 1.0;
  /// Default — most UI text
  static const double normal  = 1.3;
  /// Relaxed — body / readable paragraphs
  static const double relaxed = 1.5;
}

// ─── Semantic text styles ─────────────────────────────────────────────────────
// Use these instead of inline TextStyle() to guarantee Inter font + consistent
// sizing. Color can be overridden per-use via .copyWith(color: ...).

abstract final class AppTextStyle {
  // ── Display ──
  static const TextStyle hero = TextStyle(
    fontSize: AppFontSize.hero,
    fontWeight: FontWeight.w800,
    letterSpacing: -2.0,
    height: AppLineHeight.tight,
    color: AppColors.textPrimary,
  );
  static const TextStyle display1 = TextStyle(
    fontSize: AppFontSize.display1,
    fontWeight: FontWeight.w800,
    letterSpacing: -1.5,
    height: AppLineHeight.tight,
    color: AppColors.textPrimary,
  );
  static const TextStyle display2 = TextStyle(
    fontSize: AppFontSize.display2,
    fontWeight: FontWeight.w700,
    letterSpacing: -1.0,
    height: AppLineHeight.tight,
    color: AppColors.textPrimary,
  );
  static const TextStyle display3 = TextStyle(
    fontSize: AppFontSize.display3,
    fontWeight: FontWeight.w800,
    letterSpacing: AppLetterSpacing.display,
    height: AppLineHeight.tight,
    color: AppColors.textPrimary,
  );

  // ── Headings ──
  static const TextStyle h1 = TextStyle(
    fontSize: AppFontSize.h1,
    fontWeight: FontWeight.w700,
    letterSpacing: AppLetterSpacing.heading,
    color: AppColors.textPrimary,
  );
  static const TextStyle h2 = TextStyle(
    fontSize: AppFontSize.h2,
    fontWeight: FontWeight.w700,
    letterSpacing: AppLetterSpacing.heading,
    color: AppColors.textPrimary,
  );
  static const TextStyle h3 = TextStyle(
    fontSize: AppFontSize.h3,
    fontWeight: FontWeight.w600,
    letterSpacing: AppLetterSpacing.heading,
    color: AppColors.textPrimary,
  );

  // ── Screen / sheet titles ──
  static const TextStyle screenTitle = TextStyle(
    fontSize: AppFontSize.xxl,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.2,
    color: AppColors.textPrimary,
  );
  static const TextStyle sheetTitle = TextStyle(
    fontSize: AppFontSize.h2,
    fontWeight: FontWeight.w700,
    letterSpacing: AppLetterSpacing.heading,
    color: AppColors.textPrimary,
  );

  // ── Titles (list tiles, cards) ──
  static const TextStyle titleLg = TextStyle(
    fontSize: AppFontSize.lg,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );
  static const TextStyle titleBase = TextStyle(
    fontSize: AppFontSize.xl,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  // ── Body ──
  static const TextStyle bodyLg = TextStyle(
    fontSize: AppFontSize.lg,
    fontWeight: FontWeight.w400,
    height: AppLineHeight.relaxed,
    color: AppColors.textSecondary,
  );
  static const TextStyle bodyBase = TextStyle(
    fontSize: AppFontSize.base,
    fontWeight: FontWeight.w400,
    height: AppLineHeight.normal,
    color: AppColors.textSecondary,
  );
  static const TextStyle bodySm = TextStyle(
    fontSize: AppFontSize.md,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
  );

  // ── Labels ──
  static const TextStyle labelLg = TextStyle(
    fontSize: AppFontSize.md,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );
  static const TextStyle labelBase = TextStyle(
    fontSize: AppFontSize.sm,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
  );
  static const TextStyle labelSm = TextStyle(
    fontSize: AppFontSize.xs,
    fontWeight: FontWeight.w500,
    color: AppColors.textMuted,
  );
  static const TextStyle labelCaps = TextStyle(
    fontSize: AppFontSize.xs,
    fontWeight: FontWeight.w700,
    letterSpacing: AppLetterSpacing.label,
    color: AppColors.primary,
  );

  // ── Captions / micro ──
  static const TextStyle caption = TextStyle(
    fontSize: AppFontSize.sm,
    fontWeight: FontWeight.w400,
    color: AppColors.textMuted,
  );
  static const TextStyle micro = TextStyle(
    fontSize: AppFontSize.micro,
    fontWeight: FontWeight.w500,
    color: AppColors.textMuted,
  );
}

abstract final class AppSpacing {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double base = 16.0;
  static const double lg = 20.0;
  static const double xl = 24.0;
  static const double xxl = 32.0;
  static const double xxxl = 40.0;
  static const double huge = 56.0;
  static const double max = 72.0;
}

abstract final class AppRadius {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double input = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 20.0;
  static const double xxl = 24.0;
  static const double full = 999.0;
}

abstract final class AppDuration {
  static const Duration instant = Duration(milliseconds: 100);
  static const Duration fast = Duration(milliseconds: 200);
  static const Duration normal = Duration(milliseconds: 300);
  static const Duration medium = Duration(milliseconds: 400);
  static const Duration slow = Duration(milliseconds: 600);
  static const Duration page = Duration(milliseconds: 500);
}

abstract final class AppCurves {
  static const Curve standard = Curves.easeInOut;
  static const Curve decelerate = Curves.easeOut;

  static const Curve spring = Cubic(0.34, 1.56, 0.64, 1.0);

  static const Curve emphasized = Cubic(0.2, 0.0, 0.0, 1.0);
}
