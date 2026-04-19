import 'package:flutter/services.dart';

/// Tunify haptics wrapper.
///
/// Centralizes mapping to Flutter's platform haptics so UI widgets don't
/// depend on system calls directly.
///
/// Usage guidelines:
/// - selection(): For toggles, switches, filter pills
/// - impactLight(): For subtle interactions like taps on secondary buttons
/// - impactMedium(): For primary button presses, long press start
/// - impactHeavy(): For important actions like delete, save
/// - error(): For error states, failed operations
class TunifyHaptics {
  const TunifyHaptics._();

  /// Light selection feedback for toggles and switches
  static void selection() => HapticFeedback.selectionClick();

  /// Light impact for subtle interactions
  static void impactLight() => HapticFeedback.lightImpact();

  /// Medium impact for standard button presses
  static void impactMedium() => HapticFeedback.mediumImpact();

  /// Heavy impact for important actions
  static void impactHeavy() => HapticFeedback.heavyImpact();

  /// Error/warning feedback
  static void error() => HapticFeedback.vibrate();
}
