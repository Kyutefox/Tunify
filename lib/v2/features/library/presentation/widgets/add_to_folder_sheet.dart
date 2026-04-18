import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tunify/v2/core/constants/app_border_radius.dart';
import 'package:tunify/v2/core/constants/app_colors.dart';
import 'package:tunify/v2/core/constants/app_spacing.dart';
import 'package:tunify/v2/core/theme/app_text_styles.dart';
import 'package:tunify/v2/features/library/domain/entities/library_item.dart';
import 'package:tunify/v2/features/library/presentation/constants/library_layout.dart';
import 'package:tunify/v2/features/library/presentation/library_list_invalidation.dart';
import 'package:tunify/v2/features/library/presentation/providers/library_providers.dart';

/// Pick a folder and attach [playlistId] (Tunify library `playlist_id`).
void showAddToFolderSheet(
  BuildContext context,
  WidgetRef ref, {
  required String playlistId,
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
    builder: (_) => _AddToFolderSheetBody(playlistId: playlistId),
  );
}

class _AddToFolderSheetBody extends ConsumerStatefulWidget {
  const _AddToFolderSheetBody({required this.playlistId});

  final String playlistId;

  @override
  ConsumerState<_AddToFolderSheetBody> createState() =>
      _AddToFolderSheetBodyState();
}

class _AddToFolderSheetBodyState extends ConsumerState<_AddToFolderSheetBody> {
  bool _busy = false;

  Future<void> _pick(LibraryItem folder) async {
    if (_busy) {
      return;
    }
    setState(() => _busy = true);
    final gw = ref.read(libraryWriteGatewayProvider);
    final messenger = ScaffoldMessenger.maybeOf(context);
    try {
      await gw.addPlaylistToFolder(
        folderId: folder.id,
        playlistId: widget.playlistId,
      );
      invalidateLibraryListCaches(ref, folderId: folder.id);
      if (!mounted) {
        return;
      }
      messenger?.showSnackBar(
        SnackBar(content: Text('Added to ${folder.title}')),
      );
      Navigator.of(context).pop();
    } on Object catch (e) {
      messenger?.showSnackBar(
        SnackBar(content: Text('Could not add to folder ($e)')),
      );
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final foldersAsync = ref.watch(libraryRemoteItemsProvider(null));

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: AppSpacing.md),
            Center(
              child: Container(
                width: LibraryLayout.sheetHandleWidth,
                height: LibraryLayout.sheetHandleHeight,
                decoration: BoxDecoration(
                  color: AppColors.silver.withValues(alpha: 0.4),
                  borderRadius:
                      BorderRadius.circular(LibraryLayout.sheetHandleRadius),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
              child: Text(
                'Add to folder',
                style: AppTextStyles.sectionTitle,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            foldersAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(AppSpacing.xl),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Text(
                  e.toString(),
                  style: AppTextStyles.caption,
                ),
              ),
              data: (items) {
                final folders =
                    items.where((i) => i.kind == LibraryItemKind.folder).toList();
                if (folders.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    child: Text(
                      'Create a folder from Your Library first.',
                      style: AppTextStyles.caption.copyWith(color: AppColors.silver),
                    ),
                  );
                }
                return ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.sizeOf(context).height * 0.5,
                  ),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: folders.length,
                    itemBuilder: (context, index) {
                      final f = folders[index];
                      return ListTile(
                        enabled: !_busy,
                        title: Text(
                          f.title,
                          style: AppTextStyles.bodyBold
                              .copyWith(color: AppColors.white),
                        ),
                        onTap: () => _pick(f),
                      );
                    },
                  ),
                );
              },
            ),
            if (_busy)
              const Padding(
                padding: EdgeInsets.only(top: AppSpacing.sm),
                child: Center(
                  child: SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
