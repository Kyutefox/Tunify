import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../common/sheet.dart';
import 'package:tunify/core/constants/app_icons.dart';
import 'package:tunify/data/models/related_feed.dart';
import 'package:tunify/data/models/mood.dart';
import 'package:tunify/data/models/song.dart';
import 'package:tunify/features/home/home_state_provider.dart';
import 'package:tunify/features/player/player_state_provider.dart';
import 'package:tunify/ui/theme/app_colors.dart';
import 'package:tunify/ui/theme/design_tokens.dart';
import 'package:tunify/ui/theme/app_colors_scheme.dart';

void showMoodBrowseSheet(
  BuildContext context, {
  List<Mood>? moods,
  Mood? initialMood,
}) {
  showAppSheet(
    context,
    maxHeight: null,
    child: ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      child: _MoodBrowseSheet(
        moods: moods,
        initialMood: initialMood,
      ),
    ),
  );
}

class _MoodBrowseSheet extends ConsumerStatefulWidget {
  const _MoodBrowseSheet({
    this.moods,
    this.initialMood,
  });
  final List<Mood>? moods;
  final Mood? initialMood;

  @override
  ConsumerState<_MoodBrowseSheet> createState() => _MoodBrowseSheetState();
}

class _MoodBrowseSheetState extends ConsumerState<_MoodBrowseSheet> {
  final _pages = <_PageEntry>[];
  bool _loading = false;
  bool _openingWithInitialMood = false;
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    if (widget.initialMood != null) {
      _openingWithInitialMood = true;
      _pages.add(_PageEntry(title: 'Moods & Genres', moods: widget.moods));
      _browseMood(widget.initialMood!);
    } else {
      _pages.add(_PageEntry(title: 'Moods & Genres', moods: widget.moods));
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _browseMood(Mood mood) async {
    if (_loading) return;
    if (mood.browseId == null || mood.browseId!.isEmpty) return;

    setState(() => _loading = true);
    try {
      final sm = ref.read(streamManagerProvider);
      final detail = await sm.getMoodDetail(
        mood.browseId!,
        params: mood.browseParams,
      );

      if (!mounted) return;

      if (detail.subCategories.isEmpty && detail.playlists.isEmpty) {
        setState(() {
          _pages.add(_PageEntry(
            title: mood.label,
            moods: null,
            playlists: null,
            gradient: mood.gradient,
          ));
          _loading = false;
          _openingWithInitialMood = false;
        });
        return;
      }

      final subMoods = detail.subCategories
          .asMap()
          .entries
          .map((e) => Mood(
                id: e.value.browseId,
                label: e.value.title,
                query: e.value.title,
                browseId: e.value.browseId,
                browseParams: e.value.params,
                subtitle: e.value.sectionTitle,
                gradient: AppColors
                    .moodGradients[e.key % AppColors.moodGradients.length],
              ))
          .toList();

      setState(() {
        _pages.add(_PageEntry(
          title: mood.label,
          moods: subMoods.isNotEmpty ? subMoods : null,
          playlists: detail.playlists,
          gradient: mood.gradient,
        ));
        _loading = false;
        _openingWithInitialMood = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading = false;
          _openingWithInitialMood = false;
        });
      }
    }
  }

