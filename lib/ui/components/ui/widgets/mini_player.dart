import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../config/app_icons.dart';
import '../../../../models/song.dart';
import '../../../../shared/providers/library_provider.dart';
import '../../../../shared/providers/player_state_provider.dart';
import '../../../../ui/layout/shell_context.dart';
import '../../../../ui/screens/player_screen.dart';
import '../../../../ui/theme/app_colors.dart';
import '../../../../ui/theme/design_tokens.dart';
import 'mini_player_play_button.dart';

void openFullPlayerRoute(BuildContext context) {
  Navigator.of(context).push(
    PageRouteBuilder(
      opaque: true,
      barrierColor: Colors.black87,
      pageBuilder: (_, __, ___) => const PlayerScreen(),
      transitionDuration: const Duration(milliseconds: 180),
      reverseTransitionDuration: const Duration(milliseconds: 160),
      transitionsBuilder: (_, anim, __, child) {
        return FadeTransition(
          opacity: CurvedAnimation(parent: anim, curve: Curves.easeOut),
          child: child,
        );
      },
    ),
  );
}

class MiniPlayer extends ConsumerStatefulWidget {
  const MiniPlayer({super.key});

  @override
  ConsumerState<MiniPlayer> createState() => _MiniPlayerState();
}

class _MiniPlayerState extends ConsumerState<MiniPlayer> {
  double _dragY = 0;
  bool _isOpening = false;

  void _openFullPlayer() {
    if (_isOpening) return;
    _isOpening = true;
    openFullPlayerRoute(context);
    Future<void>.delayed(const Duration(milliseconds: 400), () {
      _isOpening = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Desktop has its own DesktopPlayerBar — never show the mobile mini player.
    if (ShellContext.isDesktopOf(context)) return const SizedBox.shrink();

    final song = ref.watch(currentSongProvider);
    if (song == null) return const SizedBox.shrink();

    final isPlaying = ref.watch(playerProvider.select((s) => s.isPlaying));
    final isLoading = ref.watch(playerProvider.select((s) => s.isLoading));
    final progress = ref.watch(playerProvider.select((s) => s.progress));

    return GestureDetector(
      onTap: _openFullPlayer,
      onVerticalDragUpdate: (d) {
        _dragY += d.delta.dy;
        if (_dragY < -24) {
          _openFullPlayer();
          _dragY = 0;
        }
      },
      onVerticalDragEnd: (_) => _dragY = 0,
      onHorizontalDragEnd: (d) {
        final v = d.primaryVelocity ?? 0;
        if (v < -400) {
          ref.read(playerProvider.notifier).playNext();
        } else if (v > 400) {
          ref.read(playerProvider.notifier).playPrevious();
        }
      },
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.sm,
          0,
          AppSpacing.sm,
          AppSpacing.sm,
        ),
        child: Container(
          height: 68,
          decoration: BoxDecoration(
            color: AppColors.surfaceLight.withValues(alpha: 0.97),
            borderRadius: BorderRadius.circular(AppRadius.xl),
            border: Border.all(
              color: AppColors.glassBorder,
              width: 0.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.35),
                blurRadius: 24,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Stack(
            clipBehavior: Clip.hardEdge,
            children: [
              Positioned.fill(
                bottom: 3,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                  ),
                  child: Row(
                    children: [
                      _AlbumThumb(url: song.thumbnailUrl),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              song.title,
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
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
                      _MiniLikeButton(song: song),
                      const SizedBox(width: AppSpacing.xs),
                      MiniPlayerPlayButton(
                        isPlaying: isPlaying,
                        isLoading: isLoading,
                        onTap: () =>
                            ref.read(playerProvider.notifier).togglePlayPause(),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                left: AppSpacing.md,
                right: AppSpacing.md,
                bottom: 0,
                child: RepaintBoundary(
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(AppRadius.xl),
                    ),
                    child: LinearProgressIndicator(
                      value: progress.clamp(0.0, 1.0),
                      minHeight: 3,
                      backgroundColor: Colors.white.withValues(alpha: 0.06),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        AppColors.primary,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


class _AlbumThumb extends StatelessWidget {
  const _AlbumThumb({required this.url});
  final String url;

  @override
  Widget build(BuildContext context) {
    final cachePx = (44 * MediaQuery.of(context).devicePixelRatio).round();
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Container(
        color: Colors.black.withValues(alpha: 0.18),
        child: CachedNetworkImage(
          imageUrl: url,
          width: 44,
          height: 44,
          memCacheWidth: cachePx,
          memCacheHeight: cachePx,
          fit: BoxFit.contain,
          errorWidget: (_, __, ___) => Container(
            width: 44,
            height: 44,
            color: AppColors.surface,
            child: AppIcon(
              icon: AppIcons.musicNote,
              color: AppColors.textMuted,
              size: 20,
            ),
          ),
        ),
      ),
    );
  }
}

class _MiniLikeButton extends ConsumerWidget {
  const _MiniLikeButton({required this.song});
  final Song song;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLiked = ref.watch(
      libraryProvider.select((s) => s.likedSongIds.contains(song.id)),
    );
    return GestureDetector(
      onTap: () {
        ref.read(libraryProvider.notifier).toggleLiked(song);
      },
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xs),
        child: FavouriteIcon(
          isLiked: isLiked,
          songId: song.id,
          size: 20,
          emptyColor: AppColors.textSecondary,
        ),
      ),
    );
  }
}

