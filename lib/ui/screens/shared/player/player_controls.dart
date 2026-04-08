import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tunify/core/constants/app_icons.dart';
import 'package:tunify/data/models/library_playlist.dart' show ShuffleMode;
import 'package:tunify/features/player/player_state_provider.dart';
import 'package:tunify/ui/theme/app_colors.dart';
import 'package:tunify/ui/theme/design_tokens.dart';

// PERF: hoisted as file-level consts — no allocation per build.
const Color _kIconInactive = AppColors.playerIconInactive;
const Color _kExtraIconColor = AppColors.playerIconExtra;
const TextStyle _kExtraLabelStyle = TextStyle(
  color: AppColors.playerIconExtra,
  fontSize: AppFontSize.micro,
  fontWeight: FontWeight.w500,
);

class PlayerControls extends ConsumerWidget {
  const PlayerControls({super.key, required this.dominantColor});
  final Color dominantColor;

  List<List<dynamic>> _repeatIcon(PlayerRepeatMode mode) =>
      mode == PlayerRepeatMode.one ? AppIcons.repeatOne : AppIcons.repeat;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isShuffleEnabled =
        ref.watch(playerProvider.select((s) => s.isShuffleEnabled));
    final activeShuffleMode =
        ref.watch(playerProvider.select((s) => s.activeShuffleMode));
    final repeatMode = ref.watch(playerProvider.select((s) => s.repeatMode));
    final isPlaying = ref.watch(playerProvider.select((s) => s.isPlaying));
    final isLoading = ref.watch(playerProvider.select((s) => s.isLoading));
    final notifier = ref.read(playerProvider.notifier);

    final isAnyShuffleActive =
        isShuffleEnabled || activeShuffleMode != ShuffleMode.none;
    final isSmartShuffleActive = activeShuffleMode == ShuffleMode.smart;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _ShuffleControlIcon(
          isActive: isAnyShuffleActive,
          isSmart: isSmartShuffleActive,
          onTap: () {
            HapticFeedback.selectionClick();
            notifier.cycleShuffleMode();
          },
        ),
        PlayerControlIcon(
          icon: AppIcons.skipPrevious,
          size: 36,
          semanticLabel: 'Previous',
          onTap: () {
            HapticFeedback.mediumImpact();
            notifier.playPrevious();
          },
        ),
        PlayerBigPlayButton(
          isPlaying: isPlaying,
          isLoading: isLoading,
          dominantColor: dominantColor,
          onTap: notifier.togglePlayPause,
        ),
        PlayerControlIcon(
          icon: AppIcons.skipNext,
          size: 36,
          semanticLabel: 'Next',
          onTap: () {
            HapticFeedback.mediumImpact();
            notifier.playNext();
          },
        ),
        PlayerControlIcon(
          icon: _repeatIcon(repeatMode),
          isActive: repeatMode != PlayerRepeatMode.off,
          semanticLabel: 'Repeat: ${repeatMode.name}',
          onTap: () {
            HapticFeedback.selectionClick();
            notifier.cycleRepeatMode();
          },
        ),
      ],
    );
  }
}

class _ShuffleControlIcon extends StatelessWidget {
  const _ShuffleControlIcon({
    required this.isActive,
    required this.isSmart,
    required this.onTap,
  });

