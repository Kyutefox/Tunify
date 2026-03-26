import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tunify/core/constants/app_icons.dart';
import 'package:tunify/features/player/player_state_provider.dart';
import 'package:tunify/ui/theme/app_colors.dart';import 'package:tunify/ui/theme/design_tokens.dart';

class PlayerControls extends ConsumerWidget {
  const PlayerControls({super.key, required this.dominantColor});
  final Color dominantColor;

  List<List<dynamic>> _repeatIcon(PlayerRepeatMode mode) =>
      mode == PlayerRepeatMode.one
          ? AppIcons.repeatOne
          : AppIcons.repeat;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isShuffleEnabled =
        ref.watch(playerProvider.select((s) => s.isShuffleEnabled));
    final repeatMode = ref.watch(playerProvider.select((s) => s.repeatMode));
    final isPlaying = ref.watch(playerProvider.select((s) => s.isPlaying));
    final isLoading = ref.watch(playerProvider.select((s) => s.isLoading));
    final notifier = ref.read(playerProvider.notifier);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        PlayerControlIcon(
          icon: AppIcons.shuffle,
          isActive: isShuffleEnabled,
          onTap: notifier.toggleShuffle,
        ),
        PlayerControlIcon(
          icon: AppIcons.skipPrevious,
          size: 36,
          onTap: notifier.playPrevious,
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
          onTap: notifier.playNext,
        ),
        PlayerControlIcon(
          icon: _repeatIcon(repeatMode),
          isActive: repeatMode != PlayerRepeatMode.off,
          onTap: notifier.cycleRepeatMode,
        ),
      ],
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
  });

  final List<List<dynamic>> icon;
  final VoidCallback onTap;
  final double size;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    // Ensure minimum 44px touch target per HIG/Material guidelines.
    final padding = ((44.0 - size) / 2).clamp(8.0, 16.0);
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: EdgeInsets.all(padding),
        child: AppIcon(
          icon: icon,
          size: size,
          color: isActive ? AppColors.primary : Colors.white.withValues(alpha: 0.8),
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
    return GestureDetector(
      onTapDown: (_) => _scale.reverse(),
      onTapUp: (_) {
        _scale.forward();
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
                color: widget.dominantColor.withValues(alpha: PaletteTheme.playerArtGlowAlpha),
                blurRadius: 28,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Center(
            child: widget.isLoading
                ? SizedBox(
                    width: 26,
                    height: 26,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppColors.background,
                      ),
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
                      color: AppColors.background,
                    ),
                  ),
          ),
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
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppIcon(icon: icon, color: Colors.white.withValues(alpha: 0.75), size: 22),
            const SizedBox(height: AppSpacing.xs + 2),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.75),
                fontSize: AppFontSize.micro,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
