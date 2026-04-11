import 'package:flutter/material.dart';

import 'package:tunify/v1/ui/theme/app_colors.dart';
import 'package:tunify/v1/ui/theme/design_tokens.dart';

class HoverTile extends StatefulWidget {
  const HoverTile({
    super.key,
    required this.child,
    this.borderRadius,
    this.duration = const Duration(milliseconds: 160),
    this.hoverColor,
    this.showClickCursor = true,
  });

  final Widget child;
  final double? borderRadius;
  final Duration duration;
  final Color? hoverColor;
  final bool showClickCursor;

  @override
  State<HoverTile> createState() => _HoverTileState();
}

class _HoverTileState extends State<HoverTile>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Color?> _colorAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: widget.duration, vsync: this);
    _colorAnimation = ColorTween(
      begin: Colors.transparent,
      end: widget.hoverColor ?? AppColors.hoverOverlay.withValues(alpha: 0.28),
    ).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final radius = widget.borderRadius ?? AppRadius.sm;
    return MouseRegion(
      cursor:
          widget.showClickCursor ? SystemMouseCursors.click : MouseCursor.defer,
      onEnter: (_) => _controller.forward(),
      onExit: (_) => _controller.reverse(),
      child: RepaintBoundary(
        child: AnimatedBuilder(
          animation: _colorAnimation,
          builder: (context, child) => Container(
            decoration: BoxDecoration(
              color: _colorAnimation.value,
              borderRadius: BorderRadius.circular(radius),
            ),
            child: child,
          ),
          child: widget.child,
        ),
      ),
    );
  }
}
