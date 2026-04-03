import 'package:flutter/material.dart';

import 'package:tunify/ui/widgets/common/adaptive_menu.dart';
import 'package:tunify/ui/widgets/library/library_filter_chips.dart';
import 'package:tunify/ui/widgets/common/button.dart';
import 'package:tunify/core/constants/app_icons.dart';
import 'package:tunify/features/library/library_provider.dart';
import 'package:tunify/ui/theme/app_colors.dart';
import 'package:tunify/ui/theme/design_tokens.dart';
import 'package:tunify/ui/widgets/player/download_queue_progress_icon.dart';
import 'package:tunify/ui/theme/app_colors_scheme.dart';

enum LibraryFilter {
  all,
  playlists,
  albums,
  artists,
}

extension LibraryFilterX on LibraryFilter {
  String get label {
    switch (this) {
      case LibraryFilter.all:
        return 'All';
      case LibraryFilter.playlists:
        return 'Playlists';
      case LibraryFilter.albums:
        return 'Albums';
      case LibraryFilter.artists:
        return 'Artists';
    }
  }
}

class LibraryAppBar extends StatefulWidget {
  const LibraryAppBar({
    super.key,
    required this.onSearchTap,
    required this.onDownloadQueueTap,
    required this.onCreateTap,
    required this.selectedFilter,
    required this.onFilterChanged,
    required this.sortOrder,
    required this.viewMode,
    required this.onSortChanged,
    required this.onViewModeChanged,
    this.folderName,
    this.onExitFolder,
    this.asSliver = true,
  });

  final VoidCallback onSearchTap;
  final VoidCallback onDownloadQueueTap;
  final VoidCallback onCreateTap;

  /// Null = no filter (main section). Non-null = that filter's section is shown.
  final LibraryFilter? selectedFilter;

  /// Pass null to clear filter and show main section.
  final ValueChanged<LibraryFilter?> onFilterChanged;
  final LibrarySortOrder sortOrder;
  final LibraryViewMode viewMode;
  final ValueChanged<LibrarySortOrder> onSortChanged;
  final ValueChanged<LibraryViewMode> onViewModeChanged;

  /// When set, the filter chip row is replaced by [X] and folder name (exit folder view).
  final String? folderName;
  final VoidCallback? onExitFolder;

  /// When true (default), wraps content in [SliverToBoxAdapter]. When false, returns the header widget only for use in a fixed header.
  final bool asSliver;

  @override
  State<LibraryAppBar> createState() => _LibraryAppBarState();
}

/// Shows the library sort-order menu.
/// Mobile: bottom sheet. Desktop: dropdown anchored to [anchorRect].
/// Shared between [LibraryAppBar] (mobile) and the desktop sidebar.
void showLibrarySortSheet(
  BuildContext context,
  LibrarySortOrder current,
  ValueChanged<LibrarySortOrder> onSelected, {
  Rect? anchorRect,
}) {
  showAdaptiveMenu(
    context,
    title: 'Sort by',
    anchorRect: anchorRect,
    entries: LibrarySortOrder.values
        .map((o) => AppMenuEntry(
              icon: o == current ? AppIcons.check : AppIcons.sort,
              label: o.label,
              color: o == current ? AppColors.primary : null,
              onTap: () => onSelected(o),
            ))
        .toList(),
  );
}

class _LibraryAppBarState extends State<LibraryAppBar> {
  static const double _sortGridIconSize = 18;

  Widget _buildHeaderContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.base, AppSpacing.sm, AppSpacing.base, 0),
          child: Row(
            children: [
              Text(
                'Library',
                style: TextStyle(
                  color: AppColorsScheme.of(context).textPrimary,
                  fontSize: AppFontSize.display3,
                  fontWeight: FontWeight.w800,
                  letterSpacing: AppLetterSpacing.display,
                ),
              ),
              const Spacer(),
              AppIconButton(
                icon: DownloadQueueProgressIcon(
                  iconSize: 22,
                  baseColor: AppColorsScheme.of(context).textPrimary,
                ),
                onPressed: widget.onDownloadQueueTap,
                tooltip: 'Download queue',
                size: 40,
                iconSize: 22,
                iconAlignment: Alignment.centerRight,
              ),
              AppIconButton(
                icon: AppIcon(
                  icon: AppIcons.add,
                  size: 24,
                  color: AppColorsScheme.of(context).textPrimary,
                ),
                onPressed: widget.onCreateTap,
                tooltip: 'Create playlist or folder',
                iconAlignment: Alignment.centerRight,
              ),
              AppIconButton(
                icon: AppIcon(
                  icon: AppIcons.search,
                  size: 24,
                  color: AppColorsScheme.of(context).textPrimary,
                ),
                onPressed: widget.onSearchTap,
                tooltip: 'Search library',
                iconAlignment: Alignment.centerRight,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.base),
          child: LibraryFilterChips(
            selectedFilter: widget.selectedFilter,
            onFilterChanged: widget.onFilterChanged,
            folderName: widget.folderName,
            onExitFolder: widget.onExitFolder,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Padding(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.base, 0, AppSpacing.base, AppSpacing.sm),
          child: Row(
            children: [
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => showLibrarySortSheet(
                      context, widget.sortOrder, widget.onSortChanged),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  child: Padding(
                    padding: const EdgeInsets.only(
                      right: AppSpacing.sm,
                      top: AppSpacing.xs,
                      bottom: AppSpacing.xs,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AppIcon(
                          icon: AppIcons.sort,
                          color: AppColorsScheme.of(context).textSecondary,
                          size: _sortGridIconSize,
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Text(
                          widget.sortOrder.label,
                          style: TextStyle(
                            color: AppColorsScheme.of(context).textSecondary,
                            fontSize: AppFontSize.md,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const Spacer(),
              AppIconButton(
                tooltip: widget.viewMode == LibraryViewMode.list
                    ? 'Grid view'
                    : 'List view',
                color: AppColorsScheme.of(context).textSecondary,
                onPressed: () => widget.onViewModeChanged(
                  widget.viewMode == LibraryViewMode.list
                      ? LibraryViewMode.grid
                      : LibraryViewMode.list,
                ),
                icon: AppIcon(
                  icon: widget.viewMode == LibraryViewMode.list
                      ? AppIcons.gridView
                      : AppIcons.listView,
                  size: _sortGridIconSize,
                  color: AppColorsScheme.of(context).textSecondary,
                ),
                iconSize: _sortGridIconSize,
                size: 36,
                iconAlignment: Alignment.centerRight,
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.asSliver) {
      return SliverToBoxAdapter(child: _buildHeaderContent());
    }
    return _buildHeaderContent();
  }
}
