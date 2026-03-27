import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tunify/ui/widgets/common/button.dart';
import 'package:tunify/ui/widgets/common/back_title_app_bar.dart';
import 'package:tunify/ui/widgets/library/song_list_tile.dart';
import 'package:tunify/core/constants/app_icons.dart';
import 'package:tunify/data/models/song.dart';
import 'package:tunify/features/settings/content_settings_provider.dart';
import 'package:tunify/features/home/home_state_provider.dart';
import 'package:tunify/features/player/player_state_provider.dart';
import 'package:tunify/ui/theme/app_colors.dart';
import 'package:tunify/ui/theme/design_tokens.dart';
import '../player/song_options_sheet.dart';
import 'package:tunify/ui/widgets/common/empty_state_placeholder.dart';
import 'package:tunify/ui/widgets/player/mini_player.dart';

class _RpShuffleNotifier extends Notifier<bool> {
  @override
  bool build() => false;
  void toggle() => state = !state;
}

final _rpShuffleProvider = NotifierProvider<_RpShuffleNotifier, bool>(_RpShuffleNotifier.new);

class RecentlyPlayedScreen extends ConsumerWidget {
  const RecentlyPlayedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final songs = ref.watch(recentlyPlayedProvider);
    final timestamps = ref.watch(recentlyPlayedTimestampsProvider);
    final showExplicit = ref.watch(showExplicitContentProvider);
    final displaySongs = filterByExplicitSetting(songs, showExplicit);
    final displayTimestamps = <DateTime>[];
    for (int i = 0; i < songs.length; i++) {
      if (showExplicit || !songs[i].isExplicit) {
        displayTimestamps.add(
            i < timestamps.length ? timestamps[i] : DateTime.now());
      }
    }
    final hasSong = ref.watch(currentSongProvider) != null;
    final shuffleEnabled = ref.watch(_rpShuffleProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const BackTitleAppBar(title: 'Recently Played'),
      body: displaySongs.isEmpty
          ? EmptyStatePlaceholder(
              icon: AppIcon(
                icon: AppIcons.musicNote,
                color: AppColors.textMuted,
                size: 48,
              ),
              title: 'Nothing played yet',
              subtitle:
                  'Start playing songs and they\'ll appear here.',
            )
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.base,
                    vertical: AppSpacing.md,
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: AppIcon(
                          icon: AppIcons.shuffle,
                          size: 24,
                          color: shuffleEnabled
                              ? AppColors.primary
                              : AppColors.textMuted,
                        ),
                        onPressed: () {
                          ref.read(_rpShuffleProvider.notifier).toggle();
                        },
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: () {
                          final queue = shuffleEnabled
                              ? (List<Song>.from(displaySongs)..shuffle(Random()))
                              : displaySongs;
                          ref.read(playerProvider.notifier).playSong(
                                queue.first,
                                queue: queue,
                              );
                        },
                        child: Container(
                          width: 56,
                          height: 56,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.primary,
                          ),
                          child: Center(
                            child: AppIcon(
                              icon: AppIcons.play,
                              color: Colors.white,
                              size: 32,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: _DateGroupedSongList(
                    songs: displaySongs,
                    timestamps: displayTimestamps,
                    onPlay: (song) {
                      ref.read(playerProvider.notifier).playSong(song);
                    },
                  ),
                ),
              ],
            ),
      bottomNavigationBar: hasSong
          ? const SafeArea(
              child: MiniPlayer(key: ValueKey('recently-played-mini-player')))
          : null,
    );
  }
}


enum _DateGroup { today, yesterday, older }

class _DateGroupedSongList extends ConsumerWidget {
  const _DateGroupedSongList({
    required this.songs,
    required this.timestamps,
    required this.onPlay,
  });

  final List<Song> songs;
  final List<DateTime> timestamps;
  final void Function(Song song) onPlay;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    final groups = <(_DateGroup, String, List<Song>)>[];
    final todaySongs = <Song>[];
    final yesterdaySongs = <Song>[];
    final olderMap = <String, List<Song>>{};
    final olderOrder = <String>[];

