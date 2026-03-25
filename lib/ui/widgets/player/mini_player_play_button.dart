import 'package:flutter/material.dart';

import 'package:tunify/core/constants/app_icons.dart';
import 'package:tunify/ui/theme/app_colors.dart';
import 'package:tunify/ui/theme/design_tokens.dart';

/// Reusable play/pause button (mini player style: circle, play/pause icon).
/// Used by [MiniPlayer] and the queue sheet now-playing row.
class MiniPlayerPlayButton extends StatelessWidget {
  const MiniPlayerPlayButton({
    super.key,
    required this.isPlaying,
    required this.isLoading,
    required this.onTap,
  });
  final bool isPlaying;
  final bool isLoading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: const BoxDecoration(
          color: AppColors.textPrimary,
          shape: BoxShape.circle,
        ),
        child: Center(
          child: isLoading
              ? SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppColors.background,
                    ),
                  ),
                )
              : AnimatedSwitcher(
                  duration: AppDuration.fast,
                  transitionBuilder: (child, anim) => ScaleTransition(
                    scale: anim,
                    child: child,
                  ),
                  child: AppIcon(
                    key: ValueKey(isPlaying),
                    icon: isPlaying ? AppIcons.pause : AppIcons.play,
                    size: 22,
                    color: AppColors.background,
                  ),
                ),
        ),
      ),
    );
  }
}
