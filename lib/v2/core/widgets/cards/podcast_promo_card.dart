import 'package:flutter/material.dart';
import 'package:tunify/v2/core/constants/app_border_radius.dart';
import 'package:tunify/v2/core/constants/app_colors.dart';
import 'package:tunify/v2/core/constants/app_spacing.dart';
import 'package:tunify/v2/core/constants/podcast_promo_layout.dart';
import 'package:tunify/v2/core/theme/app_text_styles.dart';
import 'package:tunify/v2/core/widgets/art/artwork_or_gradient.dart';
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
    this.onOpenDetail,
    this.mosaicArtworkUrls = const [],
    this.coverWidth,
    this.coverHeight,
    this.showAddToLibraryButton = true,
    this.compactPlaylistStyle = false,
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

  /// Opens the collection detail screen (card tap / primary surface).
  final VoidCallback? onOpenDetail;

  /// When non-empty (typically 4 URLs), shows a 2×2 mosaic instead of a flat placeholder.
  final List<String> mosaicArtworkUrls;

  /// When both set, overrides the default square [PodcastPromoLayout.coverSize] cover.
  final double? coverWidth;
  final double? coverHeight;

  /// When false, the add-to-library control is omitted (e.g. ephemeral home shelves).
  final bool showAddToLibraryButton;

  /// Spotify-style compact playlist promo (folded home track shelf).
  final bool compactPlaylistStyle;

  @override
  Widget build(BuildContext context) {
    if (compactPlaylistStyle) {
      return _buildCompactPlaylistPromo(context);
    }
    return _buildClassicPromo(context);
  }

  Widget _buildCompactPlaylistPromo(BuildContext context) {
    final coverW = coverWidth ?? PodcastPromoLayout.trackShelfCoverSize;
    final coverH = coverHeight ?? PodcastPromoLayout.trackShelfCoverSize;
    final radius = PodcastPromoLayout.compactPlaylistCardCornerRadius;
    final base = Color(backgroundArgb);
    final gradientTop = Color.alphaBlend(
      Colors.white.withValues(alpha: 0.08),
      base,
    );
    final gradientBottom = Color.alphaBlend(
      Colors.black.withValues(alpha: 0.32),
      base,
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.06),
          ),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [gradientTop, gradientBottom],
          ),
        ),
        child: Material(
          color: AppColors.transparent,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: PodcastPromoLayout.compactPlaylistPaddingH,
              vertical: PodcastPromoLayout.compactPlaylistPaddingV,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                InkWell(
                  onTap: onOpenDetail,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(
                          AppBorderRadius.subtle,
                        ),
                        child: SizedBox(
                          width: coverW,
                          height: coverH,
                          child: _PromoCover(
                            mosaicArtworkUrls: mosaicArtworkUrls,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md + AppSpacing.xs),
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Text(
                                    title,
                                    style: AppTextStyles.podcastPromoTitle.copyWith(
                                      letterSpacing:
                                          PodcastPromoLayout
                                              .compactPlaylistTitleLetterSpacing,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                TunifyMoreIconButton(
                                  style: TunifyMoreIconStyle.vertical,
                                  color: AppColors.white.withValues(
                                    alpha: 0.88,
                                  ),
                                  onPressed: onMore,
                                ),
                              ],
                            ),
                            if (showSubtitle.trim().isNotEmpty) ...[
                              const SizedBox(height: AppSpacing.sm),
                              Text(
                                showSubtitle,
                                style: AppTextStyles.caption.copyWith(
                                  color: AppColors.white.withValues(
                                    alpha: 0.72,
                                  ),
                                  height: 1.2,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  height: PodcastPromoLayout.compactPlaylistTitleToActionsGap,
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    ListenNowPillButton(
                      label: listenNowLabel,
                      onPressed: onListenNow,
                      dense: true,
                    ),
                    const Spacer(),
                    if (showAddToLibraryButton) ...[
                      TunifyAddToLibraryIconButton(
                        onPressed: onAddToLibrary,
                        iconColor: AppColors.white.withValues(alpha: 0.92),
                      ),
                      const SizedBox(width: AppSpacing.md),
                    ],
                    TunifyPlayCircleButton(
                      diameter: PodcastPromoLayout.compactPlaylistPlayOuter,
                      iconSize: PodcastPromoLayout.compactPlaylistPlayInner,
                      onPressed: onPlay,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildClassicPromo(BuildContext context) {
    final coverW = coverWidth ?? PodcastPromoLayout.coverSize;
    final coverH = coverHeight ?? PodcastPromoLayout.coverSize;
    return ClipRRect(
      borderRadius: BorderRadius.circular(PodcastPromoLayout.cardCornerRadius),
      child: ColoredBox(
        color: Color(backgroundArgb),
        child: Material(
          color: AppColors.transparent,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: PodcastPromoLayout.verticalPadding,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                InkWell(
                  onTap: onOpenDetail,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.lg),
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
                                width: coverW,
                                height: coverH,
                                child: _PromoCover(
                                  mosaicArtworkUrls: mosaicArtworkUrls,
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
                                            height: PodcastPromoLayout
                                                .titleLineHeightRatio,
                                            letterSpacing: PodcastPromoLayout
                                                .titleLetterSpacing,
                                          ),
                                          maxLines: 3,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      TunifyMoreIconButton(
                                        style: TunifyMoreIconStyle.vertical,
                                        color: AppColors.white.withValues(
                                          alpha: 0.95,
                                        ),
                                        onPressed: onMore,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: AppSpacing.sm),
                                  Text(
                                    showSubtitle,
                                    style: AppTextStyles.small.copyWith(
                                      color: AppColors.white.withValues(
                                        alpha: 0.6,
                                      ),
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
                          style: AppTextStyles.small.copyWith(
                            color: AppColors.white,
                          ),
                          maxLines: 5,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(
                  height: PodcastPromoLayout.descriptionToActionsGap -
                      AppSpacing.lg,
                ),
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
                        if (showAddToLibraryButton) ...[
                          TunifyAddToLibraryIconButton(
                            onPressed: onAddToLibrary,
                            iconColor: AppColors.white.withValues(alpha: 0.95),
                          ),
                          const SizedBox(width: AppSpacing.lg),
                        ],
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
  }
}

class _PromoCover extends StatelessWidget {
  const _PromoCover({required this.mosaicArtworkUrls});

  final List<String> mosaicArtworkUrls;

  @override
  Widget build(BuildContext context) {
    final urls = mosaicArtworkUrls.where((u) => u.trim().isNotEmpty).take(4).toList();
    if (urls.isEmpty) {
      return const ColoredBox(color: AppColors.darkSurface);
    }
    if (urls.length == 1) {
      return ArtworkOrGradient(imageUrl: urls.first);
    }
    final padded = List<String>.from(urls);
    while (padded.length < 4) {
      padded.add('');
    }
    return ColoredBox(
      color: AppColors.darkSurface,
      child: Column(
        children: [
          Expanded(
            child: Row(
              children: [
                Expanded(child: _mosaicCell(padded[0])),
                Expanded(child: _mosaicCell(padded[1])),
              ],
            ),
          ),
          Expanded(
            child: Row(
              children: [
                Expanded(child: _mosaicCell(padded[2])),
                Expanded(child: _mosaicCell(padded[3])),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _mosaicCell(String url) {
    final t = url.trim();
    if (t.isEmpty) {
      return const ColoredBox(color: AppColors.midDark);
    }
    return ArtworkOrGradient(imageUrl: t, fit: BoxFit.cover);
  }
}
