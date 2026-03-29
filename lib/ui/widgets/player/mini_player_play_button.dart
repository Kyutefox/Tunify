import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:tunify/core/constants/app_icons.dart';
import 'package:tunify/ui/theme/design_tokens.dart';
import 'package:tunify/ui/theme/app_colors_scheme.dart';

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
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: AppColorsScheme.of(context).textPrimary,
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
                      AppColorsScheme.of(context).background,
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
                    color: AppColorsScheme.of(context).background,
                  ),
                ),
        ),
      ),
    );
  }
}
