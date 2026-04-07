import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tunify/features/player/palette_provider.dart';
import 'package:tunify/features/player/player_state_provider.dart';
import 'package:tunify/features/player/playback_position_provider.dart';
import 'package:tunify/ui/shell/shell_context.dart';
import 'package:tunify/ui/screens/desktop/player/player_screen.dart';
import 'package:tunify/ui/theme/design_tokens.dart';
import 'package:tunify/ui/widgets/player/album_art_hero.dart';
import '../player/../player/mini_player_play_button.dart';
import 'package:tunify/core/constants/app_icons.dart';
import 'package:tunify/ui/theme/app_colors_scheme.dart';

void openFullPlayerRoute(BuildContext context) {
  Navigator.of(context).push(
    PageRouteBuilder(
      opaque: false,
      barrierColor: Colors.transparent,
      pageBuilder: (_, __, ___) => const PlayerScreen(),
      transitionDuration: const Duration(milliseconds: 380),
      reverseTransitionDuration: const Duration(milliseconds: 260),
      transitionsBuilder: (_, animation, __, child) {
        // The Hero flies freely — no FadeTransition wrapper fighting it.
        // The player background (gradient + deferred blur) fades itself in
        // via PlayerBlurredBackground's own post-frame animation.
        // On close: fade out so the mini player reappears cleanly.
        return FadeTransition(
          opacity: CurvedAnimation(
            parent: animation,
            curve: Curves.easeIn,
            reverseCurve: Curves.easeIn,
          ),
          child: child,
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

// No shadow - cleaner look for both light and dark modes
List<BoxShadow> _kMiniPlayerStaticShadow(BuildContext context) => [];

class _MiniPlayerState extends ConsumerState<MiniPlayer> {
  double _dragY = 0;
  double _dragX = 0;
  bool _isOpening = false;

  late List<BoxShadow> _boxShadows = _kMiniPlayerStaticShadow(context);

  // Drives a subtle scale-up (max 3%) as the user drags upward, giving
  // immediate tactile feedback before the full player opens.
  double _dragScale = 0.0;
  double _dragOpacity = 1.0;

  // Ensures the selection haptic fires only once per drag gesture.
  bool _didTriggerOpenHaptic = false;
  bool _didTriggerNextHaptic = false;
  bool _didTriggerPrevHaptic = false;

  void _openFullPlayer() {
    if (_isOpening) return;
    _isOpening = true;
    _didTriggerOpenHaptic = false;
    if (_dragScale > 0) setState(() => _dragScale = 0.0);
    if (_dragOpacity < 1.0) setState(() => _dragOpacity = 1.0);
    openFullPlayerRoute(context);
    Future<void>.delayed(const Duration(milliseconds: 500), () {
      if (mounted) _isOpening = false;
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
    // No shadows - cleaner look for both light and dark modes
    _boxShadows = [];

    // PERF: playbackPositionProvider is intentionally NOT watched here.
    // _MiniPlayerSeekBar is wrapped in RepaintBoundary and subscribes to
    // position itself — position ticks no longer rebuild MiniPlayer's
    // AnimatedContainer (boxShadow + Color.lerp) or the Hero widget.

    return GestureDetector(
      onTap: _openFullPlayer,
      onVerticalDragUpdate: (d) {
        final nextY = (_dragY + d.delta.dy).clamp(-80.0, 120.0);
        final shouldOpen = nextY < -24;

        if (!shouldOpen &&
            !_didTriggerOpenHaptic &&
            nextY < -8) {
          _didTriggerOpenHaptic = true;
          HapticFeedback.selectionClick();
        }

        setState(() {
          if (shouldOpen) {
            _dragY = 0;
            _dragScale = 0;
            _dragOpacity = 1.0;
          } else {
            _dragY = nextY;
            if (_dragY < 0) {
              final upPx = (-_dragY).clamp(0.0, 50.0);
              _dragScale = upPx / 50.0;
              _dragOpacity = 1.0;
            } else if (_dragY > 0) {
              _dragScale = 0;
              _dragOpacity =
                  (1.0 - (_dragY / 120.0) * 0.35).clamp(0.65, 1.0);
            } else {
              _dragScale = 0;
              _dragOpacity = 1.0;
            }
          }
        });

        if (shouldOpen) {
          _didTriggerOpenHaptic = false;
          _openFullPlayer();
        }
      },
      onVerticalDragEnd: (d) {
        final vy = d.primaryVelocity ?? 0;
        const dismissDistance = 48.0;
        const flingDismissVy = 400.0;
        final dismiss = _dragY > dismissDistance || vy > flingDismissVy;

        if (dismiss) {
          HapticFeedback.mediumImpact();
          ref.read(playerProvider.notifier).clearCurrentSong();
        }

        if (!mounted) return;
        setState(() {
          _dragY = 0;
          _dragScale = 0;
          _dragOpacity = 1.0;
        });
        _didTriggerOpenHaptic = false;
      },
      onHorizontalDragUpdate: (d) {
        _dragX += d.delta.dx;

        // Provide visual feedback during horizontal drag
        if (_dragX.abs() > 5) {
          if (_dragX > 0 && !_didTriggerPrevHaptic) {
            // Dragging right (previous)
            _didTriggerPrevHaptic = true;
            _didTriggerNextHaptic = false;
            HapticFeedback.selectionClick();
          } else if (_dragX < 0 && !_didTriggerNextHaptic) {
            // Dragging left (next)
            _didTriggerNextHaptic = true;
            _didTriggerPrevHaptic = false;
            HapticFeedback.selectionClick();
          }
        }
      },
      onHorizontalDragEnd: (d) {
        final v = d.primaryVelocity ?? 0;
        if (v < -300 || _dragX < -50) {
          // Swipe left (next song)
          HapticFeedback.mediumImpact();
          ref.read(playerProvider.notifier).playNext();
        } else if (v > 300 || _dragX > 50) {
          // Swipe right (previous song)
          HapticFeedback.mediumImpact();
          ref.read(playerProvider.notifier).playPrevious();
        }

        // Reset horizontal drag state
        _dragX = 0;
        _didTriggerNextHaptic = false;
        _didTriggerPrevHaptic = false;
      },
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.sm,
          0,
          AppSpacing.sm,
          AppSpacing.sm,
        ),
        child: AnimatedOpacity(
          opacity: _dragOpacity,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          child: Transform.scale(
            scale: 1.0 +
                _dragScale *
                    0.03, // Only scale on intentional drag up, not swipe gestures
            // Add horizontal translation feedback for swipe gestures
            child: Transform.translate(
              offset: Offset(_dragX * 0.2, _dragY > 0 ? _dragY : 0),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                height: 68,
                decoration: BoxDecoration(
                  color: AppColorsScheme.of(context).background,
                  borderRadius: BorderRadius.circular(AppRadius.xl),
                  border: Border.all(
                    color: AppColorsScheme.of(context)
                        .textPrimary
                        .withValues(alpha: 0.10),
                    width: 0.5,
                  ),
                  boxShadow: _boxShadows,
                ),
                child: Stack(
                  clipBehavior: Clip.hardEdge,
                  children: [
                    // Main content
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
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    song.title,
                                    style: TextStyle(
                                      color: AppColorsScheme.of(context)
                                          .textPrimary,
                                      fontSize: AppFontSize.md,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    song.artist,
                                    style: TextStyle(
                                      color:
                                          AppColorsScheme.of(context).textMuted,
                                      fontSize: AppFontSize.xs,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const _MiniPlayerUpNext(),
                                ],
                              ),
                            ),
                            MiniPlayerPlayButton(
                              isPlaying: isPlaying,
                              isLoading: isLoading,
                              onTap: () => ref
                                  .read(playerProvider.notifier)
                                  .togglePlayPause(),
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
                Duration(milliseconds: (fraction * dur.inMilliseconds).round()),
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

/// Shows "Up next: [title]" below the artist name when the queue has a
/// following track.  Isolated in its own widget so it rebuilds independently
/// of the parent [MiniPlayer] — no position ticks trigger it.
class _MiniPlayerUpNext extends ConsumerWidget {
  const _MiniPlayerUpNext();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nextSong = ref.watch(playerProvider.select((s) {
      final idx = s.currentIndex;
      if (idx < 0 || idx + 1 >= s.queue.length) return null;
      return s.queue[idx + 1];
    }));

    if (nextSong == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Row(
        children: [
          AppIcon(
            icon: AppIcons.skipNext,
            color: AppColorsScheme.of(context).textMuted.withValues(alpha: 0.6),
            size: 10,
          ),
          const SizedBox(width: 3),
          Expanded(
            child: Text(
              nextSong.title,
              style: TextStyle(
                color: AppColorsScheme.of(context)
                    .textMuted
                    .withValues(alpha: 0.7),
                fontSize: AppFontSize.micro,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
