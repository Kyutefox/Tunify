import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tunify/v2/core/constants/app_colors.dart';
import 'package:tunify/v2/core/constants/app_icons.dart';
import 'package:tunify/v2/core/constants/app_spacing.dart';
import 'package:tunify/v2/core/theme/app_text_styles.dart';
import 'package:tunify/v2/core/widgets/navigation/app_top_navigation.dart';
import 'package:tunify/v2/core/widgets/navigation/user_menu_launcher.dart';
import 'package:tunify/v2/features/library/domain/entities/library_item.dart';
import 'package:tunify/v2/features/library/presentation/constants/library_layout.dart';
import 'package:tunify/v2/features/library/presentation/constants/library_strings.dart';
import 'package:tunify/v2/features/library/presentation/providers/library_providers.dart';
import 'package:tunify/v2/features/library/presentation/library_list_invalidation.dart';
import 'package:tunify/v2/features/library/presentation/navigation/open_library_item.dart';
import 'package:tunify/v2/features/library/presentation/widgets/library_filter_pills.dart';
import 'package:tunify/v2/features/library/presentation/widgets/library_plus_actions_sheet.dart';
import 'package:tunify/v2/features/library/presentation/widgets/library_grid_tile.dart';
import 'package:tunify/v2/features/library/presentation/widgets/library_list_tile.dart';
import 'package:tunify/v2/features/library/presentation/widgets/library_sort_controls.dart';
import 'package:tunify/v2/features/library/presentation/widgets/library_search_mode_overlay.dart';

