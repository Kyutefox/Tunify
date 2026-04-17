part of 'library_details_scroll_view.dart';

class _TrackRow extends StatelessWidget {
  const _TrackRow({
    required this.track,
    required this.item,
  });

  final LibraryDetailsTrack track;
  final LibraryItem item;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        LibraryDetailMiniCover(
          item: item,
          imageUrlOverride: track.thumbUrl,
          size: LibraryDetailsLayout.trackRowArtSize,
        ),
        const SizedBox(width: AppSpacing.md),
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
        AppIcon(
          icon: AppIcons.moreVert,
          color: AppColors.silver,
          size: LibraryDetailsLayout.trackMoreIconSize,
        ),
      ],
    );
  }
}
