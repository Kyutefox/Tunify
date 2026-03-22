import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../config/app_icons.dart';
import '../../../../models/playlist.dart';
import '../../../../ui/theme/app_colors.dart';
import '../../../../ui/theme/design_tokens.dart';
import '../../../../ui/screens/home/home_shared.dart';

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

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: PressScale(
        onTap: widget.onTap ?? () {},
        scale: 0.95,
        child: SizedBox(
          width: widget.width,
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
                  fontSize: AppFontSize.lg,
                  fontWeight: FontWeight.w600,
                  letterSpacing: AppLetterSpacing.heading,
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
                        fontSize: AppFontSize.sm,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Text(
                      ' • ',
                      style: TextStyle(color: AppColors.textMuted, fontSize: AppFontSize.sm),
                    ),
                  ],
                  Text(
                    widget.playlist.trackCountFormatted,
                    style: const TextStyle(color: AppColors.textMuted, fontSize: AppFontSize.sm),
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
              placeholder: (context, url) => PlaceholderArt(size: widget.width),
              errorWidget: (context, url, error) => PlaceholderArt(size: widget.width),
            ),
            // Shared bottom-fade overlay
            Container(decoration: const BoxDecoration(gradient: AppColors.cardOverlayGradient)),
            // Shared hover play overlay
            HoverPlayOverlay(visible: _isHovered),
            // Duration badge (hidden on hover)
            Positioned(
              left: 12,
              right: 12,
              bottom: 12,
              child: AnimatedOpacity(
                opacity: _isHovered ? 0.0 : 1.0,
                duration: AppDuration.fast,
                child: Row(
                  children: [
                    AppIcon(icon: AppIcons.playCircleFilled, color: Colors.white70, size: 18),
                    const SizedBox(width: 6),
                    Text(
                      widget.playlist.durationFormatted,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: AppFontSize.sm,
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

class LargePlaylistCard extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final cardWidth = MediaQuery.of(context).size.width - 40;

    return PressScale(
      onTap: onTap ?? () {},
      scale: 0.98,
      child: Container(
        width: cardWidth,
        height: 200,
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.xl),
          child: Stack(
            fit: StackFit.expand,
            children: [
              CachedNetworkImage(imageUrl: playlist.coverUrl, fit: BoxFit.cover),
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
                    if (playlist.curatorName != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.8),
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                        child: Text(
                          playlist.curatorName!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: AppFontSize.xs,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      playlist.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: AppFontSize.h1,
                        fontWeight: FontWeight.w700,
                        letterSpacing: AppLetterSpacing.display,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      playlist.description,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: AppFontSize.md,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            gradient: AppColors.primaryGradient,
                            borderRadius: BorderRadius.circular(AppRadius.xl),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              AppIcon(icon: AppIcons.play, color: Colors.white, size: 20),
                              const SizedBox(width: AppSpacing.xs),
                              const Text(
                                'Play',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: AppFontSize.md,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Text(
                          '${playlist.trackCountFormatted} • ${playlist.durationFormatted}',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.6),
                            fontSize: AppFontSize.sm,
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
        .animate(delay: Duration(milliseconds: index * 100))
        .fadeIn(duration: 500.ms)
        .slideY(begin: 0.1, curve: Curves.easeOutCubic);
  }
}
