import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tunify/core/constants/app_icons.dart';
import 'package:tunify/features/player/player_state_provider.dart';
import 'package:tunify/ui/theme/app_colors.dart';
import 'package:tunify/ui/theme/design_tokens.dart';
import 'package:tunify/ui/widgets/common/click_region.dart';
import 'package:tunify/ui/widgets/player/now_playing_indicator.dart';
import 'package:tunify/ui/theme/app_colors_scheme.dart';

/// Circular play button used in section headers and action rows.
/// Default size matches [HomeSectionNavIcon] (32) so play aligns with prev/next on home.
/// Pass [size] / [iconSize] for larger affordances (e.g. playlist hero).
class PlayCircleButton extends StatefulWidget {
  const PlayCircleButton({
    super.key,
    required this.onTap,
    this.size,
    this.iconSize,
  });

  final VoidCallback onTap;
  final double? size;
  final double? iconSize;

  @override
  State<PlayCircleButton> createState() => _PlayCircleButtonState();
}

class _PlayCircleButtonState extends State<PlayCircleButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final size = widget.size ?? 32;
    final iconSize = widget.iconSize ?? 16;

    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.92 : 1.0,
        duration: AppDuration.normal,
        curve: Curves.easeOut,
        child: Container(
          width: size,
          height: size,
          decoration: const BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: AppIcon(
              icon: AppIcons.play,
              size: iconSize,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}

/// Prev/next pager controls used in home section headers (shared with loading skeletons).
class HomeSectionNavButtonPair extends StatelessWidget {
  const HomeSectionNavButtonPair({
    super.key,
    required this.pageCtrl,
    required this.currentPage,
    this.totalPages = 2,
  });

  final PageController pageCtrl;
  final int currentPage;
  final int totalPages;

  void _go(int page) => pageCtrl.animateToPage(
        page,
        duration: AppDuration.normal,
        curve: Curves.easeInOut,
      );

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        HomeSectionNavIcon(
          icon: AppIcons.back,
          enabled: currentPage > 0,
          onTap: () => _go(currentPage - 1),
        ),
        const SizedBox(width: AppSpacing.xs),
        HomeSectionNavIcon(
          icon: AppIcons.forward,
          enabled: currentPage < totalPages - 1,
          onTap: () => _go(currentPage + 1),
        ),
      ],
    );
  }
}

class HomeSectionNavIcon extends StatelessWidget {
  const HomeSectionNavIcon({
    super.key,
    required this.icon,
    required this.onTap,
    this.enabled = true,
  });

  final List<List<dynamic>> icon;
  final VoidCallback onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: enabled
              ? AppColorsScheme.of(context).surface
              : AppColorsScheme.of(context).surface.withValues(alpha: 0.4),
          shape: BoxShape.circle,
        ),
        child: Center(
          child: AppIcon(
            icon: icon,
            size: 16,
            color: enabled
                ? AppColorsScheme.of(context).textPrimary
                : AppColorsScheme.of(context).textMuted,
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
    return ClickRegion(
      child: GestureDetector(
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
          duration: reduceMotion ? AppDuration.instant : AppDuration.normal,
          curve: AppCurves.decelerate,
          child: widget.child,
        ),
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
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColorsScheme.of(context).surfaceHighlight,
            AppColorsScheme.of(context).surfaceLight
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: AppIcon(
          icon: AppIcons.musicNote,
          color: AppColorsScheme.of(context).textMuted,
          size: 36,
        ),
      ),
    );
  }
}

// ─── PageController lifecycle mixin ──────────────────────────────────────────

/// Mixin that manages a [PageController] with a page-tracking listener.
/// Mix into a [State] or [ConsumerState] to eliminate the repeated
/// initState/dispose/listener boilerplate across all paged section widgets.
///
/// Usage:
///   class _MyState extends ConsumerState[MyWidget] with PagedSectionMixin {
///     @override Widget build(...) { ... use pageCtrl, currentPage ... }
///   }
mixin PagedSectionMixin<T extends StatefulWidget> on State<T> {
  final pageCtrl = PageController();
  int currentPage = 0;

  void _onPageScroll() {
    final p = pageCtrl.page?.round() ?? 0;
    if (p != currentPage) setState(() => currentPage = p);
  }

  @override
  void initState() {
    super.initState();
    pageCtrl.addListener(_onPageScroll);
  }

  @override
  void dispose() {
    pageCtrl.removeListener(_onPageScroll);
    pageCtrl.dispose();
    super.dispose();
  }
}

