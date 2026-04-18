import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tunify/v2/core/constants/app_border_radius.dart';
import 'package:tunify/v2/core/constants/app_colors.dart';
import 'package:tunify/v2/core/constants/app_spacing.dart';
import 'package:tunify/v2/core/theme/app_text_styles.dart';
import 'package:tunify/v2/features/library/domain/entities/library_item.dart';
import 'package:tunify/v2/features/library/presentation/constants/library_layout.dart';
import 'package:tunify/v2/features/library/presentation/library_list_invalidation.dart';
import 'package:tunify/v2/features/library/presentation/screens/library_create_item_screen.dart';
import 'package:tunify/v2/features/library/presentation/screens/library_details_screen.dart';

/// Root library (+): create playlist or folder (v1-style full-screen flows).
void showLibraryPlusActionsSheet(BuildContext context, WidgetRef ref) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.bottomSheetSurface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(AppBorderRadius.comfortable),
      ),
    ),
    builder: (sheetContext) {
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
            const SizedBox(height: AppSpacing.lg),
            ListTile(
              title: Text(
                'Playlist',
                style: AppTextStyles.bodyBold.copyWith(color: AppColors.white),
              ),
              subtitle: Text(
                'Create a new playlist',
                style: AppTextStyles.small.copyWith(color: AppColors.silver),
              ),
              onTap: () async {
                Navigator.of(sheetContext).pop();
                final created = await Navigator.of(context).push<LibraryItem?>(
                  MaterialPageRoute<LibraryItem?>(
                    builder: (_) => const LibraryCreateItemScreen(
                      isPlaylist: true,
                    ),
                  ),
                );
                if (!context.mounted) {
                  return;
                }
                if (created != null) {
                  invalidateLibraryListCaches(ref);
                  await Navigator.of(context).push<void>(
                    MaterialPageRoute<void>(
                      builder: (_) => LibraryDetailsScreen(item: created),
                    ),
                  );
                }
              },
            ),
            ListTile(
              title: Text(
                'Folder',
                style: AppTextStyles.bodyBold.copyWith(color: AppColors.white),
              ),
              subtitle: Text(
                'Organize playlists into a folder',
                style: AppTextStyles.small.copyWith(color: AppColors.silver),
              ),
              onTap: () async {
                Navigator.of(sheetContext).pop();
                final ok = await Navigator.of(context).push<bool?>(
                  MaterialPageRoute<bool?>(
                    builder: (_) => const LibraryCreateItemScreen(
                      isPlaylist: false,
                    ),
                  ),
                );
                if (!context.mounted) {
                  return;
                }
                if (ok == true) {
                  invalidateLibraryListCaches(ref);
                }
              },
            ),
            const SizedBox(height: AppSpacing.md),
          ],
        ),
      );
    },
  );
}
