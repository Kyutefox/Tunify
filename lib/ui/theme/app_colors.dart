import 'package:flutter/material.dart';

import 'package:tunify/core/constants/primary_palette.dart';

/// Spotify-style color system: dark backgrounds, green accents for active/playback.
abstract final class AppColors {
  // ——— Base backgrounds ———
  /// background_main
  static const Color background = Color(0xFF121212);
  /// background_sidebar
  static const Color backgroundSecondary = Color(0xFF000000);
  /// background_base
  static const Color backgroundBase = Color(0xFF191414);

  // ——— Surface layers (elevated, card, hover) ———
  /// surface_elevated
  static const Color surface = Color(0xFF181818);
  static const Color surfaceElevated = Color(0xFF181818);
  /// surface_card — cards, list tiles
  static const Color card = Color(0xFF282828);
  /// surface_hover — hover brighten
  static const Color surfaceLight = Color(0xFF2A2A2A);
  static const Color surfaceHighlight = Color(0xFF333333);

  // ——— Primary / accent (green for active, buttons, playback) ———
  static const Color primary = PrimaryPalette.primary;
  static const Color primaryLight = PrimaryPalette.primaryLight;
  static const Color primaryDark = PrimaryPalette.primaryDark;
  static const Color primaryContainer = PrimaryPalette.primaryContainer;
  /// Brighter green for active icon states on dark surfaces — more punch than [primary].
  static const Color primaryIcon = PrimaryPalette.primaryLight;
  static const Color secondary = PrimaryPalette.primaryLight;
  static const Color secondaryLight = PrimaryPalette.primaryLight;
  static const Color accent = PrimaryPalette.primary;
  static const Color accentGreen = PrimaryPalette.primary;
  static const Color accentOrange = Color(0xFFFF6B35);
  static const Color accentRed = Color(0xFFE91429);
  static const Color accentCyan = Color(0xFF00D2FF);

