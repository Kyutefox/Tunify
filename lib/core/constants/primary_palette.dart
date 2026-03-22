import 'package:flutter/material.dart';

/// Spotify-inspired green palette used for active states, playback controls, and progress indicators.
abstract final class PrimaryPalette {
  PrimaryPalette._();

  /// Base brand green — buttons, active state indicators, playback progress bar.
  static const Color primary = Color(0xFF1DB954);

  /// Lightened brand green — hover states and gradient end stop.
  static const Color primaryLight = Color(0xFF1ED760);

  /// Alias for [primaryLight]; retained for compatibility.
  static const Color primaryMid = Color(0xFF1ED760);

  /// Darkened brand green — pressed states and container fills.
  static const Color primaryDark = Color(0xFF169C46);

  /// Muted dark surface tinted with brand green — used for primary-colored containers.
  static const Color primaryContainer = Color(0xFF1A3D2A);
}
