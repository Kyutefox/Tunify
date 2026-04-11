import 'package:flutter/material.dart';
import 'package:tunify/v2/core/constants/app_spacing.dart';
import 'package:tunify/v2/core/widgets/cards/track_slim_card.dart';
import 'package:tunify/v2/features/home/domain/entities/home_block.dart';
import 'package:tunify/v2/features/home/presentation/constants/home_layout.dart';

/// Two-column slim grid — equal-width columns ([Expanded]); symmetric [AppSpacing.lg] inset.
class HomeSlimGrid extends StatelessWidget {
  const HomeSlimGrid({
    super.key,
    required this.tiles,
  });

  final List<HomeSlimTile> tiles;

  @override
  Widget build(BuildContext context) {
    final gap = AppSpacing.md;
    final horizontalPadding = AppSpacing.lg;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        horizontalPadding,
        AppSpacing.md,
        horizontalPadding,
        0,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (int i = 0; i < tiles.length; i += 2) ...[
            if (i > 0) SizedBox(height: gap),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _tileCard(tiles[i])),
                SizedBox(width: gap),
                Expanded(
                  child: i + 1 < tiles.length
                      ? _tileCard(tiles[i + 1])
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _tileCard(HomeSlimTile tile) {
    return TrackSlimCard(
      title: tile.title,
      mockThumbArgbColors: tile.thumbColors,
      rowHeight: HomeLayout.slimRowHeight,
      thumbSize: HomeLayout.slimThumbSize,
      showNowPlayingIndicator: tile.showNowPlayingIndicator,
      showMoreMenu: tile.showMoreMenu,
      showSeekBar: tile.showSeekBar,
      seekProgress: tile.seekProgress,
    );
  }
}
