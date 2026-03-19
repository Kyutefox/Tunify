import 'package:flutter/scheduler.dart';
import 'package:flutter/material.dart';

import '../../components/ui/button.dart';
import '../../components/ui/sheet.dart';
import '../../components/ui/widgets/widgets.dart';
import '../../../config/app_icons.dart';
import '../../../shared/providers/library_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/design_tokens.dart';

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

/// Approximate width of the clear (X) chip + padding so slot can shrink in sync with X exit.
const double _clearChipSlotWidth = 44;

class LibraryAppBar extends StatefulWidget {
  const LibraryAppBar({
    super.key,
    required this.onSearchTap,
    required this.onDownloadQueueTap,
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

class _LibraryAppBarState extends State<LibraryAppBar>
    with SingleTickerProviderStateMixin {
  static const double _sortGridIconSize = 18;
  static const Duration _chipTransitionDuration =
      Duration(milliseconds: 320);

  late final AnimationController _exitController = AnimationController(
    vsync: this,
    duration: _chipTransitionDuration,
  );
  LibraryFilter? _exitingFilter;

  @override
  void initState() {
    super.initState();
    _exitController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        SchedulerBinding.instance.addPostFrameCallback((_) {
          if (mounted) setState(() => _exitingFilter = null);
        });
      }
    });
  }

  @override
  void didUpdateWidget(LibraryAppBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedFilter != null && widget.selectedFilter == null) {
      _exitingFilter = oldWidget.selectedFilter;
      _exitController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _exitController.dispose();
    super.dispose();
  }

