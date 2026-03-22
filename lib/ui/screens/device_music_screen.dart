import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:on_audio_query_pluse/on_audio_query.dart';

import 'package:tunify/ui/widgets/button.dart';
import 'package:tunify/ui/widgets/input_field.dart';
import 'package:tunify/ui/widgets/empty_list_message.dart';
import 'package:tunify/ui/widgets/items/song_list_tile.dart';
import 'package:tunify/core/constants/app_icons.dart';
import 'package:tunify/core/constants/app_strings.dart';
import 'package:tunify/data/models/song.dart';
import 'package:tunify/features/settings/content_settings_provider.dart';
import 'package:tunify/features/device/device_music_provider.dart';
import 'package:tunify/features/player/player_state_provider.dart';
import 'package:tunify/ui/theme/app_colors.dart';
import 'package:tunify/ui/theme/design_tokens.dart';
import 'player/song_options_sheet.dart';
import 'package:tunify/ui/widgets/empty_state_placeholder.dart';

class DeviceMusicScreen extends ConsumerStatefulWidget {
  const DeviceMusicScreen({super.key});

  @override
  ConsumerState<DeviceMusicScreen> createState() => _DeviceMusicScreenState();
}

class _DeviceMusicScreenState extends ConsumerState<DeviceMusicScreen>
    with WidgetsBindingObserver {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    Future.microtask(() {
      ref.read(deviceMusicProvider.notifier).loadSongs();
    });
    _searchController.addListener(() {
      setState(() => _query = _searchController.text.toLowerCase());
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _searchController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      final deviceState = ref.read(deviceMusicProvider);
      if (!deviceState.hasPermission) {
        ref.read(deviceMusicProvider.notifier).loadSongs();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(deviceMusicProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.base,
                AppSpacing.base,
                AppSpacing.base,
                AppSpacing.sm,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Device Music',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: AppFontSize.h1,
                            fontWeight: FontWeight.w700,
                            letterSpacing: AppLetterSpacing.display,
                          ),
                        ),
                        if (state.songs.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            '${state.songs.length} songs',
                            style: const TextStyle(
                              color: AppColors.textMuted,
                              fontSize: AppFontSize.md,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (state.songs.isNotEmpty) ...[
                    GestureDetector(
                      onTap: () {
                        final filtered = _filteredSongs(state.songs);
                        final songs = filterByExplicitSetting(
                            filtered, ref.read(showExplicitContentProvider));
                        if (songs.isEmpty) return;
                        final shuffled = List<Song>.from(songs)
                          ..shuffle(Random());
                        ref.read(playerProvider.notifier).playSong(
                              shuffled.first,
                              queue: shuffled,
                              queueSource: 'device',
                            );
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.xs),
                        child: AppIcon(
                          icon: AppIcons.shuffle,
                          color: AppColors.textSecondary,
                          size: 24,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    GestureDetector(
                      onTap: () {
                        final filtered = _filteredSongs(state.songs);
                        final songs = filterByExplicitSetting(
                            filtered, ref.read(showExplicitContentProvider));
                        if (songs.isEmpty) return;
                        ref.read(playerProvider.notifier).playSong(
                              songs.first,
                              queue: songs,
                              queueSource: 'device',
                            );
                      },
                      child: Container(
                        width: 42,
                        height: 42,
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: AppIcon(
                            icon: AppIcons.play,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            if (state.songs.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.base,
                  vertical: AppSpacing.sm,
                ),
                child: AppInputField(
                  controller: _searchController,
                  hintText: 'Search songs on device',
                  style: InputFieldStyle.filled,
                  prefixIcon: AppIcon(
                    icon: AppIcons.search,
                    color: AppColors.textMuted,
                    size: 20,
                  ),
                  suffixIcon: _query.isNotEmpty
                      ? GestureDetector(
                          onTap: () => _searchController.clear(),
                          child: AppIcon(
                            icon: AppIcons.clear,
                            color: AppColors.textMuted,
                            size: 18,
                          ),
                        )
                      : null,
                ),
              ),

            Expanded(child: _buildBody(state)),
          ],
        ),
      ),
    );
  }

  List<Song> _filteredSongs(List<Song> songs) {
    if (_query.isEmpty) return songs;
    return songs
        .where((s) =>
            s.title.toLowerCase().contains(_query) ||
            s.artist.toLowerCase().contains(_query))
        .toList();
  }

  Widget _buildBody(DeviceMusicState state) {
    if (state.isLoading && state.songs.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (!state.hasPermission && state.error != null) {
      return _PermissionPrompt(
        permanentlyDenied: state.permanentlyDenied,
        onGrant: () => ref.read(deviceMusicProvider.notifier).loadSongs(),
        onOpenSettings: () async {
          await ref.read(deviceMusicProvider.notifier).openAppSettings();
        },
      );
    }

    if (state.songs.isEmpty) {
      return EmptyStatePlaceholder(
        icon: AppIcon(
          icon: AppIcons.musicNote,
          color: AppColors.textMuted,
          size: 48,
        ),
        title: 'No music found on device',
        actionLabel: 'Refresh',
        onAction: () =>
            ref.read(deviceMusicProvider.notifier).loadSongs(),
      );
    }

    final filtered = _filteredSongs(state.songs);
    final showExplicit = ref.watch(showExplicitContentProvider);
    final displaySongs = filterByExplicitSetting(filtered, showExplicit);

    if (displaySongs.isEmpty) {
      return EmptyListMessage(emptyLabel: 'songs', query: _query);
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 120),
      itemCount: displaySongs.length,
      itemBuilder: (context, index) {
        final song = displaySongs[index];
        final audioId = int.tryParse(song.id.replaceFirst('device_', '')) ?? 0;

        return SongListTile(
          song: song,
          onTap: () {
            ref.read(playerProvider.notifier).playSong(
                  song,
                  queue: displaySongs,
                  queueSource: 'device',
                );
          },
          highlightBackground: true,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.base,
            vertical: AppSpacing.sm,
          ),
          thumbnail: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.sm),
            child: SizedBox(
              width: 48,
              height: 48,
              child: QueryArtworkWidget(
                id: audioId,
                type: ArtworkType.AUDIO,
                artworkBorder: BorderRadius.zero,
                artworkWidth: 48,
                artworkHeight: 48,
                nullArtworkWidget: Container(
                  width: 48,
                  height: 48,
                  color: AppColors.surfaceLight,
                  child: Center(
                    child: AppIcon(
                      icon: AppIcons.musicNote,
                      color: AppColors.textMuted,
                      size: 22,
                    ),
                  ),
                ),
              ),
            ),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                song.durationFormatted,
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: AppFontSize.sm,
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
}

class _PermissionPrompt extends StatelessWidget {
  const _PermissionPrompt({
    required this.permanentlyDenied,
    required this.onGrant,
    required this.onOpenSettings,
  });
  final bool permanentlyDenied;
  final VoidCallback onGrant;
  final VoidCallback onOpenSettings;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppIcon(
              icon: AppIcons.folder,
              color: AppColors.textMuted,
              size: 48,
            ),
            const SizedBox(height: AppSpacing.lg),
            const Text(
              'Allow access to device music',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: AppFontSize.xxl,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              permanentlyDenied
                  ? 'Permission was denied. Please enable it in Settings.'
                  : '${AppStrings.appName} needs permission to read audio files stored on your device.',
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: AppFontSize.base,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xl),
            AppButton(
              label: permanentlyDenied ? 'Open Settings' : 'Grant Permission',
              onPressed: permanentlyDenied ? onOpenSettings : onGrant,
              backgroundColor: AppColors.accent,
            ),
          ],
        ),
      ),
    );
  }
}
