import 'dart:async';
import 'dart:math';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tunify/ui/widgets/collection_detail_scaffold.dart';
import 'package:tunify/ui/widgets/pages/search_page.dart';
import 'package:tunify/ui/widgets/button.dart';
import 'package:tunify/ui/widgets/sheet.dart';
import 'package:tunify/ui/widgets/confirm_dialog.dart';
import 'package:tunify/ui/widgets/back_title_app_bar.dart';
import 'package:tunify/ui/widgets/empty_list_message.dart';
import 'package:tunify/ui/widgets/items/song_list_tile.dart';
import 'package:tunify/ui/widgets/items/now_playing_indicator.dart';
import 'package:tunify/ui/widgets/items/multi_download_button.dart';
import 'package:tunify/ui/widgets/input_field.dart';
import '../home/home_shared.dart';
import 'package:tunify/core/constants/app_icons.dart';
import 'package:tunify/data/models/song.dart';
import 'package:tunify/features/settings/content_settings_provider.dart';
import 'package:tunify/features/home/home_state_provider.dart';
import 'package:tunify/features/library/library_provider.dart';
import 'package:tunify/features/player/player_state_provider.dart';
import 'package:tunify/ui/theme/app_colors.dart';
import 'package:tunify/ui/theme/design_tokens.dart';
import 'package:tunify/ui/theme/app_routes.dart';
import '../player/song_options_sheet.dart';
import 'package:tunify/ui/widgets/items/mini_player.dart';

class LibraryLikedSongsScreen extends ConsumerStatefulWidget {
  const LibraryLikedSongsScreen({super.key});

  @override
  ConsumerState<LibraryLikedSongsScreen> createState() =>
      _LibraryLikedSongsScreenState();
}

class _LibraryLikedSongsScreenState
    extends ConsumerState<LibraryLikedSongsScreen> {
  @override
  Widget build(BuildContext context) {
    final likedSongs = ref.watch(libraryProvider.select((s) => s.likedSongs));
    final showExplicit = ref.watch(showExplicitContentProvider);
    final filteredSongs = filterByExplicitSetting(likedSongs, showExplicit);
    final isEmpty = likedSongs.isEmpty;
    final hasSong = ref.watch(currentSongProvider) != null;

    final subtitle = Row(
      children: [
        Text(
          '${likedSongs.length} ${likedSongs.length == 1 ? 'song' : 'songs'}',
          style: TextStyle(
            color: AppColors.textMuted.withValues(alpha: 0.9),
            fontSize: AppFontSize.base,
          ),
        ),
        if (likedSongs.isNotEmpty) ...[
          Text(
            ' • ',
            style: TextStyle(
              color: AppColors.textMuted.withValues(alpha: 0.9),
              fontSize: AppFontSize.base,
            ),
          ),
          Text(
            _formatDuration(likedSongs),
            style: TextStyle(
              color: AppColors.textMuted.withValues(alpha: 0.9),
              fontSize: AppFontSize.base,
            ),
          ),
        ],
      ],
    );

    return CollectionDetailScaffold(
      isEmpty: isEmpty,
      paletteColor: const Color(0xFFE91E8C),
      title: 'Liked Songs',
      headerExpandedChild: CollectionDetailExpandedContent(
        cover: _LikedCoverWithPalette(songs: likedSongs),
        title: 'Liked Songs',
        subtitle: subtitle,
      ),
      actionRow: _LikedActionRow(
        songs: likedSongs,
        filteredSongs: filteredSongs,
        onEdit: () => _openEditLikedSheet(context, likedSongs),
        onAddSongs: () => _openAddLikedSheet(context, ref),
      ),
      playButton: _LikedStickyPlayButton(
        songs: likedSongs,
        filteredSongs: filteredSongs,
      ),
      searchField: _SearchInLikedTap(songs: likedSongs),
      bodySlivers: [
        if (filteredSongs.isEmpty)
          const SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: Padding(
                padding: EdgeInsets.all(AppSpacing.xxl),
                child: Text(
                  'Your liked songs will appear here.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: AppFontSize.base,
                  ),
                ),
              ),
            ),
          )
        else
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final song = filteredSongs[index];
                return _LikedTrackTile(
                  song: song,
                  filteredSongs: filteredSongs,
                );
              },
              childCount: filteredSongs.length,
            ),
          ),
        const SliverToBoxAdapter(child: SizedBox(height: 160)),
      ],
      hasSong: hasSong,
      miniPlayerKey: const ValueKey('liked-songs-mini-player'),
    );
  }

  static String _formatDuration(List<Song> songs) {
    if (songs.isEmpty) return '';
    final totalMs =
        songs.fold<int>(0, (sum, s) => sum + s.duration.inMilliseconds);
    final d = Duration(milliseconds: totalMs);
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    if (h > 0) return '${h}h ${m}min';
    return '${m}min';
  }
}