  final bool isActive;
  final bool isSmart;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const size = 26.0;
    final padding = ((44.0 - size) / 2).clamp(8.0, 16.0);
    final targetColor = isActive ? AppColors.primary : _kIconInactive;
    return Semantics(
      button: true,
      label:
          isSmart ? 'Smart Shuffle' : (isActive ? 'Shuffle on' : 'Shuffle off'),
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: EdgeInsets.all(padding),
          child: TweenAnimationBuilder<Color?>(
            tween: ColorTween(end: targetColor),
            duration: AppDuration.fast,
            curve: Curves.easeOut,
            builder: (_, color, __) {
              final c = color ?? targetColor;
              return SizedBox(
                width: size,
                height: size,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    AppIcon(icon: AppIcons.shuffle, size: size, color: c),
                    if (isSmart)
                      Positioned(
                        right: -6,
                        top: -6,
                        child: Icon(Icons.auto_awesome, size: 13, color: c),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class PlayerControlIcon extends StatelessWidget {
  const PlayerControlIcon({
    super.key,
    required this.icon,
    required this.onTap,
    this.size = 26,
    this.isActive = false,
    this.semanticLabel,
  });

  final List<List<dynamic>> icon;
  final VoidCallback onTap;
  final double size;
  final bool isActive;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    // Ensure minimum 44px touch target per HIG/Material guidelines.
    final padding = ((44.0 - size) / 2).clamp(8.0, 16.0);
    final targetColor = isActive ? AppColors.primary : _kIconInactive;
    return Semantics(
      button: true,
      label: semanticLabel,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: EdgeInsets.all(padding),
          child: TweenAnimationBuilder<Color?>(
            tween: ColorTween(end: targetColor),
            duration: AppDuration.fast,
            curve: Curves.easeOut,
            builder: (_, color, __) => AppIcon(
              icon: icon,
              size: size,
              color: color ?? targetColor,
            ),
          ),
        ),
      ),
    );
  }
}

class PlayerBigPlayButton extends StatefulWidget {
  const PlayerBigPlayButton({
    super.key,
    required this.isPlaying,
    required this.isLoading,
    required this.dominantColor,
    required this.onTap,
  });

  final bool isPlaying;
  final bool isLoading;
  final Color dominantColor;
  final VoidCallback onTap;

  @override
  State<PlayerBigPlayButton> createState() => _PlayerBigPlayButtonState();
}

class _PlayerBigPlayButtonState extends State<PlayerBigPlayButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _scale;
  late Animation<double> _curvedScale;

  @override
  void initState() {
    super.initState();
    _scale = AnimationController(
      vsync: this,
      duration: AppDuration.fast,
      value: 1.0,
    );
    _curvedScale = Tween<double>(begin: 0.88, end: 1.0).animate(
      CurvedAnimation(parent: _scale, curve: Curves.easeOutBack),
    );
  }

  @override
  void dispose() {
    _scale.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: widget.isPlaying ? 'Pause' : 'Play',
      child: GestureDetector(
        onTapDown: (_) => _scale.reverse(),
        onTapUp: (_) {
          _scale.forward();
          HapticFeedback.lightImpact();
          widget.onTap();
        },
        onTapCancel: () => _scale.forward(),
        child: ScaleTransition(
          scale: _curvedScale,
          child: Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: widget.dominantColor
                      .withValues(alpha: PaletteTheme.playerArtGlowAlpha),
                  blurRadius: 28,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Center(
              child: widget.isLoading
                  ? const SizedBox(
                      width: 26,
                      height: 26,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Color(0xFF121212)),
                      ),
                    )
                  : AnimatedSwitcher(
                      duration: AppDuration.fast,
                      transitionBuilder: (child, anim) =>
                          ScaleTransition(scale: anim, child: child),
                      child: AppIcon(
                        key: ValueKey(widget.isPlaying),
                        icon: widget.isPlaying ? AppIcons.pause : AppIcons.play,
                        size: 38,
                        color: const Color(0xFF121212),
                      ),
                    ),
            ),
          ),
        ),
      ), // GestureDetector
    ); // Semantics
  }
}

/// ✨ Smart Shuffle toggle button for the player extra-controls row.
/// Reads and writes [activeShuffleMode] on the current session queue.
/// Does NOT persist to the playlist's database shuffle setting.
class SmartShuffleExtraButton extends ConsumerWidget {
  const SmartShuffleExtraButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeShuffleMode =
        ref.watch(playerProvider.select((s) => s.activeShuffleMode));
    final isSmartActive = activeShuffleMode == ShuffleMode.smart;
    final color = isSmartActive ? AppColors.primary : _kExtraIconColor;

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        ref.read(playerProvider.notifier).toggleSmartShuffle();
      },
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TweenAnimationBuilder<Color?>(
              tween: ColorTween(end: color),
              duration: AppDuration.fast,
              curve: Curves.easeOut,
              builder: (_, c, __) {
                final col = c ?? color;
                return SizedBox(
                  width: 22,
                  height: 22,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      AppIcon(icon: AppIcons.shuffle, size: 22, color: col),
                      Positioned(
                        right: -4,
                        top: -4,
                        child: Icon(Icons.auto_awesome, size: 11, color: col),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: AppSpacing.xs + 2),
            TweenAnimationBuilder<Color?>(
              tween: ColorTween(end: color),
              duration: AppDuration.fast,
              curve: Curves.easeOut,
              builder: (_, c, __) => Text(
                'Smart',
                style: _kExtraLabelStyle.copyWith(color: c ?? color),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PlayerExtraButton extends StatelessWidget {
  const PlayerExtraButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final List<List<dynamic>> icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppIcon(icon: icon, color: _kExtraIconColor, size: 22),
              const SizedBox(height: AppSpacing.xs + 2),
              Text(label, style: _kExtraLabelStyle),
            ],
          ),
        ),
      ),
    );
  }
}
