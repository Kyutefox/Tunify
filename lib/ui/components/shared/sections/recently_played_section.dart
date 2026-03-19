import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../config/app_icons.dart';
import '../../../../models/song.dart';
import '../../../../shared/providers/home_state_provider.dart';
import '../../../../ui/screens/home/recently_played_screen.dart';
import '../../../../ui/theme/app_colors.dart';
import '../../../../ui/theme/design_tokens.dart';
import '../../ui/widgets/section_header.dart';

/// Reusable "Recently Played" section: header with "See all" opening [RecentlyPlayedScreen],
/// and a horizontal list of song cards. Use on home and search from one source.
class RecentlyPlayedSection extends ConsumerWidget {
  const RecentlyPlayedSection({
    super.key,
    required this.onPlay,
  });

  final void Function(Song song) onPlay;

  static const int _maxVisible = 8;
  static const double _rowHeight = 188;
  static const double _cardWidth = 148;
  static const double _thumbSize = 148;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recentlyPlayed = ref.watch(recentlyPlayedProvider);

    if (recentlyPlayed.isEmpty) {
      return const SizedBox(height: AppSpacing.sm);
    }

    final visible = recentlyPlayed.take(_maxVisible).toList(growable: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: AppSpacing.sm),
        SectionHeader(
          title: 'Recently Played',
          seeAllLabel: 'See all',
          onSeeAll: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const RecentlyPlayedScreen(),
              ),
            );
          },
          useCompactStyle: true,
        ),
        SizedBox(
          height: _rowHeight,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.base),
            itemCount: visible.length,
            separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.md),
            itemBuilder: (_, i) {
              final song = visible[i];
              return _RecentSongCard(
                song: song,
                onTap: () {
                  HapticFeedback.lightImpact();
                  onPlay(song);
                },
              );
            },
          ),
        ),
        const SizedBox(height: AppSpacing.xxl),
      ],
    );
  }
}

class _RecentSongCard extends StatelessWidget {
  const _RecentSongCard({required this.song, required this.onTap});
  final Song song;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: RecentlyPlayedSection._cardWidth,
        height: RecentlyPlayedSection._rowHeight,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.md),
              child: CachedNetworkImage(
                imageUrl: song.thumbnailUrl,
                width: RecentlyPlayedSection._thumbSize,
                height: RecentlyPlayedSection._thumbSize,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(
                  width: RecentlyPlayedSection._thumbSize,
                  height: RecentlyPlayedSection._thumbSize,
                  color: AppColors.surfaceLight,
                ),
                errorWidget: (_, __, ___) => Container(
                  width: RecentlyPlayedSection._thumbSize,
                  height: RecentlyPlayedSection._thumbSize,
                  color: AppColors.surfaceLight,
                  child: AppIcon(
                    icon: AppIcons.musicNote,
                    color: AppColors.textMuted,
                    size: 32,
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    song.title,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    song.artist,
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 11,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
