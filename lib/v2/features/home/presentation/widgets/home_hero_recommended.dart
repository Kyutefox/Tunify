import 'package:flutter/material.dart';
import 'package:tunify/v2/core/constants/app_spacing.dart';
import 'package:tunify/v2/core/widgets/cards/album_promo_row_card.dart';
import 'package:tunify/v2/core/widgets/cards/section_intro_with_avatar.dart';
import 'package:tunify/v2/features/home/domain/entities/home_block.dart';
import 'package:tunify/v2/features/home/presentation/constants/home_layout.dart';

/// Home “continue listening” block — composes shared [SectionIntroWithAvatar] + [AlbumPromoRowCard].
class HomeHeroRecommendedView extends StatelessWidget {
  const HomeHeroRecommendedView({
    super.key,
    required this.data,
  });

  final HomeHeroRecommended data;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.xl,
        AppSpacing.lg,
        AppSpacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionIntroWithAvatar(
            avatarDiameter: HomeLayout.heroAvatarDiameter,
            sectionLabel: data.sectionLabel,
            sectionTitle: data.sectionTitle,
            mockAvatarArgbColors: data.avatarColors,
          ),
          const SizedBox(height: AppSpacing.lg),
          AlbumPromoRowCard(
            title: data.cardTitle,
            subtitle: data.cardSubtitle,
            mockSquareArtArgbColors: data.squareArtColors,
          ),
        ],
      ),
    );
  }
}
