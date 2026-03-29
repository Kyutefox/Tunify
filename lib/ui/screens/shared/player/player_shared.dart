import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import 'package:tunify/core/constants/app_icons.dart';
import 'package:tunify/ui/theme/app_colors.dart';
import 'package:tunify/ui/theme/design_tokens.dart';
import 'package:tunify/ui/theme/app_colors_scheme.dart';

/// Blurred background for the player screen.
///
/// Defers the expensive [ImageFiltered] blur rasterization until after the
/// Hero animation completes. Without the delay the GPU is asked to rasterize
/// a full-screen blur on the very first frame of the route, which competes
/// with the Hero flight and causes the visible mid-flight stutter.
class PlayerBlurredBackground extends StatefulWidget {
  const PlayerBlurredBackground({
    super.key,
    required this.url,
    required this.dominantColor,
  });

  final String url;
  final Color dominantColor;

  @override
  State<PlayerBlurredBackground> createState() =>
      _PlayerBlurredBackgroundState();
}

class _PlayerBlurredBackgroundState extends State<PlayerBlurredBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: AppDuration.fast,
    );
    _opacity = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    // One post-frame callback: Hero rasterizes first frame, then blur is added.
    // GPU handles them sequentially instead of simultaneously — no hitch.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasArt = widget.url.isNotEmpty;
    return Stack(
      fit: StackFit.expand,
      children: [
        // Solid background — always dark regardless of theme; player is immersive.
        const ColoredBox(color: Color(0xFF121212)),
        // Gradient overlay — visible immediately so the player never looks dim.
        if (hasArt)
          RepaintBoundary(
            child: AnimatedContainer(
              duration: AppDuration.fast,
              curve: AppCurves.decelerate,
              decoration: BoxDecoration(
                gradient: PaletteTheme.playerGradient(widget.dominantColor),
              ),
            ),
          ),
        // Blur layer — deferred until after the Hero flight ends so the GPU
        // doesn't rasterize a full-screen blur mid-flight (the visible stutter).
        // ColorFiltered dark overlay is INSIDE the fade so brightness is
        // consistent: gradient already provides the dark feel before blur arrives.
        if (hasArt)
          FadeTransition(
            opacity: _opacity,
            child: RepaintBoundary(
              key: ValueKey('blur_${widget.url}'),
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: CachedNetworkImage(
                  imageUrl: widget.url,
                  fit: BoxFit.cover,
                  memCacheWidth: 100,
                  memCacheHeight: 100,
                  fadeInDuration: Duration.zero,
                  fadeOutDuration: Duration.zero,
                  errorWidget: (_, __, ___) =>
                      const ColoredBox(color: Color(0xFF121212)),
                ),
              ),
            ),
          ),
        // Permanent dark overlay — always on top of blur so brightness never
        // changes as blur fades in. Replaces the ColorFiltered that was inside
        // the deferred layer.
        if (hasArt)
          ColoredBox(
            color: Colors.black.withValues(
                alpha: PaletteTheme.playerDarkOverlayAlpha),
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
              color: Colors.white.withValues(alpha: 0.15),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.25),
                width: 0.5,
              ),
            ),
            child: Center(
              child: AppIcon(icon: widget.icon, color: Colors.white, size: widget.size),
            ),
          ),
        ),
      ),
    );
  }
}
