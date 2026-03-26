import 'dart:async';

import 'package:flutter/material.dart';

import 'package:tunify/core/constants/app_icons.dart';
import 'package:tunify/ui/theme/app_colors.dart';
import 'package:tunify/ui/theme/design_tokens.dart';
import 'package:tunify/ui/shell/shell_context.dart';
import 'package:tunify/ui/widgets/common/sheet.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// Data model
// ═══════════════════════════════════════════════════════════════════════════════

/// A single item in an adaptive menu / sheet.
class AppMenuEntry {
  const AppMenuEntry({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
    this.showChevron = false,
    this.subEntries,
  }) : isDivider = false;

  const AppMenuEntry.divider()
      : icon = const [],
        label = '',
        onTap = _noop,
        color = null,
        showChevron = false,
        subEntries = null,
        isDivider = true;

  final List<List<dynamic>> icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;
  final bool showChevron;

  /// Non-null to show a hover-triggered submenu panel to the right.
  final List<AppMenuEntry>? subEntries;
  final bool isDivider;

  static void _noop() {}
}

// ═══════════════════════════════════════════════════════════════════════════════
// Public API
// ═══════════════════════════════════════════════════════════════════════════════

/// Shows a bottom sheet on mobile, a positioned dropdown panel on desktop.
void showAdaptiveMenu(
  BuildContext context, {
  String? title,
  Widget? header,
  required List<AppMenuEntry> entries,
  Rect? anchorRect,
  bool? forceDesktop,
}) {
  final isDesktop = forceDesktop ?? ShellContext.isDesktopPlatform;
  if (isDesktop) {
    _showDesktopDropdown(
      context,
      title: title,
      header: header,
      entries: entries,
      anchorRect: anchorRect,
    );
  } else {
    _showMobileSheet(context, title: title, header: header, entries: entries);
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Mobile sheet
// ═══════════════════════════════════════════════════════════════════════════════

void _showMobileSheet(
  BuildContext context, {
  String? title,
  Widget? header,
  required List<AppMenuEntry> entries,
}) {
  showAppSheet(
    context,
    child: _MenuSheetBody(title: title, header: header, entries: entries),
  );
}

class _MenuSheetBody extends StatelessWidget {
  const _MenuSheetBody({this.title, this.header, required this.entries});

  final String? title;
  final Widget? header;
  final List<AppMenuEntry> entries;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: kSheetHorizontalPadding),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (header != null) ...[
            header!,
            const SizedBox(height: AppSpacing.md),
            Divider(color: Colors.white.withValues(alpha: 0.08), height: 1),
            const SizedBox(height: AppSpacing.sm),
          ] else if (title != null) ...[
            Padding(
              padding: const EdgeInsets.only(
                  top: AppSpacing.sm, bottom: AppSpacing.md),
              child: Text(
                title!,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: AppFontSize.xxl,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
          for (final entry in entries)
            if (entry.isDivider)
              Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                child: Divider(
                    color: Colors.white.withValues(alpha: 0.08), height: 1),
              )
            else
              SheetOptionTile(
                icon: entry.icon,
                label: entry.label,
                iconColor: entry.color ?? AppColors.textSecondary,
                labelColor: entry.color ?? AppColors.textPrimary,
                showChevron: entry.showChevron || entry.subEntries != null,
                onTap: () {
                  Navigator.of(context).pop();
                  entry.onTap();
                },
              ),
          const SizedBox(height: AppSpacing.sm),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Desktop dropdown — constants
// ═══════════════════════════════════════════════════════════════════════════════

const double _kPanelWidth = 224.0;
const double _kSubPanelWidth = 212.0;
const double _kItemVertPad = 9.0;
const double _kItemHeight = 16.0 + _kItemVertPad * 2 + 2; // icon + pad + margin
const double _kPanelGap = 6.0;
const double _kScreenMargin = 8.0;
const Duration _kOpenDur = Duration(milliseconds: 150);
const Duration _kHoverDelay = Duration(milliseconds: 110);

BoxDecoration _panelDecoration() => BoxDecoration(
      color: const Color(0xFF1C1C1E),
      borderRadius: BorderRadius.circular(AppRadius.md),
      border: Border.all(
        color: Colors.white.withValues(alpha: 0.10),
        width: 0.5,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.55),
          blurRadius: 36,
          offset: const Offset(0, 12),
        ),
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.22),
          blurRadius: 6,
          offset: const Offset(0, 2),
        ),
      ],
    );

