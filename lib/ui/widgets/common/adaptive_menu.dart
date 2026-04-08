import 'package:flutter/material.dart';

import 'package:tunify/ui/widgets/common/sheet.dart';

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
  final List<AppMenuEntry>? subEntries;
  final bool isDivider;

  static void _noop() {}
}

void showAdaptiveMenu(
  BuildContext context, {
  String? title,
  Widget? header,
  required List<AppMenuEntry> entries,
  Rect? anchorRect,
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
        children: [
          if (header != null) header!,
          for (final entry in entries)
            if (!entry.isDivider)
              SheetOptionTile(
                icon: entry.icon,
                label: entry.label,
                onTap: () {
                  Navigator.of(context).pop();
                  entry.onTap();
                },
              ),
        ],
      ),
    );
  }
}

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

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => showAdaptiveMenu(
        context,
        title: title,
        header: header,
        entries: entries,
      ),
      child: child,
    );
  }
}
