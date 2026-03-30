import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tunify/data/models/playlist.dart';
import 'package:tunify/data/models/song.dart';
import 'package:tunify/features/settings/connectivity_provider.dart';
import 'package:tunify/features/settings/content_settings_provider.dart';
import 'package:tunify/features/home/home_state_provider.dart';
import 'package:tunify/features/player/player_state_provider.dart';
import 'package:tunify/features/search/recent_search_provider.dart';
import 'package:tunify/features/search/search_provider.dart';
import 'package:tunify/core/utils/debouncer.dart';
import 'package:tunify/ui/screens/shared/library/library_playlist_screen.dart';
import 'package:tunify/ui/screens/shared/player/song_options_sheet.dart';

import 'package:tunify/ui/widgets/common/mood_section.dart';
import 'package:tunify/ui/widgets/common/recently_played_section.dart';
import 'package:tunify/ui/screens/shared/search/search_page.dart';
import 'package:tunify/ui/widgets/common/button.dart';
import 'package:tunify/ui/widgets/player/mini_player.dart';
import 'package:tunify/ui/widgets/player/mood_browse_sheet.dart';
import 'package:tunify/ui/widgets/library/song_list_tile.dart';
import 'package:tunify/ui/shell/shell_context.dart';
import 'package:tunify/core/constants/app_icons.dart';
import 'package:tunify/ui/theme/app_colors.dart';
import 'package:tunify/ui/theme/design_tokens.dart';
import 'package:tunify/ui/theme/desktop_tokens.dart';
import 'package:tunify/ui/theme/app_routes.dart';
import 'package:tunify/ui/theme/app_colors_scheme.dart';

