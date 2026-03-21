import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../config/app_icons.dart';
import '../../theme/app_colors.dart';
import '../../theme/design_tokens.dart';

/// Circular play button used in section headers and action rows.
/// Provides consistent size, color, and press feedback everywhere.
class PlayCircleButton extends StatefulWidget {
  const PlayCircleButton({
    super.key,
    required this.onTap,
    this.size = 34,
    this.iconSize = 18,
  });

  final VoidCallback onTap;
  final double size;
  final double iconSize;

  @override
  State<PlayCircleButton> createState() => _PlayCircleButtonState();
}

class _PlayCircleButtonState extends State<PlayCircleButton> {
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
        duration: AppDuration.fast,
        curve: Curves.easeOut,
        child: Container(
          width: widget.size,
          height: widget.size,
          decoration: const BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: AppIcon(
              icon: AppIcons.play,
              size: widget.iconSize,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}

int cachePx(BuildContext context, double logicalSize) {
  return (logicalSize * MediaQuery.devicePixelRatioOf(context)).round();
}

class PressScale extends StatefulWidget {
  const PressScale({
    super.key,
    required this.child,
    required this.onTap,
    this.scale = 0.94,
  });

  final Widget child;
  final VoidCallback onTap;
  final double scale;

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
        HapticFeedback.lightImpact();
      },
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: reduceMotion ? 1.0 : (_pressed ? widget.scale : 1.0),
        duration: reduceMotion ? AppDuration.instant : AppDuration.fast,
        curve: AppCurves.decelerate,
        child: widget.child,
      ),
    );
  }
}

class PlaceholderArt extends StatelessWidget {
  const PlaceholderArt({super.key, required this.size});
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.surfaceHighlight, AppColors.surfaceLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: AppIcon(
          icon: AppIcons.musicNote,
          color: AppColors.textMuted,
          size: 36,
        ),
      ),
    );
  }
}

class SkeletonBox extends StatelessWidget {
  const SkeletonBox({
    super.key,
    required this.width,
    required this.height,
    required this.radius,
  });
  final double width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.surfaceHighlight,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}
