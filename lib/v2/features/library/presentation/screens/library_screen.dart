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
import 'package:tunify/v2/features/library/presentation/screens/library_details_screen.dart';
import 'package:tunify/v2/features/library/presentation/widgets/library_filter_pills.dart';
import 'package:tunify/v2/features/library/presentation/widgets/library_grid_tile.dart';
import 'package:tunify/v2/features/library/presentation/widgets/library_list_tile.dart';
import 'package:tunify/v2/features/library/presentation/widgets/library_sort_controls.dart';

/// Spotify iOS 2024 "Your Library" screen.
///
/// Header: avatar + "Your Library" title + search icon + plus icon.
/// Filter pills row → sort / view-mode bar → grid (default) or list body.
class LibraryScreen extends ConsumerWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final viewState = ref.watch(libraryControllerProvider);
    final items = ref.watch(libraryItemsProvider);
    final bottomInset = MediaQuery.paddingOf(context).bottom + AppSpacing.xxl;

    return Scaffold(
      backgroundColor: AppColors.nearBlack,
      body: Column(
        children: [
          // ── Header: avatar · title · search · plus ──
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
                AppIcon(
                    icon: AppIcons.search, color: AppColors.white, size: 24),
                SizedBox(width: AppSpacing.lg),
                AppIcon(icon: AppIcons.add, color: AppColors.white, size: 28),
              ],
            ),
          ),

          // ── Filter pills ──
          const SizedBox(height: AppSpacing.md),
          const LibraryFilterPills(),

          // ── Sort / view-mode controls ──
          const SizedBox(height: AppSpacing.md),
          const LibrarySortControls(),

          // ── Shadow fade between fixed header and scroll area ──
          Container(
            height: LibraryLayout.headerShadowHeight,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.4),
                  Colors.transparent,
                ],
              ),
            ),
          ),

          // ── Content body ──
          Expanded(
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
        ],
      ),
    );
  }
}

/// Grid-view body using [GridView.builder] — 3 columns (Figma).
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
    if (items.isEmpty) return const _LibraryEmptyView();

    return GridView.builder(
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
          onTap: () => _openDetails(context, item),
        );
      },
    );
  }
}

/// List-view body using [ListView.builder].
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
    if (items.isEmpty) return const _LibraryEmptyView();

    return ListView.builder(
      padding: EdgeInsets.only(bottom: bottomInset),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return LibraryListTile(
          item: item,
          onTap: () => _openDetails(context, item),
        );
      },
    );
  }
}

void _openDetails(BuildContext context, LibraryItem item) {
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => LibraryDetailsScreen(item: item),
    ),
  );
}

/// Empty state when no items match the current filter.
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
