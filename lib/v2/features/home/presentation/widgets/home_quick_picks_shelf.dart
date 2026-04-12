import 'package:flutter/material.dart';
import 'package:tunify/v2/features/home/domain/entities/home_block.dart';
import 'package:tunify/v2/features/home/presentation/constants/home_layout.dart';
import 'package:tunify/v2/features/home/presentation/widgets/home_slim_grid.dart';

/// Quick picks: 2×[visibleRows] tiles per horizontal swipe page; same [HomeSlimGrid] as mock/DESIGN.
class HomeQuickPicksShelf extends StatelessWidget {
  const HomeQuickPicksShelf({
    super.key,
    required this.data,
  });

  final HomeQuickPicksBlock data;

  @override
  Widget build(BuildContext context) {
    final rows = data.visibleRows.clamp(1, 8);
    final perPage = 2 * rows;
    final tiles = data.tiles;
    final pageCount = (tiles.length / perPage).ceil().clamp(1, 24);
    final pageHeight = HomeLayout.quickPicksPageHeight(rows);

    return Padding(
      padding: EdgeInsets.only(bottom: HomeLayout.shelfTrailingAfterContent),
      child: SizedBox(
        height: pageHeight,
        child: PageView.builder(
          itemCount: pageCount,
          padEnds: false,
          itemBuilder: (context, pageIndex) {
            final start = pageIndex * perPage;
            final end = (start + perPage).clamp(0, tiles.length);
            final slice = tiles.sublist(start, end);
            return Align(
              alignment: Alignment.topCenter,
              child: HomeSlimGrid(
                tiles: slice,
                omitTrailingShelfGap: true,
              ),
            );
          },
        ),
      ),
    );
  }
}
