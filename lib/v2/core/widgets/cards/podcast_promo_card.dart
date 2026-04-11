import 'package:flutter/material.dart';
import 'package:tunify/v2/core/constants/app_border_radius.dart';
import 'package:tunify/v2/core/constants/app_colors.dart';
import 'package:tunify/v2/core/constants/app_spacing.dart';
import 'package:tunify/v2/core/constants/podcast_promo_layout.dart';
import 'package:tunify/v2/core/theme/app_text_styles.dart';
import 'package:tunify/v2/core/widgets/art/mock_art_gradient.dart';
import 'package:tunify/v2/core/widgets/buttons/listen_now_pill_button.dart';
import 'package:tunify/v2/core/widgets/buttons/tunify_add_to_library_icon_button.dart';
import 'package:tunify/v2/core/widgets/buttons/tunify_more_icon_button.dart';
import 'package:tunify/v2/core/widgets/buttons/tunify_play_circle_button.dart';

/// Large show + episode promo (cover, copy, listen / add / play).
class PodcastPromoCard extends StatelessWidget {
  const PodcastPromoCard({
    super.key,
    required this.title,
    required this.showSubtitle,
    required this.episodeDescription,
    required this.mockCoverArgbColors,
    required this.backgroundArgb,
    this.listenNowLabel = 'Listen now',
    this.onListenNow,
    this.onPlay,
    this.onAddToLibrary,
    this.onMore,
  });

  final String title;
  final String showSubtitle;
  final String episodeDescription;
  final List<int> mockCoverArgbColors;
  final int backgroundArgb;
  final String listenNowLabel;
  final VoidCallback? onListenNow;
  final VoidCallback? onPlay;
  final VoidCallback? onAddToLibrary;
  final VoidCallback? onMore;

  @override
  Widget build(BuildContext context) {
    final gradient = MockArtGradient.linearCover(mockCoverArgbColors);

    return LayoutBuilder(
      builder: (context, constraints) {
        final innerWidth = constraints.maxWidth;
        return ClipRRect(
          borderRadius: BorderRadius.circular(PodcastPromoLayout.cardCornerRadius),
          child: ColoredBox(
            color: Color(backgroundArgb),
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.md + AppSpacing.sm + AppSpacing.xs,
                AppSpacing.lg,
                AppSpacing.md + AppSpacing.sm + AppSpacing.xs,
              ),
              child: SizedBox(
                width: innerWidth,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(
                            AppBorderRadius.standard,
                          ),
                          child: SizedBox(
                            width: PodcastPromoLayout.coverSize,
                            height: PodcastPromoLayout.coverSize,
                            child: DecoratedBox(
                              decoration: BoxDecoration(gradient: gradient),
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Text(
                                      title,
                                      style: AppTextStyles.sectionTitle.copyWith(
                                        height: 26 / 24,
                                        letterSpacing: -0.55,
                                      ),
                                      maxLines: 3,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  TunifyMoreIconButton(
                                    style: TunifyMoreIconStyle.vertical,
                                    color: AppColors.white.withValues(alpha: 0.95),
                                    onPressed: onMore,
                                  ),
                                ],
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              Text(
                                showSubtitle,
                                style: AppTextStyles.small.copyWith(
                                  color: AppColors.white.withValues(alpha: 0.6),
                                ),
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      episodeDescription,
                      style: AppTextStyles.small.copyWith(color: AppColors.white),
                      maxLines: 5,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppSpacing.lg + AppSpacing.sm - AppSpacing.xs),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        ListenNowPillButton(
                          label: listenNowLabel,
                          onPressed: onListenNow,
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            TunifyAddToLibraryIconButton(
                              onPressed: onAddToLibrary,
                              iconColor: AppColors.white.withValues(alpha: 0.95),
                            ),
                            const SizedBox(width: AppSpacing.lg),
                            TunifyPlayCircleButton(
                              diameter: PodcastPromoLayout.playButtonOuter,
                              iconSize: PodcastPromoLayout.playButtonInner,
                              onPressed: onPlay,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
