import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tunify/ui/widgets/common/button.dart';
import 'package:tunify/ui/widgets/common/back_title_app_bar.dart';
import 'package:tunify/ui/widgets/common/sheet.dart';
import 'package:tunify/ui/widgets/library/song_list_tile.dart';
import 'package:tunify/core/constants/app_icons.dart';
import 'package:tunify/data/models/library_playlist.dart' show ShuffleMode;
import 'package:tunify/data/models/song.dart';
import 'package:tunify/features/settings/content_settings_provider.dart';
import 'package:tunify/features/home/home_state_provider.dart';
import 'package:tunify/features/library/library_provider.dart';
import 'package:tunify/features/player/player_state_provider.dart';
import 'package:tunify/ui/theme/app_colors.dart';
import 'package:tunify/ui/theme/design_tokens.dart';
import '../player/song_options_sheet.dart';
import 'package:tunify/ui/widgets/common/empty_state_placeholder.dart';
import 'package:tunify/ui/widgets/player/mini_player.dart';
import 'package:tunify/ui/theme/app_colors_scheme.dart';


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
    final shuffleMode = ref.watch(recentlyPlayedShuffleModeProvider);
    final shuffleEnabled = shuffleMode != ShuffleMode.none;

    return Scaffold(
      backgroundColor: AppColorsScheme.of(context).background,
      appBar: const BackTitleAppBar(title: 'Recently Played'),
      body: displaySongs.isEmpty
          ? EmptyStatePlaceholder(
              icon: AppIcon(
                icon: AppIcons.musicNote,
                color: AppColorsScheme.of(context).textMuted,
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
                      _RecentlyPlayedShuffleButton(
                        shuffleMode: shuffleMode,
                        hasSongs: displaySongs.isNotEmpty,
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
                                queueSource: 'recently_played',
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
                  style: TextStyle(
                    color: AppColorsScheme.of(context).textMuted,
                    fontSize: AppFontSize.sm,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                songs[index].durationFormatted,
                style: TextStyle(
                  color: AppColorsScheme.of(context).textMuted,
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
                style: TextStyle(
                  color: AppColorsScheme.of(context).textMuted,
                  fontSize: AppFontSize.md,
                ),
              ),
              AppIconButton(
                icon: AppIcon(
                  icon: AppIcons.moreVert,
                  color: AppColorsScheme.of(context).textMuted,
                  size: 20,
                ),
                onPressedWithContext: (btnCtx) =>
                    showSongOptionsSheet(context, song: songs[index], ref: ref, buttonContext: btnCtx),
                size: 40,
                iconSize: 20,
                iconAlignment: Alignment.centerRight,
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
                  style: TextStyle(
                    color: AppColorsScheme.of(context).textMuted,
                    fontSize: AppFontSize.sm,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                song.durationFormatted,
                style: TextStyle(
                  color: AppColorsScheme.of(context).textMuted,
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
                style: TextStyle(
                  color: AppColorsScheme.of(context).textMuted,
                  fontSize: AppFontSize.md,
                ),
              ),
              AppIconButton(
                icon: AppIcon(
                  icon: AppIcons.moreVert,
                  color: AppColorsScheme.of(context).textMuted,
                  size: 20,
                ),
                onPressedWithContext: (btnCtx) => showSongOptionsSheet(context, song: song, ref: ref, buttonContext: btnCtx),
                size: 40,
                iconSize: 20,
                iconAlignment: Alignment.centerRight,
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
        style: TextStyle(
          color: AppColorsScheme.of(context).textSecondary,
          fontSize: AppFontSize.base,
          fontWeight: FontWeight.w700,
          letterSpacing: AppLetterSpacing.normal,
        ),
      ),
    );
  }
}

// ─── Shuffle Button ───────────────────────────────────────────────────────────

class _RecentlyPlayedShuffleButton extends ConsumerWidget {
  const _RecentlyPlayedShuffleButton({
    required this.shuffleMode,
    required this.hasSongs,
  });

  final ShuffleMode shuffleMode;
  final bool hasSongs;

  void _showShuffleModeSheet(BuildContext context, WidgetRef ref) {
    showAppSheet(
      context,
      child: _RecentlyPlayedShuffleModeSheet(current: shuffleMode),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shuffleEnabled = shuffleMode != ShuffleMode.none;

    return AppIconButton(
      icon: SizedBox(
        width: 24,
        height: 24,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            AppIcon(
              icon: AppIcons.shuffle,
              size: 24,
              color: shuffleEnabled
                  ? AppColors.primary
                  : AppColorsScheme.of(context).textPrimary,
            ),
            if (shuffleMode == ShuffleMode.smart)
              Positioned(
                right: -6,
                top: -6,
                child: Icon(
                  Icons.auto_awesome,
                  size: 13,
                  color: shuffleEnabled
                      ? AppColors.primary
                      : AppColorsScheme.of(context).textPrimary,
                ),
              ),
          ],
        ),
      ),
      onPressed: hasSongs ? () => _showShuffleModeSheet(context, ref) : null,
      size: 40,
      iconSize: 24,
    );
  }
}

// ─── Shuffle Mode Sheet ───────────────────────────────────────────────────────

class _RecentlyPlayedShuffleModeSheet extends ConsumerWidget {
  const _RecentlyPlayedShuffleModeSheet({required this.current});

  final ShuffleMode current;

  void _set(BuildContext context, WidgetRef ref, ShuffleMode mode) {
    ref.read(libraryProvider.notifier).setRecentlyPlayedShuffleMode(mode);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(mainAxisSize: MainAxisSize.min, children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(
            kSheetHorizontalPadding, AppSpacing.lg, kSheetHorizontalPadding, AppSpacing.md),
        child: Text('Shuffle',
            style: TextStyle(
                color: AppColorsScheme.of(context).textPrimary,
                fontSize: AppFontSize.xl,
                fontWeight: FontWeight.w700)),
      ),
      _ShuffleModeTile(
        icon: AppIcons.shuffle,
        label: 'Shuffle off',
        selected: current == ShuffleMode.none,
        onTap: () => _set(context, ref, ShuffleMode.none),
      ),
      _ShuffleModeTile(
        icon: AppIcons.shuffle,
        label: 'Regular Shuffle',
        subtitle: 'Shuffle songs in recently played',
        selected: current == ShuffleMode.regular,
        onTap: () => _set(context, ref, ShuffleMode.regular),
      ),
      _ShuffleModeTile(
        icon: AppIcons.shuffle,
        label: 'Smart Shuffle',
        subtitle: 'Shuffle + mix in recommended songs',
        selected: current == ShuffleMode.smart,
        isSmart: true,
        onTap: () => _set(context, ref, ShuffleMode.smart),
      ),
      const SizedBox(height: AppSpacing.xl),
    ]);
  }
}

class _ShuffleModeTile extends StatelessWidget {
  const _ShuffleModeTile({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    this.subtitle,
    this.isSmart = false,
  });

  final List<List<dynamic>> icon;
  final String label;
  final String? subtitle;
  final bool selected;
  final bool isSmart;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.primary : AppColorsScheme.of(context).textSecondary;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
          horizontal: kSheetHorizontalPadding, vertical: 4),
      leading: isSmart
          ? SizedBox(
              width: 24,
              height: 24,
              child: Stack(children: [
                AppIcon(icon: icon, size: 24, color: color),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Icon(Icons.auto_awesome, size: 10, color: color),
                ),
              ]),
            )
          : AppIcon(icon: icon, size: 24, color: color),
      title: Text(label,
          style: TextStyle(
              color: selected ? AppColors.primary : AppColorsScheme.of(context).textPrimary,
              fontWeight: selected ? FontWeight.w600 : FontWeight.normal)),
      subtitle: subtitle != null
          ? Text(subtitle!,
              style: TextStyle(
                  color: AppColorsScheme.of(context).textMuted, fontSize: AppFontSize.sm))
          : null,
      trailing: selected
          ? AppIcon(icon: AppIcons.check, color: AppColors.primary, size: 24)
          : null,
      onTap: onTap,
    );
  }
}
