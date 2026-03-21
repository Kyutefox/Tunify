import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../config/app_icons.dart';
import '../../../../models/song.dart';
import '../../../../ui/theme/app_colors.dart';
import '../../../../ui/theme/design_tokens.dart';

class AnimatedMusicTile extends StatefulWidget {
  final Song song;
  final int rank;
  final int playCount;
  final int likeCount;
  final VoidCallback? onTap;
  final bool isPlaying;
  final int index;

  const AnimatedMusicTile({
    super.key,
    required this.song,
    required this.rank,
    this.playCount = 0,
    this.likeCount = 0,
    this.onTap,
    this.isPlaying = false,
    this.index = 0,
  });

  @override
  State<AnimatedMusicTile> createState() => _AnimatedMusicTileState();
}

class _AnimatedMusicTileState extends State<AnimatedMusicTile>
    with TickerProviderStateMixin {
  late AnimationController _waveController;
  late List<Animation<double>> _waveAnimations;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _waveAnimations = List.generate(8, (index) {
      final delay = index * 0.1;
      return Tween<double>(begin: 0.2, end: 1.0).animate(
        CurvedAnimation(
          parent: _waveController,
          curve: Interval(delay, delay + 0.5, curve: Curves.easeInOut),
        ),
      );
    });

    if (widget.isPlaying) {
      _waveController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(AnimatedMusicTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPlaying && !_waveController.isAnimating) {
      _waveController.repeat(reverse: true);
    } else if (!widget.isPlaying && _waveController.isAnimating) {
      _waveController.stop();
    }
  }

  @override
  void dispose() {
    _waveController.dispose();
    super.dispose();
  }

  String _formatCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    }
    if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    }
    return count.toString();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
        padding: const EdgeInsets.all(AppSpacing.md),
        transform: Matrix4.identity()
          ..scaleByDouble(
              _isPressed ? 0.97 : 1.0, _isPressed ? 0.97 : 1.0, 1.0, 1.0),
        decoration: BoxDecoration(
          gradient: widget.isPlaying
              ? LinearGradient(
                  colors: [
                    AppColors.primary.withValues(alpha: 0.15),
                    AppColors.surface,
                  ],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                )
              : AppColors.cardGradient,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: widget.isPlaying
                ? AppColors.primary.withValues(alpha: 0.4)
                : AppColors.surfaceHighlight,
            width: 1,
          ),
          boxShadow: [
            if (widget.isPlaying)
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.2),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
          ],
        ),
        child: Row(
          children: [
            SizedBox(
              width: 28,
              child: Text(
                '#${widget.rank}',
                style: TextStyle(
                  color: widget.rank <= 3
                      ? AppColors.primary
                      : AppColors.textMuted,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Hero(
              tag: 'tile_song_${widget.song.id}',
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.sm),
                child: CachedNetworkImage(
                  imageUrl: widget.song.thumbnailUrl,
                  width: 52,
                  height: 52,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    widget.song.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: widget.isPlaying
                          ? AppColors.primary
                          : AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.song.artist,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      AppIcon(
                        icon: AppIcons.play,
                        size: 14,
                        color: AppColors.textMuted,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        _formatCount(widget.playCount),
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(width: 12),
                      FavouriteIcon(
                        isLiked: true,
                        size: 13,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        _formatCount(widget.likeCount),
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(
              width: 48,
              height: 32,
              child: widget.isPlaying
                  ? _buildWaveform()
                  : AppIcon(
                      icon: AppIcons.playCircleOutline,
                      color: AppColors.textMuted,
                      size: 28,
                    ),
            ),
          ],
        ),
      ),
    )
        .animate(delay: Duration(milliseconds: widget.index * 60))
        .fadeIn(duration: 400.ms)
        .slideX(begin: 0.08, curve: Curves.easeOutCubic);
  }

  Widget _buildWaveform() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(8, (index) {
        return AnimatedBuilder(
          animation: _waveAnimations[index],
          builder: (context, child) {
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 1),
              width: 3,
              height: 24 * _waveAnimations[index].value,
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(1.5),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.5),
                    blurRadius: 4,
                  ),
                ],
              ),
            );
          },
        );
      }),
    );
  }
}

class CompactMusicTile extends StatefulWidget {
  final Song song;
  final VoidCallback? onTap;
  final bool isPlaying;
  final int index;

  const CompactMusicTile({
    super.key,
    required this.song,
    this.onTap,
    this.isPlaying = false,
    this.index = 0,
  });

  @override
  State<CompactMusicTile> createState() => _CompactMusicTileState();
}

class _CompactMusicTileState extends State<CompactMusicTile> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        width: 260,
        height: 72,
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.all(10),
        transform: Matrix4.identity()
          ..scaleByDouble(
              _isPressed ? 0.96 : 1.0, _isPressed ? 0.96 : 1.0, 1.0, 1.0),
        decoration: BoxDecoration(
          gradient: AppColors.cardGradient,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: widget.isPlaying
                ? AppColors.primary.withValues(alpha: 0.4)
                : AppColors.surfaceHighlight,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.sm),
              child: CachedNetworkImage(
                imageUrl: widget.song.thumbnailUrl,
                width: 52,
                height: 52,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    widget.song.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: widget.isPlaying
                          ? AppColors.primary
                          : AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    widget.song.artist,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            AppIcon(
              icon: widget.isPlaying
                  ? AppIcons.equalizer
                  : AppIcons.play,
              color: widget.isPlaying ? AppColors.primary : AppColors.textMuted,
              size: 24,
            ),
          ],
        ),
      ),
    )
        .animate(delay: Duration(milliseconds: widget.index * 50))
        .fadeIn(duration: 350.ms)
        .slideX(begin: 0.1, curve: Curves.easeOutCubic);
  }
}