void _openAddLikedSheet(BuildContext context, WidgetRef ref) {
  FocusManager.instance.primaryFocus?.unfocus();
  // Reuse the recently-played / search sheet by pushing a simple add-song flow.
  // We show the same sheet used for playlists but wired to liked songs.
  showAppSheet(
    context,
    maxHeight: MediaQuery.of(context).size.height * 0.75,
    child: _AddToLikedSheet(ref: ref),
  );
}

void _openEditLikedSheet(BuildContext context, List<Song> initialSongs) {
  FocusManager.instance.primaryFocus?.unfocus();
  Navigator.of(context).push(
    appPageRoute<void>(
      builder: (_) => _EditLikedSheet(initialSongs: initialSongs),
    ),
  );
}

class _EditLikedSheet extends ConsumerStatefulWidget {
  const _EditLikedSheet({required this.initialSongs});

  final List<Song> initialSongs;

  @override
  ConsumerState<_EditLikedSheet> createState() => _EditLikedSheetState();
}

class _EditLikedSheetState extends ConsumerState<_EditLikedSheet> {
  late List<Song> _items;
  final Set<String> _pendingRemoveIds = {};

  @override
  void initState() {
    super.initState();
    _items = List<Song>.from(widget.initialSongs);
  }

  void _toggleRemove(Song song) {
    setState(() {
      if (_pendingRemoveIds.contains(song.id)) {
        _pendingRemoveIds.remove(song.id);
      } else {
        _pendingRemoveIds.add(song.id);
      }
    });
  }

