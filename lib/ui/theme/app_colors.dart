import 'package:flutter/material.dart';

import '../../config/primary_palette.dart';

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
  static const Color card = Color(0xFF202020);
  /// surface_hover — hover brighten
  static const Color surfaceLight = Color(0xFF282828);
  static const Color surfaceHighlight = Color(0xFF333333);

  // ——— Primary / accent (green for active, buttons, playback) ———
  static const Color primary = PrimaryPalette.primary;
  static const Color primaryLight = PrimaryPalette.primaryLight;
  static const Color primaryDark = PrimaryPalette.primaryDark;
  static const Color primaryContainer = PrimaryPalette.primaryContainer;
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
  static const Color textMuted = Color(0xFF535353);
  static const Color textDisabled = Color(0xFF333333);

  static const Color glassWhite = Color(0x18FFFFFF);
  static const Color glassBlack = Color(0x60000000);
  static const Color glassBorder = Color(0x25FFFFFF);

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
  static const LinearGradient accentGradient = primaryGradient;
  static const LinearGradient warmGradient = primaryGradient;
  static const LinearGradient coolGradient = primaryGradient;

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
    LinearGradient(colors: [Color(0xFF1DB954), Color(0xFF1ED760)]),
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
