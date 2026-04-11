import 'package:flutter/material.dart';
import 'package:tunify/v2/core/constants/app_border_radius.dart';
import 'package:tunify/v2/core/constants/app_colors.dart';
import 'package:tunify/v2/core/constants/app_spacing.dart';
import 'package:tunify/v2/core/constants/track_slim_card_layout.dart';
import 'package:tunify/v2/core/theme/app_text_styles.dart';
import 'package:tunify/v2/core/widgets/art/mock_art_gradient.dart';

/// Compact horizontal row: artwork, title, optional now-playing / overflow / seek.
class TrackSlimCard extends StatelessWidget {
  const TrackSlimCard({
    super.key,
    required this.title,
    required this.mockThumbArgbColors,
    this.rowHeight,
    this.thumbSize,
    this.showNowPlayingIndicator = false,
    this.showMoreMenu = false,
    this.showSeekBar = false,
    this.seekProgress = 0.35,
  });

  final String title;
  final List<int> mockThumbArgbColors;
  final double? rowHeight;
  final double? thumbSize;
  final bool showNowPlayingIndicator;
  final bool showMoreMenu;
  final bool showSeekBar;
  final double seekProgress;

  @override
  Widget build(BuildContext context) {
    final h = rowHeight ?? TrackSlimCardLayout.defaultRowHeight;
    final thumb = thumbSize ?? TrackSlimCardLayout.defaultThumbSize;
    final gradient = MockArtGradient.linearCover(mockThumbArgbColors);

    return SizedBox(
      height: h,
      width: double.infinity,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppBorderRadius.subtle),
        child: Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            ColoredBox(
              color: AppColors.darkCard,
              child: Row(
                children: [
                  SizedBox(
                    width: thumb,
                    height: thumb,
                    child: DecoratedBox(
                      decoration: BoxDecoration(gradient: gradient),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(right: AppSpacing.md),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.smallBold,
                            ),
                          ),
                          if (showNowPlayingIndicator) ...[
                            const SizedBox(width: AppSpacing.md),
                            Container(
                              width: TrackSlimCardLayout.nowPlayingDotSize,
                              height: TrackSlimCardLayout.nowPlayingDotSize,
                              decoration: const BoxDecoration(
                                color: AppColors.announcementBlue,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ],
                          if (showMoreMenu) ...[
                            const SizedBox(width: AppSpacing.md),
                            const Icon(
                              Icons.more_horiz_rounded,
                              size: AppSpacing.lg,
                              color: AppColors.brandGreen,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (showSeekBar)
              Positioned(
                left: thumb + AppSpacing.md,
                right: AppSpacing.md,
                bottom: AppSpacing.md,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppBorderRadius.minimal),
                  child: SizedBox(
                    height: TrackSlimCardLayout.seekTrackHeight,
                    child: Stack(
                      children: [
                        ColoredBox(
                          color: AppColors.white.withValues(alpha: 0.2),
                        ),
                        FractionallySizedBox(
                          widthFactor: seekProgress.clamp(0.0, 1.0),
                          child: const ColoredBox(color: AppColors.brandGreen),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
