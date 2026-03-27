import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'package:tunify/core/constants/app_icons.dart';
import 'package:tunify/data/models/artist.dart';
import 'package:tunify/data/models/mood.dart';
import 'package:tunify/data/models/playlist.dart';
import 'package:tunify/data/models/song.dart';
import 'package:tunify/ui/widgets/common/artist_avatar.dart';
import 'package:tunify/ui/widgets/player/mood_browse_sheet.dart';
import 'package:tunify/features/library/library_provider.dart';
import 'package:tunify/ui/screens/shared/library/library_playlist_screen.dart';
import 'package:tunify/ui/theme/app_routes.dart';
import 'package:tunify/ui/shell/shell_context.dart';
import 'package:tunify/ui/theme/app_colors.dart';
import 'package:tunify/ui/theme/design_tokens.dart';
import 'package:tunify/ui/widgets/common/button.dart';
import 'package:tunify/ui/screens/shared/player/song_options_sheet.dart';
import 'home_shared.dart';

/// A stable [PageView] wrapper that lives outside [LayoutBuilder] to prevent
/// the [PageController] from being detached/reattached on every layout pass.
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
      child: PageView(controller: controller, children: pages),
    );
  }
}

// ─── Recently Played ──────────────────────────────────────────────────────────

class RecentlyPlayedRow extends StatelessWidget {
  const RecentlyPlayedRow(
      {super.key, required this.songs, required this.onPlay});
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
        itemCount: songs.take(8).length,
        separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.md),
        itemBuilder: (ctx, i) =>
            SquareSongCard(song: songs[i], onTap: () => onPlay(songs[i])),
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
    final status = NowPlayingStatus.of(ref, song.id);

    return RepaintBoundary(
      child: PressScale(
      onTap: onTap,
      scale: 0.93,
      child: SizedBox(
        width: 148,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DpiAwareThumbnail(
              url: song.thumbnailUrl,
              size: 148,
              radius: AppRadius.md,
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (status.isNowPlaying)
                  InlineNowPlayingDot(animate: status.isPlaying),
                Expanded(
                  child: Text(
                    song.title,
                    style: TextStyle(
                      color: status.isNowPlaying
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
                  color: AppColors.textMuted, fontSize: AppFontSize.xs),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    ),
    );
  }
}

// ─── Quick Picks ──────────────────────────────────────────────────────────────

class QuickPicksRow extends ConsumerStatefulWidget {
  const QuickPicksRow({
    super.key,
    required this.songs,
    required this.onPlay,
    this.pageController,
  });
  final List<Song> songs;
  final void Function(Song song) onPlay;
  final PageController? pageController;

  @override
  ConsumerState<QuickPicksRow> createState() => _QuickPicksRowState();
}

class _QuickPicksRowState extends ConsumerState<QuickPicksRow>
    with PagedSectionMixin {
  // Use external controller when provided, otherwise fall back to mixin's.
  PageController get _ctrl => widget.pageController ?? pageCtrl;

  void _onExternalScroll() {
    final p = _ctrl.page?.round() ?? 0;
    if (p != currentPage) setState(() => currentPage = p);
  }

  @override
  void initState() {
    super.initState();
    widget.pageController?.addListener(_onExternalScroll);
  }

  @override
  void dispose() {
    widget.pageController?.removeListener(_onExternalScroll);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final layout =
        ContentLayout.of(context, ref, itemWidth: 240, minCols: 1, maxCols: 3);
    const maxRows = 4;
    final isDesktop = ShellContext.isDesktopOf(context);
    final tileH = isDesktop ? 72.0 : (layout.cols > 2 ? 88.0 : 72.0);
    const gap = AppSpacing.sm;

    final songs = widget.songs;
    final pageSize = layout.cols * maxRows;
    final totalPages = (songs.length / pageSize).ceil();
    final hasOverflow = totalPages > 1;

    final totalGap = gap * (layout.cols - 1);
    final tileW = ((layout.maxWidth - totalGap) / layout.cols).floorToDouble();
    final gridH = tileH * maxRows + gap * (maxRows - 1);

    List<List<Song>> toRows(List<Song> items) {
      final rows = <List<Song>>[];
      for (var i = 0; i < items.length; i += layout.cols) {
        rows.add(items.sublist(i, (i + layout.cols).clamp(0, items.length)));
      }
      return rows;
    }

    Widget buildPage(List<Song> items, int rowCount) {
      final rows = toRows(items);
      final actualRows = rows.length.clamp(1, maxRows);
      final h = tileH * actualRows + gap * (actualRows - 1);
      return SizedBox(
        height: h,
        child: OverflowBox(
          maxHeight: double.infinity,
          alignment: Alignment.topCenter,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var r = 0; r < rows.length; r++) ...[
                if (r > 0) const SizedBox(height: gap),
                Row(
                  children: [
                    for (var c = 0; c < rows[r].length; c++) ...[
                      if (c > 0) const SizedBox(width: gap),
                      SizedBox(
                        width: tileW,
                        height: tileH,
                        child: QuickPickTile(
                          song: rows[r][c],
                          height: tileH,
                          width: tileW,
                          onTap: () => widget.onPlay(rows[r][c]),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ],
          ),
        ),
      );
    }

    List<Widget> buildPages() {
      final pages = <Widget>[];
      for (var i = 0; i < songs.length; i += pageSize) {
        final end = (i + pageSize).clamp(0, songs.length);
        final pageItems = songs.sublist(i, end);
        final rowCount = (pageItems.length / layout.cols).ceil();
        pages.add(buildPage(pageItems, rowCount));
      }
      return pages;
    }

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: layout.hPad),
      child: hasOverflow
          ? _StablePager(
              height: gridH,
              controller: _ctrl,
              pages: buildPages(),
            )
          : buildPage(songs, (songs.length / layout.cols).ceil()),
    );
  }
}

class QuickPickTile extends ConsumerStatefulWidget {
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
  ConsumerState<QuickPickTile> createState() => _QuickPickTileState();
}

class _QuickPickTileState extends ConsumerState<QuickPickTile> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final status = NowPlayingStatus.of(ref, widget.song.id);
    final isDesktop = ShellContext.isDesktopOf(context);

    final thumbSize = widget.height - AppSpacing.sm * 2;
    final thumb = ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.sm),
      clipBehavior: Clip.hardEdge,
      child: CachedNetworkImage(
        imageUrl: widget.song.thumbnailUrl,
        width: thumbSize,
        height: thumbSize,
        fit: BoxFit.cover,
        fadeInDuration: Duration.zero,
        fadeOutDuration: Duration.zero,
        memCacheWidth: cachePx(context, thumbSize),
        memCacheHeight: cachePx(context, thumbSize),
        errorWidget: (_, __, ___) => PlaceholderArt(size: thumbSize),
      ),
    );

    final textContent = Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (status.isNowPlaying)
                InlineNowPlayingDot(animate: status.isPlaying),
              Expanded(
                child: Text(
                  widget.song.title,
                  style: TextStyle(
                    color: status.isNowPlaying
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
            widget.song.artist,
            style: const TextStyle(
                color: AppColors.textMuted, fontSize: AppFontSize.xs),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );

    Widget tile = AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        color: _hovered ? AppColors.surfaceLight : Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      padding: isDesktop
          ? const EdgeInsets.symmetric(horizontal: AppSpacing.sm)
          : EdgeInsets.zero,
      child: Row(
        children: [
          thumb,
          const SizedBox(width: AppSpacing.md),
          textContent,
          AnimatedOpacity(
            opacity: 1.0,
            duration: const Duration(milliseconds: 150),
            child: AppIconButton(
              icon: AppIcon(
                icon: AppIcons.moreVert,
                color: AppColors.textMuted,
                size: 18,
              ),
              onPressedWithContext: (btnCtx) => showSongOptionsSheet(
                context,
                song: widget.song,
                ref: ref,
                buttonContext: btnCtx,
              ),
              size: 32,
              iconSize: 18,
            ),
          ),
        ],
      ),
    );

    if (isDesktop) {
      tile = MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: tile,
      );
    }

    return PressScale(onTap: widget.onTap, scale: 0.96, child: tile);
  }
}

