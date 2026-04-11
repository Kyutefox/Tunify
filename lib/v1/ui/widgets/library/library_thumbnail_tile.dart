import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import 'package:tunify/v1/core/constants/app_icons.dart';
import 'package:tunify/v1/ui/theme/design_tokens.dart';
import 'package:tunify/v1/ui/theme/app_tokens.dart';
import 'package:tunify/v1/ui/theme/app_colors_scheme.dart';

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
  final bool isCircle;
  final List<List<dynamic>>? icon;

  @override
  Widget build(BuildContext context) {
    final t = AppTokens.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        mouseCursor: SystemMouseCursors.click,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Padding(
          padding: EdgeInsets.symmetric(
              vertical: t.spacing.xs, horizontal: t.spacing.sm),
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
                        color: AppColorsScheme.of(context).textPrimary,
                        fontSize: AppFontSize.base,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColorsScheme.of(context).textMuted,
                        fontSize: AppFontSize.sm,
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
  }
}

class _IconThumb extends StatelessWidget {
  const _IconThumb({required this.icon});
  final List<List<dynamic>> icon;

  @override
  Widget build(BuildContext context) {
    final size = 52.0;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColorsScheme.of(context).surfaceLight,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Center(
        child: AppIcon(
            icon: icon,
            color: AppColorsScheme.of(context).textMuted,
            size: size * 0.5),
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
    final size = 52.0;
    return ClipRRect(
      borderRadius: BorderRadius.circular(isCircle ? size / 2 : AppRadius.sm),
      child: Container(
        width: size,
        height: size,
        color: AppColorsScheme.of(context).surfaceLight,
        child: thumbnailUrl != null
            ? CachedNetworkImage(
                imageUrl: thumbnailUrl!,
                fit: BoxFit.cover,
                errorWidget: (ctx, __, ___) => _icon(ctx, size),
              )
            : _icon(context, size),
      ),
    );
  }

  Widget _icon(BuildContext context, double size) => Center(
        child: AppIcon(
          icon: AppIcons.musicNote,
          color: AppColorsScheme.of(context).textMuted,
          size: size * 0.5,
        ),
      );
}