    for (int i = 0; i < songs.length; i++) {
      final ts = i < timestamps.length ? timestamps[i] : now;
      final day = DateTime(ts.year, ts.month, ts.day);
      if (day == today) {
        todaySongs.add(songs[i]);
      } else if (day == yesterday) {
        yesterdaySongs.add(songs[i]);
      } else {
        final label = _formatDate(ts);
        if (!olderMap.containsKey(label)) {
          olderMap[label] = [];
          olderOrder.add(label);
        }
        olderMap[label]!.add(songs[i]);
      }
    }

    if (todaySongs.isNotEmpty) {
      groups.add((_DateGroup.today, 'Today', todaySongs));
    }
    if (yesterdaySongs.isNotEmpty) {
      groups.add((_DateGroup.yesterday, 'Yesterday', yesterdaySongs));
    }
    for (final label in olderOrder) {
      groups.add((_DateGroup.older, label, olderMap[label]!));
    }

    if (timestamps.isEmpty) {
      return ListView.builder(
        cacheExtent: 1000,
        addAutomaticKeepAlives: true,
        itemExtent: 70,
        padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
        itemCount: songs.length,
        itemBuilder: (context, index) => SongListTile(
          song: songs[index],
          onTap: () => onPlay(songs[index]),
          subtitle: Row(
            children: [
              Flexible(
                child: Text(
                  songs[index].artist,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: AppFontSize.sm,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                songs[index].durationFormatted,
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: AppFontSize.sm,
                ),
              ),
            ],
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                songs[index].durationFormatted,
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: AppFontSize.md,
                ),
              ),
              AppIconButton(
                icon: AppIcon(
                  icon: AppIcons.moreVert,
                  color: AppColors.textMuted,
                  size: 20,
                ),
                onPressedWithContext: (btnCtx) =>
                    showSongOptionsSheet(context, song: songs[index], ref: ref, buttonContext: btnCtx),
                size: 40,
                iconSize: 20,
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      cacheExtent: 1000,
      addAutomaticKeepAlives: true,
      padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
      itemCount: _itemCount(groups),
      itemBuilder: (context, index) {
        final (isHeader, label, song) = _itemAt(groups, index);
        if (isHeader) {
          return _DateHeader(label: label);
        }
        return SongListTile(
          song: song!,
          onTap: () => onPlay(song),
          subtitle: Row(
            children: [
              Flexible(
                child: Text(
                  song.artist,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: AppFontSize.sm,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                song.durationFormatted,
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: AppFontSize.sm,
                ),
              ),
            ],
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                song.durationFormatted,
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: AppFontSize.md,
                ),
              ),
              AppIconButton(
                icon: AppIcon(
                  icon: AppIcons.moreVert,
                  color: AppColors.textMuted,
                  size: 20,
                ),
                onPressedWithContext: (btnCtx) => showSongOptionsSheet(context, song: song, ref: ref, buttonContext: btnCtx),
                size: 40,
                iconSize: 20,
              ),
            ],
          ),
        );
      },
    );
  }

  int _itemCount(List<(_DateGroup, String, List<Song>)> groups) {
    int count = 0;
    for (final (_, _, songs) in groups) {
      count += 1 + songs.length;
    }
    return count;
  }

  (bool isHeader, String label, Song? song) _itemAt(
    List<(_DateGroup, String, List<Song>)> groups,
    int index,
  ) {
    int cursor = 0;
    for (final (_, label, songs) in groups) {
      if (index == cursor) return (true, label, null);
      cursor++;
      if (index < cursor + songs.length) {
        return (false, '', songs[index - cursor]);
      }
      cursor += songs.length;
    }
    return (true, '', null);
  }

  String _formatDate(DateTime dt) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }
}


class _DateHeader extends StatelessWidget {
  const _DateHeader({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.base,
        AppSpacing.lg,
        AppSpacing.base,
        AppSpacing.sm,
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: AppFontSize.base,
          fontWeight: FontWeight.w700,
          letterSpacing: AppLetterSpacing.normal,
        ),
      ),
    );
  }
}
