import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tunify/v2/core/constants/app_colors.dart';
import 'package:tunify/v2/core/constants/app_durations.dart';
import 'package:tunify/v2/core/constants/app_icons.dart';
import 'package:tunify/v2/core/constants/app_spacing.dart';
import 'package:tunify/v2/core/theme/app_text_styles.dart';
import 'package:tunify/v2/core/widgets/art/artwork_or_gradient.dart';
import 'package:tunify/v2/core/widgets/avatar/network_avatar_image.dart';
import 'package:tunify/v2/core/widgets/lists/episode_tile.dart';
import 'package:tunify/v2/core/widgets/lists/track_tile.dart';
import 'package:tunify/v2/features/home/presentation/widgets/home_carousel_shelf.dart';
import 'package:tunify/v2/features/library/data/library_browse_recommendation_carousel_mapper.dart';
import 'package:tunify/v2/features/library/domain/entities/library_browse_recommendation_shelf.dart';
import 'package:tunify/v2/features/library/domain/entities/library_details.dart';
import 'package:tunify/v2/features/auth/presentation/providers/auth_session_provider.dart';
import 'package:tunify/v2/features/library/domain/entities/library_item.dart';
import 'package:tunify/v2/features/library/domain/library_known_creators.dart';
import 'package:tunify/v2/features/library/domain/library_playlist_management_pills.dart';
import 'package:tunify/v2/features/library/presentation/constants/library_details_layout.dart';
import 'package:tunify/v2/features/library/presentation/constants/library_strings.dart';
import 'package:tunify/v2/features/library/presentation/widgets/library_collection_artwork.dart';

part 'library_details_scroll_view.part_header.dart';
part 'library_details_scroll_view.part_hero.dart';
part 'library_details_scroll_view.part_tracks.dart';
part 'library_details_scroll_view.part_recommendations.dart';

/// Scrollable body for [LibraryDetailsScreen] (keeps the screen widget thin).
String _buildStatsLine(LibraryDetailsModel details) {
  final collectionStatInfo = details.collectionStatInfo;
  
  if (collectionStatInfo != null && collectionStatInfo.isNotEmpty) {
    return collectionStatInfo;
  }
  return '';
}

class LibraryDetailsScrollView extends StatelessWidget {
  const LibraryDetailsScrollView({
    super.key,
    required this.details,
    required this.bottomInset,
    required this.scrollController,
    required this.titleMeasureKey,
    required this.actionRowPlaceholderKey,
    required this.appBarUnderlapHeight,
    required this.onRequestTrackOptions,
    this.showInlineBackButton = false,
    this.headerScrollGradientColors = const [],
    this.onSearchTap,
  });

  final LibraryDetailsModel details;
  final double bottomInset;
  final ScrollController scrollController;
  final GlobalKey titleMeasureKey;
  final GlobalKey actionRowPlaceholderKey;
  final double appBarUnderlapHeight;
  final bool showInlineBackButton;
  final VoidCallback? onSearchTap;

  /// When non-empty, painted behind the header column so the palette scrolls with content (v1-style).
  final List<Color> headerScrollGradientColors;

  /// Opens the track row options sheet (long-press / more on the track list).
  final void Function(LibraryDetailsTrack track) onRequestTrackOptions;

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
            onTap: onSearchTap,
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
        const SizedBox(height: AppSpacing.xl),
      if (details.type == LibraryDetailsType.artist)
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            0,
            AppSpacing.lg,
            AppSpacing.lg,
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
            0,
            AppSpacing.lg,
            0,
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
        padding: const EdgeInsets.only(
          left: AppSpacing.lg,
          right: 0,
        ),
        sliver: SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) => _TrackRow(
              details: details,
              track: details.tracks[index],
              onRequestTrackOptions: onRequestTrackOptions,
            ),
            childCount: details.tracks.length,
          ),
        ),
      ),
      if (details.collectionStatInfo != null && details.collectionStatInfo!.isNotEmpty)
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.only(
              left: AppSpacing.lg,
              right: AppSpacing.lg,
              top: AppSpacing.xxxl,
              bottom: AppSpacing.xxxl,
            ),
            child: Center(
              child: Text(
                _buildStatsLine(details),
                style: AppTextStyles.micro.copyWith(
                  color: AppColors.silver,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ),
      if (details.collectionStatInfo == null || details.collectionStatInfo!.isEmpty)
        const SliverToBoxAdapter(
          child: SizedBox(height: AppSpacing.xxxl),
        ),
      if (details.browseRecommendationShelves.isNotEmpty)
        SliverToBoxAdapter(
          child: _BrowseRecommendationShelvesSection(
            shelves: details.browseRecommendationShelves,
          ),
        ),
      if (details.type == LibraryDetailsType.artist &&
          details.collectionDescription != null &&
          details.collectionDescription!.trim().isNotEmpty)
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.xl,
              AppSpacing.lg,
              AppSpacing.xl,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'About',
                  style: AppTextStyles.featureHeading,
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  details.collectionDescription!.trim(),
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.silver,
                    height: 1.35,
                  ),
                ),
              ],
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
