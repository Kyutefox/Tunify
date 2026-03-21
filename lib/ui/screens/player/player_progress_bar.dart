import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/providers/palette_provider.dart';
import '../../../shared/providers/player_state_provider.dart';
import '../../../shared/utils/duration_format.dart';

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

  // ── Drag state ────────────────────────────────────────────────────────────
  bool _isDragging = false;
  double _dragValue = 0;

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  /// Called whenever the provider emits a new progress value.
  void _onProgressUpdate(double newProgress) {
    if (_isDragging) return;
    // Snap immediately on large jumps (seek, track change).
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
    final progress = ref.watch(playerProvider.select((s) => s.progress));
    final position = ref.watch(playerProvider.select((s) => s.position));
    final duration = ref.watch(playerProvider.select((s) => s.duration));
    final dominantColor = ref.watch(dominantColorProvider);

    // Drive the animation whenever progress changes.
    _onProgressUpdate(progress.clamp(0.0, 1.0));

    final safeDuration = duration ?? Duration.zero;
    final durationKnown = duration != null && duration.inMilliseconds > 0;

    final positionText = _isDragging
        ? Duration(
            milliseconds: (_dragValue * safeDuration.inMilliseconds).round())
            .formattedMmSS
        : position.formattedMmSS;
    final durationText = durationKnown ? safeDuration.formattedMmSS : '--:--';

    const timeStyle = TextStyle(
      color: Color(0x80FFFFFF),
      fontSize: 12,
      fontWeight: FontWeight.w500,
      fontFeatures: [FontFeature.tabularFigures()],
    );

    final compact = widget.compact;

    return Row(
      children: [
        // Start time — tabular figures keep width stable
        Text(positionText, style: timeStyle),
        const SizedBox(width: 8),

        // Seek bar — animated
        Expanded(
          child: AnimatedBuilder(
            animation: _anim,
            builder: (context, _) {
              final displayProgress =
                  _isDragging ? _dragValue : _currentAnimatedProgress;
              return SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: dominantColor,
                  inactiveTrackColor: dominantColor.withValues(alpha: 0.25),
                  thumbColor: dominantColor,
                  overlayColor: dominantColor.withValues(alpha: 0.15),
                  trackHeight: compact ? 3 : 4,
                  thumbShape: RoundSliderThumbShape(
                      enabledThumbRadius: compact ? 6 : 7),
                  overlayShape: RoundSliderOverlayShape(
                      overlayRadius: compact ? 12 : 16),
                ),
                child: Slider(
                  value: displayProgress.clamp(0.0, 1.0),
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
                      milliseconds:
                          (v * safeDuration.inMilliseconds).round(),
                    );
                    ref.read(playerProvider.notifier).seekTo(target);
                    setState(() {
                      _isDragging = false;
                      _fromProgress = v;
                      _toProgress = v;
                    });
                  },
                ),
              );
            },
          ),
        ),

        const SizedBox(width: 8),
        // End time — tabular figures keep width stable
        Text(durationText, style: timeStyle),
      ],
    );
  }
}
