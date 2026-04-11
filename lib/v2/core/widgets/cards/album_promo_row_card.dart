import 'package:flutter/material.dart';
import 'package:tunify/v2/core/constants/album_promo_row_layout.dart';
import 'package:tunify/v2/core/constants/app_border_radius.dart';
import 'package:tunify/v2/core/constants/app_colors.dart';
import 'package:tunify/v2/core/constants/app_spacing.dart';
import 'package:tunify/v2/core/theme/app_text_styles.dart';
import 'package:tunify/v2/core/widgets/art/mock_art_gradient.dart';
import 'package:tunify/v2/core/widgets/buttons/tunify_add_to_library_icon_button.dart';
import 'package:tunify/v2/core/widgets/buttons/tunify_play_circle_button.dart';

/// Wide dark card: square art, title stack, add + play row actions.
class AlbumPromoRowCard extends StatelessWidget {
  const AlbumPromoRowCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.mockSquareArtArgbColors,
    this.artSize = AlbumPromoRowLayout.artSize,
    this.onAddPressed,
    this.onPlayPressed,
  });

  final String title;
  final String subtitle;
  final List<int> mockSquareArtArgbColors;
  final double artSize;
  final VoidCallback? onAddPressed;
  final VoidCallback? onPlayPressed;

  @override
  Widget build(BuildContext context) {
    final gradient = MockArtGradient.linearCover(mockSquareArtArgbColors);

    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = constraints.maxWidth;
        return ClipRRect(
          borderRadius: BorderRadius.circular(AppBorderRadius.comfortable),
          child: ColoredBox(
            color: AppColors.darkCard,
            child: SizedBox(
              width: cardWidth,
              height: artSize,
              child: Row(
                children: [
                  SizedBox(
                    width: artSize,
                    height: artSize,
                    child: DecoratedBox(
                      decoration: BoxDecoration(gradient: gradient),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.lg),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        0,
                        AppSpacing.lg,
                        AppSpacing.lg,
                        AppSpacing.lg,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(title, style: AppTextStyles.smallBold),
                              Text(
                                subtitle,
                                style: AppTextStyles.small.copyWith(
                                  color: AppColors.nearWhite,
                                ),
                              ),
                            ],
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              TunifyAddToLibraryIconButton(onPressed: onAddPressed),
                              TunifyPlayCircleButton(
                                diameter: AppSpacing.xxl,
                                iconSize: AlbumPromoRowLayout.miniPlayGlyphSize,
                                onPressed: onPlayPressed,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
