import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tunify/v2/core/constants/app_border_radius.dart';
import 'package:tunify/v2/core/constants/app_colors.dart';
import 'package:tunify/v2/core/constants/app_icons.dart';
import 'package:tunify/v2/core/constants/app_spacing.dart';
import 'package:tunify/v2/core/theme/app_text_styles.dart';
import 'package:tunify/v2/features/library/presentation/widgets/library_collection_artwork.dart';
import 'package:tunify/v2/features/library/domain/entities/library_item.dart';
import 'package:tunify/v2/features/library/domain/library_collection_catalog.dart';
import 'package:tunify/v2/features/library/presentation/constants/library_layout.dart';
import 'package:tunify/v2/features/library/presentation/widgets/add_to_folder_sheet.dart';
import 'package:tunify/v2/features/library/presentation/widgets/library_pin_toggle_row.dart';
import 'package:tunify/v2/features/library/presentation/widgets/library_item_sheet_quick_actions.dart';

/// Shows a Spotify-style "more options" bottom sheet for a library item.
List<_OptionAction> _libraryItemOptionsSecondaryActions(
  LibraryItem item, {
  required LibraryItemSheetQuickRowKind quickKind,
}) {
  final actions = <_OptionAction>[];
  final useQuickRow = quickKind != LibraryItemSheetQuickRowKind.none;
  final omitShare = item.isEphemeralHomeTrackShelf;

  if (!useQuickRow) {
    if (!omitShare) {
      actions.add(_OptionAction(icon: AppIcons.share, label: 'Share'));
    }
    actions.add(_OptionAction(icon: AppIcons.download, label: 'Download'));
  } else if (quickKind != LibraryItemSheetQuickRowKind.remoteCollection &&
      quickKind != LibraryItemSheetQuickRowKind.ephemeralHomeTrackShelf) {
    actions.add(_OptionAction(icon: AppIcons.share, label: 'Share'));
  }

  if (item.kind != LibraryItemKind.artist &&
      item.kind != LibraryItemKind.podcast &&
      item.kind != LibraryItemKind.album &&
      item.kind != LibraryItemKind.playlist) {
    actions.add(
      _OptionAction(icon: AppIcons.personOutline, label: 'Go to artist'),
    );
  }

  actions.add(_OptionAction(icon: AppIcons.queueMusic, label: 'Add to Queue'));

  if (item.kind != LibraryItemKind.playlist) {
    actions.add(
      _OptionAction(icon: AppIcons.playlistAddIcon, label: 'Add to playlist'),
    );
  }

  actions.add(
    _OptionAction(icon: AppIcons.equalizer, label: 'Show Tunify Code'),
  );
  return actions;
}

void showLibraryItemOptionsSheet(
  BuildContext context,
  LibraryItem item, {
  String? libraryListScopeFolderId,
}) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.bottomSheetSurface,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(AppBorderRadius.comfortable),
      ),
    ),
    builder: (_) => _LibraryItemOptionsSheet(
      hostContext: context,
      item: item,
      libraryListScopeFolderId: libraryListScopeFolderId,
    ),
  );
}

class _LibraryItemOptionsSheet extends ConsumerWidget {
  const _LibraryItemOptionsSheet({
    required this.hostContext,
    required this.item,
    this.libraryListScopeFolderId,
  });

  final BuildContext hostContext;
  final LibraryItem item;
  final String? libraryListScopeFolderId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final quickKind = libraryItemSheetQuickRowKindFor(item);
    final showPinRow = libraryItemSupportsPinToggle(item) &&
        quickKind == LibraryItemSheetQuickRowKind.none;

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: AppSpacing.md),
          Container(
            width: LibraryLayout.sheetHandleWidth,
            height: LibraryLayout.sheetHandleHeight,
            decoration: BoxDecoration(
              color: AppColors.silver.withValues(alpha: 0.4),
              borderRadius:
                  BorderRadius.circular(LibraryLayout.sheetHandleRadius),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          _ItemHeader(item: item),
          const SizedBox(height: AppSpacing.lg),
          const Divider(
            height: 0.5,
            thickness: 0.5,
            color: AppColors.separator10,
          ),
          const SizedBox(height: AppSpacing.sm),
          if (quickKind != LibraryItemSheetQuickRowKind.none) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
              child: LibraryItemSheetQuickActionRow(
                kind: quickKind,
                item: item,
                hostContext: hostContext,
                libraryListScopeFolderId: libraryListScopeFolderId,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            const Divider(
              height: 0.5,
              thickness: 0.5,
              color: AppColors.separator10,
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
          if (libraryItemSupportsFolderMembership(item))
            _OptionRow(
              icon: AppIcons.folder,
              label: 'Add to folder',
              onTap: () {
                Navigator.of(context).pop();
                showAddToFolderSheet(hostContext, ref, playlistId: item.id);
              },
            ),
          if (showPinRow)
            LibraryPinToggleRow(
              item: item,
              libraryListScopeFolderId: libraryListScopeFolderId,
            ),
          ..._libraryItemOptionsSecondaryActions(
            item,
            quickKind: quickKind,
          ).map(
            (a) => _OptionRow(
              icon: a.icon,
              label: a.label,
              onTap: () => Navigator.of(context).pop(),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
      ),
    );
  }
}

class _ItemHeader extends StatelessWidget {
  const _ItemHeader({required this.item});

  final LibraryItem item;

  @override
  Widget build(BuildContext context) {
    final isCircular = item.kind == LibraryItemKind.artist;
    final radius = isCircular
        ? LibraryLayout.sheetArtworkSize / 2
        : AppBorderRadius.subtle;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: Row(
        children: [
          LibraryCollectionArtwork(
            item: item,
            size: LibraryLayout.sheetArtworkSize,
            borderRadius: radius,
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodyBold,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  item.subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.small,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OptionRow extends StatelessWidget {
  const _OptionRow({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final List<List<dynamic>> icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xl,
          vertical: AppSpacing.lg,
        ),
        child: Row(
          children: [
            AppIcon(
              icon: icon,
              size: 24,
              color: AppColors.silver,
            ),
            const SizedBox(width: AppSpacing.xl),
            Expanded(
              child: Text(
                label,
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OptionAction {
  const _OptionAction({required this.icon, required this.label});

  final List<List<dynamic>> icon;
  final String label;
}
