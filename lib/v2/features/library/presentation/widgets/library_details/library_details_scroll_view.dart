import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:tunify/v2/core/constants/app_colors.dart';
import 'package:tunify/v2/core/constants/app_icons.dart';
import 'package:tunify/v2/core/constants/app_spacing.dart';
import 'package:tunify/v2/core/theme/app_text_styles.dart';
import 'package:tunify/v2/core/widgets/art/artwork_or_gradient.dart';
import 'package:tunify/v2/features/home/presentation/widgets/home_carousel_shelf.dart';
import 'package:tunify/v2/features/library/data/library_browse_recommendation_carousel_mapper.dart';
import 'package:tunify/v2/features/library/domain/entities/library_browse_recommendation_shelf.dart';
import 'package:tunify/v2/features/library/domain/entities/library_details.dart';
import 'package:tunify/v2/features/library/domain/entities/library_item.dart';
import 'package:tunify/v2/features/library/domain/library_playlist_management_pills.dart';
import 'package:tunify/v2/features/library/presentation/constants/library_details_layout.dart';
import 'package:tunify/v2/features/library/presentation/constants/library_strings.dart';
import 'package:tunify/v2/features/library/presentation/widgets/library_details/library_detail_mini_cover.dart';
import 'package:tunify/v2/features/library/presentation/widgets/system_artwork.dart';

part 'library_details_scroll_view.part_header.dart';
part 'library_details_scroll_view.part_hero.dart';
part 'library_details_scroll_view.part_tracks.dart';
part 'library_details_scroll_view.part_recommendations.dart';

/// Scrollable body for [LibraryDetailsScreen] (keeps the screen widget thin).
class LibraryDetailsScrollView extends StatelessWidget {
  const LibraryDetailsScrollView({
    super.key,
    required this.details,
    required this.bottomInset,
    required this.scrollController,
    required this.titleMeasureKey,
    required this.actionRowPlaceholderKey,
    required this.appBarUnderlapHeight,
    this.showInlineBackButton = false,
    this.headerScrollGradientColors = const [],
  });

  final LibraryDetailsModel details;
  final double bottomInset;
  final ScrollController scrollController;
  final GlobalKey titleMeasureKey;
  final GlobalKey actionRowPlaceholderKey;
  final double appBarUnderlapHeight;
  final bool showInlineBackButton;

  /// When non-empty, painted behind the header column so the palette scrolls with content (v1-style).
  final List<Color> headerScrollGradientColors;

  List<Widget> _headerColumnChildren() {
    return [
      if (showInlineBackButton) _BackHeader(),
      if (appBarUnderlapHeight > 0 && details.type != LibraryDetailsType.artist)
        SizedBox(height: appBarUnderlapHeight),
      if (details.searchHint.isNotEmpty) ...[
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: _SearchBar(
            hint: details.searchHint,
            showSortButton: details.showSortButton,
          ),
        ),
        SizedBox(
          height: details.isStaticPlaylist
              ? LibraryDetailsLayout.staticSearchToTitleGap
              : LibraryDetailsLayout.defaultSearchToHeroGap,
        ),
      ] else if (details.isStaticPlaylist)
        SizedBox(
          height: LibraryDetailsLayout.staticSearchToTitleGap,
        )
      else if (details.type != LibraryDetailsType.artist)
        SizedBox(
          height: LibraryDetailsLayout.defaultSearchToHeroGap,
        ),
      _HeroSection(
        details: details,
        titleMeasureKey: titleMeasureKey,
        appBarUnderlapHeight: appBarUnderlapHeight,
      ),
      Padding(
        padding: const EdgeInsets.only(top: AppSpacing.md),
        child: SizedBox(
          key: actionRowPlaceholderKey,
          height: LibraryDetailsLayout.collectionDockedActionRowHeight,
        ),
      ),
      if (details.chips.isNotEmpty)
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.md,
            AppSpacing.lg,
            AppSpacing.md,
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: details.chips
                  .map(
                    (label) => Padding(
                      padding: const EdgeInsets.only(right: AppSpacing.md),
                      child: _ChipPill(label: label),
                    ),
                  )
                  .toList(growable: false),
            ),
          ),
        )
      else if (details.type != LibraryDetailsType.artist)
        const SizedBox(
          height: LibraryDetailsLayout.headerToTrackListWhenNoChipsGap,
        ),
      if (details.artistTabs.isNotEmpty)
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.md,
            AppSpacing.lg,
            0,
          ),
          child: Row(
            children: details.artistTabs
                .map(
                  (tab) => Padding(
                    padding: const EdgeInsets.only(right: AppSpacing.xl),
                    child: Text(
                      tab,
                      style: AppTextStyles.body.copyWith(
                        color: tab == details.artistTabs.first
                            ? AppColors.white
                            : AppColors.silver,
                        fontWeight: tab == details.artistTabs.first
                            ? FontWeight.w700
                            : FontWeight.w400,
                      ),
                    ),
                  ),
                )
                .toList(growable: false),
          ),
        ),
      if (details.type == LibraryDetailsType.artist &&
          details.artistTabs.isNotEmpty)
        const SizedBox(height: AppSpacing.xxxl),
      if (details.type == LibraryDetailsType.artist)
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            0,
            AppSpacing.lg,
            AppSpacing.xxl,
          ),
          child: Text(
            LibraryStrings.popular,
            style: AppTextStyles.featureHeading,
          ),
        ),
      if (details.showAddRow)
        const Padding(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.md,
            AppSpacing.lg,
            AppSpacing.md,
          ),
          child: _AddToPlaylistRow(),
        ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final useScrollGradient = headerScrollGradientColors.isNotEmpty;

    final tailSlivers = <Widget>[
      SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        sliver: SliverList.separated(
          itemCount: details.tracks.length,
          separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
          itemBuilder: (context, index) => _TrackRow(
            track: details.tracks[index],
            item: details.item,
          ),
        ),
      ),
      if (details.browseRecommendationShelves.isNotEmpty)
        SliverToBoxAdapter(
          child: _BrowseRecommendationShelvesSection(
            shelves: details.browseRecommendationShelves,
          ),
        ),
      if (details.statsLine.isNotEmpty)
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.xxxl,
            ),
            child: Center(
              child: Text(
                details.statsLine,
                style: AppTextStyles.micro.copyWith(
                  color: AppColors.silver,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ),
      SliverToBoxAdapter(
        child: SizedBox(
          height: bottomInset + LibraryDetailsLayout.scrollBottomExtraPadding,
        ),
      ),
    ];

    if (useScrollGradient) {
      return CustomScrollView(
        controller: scrollController,
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  left: 0,
                  right: 0,
                  top: -appBarUnderlapHeight,
                  bottom: 0,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: headerScrollGradientColors,
                      ),
                    ),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: _headerColumnChildren(),
                ),
              ],
            ),
          ),
          ...tailSlivers,
        ],
      );
    }

    return CustomScrollView(
      controller: scrollController,
      physics: const BouncingScrollPhysics(),
      slivers: [
        ..._headerColumnChildren().map((w) => SliverToBoxAdapter(child: w)),
        ...tailSlivers,
      ],
    );
  }
}
