import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import 'package:tunify/core/constants/app_icons.dart';
import 'package:tunify/ui/theme/app_colors.dart';
import 'package:tunify/ui/theme/design_tokens.dart';
import 'package:tunify/ui/theme/desktop_tokens.dart';

/// A compact tappable list tile for library items that have a thumbnail
/// (albums, artists) or an icon placeholder (downloads, etc.).
///
/// Used by the desktop sidebar and can be reused wherever a thumbnail-based
/// library row is needed.
class LibraryThumbnailTile extends StatelessWidget {
  const LibraryThumbnailTile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.thumbnailUrl,
    this.isCircle = false,
    this.icon,
  });

  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final String? thumbnailUrl;

  /// When true, the thumbnail is clipped as a circle (for artists).
  final bool isCircle;

  /// When provided, renders an icon placeholder instead of a network image.
  final List<List<dynamic>>? icon;

  @override
  Widget build(BuildContext context) {
    final t = AppTokens.of(context);
    final tile = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: t.spacing.sm, horizontal: t.spacing.sm),
          child: Row(
            children: [
              icon != null
                  ? _IconThumb(icon: icon!)
                  : _Thumb(thumbnailUrl: thumbnailUrl, isCircle: isCircle),
              SizedBox(width: t.spacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: AppFontSize.lg,
                        fontWeight: t.isDesktop ? FontWeight.w700 : FontWeight.w600,
                      ),
                    ),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: AppFontSize.md,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (t.isDesktop) {
      return _DesktopHoverWrapper(child: tile);
    }
    return tile;
  }
}

class _IconThumb extends StatelessWidget {
  const _IconThumb({required this.icon});
  final List<List<dynamic>> icon;

  @override
  Widget build(BuildContext context) {
    final t = AppTokens.of(context);
    final size = t.isDesktop ? 44.0 : 52.0;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Center(
        child: AppIcon(icon: icon, color: AppColors.textMuted, size: size * 0.5),
      ),
    );
  }
}

class _Thumb extends StatelessWidget {
  const _Thumb({this.thumbnailUrl, this.isCircle = false});

  final String? thumbnailUrl;
  final bool isCircle;

  @override
  Widget build(BuildContext context) {
    final t = AppTokens.of(context);
    final size = t.isDesktop ? 44.0 : 52.0;
    return ClipRRect(
      borderRadius: BorderRadius.circular(isCircle ? size / 2 : AppRadius.sm),
      child: Container(
        width: size,
        height: size,
        color: AppColors.surfaceLight,
        child: thumbnailUrl != null
            ? CachedNetworkImage(
                imageUrl: thumbnailUrl!,
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) => _icon(size),
              )
            : _icon(size),
      ),
    );
  }

  Widget _icon(double size) => Center(
        child: AppIcon(
          icon: AppIcons.musicNote,
          color: AppColors.textMuted,
          size: size * 0.5,
        ),
      );
}

class _DesktopHoverWrapper extends StatefulWidget {
  const _DesktopHoverWrapper({required this.child});
  final Widget child;

  @override
  State<_DesktopHoverWrapper> createState() => _DesktopHoverWrapperState();
}

class _DesktopHoverWrapperState extends State<_DesktopHoverWrapper> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        decoration: BoxDecoration(
          color: _hovered ? AppColors.hoverOverlay : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        child: widget.child,
      ),
    );
  }
}
