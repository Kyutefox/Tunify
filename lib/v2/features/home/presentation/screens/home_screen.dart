import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tunify/v2/core/constants/app_spacing.dart';
import 'package:tunify/v2/core/constants/app_strings.dart';
import 'package:tunify/v2/core/theme/app_text_styles.dart';
import 'package:tunify/v2/features/home/domain/entities/home_block.dart';
import 'package:tunify/v2/features/home/domain/entities/home_feed.dart';
import 'package:tunify/v2/features/home/presentation/constants/home_layout.dart';
import 'package:tunify/v2/features/home/presentation/providers/home_providers.dart';
import 'package:tunify/v2/features/home/presentation/widgets/home_carousel_shelf.dart';
import 'package:tunify/v2/features/home/presentation/widgets/home_hero_recommended.dart';
import 'package:tunify/v2/features/home/presentation/widgets/home_podcast_promo.dart';
import 'package:tunify/v2/features/home/presentation/widgets/home_quick_picks_shelf.dart';
import 'package:tunify/v2/features/home/presentation/widgets/home_slim_grid.dart';
import 'package:tunify/v2/features/home/presentation/widgets/home_top_header.dart';
import 'package:tunify/v2/features/loading/presentation/screens/loading_screen.dart';

/// Home scroll + pinned header. Presentation only (RULES.md: Riverpod, no business logic).
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref.watch(homeFeedProvider).when(
          data: _HomeFeedLoadedBody.new,
          loading: () => const _HomeFeedLoadingView(),
          error: (_, __) => const _HomeFeedErrorView(),
        );
  }
}

class _HomeFeedLoadedBody extends StatelessWidget {
  const _HomeFeedLoadedBody(this.feed);

  final HomeFeed feed;

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final bottomPad = mq.padding.bottom + AppSpacing.xxl;
    final topInset = HomeLayout.scrollContentTopOffset(mq);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        CustomScrollView(
          slivers: [
            SliverPadding(
              padding: EdgeInsets.only(top: topInset, bottom: bottomPad),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final block = feed.blocks[index];
                    final top = _homeFeedBlockLeadingTop(index, block);
                    return Padding(
                      padding: EdgeInsets.only(top: top),
                      child: _HomeBlockView(block: block),
                    );
                  },
                  childCount: feed.blocks.length,
                  addAutomaticKeepAlives: false,
                  addRepaintBoundaries: true,
                ),
              ),
            ),
          ],
        ),
        const Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: HomeTopHeader(),
        ),
      ],
    );
  }
}

class _HomeFeedLoadingView extends StatelessWidget {
  const _HomeFeedLoadingView();

  @override
  Widget build(BuildContext context) {
    return const LoadingScreen(embedInParentScaffold: true);
  }
}

class _HomeFeedErrorView extends StatelessWidget {
  const _HomeFeedErrorView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Text(
          AppStrings.homeFeedLoadError,
          style: AppTextStyles.body,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

/// Leading inset applied by [SliverList] above each block so every boundary is
/// `shelfTrailingAfterContent` + `shelfLeadingBeforeTitle` (e.g. Quick picks bottom + this top).
double _homeFeedBlockLeadingTop(int index, HomeBlock block) {
  if (index > 0) {
    return HomeLayout.shelfLeadingBeforeTitle;
  }
  if (block is HomeCarouselBlock ||
      block is HomeHeroRecommendedBlock ||
      block is HomePodcastPromoBlock) {
    return HomeLayout.shelfLeadingBeforeTitle;
  }
  return 0;
}

class _HomeBlockView extends StatelessWidget {
  const _HomeBlockView({required this.block});

  final HomeBlock block;

  @override
  Widget build(BuildContext context) {
    return switch (block) {
      final HomeQuickPicksBlock qp => HomeQuickPicksShelf(data: qp),
      HomeSlimGridBlock(:final tiles) => HomeSlimGrid(tiles: tiles),
      HomeHeroRecommendedBlock(:final hero) =>
        HomeHeroRecommendedView(data: hero),
      HomeCarouselBlock(:final section) => HomeCarouselShelf(section: section),
      HomePodcastPromoBlock(:final promo) => HomePodcastPromoView(data: promo),
    };
  }
}