// ═══════════════════════════════════════════════════════════════════════════════
// Desktop dropdown — entry point
// ═══════════════════════════════════════════════════════════════════════════════

void _showDesktopDropdown(
  BuildContext context, {
  String? title,
  Widget? header,
  required List<AppMenuEntry> entries,
  Rect? anchorRect,
}) {
  final screenSize = MediaQuery.sizeOf(context);
  final effectiveRect = anchorRect ??
      Rect.fromCenter(
        center: Offset(screenSize.width / 2, screenSize.height / 2),
        width: 0,
        height: 0,
      );
  final overlay = Overlay.of(context, rootOverlay: true);
  late OverlayEntry entry;
  entry = OverlayEntry(
    builder: (_) => _DropdownOverlay(
      anchorRect: effectiveRect,
      title: title,
      header: header,
      entries: entries,
      onDismiss: () => entry.remove(),
    ),
  );
  overlay.insert(entry);
}

// ═══════════════════════════════════════════════════════════════════════════════
// Overlay widget — manages a stack of open panels
// ═══════════════════════════════════════════════════════════════════════════════

/// One open sub-panel level.
class _SubLevel {
  _SubLevel({
    required this.entries,
    required this.itemRect,
    required this.parentEntry,
  });

  final List<AppMenuEntry> entries;

  /// Screen rect of the item row that opened this level (used for positioning).
  final Rect itemRect;

  /// The entry that was hovered to open this level (used for active highlight).
  final AppMenuEntry parentEntry;
}

class _DropdownOverlay extends StatefulWidget {
  const _DropdownOverlay({
    required this.anchorRect,
    this.title,
    this.header,
    required this.entries,
    required this.onDismiss,
  });

  final Rect anchorRect;
  final String? title;
  final Widget? header;
  final List<AppMenuEntry> entries;
  final VoidCallback onDismiss;

  @override
  State<_DropdownOverlay> createState() => _DropdownOverlayState();
}

