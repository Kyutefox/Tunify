import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

class _MiniPlayerState extends ConsumerState<MiniPlayer> {
  double _dragY = 0;
  bool _isOpening = false;

  // Drives a subtle scale-up (max 3%) as the user drags upward, giving
  // immediate tactile feedback before the full player opens.
  double _dragScale = 0.0;
  // Ensures the selection haptic fires only once per drag gesture.
  bool _didTriggerOpenHaptic = false;

  void _openFullPlayer() {
    if (_isOpening) return;
    _isOpening = true;
    _didTriggerOpenHaptic = false;
    if (_dragScale > 0) setState(() => _dragScale = 0.0);
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
    final dominantColor = ref.watch(dominantColorProvider);

    // PERF: playbackPositionProvider is intentionally NOT watched here.
    // _MiniPlayerSeekBar is wrapped in RepaintBoundary and subscribes to
    // position itself — position ticks no longer rebuild MiniPlayer's
    // AnimatedContainer (boxShadow + Color.lerp) or the Hero widget.

    return GestureDetector(
      onTap: _openFullPlayer,
      onVerticalDragUpdate: (d) {
        _dragY += d.delta.dy;
        if (_dragY < 0) {
          // Upward drag: fire a one-shot selection haptic at 8px to signal
          // the gesture is being recognized, before the route commits at 24px.
          if (!_didTriggerOpenHaptic && _dragY < -8) {
            _didTriggerOpenHaptic = true;
            HapticFeedback.selectionClick();
          }
          // Scale preview: linearly map 0–50px of upward drag to 0–3% scale.
          final upPx = (-_dragY).clamp(0.0, 50.0);
          final newScale = upPx / 50.0;
          if ((newScale - _dragScale).abs() > 0.01) {
            setState(() => _dragScale = newScale);
          }
          if (_dragY < -24) {
            _openFullPlayer();
            _dragY = 0;
          }
        }
      },
      onVerticalDragEnd: (_) {
        _dragY = 0;
        _didTriggerOpenHaptic = false;
        if (_dragScale > 0) setState(() => _dragScale = 0.0);
      },
      onHorizontalDragEnd: (d) {
        final v = d.primaryVelocity ?? 0;
        if (v < -400) {
          HapticFeedback.mediumImpact();
          ref.read(playerProvider.notifier).playNext();
        } else if (v > 400) {
          HapticFeedback.mediumImpact();
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
        child: Transform.scale(
          scale: 1.0 + _dragScale * 0.03,
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
