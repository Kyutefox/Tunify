import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:tunify/v1/data/models/artist.dart';
import 'package:tunify/v1/data/models/playlist.dart';
import 'package:tunify/v1/data/models/song.dart';
import 'package:tunify/v1/features/home/home_state_provider.dart';
import 'package:tunify/v1/ui/theme/design_tokens.dart';
import 'package:tunify/v1/ui/theme/app_tokens.dart';
import 'package:tunify/v1/ui/widgets/common/section_header.dart';
import 'package:tunify/v1/ui/theme/app_colors_scheme.dart';
import 'home_sections.dart';
import 'home_shared.dart';

/// Full-home loading scaffold matching [HomeContent] structure 1:1 (except mood,
/// which is appended separately so [MoodSection] can own its loading state).
class HomePageSkeleton extends ConsumerStatefulWidget {
  const HomePageSkeleton({super.key, required this.onPlay});

  final void Function(Song song) onPlay;

  @override
  ConsumerState<HomePageSkeleton> createState() => _HomePageSkeletonState();
}

class _HomePageSkeletonState extends ConsumerState<HomePageSkeleton> {
  late final PageController _quickPicksCtrl;
  late final PageController _madeForYouCtrl;
  late final PageController _artistsCtrl;
  int _quickPicksPage = 0;
  int _madeForYouPage = 0;
  int _artistsPage = 0;

  @override
  void initState() {
    super.initState();
    _quickPicksCtrl = PageController();
    _quickPicksCtrl.addListener(_onQuickPicksScroll);
    _madeForYouCtrl = PageController();
    _madeForYouCtrl.addListener(_onMadeForYouScroll);
    _artistsCtrl = PageController();
    _artistsCtrl.addListener(_onArtistsScroll);
  }

  void _onQuickPicksScroll() {
    final p = _quickPicksCtrl.page?.round() ?? 0;
    if (p != _quickPicksPage) setState(() => _quickPicksPage = p);
  }

  void _onMadeForYouScroll() {
    final p = _madeForYouCtrl.page?.round() ?? 0;
    if (p != _madeForYouPage) setState(() => _madeForYouPage = p);
  }

  void _onArtistsScroll() {
    final p = _artistsCtrl.page?.round() ?? 0;
    if (p != _artistsPage) setState(() => _artistsPage = p);
  }

  @override
  void dispose() {
    _quickPicksCtrl.removeListener(_onQuickPicksScroll);
    _quickPicksCtrl.dispose();
    _madeForYouCtrl.removeListener(_onMadeForYouScroll);
    _madeForYouCtrl.dispose();
    _artistsCtrl.removeListener(_onArtistsScroll);
    _artistsCtrl.dispose();
    super.dispose();
  }