/// Spotify iOS 2024 "Your Library" screen.
///
/// Header: avatar + "Your Library" title + search icon + plus icon.
/// Filter pills row → sort / view-mode bar → grid (default) or list body.
class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({super.key});

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen>
    with SingleTickerProviderStateMixin {
  bool _isSearchMode = false;
  late final AnimationController _searchAnimController;
  late final CurvedAnimation _searchAnim;
  final TextEditingController _searchTextController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final ValueNotifier<String> _searchQuery = ValueNotifier<String>('');

  @override
  void initState() {
    super.initState();
    _searchAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _searchAnim = CurvedAnimation(
      parent: _searchAnimController,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    _searchTextController.addListener(() {
      _searchQuery.value = _searchTextController.text;
    });
  }

  @override
  void dispose() {
    _searchAnimController.dispose();
    _searchTextController.dispose();
    _searchFocusNode.dispose();
    _searchQuery.dispose();
    super.dispose();
  }

  void _enterSearchMode() {
    setState(() => _isSearchMode = true);
    _searchAnimController.forward();
    _searchFocusNode.requestFocus();
  }

  void _exitSearchMode() {
    _searchFocusNode.unfocus();
    _searchTextController.clear();
    _searchAnimController.reverse().then((_) {
      if (mounted) {
        setState(() => _isSearchMode = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final viewState = ref.watch(libraryControllerProvider);
    final itemsAsync = ref.watch(libraryItemsAsyncProvider(null));
    final bottomInset = MediaQuery.paddingOf(context).bottom + AppSpacing.xxl;
    final searchItems = itemsAsync.maybeWhen(
      data: (items) => items,
      orElse: () => const <LibraryItem>[],
    );

    return Scaffold(
      backgroundColor: AppColors.nearBlack,
      body: Stack(
        children: [
          Column(
            children: [
              AppTopNavigation(
                leadingOnTap: () => launchUserMenu(context),
                middle: Text(
                  LibraryStrings.yourLibrary,
                  style: AppTextStyles.sectionTitle.copyWith(
                    fontSize: LibraryLayout.screenTitleFontSize,
                    height: LibraryLayout.screenTitleLineHeight,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: _enterSearchMode,
                      child: AppIcon(
                        icon: AppIcons.search,
                        color: AppColors.white,
                        size: 24,
                      ),
                    ),
                    SizedBox(width: AppSpacing.lg),
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => showLibraryPlusActionsSheet(context, ref),
                      child: AppIcon(
                        icon: AppIcons.add,
                        color: AppColors.white,
                        size: 28,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              const LibraryFilterPills(),
              const SizedBox(height: AppSpacing.md),
              const LibrarySortControls(),
              Container(
                height: LibraryLayout.headerShadowHeight,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppColors.nearBlack.withValues(alpha: 0.4),
                      AppColors.transparent,
                    ],
                  ),
                ),
              ),
              Expanded(
                child: itemsAsync.when(
                  loading: () => const Center(
                    child: CircularProgressIndicator(),
                  ),
                  error: (e, _) => _LibraryErrorView(
                    message: e.toString(),
                    onRetry: () => invalidateLibraryListCaches(ref),
                  ),
                  data: (items) => RefreshIndicator(
                    onRefresh: () =>
                        ref.refresh(libraryRemoteItemsProvider(null).future),
                    child: AnimatedSwitcher(
                      duration: LibraryLayout.gridListSwitchDuration,
                      child: viewState.viewMode == LibraryViewMode.grid
                          ? _LibraryGridBody(
                              key: const ValueKey('grid'),
                              items: items,
                              bottomInset: bottomInset,
                            )
                          : _LibraryListBody(
                              key: const ValueKey('list'),
                              items: items,
                              bottomInset: bottomInset,
                            ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (_isSearchMode)
            PopScope(
              canPop: false,
              onPopInvokedWithResult: (didPop, _) {
                if (!didPop) {
                  _exitSearchMode();
                }
              },
              child: AnimatedBuilder(
                animation: _searchAnim,
                builder: (context, _) {
                  return FadeTransition(
                    opacity: _searchAnim,
                    child: LibrarySearchModeOverlay(
                      searchTextController: _searchTextController,
                      searchFocusNode: _searchFocusNode,
                      searchQuery: _searchQuery,
                      searchHint: LibraryStrings.searchYourLibraryHint,
                      items: searchItems,
                      bottomInset: bottomInset,
                      viewMode: viewState.viewMode,
                      onBack: _exitSearchMode,
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _LibraryGridBody extends StatelessWidget {
  const _LibraryGridBody({
    super.key,
    required this.items,
    required this.bottomInset,
  });

  final List<LibraryItem> items;
  final double bottomInset;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(
            height: MediaQuery.sizeOf(context).height * 0.45,
            child: const _LibraryEmptyView(),
          ),
        ],
      );
    }

    return GridView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(
        LibraryLayout.horizontalPadding,
        AppSpacing.sm,
        LibraryLayout.horizontalPadding,
        bottomInset,
      ),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: LibraryLayout.gridCrossAxisCount,
        mainAxisSpacing: LibraryLayout.gridMainAxisSpacing,
        crossAxisSpacing: LibraryLayout.gridCrossAxisSpacing,
        childAspectRatio: LibraryLayout.gridChildAspectRatio,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return LibraryGridTile(
          item: item,
          onTap: () => openLibraryItemFromList(context, item),
        );
      },
    );
  }
}

class _LibraryListBody extends StatelessWidget {
  const _LibraryListBody({
    super.key,
    required this.items,
    required this.bottomInset,
  });

  final List<LibraryItem> items;
  final double bottomInset;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(
            height: MediaQuery.sizeOf(context).height * 0.45,
            child: const _LibraryEmptyView(),
          ),
        ],
      );
    }

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.only(bottom: bottomInset),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return LibraryListTile(
          item: item,
          onTap: () => openLibraryItemFromList(context, item),
        );
      },
    );
  }
}

class _LibraryErrorView extends StatelessWidget {
  const _LibraryErrorView({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Could not load your library',
              style: AppTextStyles.featureHeading,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTextStyles.caption,
            ),
            const SizedBox(height: AppSpacing.lg),
            FilledButton(
              onPressed: onRetry,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

class _LibraryEmptyView extends StatelessWidget {
  const _LibraryEmptyView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppIcon(
              icon: AppIcons.libraryMusic,
              size: LibraryLayout.emptyStateIconSize,
              color: AppColors.silver,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              LibraryStrings.nothingHereTitle,
              style: AppTextStyles.featureHeading,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              LibraryStrings.nothingHereBody,
              textAlign: TextAlign.center,
              style: AppTextStyles.caption,
            ),
          ],
        ),
      ),
    );
  }
}
