import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tunify/core/constants/app_icons.dart';
import 'package:tunify/features/downloads/download_provider.dart';
import 'package:tunify/ui/theme/app_colors.dart';
import 'download_progress_ring.dart';

/// Download icon with an averaged progress ring around it.
/// Used for the Library app-bar "Download queue" button.
class DownloadQueueProgressIcon extends ConsumerStatefulWidget {
  const DownloadQueueProgressIcon({
    super.key,
    this.iconSize = 22,
    this.baseColor = AppColors.textPrimary,
  });

  final double iconSize;
  final Color baseColor;

  @override
  ConsumerState<DownloadQueueProgressIcon> createState() =>
      _DownloadQueueProgressIconState();
}

class _DownloadQueueProgressIconState
    extends ConsumerState<DownloadQueueProgressIcon>
    with SingleTickerProviderStateMixin {
  AnimationController? _rotationController;

  @override
  void dispose() {
    _rotationController?.dispose();
    _rotationController = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final downloadService = ref.watch(downloadServiceProvider);
    final queue = downloadService.queue;
    final hasInQueue = queue.isNotEmpty;

    if (hasInQueue && _rotationController == null) {
      _rotationController = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 1200),
      )..repeat();
    } else if (!hasInQueue && _rotationController != null) {
      _rotationController!.dispose();
      _rotationController = null;
    }

    if (_rotationController == null) {
      return AppIcon(
        icon: AppIcons.download,
        color: widget.baseColor,
        size: widget.iconSize,
      );
    }

    final validProgress = queue
        .where((e) =>
            e.expectedBytes != null &&
            e.expectedBytes! > 0 &&
            e.downloadedBytes != null)
        .toList();

    final double? avgProgress;
    if (validProgress.isEmpty) {
      avgProgress = null; // ring will show the rotating sweep.
    } else {
      final sum = validProgress.fold<double>(
        0,
        (acc, e) => acc +
            (e.downloadedBytes! / e.expectedBytes!)
                .clamp(0.0, 1.0),
      );
      avgProgress = (sum / validProgress.length).clamp(0.0, 1.0);
    }

    final painterProgress =
        (avgProgress != null && avgProgress < 1.0) ? avgProgress : null;

    return SizedBox(
      width: widget.iconSize + 8,
      height: widget.iconSize + 8,
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedBuilder(
            animation: _rotationController!,
            builder: (_, __) {
              return CustomPaint(
                size: Size(widget.iconSize + 8, widget.iconSize + 8),
                painter: DownloadProgressRingPainter(
                  progress: painterProgress,
                  rotation: _rotationController!.value *
                      2 *
                      3.14159265359,
                  trackColor: AppColors.textMuted,
                  progressColor: AppColors.accentGreen,
                  strokeWidth: 2,
                ),
              );
            },
          ),
          AppIcon(
            icon: AppIcons.download,
            color: widget.baseColor,
            size: widget.iconSize,
          ),
        ],
      ),
    );
  }
}