  static Widget _slideTransition(Widget child, Animation<double> animation) {
    final curved = CurvedAnimation(
      parent: animation,
      curve: Curves.easeInOutCubic,
      reverseCurve: Curves.easeInOutCubic,
    );
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(-0.35, 0),
        end: Offset.zero,
      ).animate(curved),
      child: FadeTransition(
        opacity: Tween<double>(begin: 0, end: 1).animate(curved),
        child: child,
      ),
    );
  }

  static Widget _chipLayoutBuilder(
    Widget? currentChild,
    List<Widget> previousChildren,
  ) {
    return Stack(
      alignment: Alignment.centerLeft,
      clipBehavior: Clip.none,
      children: <Widget>[
        ...previousChildren,
        if (currentChild != null) currentChild,
      ],
    );
  }

  static void _showSortSheet(
    BuildContext context,
    LibrarySortOrder current,
    ValueChanged<LibrarySortOrder> onSelected,
  ) {
    showAppSheet(
      context,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(AppSpacing.base, AppSpacing.md, AppSpacing.base, AppSpacing.sm),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Sort by',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          _SortOption(
            label: LibrarySortOrder.recent.label,
            selected: current == LibrarySortOrder.recent,
            onTap: () {
              Navigator.pop(context);
              onSelected(LibrarySortOrder.recent);
            },
          ),
          _SortOption(
            label: LibrarySortOrder.recentlyAdded.label,
            selected: current == LibrarySortOrder.recentlyAdded,
            onTap: () {
              Navigator.pop(context);
              onSelected(LibrarySortOrder.recentlyAdded);
            },
          ),
          _SortOption(
            label: LibrarySortOrder.alphabetical.label,
            selected: current == LibrarySortOrder.alphabetical,
            onTap: () {
              Navigator.pop(context);
              onSelected(LibrarySortOrder.alphabetical);
            },
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }

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
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.8,
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
            AnimatedSwitcher(
              duration: _chipTransitionDuration,
              switchInCurve: Curves.easeInOutCubic,
              switchOutCurve: Curves.easeInOutCubic,
              transitionBuilder: _slideTransition,
              layoutBuilder: _chipLayoutBuilder,
              child: widget.folderName != null && widget.onExitFolder != null
                  ? SingleChildScrollView(
                      key: const ValueKey('folder-row'),
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(
                                right: AppSpacing.sm),
                            child: _LibraryChip(
                              selected: true,
                              onTap: widget.onExitFolder!,
                              child: AppIcon(
                                icon: AppIcons.close,
                                size: 14,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                          _LibraryChip(
                            selected: true,
                            onTap: widget.onExitFolder!,
                            child: Text(
                              widget.folderName!,
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    )
                  : SingleChildScrollView(
                      key: const ValueKey('filter-row'),
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _exitingFilter != null
                              ? AnimatedBuilder(
                                  animation: _exitController,
                                  builder: (context, _) {
                                    final t = Curves.easeInOutCubic
                                        .transform(_exitController.value);
                                    final slotWidth =
                                        _clearChipSlotWidth * (1 - t);
                                    return SizedBox(
                                      width: slotWidth.clamp(0.0, double.infinity),
                                      child: ClipRect(
                                        child: Align(
                                          alignment: Alignment.centerLeft,
                                          child: SlideTransition(
                                            position: Tween<Offset>(
                                              begin: Offset.zero,
                                              end: const Offset(-1, 0),
                                            ).animate(
                                              CurvedAnimation(
                                                parent: _exitController,
                                                curve: Curves.easeInOutCubic,
                                              ),
                                            ),
                                            child: FadeTransition(
                                              opacity: Tween<double>(
                                                begin: 1,
                                                end: 0,
                                              ).animate(
                                                CurvedAnimation(
                                                  parent: _exitController,
                                                  curve: Curves.easeInOutCubic,
                                                ),
                                              ),
                                              child: Padding(
                                                padding: const EdgeInsets.only(
                                                    right: AppSpacing.sm),
                                                child: _LibraryChip(
                                                  selected: true,
                                                  onTap: () {},
                                                  child: AppIcon(
                                                    icon: AppIcons.close,
                                                    size: 14,
                                                    color: AppColors.primary,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                )
                              : widget.selectedFilter != null
                                  ? Padding(
                                      key: const ValueKey('clear-chip'),
                                      padding: const EdgeInsets.only(
                                          right: AppSpacing.sm),
                                      child: _LibraryChip(
                                        selected: true,
                                        onTap: () =>
                                            widget.onFilterChanged(null),
                                        child: AppIcon(
                                          icon: AppIcons.close,
                                          size: 14,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                    )
                                  : const SizedBox(
                                      key: ValueKey('no-clear-chip'),
                                      width: 0,
                                    ),
                          ...LibraryFilter.values
                              .where((f) => f != LibraryFilter.all)
                              .map((filter) {
                            final selected =
                                widget.selectedFilter == filter;
                            return Padding(
                              padding: EdgeInsets.only(
                                right: filter !=
                                        LibraryFilter.downloaded
                                    ? AppSpacing.sm
                                    : 0,
                              ),
                              child: _LibraryChip(
                                selected: selected,
                                onTap: () =>
                                    widget.onFilterChanged(filter),
                                child: Text(
                                  filter.label,
                                  style: TextStyle(
                                    color: selected
                                        ? AppColors.primary
                                        : AppColors.textSecondary,
                                    fontSize: 13,
                                    fontWeight: selected
                                        ? FontWeight.w600
                                        : FontWeight.w500,
                                  ),
                                ),
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => _showSortSheet(context, widget.sortOrder, widget.onSortChanged),
                    borderRadius: BorderRadius.circular(8),
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
                              fontSize: 13,
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

class _SortOption extends StatelessWidget {
  const _SortOption({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(
        label,
        style: TextStyle(
          color: selected ? AppColors.primary : AppColors.textPrimary,
          fontSize: 16,
          fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
        ),
      ),
      trailing: selected
          ? AppIcon(
              icon: AppIcons.check,
              color: AppColors.primary,
              size: 22,
            )
          : null,
      onTap: onTap,
    );
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
        borderRadius: BorderRadius.circular(8),
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
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: 6,
          ),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.primary.withValues(alpha: 0.2)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? AppColors.primary : AppColors.textSecondary,
              fontSize: 12,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

/// Reusable filter/folder chip: same size and style as library filter chips.
class _LibraryChip extends StatelessWidget {
  const _LibraryChip({
    required this.selected,
    required this.onTap,
    required this.child,
  });

  final bool selected;
  final VoidCallback onTap;
  final Widget child;

  static const double _height = 32;
  static const double _radius = 8;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(_radius),
        child: Container(
          height: _height,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected
                ? AppColors.primary.withValues(alpha: 0.2)
                : AppColors.surfaceLight.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(_radius),
            border: selected
                ? Border.all(color: AppColors.primary, width: 1)
                : null,
          ),
          child: child,
        ),
      ),
    );
  }
}
