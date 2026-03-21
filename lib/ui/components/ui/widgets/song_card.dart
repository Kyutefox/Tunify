import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../config/app_icons.dart';
import '../../../../models/song.dart';
import '../../../../ui/theme/app_colors.dart';
import '../../../../ui/theme/design_tokens.dart';
import '../components_ui.dart';

class SongCard extends StatefulWidget {
  final Song song;
  final VoidCallback? onTap;
  final bool isPlaying;
  final bool showProgress;
  final double? progress;
  final bool enableHero;
  final int index;
  final String? heroTag;

  const SongCard({
    super.key,
    required this.song,
    this.onTap,
    this.isPlaying = false,
    this.showProgress = false,
    this.progress,
    this.enableHero = false,
    this.index = 0,
    this.heroTag,
  });

  @override
  State<SongCard> createState() => _SongCardState();
}

class _SongCardState extends State<SongCard> {
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          width: 150,
          margin: const EdgeInsets.only(right: 12),
          transform: Matrix4.identity()
            ..scaleByDouble(_isPressed ? 0.95 : (_isHovered ? 1.02 : 1.0),
                _isPressed ? 0.95 : (_isHovered ? 1.02 : 1.0), 1.0, 1.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildArtwork(),
              const SizedBox(height: 10),
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
                  letterSpacing: -0.2,
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
              if (widget.showProgress && widget.progress != null) ...[
                const SizedBox(height: 8),
                _buildProgressBar(),
              ],
            ],
          ),
        ),
      ),
    )
        .animate(delay: Duration(milliseconds: widget.index * 50))
        .fadeIn(duration: 400.ms)
        .slideX(begin: 0.1, curve: Curves.easeOutCubic);
  }

  Widget _buildArtwork() {
    final artwork = Container(
      width: 150,
      height: 150,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.md),
        boxShadow: [
          BoxShadow(
            color: widget.isPlaying
                ? AppColors.primary.withValues(alpha: 0.4)
                : Colors.black.withValues(alpha: 0.3),
            blurRadius: widget.isPlaying ? 20 : 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Stack(
          fit: StackFit.expand,
          children: [
            CachedNetworkImage(
              imageUrl: widget.song.thumbnailUrl,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                color: AppColors.surfaceHighlight,
                child: Center(
                  child: AppIcon(
                    icon: AppIcons.musicNote,
                    color: AppColors.textMuted,
                    size: 32,
                  ),
                ),
              ),
              errorWidget: (context, url, error) => Container(
                color: AppColors.surfaceHighlight,
                child: Center(
                  child: AppIcon(
                    icon: AppIcons.brokenImage,
                    color: AppColors.textMuted,
                    size: 32,
                  ),
                ),
              ),
            ),
            if (widget.isPlaying)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        AppColors.primary.withValues(alpha: 0.6),
                      ],
                    ),
                  ),
                  child: Center(
                    child: NowPlayingIndicator(
                      size: 32,
                      barCount: 4,
                      animate: true,
                    ),
                  ),
                ),
              ),
            AnimatedOpacity(
              opacity: _isHovered && !widget.isPlaying ? 0.6 : 0,
              duration: const Duration(milliseconds: 200),
              child: Container(
                color: Colors.black,
                child: Center(
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: AppColors.primaryGradient,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.6),
                          blurRadius: 16,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: AppIcon(
                      icon: AppIcons.play,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 8,
              right: 8,
              child: AnimatedOpacity(
                opacity: !widget.isPlaying ? 1 : 0,
                duration: const Duration(milliseconds: 200),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(AppRadius.xs),
                  ),
                  child: Text(
                    widget.song.durationFormatted,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );

    if (widget.enableHero) {
      return Hero(
        tag: 'song_artwork_${widget.song.id}',
        child: artwork,
      );
    }
    return artwork;
  }

  Widget _buildProgressBar() {
    return Container(
      height: 3,
      decoration: BoxDecoration(
        color: AppColors.surfaceHighlight,
        borderRadius: BorderRadius.circular(AppRadius.xs),
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: widget.progress ?? 0,
        child: Container(
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(AppRadius.xs),
          ),
        ),
      ),
    );
  }
}

class LargeSongCard extends StatefulWidget {
  final Song song;
  final VoidCallback? onTap;
  final bool isPlaying;
  final int index;

  const LargeSongCard({
    super.key,
    required this.song,
    this.onTap,
    this.isPlaying = false,
    this.index = 0,
  });

  @override
  State<LargeSongCard> createState() => _LargeSongCardState();
}

class _LargeSongCardState extends State<LargeSongCard> {
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
        transform: Matrix4.identity()
          ..scaleByDouble(
              _isPressed ? 0.97 : 1.0, _isPressed ? 0.97 : 1.0, 1.0, 1.0),
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          gradient: AppColors.cardGradient,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(
            color: widget.isPlaying
                ? AppColors.primary.withValues(alpha: 0.5)
                : AppColors.surfaceHighlight,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: widget.isPlaying
                  ? AppColors.primary.withValues(alpha: 0.2)
                  : Colors.black.withValues(alpha: 0.2),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Hero(
              tag: 'large_song_${widget.song.id}',
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.sm),
                child: CachedNetworkImage(
                  imageUrl: widget.song.thumbnailUrl,
                  width: 64,
                  height: 64,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(width: 14),
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
                      fontSize: 15,
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
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            if (widget.isPlaying)
              NowPlayingIndicator(
                size: 24,
                barCount: 4,
                animate: true,
              )
            else
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.surfaceHighlight,
                ),
                child: AppIcon(
                  icon: AppIcons.play,
                  color: AppColors.textPrimary,
                  size: 24,
                ),
              ),
          ],
        ),
      ),
    )
        .animate(delay: Duration(milliseconds: widget.index * 80))
        .fadeIn(duration: 400.ms)
        .slideY(begin: 0.1, curve: Curves.easeOutCubic);
  }
}
