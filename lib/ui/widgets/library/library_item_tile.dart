import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:tunify/core/constants/app_icons.dart';
import 'package:tunify/ui/theme/app_colors.dart';
import 'package:tunify/ui/theme/app_colors_scheme.dart';
import 'package:tunify/ui/theme/design_tokens.dart';
import 'package:tunify/ui/theme/desktop_tokens.dart';
import 'package:tunify/ui/widgets/common/button.dart';

/// Generic library item tile that matches the playlist tile design
/// Used for playlists, podcasts, audiobooks, etc.
class LibraryItemTile extends StatelessWidget {
  const LibraryItemTile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.thumbnailUrl,
    required this.onTap,
    required this.onOptions,
    required this.placeholderIcon,
    this.showPinIndicator = false,
  });

  final String title;
  final String subtitle;
  final String? thumbnailUrl;
  final VoidCallback onTap;
  final void Function(Rect?) onOptions;
  final List<List<dynamic>> placeholderIcon;
  final bool showPinIndicator;

  @override
  Widget build(BuildContext context) {
    final t = AppTokens.of(context);
    final thumbSize = t.isDesktop ? 48.0 : 52.0;
    final tile = Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        hoverColor: t.isDesktop ? Colors.transparent : null,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: Padding(
          padding: EdgeInsets.symmetric(
              vertical: t.isDesktop ? t.spacing.xs : t.spacing.sm),
          child: Row(
            children: [
              _buildThumbnail(context, thumbSize),
              SizedBox(width: t.spacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: AppColorsScheme.of(context).textPrimary,
                        fontSize: AppFontSize.lg,
                        fontWeight:
                            t.isDesktop ? FontWeight.w700 : FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: AppColorsScheme.of(context).textMuted,
                        fontSize: AppFontSize.md,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (showPinIndicator)
                Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: AppIcon(
                      icon: AppIcons.pin, size: 14, color: AppColors.primary),
                ),
              Builder(
                builder: (btnCtx) => AppIconButton(
                  icon: AppIcon(
                      icon: AppIcons.moreVert,
                      size: 22,
                      color: AppColorsScheme.of(context).textMuted),
                  onPressedWithContext: (btnCtx) {
                    final box = btnCtx.findRenderObject() as RenderBox?;
                    onOptions(box != null && box.hasSize
                        ? box.localToGlobal(Offset.zero) & box.size
                        : null);
                  },
                  size: t.isDesktop ? 36 : 40,
                  iconSize: 22,
                  iconAlignment: Alignment.centerRight,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (t.isDesktop) return _LibraryHoverTile(child: tile);
    return tile;
  }

  Widget _buildThumbnail(BuildContext context, double size) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: thumbnailUrl != null && thumbnailUrl!.isNotEmpty
          ? CachedNetworkImage(
              imageUrl: thumbnailUrl!,
              width: size,
              height: size,
              fit: BoxFit.cover,
              errorWidget: (_, __, ___) => _buildPlaceholder(context, size),
            )
          : _buildPlaceholder(context, size),
    );
  }

  Widget _buildPlaceholder(BuildContext context, double size) {
    return Container(
      width: size,
      height: size,
      color: AppColorsScheme.of(context).surfaceHighlight,
      child: Center(
        child: AppIcon(
          icon: placeholderIcon,
          size: size * 0.4,
          color: AppColorsScheme.of(context).textMuted,
        ),
      ),
    );
  }
}

/// Hover highlight wrapper for desktop library list tiles.
class _LibraryHoverTile extends StatefulWidget {
  const _LibraryHoverTile({required this.child});
  final Widget child;

  @override
  State<_LibraryHoverTile> createState() => _LibraryHoverTileState();
}

class _LibraryHoverTileState extends State<_LibraryHoverTile> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
        decoration: BoxDecoration(
          color: _hovered ? AppColors.hoverOverlay : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.xs),
        ),
        child: widget.child,
      ),
    );
  }
}
