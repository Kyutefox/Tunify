import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tunify/ui/widgets/common/sheet.dart'
    show showAppDraggableSheet, kSheetHorizontalPadding;
import 'package:tunify/core/constants/app_icons.dart';
import 'package:tunify/features/downloads/download_provider.dart';
import 'package:tunify/features/downloads/download_service.dart';
import 'package:tunify/ui/theme/app_colors.dart';
import 'package:tunify/ui/theme/design_tokens.dart';
import 'package:tunify/ui/theme/app_colors_scheme.dart';

void showDownloadQueueSheet(BuildContext context) {
  showAppDraggableSheet(
    context,
    initialChildSize: 0.5,
    minChildSize: 0.25,
    maxChildSize: 0.8,
    builder: (scrollController) => DownloadQueueSheet(
      scrollController: scrollController,
    ),
  );
}

class DownloadQueueSheet extends ConsumerWidget {
  const DownloadQueueSheet({super.key, required this.scrollController});
  final ScrollController scrollController;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final downloadService = ref.watch(downloadServiceProvider);
    final queue = downloadService.queue;
    final err = downloadService.lastError;
    if (err != null && context.mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Download failed: $err'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      });
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            kSheetHorizontalPadding,
            AppSpacing.lg,
            kSheetHorizontalPadding,
            AppSpacing.sm,
          ),
          child: Row(
            children: [
              AppIcon(
                icon: AppIcons.download,
                color: AppColorsScheme.of(context).textPrimary,
                size: 22,
              ),
              const SizedBox(width: 10),
              Text(
                'Download queue',
                style: TextStyle(
                  color: AppColorsScheme.of(context).textPrimary,
                  fontSize: AppFontSize.xxl,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        if (queue.isEmpty)
          Expanded(
            child: Center(
              child: Text(
                'No downloads in the queue',
                style: TextStyle(
                  color: AppColorsScheme.of(context).textMuted,
                  fontSize: AppFontSize.lg,
                ),
              ),
            ),
          )
        else
          Expanded(
            child: ListView(
              controller: scrollController,
              padding: const EdgeInsets.fromLTRB(
                kSheetHorizontalPadding,
                0,
                kSheetHorizontalPadding,
                AppSpacing.xl,
              ),
              children: queue
                  .map((e) => DownloadQueueTile(
                        entry: e,
                        onCancel: () => ref
                            .read(downloadServiceProvider)
                            .cancelDownload(e.song.id),
                        onRetry: () =>
                            ref.read(downloadServiceProvider).enqueue(e.song),
                      ))
                  .toList(),
            ),
          ),
      ],
    );
  }
}

String formatDownloadBytes(int bytes) {
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
  return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
}

String formatSpeed(double bytesPerSecond) {
  if (bytesPerSecond < 1024) return '${bytesPerSecond.round()} B/s';
  if (bytesPerSecond < 1024 * 1024) {
    return '${(bytesPerSecond / 1024).toStringAsFixed(1)} KB/s';
  }
  return '${(bytesPerSecond / (1024 * 1024)).toStringAsFixed(1)} MB/s';
}

class DownloadQueueTile extends StatelessWidget {
  const DownloadQueueTile({
    super.key,
    required this.entry,
    required this.onCancel,
    required this.onRetry,
  });

  final DownloadEntry entry;
  final VoidCallback onCancel;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    String statusText;
    Color statusColor = AppColorsScheme.of(context).textMuted;
    switch (entry.status) {
      case DownloadStatus.queued:
        statusText = 'Queued';
        break;
      case DownloadStatus.downloading:
        statusText = 'Downloading…';
        statusColor = AppColors.primary;
        break;
      case DownloadStatus.failed:
        statusText = 'Failed';
        statusColor = AppColors.accentRed;
        break;
      case DownloadStatus.completed:
        statusText = 'Done';
        statusColor = AppColors.accentGreen;
        break;
    }

    final expected = entry.expectedBytes ?? 0;
    final downloaded = entry.downloadedBytes ?? 0;
    final hasProgress = entry.status == DownloadStatus.downloading &&
        (expected > 0 || downloaded > 0);
    final total = expected > 0 ? expected : 1;
    final progress = (downloaded / total).clamp(0.0, 1.0);
    final percent = (progress * 100).round();

    final canCancel = entry.status == DownloadStatus.queued ||
        entry.status == DownloadStatus.downloading;
    final canRetry = entry.status == DownloadStatus.failed;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 36,
            height: 36,
            child: CachedNetworkImage(
              imageUrl: entry.song.thumbnailUrl,
              fit: BoxFit.cover,
              placeholder: (_, __) => const SizedBox.shrink(),
              errorWidget: (_, __, ___) => Container(
                color: AppColorsScheme.of(context).surfaceLight,
                child: Center(
                  child: AppIcon(
                    icon: AppIcons.musicNote,
                    color: AppColorsScheme.of(context).textMuted,
                    size: 16,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.song.title,
                  style: TextStyle(
                    color: AppColorsScheme.of(context).textPrimary,
                    fontSize: AppFontSize.base,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                if (entry.status == DownloadStatus.failed &&
                    entry.errorMessage != null)
                  Text(
                    entry.errorMessage!,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: AppFontSize.sm,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  )
                else if (hasProgress) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        expected > 0
                            ? '${formatDownloadBytes(downloaded)} of ${formatDownloadBytes(expected)}'
                            : formatDownloadBytes(downloaded),
                        style: TextStyle(
                          color: AppColorsScheme.of(context).textSecondary,
                          fontSize: AppFontSize.xs,
                        ),
                      ),
                      if (expected > 0)
                        Text(
                          '$percent%',
                          style: TextStyle(
                            color: AppColorsScheme.of(context).textSecondary,
                            fontSize: AppFontSize.xs,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                    ],
                  ),
                  if (entry.speedBytesPerSecond != null &&
                      entry.speedBytesPerSecond! > 0) ...[
                    const SizedBox(height: 2),
                    Text(
                      formatSpeed(entry.speedBytesPerSecond!),
                      style: TextStyle(
                        color: AppColorsScheme.of(context).textMuted,
                        fontSize: AppFontSize.micro,
                      ),
                    ),
                  ],
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.xs),
                    child: LinearProgressIndicator(
                      value: expected > 0 ? progress : null,
                      minHeight: 4,
                      backgroundColor: Colors.white.withValues(alpha: 0.1),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                          AppColors.accentGreen),
                    ),
                  ),
                ] else
                  Text(
                    statusText,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: AppFontSize.sm,
                    ),
                  ),
              ],
            ),
          ),
          if (canCancel)
            GestureDetector(
              onTap: onCancel,
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.only(left: 8, top: 2),
                child: AppIcon(
                  icon: AppIcons.close,
                  color: AppColorsScheme.of(context).textMuted,
                  size: 18,
                ),
              ),
            )
          else if (canRetry)
            GestureDetector(
              onTap: onRetry,
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.only(left: 8, top: 2),
                child: AppIcon(
                  icon: AppIcons.refresh,
                  color: AppColorsScheme.of(context).textMuted,
                  size: 18,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
