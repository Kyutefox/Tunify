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
    required super.child,
  });

  final bool isDesktop;

  /// Returns [true] when the nearest [ShellContext] is a desktop shell.
  /// Falls back to [false] if no ancestor [ShellContext] exists.
  static bool isDesktopOf(BuildContext context) {
    return context
            .dependOnInheritedWidgetOfExactType<ShellContext>()
            ?.isDesktop ??
        false;
  }

  @override
  bool updateShouldNotify(ShellContext old) => isDesktop != old.isDesktop;
}
