import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tunify/v2/core/constants/app_border_radius.dart';
import 'package:tunify/v2/core/constants/app_colors.dart';
import 'package:tunify/v2/core/constants/app_icons.dart';
import 'package:tunify/v2/core/constants/app_spacing.dart';
import 'package:tunify/v2/core/theme/app_text_styles.dart';
import 'package:tunify/v2/features/library/presentation/widgets/library_collection_artwork.dart';
import 'package:tunify/v2/features/library/domain/entities/library_details.dart';
import 'package:tunify/v2/features/library/domain/entities/library_item.dart';
import 'package:tunify/v2/features/library/domain/library_collection_catalog.dart';
import 'package:tunify/v2/features/library/presentation/constants/library_layout.dart';
import 'package:tunify/v2/features/library/presentation/library_list_invalidation.dart';
import 'package:tunify/v2/features/library/presentation/widgets/add_to_folder_sheet.dart';
import 'package:tunify/v2/features/library/presentation/constants/library_strings.dart';
import 'package:tunify/v2/features/library/presentation/providers/library_collection_providers.dart';
import 'package:tunify/v2/features/library/presentation/widgets/library_pin_toggle_row.dart';

/// Spotify-style bottom sheet for album / playlist / artist (⋯ on the dock).
void showCollectionOptionsSheet({
  required BuildContext context,
  required LibraryDetailsModel details,
}) {
  final browseId = details.item.ytmBrowseId?.trim() ?? '';
  final target = libraryCollectionApiTargetForItem(details.item);
  if (browseId.isEmpty || target == null) {
    return;
  }

  showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.bottomSheetSurface,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(AppBorderRadius.comfortable),
      ),
    ),
    builder: (_) => _CollectionOptionsSheetContent(
      hostContext: context,
      details: details,
      apiTarget: target,
      browseId: browseId,
    ),
  );
}

class _CollectionOptionsSheetContent extends ConsumerWidget {
  const _CollectionOptionsSheetContent({
    required this.hostContext,
    required this.details,
    required this.apiTarget,
    required this.browseId,
  });

  final BuildContext hostContext;
  final LibraryDetailsModel details;
  final String apiTarget;
  final String browseId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final key = (target: apiTarget, browseId: browseId);
    final savedAsync = ref.watch(libraryCollectionSavedProvider(key));

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
          _CollectionSheetHeader(details: details),
          const SizedBox(height: AppSpacing.lg),
          const Divider(
            height: 0.5,
            thickness: 0.5,
            color: AppColors.separator10,
          ),
          const SizedBox(height: AppSpacing.sm),
          _PrimaryCollectionRow(
            details: details,
            apiTarget: apiTarget,
            browseId: browseId,
            savedAsync: savedAsync,
          ),
          if (libraryItemSupportsFolderMembership(details.item))
            _OptionRow(
              icon: AppIcons.folder,
              label: 'Add to folder',
              onTap: () {
                Navigator.of(context).pop();
                showAddToFolderSheet(hostContext, ref, playlistId: details.item.id);
              },
            ),
          if (libraryItemSupportsPinToggle(details.item))
            LibraryPinToggleRow(item: details.item),
          _OptionRow(
            icon: AppIcons.share,
            label: 'Share',
            onTap: () => Navigator.of(context).pop(),
          ),
          _OptionRow(
            icon: AppIcons.download,
            label: 'Download',
            onTap: () => Navigator.of(context).pop(),
          ),
          if (details.type != LibraryDetailsType.artist &&
              details.type != LibraryDetailsType.staticPlaylist)
            _OptionRow(
              icon: AppIcons.personOutline,
              label: 'Go to artist',
              onTap: () => Navigator.of(context).pop(),
            ),
          _OptionRow(
            icon: AppIcons.queueMusic,
            label: 'Add to Queue',
            onTap: () => Navigator.of(context).pop(),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
      ),
    );
  }
}

class _CollectionSheetHeader extends StatelessWidget {
  const _CollectionSheetHeader({required this.details});

  final LibraryDetailsModel details;

  @override
  Widget build(BuildContext context) {
    final item = details.item;
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
            preferredImageUrl: details.heroImageUrl,
            size: LibraryLayout.sheetArtworkSize,
            borderRadius: radius,
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  details.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodyBold,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  details.subtitlePrimary,
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

class _PrimaryCollectionRow extends ConsumerStatefulWidget {
  const _PrimaryCollectionRow({
    required this.details,
    required this.apiTarget,
    required this.browseId,
    required this.savedAsync,
  });

  final LibraryDetailsModel details;
  final String apiTarget;
  final String browseId;
  final AsyncValue<bool> savedAsync;

  @override
  ConsumerState<_PrimaryCollectionRow> createState() =>
      _PrimaryCollectionRowState();
}

class _PrimaryCollectionRowState extends ConsumerState<_PrimaryCollectionRow> {
  bool _busy = false;

  Future<void> _toggle(bool currentlyInLibrary) async {
    if (_busy) {
      return;
    }
    setState(() => _busy = true);
    final gateway = ref.read(libraryCollectionGatewayProvider);
    final key = (target: widget.apiTarget, browseId: widget.browseId);
    final messenger = ScaffoldMessenger.maybeOf(context);
    try {
      final next = await gateway.mutate(
        op: currentlyInLibrary ? 'remove' : 'add',
        target: widget.apiTarget,
        browseId: widget.browseId,
        title: widget.details.title,
        coverUrl: widget.details.heroImageUrl ?? widget.details.item.imageUrl,
        description: widget.details.collectionDescription,
      );
      ref.invalidate(libraryCollectionSavedProvider(key));
      invalidateLibraryListCaches(ref);
      if (!mounted) {
        return;
      }
      messenger?.showSnackBar(
        SnackBar(
          content: Text(
            widget.details.type == LibraryDetailsType.artist
                ? (next ? LibraryStrings.following : 'Artist removed from your library')
                : (next ? 'Added to Your Library' : 'Removed from Your Library'),
          ),
        ),
      );
      Navigator.of(context).pop();
    } on Object catch (e) {
      messenger?.showSnackBar(
        SnackBar(content: Text('Could not update library ($e)')),
      );
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isArtist = widget.details.type == LibraryDetailsType.artist;
    final label = widget.savedAsync.when(
      data: (saved) {
        if (isArtist) {
          return saved ? LibraryStrings.following : LibraryStrings.follow;
        }
        return saved ? 'Remove from Your Library' : 'Add to Your Library';
      },
      loading: () => isArtist ? '…' : '…',
      error: (_, __) => isArtist ? LibraryStrings.follow : 'Add to Your Library',
    );

    final icon = isArtist ? AppIcons.personOutline : AppIcons.addCircle;

    return InkWell(
      onTap: _busy
          ? null
          : () {
              final saved = widget.savedAsync.maybeWhen(
                data: (v) => v,
                orElse: () => null,
              );
              if (saved == null && widget.savedAsync.isLoading) {
                return;
              }
              _toggle(saved ?? false);
            },
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
            if (_busy)
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
          ],
        ),
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
