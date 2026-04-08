import 'package:flutter/material.dart';

/// Theme-aware structural colors. Access via [AppColorsScheme.of(context)].
/// Fixed tokens (accents, gradients, player overlays) remain in [AppColors].
class AppColorsScheme extends ThemeExtension<AppColorsScheme> {
  const AppColorsScheme({
    required this.background,
    required this.surface,
    required this.surfaceLight,
    required this.surfaceHighlight,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.panelSurface,
    required this.panelTextSecondary,
    required this.panelTextMuted,
  });

  final Color background;
  final Color surface;
  final Color surfaceLight;
  final Color surfaceHighlight;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color panelSurface;
  final Color panelTextSecondary;
  final Color panelTextMuted;

  static const AppColorsScheme dark = AppColorsScheme(
    background: Color(0xFF121212),
    surface: Color(0xFF181818),
    surfaceLight: Color(0xFF2A2A2A),
    surfaceHighlight: Color(0xFF333333),
    textPrimary: Color(0xFFFFFFFF),
    textSecondary: Color(0xFFB3B3B3),
    textMuted: Color(0xFF9E9E9E),
    panelSurface: Color(0xFF121212),
    panelTextSecondary: Color(0xFF888888),
    panelTextMuted: Color(0xFF666666),
  );

  static const AppColorsScheme light = AppColorsScheme(
    background: Color(0xFFF0F0F0), // Slightly deeper — cards pop off it
    surface: Color(0xFFFFFFFF), // Pure white cards
    surfaceLight: Color(0xFFE8E8E8), // Visible chip/tile fills
    surfaceHighlight: Color(0xFFD5D5D5), // Clear separator/border contrast
    textPrimary: Color(0xFF0D0D0D), // Near-black — sharper than 121212
    textSecondary: Color(0xFF444444), // Darker than before — readable subtitle
    textMuted: Color(0xFF777777), // Softer hints — not too light
    panelSurface: Color(0xFFF7F7F7), // Sidebar/panel: slightly off-white
    panelTextSecondary: Color(0xFF444444),
    panelTextMuted: Color(0xFF777777),
  );

  static AppColorsScheme of(BuildContext context) =>
      Theme.of(context).extension<AppColorsScheme>() ?? dark;

  @override
  AppColorsScheme copyWith({
    Color? background,
    Color? surface,
    Color? surfaceLight,
    Color? surfaceHighlight,
    Color? textPrimary,
    Color? textSecondary,
    Color? textMuted,
    Color? panelSurface,
    Color? panelTextSecondary,
    Color? panelTextMuted,
  }) =>
      AppColorsScheme(
        background: background ?? this.background,
        surface: surface ?? this.surface,
        surfaceLight: surfaceLight ?? this.surfaceLight,
        surfaceHighlight: surfaceHighlight ?? this.surfaceHighlight,
        textPrimary: textPrimary ?? this.textPrimary,
        textSecondary: textSecondary ?? this.textSecondary,
        textMuted: textMuted ?? this.textMuted,
        panelSurface: panelSurface ?? this.panelSurface,
        panelTextSecondary: panelTextSecondary ?? this.panelTextSecondary,
        panelTextMuted: panelTextMuted ?? this.panelTextMuted,
      );

  @override
  AppColorsScheme lerp(AppColorsScheme? other, double t) {
    if (other == null) return this;
    return AppColorsScheme(
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceLight: Color.lerp(surfaceLight, other.surfaceLight, t)!,
      surfaceHighlight:
          Color.lerp(surfaceHighlight, other.surfaceHighlight, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
      panelSurface: Color.lerp(panelSurface, other.panelSurface, t)!,
      panelTextSecondary:
          Color.lerp(panelTextSecondary, other.panelTextSecondary, t)!,
      panelTextMuted: Color.lerp(panelTextMuted, other.panelTextMuted, t)!,
    );
  }
}
