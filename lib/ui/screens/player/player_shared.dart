import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../config/app_icons.dart';
import '../../theme/app_colors.dart';
import '../../theme/design_tokens.dart';

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
    return Stack(
      fit: StackFit.expand,
      children: [
        ColorFiltered(
          colorFilter: ColorFilter.mode(
            Colors.black.withValues(alpha: 0.45),
            BlendMode.darken,
          ),
          child: ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
            child: CachedNetworkImage(
              imageUrl: url,
              fit: BoxFit.cover,
              memCacheWidth: 100,
              memCacheHeight: 100,
              errorWidget: (_, __, ___) =>
                  Container(color: AppColors.background),
            ),
          ),
        ),
        AnimatedContainer(
          duration: AppDuration.medium,
          curve: AppCurves.decelerate,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                dominantColor.withValues(alpha: 0.35),
                dominantColor.withValues(alpha: 0.08),
                Colors.black.withValues(alpha: 0.45),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              stops: const [0, 0.5, 1],
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
