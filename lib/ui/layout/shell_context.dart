import 'package:flutter/widgets.dart';

/// Injected by both [MobileShell] and [DesktopShell] so any descendant widget
/// can cheaply ask "am I being rendered inside the desktop layout?"
///
/// Usage:
/// ```dart
/// if (ShellContext.isDesktopOf(context)) { ... }
/// ```
class ShellContext extends InheritedWidget {
  const ShellContext({
    super.key,
    required this.isDesktop,
    this.onPushDetail,
    required super.child,
  });

  final bool isDesktop;

  /// On desktop, pushes [page] into the main content navigator (inside the
  /// content panel) rather than full-screen. Null on mobile — use
  /// [Navigator.of(context).push] directly there.
  final void Function(Widget page)? onPushDetail;

  /// Returns [true] when the nearest [ShellContext] is a desktop shell.
  /// Falls back to [false] if no ancestor [ShellContext] exists.
  static bool isDesktopOf(BuildContext context) {
    return context
            .dependOnInheritedWidgetOfExactType<ShellContext>()
            ?.isDesktop ??
        false;
  }

  /// On desktop, pushes [page] into the content navigator. Returns [false] if
  /// no [onPushDetail] handler is registered (mobile path).
  static bool pushDetail(BuildContext context, Widget page) {
    final push = context
        .dependOnInheritedWidgetOfExactType<ShellContext>()
        ?.onPushDetail;
    if (push == null) return false;
    push(page);
    return true;
  }

  @override
  bool updateShouldNotify(ShellContext old) =>
      isDesktop != old.isDesktop || onPushDetail != old.onPushDetail;
}