class _SearchBarPlaceholder extends ConsumerWidget {
  const _SearchBarPlaceholder({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // PERF: Removed ref.watch(moodsProvider) — moods are only needed inside
    // the tap callback. ref.read() is called at tap time so this widget is no
    // longer subscribed to mood list changes.
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: AppColorsScheme.of(context).surfaceLight,
        borderRadius: BorderRadius.circular(AppRadius.input),
        border: Border.all(color: Colors.transparent, width: 1),
      ),
      child: Row(
        children: [
          // Search tap area
          Expanded(
            child: GestureDetector(
              onTap: onTap,
              behavior: HitTestBehavior.opaque,
              child: Row(
                children: [
                  const SizedBox(width: AppSpacing.base),
                  AppIcon(
                    icon: AppIcons.search,
                    color: AppColorsScheme.of(context).textMuted,
                    size: 22,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      'Search songs, artists, and more',
                      style: TextStyle(
                        color: AppColorsScheme.of(context).textMuted.withValues(alpha: 0.7),
                        fontSize: AppFontSize.xl,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Divider + Browse — desktop only
          if (ShellContext.isDesktopOf(context)) ...[
            Container(
              width: 1,
              height: 22,
              color: AppColorsScheme.of(context).textMuted.withValues(alpha: 0.3),
            ),
            GestureDetector(
              onTap: () => showMoodBrowseSheet(context, moods: ref.read(moodsProvider)),
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AppIcon(
                      icon: AppIcons.gridView,
                      color: AppColorsScheme.of(context).textSecondary,
                      size: 18,
                    ),
                    const SizedBox(width: AppSpacing.xs + 2),
                    Text(
                      'Browse',
                      style: TextStyle(
                        color: AppColorsScheme.of(context).textSecondary,
                        fontSize: AppFontSize.md,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ] else
            const SizedBox(width: AppSpacing.md),
        ],
      ),
    );
  }
}

class _FullSearchScreen extends ConsumerStatefulWidget {
  const _FullSearchScreen({this.initialQuery});

  final String? initialQuery;

  @override
  ConsumerState<_FullSearchScreen> createState() => _FullSearchScreenState();
}

class _FullSearchScreenState extends ConsumerState<_FullSearchScreen> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;
  late final Debouncer _debouncer;
  late final Debouncer _suggestionsDebouncer;

  List<String> _suggestions = [];
  String _suggestionsForQuery = '';

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _focusNode = FocusNode();
    _debouncer = Debouncer(const Duration(milliseconds: 280));
    _suggestionsDebouncer = Debouncer(const Duration(milliseconds: 220));
    _controller.addListener(_onControllerChanged);
    final initial = widget.initialQuery?.trim();
    if (initial != null && initial.isNotEmpty) {
      _controller.text = initial;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) ref.read(searchProvider.notifier).search(initial);
      });
    } else {
      ref.read(searchProvider.notifier).search('');
    }
  }

  bool _isOffline = false;

  Future<void> _fetchSuggestions(String query) async {
    if (query.isEmpty) {
      if (mounted) {
        setState(() {
          _suggestions = [];
          _suggestionsForQuery = '';
          _isOffline = false;
        });
      }
      return;
    }
    final forQuery = query;
    if (mounted) {
      setState(() {
        _suggestionsForQuery = forQuery;
        _isOffline = false;
      });
    }
    try {
      final list =
          await ref.read(streamManagerProvider).getSearchSuggestions(forQuery);
      if (mounted && _suggestionsForQuery == forQuery) {
        setState(() {
          _suggestions = list;
          _isOffline = false;
        });
      }
    } catch (_) {
      if (mounted && _suggestionsForQuery == forQuery) {
        final isOnline = ref.read(connectivityProvider).value ?? true;
        setState(() {
          _suggestions = [];
          _isOffline = !isOnline;
        });
      }
    }
  }

  void _onControllerChanged() {
    final query = _controller.text.trim();
    _suggestionsDebouncer.run(() {
      if (mounted) _fetchSuggestions(query);
    });
    _debouncer.run(() {
      if (!mounted) return;
      final currentQuery = ref.read(searchProvider).query;
      if (query != currentQuery) {
        ref.read(searchProvider.notifier).search(query);
      }
    });
    if (mounted) setState(() {});
  }

  void _onSuggestionTap(String suggestion) {
    _controller.text = suggestion;
    setState(() {
      _suggestions = [];
      _suggestionsForQuery = '';
    });
    ref.read(searchProvider.notifier).search(suggestion);
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChanged);
    _controller.dispose();
    _focusNode.dispose();
    _debouncer.dispose();
    _suggestionsDebouncer.dispose();
    super.dispose();
  }

  void _openPlayer(Song song) {
    ref.read(playerProvider.notifier).playSong(song, queueSource: 'autoqueue');
  }

  @override
  Widget build(BuildContext context) {
    final hasSong = ref.watch(currentSongProvider) != null;
    final searchPage = SharedSearchPage(
      controller: _controller,
      focusNode: _focusNode,
      onBack: () => Navigator.of(context).pop(),
      onClear: () {
        ref.read(searchProvider.notifier).search('');
        setState(() {
          _suggestions = [];
          _suggestionsForQuery = '';
          _isOffline = false;
        });
      },
      hintText: 'Search songs, artists, and more',
      autofocus: true,
      body: SearchResultsBody(
        onOpenPlayer: _openPlayer,
        inlineSuggestions: _suggestions.take(4).toList(),
        inlineSuggestionsForQuery: _suggestionsForQuery,
        onSuggestionTap: _onSuggestionTap,
        isOffline: _isOffline,
        onRecentQueryTap: (q) {
          _controller.text = q;
          ref.read(searchProvider.notifier).search(q);
          setState(() {
            _suggestions = [];
            _suggestionsForQuery = '';
            _isOffline = false;
          });
        },
        emptyStateIcon: AppIcon(
          icon: AppIcons.search,
          size: 64,
          color: AppColorsScheme.of(context).textMuted,
        ),
        emptyStateHeading: 'Play what you love',
        emptyStateSubheading: 'Search artist, songs, and more',
      ),
    );
    if (!hasSong) return searchPage;
    return Scaffold(
      backgroundColor: AppColorsScheme.of(context).background,
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(child: searchPage),
            const MiniPlayer(key: ValueKey('search-mini-player')),
            SizedBox(height: MediaQuery.of(context).viewPadding.bottom),
          ],
        ),
      ),
    );
  }
}

class SearchResultsBody extends ConsumerWidget {
  const SearchResultsBody({
    super.key,
    required this.onOpenPlayer,
    this.onRecentQueryTap,
    this.inlineSuggestions = const [],
    this.inlineSuggestionsForQuery = '',
    this.onSuggestionTap,
    this.isOffline = false,
    required this.emptyStateIcon,
    required this.emptyStateHeading,
    required this.emptyStateSubheading,
  });

