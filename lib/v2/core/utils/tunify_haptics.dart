import 'package:flutter/services.dart';

/// Tunify haptics wrapper.
///
/// Centralizes mapping to Flutter's platform haptics so UI widgets don't
/// depend on system calls directly.
class TunifyHaptics {
  const TunifyHaptics._();

  static void selection() => HapticFeedback.selectionClick();

  static void impactLight() => HapticFeedback.lightImpact();

  static void impactMedium() => HapticFeedback.mediumImpact();

  static void impactHeavy() => HapticFeedback.heavyImpact();
}
