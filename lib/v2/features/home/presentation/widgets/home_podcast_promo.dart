import 'package:flutter/material.dart';
import 'package:tunify/v2/core/constants/app_spacing.dart';
import 'package:tunify/v2/core/widgets/cards/podcast_promo_card.dart';
import 'package:tunify/v2/features/home/domain/entities/home_block.dart';
import 'package:tunify/v2/features/home/presentation/constants/home_layout.dart';

/// Home feed wrapper for the shared [PodcastPromoCard].
class HomePodcastPromoView extends StatelessWidget {
  const HomePodcastPromoView({
    super.key,
    required this.data,
  });

  final HomePodcastPromo data;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        HomeLayout.shelfTrailingAfterContent,
      ),
      child: PodcastPromoCard(
        title: data.title,
        showSubtitle: data.showSubtitle,
        episodeDescription: data.episodeDescription,
        mockCoverArgbColors: data.coverColors,
        backgroundArgb: data.backgroundColor,
      ),
    );
  }
}
