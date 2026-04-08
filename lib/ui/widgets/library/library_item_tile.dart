import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:tunify/core/constants/app_icons.dart';
import 'package:tunify/ui/theme/app_colors.dart';
import 'package:tunify/ui/theme/app_colors_scheme.dart';
import 'package:tunify/ui/theme/design_tokens.dart';
import 'package:tunify/ui/theme/app_tokens.dart';
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
    this.onOptions,
    required this.placeholderIcon,
    this.showPinIndicator = false,
    this.circularThumbnail = false,
  });

  final String title;
  final String subtitle;
  final String? thumbnailUrl;
  final VoidCallback onTap;
  final void Function(Rect?)? onOptions;
  final List<List<dynamic>> placeholderIcon;
  final bool showPinIndicator;

  /// When true, the thumbnail is circular (e.g. artists).
  final bool circularThumbnail;

  @override
  Widget build(BuildContext context) {
    final t = AppTokens.of(context);
    final thumbSize = 52.0;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        mouseCursor: SystemMouseCursors.click,
        hoverColor: null,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: t.spacing.sm),
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
                        fontWeight: FontWeight.w600,
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
              if (onOptions != null)
                Builder(
                  builder: (btnCtx) => AppIconButton(
                    icon: AppIcon(
                        icon: AppIcons.moreVert,
                        size: 22,
                        color: AppColorsScheme.of(context).textMuted),
                    onPressedWithContext: (btnCtx) {
                      final box = btnCtx.findRenderObject() as RenderBox?;
                      onOptions!(
                        box != null && box.hasSize
                            ? box.localToGlobal(Offset.zero) & box.size
                            : null,
                      );
                    },
                    size: 40,
                    iconSize: 22,
                    iconAlignment: Alignment.centerRight,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildThumbnail(BuildContext context, double size) {
    final radius = circularThumbnail ? size / 2 : AppRadius.sm;
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
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
