import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tunify/v2/core/constants/app_colors.dart';
import 'package:tunify/v2/core/constants/app_spacing.dart';
import 'package:tunify/v2/core/theme/app_text_styles.dart';
import 'package:tunify/v2/core/widgets/navigation/app_top_navigation.dart';
import 'package:tunify/v2/core/widgets/navigation/user_menu_launcher.dart';
import 'package:tunify/v2/features/library/domain/entities/library_item.dart';
import 'package:tunify/v2/features/library/presentation/constants/library_layout.dart';
import 'package:tunify/v2/features/library/presentation/providers/library_providers.dart';
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
    final bottomInset =
        MediaQuery.paddingOf(context).bottom + AppSpacing.xxl;

    return Scaffold(
      backgroundColor: AppColors.nearBlack,
      body: Column(
        children: [
          // ── Header: avatar · title · search · plus ──
          AppTopNavigation(
            leadingOnTap: () => launchUserMenu(context),
            middle: Text(
              'Your Library',
              style: AppTextStyles.sectionTitle.copyWith(
                fontSize: 22,
                height: 26 / 22,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.search, color: AppColors.white, size: 24),
                SizedBox(width: AppSpacing.lg),
                Icon(Icons.add, color: AppColors.white, size: 28),
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
              duration: const Duration(milliseconds: 250),
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
      itemBuilder: (_, index) => LibraryGridTile(item: items[index]),
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
      itemBuilder: (_, index) => LibraryListTile(item: items[index]),
    );
  }
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
            const Icon(
              Icons.library_music_outlined,
              size: 48,
              color: AppColors.silver,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Nothing here yet',
              style: AppTextStyles.featureHeading,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Your saved music, podcasts, and playlists will appear here.',
              textAlign: TextAlign.center,
              style: AppTextStyles.caption,
            ),
          ],
        ),
      ),
    );
  }
}
