import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tunify/core/constants/app_icons.dart';
import 'package:tunify/data/models/song.dart';
import 'package:tunify/features/library/library_provider.dart';
import 'package:tunify/features/player/lyrics_provider.dart';
import 'package:tunify/features/player/palette_provider.dart';
import 'package:tunify/features/player/player_state_provider.dart';
import 'package:tunify/ui/screens/desktop/player/player_screen.dart'
    show showQueueSheet, showLyricsSheet, showDevicesSheet, showSleepTimerSheet;
import 'package:tunify/ui/screens/shared/player/song_options_sheet.dart'
    show showSongOptionsSheet;
import 'package:tunify/ui/theme/app_colors.dart';
import 'package:tunify/ui/theme/design_tokens.dart';
import 'package:tunify/ui/screens/shared/player/player_controls.dart';
import 'package:tunify/ui/screens/shared/player/player_progress_bar.dart';
import 'package:tunify/ui/screens/shared/player/player_shared.dart';

class MobilePlayerScreen extends ConsumerStatefulWidget {
  const MobilePlayerScreen({super.key});

  @override
  ConsumerState<MobilePlayerScreen> createState() => _MobilePlayerScreenState();
}

class _MobilePlayerScreenState extends ConsumerState<MobilePlayerScreen>
    with SingleTickerProviderStateMixin {
  double _dragDy = 0;

  late AnimationController _artScaleCtrl;
  late Animation<double> _artScale;

  @override
  void initState() {
    super.initState();
    _artScaleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
      value: 1.0,
    );
    _artScale = Tween<double>(begin: 0.92, end: 1.0).animate(
      CurvedAnimation(parent: _artScaleCtrl, curve: Curves.easeOutCubic),
    );

    ref.listenManual(currentSongProvider, (_, next) {
      if (next != null) _fetchLyrics();
    });
    ref.listenManual(playerProvider.select((s) => s.isPlaying), (_, isPlaying) {
      if (isPlaying) {
        _artScaleCtrl.forward();
      } else {
        _artScaleCtrl.reverse();
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _fetchLyrics();
    });
  }

  void _fetchLyrics() {
    final song = ref.read(currentSongProvider);
    if (song != null) {
      ref.read(lyricsProvider.notifier).fetchForVideo(song.id);
    }
  }

  @override
  void dispose() {
    _artScaleCtrl.dispose();
    super.dispose();
  }

  void _close() => Navigator.of(context).pop();

  @override
  Widget build(BuildContext context) {
    final dominantColor = ref.watch(dominantColorProvider);

    final song = ref.watch(playerProvider.select((s) => s.currentSong));

    if (song == null) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Text('Nothing playing',
              style: TextStyle(color: AppColors.textMuted)),
        ),
      );
    }

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: GestureDetector(
        onVerticalDragEnd: (d) {
          final velocity = d.primaryVelocity ?? 0;
          if (velocity > 600 || _dragDy > 100) {
            _dragDy = 0;
            _close();
          } else {
            _dragDy = 0;
          }
        },
        onVerticalDragUpdate: (d) {
          if (d.delta.dy > 0) _dragDy += d.delta.dy;
        },
        onVerticalDragCancel: () => _dragDy = 0,
        child: Scaffold(
          backgroundColor: AppColors.background,
          body: Stack(
            fit: StackFit.expand,
            children: [
              RepaintBoundary(
                child: PlayerBlurredBackground(
                  url: song.thumbnailUrl,
                  dominantColor: dominantColor,
                ),
              ),
              SafeArea(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                  child: Column(
                    children: [
                      const SizedBox(height: AppSpacing.sm),
                      _buildTopBar(),
                      const Spacer(flex: 2),
                      _buildAlbumArt(song, dominantColor),
                      const Spacer(flex: 2),
                      _buildSongInfo(song),
                      const SizedBox(height: AppSpacing.xxl),
                      const RepaintBoundary(child: PlayerProgressBar()),
                      const SizedBox(height: AppSpacing.lg),
                      RepaintBoundary(
                        child: PlayerControls(dominantColor: dominantColor),
                      ),
                      const SizedBox(height: AppSpacing.xxl),
                      _buildExtraControls(dominantColor),
                      const SizedBox(height: AppSpacing.base),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    final status = ref.watch(playerProvider.select((s) => s.status));
    final label = switch (status) {
      PlayerStatus.loading || PlayerStatus.buffering => 'LOADING',
      PlayerStatus.paused => 'PAUSED',
      PlayerStatus.error => 'ERROR',
      _ => 'NOW PLAYING',
    };
    return Row(
      children: [
        PlayerGlassButton(
          icon: AppIcons.keyboardArrowDown,
          size: 24,
          onTap: _close,
        ),
        Expanded(
          child: Column(
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: Color(0xA6FFFFFF),
                  fontSize: AppFontSize.xs,
                  fontWeight: FontWeight.w600,
                  letterSpacing: AppLetterSpacing.label,
                ),
              ),
            ],
          ),
        ),
        PlayerGlassButton(
          icon: AppIcons.moreHoriz,
          size: 20,
          onTap: () {
            final currentSong = ref.read(playerProvider).currentSong;
            if (currentSong == null) return;
            showSongOptionsSheet(context, song: currentSong, ref: ref);
          },
        ),
      ],
    );
  }

  Widget _buildAlbumArt(Song song, Color dominantColor) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final artSize = screenWidth - (AppSpacing.xl * 2) - 32;
    final cachePx = (artSize * MediaQuery.devicePixelRatioOf(context)).round();

    return ScaleTransition(
      scale: _artScale,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onHorizontalDragEnd: (d) {
          final v = d.primaryVelocity ?? 0;
          final notifier = ref.read(playerProvider.notifier);
          if (v < -400) {
            notifier.playNext();
          } else if (v > 400) {
            notifier.playPrevious();
          }
        },
        child: Hero(
          tag: 'player-album-art',
          child: Container(
            width: artSize,
            height: artSize,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.xl),
              boxShadow: [
                BoxShadow(
                  color: dominantColor.withValues(
                      alpha: PaletteTheme.playerArtGlowAlpha),
                  blurRadius: 50,
                  spreadRadius: 5,
                  offset: const Offset(0, 12),
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.xl),
              child: Container(
                color: Colors.black.withValues(alpha: 0.22),
                child: CachedNetworkImage(
                  imageUrl: song.thumbnailUrl,
                  width: artSize,
                  height: artSize,
                  memCacheWidth: cachePx,
                  memCacheHeight: cachePx,
                  fit: BoxFit.contain,
                  errorWidget: (_, __, ___) => Container(
                    width: artSize,
                    height: artSize,
                    color: AppColors.surfaceLight,
                    child: AppIcon(
                        icon: AppIcons.musicNote,
                        color: AppColors.textMuted,
                        size: 80),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSongInfo(Song song) {
    final isLiked = ref
        .watch(libraryProvider.select((s) => s.likedSongIds.contains(song.id)));
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                song.title,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: AppFontSize.h2,
                  fontWeight: FontWeight.w700,
                  letterSpacing: AppLetterSpacing.heading,
                  height: AppLineHeight.normal,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                song.artist,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: AppFontSize.xl,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        GestureDetector(
          onTap: () => ref.read(libraryProvider.notifier).toggleLiked(song),
          child: AnimatedSwitcher(
            duration: AppDuration.fast,
            transitionBuilder: (child, anim) =>
                ScaleTransition(scale: anim, child: child),
            child: FavouriteIcon(
              key: ValueKey(isLiked),
              isLiked: isLiked,
              songId: song.id,
              size: 26,
              emptyColor: AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }

  void _showQueueSheet() => showQueueSheet(context);
  void _showLyricsSheet(Color dominantColor) =>
      showLyricsSheet(context, dominantColor: dominantColor);
  void _showDevicesSheet() => showDevicesSheet(context);
  void _showSleepTimerSheet() => showSleepTimerSheet(context);

  Widget _buildExtraControls(Color dominantColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        PlayerExtraButton(
            icon: AppIcons.devices, label: 'Devices', onTap: _showDevicesSheet),
        PlayerExtraButton(
            icon: AppIcons.lyrics,
            label: 'Lyrics',
            onTap: () => _showLyricsSheet(dominantColor)),
        PlayerExtraButton(
            icon: AppIcons.queueMusic, label: 'Queue', onTap: _showQueueSheet),
        PlayerExtraButton(
            icon: AppIcons.bedtime,
            label: 'Sleep',
            onTap: _showSleepTimerSheet),
      ],
    );
  }
}
