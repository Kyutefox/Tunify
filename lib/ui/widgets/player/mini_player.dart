import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tunify/features/player/palette_provider.dart';
import 'package:tunify/features/player/player_state_provider.dart';
import 'package:tunify/features/player/playback_position_provider.dart';
import 'package:tunify/ui/shell/shell_context.dart';
import 'package:tunify/ui/screens/desktop/player/player_screen.dart';
import 'package:tunify/ui/theme/app_colors.dart';
import 'package:tunify/ui/theme/design_tokens.dart';
import 'package:tunify/ui/widgets/player/album_art_hero.dart';
import '../player/../player/mini_player_play_button.dart';

void openFullPlayerRoute(BuildContext context) {
  Navigator.of(context).push(
    PageRouteBuilder(
      opaque: true,
      barrierColor: Colors.black,
      pageBuilder: (_, __, ___) => const PlayerScreen(),
      // 420ms open: gives the two-phase stagger time to read clearly.
      // 280ms close: slightly faster than open — snappy dismissal feels
      // intentional; mirrors Spotify and Apple Music's close timing.
      transitionDuration: const Duration(milliseconds: 420),
      reverseTransitionDuration: const Duration(milliseconds: 280),
      transitionsBuilder: (_, animation, __, child) {
        // Phase 1 (0–25%): Only the album art Hero is visible, expanding from
        // the mini player position. The shell (with the mini player in its
        // correct position) is visible underneath — this is how Flutter renders
        // during Hero flight with opaque:true+FadeTransition(opacity:0).
        //
        // Phase 2 (25–85%): Background fades in around the arriving Hero.
        // Interval + easeOut: fast initial fill, graceful deceleration to opaque.
        final bgFade = CurvedAnimation(
          parent: animation,
          curve: const Interval(0.25, 0.85, curve: Curves.easeOut),
          // easeIn on close: player content fades slowly at first then
          // accelerates away, matching the "Hero shrinking back" metaphor.
          reverseCurve: Curves.easeIn,
        );

        // Phase 3 (30–100%): Controls and player text slide up into position.
        // Starts 5% after bgFade so the background materialises first, then
        // content arrives inside it. easeOutCubic: snaps to destination fast,
        // ~88% complete at the midpoint of its interval — weighted and deliberate.
        final contentSlide = CurvedAnimation(
          parent: animation,
          curve: const Interval(0.30, 1.0, curve: Curves.easeOutCubic),
          // easeInCubic on close: content snaps away quickly, reinforcing the
          // downward-swipe dismissal gesture.
          reverseCurve: Curves.easeInCubic,
        );

        return FadeTransition(
          opacity: bgFade,
          child: SlideTransition(
            position: Tween<Offset>(
              // 5.5% upward offset: subtle enough to not feel like a full slide,
              // strong enough to give the player UI a sense of weight arriving.
              begin: const Offset(0.0, 0.055),
              end: Offset.zero,
            ).animate(contentSlide),
            child: child,
          ),
        );
      },
    ),
  );
}

class MiniPlayer extends ConsumerStatefulWidget {
  const MiniPlayer({super.key});

  @override
  ConsumerState<MiniPlayer> createState() => _MiniPlayerState();
}

class _MiniPlayerState extends ConsumerState<MiniPlayer> {
  double _dragY = 0;
  bool _isOpening = false;

