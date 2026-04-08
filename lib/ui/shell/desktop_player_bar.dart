import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tunify/core/constants/app_icons.dart';
import 'package:tunify/ui/widgets/common/button.dart';
import 'package:tunify/features/library/library_provider.dart';
import 'package:tunify/features/player/player_state_provider.dart';
import 'package:tunify/features/player/sleep_timer_provider.dart';
import '../screens/shared/player/player_progress_bar.dart';
import '../screens/desktop/player/player_screen.dart';
import '../screens/shared/player/song_options_sheet.dart';
import 'package:tunify/ui/theme/app_colors.dart';
import 'package:tunify/ui/theme/design_tokens.dart';
import 'package:tunify/ui/theme/desktop_tokens.dart';
import 'desktop_right_sidebar.dart';
import 'package:tunify/ui/theme/app_colors_scheme.dart';

/// Full-width persistent player bar matching the Spotify desktop layout.
///
/// ```
/// ┌─────────────────────────────────────────────────────────────────┐
/// │ [art][title/artist][♥]  [shuffle][⏮][▶][⏭][repeat]  [lyrics][queue][device][vol──] │
/// │                         0:29 ──────────────────── 2:52         │
/// └─────────────────────────────────────────────────────────────────┘
/// ```
class DesktopPlayerBar extends ConsumerWidget {
  const DesktopPlayerBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasSong = ref.watch(currentSongProvider) != null;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      height: DesktopLayout.playerBarHeight,
      decoration: const BoxDecoration(),
      padding: const EdgeInsets.symmetric(horizontal: DesktopSpacing.base),
      child: hasSong
          ? const Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(flex: 4, child: _SongInfo()),
                Expanded(flex: 3, child: _CenterControls()),
                Expanded(flex: 4, child: _RightControls()),
              ],
            )
          : Center(
              child: Text(
                'Play a song to get started',
                style: TextStyle(
                  color: AppColorsScheme.of(context).textMuted,
                  fontSize: DesktopFontSize.base,
                ),
              ),
            ),
    );
  }
}

// ── Left: song info ───────────────────────────────────────────────────────────

class _SongInfo extends ConsumerWidget {
  const _SongInfo();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final song = ref.watch(currentSongProvider);
    if (song == null) return const SizedBox.shrink();

    final isLiked = ref
        .watch(libraryProvider.select((s) => s.likedSongIds.contains(song.id)));

