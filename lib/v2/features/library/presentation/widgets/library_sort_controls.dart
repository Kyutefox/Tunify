import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tunify/v2/core/constants/app_colors.dart';
import 'package:tunify/v2/core/constants/app_spacing.dart';
import 'package:tunify/v2/core/theme/app_text_styles.dart';
import 'package:tunify/v2/features/library/domain/entities/library_item.dart';
import 'package:tunify/v2/features/library/presentation/constants/library_layout.dart';
import 'package:tunify/v2/features/library/presentation/constants/library_strings.dart';
import 'package:tunify/v2/core/constants/app_icons.dart';
import 'package:tunify/v2/features/library/presentation/providers/library_providers.dart';

/// Sort-mode button (left) + grid/list toggle (right).
///
/// Figma: "↕ Recents" left-aligned, grid icon right-aligned.
class LibrarySortControls extends ConsumerWidget {
  const LibrarySortControls({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final viewState = ref.watch(libraryControllerProvider);
    final notifier = ref.read(libraryControllerProvider.notifier);

    return SizedBox(
      height: LibraryLayout.controlBarHeight,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: LibraryLayout.horizontalPadding,
        ),
        child: Row(
          children: [
            GestureDetector(
              onTap: () => _showSortSheet(context, ref),
              behavior: HitTestBehavior.opaque,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppIcon(
                    icon: AppIcons.swapVert,
                    size: 14,
                    color: AppColors.white,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    _sortLabel(viewState.sortMode),
                    style: AppTextStyles.small.copyWith(
                      color: AppColors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),
            GestureDetector(
              onTap: notifier.toggleViewMode,
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.sm),
                child: AppIcon(
                  icon: viewState.viewMode == LibraryViewMode.list
                      ? AppIcons.gridView
                      : AppIcons.listView,
                  size: 18,
                  color: AppColors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _sortLabel(LibrarySortMode mode) {
    return switch (mode) {
      LibrarySortMode.recents => 'Recents',
      LibrarySortMode.recentlyAdded => 'Recently Added',
      LibrarySortMode.alphabetical => 'Alphabetical',
      LibrarySortMode.creator => 'Creator',
    };
  }

  void _showSortSheet(BuildContext context, WidgetRef ref) {
    final currentMode = ref.read(libraryControllerProvider).sortMode;
    final notifier = ref.read(libraryControllerProvider.notifier);

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.darkSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSpacing.lg),
        ),
      ),
      builder: (_) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                  child: Text(
                    LibraryStrings.sortBy,
                    style: AppTextStyles.featureHeading
                        .copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                for (final mode in LibrarySortMode.values)
                  _SortOption(
                    label: _sortLabel(mode),
                    isSelected: mode == currentMode,
                    onTap: () {
                      notifier.setSortMode(mode);
                      Navigator.of(context).pop();
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SortOption extends StatelessWidget {
  const _SortOption({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md + AppSpacing.sm,
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: AppTextStyles.body.copyWith(
                    color: isSelected ? AppColors.brandGreen : AppColors.white,
                  ),
                ),
              ),
              if (isSelected)
                AppIcon(
                  icon: AppIcons.check,
                  size: 20,
                  color: AppColors.brandGreen,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