  void _openFullPlayer() {
    if (_isOpening) return;
    _isOpening = true;
    // Precache the full-resolution image before pushing the route.
    // The Hero flight is 420ms — sufficient for a disk-cache decode to
    // complete. Without this, CachedNetworkImage decodes mid-flight at the
    // full-player cache size (artSize × dpr), which is a different ImageCache
    // key from the mini player's (44 × dpr) entry. That mid-flight decode
    // triggers markNeedsBuild on the image widget, which the Hero framework
    // detects as a layout change and pauses to remeasure — the visible stutter.
    final song = ref.read(currentSongProvider);
    if (song != null && song.thumbnailUrl.isNotEmpty) {
      precacheImage(CachedNetworkImageProvider(song.thumbnailUrl), context);
    }
    openFullPlayerRoute(context);
    Future<void>.delayed(const Duration(milliseconds: 400), () {
      _isOpening = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Desktop has its own DesktopPlayerBar — never show the mobile mini player.
    if (ShellContext.isDesktopOf(context)) return const SizedBox.shrink();

    final song = ref.watch(currentSongProvider);
    if (song == null) return const SizedBox.shrink();

    final isPlaying = ref.watch(playerProvider.select((s) => s.isPlaying));
    final isLoading = ref.watch(playerProvider.select((s) => s.isLoading));
    final dominantColor = ref.watch(dominantColorProvider);

    // PERF: playbackPositionProvider is intentionally NOT watched here.
    // _MiniPlayerSeekBar is wrapped in RepaintBoundary and subscribes to
    // position itself — position ticks no longer rebuild MiniPlayer's
    // AnimatedContainer (boxShadow + Color.lerp) or the Hero widget.

    return GestureDetector(
      onTap: _openFullPlayer,
      onVerticalDragUpdate: (d) {
        _dragY += d.delta.dy;
        if (_dragY < -24) {
          _openFullPlayer();
          _dragY = 0;
        }
      },
      onVerticalDragEnd: (_) => _dragY = 0,
      onHorizontalDragEnd: (d) {
        final v = d.primaryVelocity ?? 0;
        if (v < -400) {
          ref.read(playerProvider.notifier).playNext();
        } else if (v > 400) {
          ref.read(playerProvider.notifier).playPrevious();
        }
      },
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.sm,
          0,
          AppSpacing.sm,
          AppSpacing.sm,
        ),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          height: 68,
          decoration: BoxDecoration(
            color: Color.lerp(AppColors.surfaceLight, dominantColor, 0.18)!
                .withValues(alpha: 0.97),
            borderRadius: BorderRadius.circular(AppRadius.xl),
            border: Border.all(
              color: dominantColor.withValues(alpha: 0.20),
              width: 0.5,
            ),
            boxShadow: [
              BoxShadow(
                color: dominantColor.withValues(alpha: 0.18),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.28),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            clipBehavior: Clip.hardEdge,
            children: [
              Positioned.fill(
                bottom: 3,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                  ),
                  child: Row(
                    children: [
                      AlbumArtHero(
                        url: song.thumbnailUrl,
                        size: 44,
                        borderRadius: AppRadius.md,
                        placeholderIconSize: 20,
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              song.title,
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: AppFontSize.md,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              song.artist,
                              style: const TextStyle(
                                color: AppColors.textMuted,
                                fontSize: AppFontSize.xs,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      MiniPlayerPlayButton(
                        isPlaying: isPlaying,
                        isLoading: isLoading,
                        onTap: () =>
                            ref.read(playerProvider.notifier).togglePlayPause(),
                      ),
                    ],
                  ),
                ),
              ),
              // PERF: const — allocated once globally as a compile-time constant.
              // The seek bar reads its own providers inside the RepaintBoundary,
              // so only this layer repaints on position ticks.
              const Positioned(
                left: AppSpacing.md,
                right: AppSpacing.md,
                bottom: 0,
                child: RepaintBoundary(
                  child: _MiniPlayerSeekBar(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


/// Self-contained seek bar that subscribes to position, duration, and color
/// internally. Wrapped in a [RepaintBoundary] by its parent so position ticks
/// only repaint this small layer — never the [AnimatedContainer] above.
class _MiniPlayerSeekBar extends ConsumerWidget {
  // PERF: const constructor — this widget node is a compile-time constant.
  const _MiniPlayerSeekBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // These three watches are isolated inside the RepaintBoundary.
    // Only this widget rebuilds on position tick — NOT MiniPlayer.
    final position = ref.watch(playbackPositionProvider);
    final duration = ref.watch(playerProvider.select((s) => s.duration));
    final dominantColor = ref.watch(dominantColorProvider);

    final progress = (duration != null && duration.inMilliseconds > 0)
        ? (position.inMilliseconds / duration.inMilliseconds).clamp(0.0, 1.0)
        : 0.0;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapUp: (d) {
        final box = context.findRenderObject() as RenderBox?;
        if (box == null) return;
        final fraction = (d.localPosition.dx / box.size.width).clamp(0.0, 1.0);
        final dur = ref.read(playerProvider).duration;
        if (dur != null && dur.inMilliseconds > 0) {
          ref.read(playerProvider.notifier).seekTo(
                Duration(
                    milliseconds: (fraction * dur.inMilliseconds).round()),
              );
        }
      },
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(AppRadius.xl),
        ),
        child: LinearProgressIndicator(
          value: progress,
          minHeight: 3,
          backgroundColor: Colors.white.withValues(alpha: 0.06),
          valueColor: AlwaysStoppedAnimation<Color>(dominantColor),
        ),
      ),
    );
  }
}