    return Row(
      children: [
        // Album art
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.xs),
          child: SizedBox(
            width: DesktopLayout.playerArtSize,
            height: DesktopLayout.playerArtSize,
            child: CachedNetworkImage(
              imageUrl: song.thumbnailUrl,
              width: DesktopLayout.playerArtSize,
              height: DesktopLayout.playerArtSize,
              memCacheWidth: (DesktopLayout.playerArtSize *
                      MediaQuery.devicePixelRatioOf(context))
                  .round(),
              memCacheHeight: (DesktopLayout.playerArtSize *
                      MediaQuery.devicePixelRatioOf(context))
                  .round(),
              fit: BoxFit.cover,
              errorWidget: (_, __, ___) => Container(
                width: DesktopLayout.playerArtSize,
                height: DesktopLayout.playerArtSize,
                color: AppColorsScheme.of(context).surfaceLight,
                child: Center(
                  child: AppIcon(
                    icon: AppIcons.musicNote,
                    size: DesktopIconSize.md,
                    color: AppColorsScheme.of(context).textMuted,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: DesktopSpacing.md),

        // Title + artist
        Flexible(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                song.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: AppColorsScheme.of(context).textPrimary,
                  fontSize: DesktopFontSize.lg,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                song.artist,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: AppColorsScheme.of(context).desktopTextSecondary,
                  fontSize: DesktopFontSize.sm,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: DesktopSpacing.sm),

        // Like button
        AppIconButton(
          icon: FavouriteIcon(
            isLiked: isLiked,
            songId: song.id,
            size: DesktopIconSize.sm,
            emptyColor: AppColorsScheme.of(context).textSecondary,
          ),
          onPressed: () => ref.read(libraryProvider.notifier).toggleLiked(song),
          size: DesktopButtonSize.md,
          iconSize: DesktopIconSize.sm,
        ),

        // More options
        _BarIconBtn(
          isActive: false,
          activeIcon: AppIcon(
              icon: AppIcons.moreHoriz,
              size: DesktopIconSize.sm,
              color: AppColors.primary),
          inactiveIcon: AppIcon(
              icon: AppIcons.moreHoriz,
              size: DesktopIconSize.sm,
              color: AppColorsScheme.of(context).textSecondary),
          onTap: (btnCtx) => showSongOptionsSheet(context,
              song: song, ref: ref, buttonContext: btnCtx),
        ),
      ],
    );
  }
}

// ── Center: playback controls + seek bar ─────────────────────────────────────

class _CenterControls extends ConsumerWidget {
  const _CenterControls();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPlaying = ref.watch(playerProvider.select((s) => s.isPlaying));
    final isLoading = ref.watch(playerProvider.select((s) => s.isLoading));
    final isShuffleEnabled =
        ref.watch(playerProvider.select((s) => s.isShuffleEnabled));
    final repeatMode = ref.watch(playerProvider.select((s) => s.repeatMode));
    final canNext = ref.watch(playerProvider.select((s) => s.canPlayNext));
    final canPrev = ref.watch(playerProvider.select((s) => s.canPlayPrevious));
    final notifier = ref.read(playerProvider.notifier);

    final isRepeat = repeatMode != PlayerRepeatMode.off;
    final repeatIcon = repeatMode == PlayerRepeatMode.one
        ? AppIcons.repeatOne
        : AppIcons.repeat;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: DesktopSpacing.sm),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AppIconButton(
                icon: AppIcon(
                  icon: AppIcons.shuffle,
                  size: DesktopIconSize.sm,
                  color: isShuffleEnabled
                      ? AppColors.primary
                      : AppColorsScheme.of(context).textSecondary,
                ),
                onPressed: notifier.toggleShuffle,
                size: DesktopButtonSize.sm,
                iconSize: DesktopIconSize.sm,
              ),
              const SizedBox(width: DesktopSpacing.md),
              AppIconButton(
                icon: AppIcon(
                  icon: AppIcons.skipPrevious,
                  size: DesktopIconSize.md,
                  color: canPrev
                      ? AppColorsScheme.of(context).textSecondary
                      : AppColorsScheme.of(context).textMuted,
                ),
                onPressed: canPrev ? notifier.playPrevious : null,
                size: DesktopButtonSize.md,
                iconSize: DesktopIconSize.md,
              ),
              const SizedBox(width: DesktopSpacing.sm),
              _PlayPauseBtn(
                isPlaying: isPlaying,
                isLoading: isLoading,
                onTap: notifier.togglePlayPause,
              ),
              const SizedBox(width: DesktopSpacing.sm),
              AppIconButton(
                icon: AppIcon(
                  icon: AppIcons.skipNext,
                  size: DesktopIconSize.md,
                  color: canNext
                      ? AppColorsScheme.of(context).textSecondary
                      : AppColorsScheme.of(context).textMuted,
                ),
                onPressed: canNext ? notifier.playNext : null,
                size: DesktopButtonSize.md,
                iconSize: DesktopIconSize.md,
              ),
              const SizedBox(width: DesktopSpacing.md),
              AppIconButton(
                icon: AppIcon(
                  icon: repeatIcon,
                  size: DesktopIconSize.sm,
                  color: isRepeat
                      ? AppColors.primary
                      : AppColorsScheme.of(context).textSecondary,
                ),
                onPressed: notifier.cycleRepeatMode,
                size: DesktopButtonSize.sm,
                iconSize: DesktopIconSize.sm,
              ),
            ],
          ),
          const SizedBox(height: 4),
          const PlayerProgressBar(compact: true),
        ],
      ),
    );
  }
}

// ── Right: lyrics / queue / device / volume ───────────────────────────────────

class _RightControls extends ConsumerStatefulWidget {
  const _RightControls();

  @override
  ConsumerState<_RightControls> createState() => _RightControlsState();
}

class _RightControlsState extends ConsumerState<_RightControls> {
  double _volume = 1.0;