  void _onReorder(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) newIndex -= 1;
      final song = _items.removeAt(oldIndex);
      _items.insert(newIndex, song);
    });
  }

  Future<void> _save() async {
    final toRemove = _pendingRemoveIds.length;
    if (toRemove > 0) {
      final confirmed = await showConfirmDialog(
        context,
        title: 'Remove $toRemove ${toRemove == 1 ? 'song' : 'songs'}?',
        message: 'These songs will be removed from your Liked Songs.',
        confirmLabel: 'Remove',
      );
      if (!confirmed) return;
    }
    final toKeep =
        _items.where((s) => !_pendingRemoveIds.contains(s.id)).toList();
    await ref.read(libraryProvider.notifier).setLikedSongsOrder(toKeep);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Liked Songs updated'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: BackTitleAppBar(
        title: 'Edit Liked Songs',
        backgroundColor: AppColors.background,
        actions: [
          TextButton(
            onPressed: _save,
            child: const Text(
              'Save',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: ReorderableListView.builder(
        buildDefaultDragHandles: false,
        itemCount: _items.length,
        onReorder: _onReorder,
        itemBuilder: (context, index) {
          final song = _items[index];
          final marked = _pendingRemoveIds.contains(song.id);
          final isNowPlaying = ref.watch(currentSongProvider)?.id == song.id;
          final isActuallyPlaying = ref.watch(isPlayingProvider);
          return ListTile(
            key: ValueKey(song.id),
            leading: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppIconButton(
                  icon: FavouriteIcon(
                    isLiked: !marked,
                    songId: song.id,
                    size: 22,
                    emptyColor: AppColors.textMuted,
                  ),
                  onPressed: () => _toggleRemove(song),
                  size: 40,
                  iconSize: 22,
                ),
                NowPlayingThumbnail(
                  isPlaying: isNowPlaying,
                  isActuallyPlaying: isActuallyPlaying,
                  size: 48,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.xs),
                    child: CachedNetworkImage(
                      imageUrl: song.thumbnailUrl,
                      width: 48,
                      height: 48,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(
                        width: 48,
                        height: 48,
                        color: AppColors.surfaceLight,
                        child: Center(
                          child: AppIcon(
                            icon: AppIcons.musicNote,
                            color: AppColors.textMuted,
                            size: 24,
                          ),
                        ),
                      ),
                      errorWidget: (_, __, ___) => Container(
                        width: 48,
                        height: 48,
                        color: AppColors.surfaceLight,
                        child: Center(
                          child: AppIcon(
                            icon: AppIcons.musicNote,
                            color: AppColors.textMuted,
                            size: 24,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            title: Text(
              song.title,
              style: TextStyle(
                color: marked
                    ? AppColors.textMuted
                    : isNowPlaying
                        ? AppColors.primary
                        : AppColors.textPrimary,
                decoration: marked ? TextDecoration.lineThrough : null,
              ),
            ),
            subtitle: Text(
              song.artist,
              style: TextStyle(
                color: AppColors.textMuted,
                decoration: marked ? TextDecoration.lineThrough : null,
              ),
            ),
            trailing: ReorderableDragStartListener(
              index: index,
              child: AppIcon(
                icon: AppIcons.dragHandle,
                color: AppColors.textMuted,
                size: 22,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _LikedCoverWithPalette extends StatelessWidget {
  const _LikedCoverWithPalette({required this.songs});

  final List<Song> songs;

  @override
  Widget build(BuildContext context) {
    const size = 200.0;
    if (songs.isEmpty) {
      return Center(
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            gradient: AppColors.loveThemeGradientFor('liked_songs'),
            borderRadius: BorderRadius.circular(AppRadius.sm),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFE91E8C).withValues(alpha: 0.35),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: const Center(
            child: FavouriteIcon(isLiked: true, size: 56, fillColor: Colors.white),
          ),
        ),
      );
    }

    final urls = songs.take(4).map((s) => s.thumbnailUrl).toList();
    const gap = 4.0;
    final cellSize = (size - gap) / 2;

    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: AppSpacing.base),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          color: AppColors.surfaceLight.withValues(alpha: 0.6),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(gap / 2),
          child: SizedBox(
            width: size,
            height: size,
            child: Column(
              children: [
                Row(
                  children: [
                    _coverImage(urls.isNotEmpty ? urls[0] : null, cellSize),
                    const SizedBox(width: gap),
                    _coverImage(urls.length > 1 ? urls[1] : null, cellSize),
                  ],
                ),
                const SizedBox(height: gap),
                Row(
                  children: [
                    _coverImage(urls.length > 2 ? urls[2] : null, cellSize),
                    const SizedBox(width: gap),
                    _coverImage(urls.length > 3 ? urls[3] : null, cellSize),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _coverImage(String? url, double s) {
    return SizedBox(
      width: s,
      height: s,
      child: url != null && url.isNotEmpty
          ? Builder(
              builder: (context) {
                final cachePx = (s * MediaQuery.devicePixelRatioOf(context)).round();
                return CachedNetworkImage(
                  imageUrl: url,
                  fit: BoxFit.cover,
                  memCacheWidth: cachePx,
                  memCacheHeight: cachePx,
                  errorWidget: (_, __, ___) => _placeholder(s),
                );
              },
            )
          : _placeholder(s),
    );
  }

  Widget _placeholder(double s) {
    return Container(
      width: s,
      height: s,
      color: AppColors.surfaceLight,
      child: AppIcon(icon: AppIcons.musicNote, color: AppColors.textMuted),
    );
  }
}

class _LikedActionRow extends ConsumerWidget {
  const _LikedActionRow({
    required this.songs,
    required this.filteredSongs,
    required this.onEdit,
    this.onAddSongs,
  });

  final List<Song> songs;
  final List<Song> filteredSongs;
  final VoidCallback onEdit;
  final VoidCallback? onAddSongs;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isEmpty = songs.isEmpty;

    if (isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(left: AppSpacing.sm, right: AppSpacing.base),
        child: Row(children: [
          _LikedAddPill(onTap: onAddSongs ?? () {}),
          const Spacer(),
        ]),
      );
    }

    final canPlay = filteredSongs.isNotEmpty;
    final shuffleEnabled = ref.watch(likedShuffleProvider);

    return SizedBox(
      height: kCollectionActionRowHeight,
      child: Padding(
        padding: const EdgeInsets.only(left: AppSpacing.sm, right: AppSpacing.base),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            AppIconButton(
              icon: AppIcon(
                icon: AppIcons.shuffle,
                size: 24,
                color: shuffleEnabled ? AppColors.primary : AppColors.textPrimary,
              ),
              onPressed: canPlay
                  ? () => ref.read(libraryProvider.notifier).toggleLikedShuffle()
                  : null,
              size: 40,
              iconSize: 24,
            ),
            AppIconButton(
              icon: AppIcon(icon: AppIcons.edit, size: 24, color: AppColors.textPrimary),
              onPressed: onEdit,
              size: 40,
              iconSize: 24,
            ),
            MultiDownloadButton(songs: songs, size: 24, iconSize: 20),
            const Spacer(),
            const SizedBox(width: 56),
          ],
        ),
      ),
    );
  }
}

class _LikedAddPill extends StatelessWidget {
  const _LikedAddPill({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.textMuted.withValues(alpha: 0.5)),
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          AppIcon(icon: AppIcons.add, size: 18, color: AppColors.textSecondary),
          const SizedBox(width: AppSpacing.xs),
          const Text('Add songs', style: TextStyle(
              color: AppColors.textSecondary, fontSize: AppFontSize.md,
              fontWeight: FontWeight.w500)),
        ]),
      ),
    );
  }
}

class _LikedStickyPlayButton extends ConsumerWidget {
  const _LikedStickyPlayButton({
    required this.songs,
    required this.filteredSongs,
  });

  final List<Song> songs;
  final List<Song> filteredSongs;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final canPlay = filteredSongs.isNotEmpty;
    final shuffleEnabled = ref.watch(likedShuffleProvider);
    return PlayCircleButton(
      onTap: canPlay
          ? () {
              final queue = shuffleEnabled
                  ? (List<Song>.from(songs)..shuffle(Random()))
                  : songs;
              ref.read(playerProvider.notifier).playSong(
                    queue.first,
                    queue: queue,
                    queueSource: 'liked',
                  );
            }
          : () {},
      size: 48,
      iconSize: 28,
    );
  }
}

class _SearchInLikedTap extends StatelessWidget {
  const _SearchInLikedTap({required this.songs});

  final List<Song> songs;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.base),
      child: GestureDetector(
        onTap: () {
          Navigator.of(context).push(
            appPageRoute<void>(
              builder: (_) => _LikedSearchPage(songs: songs),
            ),
          );
        },
        child: Container(
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.surfaceLight.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(AppRadius.input),
          ),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Row(
            children: [
              AppIcon(
                icon: AppIcons.search,
                color: AppColors.textMuted.withValues(alpha: 0.8),
                size: 20,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Search in Liked Songs',
                style: TextStyle(
                  color: AppColors.textMuted.withValues(alpha: 0.8),
                  fontSize: AppFontSize.base,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LikedSearchPage extends ConsumerStatefulWidget {
  const _LikedSearchPage({required this.songs});

  final List<Song> songs;

  @override
  ConsumerState<_LikedSearchPage> createState() => _LikedSearchPageState();
}

class _LikedSearchPageState extends ConsumerState<_LikedSearchPage> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _focusNode = FocusNode();
    _controller.addListener(() => setState(() {}));
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (mounted && _focusNode.canRequestFocus) _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = _controller.text.trim().toLowerCase();
    final hasSong = ref.watch(currentSongProvider) != null;
    final showExplicit = ref.watch(showExplicitContentProvider);
    final filtered = filterByExplicitSetting(
      query.isEmpty
          ? widget.songs
          : widget.songs
              .where((s) =>
                  s.title.toLowerCase().contains(query) ||
                  s.artist.toLowerCase().contains(query))
              .toList(),
      showExplicit,
    );

    final body = query.isEmpty
        ? SearchPageEmptyState(
            icon: AppIcon(
              icon: AppIcons.search,
              size: 64,
              color: AppColors.textMuted,
            ),
            heading: 'Search Liked Songs',
            subheading: 'Search by song title or artist',
          )
        : filtered.isEmpty
            ? EmptyListMessage(
                emptyLabel: 'matches',
                query: query,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: AppFontSize.lg,
                  fontWeight: FontWeight.w600,
                ),
              )
            : ListView.builder(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.only(bottom: AppSpacing.max),
                itemCount: filtered.length,
                itemBuilder: (context, index) {
                  final song = filtered[index];
                  return _LikedTrackTile(
                    song: song,
                    filteredSongs: filtered,
                  );
                },
              );

    final searchPage = SharedSearchPage(
      controller: _controller,
      focusNode: _focusNode,
      onBack: () => Navigator.of(context).pop(),
      onClear: () => setState(() {}),
      hintText: 'Search in Liked Songs',
      autofocus: false,
      body: body,
    );

    if (!hasSong) return searchPage;
    return Scaffold(
      backgroundColor: AppColors.background,
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(child: searchPage),
            const MiniPlayer(key: ValueKey('liked-search-mini-player')),
            SizedBox(height: MediaQuery.of(context).viewPadding.bottom),
          ],
        ),
      ),
    );
  }
}

class _LikedTrackTile extends ConsumerWidget {
  const _LikedTrackTile({
    required this.song,
    required this.filteredSongs,
  });

  final Song song;
  final List<Song> filteredSongs;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SongListTile(
      song: song,
      showIndexIndicator: false,
      onTap: () {
        ref.read(playerProvider.notifier).playSong(song,
            queue: filteredSongs,
            queueSource: 'liked');
      },
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
  }
}

// ─── Add to Liked Sheet ───────────────────────────────────────────────────────

class _AddToLikedSheet extends ConsumerStatefulWidget {
  const _AddToLikedSheet({required this.ref});
  final WidgetRef ref;

  @override
  ConsumerState<_AddToLikedSheet> createState() => _AddToLikedSheetState();
}

class _AddToLikedSheetState extends ConsumerState<_AddToLikedSheet> {
  final _searchCtrl = TextEditingController();
  List<Song> _results = [];
  bool _searching = false;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _search(String q) async {
    if (q.trim().isEmpty) { setState(() { _results = []; _searching = false; }); return; }
    setState(() => _searching = true);
    try {
      final r = await ref.read(playerProvider.notifier).searchSongs(q.trim());
      if (mounted) setState(() { _results = r; _searching = false; });
    } catch (_) {
      if (mounted) setState(() { _results = []; _searching = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final recent = ref.watch(recentlyPlayedProvider);
    final likedIds = ref.watch(libraryProvider.select(
        (s) => s.likedSongs.map((e) => e.id).toSet()));
    final showRecent = _searchCtrl.text.trim().isEmpty;
    final list = showRecent ? recent : _results;

    return Column(mainAxisSize: MainAxisSize.max, children: [
      GestureDetector(
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
        behavior: HitTestBehavior.translucent,
        child: Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: kSheetHorizontalPadding, vertical: AppSpacing.base),
          child: AppInputField(
            controller: _searchCtrl,
            hintText: 'Search YouTube Music',
            style: InputFieldStyle.filled,
            prefixIcon: AppIcon(icon: AppIcons.search, color: AppColors.textMuted, size: 20),
            suffixIcon: _searchCtrl.text.trim().isNotEmpty
                ? AppIconButton(
                    icon: AppIcon(icon: AppIcons.clear, size: 24, color: AppColors.textMuted),
                    onPressed: () { _searchCtrl.clear(); setState(() => _results = []); },
                    size: 40, iconSize: 24)
                : null,
            onChanged: (v) {
              setState(() {});
              _debounce?.cancel();
              _debounce = Timer(const Duration(milliseconds: 350),
                  () { if (mounted) _search(_searchCtrl.text); });
            },
            onSubmitted: _search,
          ),
        ),
      ),
      if (showRecent)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: kSheetHorizontalPadding),
          child: Align(alignment: Alignment.centerLeft,
              child: Text('Recently played', style: TextStyle(
                  color: AppColors.textMuted, fontSize: AppFontSize.sm,
                  fontWeight: FontWeight.w600))),
        ),
      const SizedBox(height: AppSpacing.sm),
      Expanded(child: _searching
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : list.isEmpty
              ? Center(child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: Text(
                    showRecent ? 'No recently played songs' : 'No results',
                    style: const TextStyle(color: AppColors.textMuted),
                    textAlign: TextAlign.center)))
              : ListView.builder(
                  itemCount: list.length,
                  itemBuilder: (context, i) {
                    final song = list[i];
                    final isLiked = likedIds.contains(song.id);
                    final isNowPlaying = ref.watch(currentSongProvider)?.id == song.id;
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: kSheetHorizontalPadding, vertical: 8),
                      leading: NowPlayingThumbnail(
                        isPlaying: isNowPlaying,
                        isActuallyPlaying: ref.watch(isPlayingProvider),
                        size: 48,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(AppRadius.xs),
                          child: CachedNetworkImage(imageUrl: song.thumbnailUrl,
                              width: 48, height: 48, fit: BoxFit.cover,
                              errorWidget: (_, __, ___) =>
                                  AppIcon(icon: AppIcons.musicNote, color: AppColors.textMuted, size: 28)),
                        ),
                      ),
                      title: Text(song.title, maxLines: 1, overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: isNowPlaying ? AppColors.accent : AppColors.textPrimary)),
                      subtitle: Text(song.artist, maxLines: 1, overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: AppColors.textMuted, fontSize: AppFontSize.sm)),
                      trailing: AppIconButton(
                        icon: AppIcon(
                          icon: isLiked ? AppIcons.checkCircle : AppIcons.addCircleOutline,
                          color: isLiked ? AppColors.primary : AppColors.textSecondary,
                          size: 24),
                        onPressed: () => ref.read(libraryProvider.notifier).toggleLiked(song),
                      ),
                    );
                  }),
      ),
    ]);
  }
}
