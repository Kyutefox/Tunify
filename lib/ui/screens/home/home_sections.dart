import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../config/app_icons.dart';
import '../../../models/artist.dart';
import '../../../models/mood.dart';
import '../../../models/playlist.dart';
import '../../../models/song.dart';
import '../../../shared/providers/content_settings_provider.dart';
import '../../../shared/providers/player_state_provider.dart';
import '../../desktop/desktop_right_sidebar.dart';
import '../../theme/app_colors.dart';
import '../../theme/design_tokens.dart';

import '../../components/ui/widgets/mood_browse_sheet.dart';
import '../../components/ui/widgets/now_playing_indicator.dart';
import '../../layout/shell_context.dart';
import 'home_shared.dart';

/// A stable [PageView] wrapper that lives outside [LayoutBuilder] to prevent
/// the [PageController] from being detached/reattached on every layout pass,
/// which causes `_elements.contains(element)` assertion failures.
class _StablePager extends StatelessWidget {
  const _StablePager({
    required this.height,
    required this.controller,
    required this.pages,
  });
  final double height;
  final PageController controller;
  final List<Widget> pages;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: PageView(
        controller: controller,
        children: pages,
      ),
    );
  }
}

class RecentlyPlayedRow extends StatelessWidget {
  const RecentlyPlayedRow({
    super.key,
    required this.songs,
    required this.onPlay,
  });
  final List<Song> songs;
  final void Function(Song song) onPlay;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 188,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const ClampingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.base),
        addRepaintBoundaries: false,
        addAutomaticKeepAlives: false,
        itemCount: songs.take(8).length,
        separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.md),
        itemBuilder: (ctx, i) => SquareSongCard(
          song: songs[i],
          onTap: () => onPlay(songs[i]),
        ),
      ),
    );
  }
}

class SquareSongCard extends ConsumerWidget {
  const SquareSongCard({super.key, required this.song, required this.onTap});
  final Song song;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentSong = ref.watch(currentSongProvider);
    final isActuallyPlaying = ref.watch(isPlayingProvider);
    final isNowPlaying = currentSong?.id == song.id;

