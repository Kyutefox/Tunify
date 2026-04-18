import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tunify/v2/core/constants/app_colors.dart';
import 'package:tunify/v2/core/constants/app_icons.dart';
import 'package:tunify/v2/core/constants/app_spacing.dart';
import 'package:tunify/v2/core/theme/app_text_styles.dart';
import 'package:tunify/v2/features/auth/presentation/providers/auth_providers.dart';
import 'package:tunify/v2/features/library/data/library_collection_gateway.dart';
import 'package:tunify/v2/features/library/domain/entities/library_item.dart';
import 'package:tunify/v2/features/library/domain/library_collection_catalog.dart';
import 'package:tunify/v2/features/library/presentation/constants/library_strings.dart';
import 'package:tunify/v2/features/library/presentation/library_list_invalidation.dart';
import 'package:tunify/v2/features/library/presentation/providers/library_collection_providers.dart';
import 'package:tunify/v2/features/library/presentation/providers/library_providers.dart';

/// Layout of the first horizontal action row on the library item options sheet.
enum LibraryItemSheetQuickRowKind {
  none,
  inLibraryCollection,
  remoteCollection,
  ownedPlaylistOrFolder,
  ephemeralHomeTrackShelf,
}

LibraryItemSheetQuickRowKind libraryItemSheetQuickRowKindFor(LibraryItem item) {
  if (item.isEphemeralHomeTrackShelf) {
    return LibraryItemSheetQuickRowKind.ephemeralHomeTrackShelf;
  }
  if (item.systemArtwork != null) {
    return LibraryItemSheetQuickRowKind.none;
  }
  if (item.kind == LibraryItemKind.folder) {
    return LibraryItemSheetQuickRowKind.ownedPlaylistOrFolder;
  }
  if (item.kind == LibraryItemKind.playlist && item.isUserOwnedPlaylist) {
    return LibraryItemSheetQuickRowKind.ownedPlaylistOrFolder;
  }
  final target = libraryCollectionApiTargetForItem(item);
  final browseId = item.ytmBrowseId?.trim();
  final hasRemoteCollection = target != null &&
      browseId != null &&
      browseId.isNotEmpty;
  if (!hasRemoteCollection) {
    return LibraryItemSheetQuickRowKind.none;
  }
  if (item.isInServerLibrary) {
    return LibraryItemSheetQuickRowKind.inLibraryCollection;
  }
  return LibraryItemSheetQuickRowKind.remoteCollection;
}

/// Three compact actions (v1 song sheet pattern) for library tiles.
class LibraryItemSheetQuickActionRow extends ConsumerWidget {
  const LibraryItemSheetQuickActionRow({
    super.key,
    required this.kind,
    required this.item,
    required this.hostContext,
    this.libraryListScopeFolderId,
  });

  final LibraryItemSheetQuickRowKind kind;
  final LibraryItem item;
  final BuildContext hostContext;
  final String? libraryListScopeFolderId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      children: [
        Expanded(
          child: _QuickCircleButton(
            icon: AppIcons.download,
            iconColor: AppColors.silver,
            label: 'Download',
            onTap: () => Navigator.of(context).pop(),
          ),
        ),
        Expanded(
          child: switch (kind) {
            LibraryItemSheetQuickRowKind.inLibraryCollection ||
            LibraryItemSheetQuickRowKind.remoteCollection =>
              _QuickCollectionSaveSlot(
                item: item,
                libraryListScopeFolderId: libraryListScopeFolderId,
              ),
            LibraryItemSheetQuickRowKind.ownedPlaylistOrFolder =>
              _QuickDeleteSlot(
                item: item,
                hostContext: hostContext,
                libraryListScopeFolderId: libraryListScopeFolderId,
              ),
            LibraryItemSheetQuickRowKind.ephemeralHomeTrackShelf =>
              const SizedBox.shrink(),
            LibraryItemSheetQuickRowKind.none => const SizedBox.shrink(),
          },
        ),
        Expanded(
          child: switch (kind) {
            LibraryItemSheetQuickRowKind.inLibraryCollection ||
            LibraryItemSheetQuickRowKind.ownedPlaylistOrFolder =>
              _QuickPinSlot(
                item: item,
                libraryListScopeFolderId: libraryListScopeFolderId,
              ),
            LibraryItemSheetQuickRowKind.remoteCollection => _QuickCircleButton(
                icon: AppIcons.share,
                iconColor: AppColors.silver,
                label: 'Share',
                onTap: () => Navigator.of(context).pop(),
              ),
            LibraryItemSheetQuickRowKind.ephemeralHomeTrackShelf =>
              const SizedBox.shrink(),
            LibraryItemSheetQuickRowKind.none => const SizedBox.shrink(),
          },
        ),
      ],
    );
  }
}

