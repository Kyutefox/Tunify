import 'package:flutter/material.dart';
import 'package:tunify/v2/core/constants/app_colors.dart';
import 'package:tunify/v2/core/constants/app_icons.dart';
import 'package:tunify/v2/core/constants/app_spacing.dart';
import 'package:tunify/v2/core/theme/app_text_styles.dart';
import 'package:tunify/v2/core/widgets/buttons/tunify_play_circle_button.dart';
import 'package:tunify/v2/features/library/domain/entities/library_details.dart';
import 'package:tunify/v2/features/library/domain/utils/track_selection.dart';
import 'package:tunify/v2/features/library/presentation/constants/library_details_layout.dart';
import 'package:tunify/v2/features/library/presentation/constants/library_strings.dart';
import 'package:tunify/v2/features/library/presentation/widgets/library_details/library_detail_mini_cover.dart';
import 'package:tunify/v2/features/library/presentation/widgets/library_details/library_detail_mini_cover_animated_border.dart';
class _DockToolbarIcon extends StatelessWidget {
  const _DockToolbarIcon({
    required this.icon,
    this.onPressed,
    this.isPrimary = false,
  });

  final List<List<dynamic>> icon;
  final VoidCallback? onPressed;
  final bool isPrimary;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      icon: AppIcon(
        icon: icon,
        color: isPrimary ? AppColors.brandGreen : AppColors.silver,
        size: LibraryDetailsLayout.toolbarActionIconSize,
      ),
    );
  }
}

/// Playlist / album toolbar without the play control (docked with scroll in v1 layout).
class LibraryPlaylistDockActionLeading extends StatelessWidget {
  const LibraryPlaylistDockActionLeading({
    super.key,
    required this.details,
    this.onAddPressed,
    this.onMorePressed,
    this.isInLibrary,
  });

  final LibraryDetailsModel details;
  final VoidCallback? onAddPressed;
  final VoidCallback? onMorePressed;
  final bool? isInLibrary;

  @override
  Widget build(BuildContext context) {
    final isUserCreated = details.item.isUserOwnedPlaylist;
    final isStaticPlaylist = details.isStaticPlaylist;
    final currentlyInLibrary = isInLibrary ?? details.item.isInServerLibrary;
    final randomTrackThumbUrl = TrackSelection.getRandomTrackThumbUrl(details);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        LibraryDetailMiniCoverAnimatedBorder(
          width: LibraryDetailsLayout.playlistActionMiniCoverWidth,
          height: LibraryDetailsLayout.playlistActionMiniCoverHeight,
          child: LibraryDetailMiniCover(
            item: details.item,
            imageUrlOverride: randomTrackThumbUrl,
            width: LibraryDetailsLayout.playlistActionMiniCoverWidth,
            height: LibraryDetailsLayout.playlistActionMiniCoverHeight,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        if (isUserCreated) ...[
          _DockToolbarIcon(icon: AppIcons.download),
          _DockToolbarIcon(icon: AppIcons.share),
        ] else if (isStaticPlaylist) ...[
          _DockToolbarIcon(icon: AppIcons.download),
        ] else ...[
          _DockToolbarIcon(
            icon: currentlyInLibrary ? AppIcons.check : AppIcons.addCircle,
            onPressed: onAddPressed,
            isPrimary: currentlyInLibrary,
          ),
          _DockToolbarIcon(icon: AppIcons.download),
        ],
        _DockToolbarIcon(icon: AppIcons.moreVert, onPressed: onMorePressed),
        const Spacer(),
        const Icon(
          Icons.shuffle_rounded,
          color: AppColors.brandGreen,
          size: LibraryDetailsLayout.shuffleIconSize,
        ),
        const SizedBox(width: LibraryDetailsLayout.dockedToolbarReserveForPlay),
      ],
    );
  }
}

/// Artist toolbar without the play control.
class LibraryArtistDockActionLeading extends StatelessWidget {
  const LibraryArtistDockActionLeading({
    super.key,
    required this.details,
    required this.isFollowing,
    required this.followBusy,
    this.onFollowPressed,
    this.onMorePressed,
  });

  final LibraryDetailsModel details;
  final bool isFollowing;
  final bool followBusy;
  final VoidCallback? onFollowPressed;
  final VoidCallback? onMorePressed;

  @override
  Widget build(BuildContext context) {
    final randomTrackThumbUrl = TrackSelection.getRandomTrackThumbUrl(details);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        LibraryDetailMiniCoverAnimatedBorder(
          width: LibraryDetailsLayout.playlistActionMiniCoverWidth,
          height: LibraryDetailsLayout.playlistActionMiniCoverHeight,
          child: LibraryDetailMiniCover(
            item: details.item,
            imageUrlOverride: randomTrackThumbUrl,
            width: LibraryDetailsLayout.playlistActionMiniCoverWidth,
            height: LibraryDetailsLayout.playlistActionMiniCoverHeight,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        OutlinedButton(
          onPressed: (followBusy || onFollowPressed == null)
              ? null
              : onFollowPressed,
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.white,
            side: const BorderSide(color: AppColors.lightBorder),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.sm,
            ),
            minimumSize: const Size(0, 32),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          child: followBusy
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(
                  isFollowing
                      ? LibraryStrings.following
                      : LibraryStrings.follow,
                  style: AppTextStyles.smallBold,
                ),
        ),
        const SizedBox(width: AppSpacing.md),
        _DockToolbarIcon(icon: AppIcons.moreVert, onPressed: onMorePressed),
        const SizedBox(width: LibraryDetailsLayout.dockedToolbarReserveForPlay),
      ],
    );
  }
}

/// Primary play control (positioned separately so it can stick under the app bar).
class LibraryDetailCollectionPlayButton extends StatelessWidget {
  const LibraryDetailCollectionPlayButton({super.key});

  @override
  Widget build(BuildContext context) {
    return TunifyPlayCircleButton(
      diameter: LibraryDetailsLayout.playButtonDiameter,
      iconSize: LibraryDetailsLayout.playButtonIconSize,
      onPressed: () {},
    );
  }
}
