import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tunify/v2/core/constants/app_border_radius.dart';
import 'package:tunify/v2/core/constants/app_colors.dart';
import 'package:tunify/v2/core/constants/app_spacing.dart';
import 'package:tunify/v2/core/theme/app_text_styles.dart';
import 'package:tunify/v2/core/widgets/cards/search_category_card.dart';
import 'package:tunify/v2/core/widgets/cards/search_explore_card.dart';
import 'package:tunify/v2/core/widgets/navigation/app_top_navigation.dart';
import 'package:tunify/v2/core/widgets/navigation/user_menu_launcher.dart';

/// Spotify-style search full view for Tunify v2.
class SearchScreen extends ConsumerWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final safeArea = MediaQuery.paddingOf(context);
    final bottomInset = safeArea.bottom + SearchLayout.bottomContentPadding;

    return Scaffold(
      backgroundColor: AppColors.nearBlack,
      body: CustomScrollView(
        slivers: [
          SliverPersistentHeader(
            pinned: true,
            delegate: _SearchHeaderDelegate(
              statusBarHeight: safeArea.top,
              onAvatarTap: () => launchUserMenu(context),
            ),
          ),
          const SliverToBoxAdapter(
            child: SizedBox(height: SearchLayout.searchToBrowseGap),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(
              horizontal: SearchLayout.horizontalPadding,
            ),
            sliver: SliverToBoxAdapter(
              child: Text(
                'Explore your musical type',
                style: AppTextStyles.featureHeading,
              ),
            ),
          ),
          const SliverToBoxAdapter(
            child: SizedBox(height: SearchLayout.exploreTitleToRailGap),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(
              horizontal: SearchLayout.horizontalPadding,
            ),
            sliver: SliverToBoxAdapter(
              child: SizedBox(
                height: SearchLayout.exploreRailHeight,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemBuilder: (context, index) => SearchExploreCard(
                    title: _exploreTiles[index].title,
                    backgroundColor: _exploreTiles[index].color,
                    width: SearchLayout.exploreTileWidth,
                    padding: SearchLayout.exploreTilePadding,
                    titleFontSize: SearchLayout.exploreCardTitleFontSize,
                  ),
                  separatorBuilder: (_, __) =>
                      const SizedBox(width: SearchLayout.exploreRailSpacing),
                  itemCount: _exploreTiles.length,
                ),
              ),
            ),
          ),
          const SliverToBoxAdapter(
            child: SizedBox(height: SearchLayout.exploreToBrowseTitleGap),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(
              horizontal: SearchLayout.horizontalPadding,
            ),
            sliver: SliverToBoxAdapter(
              child: Text('Browse all', style: AppTextStyles.featureHeading),
            ),
          ),
          const SliverToBoxAdapter(
            child: SizedBox(height: SearchLayout.browseTitleToGridGap),
          ),
          SliverPadding(
            padding: EdgeInsets.fromLTRB(
              SearchLayout.horizontalPadding,
              0,
              SearchLayout.horizontalPadding,
              bottomInset,
            ),
            sliver: SliverGrid(
              delegate: SliverChildBuilderDelegate(
                (context, index) => SearchCategoryCard(
                  title: _browseTiles[index].title,
                  backgroundColor: _browseTiles[index].color,
                  padding: SearchLayout.cardInnerPadding,
                  titleFontSize: SearchLayout.browseCardTitleFontSize,
                ),
                childCount: _browseTiles.length,
              ),
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: SearchLayout.tileMaxWidth,
                mainAxisSpacing: SearchLayout.gridSpacing,
                crossAxisSpacing: SearchLayout.gridSpacing,
                mainAxisExtent: SearchLayout.tileHeight,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TopActionButton extends StatelessWidget {
  const _TopActionButton({
    required this.icon,
    required this.onTap,
  });

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Container(
        width: SearchLayout.topActionSize,
        height: SearchLayout.topActionSize,
        decoration: const BoxDecoration(
          color: AppColors.midDark,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: AppColors.white,
          size: SearchLayout.topActionIconSize,
        ),
      ),
    );
  }
}

class _SearchInput extends StatelessWidget {
  const _SearchInput();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: SearchLayout.searchInputHeight,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppBorderRadius.comfortable),
      ),
      padding: const EdgeInsets.symmetric(horizontal: SearchLayout.searchInputHorizontalPadding),
      child: Row(
        children: [
          const Icon(
            Icons.search_rounded,
            color: AppColors.nearBlack,
            size: SearchLayout.searchIconSize,
          ),
          const SizedBox(width: AppSpacing.md),
          Text(
            'What do you want to play?',
            style: AppTextStyles.caption.copyWith(
              color: AppColors.nearBlack,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

const List<_ExploreTileData> _exploreTiles = <_ExploreTileData>[
  _ExploreTileData('#permanent wave', Color(0xFF2E1E15)),
  _ExploreTileData('#madchester', Color(0xFF5A3A23)),
  _ExploreTileData('#dance rock', Color(0xFF1D1E2A)),
];

class _ExploreTileData {
  const _ExploreTileData(this.title, this.color);

  final String title;
  final Color color;
}

const List<_BrowseTileData> _browseTiles = <_BrowseTileData>[
  _BrowseTileData('Music', Color(0xFFD82A95)),
  _BrowseTileData('Podcasts', Color(0xFF5C2B7F)),
  _BrowseTileData('Live Events', Color(0xFFBA5D07)),
  _BrowseTileData('Made for you', Color(0xFF1E3264)),
  _BrowseTileData('New releases', Color(0xFFE13300)),
  _BrowseTileData('Hindi', Color(0xFF777777)),
  _BrowseTileData('Punjabi', Color(0xFF477D95)),
  _BrowseTileData('Pop', Color(0xFF8D67AB)),
  _BrowseTileData('Hip-Hop', Color(0xFFA56752)),
];

class _BrowseTileData {
  const _BrowseTileData(this.title, this.color);

  final String title;
  final Color color;
}

/// Combined header: navigation row (collapses on scroll) + sticky search input.
///
/// `maxExtent` = status bar + nav row + search bar (fully expanded).
/// `minExtent` = status bar + search bar only (pinned, nav row scrolled away).
/// As the user scrolls, the nav row fades/slides out and the search bar
/// remains anchored below the status bar.
class _SearchHeaderDelegate extends SliverPersistentHeaderDelegate {
  _SearchHeaderDelegate({
    required this.statusBarHeight,
    required this.onAvatarTap,
  });

  final double statusBarHeight;
  final VoidCallback onAvatarTap;

  /// Reuse the single source of truth from [AppTopNavigation].
  double get _navRowHeight => AppTopNavigation.contentHeight;

  double get _searchHeight => SearchLayout.stickySearchHeaderHeight;

  @override
  double get maxExtent => statusBarHeight + _navRowHeight + _searchHeight;

  @override
  double get minExtent => statusBarHeight + _searchHeight;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final collapseProgress =
        (shrinkOffset / _navRowHeight).clamp(0.0, 1.0);

    return ClipRect(
      child: ColoredBox(
        color: AppColors.nearBlack,
        child: Stack(
          children: [
            // Nav row: translates upward with scroll, clipped as it exits.
            Positioned(
              top: -shrinkOffset,
              left: 0,
              right: 0,
              child: Opacity(
                opacity: 1.0 - collapseProgress,
                child: AppTopNavigation(
                  leadingOnTap: onAvatarTap,
                  middle: Text(
                    'Search',
                    style: AppTextStyles.sectionTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: _TopActionButton(
                    icon: Icons.camera_alt_outlined,
                    onTap: () {},
                  ),
                ),
              ),
            ),
            // Search input: always anchored at the bottom of the header.
            Positioned(
              left: SearchLayout.horizontalPadding,
              right: SearchLayout.horizontalPadding,
              bottom: SearchLayout.stickySearchBottomPadding,
              child: const _SearchInput(),
            ),
          ],
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _SearchHeaderDelegate oldDelegate) =>
      statusBarHeight != oldDelegate.statusBarHeight ||
      onAvatarTap != oldDelegate.onAvatarTap;
}

/// Search screen layout tokens (feature-scoped, no ad-hoc literals in widgets).
abstract final class SearchLayout {
  static const double horizontalPadding = AppSpacing.lg;
  static const double topContentPadding = AppSpacing.md;
  static const double bottomContentPadding = AppSpacing.xl;
  static const double stickySearchTopPadding = AppSpacing.md + AppSpacing.sm;
  static const double stickySearchBottomPadding = AppSpacing.md;
  static const double stickySearchHeaderHeight =
      stickySearchTopPadding + searchInputHeight + stickySearchBottomPadding;

  static const double searchToBrowseGap = AppSpacing.lg + AppSpacing.xs;
  static const double exploreTitleToRailGap = AppSpacing.md + AppSpacing.sm;
  static const double exploreToBrowseTitleGap =
      AppSpacing.lg + AppSpacing.md - AppSpacing.xs;
  static const double browseTitleToGridGap = AppSpacing.md + AppSpacing.sm;

  static const double searchInputHeight = 52;
  static const double searchInputHorizontalPadding = AppSpacing.lg;
  static const double searchIconSize = 24;
  static const double topActionSize = 36;
  static const double topActionIconSize = 20;

  static const double gridSpacing = AppSpacing.md;
  static const double tileHeight = 104;
  static const double tileMaxWidth = 220;
  static const double exploreRailHeight = 160;
  static const double exploreTileWidth = 132;
  static const double exploreRailSpacing = AppSpacing.md;
  static const double exploreTilePadding = AppSpacing.lg - AppSpacing.sm;
  static const double browseCardTitleFontSize = 18;
  static const double exploreCardTitleFontSize = 14;
  static const double cardInnerPadding = AppSpacing.lg;
}
