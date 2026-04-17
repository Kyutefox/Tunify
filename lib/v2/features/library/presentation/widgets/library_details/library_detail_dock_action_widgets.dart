import 'package:flutter/material.dart';
import 'package:tunify/v2/core/constants/app_colors.dart';
import 'package:tunify/v2/core/constants/app_icons.dart';
import 'package:tunify/v2/core/constants/app_spacing.dart';
import 'package:tunify/v2/core/theme/app_text_styles.dart';
import 'package:tunify/v2/core/widgets/buttons/tunify_play_circle_button.dart';
import 'package:tunify/v2/features/library/domain/entities/library_details.dart';
import 'package:tunify/v2/features/library/presentation/constants/library_details_layout.dart';
import 'package:tunify/v2/features/library/presentation/constants/library_strings.dart';
class _DockToolbarIcon extends StatelessWidget {
  const _DockToolbarIcon({required this.icon});

  final List<List<dynamic>> icon;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: () {},
      icon: AppIcon(
        icon: icon,
        color: AppColors.silver,
        size: LibraryDetailsLayout.toolbarActionIconSize,
      ),
    );
  }
}

/// Playlist / album toolbar without the play control (docked with scroll in v1 layout).
class LibraryPlaylistDockActionLeading extends StatelessWidget {
  const LibraryPlaylistDockActionLeading({super.key, required this.details});

  final LibraryDetailsModel details;

  @override
  Widget build(BuildContext context) {
    // Mini cover hidden for all collection types
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _DockToolbarIcon(icon: AppIcons.download),
        _DockToolbarIcon(icon: AppIcons.share),
        _DockToolbarIcon(icon: AppIcons.moreVert),
        const Spacer(),
        Icon(
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
  const LibraryArtistDockActionLeading({super.key, required this.details});

  final LibraryDetailsModel details;

  @override
  Widget build(BuildContext context) {
    // Mini cover hidden for all collection types
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Flexible(
          child: Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton(
              onPressed: () {},
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.white,
                side: const BorderSide(color: AppColors.lightBorder),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.sm,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                LibraryStrings.follow,
                style: AppTextStyles.smallBold,
              ),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        _DockToolbarIcon(icon: AppIcons.moreVert),
        Icon(
          Icons.shuffle_rounded,
          color: AppColors.brandGreen,
          size: LibraryDetailsLayout.shuffleIconSize,
        ),
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
