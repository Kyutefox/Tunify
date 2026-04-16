import 'package:flutter/material.dart';
import 'package:tunify/v2/core/constants/app_border_radius.dart';
import 'package:tunify/v2/core/constants/app_colors.dart';
import 'package:tunify/v2/core/constants/app_spacing.dart';
import 'package:tunify/v2/core/theme/app_text_styles.dart';
import 'package:tunify/v2/core/widgets/art/artwork_or_gradient.dart';
import 'package:tunify/v2/features/library/domain/entities/library_item.dart';
import 'package:tunify/v2/features/library/presentation/constants/library_layout.dart';
import 'package:tunify/v2/features/library/presentation/widgets/system_artwork.dart';

/// Shows a Spotify-style "more options" bottom sheet for a library item.
///
/// Displays the item header (artwork + title + subtitle), a divider, and
/// contextual action rows. Excludes premium-only options.
void showLibraryItemOptionsSheet(BuildContext context, LibraryItem item) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.bottomSheetSurface,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(AppBorderRadius.comfortable),
      ),
    ),
    builder: (_) => _LibraryItemOptionsSheet(item: item),
  );
}

/// Internal sheet content.
class _LibraryItemOptionsSheet extends StatelessWidget {
  const _LibraryItemOptionsSheet({required this.item});

  final LibraryItem item;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Drag handle ──
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

          // ── Item header ──
          const SizedBox(height: AppSpacing.xl),
          _ItemHeader(item: item),

          // ── Divider ──
          const SizedBox(height: AppSpacing.lg),
          const Divider(
            height: 0.5,
            thickness: 0.5,
            color: AppColors.separator10,
          ),

          // ── Action options ──
          const SizedBox(height: AppSpacing.sm),
          ..._buildActions(item),
          const SizedBox(height: AppSpacing.md),
        ],
      ),
    );
  }

  /// Build context-aware action list based on item kind.
  List<Widget> _buildActions(LibraryItem item) {
    final actions = <_OptionAction>[];

    actions.add(const _OptionAction(
      icon: Icons.share_outlined,
      label: 'Share',
    ));

    if (item.creatorName != 'You') {
      actions.add(const _OptionAction(
        icon: Icons.add_circle_outline,
        label: 'Add to Your Library',
      ));
    }

    actions.add(const _OptionAction(
      icon: Icons.download_outlined,
      label: 'Download',
    ));

    if (item.kind != LibraryItemKind.artist &&
        item.kind != LibraryItemKind.podcast) {
      actions.add(const _OptionAction(
        icon: Icons.person_outline,
        label: 'Go to artist',
      ));
    }

    actions.add(const _OptionAction(
      icon: Icons.queue_music_outlined,
      label: 'Add to Queue',
    ));

    if (item.kind == LibraryItemKind.album ||
        item.kind == LibraryItemKind.playlist) {
      final target = item.kind == LibraryItemKind.album ? 'album' : 'playlist';
      actions.add(_OptionAction(
        icon: Icons.sensors_rounded,
        label: 'Go to $target radio',
      ));
    }

    if (item.kind != LibraryItemKind.playlist) {
      actions.add(const _OptionAction(
        icon: Icons.playlist_add,
        label: 'Add to playlist',
      ));
    }

    actions.add(const _OptionAction(
      icon: Icons.equalizer_rounded,
      label: 'Show Tunify Code',
    ));

    return actions
        .map((a) => _OptionRow(icon: a.icon, label: a.label))
        .toList();
  }
}

/// Header row: artwork + title + subtitle.
class _ItemHeader extends StatelessWidget {
  const _ItemHeader({required this.item});

  final LibraryItem item;

  @override
  Widget build(BuildContext context) {
    final isCircular = item.kind == LibraryItemKind.artist;
    final radius = isCircular
        ? LibraryLayout.sheetArtworkSize / 2
        : AppBorderRadius.subtle;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: Row(
        children: [
          if (item.systemArtwork != null)
            SystemArtwork(
              type: item.systemArtwork!,
              size: LibraryLayout.sheetArtworkSize,
              borderRadius: radius,
            )
          else
            ClipRRect(
              borderRadius: BorderRadius.circular(radius),
              child: SizedBox(
                width: LibraryLayout.sheetArtworkSize,
                height: LibraryLayout.sheetArtworkSize,
                child: ArtworkOrGradient(imageUrl: item.imageUrl),
              ),
            ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodyBold,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  item.subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.small,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Single action row in the options sheet.
class _OptionRow extends StatelessWidget {
  const _OptionRow({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.of(context).pop(),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xl,
          vertical: AppSpacing.lg,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: LibraryLayout.sheetOptionIconSize,
              color: AppColors.silver,
            ),
            const SizedBox(width: AppSpacing.xl),
            Expanded(
              child: Text(
                label,
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Data class for an option action.
class _OptionAction {
  const _OptionAction({required this.icon, required this.label});

  final IconData icon;
  final String label;
}
