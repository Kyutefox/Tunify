import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tunify/core/constants/app_icons.dart';
import 'package:tunify/data/models/song.dart';
import 'package:tunify/features/downloads/download_provider.dart';
import 'package:tunify/ui/theme/app_colors.dart';
import 'package:tunify/ui/theme/app_colors_scheme.dart';
import 'download_progress_ring.dart';

class MultiDownloadButton extends ConsumerStatefulWidget {
  const MultiDownloadButton({
    super.key,
    required this.songs,
    this.size = 24,
    this.iconSize = 20,
  });

  final List<Song> songs;
  final double size;
  final double iconSize;

  @override
  ConsumerState<MultiDownloadButton> createState() => _MultiDownloadButtonState();
}

class _MultiDownloadButtonState extends ConsumerState<MultiDownloadButton>
    with SingleTickerProviderStateMixin {
  AnimationController? _rotationController;

  @override
  void dispose() {
    _rotationController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final downloadService = ref.watch(downloadServiceProvider);
    final total = widget.songs.length;
    if (total == 0) {
      return IconButton(
        icon: AppIcon(
          icon: AppIcons.download,
          size: widget.size,
          color: AppColorsScheme.of(context).textPrimary,
        ),
        onPressed: null,
        color: AppColorsScheme.of(context).textPrimary,
      );
    }

    final songIds = widget.songs.map((s) => s.id).toSet();
    final downloadedCount =
        widget.songs.where((s) => downloadService.isDownloaded(s.id)).length;
    final entriesInQueue = downloadService.queue
        .where((e) => songIds.contains(e.song.id))
        .toList();
    final allDownloaded = downloadedCount == total;
    final hasInQueue = entriesInQueue.isNotEmpty;

    double combinedProgress = total > 0 ? downloadedCount / total : 0.0;
    for (final e in entriesInQueue) {
      if (e.expectedBytes != null &&
          e.expectedBytes! > 0 &&
          e.downloadedBytes != null) {
        final itemProgress = (e.downloadedBytes! / e.expectedBytes!)
            .clamp(0.0, 1.0);
        combinedProgress += itemProgress / total;
        break;
      }
    }
    combinedProgress = combinedProgress.clamp(0.0, 1.0);

    if (hasInQueue && _rotationController == null) {
      _rotationController = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 1200),
      )..repeat();
    } else if (!hasInQueue && _rotationController != null) {
      _rotationController!.dispose();
      _rotationController = null;
    }

    Widget icon;
    if (allDownloaded) {
      icon = AppIcon(
        icon: AppIcons.checkCircle,
        color: AppColors.accentGreen,
        size: widget.size,
      );
    } else if (hasInQueue && _rotationController != null) {
      icon = SizedBox(
        width: widget.size + 8,
        height: widget.size + 8,
        child: Stack(
          alignment: Alignment.center,
          children: [
            AnimatedBuilder(
              animation: _rotationController!,
              builder: (_, __) {
                return CustomPaint(
                  size: Size(widget.size + 8, widget.size + 8),
                  painter: DownloadProgressRingPainter(
                    progress: combinedProgress < 1.0 ? combinedProgress : null,
                    rotation:
                        _rotationController!.value * 2 * 3.14159265359,
                    trackColor: AppColorsScheme.of(context).textMuted,
                    progressColor: AppColors.accentGreen,
                    strokeWidth: 2,
                  ),
                );
              },
            ),
            AppIcon(
              icon: AppIcons.download,
              color: AppColorsScheme.of(context).textPrimary,
              size: widget.iconSize,
            ),
          ],
        ),
      );
    } else {
      icon = AppIcon(
        icon: AppIcons.download,
        size: widget.size,
        color: AppColorsScheme.of(context).textPrimary,
      );
    }

    VoidCallback? onPressed;
    if (!allDownloaded) {
      onPressed = () {
        ref.read(downloadServiceProvider).enqueueAll(widget.songs);
      };
    }

    return IconButton(
      icon: icon,
      onPressed: onPressed,
      color: AppColorsScheme.of(context).textPrimary,
    );
  }
}
