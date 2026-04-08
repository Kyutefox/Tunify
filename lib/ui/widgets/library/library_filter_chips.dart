import 'package:flutter/material.dart';

import 'package:tunify/core/constants/app_icons.dart';
import 'package:tunify/ui/screens/shared/library/library_app_bar.dart';
import 'package:tunify/ui/theme/app_colors.dart';
import 'package:tunify/ui/theme/design_tokens.dart';
import 'package:tunify/ui/theme/desktop_tokens.dart';
import 'package:tunify/ui/theme/app_colors_scheme.dart';

class LibraryFilterChips extends StatefulWidget {
  const LibraryFilterChips({
    super.key,
    required this.selectedFilter,
    required this.onFilterChanged,
    this.folderName,
    this.onExitFolder,
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
    with TickerProviderStateMixin {
  // Drives the X clear-chip entrance/exit
  late final AnimationController _xCtrl = AnimationController(
    vsync: this,
    duration: AppDuration.normal,
    value: widget.selectedFilter != null ? 1.0 : 0.0,
  );

  // Drives the folder breadcrumb entrance/exit
  late final AnimationController _folderCtrl = AnimationController(
    vsync: this,
    duration: AppDuration.normal,
    value: widget.folderName != null ? 1.0 : 0.0,
  );

  Animation<double> _fade(AnimationController ctrl) => CurvedAnimation(
        parent: ctrl,
        curve: AppCurves.decelerate,
        reverseCurve: AppCurves.standard,
      );

  Animation<Offset> _slide(AnimationController ctrl) =>
      Tween<Offset>(begin: const Offset(-1.0, 0.0), end: Offset.zero).animate(
        CurvedAnimation(
          parent: ctrl,
          curve: AppCurves.decelerate,
          reverseCurve: AppCurves.standard,
        ),
      );

  late final Animation<double> _xFade = _fade(_xCtrl);
  late final Animation<Offset> _xSlide = _slide(_xCtrl);
  late final Animation<double> _folderFade = _fade(_folderCtrl);
  late final Animation<Offset> _folderSlide = _slide(_folderCtrl);

  @override
  void didUpdateWidget(LibraryFilterChips old) {
    super.didUpdateWidget(old);

    // X chip
    final hadFilter = old.selectedFilter != null;
    final hasFilter = widget.selectedFilter != null;
    if (!hadFilter && hasFilter) {
      _xCtrl.forward();
    } else if (hadFilter && !hasFilter) {
      _xCtrl.reverse();
    }

    // Folder breadcrumb
    final hadFolder = old.folderName != null;
    final hasFolder = widget.folderName != null;
    if (!hadFolder && hasFolder) {
      _folderCtrl.forward();
    } else if (hadFolder && !hasFolder) {
      _folderCtrl.reverse();
    }
  }

  @override
  void dispose() {
    _xCtrl.dispose();
    _folderCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final effectiveFilters = widget.filters ??
        LibraryFilter.values.where((f) => f != LibraryFilter.all).toList();

    // Folder breadcrumb mode — animated same as X chip
    if (widget.folderName != null && widget.onExitFolder != null) {
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.zero,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // X close chip — slides in from left
            SizeTransition(
              sizeFactor: _folderFade,
              axis: Axis.horizontal,
              axisAlignment: -1,
              child: Padding(
                padding: const EdgeInsets.only(right: AppSpacing.sm),
                child: ClipRect(
                  child: SlideTransition(
                    position: _folderSlide,
                    child: FadeTransition(
                      opacity: _folderFade,
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
                  ),
                ),
              ),
            ),
            // Folder name chip — slides in from left with slight delay feel
            SizeTransition(
              sizeFactor: _folderFade,
              axis: Axis.horizontal,
              axisAlignment: -1,
              child: ClipRect(
                child: SlideTransition(
                  position: _folderSlide,
                  child: FadeTransition(
                    opacity: _folderFade,
                    child: _LibraryChip(
                      selected: true,
                      onTap: widget.onExitFolder!,
                      child: Text(
                        widget.folderName!,
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: AppTokens.of(context).font.md,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
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

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: EdgeInsets.zero,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // X chip: slot width animated via SizeTransition (horizontal),
          // content slides in from the left and fades in simultaneously.
          SizeTransition(
            sizeFactor: _xFade,
            axis: Axis.horizontal,
            axisAlignment: -1, // anchor to left edge
            child: Padding(
              padding: const EdgeInsets.only(right: AppSpacing.sm),
              child: ClipRect(
                child: SlideTransition(
                  position: _xSlide,
                  child: FadeTransition(
                    opacity: _xFade,
                    child: _LibraryChip(
                      selected: true,
                      onTap: () => widget.onFilterChanged(null),
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

          // Filter chips
          for (final filter in effectiveFilters)
            Padding(
              padding: EdgeInsets.only(
                right: filter != effectiveFilters.last ? AppSpacing.sm : 0,
              ),
              child: _FilterChip(
                filter: filter,
                selected: widget.selectedFilter == filter,
                onTap: () => widget.onFilterChanged(
                  widget.selectedFilter == filter ? null : filter,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// A filter chip that animates its own selected/deselected state.
class _FilterChip extends StatefulWidget {
  const _FilterChip({
    required this.filter,
    required this.selected,
    required this.onTap,
  });
  final LibraryFilter filter;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<_FilterChip> createState() => _FilterChipState();
}

class _FilterChipState extends State<_FilterChip>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: AppDuration.fast,
    value: widget.selected ? 1.0 : 0.0,
  );
  late final Animation<double> _t = CurvedAnimation(
    parent: _ctrl,
    curve: AppCurves.decelerate,
    reverseCurve: AppCurves.standard,
  );

  @override
  void didUpdateWidget(_FilterChip old) {
    super.didUpdateWidget(old);
    if (widget.selected != old.selected) {
      widget.selected ? _ctrl.forward() : _ctrl.reverse();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _t,
      builder: (context, _) {
        final t = _t.value;
        return _LibraryChip(
          selected: widget.selected,
          onTap: widget.onTap,
          animT: t,
          child: Text(
            widget.filter.label,
            style: TextStyle(
              color: Color.lerp(AppColorsScheme.of(context).textSecondary,
                  AppColors.primary, t),
              fontSize: AppTokens.of(context).font.md,
              fontWeight: t > 0.5 ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        );
      },
    );
  }
}

/// Reusable filter/folder chip.
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
  Widget build(BuildContext context) =>
      _LibraryChip(selected: selected, onTap: onTap, child: child);
}

class _LibraryChip extends StatelessWidget {
  const _LibraryChip({
    required this.selected,
    required this.onTap,
    required this.child,
    this.animT,
  });

  final bool selected;
  final VoidCallback onTap;
  final Widget child;
  final double? animT;

  static const double _mobileHeight = 32;
  static const double _desktopHeight = 36;

  @override
  Widget build(BuildContext context) {
    final t = AppTokens.of(context);
    final chipHeight = t.isDesktop ? _desktopHeight : _mobileHeight;
    final hPad = t.isDesktop ? t.spacing.md : AppSpacing.md;
    final tv = animT ?? (selected ? 1.0 : 0.0);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        mouseCursor: SystemMouseCursors.click,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: Container(
          height: chipHeight,
          padding: EdgeInsets.symmetric(horizontal: hPad),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Color.lerp(
              AppColorsScheme.of(context).surfaceLight.withValues(alpha: 0.8),
              AppColors.primary.withValues(alpha: 0.2),
              tv,
            ),
            borderRadius: BorderRadius.circular(AppRadius.sm),
            border: Border.all(
              color: Color.lerp(Colors.transparent, AppColors.primary, tv)!,
              width: 1,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}
