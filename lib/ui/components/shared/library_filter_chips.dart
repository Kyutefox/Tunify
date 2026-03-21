import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../../config/app_icons.dart';
import '../../screens/library/library_app_bar.dart';
import '../../theme/app_colors.dart';
import '../../theme/design_tokens.dart';

/// Approximate width of the clear (X) chip + padding — kept in sync with
/// [_LibraryChip] dimensions so the slot shrinks at the same speed as the exit.
const double _kClearChipSlotWidth = 44;

/// The animated filter-chip row shared by [LibraryAppBar] (mobile) and
/// [DesktopSidebar] (desktop).
///
/// Features:
/// - Active filter gets a coloured border + tinted background.
/// - Selecting an active filter deactivates it (passes null to [onFilterChanged]).
/// - An animated [X] chip appears when a filter is active; pressing it or the
///   active chip clears the filter.
/// - When transitioning back to "all", the X chip slides out smoothly.
/// - When [folderName] + [onExitFolder] are set, the chips are replaced by a
///   folder breadcrumb (same visual language as the filter chips).
class LibraryFilterChips extends StatefulWidget {
  const LibraryFilterChips({
    super.key,
    required this.selectedFilter,
    required this.onFilterChanged,
    this.folderName,
    this.onExitFolder,
    /// Filters to show. Defaults to all except [LibraryFilter.all].
    this.filters,
  });

  final LibraryFilter? selectedFilter;
  final ValueChanged<LibraryFilter?> onFilterChanged;
  final String? folderName;
  final VoidCallback? onExitFolder;
  final List<LibraryFilter>? filters;

  @override
  State<LibraryFilterChips> createState() => _LibraryFilterChipsState();
}

class _LibraryFilterChipsState extends State<LibraryFilterChips>
    with SingleTickerProviderStateMixin {
  static const Duration _duration = Duration(milliseconds: 320);

  late final AnimationController _exitController = AnimationController(
    vsync: this,
    duration: _duration,
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
  void didUpdateWidget(LibraryFilterChips old) {
    super.didUpdateWidget(old);
    if (old.selectedFilter != null && widget.selectedFilter == null) {
      _exitingFilter = old.selectedFilter;
      _exitController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _exitController.dispose();
    super.dispose();
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  static Widget _slideIn(Widget child, Animation<double> animation) {
    final curved = CurvedAnimation(
      parent: animation,
      curve: Curves.easeInOutCubic,
      reverseCurve: Curves.easeInOutCubic,
    );
    return SlideTransition(
      position:
          Tween<Offset>(begin: const Offset(-0.35, 0), end: Offset.zero)
              .animate(curved),
      child: FadeTransition(
        opacity: Tween<double>(begin: 0, end: 1).animate(curved),
        child: child,
      ),
    );
  }

  static Widget _stackLayout(
      Widget? currentChild, List<Widget> previousChildren) {
    return Stack(
      alignment: Alignment.centerLeft,
      clipBehavior: Clip.none,
      children: <Widget>[
        ...previousChildren,
        if (currentChild != null) currentChild,
      ],
    );
  }

  // ── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final effectiveFilters = widget.filters ??
        LibraryFilter.values.where((f) => f != LibraryFilter.all).toList();

    return AnimatedSwitcher(
      duration: _duration,
      switchInCurve: Curves.easeInOutCubic,
      switchOutCurve: Curves.easeInOutCubic,
      transitionBuilder: _slideIn,
      layoutBuilder: _stackLayout,
      child: widget.folderName != null && widget.onExitFolder != null
          ? SingleChildScrollView(
              key: const ValueKey('folder-row'),
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: AppSpacing.sm),
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
                        fontSize: AppFontSize.md,
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
                  // Animated X chip slot
                  _exitingFilter != null
                      ? AnimatedBuilder(
                          animation: _exitController,
                          builder: (context, _) {
                            final t = Curves.easeInOutCubic
                                .transform(_exitController.value);
                            final slotWidth = _kClearChipSlotWidth * (1 - t);
                            return SizedBox(
                              width: slotWidth.clamp(0.0, double.infinity),
                              child: ClipRect(
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: SlideTransition(
                                    position: Tween<Offset>(
                                      begin: Offset.zero,
                                      end: const Offset(-1, 0),
                                    ).animate(CurvedAnimation(
                                      parent: _exitController,
                                      curve: Curves.easeInOutCubic,
                                    )),
                                    child: FadeTransition(
                                      opacity: Tween<double>(
                                        begin: 1,
                                        end: 0,
                                      ).animate(CurvedAnimation(
                                        parent: _exitController,
                                        curve: Curves.easeInOutCubic,
                                      )),
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
                              padding:
                                  const EdgeInsets.only(right: AppSpacing.sm),
                              child: _LibraryChip(
                                selected: true,
                                onTap: () => widget.onFilterChanged(null),
                                child: AppIcon(
                                  icon: AppIcons.close,
                                  size: 14,
                                  color: AppColors.primary,
                                ),
                              ),
                            )
                          : const SizedBox(
                              key: ValueKey('no-clear-chip'), width: 0),

                  // Filter chips
                  for (final filter in effectiveFilters)
                    Padding(
                      padding: EdgeInsets.only(
                        right: filter != effectiveFilters.last
                            ? AppSpacing.sm
                            : 0,
                      ),
                      child: _LibraryChip(
                        selected: widget.selectedFilter == filter,
                        onTap: () => widget.onFilterChanged(
                          widget.selectedFilter == filter ? null : filter,
                        ),
                        child: Text(
                          filter.label,
                          style: TextStyle(
                            color: widget.selectedFilter == filter
                                ? AppColors.primary
                                : AppColors.textSecondary,
                            fontSize: AppFontSize.md,
                            fontWeight: widget.selectedFilter == filter
                                ? FontWeight.w600
                                : FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}

/// Reusable filter/folder chip used inside [LibraryFilterChips].
class LibraryChip extends StatelessWidget {
  const LibraryChip({
    super.key,
    required this.selected,
    required this.onTap,
    required this.child,
  });

  final bool selected;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) => _LibraryChip(
        selected: selected,
        onTap: onTap,
        child: child,
      );
}

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

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: Container(
          height: _height,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected
                ? AppColors.primary.withValues(alpha: 0.2)
                : AppColors.surfaceLight.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(AppRadius.sm),
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