  final void Function(Song song) onOpenPlayer;
  final void Function(String query)? onRecentQueryTap;
  final List<String> inlineSuggestions;
  final String inlineSuggestionsForQuery;
  final void Function(String)? onSuggestionTap;
  final bool isOffline;
  final Widget emptyStateIcon;
  final String emptyStateHeading;
  final String emptyStateSubheading;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(searchProvider);
    final showExplicit = ref.watch(showExplicitContentProvider);
    final isSearching = state.query.isNotEmpty;
    final showInlineSuggestions = isSearching &&
        inlineSuggestionsForQuery == state.query &&
        inlineSuggestions.isNotEmpty;

    if (!isSearching) {
      return AnimatedSwitcher(
        duration: AppDuration.normal,
        switchInCurve: AppCurves.decelerate,
        switchOutCurve: AppCurves.decelerate,
        layoutBuilder: (currentChild, previousChildren) {
          return Stack(
            alignment: Alignment.topCenter,
            children: [
              ...previousChildren,
              if (currentChild != null) currentChild,
            ],
          );
        },
        child: Column(
          key: const ValueKey('initial'),
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            RecentSearchSection(
              compact: true,
              onQueryTap: onRecentQueryTap,
            ),
            Expanded(
              child: SearchPageEmptyState(
                icon: emptyStateIcon,
                heading: emptyStateHeading,
                subheading: emptyStateSubheading,
              ),
            ),
          ],
        ),
      );
    }

    final filter = state.filter;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Filter tab bar — always show once user has typed a query ──
        if (isSearching)
          _SearchFilterBar(
            selected: filter,
            onSelect: (f) => ref.read(searchProvider.notifier).setFilter(f),
          ),
        if (isOffline && !state.isLoading)
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xl, vertical: AppSpacing.sm),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AppIcon(
                    icon: AppIcons.wifiOff,
                    color: AppColorsScheme.of(context).textMuted,
                    size: 16),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  "You're offline — suggestions unavailable",
                  style: TextStyle(
                      color: AppColorsScheme.of(context).textMuted,
                      fontSize: AppFontSize.sm),
                ),
              ],
            ),
          ),
        // ── Results list ──
        Expanded(
          child: AnimatedSwitcher(
            duration: AppDuration.fast,
            child: _buildResultsForFilter(
              context: context,
              ref: ref,
              state: state,
              filter: filter,
              showExplicit: showExplicit,
              showInlineSuggestions: showInlineSuggestions,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildResultsForFilter({
    required BuildContext context,
    required WidgetRef ref,
    required SearchState state,
    required SearchFilter filter,
    required bool showExplicit,
    required bool showInlineSuggestions,
  }) {
    if (state.isLoading) {
      return ListView.builder(
        key: const ValueKey('loading'),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
        itemCount: 8,
        itemBuilder: (_, __) => const _SkeletonResultTile(),
      );
    }

    switch (filter) {
      case SearchFilter.artists:
        if (state.artistResults.isEmpty) return _emptyFilterState(context, 'No artists found');
        return _PaginatedList(
          listKey: const ValueKey('artists'),
          isLoadingMore: state.isLoadingMore,
          hasMore: state.continuationFor(SearchFilter.artists) != null,
          onLoadMore: () => ref.read(searchProvider.notifier).loadMore(),
          itemCount: state.artistResults.length,
          itemBuilder: (_, i) => _ArtistResultTile(artist: state.artistResults[i]),
        );

      case SearchFilter.albums:
        if (state.albumResults.isEmpty) return _emptyFilterState(context, 'No albums found');
        return _PaginatedList(
          listKey: const ValueKey('albums'),
          isLoadingMore: state.isLoadingMore,
          hasMore: state.continuationFor(SearchFilter.albums) != null,
          onLoadMore: () => ref.read(searchProvider.notifier).loadMore(),
          itemCount: state.albumResults.length,
          itemBuilder: (_, i) => _AlbumResultTile(album: state.albumResults[i]),
        );

      case SearchFilter.videos:
        final videos = filterByExplicitSetting(state.videoResults, showExplicit);
        if (videos.isEmpty) return _emptyFilterState(context, 'No videos found');
        return _PaginatedList(
          listKey: const ValueKey('videos'),
          isLoadingMore: state.isLoadingMore,
          hasMore: state.continuationFor(SearchFilter.videos) != null,
          onLoadMore: () => ref.read(searchProvider.notifier).loadMore(),
          itemCount: videos.length,
          itemBuilder: (_, i) {
            final song = videos[i];
            return RepaintBoundary(
              child: SongListTile(
                song: song,
                thumbnailSize: 54,
                onTap: () => onOpenPlayer(song),
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
                      onPressedWithContext: (btnCtx) => showSongOptionsSheet(
                          context, song: song, ref: ref, buttonContext: btnCtx),
                      iconSize: 20,
                      size: 40,
                      iconAlignment: Alignment.centerRight,
                    ),
                  ],
                ),
              ),
            );
          },
        );

      case SearchFilter.communityPlaylists:
        if (state.playlistResults.isEmpty) return _emptyFilterState(context, 'No playlists found');
        return _PaginatedList(
          listKey: const ValueKey('playlists'),
          isLoadingMore: state.isLoadingMore,
          hasMore: state.continuationFor(SearchFilter.communityPlaylists) != null,
          onLoadMore: () => ref.read(searchProvider.notifier).loadMore(),
          itemCount: state.playlistResults.length,
          itemBuilder: (_, i) => _PlaylistResultTile(playlist: state.playlistResults[i]),
        );

      case SearchFilter.featuredPlaylists:
        if (state.featuredPlaylistResults.isEmpty) return _emptyFilterState(context, 'No featured playlists found');
        return _PaginatedList(
          listKey: const ValueKey('featuredPlaylists'),
          isLoadingMore: state.isLoadingMore,
          hasMore: state.continuationFor(SearchFilter.featuredPlaylists) != null,
          onLoadMore: () => ref.read(searchProvider.notifier).loadMore(),
          itemCount: state.featuredPlaylistResults.length,
          itemBuilder: (_, i) => _PlaylistResultTile(playlist: state.featuredPlaylistResults[i]),
        );

      case SearchFilter.profiles:
        if (state.profileResults.isEmpty) return _emptyFilterState(context, 'No profiles found');
        return _PaginatedList(
          listKey: const ValueKey('profiles'),
          isLoadingMore: state.isLoadingMore,
          hasMore: state.continuationFor(SearchFilter.profiles) != null,
          onLoadMore: () => ref.read(searchProvider.notifier).loadMore(),
          itemCount: state.profileResults.length,
          itemBuilder: (_, i) => _ArtistResultTile(artist: state.profileResults[i]),
        );

      case SearchFilter.all:
      case SearchFilter.songs:
        final displayResults = filterByExplicitSetting(state.songResults, showExplicit);
        final suggestionCount = showInlineSuggestions ? inlineSuggestions.length : 0;
        final totalCount = suggestionCount + displayResults.length;
        if (totalCount == 0) return _emptyFilterState(context, 'No results found');
        return _PaginatedList(
          listKey: ValueKey('songs_${state.query}'),
          isLoadingMore: state.isLoadingMore,
          hasMore: state.continuationFor(filter) != null,
          onLoadMore: () => ref.read(searchProvider.notifier).loadMore(),
          itemCount: totalCount,
          itemBuilder: (context, index) {
            if (index < suggestionCount) {
              final s = inlineSuggestions[index];
              return RepaintBoundary(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => onSuggestionTap?.call(s),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.base,
                        vertical: AppSpacing.md,
                      ),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 54,
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: AppIcon(
                                icon: AppIcons.search,
                                color: AppColorsScheme.of(context).textMuted,
                                size: 20,
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Text(
                              s,
                              style: TextStyle(
                                color: AppColorsScheme.of(context).textPrimary,
                                fontSize: AppFontSize.base,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          AppIcon(
                            icon: AppIcons.arrowUpLeft,
                            color: AppColorsScheme.of(context).textMuted,
                            size: 18,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }
            final song = displayResults[index - suggestionCount];
            return RepaintBoundary(
              child: SongListTile(
                song: song,
                thumbnailSize: 54,
                onTap: () => onOpenPlayer(song),
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
                      onPressedWithContext: (btnCtx) => showSongOptionsSheet(
                          context,
                          song: song,
                          ref: ref,
                          buttonContext: btnCtx),
                      iconSize: 20,
                      size: 40,
                      iconAlignment: Alignment.centerRight,
                    ),
                  ],
                ),
              ),
            );
          },
        );
    }
  }

  Widget _emptyFilterState(BuildContext context, String message) => Center(
        key: ValueKey(message),
        child: Text(
          message,
          style: TextStyle(
            color: AppColorsScheme.of(context).textSecondary,
            fontSize: AppFontSize.lg,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
}

class _SearchMoodGrid extends ConsumerWidget {
  const _SearchMoodGrid();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(bottom: AppSpacing.max),
      children: [
        const RecentSearchSection(),
        RecentlyPlayedSection(
          onPlay: (song) => ref
              .read(playerProvider.notifier)
              .playSong(song, queueSource: 'autoqueue'),
        ),
        const MoodSection(showAll: true),
      ],
    );
  }
}

class RecentSearchSection extends ConsumerWidget {
  const RecentSearchSection({
    super.key,
    this.compact = false,
    this.onQueryTap,
  });

  final bool compact;
  final void Function(String query)? onQueryTap;

  void _onChipTap(BuildContext context, String query) {
    if (onQueryTap != null) {
      onQueryTap!(query);
    } else {
      Navigator.of(context).push(
        appPageRoute<void>(
          builder: (_) => _FullSearchScreen(initialQuery: query),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recent = ref.watch(recentSearchProvider);
    if (recent.isEmpty) return const SizedBox(height: AppSpacing.sm);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: AppSpacing.sm),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.base),
          child: Row(
            children: [
              AppIcon(
                icon: AppIcons.search,
                color: AppColorsScheme.of(context).textMuted,
                size: compact ? 18 : 20,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'Recent searches',
                  style: TextStyle(
                    color: AppColorsScheme.of(context).textPrimary,
                    fontSize: compact ? 16 : 20,
                    fontWeight: FontWeight.w700,
                    letterSpacing: AppLetterSpacing.heading,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () => ref.read(recentSearchProvider.notifier).clearAll(),
                child: ShaderMask(
                  shaderCallback: (bounds) =>
                      AppColors.primaryGradient.createShader(bounds),
                  child: const Text(
                    'Clear',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: AppFontSize.md,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        SizedBox(
          height: compact ? 36 : 40,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.base),
            itemCount: recent.length,
            separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
            itemBuilder: (_, i) {
              final query = recent[i];
              return Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _onChipTap(context, query),
                  borderRadius: BorderRadius.circular(AppRadius.xl),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                    decoration: BoxDecoration(
                      color: AppColorsScheme.of(context).surfaceLight.withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(AppRadius.xl),
                      border: Border.all(
                        color: AppColorsScheme.of(context).textMuted.withValues(alpha: 0.2),
                        width: 1,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      query,
                      style: TextStyle(
                        color: AppColorsScheme.of(context).textPrimary,
                        fontSize: AppFontSize.base,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        SizedBox(height: compact ? AppSpacing.md : AppSpacing.xxl),
      ],
    );
  }
}

class _SearchFilterBar extends StatelessWidget {
  const _SearchFilterBar({
    required this.selected,
    required this.onSelect,
  });

  final SearchFilter selected;
  final void Function(SearchFilter) onSelect;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.base,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final f in SearchFilter.values)
            Padding(
              padding: EdgeInsets.only(
                right: f != SearchFilter.values.last ? AppSpacing.sm : 0,
              ),
              child: _SearchFilterChip(
                label: switch (f) {
                  SearchFilter.all => 'All',
                  SearchFilter.songs => 'Songs',
                  SearchFilter.videos => 'Videos',
                  SearchFilter.albums => 'Albums',
                  SearchFilter.artists => 'Artists',
                  SearchFilter.communityPlaylists => 'Community playlists',
                  SearchFilter.featuredPlaylists => 'Featured playlists',
                  SearchFilter.profiles => 'Profiles',
                },
                selected: f == selected,
                onTap: () => onSelect(f),
              ),
            ),
        ],
      ),
    );
  }
}

class _SearchFilterChip extends StatefulWidget {
  const _SearchFilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<_SearchFilterChip> createState() => _SearchFilterChipState();
}

class _SearchFilterChipState extends State<_SearchFilterChip>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: AppDuration.fast,
    value: widget.selected ? 1.0 : 0.0,
  );
  late final Animation<double> _t = CurvedAnimation(
    parent: _ctrl,
    curve: AppCurves.decelerate,
    reverseCurve: AppCurves.standard,
  );

  @override
  void didUpdateWidget(_SearchFilterChip old) {
    super.didUpdateWidget(old);
    if (widget.selected != old.selected) {
      widget.selected ? _ctrl.forward() : _ctrl.reverse();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppTokens.of(context);
    return AnimatedBuilder(
      animation: _t,
      builder: (context, _) {
        final tv = _t.value;
        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(AppRadius.sm),
            child: Container(
              height: t.isDesktop ? 36 : 32,
              padding: EdgeInsets.symmetric(horizontal: t.isDesktop ? t.spacing.md : AppSpacing.md),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Color.lerp(
                  AppColorsScheme.of(context).surfaceLight.withValues(alpha: 0.8),
                  AppColors.primary.withValues(alpha: 0.2),
                  tv,
                ),
                borderRadius: BorderRadius.circular(AppRadius.sm),
                border: Border.all(
                  color: Color.lerp(Colors.transparent, AppColors.primary, tv)!,
                  width: 1,
                ),
              ),
              child: Text(
                widget.label,
                style: TextStyle(
                  color: Color.lerp(AppColorsScheme.of(context).textSecondary, AppColors.primary, tv),
                  fontSize: t.font.md,
                  fontWeight: tv > 0.5 ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ArtistResultTile extends StatelessWidget {
  const _ArtistResultTile({required this.artist});

  final ArtistSearchResult artist;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          appPageRoute<void>(
            builder: (_) => LibraryPlaylistScreen.artist(
              artistName: artist.name,
              thumbnailUrl: artist.thumbnailUrl,
              browseId: artist.browseId,
            ),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.base,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            children: [
              ClipOval(
                child: Image.network(
                  artist.thumbnailUrl,
                  width: 54,
                  height: 54,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 54,
                    height: 54,
                    color: AppColorsScheme.of(context).surfaceLight,
                    child: AppIcon(
                      icon: AppIcons.person,
                      color: AppColorsScheme.of(context).textMuted,
                      size: 28,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      artist.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColorsScheme.of(context).textPrimary,
                        fontSize: AppFontSize.base,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Artist',
                      style: TextStyle(
                        color: AppColorsScheme.of(context).textMuted,
                        fontSize: AppFontSize.sm,
                        fontWeight: FontWeight.w400,
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

class _AlbumResultTile extends StatelessWidget {
  const _AlbumResultTile({required this.album});

  final AlbumSearchResult album;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          appPageRoute<void>(
            builder: (_) => LibraryPlaylistScreen.album(
              songTitle: album.name,
              name: album.name,
              artistName: album.artist,
              thumbnailUrl: album.thumbnailUrl,
              browseId: album.browseId,
            ),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.base,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.sm),
                child: Image.network(
                  album.thumbnailUrl,
                  width: 54,
                  height: 54,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 54,
                    height: 54,
                    color: AppColorsScheme.of(context).surfaceLight,
                    child: AppIcon(
                      icon: AppIcons.musicNote,
                      color: AppColorsScheme.of(context).textMuted,
                      size: 28,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      album.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColorsScheme.of(context).textPrimary,
                        fontSize: AppFontSize.base,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      album.artist,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColorsScheme.of(context).textMuted,
                        fontSize: AppFontSize.sm,
                        fontWeight: FontWeight.w400,
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

class _PlaylistResultTile extends StatelessWidget {
  const _PlaylistResultTile({required this.playlist});

  final PlaylistSearchResult playlist;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          if (playlist.browseId == null) return;
          Navigator.of(context).push(
            appPageRoute<void>(
              builder: (_) => LibraryPlaylistScreen.remote(
                playlist: Playlist(
                  id: playlist.browseId!,
                  title: playlist.title,
                  description: playlist.author,
                  coverUrl: playlist.thumbnailUrl,
                ),
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.base,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.sm),
                child: Image.network(
                  playlist.thumbnailUrl,
                  width: 54,
                  height: 54,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 54,
                    height: 54,
                    color: AppColorsScheme.of(context).surfaceLight,
                    child: AppIcon(
                      icon: AppIcons.playlist,
                      color: AppColorsScheme.of(context).textMuted,
                      size: 28,
                    ),
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
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColorsScheme.of(context).textPrimary,
                        fontSize: AppFontSize.base,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      [
                        if (playlist.author.isNotEmpty) playlist.author,
                        if (playlist.songCount != null) playlist.songCount!,
                      ].join(' • '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColorsScheme.of(context).textMuted,
                        fontSize: AppFontSize.sm,
                        fontWeight: FontWeight.w400,
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

/// A ListView that fires [onLoadMore] when the user scrolls within 200px of
/// the bottom, and appends a loading spinner when [isLoadingMore] is true.
class _PaginatedList extends StatelessWidget {
  const _PaginatedList({
    required this.listKey,
    required this.itemCount,
    required this.itemBuilder,
    required this.isLoadingMore,
    required this.hasMore,
    required this.onLoadMore,
  });

  final Key listKey;
  final int itemCount;
  final Widget Function(BuildContext, int) itemBuilder;
  final bool isLoadingMore;
  final bool hasMore;
  final VoidCallback onLoadMore;

  @override
  Widget build(BuildContext context) {
    // +1 for the footer (spinner or end-of-list spacer)
    final footerIndex = itemCount;
    final totalCount = itemCount + 1;

    return NotificationListener<ScrollNotification>(
      onNotification: (n) {
        if (hasMore &&
            !isLoadingMore &&
            n is ScrollUpdateNotification &&
            n.metrics.pixels >= n.metrics.maxScrollExtent - 200) {
          onLoadMore();
        }
        return false;
      },
      child: ListView.builder(
        key: listKey,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.only(bottom: AppSpacing.max),
        itemCount: totalCount,
        itemBuilder: (ctx, i) {
          if (i == footerIndex) {
            if (isLoadingMore) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                child: Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColorsScheme.of(ctx).textMuted,
                    ),
                  ),
                ),
              );
            }
            return const SizedBox(height: AppSpacing.lg);
          }
          return itemBuilder(ctx, i);
        },
      ),
    );
  }
}

class _SkeletonResultTile extends StatelessWidget {
  const _SkeletonResultTile();

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColorsScheme.of(context).surfaceLight,
      highlightColor: AppColorsScheme.of(context).surfaceHighlight,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.base,
          vertical: AppSpacing.xs,
        ),
        leading: Container(
          width: 54,
          height: 54,
          decoration: BoxDecoration(
            color: AppColorsScheme.of(context).surfaceLight,
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
        ),
        title: Container(
          height: 13,
          margin: const EdgeInsets.only(right: 60),
          decoration: BoxDecoration(
            color: AppColorsScheme.of(context).surfaceLight,
            borderRadius: BorderRadius.circular(AppRadius.xs),
          ),
        ),
        subtitle: Container(
          height: 11,
          width: 80,
          margin: const EdgeInsets.only(top: 6),
          decoration: BoxDecoration(
            color: AppColorsScheme.of(context).surface,
            borderRadius: BorderRadius.circular(AppRadius.xs),
          ),
        ),
      ),
    );
  }
}

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColorsScheme.of(context).background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.base,
                AppSpacing.md,
                AppSpacing.base,
                AppSpacing.base,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: EdgeInsets.only(bottom: AppSpacing.md),
                    child: Text(
                      'Search',
                      style: TextStyle(
                        color: AppColorsScheme.of(context).textPrimary,
                        fontSize: AppFontSize.display3,
                        fontWeight: FontWeight.w800,
                        letterSpacing: AppLetterSpacing.display,
                      ),
                    ),
                  ),
                  _SearchBarPlaceholder(
                    onTap: () => Navigator.of(context).push(
                      appPageRoute<void>(
                        builder: (_) => const _FullSearchScreen(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Expanded(child: _SearchMoodGrid()),
          ],
        ),
      ),
    );
  }
}
