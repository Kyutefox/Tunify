import 'package:flutter/material.dart';
import 'package:tunify/v2/core/constants/app_spacing.dart';
import 'package:tunify/v2/core/constants/app_border_radius.dart';
import 'package:tunify/v2/core/widgets/cards/track_slim_card.dart';
import 'package:tunify/v2/core/widgets/buttons/tunify_press_feedback.dart';
import 'package:tunify/v2/features/library/domain/entities/library_item.dart';
import 'package:tunify/v2/features/library/presentation/widgets/library_item_options_sheet.dart';
import 'package:tunify/v2/features/home/domain/entities/home_block.dart';
import 'package:tunify/v2/features/home/presentation/constants/home_layout.dart';

/// Two-column slim grid — equal-width columns ([Expanded]); symmetric [AppSpacing.lg] inset.
class HomeSlimGrid extends StatelessWidget {
  const HomeSlimGrid({
    super.key,
    required this.tiles,
    this.omitTrailingShelfGap = false,
  });

  final List<HomeSlimTile> tiles;

  /// When true (e.g. Quick picks pages), no bottom [HomeLayout.shelfTrailingAfterContent] so the
  /// parent owns the boundary gap once per shelf.
  final bool omitTrailingShelfGap;

  @override
  Widget build(BuildContext context) {
    final bottomPad =
        omitTrailingShelfGap ? 0.0 : HomeLayout.shelfTrailingAfterContent;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        bottomPad,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (int i = 0; i < tiles.length; i += 2) ...[
            if (i > 0) const SizedBox(height: AppSpacing.md),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _tileCard(context, tiles[i])),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: i + 1 < tiles.length
                      ? _tileCard(context, tiles[i + 1])
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _tileCard(BuildContext context, HomeSlimTile tile) {
    final libraryItem = LibraryItem(
      id: tile.id,
      title: tile.title,
      subtitle: 'Playlist',
      kind: LibraryItemKind.playlist,
      imageUrl: tile.artworkUrl,
      creatorName: 'Tunify',
    );

    return TunifyPressFeedback(
      borderRadius: BorderRadius.circular(AppBorderRadius.subtle),
      onLongPress: () => showLibraryItemOptionsSheet(context, libraryItem),
      child: TrackSlimCard(
        title: tile.title,
        mockThumbArgbColors: tile.thumbColors,
        artworkUrl: tile.artworkUrl,
        rowHeight: HomeLayout.slimRowHeight,
        thumbSize: HomeLayout.slimThumbSize,
        showNowPlayingIndicator: tile.showNowPlayingIndicator,
        showMoreMenu: tile.showMoreMenu,
        showSeekBar: tile.showSeekBar,
        seekProgress: tile.seekProgress,
      ),
    );
  }
}
