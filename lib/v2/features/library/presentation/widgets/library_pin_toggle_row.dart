import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tunify/v2/core/constants/app_colors.dart';
import 'package:tunify/v2/core/constants/app_icons.dart';
import 'package:tunify/v2/core/constants/app_spacing.dart';
import 'package:tunify/v2/core/theme/app_text_styles.dart';
import 'package:tunify/v2/features/library/domain/entities/library_item.dart';
import 'package:tunify/v2/features/library/presentation/library_list_invalidation.dart';
import 'package:tunify/v2/features/library/presentation/providers/library_providers.dart';

/// Pin / Unpin row for library or collection option sheets.
class LibraryPinToggleRow extends ConsumerStatefulWidget {
  const LibraryPinToggleRow({
    super.key,
    required this.item,
    this.libraryListScopeFolderId,
  });

  final LibraryItem item;

  /// When non-null (folder drill-in), invalidates that folder list as well as root.
  final String? libraryListScopeFolderId;

  @override
  ConsumerState<LibraryPinToggleRow> createState() => _LibraryPinToggleRowState();
}

class _LibraryPinToggleRowState extends ConsumerState<LibraryPinToggleRow> {
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
    return InkWell(
      onTap: _busy ? null : _toggle,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xl,
          vertical: AppSpacing.lg,
        ),
        child: Row(
          children: [
            AppIcon(
              icon: pinned ? AppIcons.pinOff : AppIcons.pin,
              size: 24,
              color: AppColors.silver,
            ),
            const SizedBox(width: AppSpacing.xl),
            Expanded(
              child: Text(
                pinned ? 'Unpin' : 'Pin',
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