    return PressScale(
      onTap: onTap,
      scale: 0.93,
      child: SizedBox(
        width: 148,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.md),
              clipBehavior: Clip.hardEdge,
              child: CachedNetworkImage(
                imageUrl: song.thumbnailUrl,
                width: 148,
                height: 148,
                fit: BoxFit.cover,
                fadeInDuration: Duration.zero,
                fadeOutDuration: Duration.zero,
                memCacheWidth: cachePx(context, 148),
                memCacheHeight: cachePx(context, 148),
                errorWidget: (_, __, ___) => PlaceholderArt(size: 148),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isNowPlaying)
                  Padding(
                    padding: const EdgeInsets.only(right: AppSpacing.xs),
                    child: SizedBox(
                      width: 10,
                      height: 10,
                      child: FittedBox(
                        fit: BoxFit.contain,
                        child: NowPlayingIndicator(
                          size: 8,
                          barCount: 3,
                          animate: isActuallyPlaying,
                        ),
                      ),
                    ),
                  ),
                Expanded(
                  child: Text(
                    song.title,
                    style: TextStyle(
                      color: isNowPlaying
                          ? AppColors.accent
                          : AppColors.textPrimary,
                      fontSize: AppFontSize.md,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            Text(
              song.artist,
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: AppFontSize.xs,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class QuickPicksRow extends ConsumerStatefulWidget {
  const QuickPicksRow({
    super.key,
    required this.songs,
    required this.onPlay,
    this.pageController,
  });
  final List<Song> songs;
  final void Function(Song song) onPlay;
  /// Optional external controller so the section header can drive page changes.
  final PageController? pageController;

  @override
  ConsumerState<QuickPicksRow> createState() => _QuickPicksRowState();
}

class _QuickPicksRowState extends ConsumerState<QuickPicksRow> {
  late final PageController _ctrl;
  bool _ownsController = false;
  int _page = 0;

  @override
  void initState() {
    super.initState();
    if (widget.pageController != null) {
      _ctrl = widget.pageController!;
    } else {
      _ctrl = PageController();
      _ownsController = true;
    }
    _ctrl.addListener(_onScroll);
  }

  void _onScroll() {
    final p = _ctrl.page?.round() ?? 0;
    if (p != _page) setState(() => _page = p);
  }

  @override
  void dispose() {
    _ctrl.removeListener(_onScroll);
    if (_ownsController) _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = ShellContext.isDesktopOf(context);
    final maxRows = 4;
    final tileH = isDesktop ? 76.0 : 64.0;
    final hPad = isDesktop ? AppSpacing.xl : AppSpacing.base;
    const gap = AppSpacing.sm;

    final capped = widget.songs.take(40).toList();

    // Use exact content-panel width so cols update immediately when sidebar opens.
    final double maxWidth;
    final int cols;
    if (isDesktop) {
      final rightOpen = ref.watch(rightSidebarTabProvider) != null;
      final screenW = MediaQuery.sizeOf(context).width;
      maxWidth = ShellContext.desktopContentInnerWidth(
        screenWidth: screenW,
        rightSidebarOpen: rightOpen,
        hPad: hPad,
      );
      cols = (maxWidth / 200).floor().clamp(2, 5);
    } else {
      maxWidth = MediaQuery.sizeOf(context).width - hPad * 2;
      cols = 2;
    }

    final pageSize = cols * maxRows;
    final gridItems = capped.take(pageSize).toList();
    final overflowItems = capped.length > pageSize ? capped.sublist(pageSize) : <Song>[];
    final hasOverflow = overflowItems.isNotEmpty;

    final totalGap = gap * (cols - 1);
    final tileW = ((maxWidth - totalGap) / cols).floorToDouble();
    final gridH = tileH * maxRows + gap * (maxRows - 1);

    final gridRows = <List<Song>>[];
    for (var i = 0; i < gridItems.length; i += cols) {
      gridRows.add(gridItems.sublist(i, (i + cols).clamp(0, gridItems.length)));
    }

    Widget buildGrid() => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var r = 0; r < gridRows.length; r++) ...[
              if (r > 0) const SizedBox(height: gap),
              Row(
                children: [
                  for (var c = 0; c < gridRows[r].length; c++) ...[
                    if (c > 0) const SizedBox(width: gap),
                    SizedBox(
                      width: tileW,
                      height: tileH,
                      child: QuickPickTile(
                        song: gridRows[r][c],
                        height: tileH,
                        width: tileW,
                        onTap: () => widget.onPlay(gridRows[r][c]),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ],
        );

    Widget buildOverflowGrid() {
      final cappedOverflow = overflowItems.take(pageSize).toList();
      final overflowRows = <List<Song>>[];
      for (var i = 0; i < cappedOverflow.length; i += cols) {
        overflowRows.add(cappedOverflow.sublist(i, (i + cols).clamp(0, cappedOverflow.length)));
      }
      return SizedBox(
        height: gridH,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var r = 0; r < overflowRows.length; r++) ...[
              if (r > 0) const SizedBox(height: gap),
              Row(
                children: [
                  for (var c = 0; c < overflowRows[r].length; c++) ...[
                    if (c > 0) const SizedBox(width: gap),
                    SizedBox(
                      width: tileW,
                      height: tileH,
                      child: QuickPickTile(
                        song: overflowRows[r][c],
                        height: tileH,
                        width: tileW,
                        onTap: () => widget.onPlay(overflowRows[r][c]),
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

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: hPad),
      child: hasOverflow
          ? _StablePager(
              height: gridH,
              controller: _ctrl,
              pages: [buildGrid(), buildOverflowGrid()],
            )
          : buildGrid(),
    );
  }
}

class QuickPickTile extends ConsumerWidget {
  const QuickPickTile({
    super.key,
    required this.song,
    required this.onTap,
    this.height = 64,
    this.width = 220,
  });
  final Song song;
  final VoidCallback onTap;
  final double height;
  final double width;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentSong = ref.watch(currentSongProvider);
    final isActuallyPlaying = ref.watch(isPlayingProvider);
    final isNowPlaying = currentSong?.id == song.id;

    return PressScale(
      onTap: onTap,
      scale: 0.96,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(
                left: Radius.circular(AppRadius.md),
              ),
              clipBehavior: Clip.hardEdge,
              child: CachedNetworkImage(
                imageUrl: song.thumbnailUrl,
                width: height,
                height: height,
                fit: BoxFit.cover,
                fadeInDuration: Duration.zero,
                fadeOutDuration: Duration.zero,
                memCacheWidth: cachePx(context, height),
                memCacheHeight: cachePx(context, height),
                errorWidget: (_, __, ___) => PlaceholderArt(size: height),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isNowPlaying)
                        Padding(
                          padding: const EdgeInsets.only(right: AppSpacing.xs),
                          child: SizedBox(
                            width: 10,
                            height: 10,
                            child: FittedBox(
                              fit: BoxFit.contain,
                              child: NowPlayingIndicator(
                                size: 8,
                                barCount: 3,
                                animate: isActuallyPlaying,
                              ),
                            ),
                          ),
                        ),
                      Expanded(
                        child: Text(
                          song.title,
                          style: TextStyle(
                            color: isNowPlaying
                                ? AppColors.accent
                                : AppColors.textPrimary,
                            fontSize: AppFontSize.md,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    song.artist,
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: AppFontSize.xs,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
          ],
        ),
      ),
    );
  }
}

class PlaylistsRow extends ConsumerStatefulWidget {
  const PlaylistsRow({super.key, required this.playlists, this.pageController});
  final List<Playlist> playlists;
  final PageController? pageController;

  @override
  ConsumerState<PlaylistsRow> createState() => _PlaylistsRowState();
}

class _PlaylistsRowState extends ConsumerState<PlaylistsRow> {
  late final PageController _ctrl;
  bool _ownsController = false;
  int _page = 0;

  @override
  void initState() {
    super.initState();
    if (widget.pageController != null) {
      _ctrl = widget.pageController!;
    } else {
      _ctrl = PageController();
      _ownsController = true;
    }
    _ctrl.addListener(_onScroll);
  }

  void _onScroll() {
    final p = _ctrl.page?.round() ?? 0;
    if (p != _page) setState(() => _page = p);
  }

  @override
  void dispose() {
    _ctrl.removeListener(_onScroll);
    if (_ownsController) _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = ShellContext.isDesktopOf(context);
    final hPad = isDesktop ? AppSpacing.xl : AppSpacing.base;
    const gap = AppSpacing.md;
    const rows = 1;

    final double maxWidth;
    final int cols;
    if (isDesktop) {
      final rightOpen = ref.watch(rightSidebarTabProvider) != null;
      final screenW = MediaQuery.sizeOf(context).width;
      maxWidth = ShellContext.desktopContentInnerWidth(
        screenWidth: screenW,
        rightSidebarOpen: rightOpen,
        hPad: hPad,
      );
      cols = (maxWidth / 160).floor().clamp(2, 5);
    } else {
      maxWidth = MediaQuery.sizeOf(context).width - hPad * 2;
      cols = 2;
    }

    final pageSize = cols * rows;
    final hasOverflow = widget.playlists.length > pageSize;
    final pageItems = widget.playlists.take(pageSize).toList();
    final overflowItems = hasOverflow ? widget.playlists.sublist(pageSize) : <Playlist>[];

    final tileW = ((maxWidth - gap * (cols - 1)) / cols).floorToDouble();
    final tileH = tileW + 48.0;
    final gridH = tileH * rows + gap * (rows - 1);

    Widget buildGrid() {
      final gridRows = <List<Playlist>>[];
      for (var i = 0; i < pageItems.length; i += cols) {
        gridRows.add(pageItems.sublist(i, (i + cols).clamp(0, pageItems.length)));
      }
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var r = 0; r < gridRows.length; r++) ...[
            if (r > 0) const SizedBox(height: gap),
            Row(
              children: [
                for (var c = 0; c < gridRows[r].length; c++) ...[
                  if (c > 0) const SizedBox(width: gap),
                  SizedBox(
                    width: tileW,
                    child: BrowsePlaylistCard(playlist: gridRows[r][c], size: tileW),
                  ),
                ],
              ],
            ),
          ],
        ],
      );
    }

    Widget buildOverflow() => SizedBox(
          height: gridH,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: overflowItems.length,
            separatorBuilder: (_, __) => const SizedBox(width: gap),
            itemBuilder: (_, i) => SizedBox(
              width: tileW,
              child: BrowsePlaylistCard(playlist: overflowItems[i], size: tileW),
            ),
          ),
        );

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: hPad),
      child: hasOverflow
          ? _StablePager(
              height: gridH,
              controller: _ctrl,
              pages: [buildGrid(), buildOverflow()],
            )
          : buildGrid(),
    );
  }
}

class BrowsePlaylistCard extends ConsumerStatefulWidget {
  const BrowsePlaylistCard({super.key, required this.playlist, this.size = 148});
  final Playlist playlist;
  final double size;

  @override
  ConsumerState<BrowsePlaylistCard> createState() =>
      _BrowsePlaylistCardState();
}

class _BrowsePlaylistCardState extends ConsumerState<BrowsePlaylistCard> {
  bool _loading = false;

  Future<void> _onTap() async {
    if (_loading) return;
    setState(() => _loading = true);
    try {
      final sm = ref.read(streamManagerProvider);
      final playlistId = widget.playlist.id;
      final result = await sm.getCollectionTracks(playlistId);
      final songs = result.tracks.map((t) => Song.fromTrack(t)).toList();
      if (!mounted) return;
      final showExplicit = ref.read(showExplicitContentProvider);
      final toPlay = filterByExplicitSetting(songs, showExplicit);
      if (toPlay.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No songs found in this playlist')),
        );
        setState(() => _loading = false);
        return;
      }
      ref.read(playerProvider.notifier).playSong(toPlay.first, queue: toPlay);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load playlist: $e')),
        );
      }
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final playlist = widget.playlist;
    final size = widget.size;
    return PressScale(
      onTap: _onTap,
      scale: 0.93,
      child: SizedBox(
        width: size,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  clipBehavior: Clip.hardEdge,
                  child: CachedNetworkImage(
                    imageUrl: playlist.coverUrl,
                    width: size,
                    height: size,
                    fit: BoxFit.cover,
                    fadeInDuration: Duration.zero,
                    fadeOutDuration: Duration.zero,
                    memCacheWidth: cachePx(context, size),
                    memCacheHeight: cachePx(context, size),
                    errorWidget: (_, __, ___) => PlaceholderArt(size: size),
                  ),
                ),
                if (_loading)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      child: const Center(
                        child: SizedBox(
                          width: 28,
                          height: 28,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              playlist.title,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: AppFontSize.md,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              playlist.curatorName ?? '${playlist.trackCount} songs',
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: AppFontSize.xs,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class MoodGrid extends StatelessWidget {
  const MoodGrid({super.key, required this.moods});
  final List<Mood> moods;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final tileWidth = (screenWidth - AppSpacing.base * 2 - AppSpacing.md) / 2;
    final tileHeight = tileWidth / 3.0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.base),
      child: Wrap(
        spacing: AppSpacing.md,
        runSpacing: AppSpacing.md,
        children: [
          for (int i = 0; i < moods.length; i++)
            SizedBox(
              width: tileWidth,
              height: tileHeight,
              child: HomeMoodTile(mood: moods[i]),
            ),
        ],
      ),
    );
  }
}

class HomeMoodTile extends StatelessWidget {
  const HomeMoodTile({super.key, required this.mood});
  final Mood mood;

  @override
  Widget build(BuildContext context) {
    return PressScale(
      onTap: () => showMoodBrowseSheet(context, initialMood: mood),
      child: Container(
        decoration: BoxDecoration(
          gradient: mood.gradient,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            mood.label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: AppFontSize.base,
              fontWeight: FontWeight.w700,
              shadows: [Shadow(color: Colors.black26, blurRadius: 4)],
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }
}

class ArtistsRow extends ConsumerStatefulWidget {
  const ArtistsRow({super.key, required this.artists, this.pageController});
  final List<Artist> artists;
  final PageController? pageController;

  @override
  ConsumerState<ArtistsRow> createState() => _ArtistsRowState();
}

class _ArtistsRowState extends ConsumerState<ArtistsRow> {
  late final PageController _ctrl;
  bool _ownsController = false;
  int _page = 0;

  @override
  void initState() {
    super.initState();
    if (widget.pageController != null) {
      _ctrl = widget.pageController!;
    } else {
      _ctrl = PageController();
      _ownsController = true;
    }
    _ctrl.addListener(_onScroll);
  }

  void _onScroll() {
    final p = _ctrl.page?.round() ?? 0;
    if (p != _page) setState(() => _page = p);
  }

  @override
  void dispose() {
    _ctrl.removeListener(_onScroll);
    if (_ownsController) _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = ShellContext.isDesktopOf(context);
    final hPad = isDesktop ? AppSpacing.xl : AppSpacing.base;
    const gap = AppSpacing.xl;
    const rows = 1;
    final avatarSize = isDesktop ? 88.0 : 72.0;
    final rowH = avatarSize + 28.0;
    final gridH = rowH * rows + gap * (rows - 1);

    final double maxWidth;
    final int cols;
    if (isDesktop) {
      final rightOpen = ref.watch(rightSidebarTabProvider) != null;
      final screenW = MediaQuery.sizeOf(context).width;
      maxWidth = ShellContext.desktopContentInnerWidth(
        screenWidth: screenW,
        rightSidebarOpen: rightOpen,
        hPad: hPad,
      );
      cols = (maxWidth / 160).floor().clamp(2, 5);
    } else {
      maxWidth = MediaQuery.sizeOf(context).width - hPad * 2;
      cols = 2;
    }

    final pageSize = cols * rows;
    final hasOverflow = widget.artists.length > pageSize;
    final pageItems = widget.artists.take(pageSize).toList();
    final overflowItems = hasOverflow ? widget.artists.sublist(pageSize) : <Artist>[];

    final itemW = ((maxWidth - gap * (cols - 1)) / cols).floorToDouble();

    Widget buildGrid() {
      final gridRows = <List<Artist>>[];
      for (var i = 0; i < pageItems.length; i += cols) {
        gridRows.add(pageItems.sublist(i, (i + cols).clamp(0, pageItems.length)));
      }
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var r = 0; r < gridRows.length; r++) ...[
            if (r > 0) const SizedBox(height: gap),
            Row(
              children: [
                for (var c = 0; c < gridRows[r].length; c++) ...[
                  if (c > 0) const SizedBox(width: gap),
                  SizedBox(
                    width: itemW,
                    height: rowH,
                    child: HomeArtistAvatar(artist: gridRows[r][c], size: avatarSize),
                  ),
                ],
              ],
            ),
          ],
        ],
      );
    }

    Widget buildOverflow() => SizedBox(
          height: gridH,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: overflowItems.length,
            separatorBuilder: (_, __) => const SizedBox(width: gap),
            itemBuilder: (_, i) => SizedBox(
              width: itemW,
              height: rowH,
              child: HomeArtistAvatar(artist: overflowItems[i], size: avatarSize),
            ),
          ),
        );

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: hPad),
      child: hasOverflow
          ? _StablePager(
              height: gridH,
              controller: _ctrl,
              pages: [buildGrid(), buildOverflow()],
            )
          : buildGrid(),
    );
  }
}

class HomeArtistAvatar extends StatelessWidget {
  const HomeArtistAvatar({super.key, required this.artist, this.size = 72});
  final Artist artist;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      child: Column(
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.glassBorder,
                width: 1.5,
              ),
            ),
            child: ClipOval(
              clipBehavior: Clip.hardEdge,
              child: CachedNetworkImage(
                imageUrl: artist.avatarUrl,
                fit: BoxFit.cover,
                fadeInDuration: Duration.zero,
                fadeOutDuration: Duration.zero,
                memCacheWidth: cachePx(context, size),
                memCacheHeight: cachePx(context, size),
                errorWidget: (_, __, ___) => Container(
                  color: AppColors.surface,
                  child: AppIcon(
                    icon: AppIcons.person,
                    color: AppColors.textMuted,
                    size: size * 0.44,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            artist.name,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: AppFontSize.xs,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