class _QuickCircleButton extends StatelessWidget {
  const _QuickCircleButton({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.onTap,
    this.busy = false,
    this.isActive = false,
  });

  final List<List<dynamic>> icon;
  final Color iconColor;
  final String label;
  final VoidCallback onTap;
  final bool busy;
  final bool isActive;

  static const double _circleSize = 44;
  static const double _iconSize = 24;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: busy ? null : onTap,
        customBorder: const CircleBorder(),
        splashColor: AppColors.brandGreen.withValues(alpha: 0.12),
        highlightColor: AppColors.brandGreen.withValues(alpha: 0.06),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: _circleSize,
                height: _circleSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isActive
                      ? AppColors.brandGreen.withValues(alpha: 0.15)
                      : AppColors.midDark,
                  border: Border.all(
                    color: isActive
                        ? AppColors.brandGreenBorder.withValues(alpha: 0.5)
                        : AppColors.separator10,
                  ),
                ),
                child: Center(
                  child: busy
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : AppIcon(icon: icon, color: iconColor, size: _iconSize),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: AppTextStyles.small.copyWith(
                  color: AppColors.silver,
                  fontWeight: FontWeight.w500,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickCollectionSaveSlot extends ConsumerStatefulWidget {
  const _QuickCollectionSaveSlot({
    required this.item,
    this.libraryListScopeFolderId,
  });

  final LibraryItem item;
  final String? libraryListScopeFolderId;

  @override
  ConsumerState<_QuickCollectionSaveSlot> createState() =>
      _QuickCollectionSaveSlotState();
}

class _QuickCollectionSaveSlotState extends ConsumerState<_QuickCollectionSaveSlot> {
  bool _busy = false;

  Future<void> _runMutation(bool remove) async {
    if (_busy) {
      return;
    }
    final target = libraryCollectionApiTargetForItem(widget.item);
    final browseId = widget.item.ytmBrowseId?.trim();
    if (target == null || browseId == null || browseId.isEmpty) {
      return;
    }
    setState(() => _busy = true);
    final gateway = LibraryCollectionGateway(api: ref.read(tunifyApiClientProvider));
    final messenger = ScaffoldMessenger.maybeOf(context);
    final key = (target: target, browseId: browseId);
    try {
      await gateway.mutate(
        op: remove ? 'remove' : 'add',
        target: target,
        browseId: browseId,
        title: widget.item.title,
        coverUrl: widget.item.imageUrl,
      );
      ref.invalidate(libraryCollectionSavedProvider(key));
      invalidateLibraryListCaches(
        ref,
        folderId: widget.libraryListScopeFolderId,
      );
      if (!mounted) {
        return;
      }
      messenger?.showSnackBar(
        SnackBar(
          content: Text(
            widget.item.kind == LibraryItemKind.artist
                ? (remove
                    ? 'Artist removed from your library'
                    : LibraryStrings.following)
                : (remove
                    ? 'Removed from Your Library'
                    : 'Added to Your Library'),
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
    final target = libraryCollectionApiTargetForItem(widget.item)!;
    final browseId = widget.item.ytmBrowseId!.trim();
    final key = (target: target, browseId: browseId);
    final savedAsync = widget.item.isInServerLibrary
        ? const AsyncValue<bool>.data(true)
        : ref.watch(libraryCollectionSavedProvider(key));

    final isArtist = widget.item.kind == LibraryItemKind.artist;
    final remove = widget.item.isInServerLibrary ||
        (savedAsync.maybeWhen(data: (v) => v, orElse: () => false));

    final label = widget.item.isInServerLibrary
        ? (isArtist ? 'Unfollow' : 'Remove')
        : savedAsync.maybeWhen(
            data: (saved) {
              if (isArtist) {
                return saved ? 'Unfollow' : 'Follow';
              }
              return saved ? 'Remove' : 'Save';
            },
            loading: () => '…',
            error: (_, __) => isArtist ? 'Follow' : 'Save',
            orElse: () => isArtist ? 'Follow' : 'Save',
          );

    final icon = remove
        ? (isArtist ? AppIcons.personOutline : AppIcons.close)
        : AppIcons.addCircle;

    return _QuickCircleButton(
      icon: icon,
      iconColor: AppColors.silver,
      label: label,
      busy: _busy,
      onTap: () {
        if (!widget.item.isInServerLibrary &&
            savedAsync.isLoading &&
            !savedAsync.hasError) {
          return;
        }
        _runMutation(remove);
      },
    );
  }
}

class _QuickPinSlot extends ConsumerStatefulWidget {
  const _QuickPinSlot({
    required this.item,
    this.libraryListScopeFolderId,
  });

  final LibraryItem item;
  final String? libraryListScopeFolderId;

  @override
  ConsumerState<_QuickPinSlot> createState() => _QuickPinSlotState();
}

class _QuickPinSlotState extends ConsumerState<_QuickPinSlot> {
  bool _busy = false;

  Future<void> _toggle() async {
    if (_busy) {
      return;
    }
    setState(() => _busy = true);
    final gw = ref.read(libraryWriteGatewayProvider);
    final messenger = ScaffoldMessenger.maybeOf(context);
    final nextPinned = !widget.item.isPinned;
    try {
      await gw.setLibraryPin(
        playlistId: widget.item.kind == LibraryItemKind.folder
            ? null
            : widget.item.id,
        folderId: widget.item.kind == LibraryItemKind.folder
            ? widget.item.id
            : null,
        pinned: nextPinned,
      );
      invalidateLibraryListCaches(
        ref,
        folderId: widget.libraryListScopeFolderId,
      );
      if (!mounted) {
        return;
      }
      messenger?.showSnackBar(
        SnackBar(
          content: Text(nextPinned ? 'Pinned to Your Library' : 'Unpinned'),
        ),
      );
      Navigator.of(context).pop();
    } on Object catch (e) {
      messenger?.showSnackBar(
        SnackBar(content: Text('Could not update pin ($e)')),
      );
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final pinned = widget.item.isPinned;
    return _QuickCircleButton(
      icon: pinned ? AppIcons.pinOff : AppIcons.pin,
      iconColor: AppColors.silver,
      label: pinned ? 'Unpin' : 'Pin',
      busy: _busy,
      isActive: pinned,
      onTap: _toggle,
    );
  }
}

class _QuickDeleteSlot extends ConsumerStatefulWidget {
  const _QuickDeleteSlot({
    required this.item,
    required this.hostContext,
    this.libraryListScopeFolderId,
  });

  final LibraryItem item;
  final BuildContext hostContext;
  final String? libraryListScopeFolderId;

  @override
  ConsumerState<_QuickDeleteSlot> createState() => _QuickDeleteSlotState();
}

class _QuickDeleteSlotState extends ConsumerState<_QuickDeleteSlot> {
  bool _busy = false;

  Future<void> _confirmAndDelete() async {
    final isFolder = widget.item.kind == LibraryItemKind.folder;
    final title = isFolder ? 'Delete folder?' : 'Delete playlist?';
    final body = isFolder
        ? '${widget.item.title} will be removed. Playlists inside stay in your library.'
        : '${widget.item.title} will be removed from your library.';

    final go = await showDialog<bool>(
      context: widget.hostContext,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.midCard,
        title: Text(title, style: AppTextStyles.featureHeading),
        content: Text(body, style: AppTextStyles.caption),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.negativeRed,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (go != true || !mounted) {
      return;
    }
    setState(() => _busy = true);
    final gw = ref.read(libraryWriteGatewayProvider);
    final messenger = ScaffoldMessenger.maybeOf(context);
    try {
      if (isFolder) {
        await gw.deleteFolder(folderId: widget.item.id);
      } else {
        await gw.deleteUserPlaylist(playlistId: widget.item.id);
      }
      invalidateLibraryListCaches(
        ref,
        folderId: widget.libraryListScopeFolderId,
      );
      if (!mounted) {
        return;
      }
      messenger?.showSnackBar(
        SnackBar(content: Text(isFolder ? 'Folder deleted' : 'Playlist deleted')),
      );
      Navigator.of(context).pop();
    } on Object catch (e) {
      messenger?.showSnackBar(
        SnackBar(content: Text('Could not delete ($e)')),
      );
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return _QuickCircleButton(
      icon: AppIcons.delete,
      iconColor: AppColors.negativeRed,
      label: 'Delete',
      busy: _busy,
      onTap: _confirmAndDelete,
    );
  }
}
