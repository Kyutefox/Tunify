import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tunify/v1/features/player/palette_provider.dart';
import 'package:tunify/v1/features/player/player_state_provider.dart';
import 'package:tunify/v1/features/player/playback_position_provider.dart';
import 'package:tunify/v1/core/utils/duration_format.dart';
import 'package:tunify/v1/ui/theme/app_colors.dart';
import 'package:tunify/v1/ui/theme/design_tokens.dart';

// PERF: Hoisted as a file-level const to avoid allocation inside build().
// FontFeature('tnum') is the const equivalent of FontFeature.tabularFigures().
const TextStyle _kTimeStyle = TextStyle(
  color: AppColors.playerTimeMuted,
  fontSize: AppFontSize.sm,
  fontWeight: FontWeight.w500,
  fontFeatures: [FontFeature('tnum')],
);

class PlayerProgressBar extends ConsumerStatefulWidget {
  const PlayerProgressBar({super.key, this.compact = false});

  final bool compact;

  @override
  ConsumerState<PlayerProgressBar> createState() => _PlayerProgressBarState();
}

class _PlayerProgressBarState extends ConsumerState<PlayerProgressBar>
    with SingleTickerProviderStateMixin {
  // ── Smooth seek animation ─────────────────────────────────────────────────
  late final AnimationController _anim = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 980), // slightly under 1 s tick
  );

  double _fromProgress = 0;
  double _toProgress = 0;

  // ── Buffered progress ─────────────────────────────────────────────────────
  // Updated via listenManual (never watch) — same isolation strategy as position.
  // Written directly to the field during playback; AnimatedBuilder picks it up
  // on its next tick. setState is called only when paused and change > 2%.
  double _bufferedProgress = 0.0;

  // ── Drag state ────────────────────────────────────────────────────────────
  bool _isDragging = false;
  double _dragValue = 0;

  @override
  void initState() {
    super.initState();
    // Listen outside build so animation side-effects never run during a build pass.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      ref.listenManual(
        playbackPositionProvider,
        (_, position) {
          final duration = ref.read(playerProvider.select((s) => s.duration));
          if (duration == null || duration.inMilliseconds == 0) return;
          final progress = position.inMilliseconds / duration.inMilliseconds;
          _onProgressUpdate(progress.clamp(0.0, 1.0));
        },
        fireImmediately: true,
      );

      // Buffered position: never watch, always listenManual.
      // During active playback _anim is ticking, so we write the field directly
      // and let AnimatedBuilder read it on its next tick — no setState cost.
      // When paused (_anim stopped), setState is needed to trigger a repaint,
      // but only when the change exceeds 2% to cap to ~50 repaints per song.
      ref.listenManual(bufferedPositionProvider, (_, buffered) {
        final duration = ref.read(playerProvider.select((s) => s.duration));
        if (duration == null || duration.inMilliseconds == 0) return;
        final progress =
            (buffered.inMilliseconds / duration.inMilliseconds).clamp(0.0, 1.0);
        if ((progress - _bufferedProgress).abs() > 0.02) {
          _bufferedProgress = progress;
          if (!_anim.isAnimating && mounted) setState(() {});
        }
      });
    });
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  void _onProgressUpdate(double newProgress) {
    if (_isDragging) return;
    if ((newProgress - _toProgress).abs() > 0.02) {
      _anim.stop();
      _fromProgress = newProgress;
      _toProgress = newProgress;
      _anim.value = 1.0;
    } else {
      _fromProgress = _currentAnimatedProgress;
      _toProgress = newProgress;
      _anim.forward(from: 0);
    }
  }

  double get _currentAnimatedProgress =>
      _fromProgress + (_toProgress - _fromProgress) * _anim.value;

  @override
  Widget build(BuildContext context) {
    // PERF: playbackPositionProvider is NOT watched here.
    // Position updates are handled exclusively by listenManual → _anim.
    // This widget only rebuilds on duration change (track change) or color
    // change (palette extraction) — both are infrequent events.
    final duration = ref.watch(playerProvider.select((s) => s.duration));
    final dominantColor = ref.watch(dominantColorProvider);

    final safeDuration = duration ?? Duration.zero;
    final durationKnown = duration != null && duration.inMilliseconds > 0;
    final durationText = durationKnown ? safeDuration.formattedMmSS : '--:--';

    // PERF: SliderThemeData computed ONCE per build, not per animation frame.
    // Moving this out of AnimatedBuilder.builder eliminates 120 object
    // allocations/second during scrubbing at 120fps.
    final sliderTheme = SliderTheme.of(context).copyWith(
      activeTrackColor: dominantColor,
      inactiveTrackColor: dominantColor.withValues(alpha: 0.25),
      // Buffered section sits between played and unplayed tracks.
      // 45% opacity strikes the balance: visible on dark backgrounds
      // without competing with the played (100%) track color.
      secondaryActiveTrackColor: dominantColor.withValues(alpha: 0.45),
      thumbColor: dominantColor,
      overlayColor: dominantColor.withValues(alpha: 0.15),
      trackHeight: widget.compact ? 3 : 4,
      thumbShape:
          RoundSliderThumbShape(enabledThumbRadius: widget.compact ? 6 : 7),
      overlayShape:
          RoundSliderOverlayShape(overlayRadius: widget.compact ? 12 : 16),
    );

    return Row(
      children: [
        // PERF: Isolated ConsumerWidget — only this leaf rebuilds on position
        // tick, not the whole PlayerProgressBar.
        _PlaybackTimeText(
          isDragging: _isDragging,
          dragFraction: _dragValue,
          safeDuration: safeDuration,
        ),
        const SizedBox(width: 8),

        // Seek bar — SliderTheme wraps AnimatedBuilder; data allocated once above.
        Expanded(
          child: SliderTheme(
            data: sliderTheme,
            child: AnimatedBuilder(
              animation: _anim,
              builder: (context, _) {
                final displayProgress =
                    _isDragging ? _dragValue : _currentAnimatedProgress;
                // PERF: No SliderTheme.of().copyWith() here — uses the parent
                // SliderTheme inherited from the widget above.
                return Slider(
                  value: displayProgress.clamp(0.0, 1.0),
                  // secondaryTrackValue renders the buffered range between the
                  // played track and the unplayed track using
                  // secondaryActiveTrackColor from SliderTheme above.
                  secondaryTrackValue: _bufferedProgress.clamp(0.0, 1.0),
                  onChangeStart: (v) {
                    _anim.stop();
                    setState(() {
                      _isDragging = true;
                      _dragValue = v;
                    });
                  },
                  onChanged: (v) => setState(() => _dragValue = v),
                  onChangeEnd: (v) {
                    final target = Duration(
                      milliseconds: (v * safeDuration.inMilliseconds).round(),
                    );
                    ref.read(playerProvider.notifier).seekTo(target);
                    setState(() {
                      _isDragging = false;
                      _fromProgress = v;
                      _toProgress = v;
                    });
                  },
                );
              },
            ),
          ),
        ),

        const SizedBox(width: 8),
        // Duration text — infrequent rebuild (only on track change).
        Text(durationText, style: _kTimeStyle),
      ],
    );
  }
}

/// Isolated leaf widget that watches [playbackPositionProvider] directly.
///
/// Only this widget (a single [Text] node) rebuilds on every position tick.
/// [PlayerProgressBar] itself is shielded from position-driven rebuilds,
/// eliminating its [SliderTheme] allocation and full Row reconstruction
/// at playback frequency.
class _PlaybackTimeText extends ConsumerWidget {
  const _PlaybackTimeText({
    required this.isDragging,
    required this.dragFraction,
    required this.safeDuration,
  });

  final bool isDragging;
  final double dragFraction;
  final Duration safeDuration;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Always watch so the subscription is stable (no conditional watch).
    final position = ref.watch(playbackPositionProvider);
    final text = isDragging
        ? Duration(
                milliseconds:
                    (dragFraction * safeDuration.inMilliseconds).round())
            .formattedMmSS
        : position.formattedMmSS;
    return Text(text, style: _kTimeStyle);
  }
}
