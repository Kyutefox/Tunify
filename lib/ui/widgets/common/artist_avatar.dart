import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:tunify/core/constants/app_icons.dart';
import 'package:tunify/data/models/artist.dart';
import 'package:tunify/ui/theme/app_colors.dart';
import 'package:tunify/ui/theme/design_tokens.dart';
import 'package:tunify/ui/screens/shared/home/home_shared.dart';

class ArtistAvatar extends StatefulWidget {
  final Artist artist;
  final VoidCallback? onTap;
  final int index;
  final double size;
  final bool showInfo;
  /// When true, renders a compact version (no pulse animation, simpler info)
  /// suitable for home section rows. Replaces the old HomeArtistAvatar widget.
  final bool compact;

  const ArtistAvatar({
    super.key,
    required this.artist,
    this.onTap,
    this.index = 0,
    this.size = 80,
    this.showInfo = true,
    this.compact = false,
  });

  @override
  State<ArtistAvatar> createState() => _ArtistAvatarState();
}

class _ArtistAvatarState extends State<ArtistAvatar>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    if (!widget.compact) _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final content = PressScale(
      onTap: widget.onTap ?? () {},
      scale: 0.92,
      child: SizedBox(
        width: widget.compact ? widget.size : widget.size + 20,
        child: Column(
          children: [
            _buildAvatar(),
            if (widget.showInfo) ...[
              const SizedBox(height: 10),
              Text(
                widget.artist.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: widget.compact ? AppColors.textSecondary : AppColors.textPrimary,
                  fontSize: widget.compact ? AppFontSize.xs : AppFontSize.md,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (!widget.compact) ...[
                const SizedBox(height: 2),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (widget.artist.isVerified) ...[
                      AppIcon(icon: AppIcons.verified, size: 12, color: AppColors.primary),
                      const SizedBox(width: 4),
                    ],
                    Flexible(
                      child: Text(
                        widget.artist.genre ?? widget.artist.listenersFormatted,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: AppFontSize.xs,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ],
        ),
      ),
    );

    if (widget.compact) return content;

    return content
        .animate(delay: Duration(milliseconds: widget.index * 70))
        .fadeIn(duration: 400.ms)
        .scale(begin: const Offset(0.8, 0.8), curve: Curves.easeOutBack);
  }

  Widget _buildAvatar() {
    if (widget.compact) {
      // Compact: simple circle with border, no pulse
      return Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.glassBorder, width: 1.5),
        ),
        child: ClipOval(
          clipBehavior: Clip.hardEdge,
          child: CachedNetworkImage(
            imageUrl: widget.artist.avatarUrl,
            fit: BoxFit.cover,
            fadeInDuration: Duration.zero,
            fadeOutDuration: Duration.zero,
            errorWidget: (_, __, ___) => Container(
              color: AppColors.surface,
              child: AppIcon(
                icon: AppIcons.person,
                color: AppColors.textMuted,
                size: widget.size * 0.44,
              ),
            ),
          ),
        ),
      );
    }

    // Full: pulsing glow ring
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(
                  alpha: 0.2 + (_pulseController.value * 0.2),
                ),
                blurRadius: 16 + (_pulseController.value * 8),
                spreadRadius: 2,
              ),
            ],
          ),
          child: child,
        );
      },
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: widget.artist.isVerified ? AppColors.primaryGradient : null,
          color: widget.artist.isVerified ? null : AppColors.surfaceHighlight,
        ),
        padding: const EdgeInsets.all(2),
        child: Container(
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.background,
          ),
          padding: const EdgeInsets.all(2),
          child: ClipOval(
            child: CachedNetworkImage(
              imageUrl: widget.artist.avatarUrl,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                color: AppColors.surfaceHighlight,
                child: AppIcon(icon: AppIcons.person, color: AppColors.textMuted),
              ),
              errorWidget: (context, url, error) => Container(
                color: AppColors.surfaceHighlight,
                child: AppIcon(icon: AppIcons.person, color: AppColors.textMuted),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class ArtistCard extends StatelessWidget {
  final Artist artist;
  final VoidCallback? onTap;
  final int index;

  const ArtistCard({
    super.key,
    required this.artist,
    this.onTap,
    this.index = 0,
  });

  @override
  Widget build(BuildContext context) {
    return PressScale(
      onTap: onTap ?? () {},
      scale: 0.96,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          gradient: AppColors.cardGradient,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: AppColors.surfaceHighlight, width: 1),
        ),
        child: Row(
          children: [
            Hero(
              tag: 'artist_${artist.id}',
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: artist.isVerified ? AppColors.primaryGradient : null,
                  color: artist.isVerified ? null : AppColors.surfaceHighlight,
                ),
                padding: const EdgeInsets.all(2),
                child: ClipOval(
                  child: CachedNetworkImage(imageUrl: artist.avatarUrl, fit: BoxFit.cover),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          artist.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: AppFontSize.lg,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      if (artist.isVerified) ...[
                        const SizedBox(width: 6),
                        AppIcon(icon: AppIcons.verified, size: 16, color: AppColors.primary),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    artist.listenersFormatted,
                    style: const TextStyle(color: AppColors.textMuted, fontSize: AppFontSize.sm),
                  ),
                  if (artist.latestRelease != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: AppColors.accentGreen,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            'Latest: ${artist.latestRelease}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: AppFontSize.xs,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.primary),
                borderRadius: BorderRadius.circular(AppRadius.lg),
              ),
              child: const Text(
                'Follow',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: AppFontSize.sm,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    )
        .animate(delay: Duration(milliseconds: index * 80))
        .fadeIn(duration: 400.ms)
        .slideX(begin: 0.1, curve: Curves.easeOutCubic);
  }
}
