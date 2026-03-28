import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import 'package:tunify/core/constants/app_icons.dart';
import 'package:tunify/ui/theme/app_colors.dart';
import 'package:tunify/ui/theme/design_tokens.dart';

/// Shared Hero widget for the album art element transitioning between
/// [MiniPlayer] and [PlayerScreen].
///
/// ## Why a shared widget?
/// Both source and destination must present an *identical* widget tree inside
/// the Hero child so the framework never triggers an intrinsic-size
/// recalculation mid-flight. Any layout mismatch — different `width`/`height`
/// constraints, different `memCacheWidth`, a wrapping `Container` on one side
/// but not the other — causes `_HeroFlight.performUpdate` to re-query the
/// destination bounding box on every tick, which pauses the animation while
/// the engine re-measures.
///
/// ## Key decisions
/// - `SizedBox.square` pins the Hero child to an exact layout box; no implicit
///   sizing from the image widget itself.
/// - `CachedNetworkImage` has **no** `width`, `height`, `memCacheWidth`, or
///   `memCacheHeight`. This keeps its `ImageProvider` key identical to the one
///   used by `precacheImage(CachedNetworkImageProvider(url), context)` in
///   `_openFullPlayer`. A key mismatch would cause a cache miss, a mid-flight
///   decode, and a Hero pause.
/// - `RectTween` (linear path) is correct for a vertical mini→full expansion.
///   `MaterialRectArcTween` would arc sideways during the flight.
/// - `fadeInDuration: Duration.zero` prevents CachedNetworkImage from fading
///   in *on top of* the Hero shuttle image when the route completes.
/// - Shadow lives *outside* this widget in the caller so it is never part of
///   the Hero overlay. Shadow inside the Hero child is absent during the
///   shuttle and "pops" on landing — visually reads as the image growing taller.
class AlbumArtHero extends StatelessWidget {
  const AlbumArtHero({
    super.key,
    required this.url,
    required this.size,
    required this.borderRadius,
    this.placeholderIconSize = 24,
  });

  final String url;
  final double size;
  final double borderRadius;
  final double placeholderIconSize;

  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: 'player-album-art',
      createRectTween: (begin, end) => RectTween(begin: begin, end: end),
      flightShuttleBuilder: (_, anim, direction, __, ___) {
        final radius = Tween<double>(
          begin: direction == HeroFlightDirection.push
              ? AppRadius.md
              : AppRadius.xl,
          end: direction == HeroFlightDirection.push
              ? AppRadius.xl
              : AppRadius.md,
        ).animate(CurvedAnimation(
          parent: anim,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        ));
        return AnimatedBuilder(
          animation: radius,
          child: _ArtImage(url: url, iconSize: placeholderIconSize),
          builder: (_, child) => ClipRRect(
            borderRadius: BorderRadius.circular(radius.value),
            child: child,
          ),
        );
      },
      // SizedBox.square pins layout so the Hero child never triggers intrinsic
      // sizing. ClipRRect + _ArtImage mirror the shuttle exactly.
      child: SizedBox.square(
        dimension: size,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(borderRadius),
          child: _ArtImage(url: url, iconSize: placeholderIconSize),
        ),
      ),
    );
  }
}

/// Unconstrained image that fills whatever bounding box the Hero flight
/// allocates. No explicit width/height/memCacheWidth/memCacheHeight so its
/// [ImageProvider] key matches `precacheImage(CachedNetworkImageProvider(url))`.
class _ArtImage extends StatelessWidget {
  const _ArtImage({required this.url, required this.iconSize});

  final String url;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    if (url.isEmpty) {
      return ColoredBox(
        color: AppColors.surfaceLight,
        child: Center(
          child: AppIcon(
            icon: AppIcons.musicNote,
            color: AppColors.textMuted,
            size: iconSize,
          ),
        ),
      );
    }
    return CachedNetworkImage(
      imageUrl: url,
      fit: BoxFit.cover,
      fadeInDuration: Duration.zero,
      fadeOutDuration: Duration.zero,
      errorWidget: (_, __, ___) => ColoredBox(
        color: AppColors.surfaceLight,
        child: Center(
          child: AppIcon(
            icon: AppIcons.musicNote,
            color: AppColors.textMuted,
            size: iconSize,
          ),
        ),
      ),
    );
  }
}
