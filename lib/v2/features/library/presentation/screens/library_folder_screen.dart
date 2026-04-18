import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tunify/v2/core/constants/app_colors.dart';
import 'package:tunify/v2/core/constants/app_icons.dart';
import 'package:tunify/v2/core/constants/app_spacing.dart';
import 'package:tunify/v2/core/theme/app_text_styles.dart';
import 'package:tunify/v2/core/widgets/buttons/filter_single_pill.dart';
import 'package:tunify/v2/core/widgets/navigation/app_top_navigation.dart';
import 'package:tunify/v2/features/library/domain/entities/library_item.dart';
import 'package:tunify/v2/features/library/domain/library_items_query.dart';
import 'package:tunify/v2/features/library/presentation/constants/library_layout.dart';
import 'package:tunify/v2/features/library/presentation/constants/library_strings.dart';
import 'package:tunify/v2/features/library/presentation/library_list_invalidation.dart';
import 'package:tunify/v2/features/library/presentation/navigation/open_library_item.dart';
import 'package:tunify/v2/features/library/presentation/providers/library_providers.dart';
import 'package:tunify/v2/features/library/presentation/screens/library_create_item_screen.dart';
import 'package:tunify/v2/features/library/presentation/screens/library_details_screen.dart';
import 'package:tunify/v2/features/library/presentation/widgets/library_grid_tile.dart';
import 'package:tunify/v2/features/library/presentation/widgets/library_list_tile.dart';
import 'package:tunify/v2/features/library/presentation/widgets/library_sort_controls.dart';
import 'package:tunify/v2/features/library/presentation/widgets/library_search_mode_overlay.dart';

/// Library scoped to one folder: back, folder title, search, + (create playlist here),
/// single "By you" filter, sort + view as root.
class LibraryFolderScreen extends ConsumerStatefulWidget {
  const LibraryFolderScreen({
    super.key,
    required this.folderId,
    required this.folderName,
  });

  final String folderId;
  final String folderName;

  @override
  ConsumerState<LibraryFolderScreen> createState() => _LibraryFolderScreenState();
}

class _LibraryFolderScreenState extends ConsumerState<LibraryFolderScreen>
    with SingleTickerProviderStateMixin {
  bool _byYouOnly = false;
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

  Future<void> _onTapPlus() async {
    final created = await Navigator.of(context).push<LibraryItem?>(
      MaterialPageRoute<LibraryItem?>(
        builder: (_) => LibraryCreateItemScreen(
          isPlaylist: true,
          initialFolderId: widget.folderId,
        ),
      ),
    );
    if (!mounted) {
      return;
    }
    if (created != null) {
      invalidateLibraryListCaches(ref, folderId: widget.folderId);
      await Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (_) => LibraryDetailsScreen(item: created),
        ),
      );
    }
  }

  AsyncValue<List<LibraryItem>> _processedItems() {
    final remote = ref.watch(libraryRemoteItemsProvider(widget.folderId));
    final sortMode = ref.watch(
      libraryControllerProvider.select((s) => s.sortMode),
    );
    return remote.whenData((raw) {
      var base = raw;
      if (_byYouOnly) {
        base = raw
            .where(
              (i) =>
                  i.kind != LibraryItemKind.playlist ||
                  LibraryItemsQuery.playlistIsByYou(i),
            )
            .toList();
      }
      return LibraryItemsQuery.applyFolderContents(
        items: base,
        sortMode: sortMode,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final viewMode = ref.watch(
      libraryControllerProvider.select((s) => s.viewMode),
    );
    final itemsAsync = _processedItems();
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
                useBackButton: true,
                leadingOnTap: () => Navigator.of(context).maybePop(),
                middle: Text(
                  widget.folderName,
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
                      onTap: _onTapPlus,
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
              SizedBox(
                height: LibraryLayout.filterPillsRowHeight,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: LibraryLayout.horizontalPadding,
                    ),
                    child: FilterSinglePill(
                      label: 'By you',
                      selected: _byYouOnly,
                      onPressed: () => setState(() => _byYouOnly = !_byYouOnly),
                    ),
                  ),
                ),
              ),
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
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => _FolderErrorView(
                    message: e.toString(),
                    onRetry: () => ref.invalidate(
                      libraryRemoteItemsProvider(widget.folderId),
                    ),
                  ),
                  data: (items) => RefreshIndicator(
                    onRefresh: () => ref.refresh(
                      libraryRemoteItemsProvider(widget.folderId).future,
                    ),
                    child: AnimatedSwitcher(
                      duration: LibraryLayout.gridListSwitchDuration,
                      child: viewMode == LibraryViewMode.grid
                          ? _FolderGridBody(
                              key: const ValueKey('grid'),
                              folderId: widget.folderId,
                              items: items,
                              bottomInset: bottomInset,
                            )
                          : _FolderListBody(
                              key: const ValueKey('list'),
                              folderId: widget.folderId,
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
                      searchHint: LibraryStrings.searchFolderHint,
                      items: searchItems,
                      bottomInset: bottomInset,
                      viewMode: viewMode,
                      onBack: _exitSearchMode,
                      libraryListScopeFolderId: widget.folderId,
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

class _FolderGridBody extends StatelessWidget {
  const _FolderGridBody({
    super.key,
    required this.folderId,
    required this.items,
    required this.bottomInset,
  });

  final String folderId;
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
            child: const _FolderEmptyView(),
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
          libraryListScopeFolderId: folderId,
          onTap: () => openLibraryItemFromList(context, item),
        );
      },
    );
  }
}

class _FolderListBody extends StatelessWidget {
  const _FolderListBody({
    super.key,
    required this.folderId,
    required this.items,
    required this.bottomInset,
  });

  final String folderId;
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
            child: const _FolderEmptyView(),
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
          libraryListScopeFolderId: folderId,
          onTap: () => openLibraryItemFromList(context, item),
        );
      },
    );
  }
}

class _FolderErrorView extends StatelessWidget {
  const _FolderErrorView({
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
              'Could not load folder',
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

class _FolderEmptyView extends StatelessWidget {
  const _FolderEmptyView();

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
