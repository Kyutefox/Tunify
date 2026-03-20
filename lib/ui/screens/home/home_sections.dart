import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../config/app_icons.dart';
import '../../../models/artist.dart';
import '../../../models/mood.dart';
import '../../../models/playlist.dart';
import '../../../models/song.dart';
import '../../../shared/providers/content_settings_provider.dart';
import '../../../shared/providers/player_state_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/design_tokens.dart';

import '../../components/ui/widgets/mood_browse_sheet.dart';
import '../../components/ui/widgets/now_playing_indicator.dart';
import '../../layout/shell_context.dart';
import 'home_shared.dart';

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
                      fontSize: 13,
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
                fontSize: 11,
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

class QuickPicksRow extends StatelessWidget {
  const QuickPicksRow({
    super.key,
    required this.songs,
    required this.onPlay,
  });
  final List<Song> songs;
  final void Function(Song song) onPlay;

  static const int _perColumn = 4;

  @override
  Widget build(BuildContext context) {
    final isDesktop = ShellContext.isDesktopOf(context);
    final tileH = isDesktop ? 76.0 : 64.0;
    final tileW = isDesktop ? 264.0 : 220.0;
    const gap = AppSpacing.sm;
    final listH = tileH * _perColumn + gap * (_perColumn - 1);
    final hPad = isDesktop ? AppSpacing.xl : AppSpacing.base;

    final capped = songs.take(20).toList();
    final columns = <List<Song>>[];
    for (var i = 0; i < capped.length; i += _perColumn) {
      columns.add(capped.sublist(i, (i + _perColumn).clamp(0, capped.length)));
    }
    return SizedBox(
      height: listH,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const ClampingScrollPhysics(),
        padding: EdgeInsets.symmetric(horizontal: hPad),
        addRepaintBoundaries: false,
        addAutomaticKeepAlives: false,
        itemCount: columns.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.md),
        itemBuilder: (ctx, colIdx) {
          final col = columns[colIdx];
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(col.length, (rowIdx) {
              return Padding(
                padding: EdgeInsets.only(
                  bottom: rowIdx < col.length - 1 ? gap : 0,
                ),
                child: QuickPickTile(
                  song: col[rowIdx],
                  height: tileH,
                  width: tileW,
                  onTap: () => onPlay(col[rowIdx]),
                ),
              );
            }),
          );
        },
      ),
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
                            fontSize: 13,
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
                      fontSize: 11,
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

class PlaylistsRow extends StatelessWidget {
  const PlaylistsRow({super.key, required this.playlists});
  final List<Playlist> playlists;

  @override
  Widget build(BuildContext context) {
    final isDesktop = ShellContext.isDesktopOf(context);
    final cardSize = isDesktop ? 176.0 : 148.0;
    final rowHeight = cardSize + 48; // artwork + text labels
    final hPad = isDesktop ? AppSpacing.xl : AppSpacing.base;

    return SizedBox(
      height: rowHeight,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const ClampingScrollPhysics(),
        padding: EdgeInsets.symmetric(horizontal: hPad),
        addRepaintBoundaries: false,
        addAutomaticKeepAlives: false,
        itemCount: playlists.take(6).length,
        separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.md),
        itemBuilder: (ctx, i) => BrowsePlaylistCard(
          playlist: playlists[i],
          size: cardSize,
        ),
      ),
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
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              playlist.curatorName ?? '${playlist.trackCount} songs',
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 11,
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
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        showMoodBrowseSheet(context, initialMood: mood);
      },
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
              fontSize: 14,
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

class ArtistsRow extends StatelessWidget {
  const ArtistsRow({super.key, required this.artists});
  final List<Artist> artists;

  @override
  Widget build(BuildContext context) {
    final isDesktop = ShellContext.isDesktopOf(context);
    final avatarSize = isDesktop ? 88.0 : 72.0;
    final rowHeight = isDesktop ? 130.0 : 108.0;
    final separator = isDesktop ? AppSpacing.xxl : AppSpacing.xl;
    final hPad = isDesktop ? AppSpacing.xl : AppSpacing.base;

    return SizedBox(
      height: rowHeight,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const ClampingScrollPhysics(),
        padding: EdgeInsets.symmetric(horizontal: hPad),
        addRepaintBoundaries: false,
        addAutomaticKeepAlives: false,
        itemCount: artists.take(10).length,
        separatorBuilder: (_, __) => SizedBox(width: separator),
        itemBuilder: (ctx, i) => HomeArtistAvatar(
          artist: artists[i],
          size: avatarSize,
        ),
      ),
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
              fontSize: 11,
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
