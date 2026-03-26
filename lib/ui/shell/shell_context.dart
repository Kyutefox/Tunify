import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tunify/ui/shell/desktop_right_sidebar.dart';
import 'package:tunify/ui/shell/desktop_sidebar.dart';

/// Injected by both [MobileShell] and [DesktopShell] so any descendant widget
/// can cheaply ask "am I being rendered inside the desktop layout?"
class ShellContext extends InheritedWidget {
  const ShellContext({
    super.key,
    required this.isDesktop,
    this.onPushDetail,
    this.onOpenBrowse,
    required super.child,
  });

  final bool isDesktop;
  final void Function(Widget page)? onPushDetail;
  final VoidCallback? onOpenBrowse;

  /// True when the app is running on a desktop OS (macOS, Windows, or Linux).
  /// Use this where [BuildContext] is unavailable; otherwise prefer [isDesktopOf].
  static bool get isDesktopPlatform =>
      defaultTargetPlatform == TargetPlatform.macOS ||
      defaultTargetPlatform == TargetPlatform.windows ||
      defaultTargetPlatform == TargetPlatform.linux;

  static bool isDesktopOf(BuildContext context) {
    return context
            .dependOnInheritedWidgetOfExactType<ShellContext>()
            ?.isDesktop ??
        false;
  }

  static bool pushDetail(BuildContext context, Widget page) {
    final push = context
        .dependOnInheritedWidgetOfExactType<ShellContext>()
        ?.onPushDetail;
    if (push == null) return false;
    push(page);
    return true;
  }

  static bool openBrowse(BuildContext context) {
    final onOpenBrowse = context
        .dependOnInheritedWidgetOfExactType<ShellContext>()
        ?.onOpenBrowse;
    if (onOpenBrowse == null) return false;
    onOpenBrowse();
    return true;
  }

  /// Computes the exact inner content-panel width on desktop, accounting for
  /// shell gaps, left sidebar, right sidebar (if open), and horizontal padding.
  ///
  /// [screenWidth]      — from MediaQuery.sizeOf(context).width
  /// [rightSidebarOpen] — whether the right sidebar slot is in the Row
  /// [hPad]             — horizontal padding applied inside the content panel
  static double desktopContentInnerWidth({
    required double screenWidth,
    required bool rightSidebarOpen,
    required double hPad,
  }) {
    const gap = 8.0;
    final sidebarSlot =
        rightSidebarOpen ? kDesktopRightSidebarWidth + gap : 0.0;
    return screenWidth -
        gap * 2 -
        kDesktopSidebarWidth -
        gap -
        sidebarSlot -
        hPad * 2;
  }

  @override
  bool updateShouldNotify(ShellContext old) =>
      isDesktop != old.isDesktop ||
      onPushDetail != old.onPushDetail ||
      onOpenBrowse != old.onOpenBrowse;
}

/// Computes the responsive column count and max content width used by all
/// home/library section rows. Call once per build, pass results down.
class ContentLayout {
  const ContentLayout({
    required this.cols,
    required this.maxWidth,
    required this.hPad,
  });

  final int cols;
  final double maxWidth;
  final double hPad;

  /// Resolves layout for the current context + ref.
  /// [itemWidth] is the approximate width of one column item (default 160).
  static ContentLayout of(
    BuildContext context,
    WidgetRef ref, {
    double itemWidth = 160,
    int minCols = 2,
    int maxCols = 5,
  }) {
    final isDesktop = ShellContext.isDesktopOf(context);
    final hPad = isDesktop ? 28.0 : 16.0; // DesktopSpacing.lg : AppSpacing.base
    final screenW = MediaQuery.sizeOf(context).width;

    final double maxWidth;
    final int cols;
    if (isDesktop) {
      final rightOpen = ref.watch(rightSidebarTabProvider) != null;
      maxWidth = ShellContext.desktopContentInnerWidth(
        screenWidth: screenW,
        rightSidebarOpen: rightOpen,
        hPad: hPad,
      );
      cols = (maxWidth / itemWidth).floor().clamp(minCols, maxCols);
    } else {
      maxWidth = screenW - hPad * 2;
      cols = minCols;
    }

    return ContentLayout(cols: cols, maxWidth: maxWidth, hPad: hPad);
  }
}