class _DropdownOverlayState extends State<_DropdownOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: _kOpenDur,
  )..forward();

  /// Open sub-panel stack. `_subLevels[0]` = first submenu from root,
  /// `_subLevels[1]` = submenu from `_subLevels[0]`, etc.
  final List<_SubLevel> _subLevels = [];

  /// Debounce timers keyed by parent-level index (0 = timer for first submenu).
  final Map<int, Timer> _timers = {};

  // ── Level management ──────────────────────────────────────────────────────

  /// Opens (or replaces) the submenu triggered from `parentLevel`.
  void _openLevel(int parentLevel, AppMenuEntry entry, Rect itemRect) {
    _timers[parentLevel]?.cancel();
    if (!mounted) return;
    setState(() {
      while (_subLevels.length > parentLevel) { _subLevels.removeLast(); }
      _subLevels.add(_SubLevel(
        entries: entry.subEntries!,
        itemRect: itemRect,
        parentEntry: entry,
      ));
    });
  }

  /// Schedules closing the submenu at `parentLevel` (and all deeper ones).
  void _scheduleClose(int parentLevel) {
    _timers[parentLevel]?.cancel();
    _timers[parentLevel] = Timer(_kHoverDelay, () {
      if (!mounted) return;
      setState(() {
        while (_subLevels.length > parentLevel) { _subLevels.removeLast(); }
      });
    });
  }

  /// Cancels close timers for `level` **and all ancestors** so that moving
  /// from a parent panel into a child panel keeps the entire chain alive.
  void _cancelClose(int level) {
    for (var i = 0; i <= level; i++) { _timers[i]?.cancel(); }
  }

  void _dismiss() {
    for (final t in _timers.values) { t.cancel(); }
    _ctrl.reverse().then((_) => widget.onDismiss());
  }

  @override
  void dispose() {
    for (final t in _timers.values) { t.cancel(); }
    _ctrl.dispose();
    super.dispose();
  }

  // ── Layout helpers ────────────────────────────────────────────────────────

  double _estimateH(List<AppMenuEntry> entries, {bool hasHeader = false}) {
    final items = entries.where((e) => !e.isDivider).length;
    final dividers = entries.where((e) => e.isDivider).length;
    return (items * _kItemHeight) +
        (dividers * 9.0) +
        (hasHeader ? 50.0 : 0.0) +
        8.0;
  }

  /// Positions the root panel below/above the trigger anchor.
  Offset _rootOrigin(Size screen, double panelH) {
    double top = widget.anchorRect.bottom + 4;
    if (top + panelH > screen.height - _kScreenMargin) {
      top = widget.anchorRect.top - panelH - 4;
    }
    double left = widget.anchorRect.right - _kPanelWidth;
    left = left.clamp(_kScreenMargin, screen.width - _kPanelWidth - _kScreenMargin);
    return Offset(left, top.clamp(_kScreenMargin, screen.height - _kScreenMargin));
  }

  /// Positions a sub-panel to the right/left of its trigger item row.
  Offset _subOrigin(Size screen, Rect itemRect, double panelH) {
    double left = itemRect.right + _kPanelGap;
    if (left + _kSubPanelWidth > screen.width - _kScreenMargin) {
      left = itemRect.left - _kSubPanelWidth - _kPanelGap;
    }
    left = left.clamp(_kScreenMargin, screen.width - _kSubPanelWidth - _kScreenMargin);
    double top = itemRect.top - 4;
    if (top + panelH > screen.height - _kScreenMargin) {
      top = screen.height - panelH - _kScreenMargin;
    }
    return Offset(left, top.clamp(_kScreenMargin, screen.height - _kScreenMargin));
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.sizeOf(context);

    // Which entries currently have their submenu open (for active highlight).
    final activeEntries = <AppMenuEntry>{
      for (final level in _subLevels) level.parentEntry,
    };

    final rootH = _estimateH(
      widget.entries,
      hasHeader: widget.header != null || widget.title != null,
    );
    final rootOrigin = _rootOrigin(screen, rootH);

    return Stack(
      children: [
        // Full-screen dismiss barrier.
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _dismiss,
          ),
        ),

        // Root panel.
        Positioned(
          left: rootOrigin.dx,
          top: rootOrigin.dy,
          width: _kPanelWidth,
          child: _AnimatedPanel(
            animation: _ctrl,
            scaleAlignment: Alignment.topRight,
            child: _MenuPanel(
              entries: widget.entries,
              title: widget.title,
              header: widget.header,
              activeEntries: activeEntries,
              onTap: (e) { e.onTap(); _dismiss(); },
              onSubHover: (e, r) => _openLevel(0, e, r),
              onSubLeave: () => _scheduleClose(0),
              onRegularHover: () {
                if (_subLevels.isNotEmpty) {
                  setState(_subLevels.clear);
                }
              },
            ),
          ),
        ),

        // Sub-panels (one per open level).
        for (var i = 0; i < _subLevels.length; i++)
          _buildSubPanel(screen, i, activeEntries),
      ],
    );
  }

  Widget _buildSubPanel(
      Size screen, int i, Set<AppMenuEntry> activeEntries) {
    final level = _subLevels[i];
    final panelH = _estimateH(level.entries);
    final origin = _subOrigin(screen, level.itemRect, panelH);

    return Positioned(
      left: origin.dx,
      top: origin.dy,
      width: _kSubPanelWidth,
      // MouseRegion on the panel itself so moving between item and panel
      // doesn't trigger the close timer.
      child: MouseRegion(
        onEnter: (_) => _cancelClose(i),
        onExit: (_) => _scheduleClose(i),
        child: TweenAnimationBuilder<double>(
          key: ValueKey(level.parentEntry.label),
          tween: Tween(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 130),
          curve: Curves.easeOutCubic,
          builder: (_, t, child) => Opacity(
            opacity: t.clamp(0.0, 1.0),
            child: Transform.scale(
              scale: 0.95 + 0.05 * t,
              alignment: Alignment.centerLeft,
              child: child,
            ),
          ),
          child: _MenuPanel(
            entries: level.entries,
            activeEntries: activeEntries,
            emptyLabel: 'No playlists yet',
            onTap: (e) { e.onTap(); _dismiss(); },
            onSubHover: (e, r) => _openLevel(i + 1, e, r),
            onSubLeave: () => _scheduleClose(i + 1),
            onRegularHover: () {
              if (_subLevels.length > i + 1) {
                setState(() {
                  while (_subLevels.length > i + 1) { _subLevels.removeLast(); }
                });
              }
            },
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Panel widget — renders a list of entries inside a styled container
// ═══════════════════════════════════════════════════════════════════════════════

class _MenuPanel extends StatelessWidget {
  const _MenuPanel({
    required this.entries,
    this.title,
    this.header,
    required this.activeEntries,
    required this.onTap,
    required this.onSubHover,
    required this.onSubLeave,
    required this.onRegularHover,
    this.emptyLabel,
  });

  final List<AppMenuEntry> entries;
  final String? title;
  final Widget? header;
  final Set<AppMenuEntry> activeEntries;
  final void Function(AppMenuEntry) onTap;
  final void Function(AppMenuEntry, Rect) onSubHover;
  final VoidCallback onSubLeave;

  /// Called when the mouse enters a non-submenu item — the overlay uses this
  /// to close any deeper panels that are currently open.
  final VoidCallback onRegularHover;
  final String? emptyLabel;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
      constraints: const BoxConstraints(maxHeight: 360),
      decoration: _panelDecoration(),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (header != null) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
                  child: header!,
                ),
                const _PanelDivider(),
              ] else if (title != null) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 5),
                  child: Text(
                    title!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: AppFontSize.xs,
                      fontWeight: FontWeight.w600,
                      letterSpacing: AppLetterSpacing.normal,
                    ),
                  ),
                ),
                const _PanelDivider(),
              ],
              if (entries.isEmpty && emptyLabel != null)
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  child: Text(
                    emptyLabel!,
                    style: const TextStyle(
                        color: AppColors.textMuted, fontSize: AppFontSize.md),
                  ),
                ),
              for (final e in entries)
                if (e.isDivider)
                  const _PanelDivider()
                else
                  _MenuItem(
                    entry: e,
                    isActive: activeEntries.contains(e),
                    onTap: () => onTap(e),
                    onSubHover: e.subEntries != null
                        ? (rect) => onSubHover(e, rect)
                        : null,
                    onSubLeave: e.subEntries != null ? onSubLeave : null,
                    onRegularHover:
                        e.subEntries == null ? onRegularHover : null,
                  ),
            ],
          ),
        ),
      ),
    ));
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Menu item — hover-highlighted row with optional active state
// ═══════════════════════════════════════════════════════════════════════════════

