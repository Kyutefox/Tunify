part of 'library_details_scroll_view.dart';

class _TrackRow extends StatelessWidget {
  const _TrackRow({
    required this.details,
    required this.track,
    required this.onRequestTrackOptions,
  });

  final LibraryDetailsModel details;
  final LibraryDetailsTrack track;
  final void Function(LibraryDetailsTrack track) onRequestTrackOptions;

  bool get _sheetAvailable =>
      track.videoId.trim().isNotEmpty || details.item.isUserOwnedPlaylist;

  @override
  Widget build(BuildContext context) {
    final type = details.type;
    final item = details.item;
    final showThumbnail = type != LibraryDetailsType.album;

    return Material(
      color: AppColors.transparent,
      child: InkWell(
        onLongPress: () => onRequestTrackOptions(track),
        borderRadius: BorderRadius.circular(AppBorderRadius.subtle),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (showThumbnail)
                LibraryDetailMiniCover(
                  item: item,
                  imageUrlOverride: track.thumbUrl,
                  size: LibraryDetailsLayout.trackRowArtSize,
                ),
              if (showThumbnail) const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      track.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.menuItemLabel,
                    ),
                    SizedBox(height: LibraryDetailsLayout.trackTitleSubtitleGap),
                    Text(
                      track.subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.small.copyWith(color: AppColors.silver),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(
                  minWidth: LibraryDetailsLayout.trackMoreIconSize + 8,
                  minHeight: LibraryDetailsLayout.trackMoreIconSize + 8,
                ),
                onPressed: _sheetAvailable
                    ? () => onRequestTrackOptions(track)
                    : null,
                icon: AppIcon(
                  icon: AppIcons.moreVert,
                  color: _sheetAvailable
                      ? AppColors.silver
                      : AppColors.silver.withValues(alpha: 0.35),
                  size: LibraryDetailsLayout.trackMoreIconSize,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