// ─── InlineNowPlayingDot ──────────────────────────────────────────────────────

/// Tiny animated bars indicator shown inline before a song title.
/// Replaces the repeated Padding→SizedBox(10×10)→FittedBox→NowPlayingIndicator
/// pattern used in SongListTile, SquareSongCard, and QuickPickTile.
class InlineNowPlayingDot extends StatelessWidget {
  const InlineNowPlayingDot({super.key, required this.animate});
  final bool animate;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: AppSpacing.xs),
      child: SizedBox(
        width: 10,
        height: 10,
        child: FittedBox(
          fit: BoxFit.contain,
          child: NowPlayingIndicator(size: 8, barCount: 3, animate: animate),
        ),
      ),
    );
  }
}

// ─── NowPlayingStatus helper ──────────────────────────────────────────────────

/// Resolves now-playing state for a given [songId] from the player provider.
/// Avoids repeating the same two ref.watch calls + id comparison in every tile.
class NowPlayingStatus {
  const NowPlayingStatus({required this.isNowPlaying, required this.isPlaying});
  final bool isNowPlaying;
  final bool isPlaying;

  static NowPlayingStatus of(WidgetRef ref, String songId) {
    // PERF: single select — scopes isPlaying to this songId, one equality check
    // instead of two broad subscriptions (was: all tiles rebuilt on play/pause).
    final (isNowPlaying, isPlaying) = ref.watch(
      playerProvider.select((s) {
        final isCurrent = s.currentSong?.id == songId;
        return (isCurrent, isCurrent && s.isPlaying);
      }),
    );
    return NowPlayingStatus(isNowPlaying: isNowPlaying, isPlaying: isPlaying);
  }
}

// ─── DpiAwareThumbnail ────────────────────────────────────────────────────────

/// DPI-aware [CachedNetworkImage] thumbnail with rounded corners.
/// Promoted from the private _DpiAwareThumbnail in song_list_tile.dart so all
/// widgets share one implementation.
class DpiAwareThumbnail extends StatelessWidget {
  const DpiAwareThumbnail({
    super.key,
    required this.url,
    required this.size,
    this.radius = AppRadius.sm,
  });

  final String url;
  final double size;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final dpr = MediaQuery.devicePixelRatioOf(context);
    final cacheSize = (size * dpr).round();

    // PERF: ClipRRect (1 render object) replaces Container+BoxDecoration+clipBehavior (3+).
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: SizedBox(
        width: size,
        height: size,
        child: url.isNotEmpty
            ? CachedNetworkImage(
                imageUrl: url,
                width: size,
                height: size,
                fit: BoxFit.cover,
                memCacheWidth: cacheSize,
                memCacheHeight: cacheSize,
                fadeInDuration: Duration.zero,
                fadeOutDuration: Duration.zero,
                errorWidget: (_, __, ___) => PlaceholderArt(size: size),
              )
            : PlaceholderArt(size: size),
      ),
    );
  }
}

// ─── ExplicitBadge ────────────────────────────────────────────────────────────

/// Small "E" badge shown next to explicit song titles.
/// Promoted from the private _ExplicitBadge in song_list_tile.dart.
class ExplicitBadge extends StatelessWidget {
  const ExplicitBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: AppColorsScheme.of(context).textMuted.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(AppRadius.xs),
      ),
      child: Text(
        'E',
        style: TextStyle(
          color: AppColorsScheme.of(context).textMuted,
          fontSize: AppFontSize.micro,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

// ─── HoverPlayOverlay ─────────────────────────────────────────────────────────

/// Animated play-button overlay shown on hover over artwork cards.
/// Replaces the duplicated AnimatedOpacity+Container+gradient-circle pattern
/// in SongCard and PlaylistCard.
class HoverPlayOverlay extends StatelessWidget {
  const HoverPlayOverlay({super.key, required this.visible});
  final bool visible;

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: visible ? 1.0 : 0.0,
      duration: AppDuration.fast,
      child: Container(
        color: Colors.black.withValues(alpha: 0.3),
        child: Center(
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.8, end: visible ? 1.0 : 0.8),
            duration: AppDuration.fast,
            builder: (context, scale, child) => Transform.scale(
              scale: scale,
              child: Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppColors.primaryGradient,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.6),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child:
                    AppIcon(icon: AppIcons.play, color: Colors.white, size: 30),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
