import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config/app_icons.dart';
import '../components/ui/button.dart';
import '../../shared/providers/library_provider.dart';
import '../../shared/providers/palette_provider.dart';
import '../../shared/providers/player_state_provider.dart';
import '../../shared/providers/sleep_timer_provider.dart';
import '../screens/player/player_progress_bar.dart';
import '../screens/player/player_screen.dart';
import '../screens/player/song_options_sheet.dart';
import '../theme/app_colors.dart';
import '../theme/design_tokens.dart';
import 'desktop_right_sidebar.dart';

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
    final dominantColor = ref.watch(dominantColorProvider);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutCubic,
      height: 92,
      decoration: BoxDecoration(
        color: hasSong
            ? Color.lerp(AppColors.background, dominantColor, 0.10)!
            : AppColors.background,
        border: Border(
          top: BorderSide(
            color: hasSong
                ? dominantColor.withValues(alpha: 0.18)
                : AppColors.glassBorder,
            width: 0.5,
          ),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.base),
      child: hasSong
          ? const Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Left: song info
                Expanded(flex: 3, child: _SongInfo()),
                // Center: controls + seek bar
                Expanded(flex: 4, child: _CenterControls()),
                // Right: extra controls + volume
                Expanded(flex: 3, child: _RightControls()),
              ],
            )
          : const Center(
              child: Text(
                'Play a song to get started',
                style: TextStyle(color: AppColors.textMuted, fontSize: AppFontSize.md),
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

    final isLiked = ref.watch(
        libraryProvider.select((s) => s.likedSongIds.contains(song.id)));

    return Row(
      children: [
        // Album art
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.xs),
          child: CachedNetworkImage(
            imageUrl: song.thumbnailUrl,
            width: 56,
            height: 56,
            fit: BoxFit.cover,
            errorWidget: (_, __, ___) => Container(
              width: 56,
              height: 56,
              color: AppColors.surfaceLight,
              child: Center(
                child: AppIcon(
                  icon: AppIcons.musicNote,
                  size: 24,
                  color: AppColors.textMuted,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.md),

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
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: AppFontSize.md,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                song.artist,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: AppFontSize.sm,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.md),

        // Like button — same FavouriteIcon used in mobile mini player
        AppIconButton(
          icon: FavouriteIcon(
            isLiked: isLiked,
            songId: song.id,
            size: 20,
            emptyColor: AppColors.textSecondary,
          ),
          onPressed: () =>
              ref.read(libraryProvider.notifier).toggleLiked(song),
          size: 36,
          iconSize: 20,
        ),

        // More options
        _BarIconBtn(
          isActive: false,
          activeIcon: AppIcon(
              icon: AppIcons.moreHoriz, size: 18, color: AppColors.primary),
          inactiveIcon: AppIcon(
              icon: AppIcons.moreHoriz,
              size: 18,
              color: AppColors.textSecondary),
          onTap: (btnCtx) => showSongOptionsSheet(context, song: song, ref: ref, buttonContext: btnCtx),
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
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Controls row
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AppIconButton(
                icon: AppIcon(
                  icon: AppIcons.shuffle,
                  size: 18,
                  color: isShuffleEnabled
                      ? AppColors.primary
                      : Colors.white.withValues(alpha: 0.75),
                ),
                onPressed: notifier.toggleShuffle,
                size: 30,
                iconSize: 18,
              ),
              const SizedBox(width: 16),
              AppIconButton(
                icon: AppIcon(
                  icon: AppIcons.skipPrevious,
                  size: 20,
                  color: canPrev
                      ? Colors.white.withValues(alpha: 0.75)
                      : Colors.white.withValues(alpha: 0.3),
                ),
                onPressed: canPrev ? notifier.playPrevious : null,
                size: 32,
                iconSize: 20,
              ),
              const SizedBox(width: 12),
              _PlayPauseBtn(
                isPlaying: isPlaying,
                isLoading: isLoading,
                onTap: notifier.togglePlayPause,
              ),
              const SizedBox(width: 12),
              AppIconButton(
                icon: AppIcon(
                  icon: AppIcons.skipNext,
                  size: 20,
                  color: canNext
                      ? Colors.white.withValues(alpha: 0.75)
                      : Colors.white.withValues(alpha: 0.3),
                ),
                onPressed: canNext ? notifier.playNext : null,
                size: 32,
                iconSize: 20,
              ),
              const SizedBox(width: 16),
              AppIconButton(
                icon: AppIcon(
                  icon: repeatIcon,
                  size: 18,
                  color: isRepeat
                      ? AppColors.primary
                      : Colors.white.withValues(alpha: 0.75),
                ),
                onPressed: notifier.cycleRepeatMode,
                size: 30,
                iconSize: 18,
              ),
            ],
          ),
          const SizedBox(height: 4),

          // Seek bar — reuses PlayerProgressBar with compact dimensions
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
    final sleepActive =
        ref.watch(sleepTimerProvider.select((s) => s.isActive));
    final activeTab = ref.watch(rightSidebarTabProvider);
    final dominantColor = ref.watch(dominantColorProvider);

    final volIcon = _volume == 0
        ? AppIcons.volumeOff
        : _volume < 0.5
            ? AppIcons.volumeLow
            : AppIcons.volumeHigh;

    // Returns the icon color for a sidebar-toggle button.
    Color tabColor(RightSidebarTab tab) => activeTab == tab
        ? AppColors.primary
        : Colors.white.withValues(alpha: 0.75);

    void toggleTab(RightSidebarTab tab) {
      final notifier = ref.read(rightSidebarTabProvider.notifier);
      notifier.state = activeTab == tab ? null : tab;
    }

    // Layout: [sleep · lyrics] [vol-icon ── vol-slider ──] [queue · devices]
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        // ── Left pair ────────────────────────────────────────────────────
        AppIconButton(
          icon: AppIcon(
            icon: AppIcons.bedtime,
            size: 18,
            color: sleepActive
                ? AppColors.primary
                : Colors.white.withValues(alpha: 0.75),
          ),
          onPressed: () => showSleepTimerSheet(context),
          size: 30,
          iconSize: 18,
        ),
        const SizedBox(width: 2),
        AppIconButton(
          icon: AppIcon(
            icon: AppIcons.lyrics,
            size: 18,
            color: tabColor(RightSidebarTab.lyrics),
          ),
          onPressed: () => toggleTab(RightSidebarTab.lyrics),
          size: 30,
          iconSize: 18,
          tooltip: 'Lyrics',
        ),
        const SizedBox(width: 8),

        // ── Volume (icon + slider) ────────────────────────────────────────
        GestureDetector(
          onTap: () =>
              setState(() => _volume = _volume == 0 ? 1.0 : 0),
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xs),
            child: AppIcon(icon: volIcon, color: Colors.white.withValues(alpha: 0.75), size: 18),
          ),
        ),
        const SizedBox(width: 4),
        SizedBox(
          width: 96,
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: dominantColor,
              inactiveTrackColor: dominantColor.withValues(alpha: 0.25),
              thumbColor: dominantColor,
              overlayColor: dominantColor.withValues(alpha: 0.15),
              trackHeight: 3,
              thumbShape:
                  const RoundSliderThumbShape(enabledThumbRadius: 5),
              overlayShape:
                  const RoundSliderOverlayShape(overlayRadius: 10),
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
        const SizedBox(width: 8),

        // ── Right pair ───────────────────────────────────────────────────
        AppIconButton(
          icon: AppIcon(
            icon: AppIcons.queueMusic,
            size: 18,
            color: tabColor(RightSidebarTab.queue),
          ),
          onPressed: () => toggleTab(RightSidebarTab.queue),
          size: 30,
          iconSize: 18,
          tooltip: 'Queue',
        ),
        const SizedBox(width: 2),
        AppIconButton(
          icon: AppIcon(
            icon: AppIcons.devices,
            size: 18,
            color: tabColor(RightSidebarTab.devices),
          ),
          onPressed: () => toggleTab(RightSidebarTab.devices),
          size: 30,
          iconSize: 18,
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
        width: 36,
        height: 36,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
        ),
        child: Center(
          child: isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                        AppColors.background),
                  ),
                )
              : SizedBox(
                  width: 18,
                  height: 18,
                  child: AnimatedSwitcher(
                    duration: AppDuration.fast,
                    child: AppIcon(
                      key: ValueKey(isPlaying),
                      icon: isPlaying ? AppIcons.pause : AppIcons.play,
                      size: 18,
                      color: AppColors.background,
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

