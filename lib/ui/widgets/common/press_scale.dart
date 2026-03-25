import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:tunify/core/constants/app_icons.dart';
import 'package:tunify/ui/theme/app_colors.dart';
import 'package:tunify/ui/theme/design_tokens.dart';

class PressScale extends StatefulWidget {
  const PressScale({
    super.key,
    required this.child,
    required this.onTap,
    this.scale = 0.94,
    this.enableHaptics = true,
    this.duration,
    this.curve,
  });

  final Widget child;
  final VoidCallback onTap;
  final double scale;
  final bool enableHaptics;
  final Duration? duration;
  final Curve? curve;

  @override
  State<PressScale> createState() => _PressScaleState();
}

class _PressScaleState extends State<PressScale> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    return GestureDetector(
      onTapDown: (_) {
        setState(() => _pressed = true);
        if (widget.enableHaptics) HapticFeedback.lightImpact();
      },
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: reduceMotion ? 1.0 : (_pressed ? widget.scale : 1.0),
        duration: reduceMotion
            ? AppDuration.instant
            : (widget.duration ?? AppDuration.fast),
        curve: widget.curve ?? AppCurves.decelerate,
        child: widget.child,
      ),
    );
  }
}

class GlassPressButton extends StatefulWidget {
  const GlassPressButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.size = 22,
    this.containerSize = 42,
  });

  final List<List<dynamic>> icon;
  final VoidCallback onTap;
  final double size;
  final double containerSize;

  @override
  State<GlassPressButton> createState() => _GlassPressButtonState();
}

class _GlassPressButtonState extends State<GlassPressButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.88 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: AnimatedOpacity(
          opacity: _pressed ? 0.6 : 1.0,
          duration: const Duration(milliseconds: 120),
          child: Container(
            width: widget.containerSize,
            height: widget.containerSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.08),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.12),
                width: 0.5,
              ),
            ),
            child: Center(
              child: AppIcon(
                icon: widget.icon,
                color: AppColors.textPrimary,
                size: widget.size,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