  // ——— Text ———
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFB3B3B3);
  static const Color textMuted = Color(0xFF9E9E9E);
  static const Color textDisabled = Color(0xFF727272);

  // ——— Desktop-specific text colors (higher contrast for larger screens) ———
  static const Color desktopTextSecondary = Color(0xFF888888);
  static const Color desktopTextMuted = Color(0xFF666666);

  // ——— Desktop surface layers ———
  static const Color desktopSurface = Color(0xFF1E1E1E);
  static const Color desktopCanvas = Color(0xFF0A0A0A);

  // ——— Hover overlay ———
  static const Color hoverOverlay = Color(0x0FFFFFFF);

  static const Color glassWhite = Color(0x18FFFFFF);
  static const Color glassBlack = Color(0x60000000);
  static const Color glassBorder = Color(0x25FFFFFF);

  // ——— Player overlay text / icon tints (white with opacity) ———
  /// Player icon inactive state — white @ 80%
  static const Color playerIconInactive = Color(0xCCFFFFFF);
  /// Player extra button icons / label — white @ 75%
  static const Color playerIconExtra = Color(0xBFFFFFFF);
  /// Player status label ("NOW PLAYING") — white @ 65%
  static const Color playerLabelSubtle = Color(0xA6FFFFFF);
  /// Player time label — white @ 50%
  static const Color playerTimeMuted = Color(0x80FFFFFF);

  // ——— Gradients ———
  /// gradient_app_background
  static const LinearGradient backgroundGradient = LinearGradient(
    colors: [Color(0xFF121212), Color(0xFF000000)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  /// gradient_green_accent
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF1DB954), Color(0xFF1ED760)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  /// gradient_downloads — teal-to-blue for the Downloads fixed playlist
  static const LinearGradient downloadGradient = LinearGradient(
    colors: [Color(0xFF0EA5E9), Color(0xFF6366F1)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// gradient_playlist_header (content headers)
  static const LinearGradient playlistHeaderGradient = LinearGradient(
    colors: [Color(0xFF404040), Color(0xFF121212)],
    stops: [0.0, 0.6],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  /// gradient_dark_overlay
  static const LinearGradient darkOverlayGradient = LinearGradient(
    colors: [Color(0x00000000), Color(0xB3000000)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFF282828), Color(0xFF181818)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient headerGradient = LinearGradient(
    colors: [Color(0x60000000), Color(0x00000000)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const List<LinearGradient> moodGradients = [
    LinearGradient(colors: [PrimaryPalette.primary, PrimaryPalette.primaryLight]),
    primaryGradient,
    LinearGradient(colors: [Color(0xFFFF6B35), Color(0xFFFF2D78)]),
    LinearGradient(colors: [Color(0xFF00D2FF), Color(0xFF3A7BD5)]),
    LinearGradient(colors: [Color(0xFFFFD60A), PrimaryPalette.primary]),
    LinearGradient(colors: [Color(0xFF3A7BD5), PrimaryPalette.primary]),
    LinearGradient(colors: [PrimaryPalette.primary, PrimaryPalette.primaryDark]),
    LinearGradient(colors: [PrimaryPalette.primary, PrimaryPalette.primaryLight]),
  ];

  /// Love-theme gradients (5 options) for liked hearts and favourite UI.
  static const List<LinearGradient> loveThemeGradients = [
    LinearGradient(
      colors: [Color(0xFFE91429), Color(0xFFF472B6)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    LinearGradient(
      colors: [Color(0xFFEC4899), Color(0xFFBE185D)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    LinearGradient(
      colors: [Color(0xFFF472B6), Color(0xFFE11D48)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    LinearGradient(
      colors: [Color(0xFFDB2777), Color(0xFF831843)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    LinearGradient(
      colors: [Color(0xFFF9A8D4), Color(0xFFEC4899)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  ];

  /// Stable colour from [loveThemeGradients] for a given id (for solid liked heart).
  static Color loveThemeColorFor(String? id) {
    final index = (id?.hashCode ?? 0).abs() % loveThemeGradients.length;
    return loveThemeGradients[index].colors.first;
  }

  /// Stable gradient from [loveThemeGradients] for a given id (for gradient-filled heart).
  static LinearGradient loveThemeGradientFor(String? id) {
    final index = (id?.hashCode ?? 0).abs() % loveThemeGradients.length;
    return loveThemeGradients[index];
  }

  /// Bottom-fade overlay used on artwork cards (song, playlist).
  static const LinearGradient cardOverlayGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Colors.transparent, Color(0x99000000)],
    stops: [0.5, 1.0],
  );

  static LinearGradient dynamicGradient(Color dominantColor) {
    final hsl = HSLColor.fromColor(dominantColor);
    final darker =
        hsl.withLightness((hsl.lightness - 0.3).clamp(0.0, 1.0)).toColor();
    return LinearGradient(
      colors: [
        darker.withValues(alpha: 0.9),
        dominantColor.withValues(alpha: 0.5),
        Colors.transparent,
      ],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    );
  }
}

/// Central palette/gradient constants used across collection headers,
/// the main player background, and anywhere a dominant/palette color is applied.
abstract final class PaletteTheme {
  // ── Palette extraction (HSL adjustments) ──────────────────────────────────
  /// Lightness boost — small, just enough to avoid near-black colors.
  static const double extractLightnessBoost = 0.05;
  /// Minimum lightness — prevents very dark colors from being invisible.
  static const double extractLightnessMin = 0.35;
  /// Maximum lightness — prevents colors from washing out completely.
  static const double extractLightnessMax = 0.75;
  /// Saturation reduction — keep colors vivid, just slightly soften.
  static const double extractSaturationReduce = 0.05;

  /// Liked Songs gets a slightly stronger lightness boost for its fixed color.
  static const double likedLightnessBoost = 0.10;
  static const double likedLightnessMax = 0.78;

  // ── Collection header gradient (scrolls with content) ────────────────────
  /// Top alpha — strong enough to be clearly visible on dark background.
  static const double headerGradientTopAlpha = 0.85;
  /// Mid alpha — still visible as it fades out.
  static const double headerGradientMidAlpha = 0.40;
  /// Gradient stop positions [top, mid, transparent].
  static const List<double> headerGradientStops = [0.0, 0.55, 1.0];
  /// Total height of the gradient panel (appBarHeight + this).
  static const double headerGradientContentHeight = 600.0;

  // ── AppBar pinned background blend ───────────────────────────────────────
  /// Alpha used when blending the palette color into the pinned AppBar bg.
  static const double appBarBlendAlpha = 0.90;

  // ── Player background gradient ────────────────────────────────────────────
  /// Top alpha of the dominant-color overlay on the player blurred background.
  static const double playerGradientTopAlpha = 0.60;
  /// Mid alpha of the dominant-color overlay.
  static const double playerGradientMidAlpha = 0.20;
  /// Dark overlay alpha applied over the blurred artwork — reduced so color shows.
  static const double playerDarkOverlayAlpha = 0.30;

  // ── Player queue sheet gradient ───────────────────────────────────────────
  static const double playerQueueGradientAlpha = 0.30;

  // ── Player album art glow ─────────────────────────────────────────────────
  static const double playerArtGlowAlpha = 0.55;

  // ── Helpers ───────────────────────────────────────────────────────────────

  /// Converts a raw dominant/vibrant [color] into the palette color used for
  /// gradients. Keeps the color vivid — only clamps lightness to a safe range.
  static Color toPaletteColor(Color color, {
    double lightnessBoost = extractLightnessBoost,
    double lightnessMin = extractLightnessMin,
    double lightnessMax = extractLightnessMax,
    double saturationReduce = extractSaturationReduce,
  }) {
    final hsl = HSLColor.fromColor(color);
    return hsl
        .withLightness((hsl.lightness + lightnessBoost).clamp(lightnessMin, lightnessMax))
        .withSaturation((hsl.saturation - saturationReduce).clamp(0.0, 1.0))
        .toColor();
  }

  /// Builds the [LinearGradient] used in the collection header sliver.
  static LinearGradient headerGradient(Color paletteColor) => LinearGradient(
        colors: [
          paletteColor.withValues(alpha: headerGradientTopAlpha),
          paletteColor.withValues(alpha: headerGradientMidAlpha),
          Colors.transparent,
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        stops: headerGradientStops,
      );

  /// Builds the pinned AppBar background color by blending [paletteColor]
  /// over [background] (defaults to [AppColors.background]).
  static Color appBarBackground(Color paletteColor, {Color? background}) => Color.alphaBlend(
        paletteColor.withValues(alpha: appBarBlendAlpha),
        background ?? AppColors.background,
      );

  /// Builds the dominant-color overlay gradient used in [PlayerBlurredBackground].
  static LinearGradient playerGradient(Color dominantColor) => LinearGradient(
        colors: [
          dominantColor.withValues(alpha: playerGradientTopAlpha),
          dominantColor.withValues(alpha: playerGradientMidAlpha),
          Colors.black.withValues(alpha: playerDarkOverlayAlpha),
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        stops: const [0, 0.5, 1],
      );
}