  @override
  Widget build(BuildContext context) {
    final sleepActive = ref.watch(sleepTimerProvider.select((s) => s.isActive));
    final activeTab = ref.watch(rightSidebarTabProvider);

    final volIcon = _volume == 0
        ? AppIcons.volumeOff
        : _volume < 0.5
            ? AppIcons.volumeLow
            : AppIcons.volumeHigh;

    // Returns the icon color for a sidebar-toggle button.
    Color tabColor(RightSidebarTab tab) => activeTab == tab
        ? AppColors.primary
        : AppColorsScheme.of(context).textSecondary;

    void toggleTab(RightSidebarTab tab) {
      final notifier = ref.read(rightSidebarTabProvider.notifier);
      notifier.set(activeTab == tab ? null : tab);
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        AppIconButton(
          icon: AppIcon(
            icon: AppIcons.bedtime,
            size: DesktopIconSize.sm,
            color: sleepActive
                ? AppColors.primary
                : AppColorsScheme.of(context).textSecondary,
          ),
          onPressed: () => showSleepTimerSheet(context),
          size: DesktopButtonSize.sm,
          iconSize: DesktopIconSize.sm,
        ),
        AppIconButton(
          icon: AppIcon(
            icon: AppIcons.lyrics,
            size: DesktopIconSize.sm,
            color: tabColor(RightSidebarTab.lyrics),
          ),
          onPressed: () => toggleTab(RightSidebarTab.lyrics),
          size: DesktopButtonSize.sm,
          iconSize: DesktopIconSize.sm,
          tooltip: 'Lyrics',
        ),
        const SizedBox(width: DesktopSpacing.xs),

        // Volume icon + slider
        GestureDetector(
          onTap: () => setState(() => _volume = _volume == 0 ? 1.0 : 0),
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: const EdgeInsets.all(DesktopSpacing.xs),
            child: AppIcon(
              icon: volIcon,
              color: AppColorsScheme.of(context).textSecondary,
              size: DesktopIconSize.sm,
            ),
          ),
        ),
        SizedBox(
          width: DesktopLayout.volumeSliderWidth,
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: AppColorsScheme.of(context).textPrimary,
              inactiveTrackColor: AppColorsScheme.of(context)
                  .textPrimary
                  .withValues(alpha: 0.25),
              thumbColor: AppColorsScheme.of(context).textPrimary,
              overlayColor: AppColorsScheme.of(context)
                  .textPrimary
                  .withValues(alpha: 0.15),
              trackHeight: 3,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 10),
            ),
            child: Slider(
              value: _volume,
              onChanged: (v) {
                setState(() => _volume = v);
                ref.read(playerProvider.notifier).setVolume(v);
              },
            ),
          ),
        ),
        const SizedBox(width: DesktopSpacing.xs),

        AppIconButton(
          icon: AppIcon(
            icon: AppIcons.queueMusic,
            size: DesktopIconSize.sm,
            color: tabColor(RightSidebarTab.queue),
          ),
          onPressed: () => toggleTab(RightSidebarTab.queue),
          size: DesktopButtonSize.sm,
          iconSize: DesktopIconSize.sm,
          tooltip: 'Queue',
        ),
        AppIconButton(
          icon: AppIcon(
            icon: AppIcons.devices,
            size: DesktopIconSize.sm,
            color: tabColor(RightSidebarTab.devices),
          ),
          onPressed: () => toggleTab(RightSidebarTab.devices),
          size: DesktopButtonSize.sm,
          iconSize: DesktopIconSize.sm,
          tooltip: 'Connect',
        ),
      ],
    );
  }
}

// ── Shared helper widgets ─────────────────────────────────────────────────────

class _PlayPauseBtn extends StatelessWidget {
  const _PlayPauseBtn({
    required this.isPlaying,
    required this.isLoading,
    required this.onTap,
  });

  final bool isPlaying;
  final bool isLoading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: DesktopButtonSize.lg,
        height: DesktopButtonSize.lg,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
        ),
        child: Center(
          child: isLoading
              ? SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                        AppColorsScheme.of(context).background),
                  ),
                )
              : SizedBox(
                  width: DesktopIconSize.md,
                  height: DesktopIconSize.md,
                  child: AnimatedSwitcher(
                    duration: AppDuration.fast,
                    child: AppIcon(
                      key: ValueKey(isPlaying),
                      icon: isPlaying ? AppIcons.pause : AppIcons.play,
                      size: DesktopIconSize.md,
                      color: AppColorsScheme.of(context).background,
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}

class _BarIconBtn extends StatelessWidget {
  const _BarIconBtn({
    required this.isActive,
    required this.activeIcon,
    required this.inactiveIcon,
    required this.onTap,
  });

  final bool isActive;
  final Widget activeIcon;
  final Widget inactiveIcon;
  final void Function(BuildContext ctx) onTap;

  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (ctx) => GestureDetector(
        onTap: () => onTap(ctx),
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: SizedBox(
            width: 20,
            height: 20,
            child: AnimatedSwitcher(
              duration: AppDuration.fast,
              child: isActive
                  ? KeyedSubtree(key: const ValueKey('a'), child: activeIcon)
                  : KeyedSubtree(key: const ValueKey('i'), child: inactiveIcon),
            ),
          ),
        ),
      ),
    );
  }
}
