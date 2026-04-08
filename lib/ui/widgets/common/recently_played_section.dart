import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tunify/data/models/song.dart';
import 'package:tunify/features/home/home_state_provider.dart';
import 'package:tunify/ui/screens/shared/home/recently_played_screen.dart';
import 'package:tunify/ui/screens/shared/home/home_sections.dart';
import 'package:tunify/ui/theme/desktop_tokens.dart';
import 'package:tunify/ui/theme/design_tokens.dart';
import 'package:tunify/ui/theme/app_routes.dart';
import 'package:tunify/ui/theme/app_colors_scheme.dart';
import 'package:tunify/ui/widgets/common/section_header.dart';
import 'package:tunify/ui/shell/shell_context.dart';

class RecentlyPlayedSection extends ConsumerStatefulWidget {
  const RecentlyPlayedSection({super.key, required this.onPlay});
  final void Function(Song song) onPlay;

  @override
  ConsumerState<RecentlyPlayedSection> createState() =>
      _RecentlyPlayedSectionState();
}

class _RecentlyPlayedSectionState extends ConsumerState<RecentlyPlayedSection> {
  @override
  Widget build(BuildContext context) {
    final songs = ref.watch(recentlyPlayedProvider);
    if (songs.isEmpty) return const SizedBox(height: AppSpacing.sm);

    final visibleSongs = songs.take(20).toList(growable: false);
    final isDesktop = ShellContext.isDesktopOf(context);
    final layout = ContentLayout.of(
      context,
      ref,
      itemWidth: isDesktop ? 240 : 320,
      minCols: 1,
      maxCols: isDesktop ? 3 : 1,
    );
    const gap = AppSpacing.sm;
    const rows = 2;

    final cols = isDesktop ? 3 : 1;
    final itemCount = (rows * cols).clamp(0, visibleSongs.length);
    final gridSongs = visibleSongs.take(itemCount).toList(growable: false);
    final actualRows = (gridSongs.length / cols).ceil();
    final tileH = isDesktop ? 72.0 : (cols > 2 ? 88.0 : 72.0);
    final totalGap = gap * (cols - 1);
    final tileW = ((layout.maxWidth - totalGap) / cols).floorToDouble();
    final gridH = tileH * actualRows + gap * (actualRows - 1);

    List<List<Song>> toRows(List<Song> items) {
      final rows = <List<Song>>[];
      for (var i = 0; i < items.length; i += cols) {
        rows.add(items.sublist(i, (i + cols).clamp(0, items.length)));
      }
      return rows;
    }

    Widget buildGrid(List<Song> items) {
      final chunkedRows = toRows(items);
      return SizedBox(
        height: gridH,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var r = 0; r < actualRows; r++) ...[
              if (r > 0) const SizedBox(height: gap),
              Row(
                children: [
                  if (r < chunkedRows.length)
                    for (var c = 0; c < chunkedRows[r].length; c++) ...[
                      if (c > 0) const SizedBox(width: gap),
                      SizedBox(
                        width: tileW,
                        height: tileH,
                        child: QuickPickTile(
                          song: chunkedRows[r][c],
                          height: tileH,
                          width: tileW,
                          onTap: () => widget.onPlay(chunkedRows[r][c]),
                        ),
                      ),
                    ],
                ],
              ),
            ],
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: AppSpacing.sm),
        SectionHeader(
          title: 'Recently Played',
          useCompactStyle: true,
          trailing: GestureDetector(
            onTap: () => Navigator.of(context).push(
              appPageRoute<void>(
                builder: (_) => const RecentlyPlayedScreen(),
              ),
            ),
            child: Text(
              'See all',
              style: TextStyle(
                color: AppColorsScheme.of(context).textPrimary,
                fontSize: AppFontSize.sm,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: layout.hPad),
          child: buildGrid(gridSongs),
        ),
        SizedBox(height: isDesktop ? DesktopSpacing.xxl : AppSpacing.xxl),
      ],
    );
  }
}
