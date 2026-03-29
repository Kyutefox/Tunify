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
    show showQueueSheet, showLyricsSheet, showDevicesSheet, showSleepTimerSheet,
        showPlaybackSpeedSheet, SpeedExtraButton;
import 'package:tunify/ui/screens/shared/player/song_options_sheet.dart'
    show showSongOptionsSheet;
import 'package:tunify/ui/theme/app_colors.dart';
import 'package:tunify/ui/theme/design_tokens.dart';
import 'package:tunify/ui/screens/shared/player/player_controls.dart';
import 'package:tunify/ui/screens/shared/player/player_progress_bar.dart';
import 'package:tunify/ui/screens/shared/player/player_shared.dart';
import 'package:tunify/ui/widgets/player/album_art_hero.dart';

class MobilePlayerScreen extends ConsumerStatefulWidget {
  const MobilePlayerScreen({super.key});

  @override
  ConsumerState<MobilePlayerScreen> createState() => _MobilePlayerScreenState();
}

class _MobilePlayerScreenState extends ConsumerState<MobilePlayerScreen>
    with SingleTickerProviderStateMixin {
  // ── Swipe-to-dismiss ──────────────────────────────────────────────────────
  // _dragOffset: live offset during user drag (drives setState once per pointer event)
  // _snapFromOffset: offset at the moment snap-back starts (used by AnimatedBuilder)
  double _dragOffset = 0;
  double _snapFromOffset = 0;
  double _dragDy = 0;

  late final AnimationController _snapBackCtrl;

  @override
  void initState() {
    super.initState();
    // No addListener — AnimatedBuilder reads _snapBackCtrl.value directly,
    // eliminating per-frame setState calls during the 300ms snap-back animation.
    _snapBackCtrl = AnimationController(vsync: this);
    ref.listenManual(currentSongProvider, (_, next) {
      if (next != null) _fetchLyrics();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _fetchLyrics();
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
    _snapBackCtrl.dispose();
    super.dispose();
  }

  void _close() => Navigator.of(context).pop();

  @override
  Widget build(BuildContext context) {
    final dominantColor = ref.watch(dominantColorProvider);

    final song = ref.watch(playerProvider.select((s) => s.currentSong));

    if (song == null) {
      return const Scaffold(
        backgroundColor: Color(0xFF121212),
        body: Center(
          child: Text('Nothing playing',
              style: TextStyle(color: Colors.white54)),
        ),
      );
    }

    final screenHeight = MediaQuery.sizeOf(context).height;

    // AnimatedBuilder reads the controller value on every animation tick without
    // calling setState — only the Transform widgets rebuild, not the full tree.
    return AnimatedBuilder(
      animation: _snapBackCtrl,
      builder: (context, child) {
        // During snap-back: derive offset from animation progress.
        // During drag: _snapBackCtrl is stopped at 0, so snapOffset = _snapFromOffset.
        final snapOffset = _snapFromOffset * (1.0 - _snapBackCtrl.value);
        // Live drag offset is only non-zero while the user is actively dragging.
        final totalOffset = _dragOffset + snapOffset;
        final dismissScale =
            1.0 - (totalOffset / screenHeight).clamp(0.0, 1.0) * 0.08;
        return Transform.translate(
          offset: Offset(0, totalOffset),
          child: Transform.scale(
            scale: dismissScale,
            child: child,
          ),
        );
      },
      child: GestureDetector(
        onVerticalDragUpdate: (d) {
          if (d.delta.dy > 0) {
            _snapBackCtrl.stop();
            _snapFromOffset = 0;
            setState(() {
              _dragDy += d.delta.dy;
              _dragOffset = _dragDy;
            });
          }
        },
        onVerticalDragEnd: (d) {
          final velocity = d.primaryVelocity ?? 0;
          if (velocity > 600 || _dragDy > 120) {
            _dragDy = 0;
            _dragOffset = 0;
            _close();
          } else {
            _snapFromOffset = _dragOffset;
            _dragOffset = 0;
            _dragDy = 0;
            _snapBackCtrl.value = 0.0;
            _snapBackCtrl.animateTo(
              1.0,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
            );
          }
        },
        onVerticalDragCancel: () {
          _snapFromOffset = _dragOffset;
          _dragOffset = 0;
          _dragDy = 0;
          _snapBackCtrl.value = 0.0;
          _snapBackCtrl.animateTo(
            1.0,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
          );
        },
        child: Scaffold(
          backgroundColor: const Color(0xFF121212),
          body: Stack(
            fit: StackFit.expand,
            children: [
              PlayerBlurredBackground(
                url: song.thumbnailUrl,
                dominantColor: dominantColor,
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
        ),      // Scaffold
      ),        // GestureDetector
    );          // AnimatedBuilder
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
                  color: AppColors.playerLabelSubtle,
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

    return GestureDetector(
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
      child: DecoratedBox(
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
        child: AlbumArtHero(
          url: song.thumbnailUrl,
          size: artSize,
          borderRadius: AppRadius.xl,
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
                  color: Colors.white,
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
                  color: AppColors.playerIconInactive,
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
          onTap: () {
            HapticFeedback.lightImpact();
            ref.read(libraryProvider.notifier).toggleLiked(song);
          },
          child: AnimatedSwitcher(
            duration: AppDuration.fast,
            transitionBuilder: (child, anim) =>
                ScaleTransition(scale: anim, child: child),
            child: FavouriteIcon(
              key: ValueKey(isLiked),
              isLiked: isLiked,
              songId: song.id,
              size: 26,
              emptyColor: AppColors.playerIconInactive,
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
  void _showPlaybackSpeedSheet() => showPlaybackSpeedSheet(context);

  Widget _buildExtraControls(Color dominantColor) {
    final speed = ref.watch(playerProvider.select((s) => s.playbackSpeed));
    final isSpeedActive = (speed - 1.0).abs() > 0.01;
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
        SpeedExtraButton(
            isActive: isSpeedActive,
            speed: speed,
            onTap: _showPlaybackSpeedSheet),
      ],
    );
  }
}