// ─── Playlists Row ────────────────────────────────────────────────────────────

class PlaylistsRow extends ConsumerStatefulWidget {
  const PlaylistsRow({super.key, required this.playlists, this.pageController});
  final List<Playlist> playlists;
  final PageController? pageController;

  @override
  ConsumerState<PlaylistsRow> createState() => _PlaylistsRowState();
}

class _PlaylistsRowState extends ConsumerState<PlaylistsRow>
    with PagedSectionMixin {
  PageController get _ctrl => widget.pageController ?? pageCtrl;

  void _onExternalScroll() {
    final p = _ctrl.page?.round() ?? 0;
    if (p != currentPage) setState(() => currentPage = p);
  }

  @override
  void initState() {
    super.initState();
    widget.pageController?.addListener(_onExternalScroll);
  }

  @override
  void dispose() {
    widget.pageController?.removeListener(_onExternalScroll);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final layout = ContentLayout.of(context, ref, itemWidth: 200, maxCols: 6);
    const gap = AppSpacing.md;
    const rows = 1;

    final pageSize = layout.cols * rows;
    final totalPages = (widget.playlists.length / pageSize).ceil();
    final hasOverflow = totalPages > 1;

    final tileW = ((layout.maxWidth - gap * (layout.cols - 1)) / layout.cols)
        .floorToDouble();
    final tileH = tileW + 48.0;
    final gridH = tileH * rows + gap * (rows - 1);

    List<List<Playlist>> toRows(List<Playlist> items) {
      final rows = <List<Playlist>>[];
      for (var i = 0; i < items.length; i += layout.cols) {
        rows.add(items.sublist(i, (i + layout.cols).clamp(0, items.length)));
      }
      return rows;
    }

    Widget buildGrid(List<Playlist> items) {
      final gridRows = toRows(items);
      return SizedBox(
        height: gridH,
        child: OverflowBox(
          maxHeight: double.infinity,
          alignment: Alignment.topCenter,
          child: Column(
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
                        child: BrowsePlaylistCard(
                            playlist: gridRows[r][c], size: tileW),
                      ),
                    ],
                  ],
                ),
              ],
            ],
          ),
        ),
      );
    }

    List<Widget> buildPages() {
      final pages = <Widget>[];
      for (var i = 0; i < widget.playlists.length; i += pageSize) {
        final end = (i + pageSize).clamp(0, widget.playlists.length);
        pages.add(buildGrid(widget.playlists.sublist(i, end)));
      }
      return pages;
    }

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: layout.hPad),
      child: hasOverflow
          ? _StablePager(height: gridH, controller: _ctrl, pages: buildPages())
          : buildGrid(widget.playlists),
    );
  }
}

