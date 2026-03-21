import 'package:flutter/material.dart';

import '../../../config/app_icons.dart';
import '../../../ui/theme/app_colors.dart';
import '../../../ui/theme/design_tokens.dart';

/// Use this for a consistent horizontal gutter when building sheet content.
/// The sheet itself applies no content padding; content fills the sheet and
/// uses this constant where it wants left/right inset.
const double kSheetHorizontalPadding = AppSpacing.base;

/// Default vertical padding for sheet list items (tiles, options).
const double kSheetTileVerticalPadding = AppSpacing.md;

/// Optional tighter vertical padding (e.g. pass to [SheetOptionTile.verticalPadding] when needed).
const double kSheetTileVerticalPaddingCompact = AppSpacing.sm;

/// Single option row for sheets: icon + label, optional chevron. Same layout everywhere
/// (Create sheet, song options, folder/playlist options).
/// Set [showChevron] to true only when the item opens a new page; otherwise false.
class SheetOptionTile extends StatelessWidget {
  const SheetOptionTile({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.iconColor,
    this.labelColor,
    this.verticalPadding,
    this.showChevron = true,
  });

  final List<List<dynamic>> icon;
  final String label;
  final VoidCallback onTap;
  final Color? iconColor;
  final Color? labelColor;
  /// If null, uses [kSheetTileVerticalPadding] (12). Pass [kSheetTileVerticalPaddingCompact] (8) for tighter.
  final double? verticalPadding;
  /// True when this item opens a new page; false for in-place actions (e.g. Pin, Delete).
  final bool showChevron;

  @override
  Widget build(BuildContext context) {
    final iconColor = this.iconColor ?? AppColors.textSecondary;
    final labelColor = this.labelColor ?? AppColors.textPrimary;
    final vertical = verticalPadding ?? kSheetTileVerticalPadding;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: Padding(
          padding: EdgeInsets.symmetric(
            vertical: vertical,
            horizontal: 0,
          ),
          child: Row(
            children: [
              AppIcon(icon: icon, color: iconColor, size: 24),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: labelColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              if (showChevron)
                AppIcon(
                  icon: AppIcons.chevronRight,
                  color: AppColors.textMuted,
                  size: 20,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Reusable bottom sheet shell: no content padding. Content fills the sheet
/// and adjusts to its bounds; use [kSheetHorizontalPadding] in content where needed.
/// Only bottom safe area is applied so content doesn't draw under system UI.
class AppSheet extends StatelessWidget {
  const AppSheet({
    super.key,
    required this.child,
    this.showDragHandle = true,
    this.useSafeAreaBottom = true,
    this.maxHeight,
    this.showTopBorder = true,
  });

  final Widget child;
  final bool showDragHandle;
  final bool useSafeAreaBottom;
  final double? maxHeight;
  final bool showTopBorder;

  static const double _handleWidth = 40;
  static const double _handleHeight = 4;
  static const double _handleTopPadding = 12;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: maxHeight != null
          ? BoxConstraints(maxHeight: maxHeight!)
          : null,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppRadius.xxl),
        ),
        border: showTopBorder
            ? Border(
                top: BorderSide(
                  color: Colors.white.withValues(alpha: 0.08),
                  width: 1,
                ),
              )
            : null,
      ),
      padding: EdgeInsets.only(
        top: showDragHandle ? _handleTopPadding : 0,
        bottom: useSafeAreaBottom
            ? MediaQuery.of(context).padding.bottom
            : 0,
      ),
      child: Column(
        mainAxisSize: maxHeight != null ? MainAxisSize.max : MainAxisSize.min,
        children: [
          if (showDragHandle) ...[
            Container(
              width: _handleWidth,
              height: _handleHeight,
              decoration: BoxDecoration(
                color: AppColors.textMuted.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(AppRadius.xs),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
          if (maxHeight != null) Expanded(child: child) else child,
        ],
      ),
    );
  }
}

/// Draggable bottom sheet with the same visual shell; [builder] receives
/// a [ScrollController] for the main scrollable content.
/// Use [decoration] to override background (e.g. gradient); when non-null
/// it must include [borderRadius] and [border] for consistency.
class AppDraggableSheet extends StatelessWidget {
  const AppDraggableSheet({
    super.key,
    required this.builder,
    this.initialChildSize = 0.5,
    this.minChildSize = 0.25,
    this.maxChildSize = 0.9,
    this.showDragHandle = true,
    this.showTopBorder = true,
    this.decoration,
  });

  final Widget Function(ScrollController scrollController) builder;
  final double initialChildSize;
  final double minChildSize;
  final double maxChildSize;
  final bool showDragHandle;
  final bool showTopBorder;
  final BoxDecoration? decoration;

  static const double _handleWidth = 40;
  static const double _handleHeight = 4;
  static const double _handleTopPadding = 12;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: initialChildSize,
      minChildSize: minChildSize,
      maxChildSize: maxChildSize,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: decoration ??
              BoxDecoration(
                color: AppColors.surface,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppRadius.xxl),
                ),
                border: showTopBorder
                    ? Border(
                        top: BorderSide(
                          color: Colors.white.withValues(alpha: 0.08),
                          width: 1,
                        ),
                      )
                    : null,
              ),
          child: Column(
            children: [
              if (showDragHandle) ...[
                const SizedBox(height: _handleTopPadding),
                Container(
                  width: _handleWidth,
                  height: _handleHeight,
                  decoration: BoxDecoration(
                    color: AppColors.textMuted.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(AppRadius.xs),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
              ],
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).padding.bottom,
                  ),
                  child: builder(scrollController),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Shows a modal bottom sheet with [child] as the root—no [AppSheet] wrapper.
/// Use for widgets that already provide their own sheet chrome (e.g. drag handle,
/// background, padding), so you don't get a double sheet (shell within shell).
void showRawSheet(
  BuildContext context, {
  required Widget child,
  bool isDismissible = true,
  bool enableDrag = true,
}) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    isDismissible: isDismissible,
    enableDrag: enableDrag,
    backgroundColor: Colors.transparent,
    builder: (_) => child,
  );
}

/// Shows a modal bottom sheet using [AppSheet] with transparent background.
void showAppSheet(
  BuildContext context, {
  required Widget child,
  bool isScrollControlled = true,
  bool isDismissible = true,
  bool enableDrag = true,
  bool showDragHandle = true,
  bool useSafeAreaBottom = true,
  double? maxHeight,
}) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: isScrollControlled,
    isDismissible: isDismissible,
    enableDrag: enableDrag,
    backgroundColor: Colors.transparent,
    builder: (_) => AppSheet(
      showDragHandle: showDragHandle,
      useSafeAreaBottom: useSafeAreaBottom,
      maxHeight: maxHeight,
      child: child,
    ),
  );
}

/// Shows a modal bottom sheet using [AppDraggableSheet].
/// Pass [decoration] to override the sheet background (e.g. gradient).
void showAppDraggableSheet(
  BuildContext context, {
  required Widget Function(ScrollController scrollController) builder,
  double initialChildSize = 0.5,
  double minChildSize = 0.25,
  double maxChildSize = 0.9,
  bool isDismissible = true,
  bool enableDrag = true,
  BoxDecoration? decoration,
}) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    isDismissible: isDismissible,
    enableDrag: enableDrag,
    backgroundColor: Colors.transparent,
    builder: (_) => AppDraggableSheet(
      initialChildSize: initialChildSize,
      minChildSize: minChildSize,
      maxChildSize: maxChildSize,
      builder: builder,
      decoration: decoration,
    ),
  );
}