  /// Same grid as [RecentlyPlayedSection] (not the horizontal [RecentlyPlayedRow]).
  Widget _recentlyPlayedBlock() {
    final layout = ContentLayout.of(
      context,
      ref,
      itemWidth: 320,
      minCols: 1,
      maxCols: 1,
    );
    const gap = AppSpacing.sm;
    const rows = 2;
    final cols = 1;
    final itemCount = (rows * cols).clamp(0, _demoSongs.length);
    final gridSongs = _demoSongs.take(itemCount).toList(growable: false);
    final actualRows = (gridSongs.length / cols).ceil();
    final tileH = (cols > 2 ? 88.0 : 72.0);
    final totalGap = gap * (cols - 1);
    final tileW = ((layout.maxWidth - totalGap) / cols).floorToDouble();
    final gridH = tileH * actualRows + gap * (actualRows - 1);

    List<List<Song>> toRows(List<Song> items) {
      final out = <List<Song>>[];
      for (var i = 0; i < items.length; i += cols) {
        out.add(items.sublist(i, (i + cols).clamp(0, items.length)));
      }
      return out;
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
            onTap: () {},
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
        SizedBox(height: AppSpacing.xxl),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(homeIsLoadingProvider);
    final dynamicSections = ref.watch(homeDynamicSectionsProvider);
    final showDynamicPlaceholder = isLoading && dynamicSections.isEmpty;

    final qpLayout =
        ContentLayout.of(context, ref, itemWidth: 240, minCols: 1, maxCols: 3);
    const maxRows = 4;
    final qpPageSize = qpLayout.cols * maxRows;
    const qpCount = 12;
    final qpTotalPages = (qpCount / qpPageSize).ceil();
    final qpHasOverflow = qpTotalPages > 1;

    final libLayout = ContentLayout.of(context, ref);
    final mfTotalPages = (_demoPlaylists.length / libLayout.cols).ceil();
    final mfHasOverflow = mfTotalPages > 1;
    final arTotalPages = (_demoArtists.length / libLayout.cols).ceil();
    final arHasOverflow = arTotalPages > 1;

    return Skeletonizer(
      enabled: true,
      child: IgnorePointer(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _recentlyPlayedBlock(),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SectionHeader(
                  title: 'Quick Picks',
                  subtitle: 'Based on your taste',
                  subtitleFirst: true,
                  useCompactStyle: true,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (qpHasOverflow) ...[
                        HomeSectionNavButtonPair(
                          pageCtrl: _quickPicksCtrl,
                          currentPage: _quickPicksPage,
                          totalPages: qpTotalPages,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                      ],
                      PlayCircleButton(onTap: () {}),
                    ],
                  ),
                ),
                QuickPicksRow(
                  songs: _demoSongs.take(qpCount).toList(growable: false),
                  onPlay: widget.onPlay,
                  pageController: _quickPicksCtrl,
                ),
                SizedBox(height: AppSpacing.xxl),
              ],
            ),
            if (showDynamicPlaceholder) ...[
              const DynamicSectionsSkeleton(),
              SizedBox(height: AppSpacing.xxl),
            ],
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SectionHeader(
                  title: 'Made For You',
                  useCompactStyle: true,
                  trailing: mfHasOverflow
                      ? HomeSectionNavButtonPair(
                          pageCtrl: _madeForYouCtrl,
                          currentPage: _madeForYouPage,
                          totalPages: mfTotalPages,
                        )
                      : null,
                ),
                PlaylistsRow(
                  playlists: _demoPlaylists,
                  pageController: _madeForYouCtrl,
                ),
                SizedBox(height: AppSpacing.xxl),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SectionHeader(
                  title: 'Popular Artists',
                  useCompactStyle: true,
                  trailing: arHasOverflow
                      ? HomeSectionNavButtonPair(
                          pageCtrl: _artistsCtrl,
                          currentPage: _artistsPage,
                          totalPages: arTotalPages,
                        )
                      : null,
                ),
                ArtistsRow(
                  artists: _demoArtists,
                  pageController: _artistsCtrl,
                ),
                SizedBox(height: AppSpacing.xxl),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class SectionSkeleton extends StatelessWidget {
  const SectionSkeleton({
    super.key,
    required this.title,
    required this.child,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.base,
            0,
            AppSpacing.base,
            AppSpacing.md,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: AppFontSize.xl,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle!,
                        style: const TextStyle(fontSize: AppFontSize.sm),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        child,
      ],
    );
  }
}

class SectionAsyncSwap extends StatelessWidget {
  const SectionAsyncSwap({
    super.key,
    required this.isLoading,
    required this.hasData,
    required this.loadedChild,
    required this.loadingChild,
  });

  final bool isLoading;
  final bool hasData;
  final Widget loadedChild;
  final Widget loadingChild;

  @override
  Widget build(BuildContext context) {
    if (hasData) return loadedChild;
    if (isLoading) {
      return Skeletonizer(
        enabled: true,
        child: IgnorePointer(child: loadingChild),
      );
    }
    return const SizedBox.shrink();
  }
}

class QuickPicksRowSkeleton extends StatelessWidget {
  const QuickPicksRowSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return QuickPicksRow(songs: _demoSongs.take(12).toList(), onPlay: (_) {});
  }
}

class QuickPickTileSkeleton extends StatelessWidget {
  const QuickPickTileSkeleton({super.key, required this.height});
  final double height;

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}

class PlaylistsRowSkeleton extends StatelessWidget {
  const PlaylistsRowSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return PlaylistsRow(playlists: _demoPlaylists);
  }
}

class MoodGridSkeleton extends StatelessWidget {
  const MoodGridSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}

class ArtistsRowSkeleton extends StatelessWidget {
  const ArtistsRowSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ArtistsRow(artists: _demoArtists);
  }
}

class DynamicSectionsSkeleton extends StatelessWidget {
  const DynamicSectionsSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'Related songs',
          subtitle: 'Recommended',
          subtitleFirst: true,
          useCompactStyle: true,
        ),
        const QuickPicksRowSkeleton(),
        SizedBox(height: AppSpacing.xxl),
        const SectionHeader(
          title: 'You may like',
          useCompactStyle: true,
        ),
        const PlaylistsRowSkeleton(),
      ],
    );
  }
}

final _demoSongs = List.generate(
  16,
  (i) => Song(
    id: 'skeleton-song-$i',
    title: 'Loading song title $i',
    artist: 'Loading artist',
    thumbnailUrl: '',
    duration: const Duration(minutes: 3, seconds: 24),
  ),
);

final _demoPlaylists = List.generate(
  6,
  (i) => Playlist(
    id: 'skeleton-playlist-$i',
    title: 'Loading playlist $i',
    description: 'Loading',
    coverUrl: '',
    trackCount: 24,
  ),
);

final _demoArtists = List.generate(
  6,
  (i) => Artist(id: 'skeleton-artist-$i', name: 'Artist $i', avatarUrl: ''),
);
