import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tunify/core/constants/app_icons.dart';
import 'package:tunify/data/models/podcast.dart';
import 'package:tunify/features/player/player_state_provider.dart';
import 'package:tunify/features/podcast/podcast_provider.dart';
import 'package:tunify/ui/theme/app_colors.dart';
import 'package:tunify/ui/theme/app_colors_scheme.dart';
import 'package:tunify/ui/theme/design_tokens.dart';
import 'package:tunify/ui/widgets/common/button.dart';

class PodcastDetailScreen extends ConsumerWidget {
  const PodcastDetailScreen({super.key, required this.podcast});
  final Podcast podcast;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final overlayStyle = isDark
        ? SystemUiOverlayStyle.light
            .copyWith(statusBarColor: Colors.transparent)
        : SystemUiOverlayStyle.dark
            .copyWith(statusBarColor: Colors.transparent);

    final podcastState = ref.watch(podcastProvider);
    final isSubscribed = podcastState.isSubscribed(podcast.id);
    final episodesAsync = ref.watch(
        podcastEpisodesProvider(podcast.browseId ?? podcast.id));

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: overlayStyle,
      child: Scaffold(
        backgroundColor: AppColorsScheme.of(context).background,
        body: SafeArea(
          bottom: false,
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: _PodcastHeader(
                  podcast: podcast,
                  isSubscribed: isSubscribed,
                  onToggleSubscribe: () => ref
                      .read(podcastProvider.notifier)
                      .toggleSubscription(podcast),
                ),
              ),
              episodesAsync.when(
                loading: () => const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(AppSpacing.xl),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                ),
                error: (_, __) => SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    child: Center(
                      child: Text(
                        'Could not load episodes',
                        style: TextStyle(
                            color: AppColorsScheme.of(context).textMuted),
                      ),
                    ),
                  ),
                ),
                data: (episodes) => episodes.isEmpty
                    ? SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpacing.xl),
                          child: Center(
                            child: Text(
                              'No episodes found',
                              style: TextStyle(
                                  color: AppColorsScheme.of(context).textMuted),
                            ),
                          ),
                        ),
                      )
                    : SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, i) => _EpisodeTile(
                            episode: episodes[i],
                            onPlay: () => _playEpisode(context, ref, episodes, i),
                          ),
                          childCount: episodes.length,
                        ),
                      ),
              ),
              const SliverPadding(padding: EdgeInsets.only(bottom: 120)),
            ],
          ),
        ),
      ),
    );
  }

  void _playEpisode(
      BuildContext context, WidgetRef ref, List<Episode> episodes, int index) {
    final episode = episodes[index];
    final song = episode.toSong();
    ref.read(playerProvider.notifier).playSong(
          song,
          queue: episodes.map((e) => e.toSong()).toList(),
        );
  }
}

// ── Header (Playlist-style) ─────────────────────────────────────────────────

