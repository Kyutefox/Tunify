import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tunify/v2/core/constants/app_border_radius.dart';
import 'package:tunify/v2/core/constants/app_colors.dart';
import 'package:tunify/v2/core/constants/app_icons.dart';
import 'package:tunify/v2/core/constants/app_spacing.dart';
import 'package:tunify/v2/core/theme/app_text_styles.dart';
import 'package:tunify/v2/core/widgets/cards/search_category_card.dart';
import 'package:tunify/v2/core/widgets/cards/search_explore_card.dart';
import 'package:tunify/v2/core/widgets/navigation/app_top_navigation.dart';
import 'package:tunify/v2/core/widgets/navigation/user_menu_launcher.dart';
import 'package:tunify/v2/features/search/domain/entities/search_models.dart';
import 'package:tunify/v2/features/search/presentation/constants/search_discovery_tiles.dart';
import 'package:tunify/v2/features/search/presentation/constants/search_mood_tile_colors.dart';
import 'package:tunify/v2/features/search/presentation/providers/search_providers.dart';
import 'package:tunify/v2/features/search/presentation/providers/moods_providers.dart';
import 'package:tunify/v2/features/search/presentation/widgets/search_focus_bodies.dart';
import 'package:tunify/v2/features/search/presentation/widgets/search_filter_chips_row.dart';
import 'package:tunify/v2/features/search/presentation/widgets/search_focus_header.dart';

