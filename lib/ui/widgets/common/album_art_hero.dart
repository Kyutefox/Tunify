import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import 'package:tunify/ui/theme/app_colors.dart';
import 'package:tunify/ui/theme/design_tokens.dart';

class AlbumArtHero extends StatelessWidget {
  const AlbumArtHero({
    super.key,
    required this.url,
    required this.tag,
    this.size,
    this.borderRadius,
    this.enableFlightShuttle = false,
  });

  final String url;
  final Object tag;
  final double? size;
  final double? borderRadius;
  final bool enableFlightShuttle;

  @override
  Widget build(BuildContext context) {
    final size = this.size ?? AppSpacing.xxl * 2;
    final radius = borderRadius ?? AppRadius.xl;
    final cachePx = (size * MediaQuery.devicePixelRatioOf(context)).round();

    return Hero(
      tag: tag,
      flightShuttleBuilder: enableFlightShuttle ? _flightShuttleBuilder : null,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: Container(
          width: size,
          height: size,
          color: Colors.black.withValues(alpha: 0.22),
          child: CachedNetworkImage(
            imageUrl: url,
            width: size,
            height: size,
            memCacheWidth: cachePx,
            memCacheHeight: cachePx,
            fit: BoxFit.contain,
            errorWidget: (_, __, ___) => _ErrorPlaceholder(size: size),
          ),
        ),
      ),
    );
  }

  static Widget _flightShuttleBuilder(
    BuildContext flightContext,
    Animation<double> animation,
    HeroFlightDirection direction,
    BuildContext fromHeroContext,
    BuildContext toHeroContext,
  ) {
    final radius = Tween<double>(
      begin:
          direction == HeroFlightDirection.push ? AppRadius.md : AppRadius.xl,
      end: direction == HeroFlightDirection.push ? AppRadius.xl : AppRadius.md,
    ).animate(CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
    ));

    return AnimatedBuilder(
      animation: radius,
      builder: (_, __) => ClipRRect(
        borderRadius: BorderRadius.circular(radius.value),
        child: _ShuttleImage(direction: direction),
      ),
    );
  }
}

class _ShuttleImage extends StatelessWidget {
  const _ShuttleImage({required this.direction});
  final HeroFlightDirection direction;

  @override
  Widget build(BuildContext context) {
    final heroWidget = direction == HeroFlightDirection.push
        ? (context.widget as Hero).child
        : (context.widget as Hero).child;

    if (heroWidget is ClipRRect) {
      final container = heroWidget.child;
      if (container is Container && container.child is CachedNetworkImage) {
        final image = container.child as CachedNetworkImage;
        return CachedNetworkImage(
            imageUrl: image.imageUrl.isNotEmpty ? image.imageUrl : '');
      }
    }
    return const SizedBox();
  }
}

class _ErrorPlaceholder extends StatelessWidget {
  const _ErrorPlaceholder({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      color: AppColors.surfaceLight,
      child: const Icon(
        Icons.music_note,
        color: AppColors.textMuted,
        size: 32,
      ),
    );
  }
}
