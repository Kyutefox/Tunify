import 'package:flutter/material.dart';

import 'package:tunify/ui/theme/app_colors.dart';
import 'package:tunify/ui/theme/design_tokens.dart';

class HoverTile extends StatefulWidget {
  const HoverTile({
    super.key,
    required this.child,
    this.borderRadius,
    this.duration = const Duration(milliseconds: 120),
    this.hoverColor,
  });

  final Widget child;
  final double? borderRadius;
  final Duration duration;
  final Color? hoverColor;

  @override
  State<HoverTile> createState() => _HoverTileState();
}

class _HoverTileState extends State<HoverTile> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final radius = widget.borderRadius ?? AppRadius.sm;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: widget.duration,
        decoration: BoxDecoration(
          color: _hovered
              ? (widget.hoverColor ?? AppColors.hoverOverlay)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(radius),
        ),
        child: widget.child,
      ),
    );
  }
}