class _MenuItem extends StatefulWidget {
  const _MenuItem({
    required this.entry,
    required this.isActive,
    required this.onTap,
    this.onSubHover,
    this.onSubLeave,
    this.onRegularHover,
  });

  final AppMenuEntry entry;
  final bool isActive;
  final VoidCallback onTap;
  final void Function(Rect)? onSubHover;
  final VoidCallback? onSubLeave;
  final VoidCallback? onRegularHover;

  @override
  State<_MenuItem> createState() => _MenuItemState();
}

class _MenuItemState extends State<_MenuItem> {
  bool _hovered = false;
  final _key = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final e = widget.entry;
    final color = e.color ?? AppColors.textPrimary;
    final highlighted = _hovered || widget.isActive;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) {
        if (!mounted) return;
        setState(() => _hovered = true);
        if (widget.onSubHover != null) {
          final box = _key.currentContext?.findRenderObject() as RenderBox?;
          if (box != null && box.hasSize) {
            widget.onSubHover!(box.localToGlobal(Offset.zero) & box.size);
          }
        } else {
          widget.onRegularHover?.call();
        }
      },
      onExit: (_) {
        if (!mounted) return;
        setState(() => _hovered = false);
        widget.onSubLeave?.call();
      },
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: e.subEntries != null ? null : widget.onTap,
        child: AnimatedContainer(
          key: _key,
          duration: const Duration(milliseconds: 80),
          margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
          padding: EdgeInsets.symmetric(
              horizontal: 10, vertical: _kItemVertPad),
          decoration: BoxDecoration(
            color: highlighted
                ? Colors.white.withValues(alpha: 0.07)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadius.xs),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: Center(
                  child: AppIcon(icon: e.icon, color: color, size: 15),
                ),
              ),
              const SizedBox(width: AppSpacing.sm + 2),
              Expanded(
                child: Text(
                  e.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: color,
                    fontSize: AppFontSize.md,
                    fontWeight: FontWeight.w500,
                    height: AppLineHeight.normal,
                  ),
                ),
              ),
              if (e.subEntries != null || e.showChevron) ...[
                const SizedBox(width: AppSpacing.xs + 2),
                AppIcon(
                  icon: AppIcons.chevronRight,
                  color: AppColors.textMuted,
                  size: 12,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Animated panel wrapper (for root panel open animation)
// ═══════════════════════════════════════════════════════════════════════════════

class _AnimatedPanel extends StatelessWidget {
  const _AnimatedPanel({
    required this.animation,
    required this.child,
    this.scaleAlignment = Alignment.topLeft,
  });

  final Animation<double> animation;
  final Widget child;
  final Alignment scaleAlignment;

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
      child: ScaleTransition(
        scale: Tween<double>(begin: 0.94, end: 1.0).animate(
          CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
        ),
        alignment: scaleAlignment,
        child: child,
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Divider
// ═══════════════════════════════════════════════════════════════════════════════

class _PanelDivider extends StatelessWidget {
  const _PanelDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 3),
      height: 0.5,
      color: Colors.white.withValues(alpha: 0.08),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// AdaptiveMenuAnchor — wrap any widget to trigger the menu on tap
// ═══════════════════════════════════════════════════════════════════════════════

/// Wraps [child] so that tapping it opens an adaptive menu.
/// On desktop the anchor rect is computed automatically for correct positioning.
///
/// ```dart
/// AdaptiveMenuAnchor(
///   entries: [AppMenuEntry(icon: AppIcons.edit, label: 'Edit', onTap: () {})],
///   child: AppIconButton(icon: ..., onPressed: null),
/// )
/// ```
class AdaptiveMenuAnchor extends StatelessWidget {
  const AdaptiveMenuAnchor({
    super.key,
    required this.entries,
    required this.child,
    this.title,
    this.header,
  });

  final List<AppMenuEntry> entries;
  final Widget child;
  final String? title;
  final Widget? header;

  void _onTap(BuildContext context) {
    final box = context.findRenderObject() as RenderBox?;
    Rect? anchorRect;
    if (box != null && box.hasSize) {
      anchorRect = box.localToGlobal(Offset.zero) & box.size;
    }
    showAdaptiveMenu(
      context,
      title: title,
      header: header,
      entries: entries,
      anchorRect: anchorRect,
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _onTap(context),
      child: child,
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
