import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tunify/core/constants/app_icons.dart';
import 'package:tunify/data/models/audiobook.dart';
import 'package:tunify/data/models/podcast.dart';
import 'package:tunify/data/models/playback_position.dart';
import 'package:tunify/features/player/player_state_provider.dart';
import 'package:tunify/features/podcast/podcast_provider.dart';
import 'package:tunify/ui/theme/app_colors.dart';
import 'package:tunify/ui/theme/app_colors_scheme.dart';
import 'package:tunify/ui/theme/design_tokens.dart';
import 'package:tunify/ui/widgets/common/button.dart';

class AudiobookDetailScreen extends ConsumerWidget {
  const AudiobookDetailScreen({super.key, required this.audiobook});
  final Audiobook audiobook;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final overlayStyle = isDark
        ? SystemUiOverlayStyle.light
            .copyWith(statusBarColor: Colors.transparent)
        : SystemUiOverlayStyle.dark
            .copyWith(statusBarColor: Colors.transparent);

    final podcastState = ref.watch(podcastProvider);
    final isSaved = podcastState.isAudiobookSaved(audiobook.id);
    final position = podcastState.positionFor(audiobook.id, PlaybackContentType.audiobook);

    final chaptersAsync =
        ref.watch(podcastEpisodesProvider(audiobook.browseId ?? audiobook.id));

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: overlayStyle,
      child: Scaffold(
        backgroundColor: AppColorsScheme.of(context).background,
        body: SafeArea(
          bottom: false,
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: _AudiobookHeader(
                  audiobook: audiobook,
                  isSaved: isSaved,
                  position: position,
                  onToggleSave: () => ref
                      .read(podcastProvider.notifier)
                      .toggleSavedAudiobook(audiobook),
                  onPlay: () => _playAudiobook(context, ref),
                ),
              ),
              chaptersAsync.when(
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
                        'Could not load chapters',
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
                              'No chapters found',
                              style: TextStyle(
                                  color: AppColorsScheme.of(context).textMuted),
                            ),
                          ),
                        ),
                      )
                    : SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (ctx, i) => _ChapterTile(
                            episode: episodes[i],
                            index: i,
                            onPlay: () =>
                                _playFrom(context, ref, episodes, i),
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

  void _playAudiobook(BuildContext context, WidgetRef ref) {
    final chaptersAsync = ref.read(
        podcastEpisodesProvider(audiobook.browseId ?? audiobook.id));
    chaptersAsync.whenData((episodes) {
      if (episodes.isEmpty) return;
      final songs = episodes.map((e) => e.toSong()).toList();
      ref.read(playerProvider.notifier).playSong(
            songs.first,
            queue: songs,
          );
    });
  }

  void _playFrom(
      BuildContext context, WidgetRef ref, List<Episode> episodes, int index) {
    final songs = episodes.map((e) => e.toSong()).toList();
    ref.read(playerProvider.notifier).playSong(
          songs[index],
          queue: songs,
        );
  }
}

// ── Header ────────────────────────────────────────────────────────────────────

class _AudiobookHeader extends StatelessWidget {
  const _AudiobookHeader({
    required this.audiobook,
    required this.isSaved,
    required this.position,
    required this.onToggleSave,
    required this.onPlay,
  });
  final Audiobook audiobook;
  final bool isSaved;
  final PlaybackPosition? position;
  final VoidCallback onToggleSave;
  final VoidCallback onPlay;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.base),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
          Center(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.md),
              child: audiobook.thumbnailUrl != null
                  ? CachedNetworkImage(
                      imageUrl: audiobook.thumbnailUrl!,
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
                          icon: AppIcons.bookOpen,
                          size: 60,
                          color: AppColorsScheme.of(context).textMuted,
                        ),
                      ),
                    ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Center(
            child: Text(
              audiobook.title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColorsScheme.of(context).textPrimary,
                fontSize: AppFontSize.xl,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          if (audiobook.author != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Center(
              child: Text(
                audiobook.author!,
                style: TextStyle(
                  color: AppColorsScheme.of(context).textMuted,
                  fontSize: AppFontSize.md,
                ),
              ),
            ),
          ],
          if (position != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Center(
              child: Text(
                position!.timeRemaining,
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: AppFontSize.sm,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            LinearProgressIndicator(
              value: position!.progress,
              backgroundColor:
                  AppColorsScheme.of(context).surfaceHighlight,
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(AppRadius.full),
              minHeight: 3,
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: onPlay,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(AppRadius.full),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AppIcon(
                            icon: AppIcons.play,
                            size: 18,
                            color: Colors.white),
                        const SizedBox(width: AppSpacing.xs),
                        Text(
                          position != null ? 'Resume' : 'Play',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: AppFontSize.md,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              AppIconButton(
                icon: AppIcon(
                  icon: isSaved ? AppIcons.checkCircle : AppIcons.addCircleOutline,
                  size: 26,
                  color: isSaved
                      ? AppColors.primary
                      : AppColorsScheme.of(context).textPrimary,
                ),
                onPressed: onToggleSave,
                size: 44,
                iconSize: 26,
              ),
            ],
          ),
          if (audiobook.description != null) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              audiobook.description!,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: AppColorsScheme.of(context).textMuted,
                fontSize: AppFontSize.sm,
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          Text(
            'Chapters',
            style: TextStyle(
              color: AppColorsScheme.of(context).textPrimary,
              fontSize: AppFontSize.lg,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Chapter tile ──────────────────────────────────────────────────────────────

class _ChapterTile extends StatelessWidget {
  const _ChapterTile(
      {required this.episode, required this.index, required this.onPlay});
  final Episode episode;
  final int index;
  final VoidCallback onPlay;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.base, vertical: AppSpacing.xs),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColorsScheme.of(context).surfaceHighlight,
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        child: Center(
          child: Text(
            '${index + 1}',
            style: TextStyle(
              color: AppColorsScheme.of(context).textMuted,
              fontWeight: FontWeight.w600,
              fontSize: AppFontSize.md,
            ),
          ),
        ),
      ),
      title: Text(
        episode.title,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: AppColorsScheme.of(context).textPrimary,
          fontWeight: FontWeight.w500,
          fontSize: AppFontSize.md,
        ),
      ),
      subtitle: Text(
        episode.durationFormatted,
        style: TextStyle(
            color: AppColorsScheme.of(context).textMuted,
            fontSize: AppFontSize.xs),
      ),
      trailing: AppIconButton(
        icon: AppIcon(
            icon: AppIcons.play,
            size: 20,
            color: AppColorsScheme.of(context).textPrimary),
        onPressed: onPlay,
        size: 36,
        iconSize: 20,
      ),
      onTap: onPlay,
    );
  }
}
