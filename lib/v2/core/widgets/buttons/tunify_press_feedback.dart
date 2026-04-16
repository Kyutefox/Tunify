import 'package:flutter/material.dart';

import 'package:tunify/v2/core/constants/app_border_radius.dart';
import 'package:tunify/v2/core/utils/tunify_haptics.dart';

/// Tunify press feedback:
/// - Slight scale-down while pressed
/// - Single haptic on long-press start
/// - No InkWell ripple / highlight overlay (avoids unwanted background)
class TunifyPressFeedback extends StatefulWidget {
  const TunifyPressFeedback({
    super.key,
    required this.child,
    required this.onLongPress,
    this.borderRadius =
        const BorderRadius.all(Radius.circular(AppBorderRadius.subtle)),
    this.enableHaptics = true,
    this.scaleDownFactor = 0.97,
  });

  final Widget child;
  final VoidCallback onLongPress;
  final BorderRadius borderRadius;
  final bool enableHaptics;
  final double scaleDownFactor;

  @override
  State<TunifyPressFeedback> createState() => _TunifyPressFeedbackState();
}

class _TunifyPressFeedbackState extends State<TunifyPressFeedback> {
  bool _pressed = false;
  bool _hapticFired = false;

  void _setPressed(bool value) {
    if (_pressed == value) return;
    setState(() => _pressed = value);
  }

  void _fireHapticIfNeeded() {
    if (!widget.enableHaptics || _hapticFired) return;
    _hapticFired = true;
    // Centralized mapping (so widgets don't call system haptics directly).
    TunifyHaptics.impactMedium();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: widget.borderRadius,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTapDown: (_) {
          _setPressed(true);
        },
        onTapUp: (_) {
          _setPressed(false);
          _hapticFired = false;
        },
        onTapCancel: () {
          _setPressed(false);
          _hapticFired = false;
        },
        onLongPressStart: (_) {
          _setPressed(true);
          _fireHapticIfNeeded();
        },
        onLongPress: () {
          // Some platforms/gestures may not reliably call onLongPressStart;
          // fire again defensively but still guarded by `_hapticFired`.
          _fireHapticIfNeeded();
          // Ensure press state always releases even when opening a modal sheet
          // prevents onLongPressEnd from firing.
          _setPressed(false);
          _hapticFired = false;
          widget.onLongPress();
        },
        onLongPressEnd: (_) {
          _setPressed(false);
          _hapticFired = false;
        },
        child: AnimatedScale(
          scale: _pressed ? widget.scaleDownFactor : 1.0,
          duration: const Duration(milliseconds: 110),
          curve: Curves.easeOutCubic,
          child: widget.child,
        ),
      ),
    );
  }
}