class _PodcastHeader extends StatelessWidget {
  const _PodcastHeader({
    required this.podcast,
    required this.isSubscribed,
    required this.onToggleSubscribe,
  });
  final Podcast podcast;
  final bool isSubscribed;
  final VoidCallback onToggleSubscribe;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.base),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Back button row
          Row(
            children: [
              AppIconButton(
                icon: AppIcon(
                  icon: AppIcons.back,
                  size: 24,
                  color: AppColorsScheme.of(context).textPrimary,
                ),
                onPressed: () => Navigator.of(context).pop(),
                size: 44,
                iconSize: 24,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          // Cover image (playlist style - larger)
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.md),
                child: podcast.thumbnailUrl != null
                    ? CachedNetworkImage(
                        imageUrl: podcast.thumbnailUrl!,
                        width: 160,
                        height: 160,
                        fit: BoxFit.cover,
                      )
                    : Container(
                        width: 160,
                        height: 160,
                        color: AppColorsScheme.of(context).surfaceHighlight,
                        child: Center(
                          child: AppIcon(
                            icon: AppIcons.podcast,
                            size: 64,
                            color: AppColorsScheme.of(context).textMuted,
                          ),
                        ),
                      ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          // Title
          Text(
            podcast.title,
            style: TextStyle(
              color: AppColorsScheme.of(context).textPrimary,
              fontSize: AppFontSize.xxl,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          // Author
          if (podcast.author != null)
            Text(
              podcast.author!,
              style: TextStyle(
                color: AppColorsScheme.of(context).textSecondary,
                fontSize: AppFontSize.md,
              ),
            ),
          const SizedBox(height: AppSpacing.md),
          // Description
          if (podcast.description != null)
            Text(
              podcast.description!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: AppColorsScheme.of(context).textMuted,
                fontSize: AppFontSize.sm,
              ),
            ),
          const SizedBox(height: AppSpacing.lg),
          // Save/Bookmark button (instead of play)
          Row(
            children: [
              AppIconButton(
                icon: AppIcon(
                  icon: isSubscribed ? AppIcons.bookmark : AppIcons.bookmarkOutline,
                  size: 28,
                  color: isSubscribed ? AppColors.primary : AppColorsScheme.of(context).textPrimary,
                ),
                onPressed: onToggleSubscribe,
                size: 56,
                iconSize: 28,
              ),
              const SizedBox(width: AppSpacing.sm),
              // More options
              AppIconButton(
                icon: AppIcon(
                  icon: AppIcons.moreVert,
                  size: 24,
                  color: AppColorsScheme.of(context).textMuted,
                ),
                onPressed: () {
                  // Show more options sheet
                },
                size: 48,
                iconSize: 24,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          // Episodes header
          Text(
            'Episodes',
            style: TextStyle(
              color: AppColorsScheme.of(context).textPrimary,
              fontSize: AppFontSize.lg,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
      ),
    );
  }
}

// ── Episode Tile (Song-list style with description) ───────────────────────────

class _EpisodeTile extends StatelessWidget {
  const _EpisodeTile({required this.episode, required this.onPlay});
  final Episode episode;
  final VoidCallback onPlay;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPlay,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.base,
          vertical: AppSpacing.sm,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.xs),
              child: episode.thumbnailUrl != null
                  ? CachedNetworkImage(
                      imageUrl: episode.thumbnailUrl!,
                      width: 56,
                      height: 56,
                      fit: BoxFit.cover,
                    )
                  : Container(
                      width: 56,
                      height: 56,
                      color: AppColorsScheme.of(context).surfaceHighlight,
                      child: Center(
                        child: AppIcon(
                          icon: AppIcons.podcast,
                          size: 22,
                          color: AppColorsScheme.of(context).textMuted,
                        ),
                      ),
                    ),
            ),
            const SizedBox(width: AppSpacing.md),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title row with more icon
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          episode.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: AppColorsScheme.of(context).textPrimary,
                            fontWeight: FontWeight.w500,
                            fontSize: AppFontSize.md,
                          ),
                        ),
                      ),
                      AppIconButton(
                        icon: AppIcon(
                          icon: AppIcons.moreVert,
                          size: 20,
                          color: AppColorsScheme.of(context).textMuted,
                        ),
                        onPressed: () {
                          // Show episode options
                        },
                        size: 32,
                        iconSize: 20,
                      ),
                    ],
                  ),
                  // Description (2 lines max)
                  if (episode.description != null && episode.description!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.xs),
                      child: Text(
                        episode.description!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: AppColorsScheme.of(context).textMuted,
                          fontSize: AppFontSize.sm,
                        ),
                      ),
                    ),
                  // Date and duration row
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.xs),
                    child: Row(
                      children: [
                        if (episode.publishedDate != null)
                          Text(
                            episode.publishedDate!,
                            style: TextStyle(
                              color: AppColorsScheme.of(context).textMuted,
                              fontSize: AppFontSize.xs,
                            ),
                          ),
                        if (episode.publishedDate != null && episode.durationSeconds != null)
                          Text(
                            ' · ',
                            style: TextStyle(
                              color: AppColorsScheme.of(context).textMuted,
                              fontSize: AppFontSize.xs,
                            ),
                          ),
                        if (episode.durationSeconds != null)
                          Text(
                            episode.durationFormatted,
                            style: TextStyle(
                              color: AppColorsScheme.of(context).textMuted,
                              fontSize: AppFontSize.xs,
                            ),
                          ),
                      ],
                    ),
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
