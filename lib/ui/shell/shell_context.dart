import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Mobile-only compatibility context.
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

  static bool get isDesktopPlatform => false;

  static bool isDesktopOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<ShellContext>()?.isDesktop ??
        false;
  }

  static bool pushDetail(BuildContext context, Widget page) {
    final push =
        context.dependOnInheritedWidgetOfExactType<ShellContext>()?.onPushDetail;
    if (push == null) return false;
    push(page);
    return true;
  }

  static bool openBrowse(BuildContext context) {
    final open =
        context.dependOnInheritedWidgetOfExactType<ShellContext>()?.onOpenBrowse;
    if (open == null) return false;
    open();
    return true;
  }

  static double desktopContentInnerWidth({
    required double screenWidth,
    required bool rightSidebarOpen,
    required double hPad,
  }) {
    return screenWidth - hPad * 2;
  }

  @override
  bool updateShouldNotify(ShellContext old) =>
      isDesktop != old.isDesktop ||
      onPushDetail != old.onPushDetail ||
      onOpenBrowse != old.onOpenBrowse;
}

class ContentLayout {
  const ContentLayout({
    required this.cols,
    required this.maxWidth,
    required this.hPad,
  });

  final int cols;
  final double maxWidth;
  final double hPad;

  static ContentLayout of(
    BuildContext context,
    WidgetRef ref, {
    double itemWidth = 160,
    int minCols = 2,
    int maxCols = 5,
  }) {
    final hPad = 16.0;
    final screenW = MediaQuery.sizeOf(context).width;
    final maxWidth = screenW - hPad * 2;
    final cols = (maxWidth / itemWidth).floor().clamp(minCols, maxCols);
    return ContentLayout(cols: cols, maxWidth: maxWidth, hPad: hPad);
  }
}