  Future<void> _playPlaylist(MoodPlaylist playlist) async {
    setState(() => _loading = true);
    try {
      final sm = ref.read(streamManagerProvider);
      final result = await sm.getCollectionTracks(playlist.id);

      if (!mounted) return;
      setState(() => _loading = false);

      final songs = result.tracks.map(Song.fromTrack).toList();

      if (songs.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No songs found in this playlist')),
        );
        return;
      }

      ref.read(playerProvider.notifier).playSong(songs.first, queue: songs);
      Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load playlist: $e')),
        );
      }
    }
  }

  bool _popPage() {
    if (_pages.length > 1) {
      setState(() => _pages.removeLast());
      return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final currentPage = _pages.last;
    final canPop = _pages.length > 1;
    final homeMoods = ref.watch(moodsProvider);
    final isRootPage = _pages.isNotEmpty && _pages.first == currentPage;
    final skipRootGrid = isRootPage &&
        (_loading || _openingWithInitialMood) &&
        widget.initialMood != null;
    final effectiveMoods = skipRootGrid
        ? <Mood>[]
        : (currentPage.moods != null && currentPage.moods!.isNotEmpty
            ? currentPage.moods!
            : (isRootPage ? homeMoods : <Mood>[]));

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxContentHeight = constraints.maxHeight - 120;
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                kSheetHorizontalPadding,
                AppSpacing.sm,
                kSheetHorizontalPadding,
                AppSpacing.sm,
              ),
              child: Row(
                children: [
                  if (canPop)
                    GestureDetector(
                      onTap: _popPage,
                      child: Padding(
                        padding: const EdgeInsets.only(right: AppSpacing.md),
                        child: AppIcon(
                          icon: AppIcons.back,
                          color: AppColorsScheme.of(context).textPrimary,
                          size: 20,
                        ),
                      ),
                    ),
                  Expanded(
                    child: Text(
                      currentPage.title,
                      style: TextStyle(
                        color: AppColorsScheme.of(context).textPrimary,
                        fontSize: AppFontSize.h3,
                        fontWeight: FontWeight.w700,
                        letterSpacing: AppLetterSpacing.heading,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: AppIcon(
                      icon: AppIcons.close,
                      color: AppColorsScheme.of(context).textSecondary,
                      size: 24,
                    ),
                  ),
                ],
              ),
            ),
            if (_loading)
              Padding(
                padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
                child: LinearProgressIndicator(
                  color: AppColors.primary,
                  backgroundColor: AppColorsScheme.of(context).surfaceLight,
                  minHeight: 2,
                ),
              ),
            ConstrainedBox(
              constraints: BoxConstraints(maxHeight: maxContentHeight),
              child: AnimatedSwitcher(
                duration: AppDuration.fast,
                child: SingleChildScrollView(
                  key: ValueKey(_pages.length),
                  controller: _scrollController,
                  padding: const EdgeInsets.fromLTRB(
                    kSheetHorizontalPadding,
                    AppSpacing.sm,
                    kSheetHorizontalPadding,
                    AppSpacing.max,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Only show mood chips when there are no playlists (e.g. root page or sub-mood with no playlists).
                      if (effectiveMoods.isNotEmpty &&
                          (currentPage.playlists == null ||
                              currentPage.playlists!.isEmpty)) ...[
                        if (_pages.length > 1)
                          Padding(
                            padding: EdgeInsets.only(bottom: AppSpacing.md),
                            child: Text(
                              'Categories',
                              style: TextStyle(
                                color:
                                    AppColorsScheme.of(context).textSecondary,
                                fontSize: AppFontSize.base,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          cacheExtent: 1000,
                          addAutomaticKeepAlives: true,
                          addRepaintBoundaries: true,
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: AppSpacing.md,
                            mainAxisSpacing: AppSpacing.md,
                            childAspectRatio: 3.0,
                          ),
                          itemCount: effectiveMoods.length,
                          itemBuilder: (ctx, i) {
                            final mood = effectiveMoods[i];
                            return _SheetMoodTile(
                              mood: mood,
                              onTap: () => _browseMood(mood),
                            );
                          },
                        ),
                        const SizedBox(height: AppSpacing.xxl),
                      ],

                      if (currentPage.playlists != null &&
                          currentPage.playlists!.isNotEmpty) ...[
                        Padding(
                          padding: EdgeInsets.only(bottom: AppSpacing.md),
                          child: Text(
                            'Playlists',
                            style: TextStyle(
                              color: AppColorsScheme.of(context).textSecondary,
                              fontSize: AppFontSize.base,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        ...currentPage.playlists!.map(
                          (pl) => _PlaylistRow(
                            playlist: pl,
                            onTap: () => _playPlaylist(pl),
                          ),
                        ),
                      ],
                      if (effectiveMoods.isEmpty &&
                          (currentPage.playlists == null ||
                              currentPage.playlists!.isEmpty) &&
                          _pages.length > 1)
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              vertical: AppSpacing.xxl),
                          child: Center(
                            child: Text(
                              'No subcategories or playlists for this mood.',
                              style: TextStyle(
                                color: AppColorsScheme.of(context).textMuted,
                                fontSize: AppFontSize.base,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _PageEntry {
  final String title;
  final List<Mood>? moods;
  final List<MoodPlaylist>? playlists;
  final LinearGradient? gradient;

  const _PageEntry({
    required this.title,
    this.moods,
    this.playlists,
    this.gradient,
  });
}

class _SheetMoodTile extends StatelessWidget {
  const _SheetMoodTile({required this.mood, required this.onTap});
  final Mood mood;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: mood.gradient,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            mood.label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: AppFontSize.base,
              fontWeight: FontWeight.w700,
              shadows: [Shadow(color: Colors.black26, blurRadius: 4)],
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }
}

class _PlaylistRow extends StatelessWidget {
  const _PlaylistRow({required this.playlist, required this.onTap});
  final MoodPlaylist playlist;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.md),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.sm),
              child: playlist.thumbnailUrl.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: playlist.thumbnailUrl,
                      width: 56,
                      height: 56,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(
                        width: 56,
                        height: 56,
                        color: AppColorsScheme.of(context).surfaceLight,
                      ),
                      errorWidget: (_, __, ___) => Container(
                        width: 56,
                        height: 56,
                        color: AppColorsScheme.of(context).surfaceLight,
                        child: AppIcon(
                          icon: AppIcons.musicNote,
                          color: AppColorsScheme.of(context).textMuted,
                        ),
                      ),
                    )
                  : Container(
                      width: 56,
                      height: 56,
                      color: AppColorsScheme.of(context).surfaceLight,
                      child: AppIcon(
                        icon: AppIcons.musicNote,
                        color: AppColorsScheme.of(context).textMuted,
                      ),
                    ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    playlist.title,
                    style: TextStyle(
                      color: AppColorsScheme.of(context).textPrimary,
                      fontSize: AppFontSize.lg,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (playlist.subtitle != null &&
                      playlist.subtitle!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      playlist.subtitle!,
                      style: TextStyle(
                        color: AppColorsScheme.of(context).textMuted,
                        fontSize: AppFontSize.sm,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            AppIcon(
              icon: AppIcons.playCircleOutline,
              color: AppColorsScheme.of(context).textSecondary,
              size: 28,
            ),
          ],
        ),
      ),
    );
  }
}