class BrowsePlaylistCard extends ConsumerStatefulWidget {
  const BrowsePlaylistCard(
      {super.key, required this.playlist, this.size = 148});
  final Playlist playlist;
  final double size;

  @override
  ConsumerState<BrowsePlaylistCard> createState() => _BrowsePlaylistCardState();
}

class _BrowsePlaylistCardState extends ConsumerState<BrowsePlaylistCard> {
  void _onTap() {
    final saved = ref
        .read(libraryProvider)
        .playlists
        .any((p) => p.id == widget.playlist.id);
    final page = saved
        ? LibraryPlaylistScreen(playlistId: widget.playlist.id)
        : LibraryPlaylistScreen.remote(playlist: widget.playlist);
    if (!ShellContext.pushDetail(context, page)) {
      Navigator.of(context).push(appPageRoute<void>(builder: (_) => page));
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.size;
    return PressScale(
      onTap: _onTap,
      scale: 0.93,
      child: SizedBox(
        width: size,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DpiAwareThumbnail(
                url: widget.playlist.coverUrl,
                size: size,
                radius: AppRadius.md),
            const SizedBox(height: AppSpacing.sm),
            Text(
              widget.playlist.title,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: AppFontSize.md,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              widget.playlist.curatorName ??
                  '${widget.playlist.trackCount} songs',
              style: const TextStyle(
                  color: AppColors.textMuted, fontSize: AppFontSize.xs),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Mood Grid ────────────────────────────────────────────────────────────────

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
            horizontal: AppSpacing.md, vertical: AppSpacing.sm),
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

// ─── Artists Row ──────────────────────────────────────────────────────────────

class ArtistsRow extends ConsumerStatefulWidget {
  const ArtistsRow({super.key, required this.artists, this.pageController});
  final List<Artist> artists;
  final PageController? pageController;

  @override
  ConsumerState<ArtistsRow> createState() => _ArtistsRowState();
}

class _ArtistsRowState extends ConsumerState<ArtistsRow>
    with PagedSectionMixin {
  PageController get _ctrl => widget.pageController ?? pageCtrl;

  void _onExternalScroll() {
    final p = _ctrl.page?.round() ?? 0;
    if (p != currentPage) setState(() => currentPage = p);
  }

  @override
  void initState() {
    super.initState();
    widget.pageController?.addListener(_onExternalScroll);
  }

  @override
  void dispose() {
    widget.pageController?.removeListener(_onExternalScroll);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final layout = ContentLayout.of(context, ref, itemWidth: 200, maxCols: 6);
    const gap = AppSpacing.xl;
    const rows = 1;
    final avatarSize = layout.cols > 2 ? 88.0 : 72.0;
    final rowH = avatarSize + 28.0;
    final gridH = rowH * rows + gap * (rows - 1);

    final pageSize = layout.cols * rows;
    final totalPages = (widget.artists.length / pageSize).ceil();
    final hasOverflow = totalPages > 1;

    final itemW = ((layout.maxWidth - gap * (layout.cols - 1)) / layout.cols)
        .floorToDouble();

    List<List<Artist>> toRows(List<Artist> items) {
      final rows = <List<Artist>>[];
      for (var i = 0; i < items.length; i += layout.cols) {
        rows.add(items.sublist(i, (i + layout.cols).clamp(0, items.length)));
      }
      return rows;
    }

    Widget buildGrid(List<Artist> items) {
      final gridRows = toRows(items);
      return SizedBox(
        height: gridH,
        child: OverflowBox(
          maxHeight: double.infinity,
          alignment: Alignment.topCenter,
          child: Column(
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
                        child: ArtistAvatar(
                          artist: gridRows[r][c],
                          size: avatarSize,
                          compact: true,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ],
          ),
        ),
      );
    }

    List<Widget> buildPages() {
      final pages = <Widget>[];
      for (var i = 0; i < widget.artists.length; i += pageSize) {
        final end = (i + pageSize).clamp(0, widget.artists.length);
        pages.add(buildGrid(widget.artists.sublist(i, end)));
      }
      return pages;
    }

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: layout.hPad),
      child: hasOverflow
          ? _StablePager(height: gridH, controller: _ctrl, pages: buildPages())
          : buildGrid(widget.artists),
    );
  }
}
