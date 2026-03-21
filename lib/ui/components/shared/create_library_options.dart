import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../config/app_icons.dart';
import '../../../shared/providers/library_provider.dart';
import '../../screens/library/create_library_item_screen.dart';
import 'adaptive_menu.dart';

/// Shared logic for the "Create playlist / folder" flow.
///
/// [createPlaylist] and [createFolder] own the push-and-await-name pattern.
/// [showCreateLibraryOptions] shows an adaptive menu (sheet on mobile,
/// dropdown on desktop) — single call site for both platforms.
Future<void> createPlaylist(BuildContext context, WidgetRef ref) async {
  final name = await Navigator.of(context).push<String>(
    MaterialPageRoute<String>(
      builder: (_) => const CreateLibraryItemScreen(
        mode: CreateLibraryItemMode.createPlaylist,
      ),
    ),
  );
  if (name != null && name.trim().isNotEmpty) {
    await ref.read(libraryProvider.notifier).createPlaylist(name.trim());
  }
}

Future<void> createFolder(BuildContext context, WidgetRef ref) async {
  final name = await Navigator.of(context).push<String>(
    MaterialPageRoute<String>(
      builder: (_) => const CreateLibraryItemScreen(
        mode: CreateLibraryItemMode.createFolder,
      ),
    ),
  );
  if (name != null && name.trim().isNotEmpty) {
    await ref.read(libraryProvider.notifier).createFolder(name.trim());
  }
}

/// Shows an adaptive menu with "Create playlist" and "Create folder" options.
/// Mobile: bottom sheet. Desktop: dropdown anchored to [anchorRect].
void showCreateLibraryOptions(
  BuildContext context,
  WidgetRef ref, {
  Rect? anchorRect,
}) {
  showAdaptiveMenu(
    context,
    title: 'Create',
    anchorRect: anchorRect,
    entries: [
      AppMenuEntry(
        icon: AppIcons.playlistAdd,
        label: 'Create playlist',
        onTap: () => createPlaylist(context, ref),
      ),
      AppMenuEntry(
        icon: AppIcons.newFolder,
        label: 'Create folder',
        onTap: () => createFolder(context, ref),
      ),
    ],
  );
}

/// Legacy alias — kept so existing callers don't break.
void showCreateLibrarySheet(BuildContext context, WidgetRef ref) =>
    showCreateLibraryOptions(context, ref);
