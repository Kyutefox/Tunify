import 'package:flutter/material.dart';

import 'package:tunify/core/constants/app_icons.dart';
import 'package:tunify/data/models/library_playlist.dart';
import 'package:tunify/ui/theme/app_colors.dart';
import 'package:tunify/ui/theme/design_tokens.dart';
import 'package:tunify/core/utils/string_utils.dart';

/// Reusable playlist row for sheets (folder playlists, etc.). Same look everywhere.
class SheetPlaylistTile extends StatelessWidget {
  const SheetPlaylistTile({
    super.key,
    required this.playlist,
    required this.onTap,
  });

  final LibraryPlaylist playlist;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.xs + 2,
          horizontal: AppSpacing.sm,
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(AppRadius.xs),
              ),
              child: Center(
                child: AppIcon(
                  icon: AppIcons.musicNote,
                  color: AppColors.textMuted,
                  size: 18,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    playlist.name.capitalized,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: AppFontSize.base,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    playlist.trackCountLabel,
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: AppFontSize.sm,
                    ),
                  ),
                ],
              ),
            ),
            AppIcon(
              icon: AppIcons.chevronRight,
              color: AppColors.textMuted,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}
