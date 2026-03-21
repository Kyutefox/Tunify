import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../config/app_icons.dart';
import '../../../../models/playlist.dart';
import '../../../../ui/theme/app_colors.dart';
import '../../../../ui/theme/design_tokens.dart';

class PlaylistCard extends StatefulWidget {
  final Playlist playlist;
  final VoidCallback? onTap;
  final int index;
  final double width;
  final double height;

  const PlaylistCard({
    super.key,
    required this.playlist,
    this.onTap,
    this.index = 0,
    this.width = 180,
    this.height = 180,
  });

  @override
  State<PlaylistCard> createState() => _PlaylistCardState();
}

class _PlaylistCardState extends State<PlaylistCard> {
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
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          width: widget.width,
          margin: const EdgeInsets.only(right: 16),
          transform: Matrix4.identity()
            ..scaleByDouble(_isPressed ? 0.95 : (_isHovered ? 1.03 : 1.0),
                _isPressed ? 0.95 : (_isHovered ? 1.03 : 1.0), 1.0, 1.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildCover(),
              const SizedBox(height: AppSpacing.md),
              Text(
                widget.playlist.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Row(
                children: [
                  if (widget.playlist.curatorName != null) ...[
                    Text(
                      widget.playlist.curatorName!,
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Text(
                      ' • ',
                      style:
                          TextStyle(color: AppColors.textMuted, fontSize: 12),
                    ),
                  ],
                  Text(
                    widget.playlist.trackCountFormatted,
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    )
        .animate(delay: Duration(milliseconds: widget.index * 60))
        .fadeIn(duration: 450.ms)
        .slideY(begin: 0.08, curve: Curves.easeOutCubic);
  }

  Widget _buildCover() {
    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: [
          BoxShadow(
            color: _isHovered
                ? AppColors.primary.withValues(alpha: 0.3)
                : Colors.black.withValues(alpha: 0.4),
            blurRadius: _isHovered ? 24 : 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Stack(
          fit: StackFit.expand,
          children: [
            CachedNetworkImage(
              imageUrl: widget.playlist.coverUrl,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                decoration: BoxDecoration(
                  gradient: AppColors.cardGradient,
                ),
                child: Center(
                  child: AppIcon(
                    icon: AppIcons.queueMusic,
                    color: AppColors.textMuted,
                    size: 40,
                  ),
                ),
              ),
              errorWidget: (context, url, error) => Container(
                decoration: BoxDecoration(
                  gradient: AppColors.cardGradient,
                ),
                child: Center(
                  child: AppIcon(
                    icon: AppIcons.queueMusic,
                    color: AppColors.textMuted,
                    size: 40,
                  ),
                ),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.6),
                  ],
                  stops: const [0.5, 1.0],
                ),
              ),
            ),
            AnimatedOpacity(
              opacity: _isHovered ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 200),
              child: Container(
                color: Colors.black.withValues(alpha: 0.3),
                child: Center(
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.8, end: _isHovered ? 1.0 : 0.8),
                    duration: const Duration(milliseconds: 200),
                    builder: (context, scale, child) {
                      return Transform.scale(
                        scale: scale,
                        child: Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: AppColors.primaryGradient,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.6),
                                blurRadius: 20,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: AppIcon(
                            icon: AppIcons.play,
                            color: Colors.white,
                            size: 32,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
            Positioned(
              left: 12,
              right: 12,
              bottom: 12,
              child: AnimatedOpacity(
                opacity: _isHovered ? 0.0 : 1.0,
                duration: const Duration(milliseconds: 200),
                child: Row(
                  children: [
                    AppIcon(
                      icon: AppIcons.playCircleFilled,
                      color: Colors.white70,
                      size: 18,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      widget.playlist.durationFormatted,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class LargePlaylistCard extends StatefulWidget {
  final Playlist playlist;
  final VoidCallback? onTap;
  final int index;

  const LargePlaylistCard({
    super.key,
    required this.playlist,
    this.onTap,
    this.index = 0,
  });

  @override
  State<LargePlaylistCard> createState() => _LargePlaylistCardState();
}

class _LargePlaylistCardState extends State<LargePlaylistCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final cardWidth = screenWidth - 40;

    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        width: cardWidth,
        height: 200,
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        transform: Matrix4.identity()
          ..scaleByDouble(
              _isPressed ? 0.98 : 1.0, _isPressed ? 0.98 : 1.0, 1.0, 1.0),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.xl),
          child: Stack(
            fit: StackFit.expand,
            children: [
              CachedNetworkImage(
                imageUrl: widget.playlist.coverUrl,
                fit: BoxFit.cover,
              ),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.black.withValues(alpha: 0.7),
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.8),
                    ],
                    stops: const [0.0, 0.5, 1.0],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (widget.playlist.curatorName != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.8),
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                        child: Text(
                          widget.playlist.curatorName!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      widget.playlist.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      widget.playlist.description,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            gradient: AppColors.primaryGradient,
                            borderRadius: BorderRadius.circular(AppRadius.xl),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              AppIcon(icon: AppIcons.play,
                                  color: Colors.white, size: 20),
                              const SizedBox(width: AppSpacing.xs),
                              Text(
                                'Play',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Text(
                          '${widget.playlist.trackCountFormatted} • ${widget.playlist.durationFormatted}',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.6),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    )
        .animate(delay: Duration(milliseconds: widget.index * 100))
        .fadeIn(duration: 500.ms)
        .slideY(begin: 0.1, curve: Curves.easeOutCubic);
  }
}