class SearchScreen extends ConsumerWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final moodsAsync = ref.watch(moodsAndGenresProvider);
    final safeArea = MediaQuery.paddingOf(context);
    final bottomInset = safeArea.bottom + AppSpacing.xxl;

    return Scaffold(
      backgroundColor: AppColors.nearBlack,
      body: CustomScrollView(
        slivers: [
          SliverPersistentHeader(
            pinned: true,
            delegate: _SearchHeaderDelegate(
              statusBarHeight: safeArea.top,
              onAvatarTap: () => launchUserMenu(context),
              onSearchTap: () {
                ref.read(searchControllerProvider.notifier).clearQuery();
                ref.read(searchRecentItemsProvider.notifier).clear();
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const SearchFocusScreen(),
                    fullscreenDialog: true,
                  ),
                );
              },
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.lg)),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            sliver: SliverToBoxAdapter(
              child: Text(
                'Explore your musical type',
                style: AppTextStyles.featureHeading,
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.lg)),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            sliver: SliverToBoxAdapter(
              child: SizedBox(
                height: 160,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: searchExploreTiles.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(width: AppSpacing.md),
                  itemBuilder: (context, index) {
                    final tile = searchExploreTiles[index];
                    return SearchExploreCard(
                      title: tile.$1,
                      backgroundColor: tile.$2,
                      width: 132,
                      padding: AppSpacing.lg - AppSpacing.sm,
                      titleFontSize: AppSpacing.searchExploreCardTitleFontSize,
                    );
                  },
                ),
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xl)),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            sliver: SliverToBoxAdapter(
              child: Text('Browse all', style: AppTextStyles.featureHeading),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.lg)),
          SliverPadding(
            padding: EdgeInsets.fromLTRB(
                AppSpacing.lg, 0, AppSpacing.lg, bottomInset),
            sliver: moodsAsync.when(
              data: (moods) {
                final colorSeed = moods.fold<int>(
                  0,
                  (acc, mood) =>
                      acc ^ mood.browseId.hashCode ^ mood.title.hashCode,
                );
                final moodTileColors = buildRandomizedMoodTileColors(
                  moods.length,
                  seed: colorSeed,
                );
                return SliverGrid(
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 220,
                    mainAxisSpacing: AppSpacing.md,
                    crossAxisSpacing: AppSpacing.md,
                    mainAxisExtent: 104,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final mood = moods[index];
                      return SearchCategoryCard(
                        title: mood.title,
                        backgroundColor: moodTileColors[index],
                        padding: AppSpacing.lg,
                        titleFontSize: AppSpacing.searchCategoryCardTitleFontSize,
                      );
                    },
                    childCount: moods.length,
                  ),
                );
              },
              loading: () => const SliverToBoxAdapter(
                child: SizedBox(
                  height: 240,
                  child: Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.white,
                      ),
                    ),
                  ),
                ),
              ),
              error: (err, _) => SliverToBoxAdapter(
                child: SizedBox(
                  height: 240,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: Text(
                        'Failed to load moods',
                        style: AppTextStyles.small,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SearchFocusScreen extends ConsumerStatefulWidget {
  const SearchFocusScreen({super.key});

  @override
  ConsumerState<SearchFocusScreen> createState() => _SearchFocusScreenState();
}

class _SearchFocusScreenState extends ConsumerState<SearchFocusScreen> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    final initial = ref.read(searchControllerProvider).query;
    _controller = TextEditingController(text: initial);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(searchControllerProvider);
    final searchController = ref.read(searchControllerProvider.notifier);
    final recentItems = ref.watch(searchRecentItemsProvider);

    if (_controller.text != state.query) {
      _controller.value = _controller.value.copyWith(
        text: state.query,
        selection: TextSelection.collapsed(offset: state.query.length),
      );
    }

    final query = state.query.trim();
    final typingData = state.typingData;
    final suggestions = (typingData?.suggestions ?? const <String>[])
        .take(5)
        .toList(growable: false);
    final typingItems = typingData?.items ?? const <SearchResultItem>[];
    final showSuggestions = query.isNotEmpty;
    final hasResultsData = state.results != null &&
        ((state.results!.topResult != null) || state.results!.items.isNotEmpty);
    final showResults = state.hasSubmittedSearch && query.isNotEmpty;

    return Scaffold(
      backgroundColor: AppColors.nearBlack,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            SearchFocusHeader(
              controller: _controller,
              onChanged: searchController.updateQueryDraft,
              onSubmitted: (value) async {
                final trimmed = value.trim();
                if (trimmed.isEmpty) {
                  searchController.hideSubmittedSearch();
                  return;
                }
                await searchController.submitSearch();
              },
              onBack: () => Navigator.of(context).pop(),
              onClear: () {
                _controller.clear();
                searchController.clearQuery();
              },
            ),
            if (showResults) ...[
              const SizedBox(height: AppSpacing.md),
              SearchFilterChipsRow(
                selectedFilter: state.selectedFilter,
                onFilterSelected: (filter) async {
                  await searchController.onFilterChanged(filter);
                },
              ),
              const SizedBox(height: AppSpacing.md),
            ],
            Expanded(
              child: Builder(
                builder: (_) {
                  if (!showResults && query.isEmpty && recentItems.isEmpty) {
                    return const SearchFocusEmptyBody();
                  }
                  if (!showResults && query.isEmpty && recentItems.isNotEmpty) {
                    return SearchRecentBody(items: recentItems);
                  }
                  if (!showResults && state.isLoading) {
                    return const Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.white,
                        ),
                      ),
                    );
                  }
                  if (!showResults && showSuggestions && typingData != null) {
                    return SearchSuggestionBody(
                      suggestions: suggestions,
                      simpleItems: typingItems,
                      onSuggestionTap: (text) async {
                        _controller.text = text;
                        _controller.selection =
                            TextSelection.collapsed(offset: text.length);
                        searchController.updateQueryDraft(text);
                        await searchController.submitSearch();
                      },
                    );
                  }
                  if (showResults && state.isLoading) {
                    return const Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.white,
                        ),
                      ),
                    );
                  }
                  if (showResults && state.error != null && !hasResultsData) {
                    return SearchErrorBody(
                      message: state.error!.message,
                      onRetry: searchController.retry,
                    );
                  }
                  if (!showResults || state.results == null) {
                    return const SizedBox.shrink();
                  }
                  return SearchResultBody(
                    results: state.results!,
                    isLoadingMore: state.isLoadingMore,
                    onLoadMore: searchController.loadMore,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchHeaderDelegate extends SliverPersistentHeaderDelegate {
  _SearchHeaderDelegate({
    required this.statusBarHeight,
    required this.onAvatarTap,
    required this.onSearchTap,
  });

  final double statusBarHeight;
  final VoidCallback onAvatarTap;
  final VoidCallback onSearchTap;

  double get _navRowHeight => AppTopNavigation.contentHeight;
  static const double _searchAreaHeight = 72;

  @override
  double get maxExtent => statusBarHeight + _navRowHeight + _searchAreaHeight;

  @override
  double get minExtent => statusBarHeight + _searchAreaHeight;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    final collapseProgress = (shrinkOffset / _navRowHeight).clamp(0.0, 1.0);

    return ClipRect(
      child: ColoredBox(
        color: AppColors.nearBlack,
        child: Stack(
          children: [
            if (collapseProgress < 1.0)
              Positioned(
                left: 0,
                right: 0,
                top: -shrinkOffset,
                child: Opacity(
                  opacity: 1 - collapseProgress,
                  child: AppTopNavigation(
                    leadingOnTap: onAvatarTap,
                    middle: Text(
                      'Search',
                      style: AppTextStyles.sectionTitle.copyWith(
                        fontSize: AppSpacing.searchHeaderCollapsedTitleFontSize,
                        height: 26 / AppSpacing.searchHeaderCollapsedTitleFontSize,
                      ),
                    ),
                    trailing: AppIcon(
                      icon: AppIcons.camera,
                      color: AppColors.white,
                      size: 24,
                    ),
                  ),
                ),
              ),
            Positioned(
              left: AppSpacing.lg,
              right: AppSpacing.lg,
              bottom: AppSpacing.lg,
              child: _CollapsedSearchInput(onTap: onSearchTap),
            ),
          ],
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _SearchHeaderDelegate oldDelegate) {
    return statusBarHeight != oldDelegate.statusBarHeight ||
        onAvatarTap != oldDelegate.onAvatarTap ||
        onSearchTap != oldDelegate.onSearchTap;
  }
}

class _CollapsedSearchInput extends StatelessWidget {
  const _CollapsedSearchInput({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppBorderRadius.comfortable),
        onTap: onTap,
        child: Ink(
          height: 48,
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(AppBorderRadius.comfortable),
          ),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Row(
            children: [
              AppIcon(
                icon: AppIcons.search, size: 28, color: AppColors.nearBlack),
              const SizedBox(width: AppSpacing.md),
              Text(
                'What do you want to play?',
                style: AppTextStyles.listItemTitle.copyWith(
                  color: AppColors.nearBlack,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
