import 'package:flutter/widgets.dart';

import '../desktop/desktop_right_sidebar.dart';
import '../desktop/desktop_sidebar.dart';

/// Injected by both [MobileShell] and [DesktopShell] so any descendant widget
/// can cheaply ask "am I being rendered inside the desktop layout?"
class ShellContext extends InheritedWidget {
  const ShellContext({
    super.key,
    required this.isDesktop,
    this.onPushDetail,
    required super.child,
  });

  final bool isDesktop;
  final void Function(Widget page)? onPushDetail;

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
    final sidebarSlot = rightSidebarOpen ? kDesktopRightSidebarWidth + gap : 0.0;
    return screenWidth - gap * 2 - kDesktopSidebarWidth - gap - sidebarSlot - hPad * 2;
  }

  @override
  bool updateShouldNotify(ShellContext old) =>
      isDesktop != old.isDesktop || onPushDetail != old.onPushDetail;
}
