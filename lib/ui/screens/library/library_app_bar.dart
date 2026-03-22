import 'package:flutter/material.dart';

import 'package:tunify/ui/widgets/adaptive_menu.dart';
import 'package:tunify/ui/widgets/library_filter_chips.dart';
import 'package:tunify/ui/widgets/button.dart';
import 'package:tunify/core/constants/app_icons.dart';
import 'package:tunify/features/library/library_provider.dart';
import 'package:tunify/ui/theme/app_colors.dart';
import 'package:tunify/ui/theme/design_tokens.dart';
import 'package:tunify/ui/widgets/items/download_queue_progress_icon.dart';

enum LibraryFilter {
  all,
  playlists,
  albums,
  artists,
  downloaded,
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
      case LibraryFilter.downloaded:
        return 'Downloaded';
    }
  }
}

enum DownloadedSource { library, device }

class LibraryAppBar extends StatefulWidget {
  const LibraryAppBar({
    super.key,
    required this.onSearchTap,
    required this.onDownloadQueueTap,
    required this.onCreateTap,
    required this.selectedFilter,
    required this.onFilterChanged,
    this.downloadedSource,
    this.onDownloadedSourceChanged,
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
  final DownloadedSource? downloadedSource;
  final ValueChanged<DownloadedSource>? onDownloadedSourceChanged;
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
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.base,
        vertical: AppSpacing.sm,
      ),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'Library',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: AppFontSize.display3,
                    fontWeight: FontWeight.w800,
                    letterSpacing: AppLetterSpacing.display,
                  ),
                ),
                const Spacer(),
                AppIconButton(
                  icon: const DownloadQueueProgressIcon(
                    iconSize: 22,
                    baseColor: AppColors.textPrimary,
                  ),
                  onPressed: widget.onDownloadQueueTap,
                  tooltip: 'Download queue',
                  size: 40,
                  iconSize: 22,
                ),
                AppIconButton(
                  icon: AppIcon(
                    icon: AppIcons.add,
                    size: 24,
                    color: AppColors.textPrimary,
                  ),
                  onPressed: widget.onCreateTap,
                  tooltip: 'Create playlist or folder',
                ),
                AppIconButton(
                  icon: AppIcon(
                    icon: AppIcons.search,
                    size: 24,
                    color: AppColors.textPrimary,
                  ),
                  onPressed: widget.onSearchTap,
                  tooltip: 'Search library',
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            LibraryFilterChips(
              selectedFilter: widget.selectedFilter,
              onFilterChanged: widget.onFilterChanged,
              folderName: widget.folderName,
              onExitFolder: widget.onExitFolder,
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => showLibrarySortSheet(context, widget.sortOrder, widget.onSortChanged),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: AppSpacing.xs,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AppIcon(
                            icon: AppIcons.sort,
                            color: AppColors.textSecondary,
                            size: _sortGridIconSize,
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Text(
                            widget.sortOrder.label,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: AppFontSize.md,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                if (widget.selectedFilter == LibraryFilter.downloaded &&
                    widget.downloadedSource != null &&
                    widget.onDownloadedSourceChanged != null) ...[
                  const SizedBox(width: AppSpacing.md),
                  _LibraryDeviceSwitch(
                    source: widget.downloadedSource!,
                    onChanged: widget.onDownloadedSourceChanged!,
                  ),
                ],
                const Spacer(),
                AppIconButton(
                  tooltip: widget.viewMode == LibraryViewMode.list
                      ? 'Grid view'
                      : 'List view',
                  color: AppColors.textSecondary,
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
                    color: AppColors.textSecondary,
                  ),
                  iconSize: _sortGridIconSize,
                  size: 36,
                ),
              ],
            ),
          ],
        ),
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


class _LibraryDeviceSwitch extends StatelessWidget {
  const _LibraryDeviceSwitch({
    required this.source,
    required this.onChanged,
  });

  final DownloadedSource source;
  final ValueChanged<DownloadedSource> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _Segment(
            label: 'Library',
            selected: source == DownloadedSource.library,
            onTap: () => onChanged(DownloadedSource.library),
          ),
          _Segment(
            label: 'Device',
            selected: source == DownloadedSource.device,
            onTap: () => onChanged(DownloadedSource.device),
          ),
        ],
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  const _Segment({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.xs),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: 6,
          ),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.primary.withValues(alpha: 0.2)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadius.xs),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? AppColors.primary : AppColors.textSecondary,
              fontSize: AppFontSize.sm,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

