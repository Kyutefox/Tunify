import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import 'package:tunify/core/constants/app_icons.dart';
import 'package:tunify/ui/theme/app_colors.dart';
import 'package:tunify/ui/theme/design_tokens.dart';

class PlayerBlurredBackground extends StatelessWidget {
  const PlayerBlurredBackground({
    super.key,
    required this.url,
    required this.dominantColor,
  });

  final String url;
  final Color dominantColor;

  @override
  Widget build(BuildContext context) {
    final hasArt = url.isNotEmpty;
    return Stack(
      fit: StackFit.expand,
      children: [
        if (hasArt)
          // PERF: ValueKey ensures this layer is reused across song changes when
          // the URL stays the same. The blur (sigmaX: 40) is expensive; the
          // RepaintBoundary ensures it only repaints when the image URL changes,
          // not on every dominantColor animation tick.
          RepaintBoundary(
            key: ValueKey('blur_$url'),
            child: ColorFiltered(
              colorFilter: ColorFilter.mode(
                Colors.black.withValues(alpha: PaletteTheme.playerDarkOverlayAlpha),
                BlendMode.darken,
              ),
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
                child: CachedNetworkImage(
                  imageUrl: url,
                  fit: BoxFit.cover,
                  memCacheWidth: 100,
                  memCacheHeight: 100,
                  fadeInDuration: Duration.zero,
                  fadeOutDuration: Duration.zero,
                  errorWidget: (_, __, ___) =>
                      Container(color: AppColors.background),
                ),
              ),
            ),
          )
        else
          Container(color: AppColors.background),
        if (hasArt)
          // PERF: RepaintBoundary isolates the gradient overlay's implicit
          // animation repaints (60–120fps) from the blur layer above it.
          // Without this boundary, every gradient animation tick would
          // invalidate the full background stack.
          RepaintBoundary(
            child: AnimatedContainer(
              duration: AppDuration.medium,
              curve: AppCurves.decelerate,
              decoration: BoxDecoration(
                gradient: PaletteTheme.playerGradient(dominantColor),
              ),
            ),
          ),
      ],
    );
  }
}

class PlayerGlassButton extends StatefulWidget {
  const PlayerGlassButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.size = 22,
  });

  final List<List<dynamic>> icon;
  final VoidCallback onTap;
  final double size;

  @override
  State<PlayerGlassButton> createState() => _PlayerGlassButtonState();
}

class _PlayerGlassButtonState extends State<PlayerGlassButton> {
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
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.08),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.12),
                width: 0.5,
              ),
            ),
            child: Center(
              child: AppIcon(icon: widget.icon, color: AppColors.textPrimary, size: widget.size),
            ),
          ),
        ),
      ),
    );
  }
}
