import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../config/app_icons.dart';
import '../../../shared/providers/download_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/design_tokens.dart';
import '../../theme/app_routes.dart';
import '../download_queue_sheet.dart';
import 'library_downloaded_screen.dart';

class LibraryDownloadedSection extends ConsumerWidget {
  const LibraryDownloadedSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final downloadService = ref.watch(downloadServiceProvider);
    final count = downloadService.downloadedSongs.length;

    return Padding(
      padding: const EdgeInsets.only(
        top: AppSpacing.md,
        left: AppSpacing.base,
        right: AppSpacing.base,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.of(context).push(
              appPageRoute<void>(
                builder: (_) => const LibraryDownloadedScreen(),
              ),
            );
          },
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.base),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppColors.accentGreen.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Center(
                    child: AppIcon(
                      icon: AppIcons.download,
                      color: AppColors.accentGreen,
                      size: 26,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.base),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Downloaded',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: AppFontSize.xxl,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        count == 0
                            ? 'Songs saved to this device'
                            : '$count song${count == 1 ? '' : 's'} on device',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: AppFontSize.md,
                        ),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => showDownloadQueueSheet(context),
                  behavior: HitTestBehavior.opaque,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 12),
                    child: AppIcon(
                      icon: AppIcons.download,
                      color: AppColors.textSecondary,
                      size: 22,
                    ),
                  ),
                ),
                Center(
                  child: AppIcon(
                    icon: AppIcons.chevronRight,
                    color: AppColors.textMuted,
                    size: 22,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
