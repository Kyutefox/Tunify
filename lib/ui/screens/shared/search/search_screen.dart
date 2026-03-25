import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tunify/data/models/song.dart';
import 'package:tunify/features/settings/connectivity_provider.dart';
import 'package:tunify/features/settings/content_settings_provider.dart';
import 'package:tunify/features/home/home_state_provider.dart';
import 'package:tunify/features/player/player_state_provider.dart';
import 'package:tunify/features/search/recent_search_provider.dart';
import 'package:tunify/features/search/search_provider.dart';
import 'package:tunify/core/utils/debouncer.dart';
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
import 'package:tunify/ui/theme/app_routes.dart';

class _SearchBarPlaceholder extends ConsumerWidget {
  const _SearchBarPlaceholder({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final moods = ref.watch(moodsProvider);
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
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
                    color: AppColors.textMuted,
                    size: 22,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      'Search songs, artists, and more',
                      style: TextStyle(
                        color: AppColors.textMuted.withValues(alpha: 0.7),
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
              color: AppColors.textMuted.withValues(alpha: 0.3),
            ),
            GestureDetector(
              onTap: () => showMoodBrowseSheet(context, moods: moods),
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AppIcon(
                      icon: AppIcons.gridView,
                      color: AppColors.textSecondary,
                      size: 18,
                    ),
                    const SizedBox(width: AppSpacing.xs + 2),
                    const Text(
                      'Browse',
                      style: TextStyle(
                        color: AppColors.textSecondary,
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
          color: AppColors.textMuted,
        ),
        emptyStateHeading: 'Play what you love',
        emptyStateSubheading: 'Search artist, songs, and more',
      ),
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
    final displayResults = filterByExplicitSetting(state.results, showExplicit);
    final isSearching = state.query.isNotEmpty;
    final hasResults = displayResults.isNotEmpty;
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

    final suggestionCount =
        showInlineSuggestions ? inlineSuggestions.length : 0;
    final contentCount = state.isLoading ? 8 : displayResults.length;
    final totalCount = suggestionCount + contentCount;
    final hasContent = state.isLoading || hasResults;

    if (!hasContent) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (isOffline)
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xl, vertical: AppSpacing.md),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AppIcon(
                      icon: AppIcons.wifiOff,
                      color: AppColors.textMuted,
                      size: 16),
                  const SizedBox(width: AppSpacing.xs),
                  const Text(
                    "You're offline — suggestions unavailable",
                    style: TextStyle(
                        color: AppColors.textMuted, fontSize: AppFontSize.sm),
                  ),
                ],
              ),
            ),
          const Expanded(
            child: Center(
              child: Text(
                'No results found',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: AppFontSize.lg,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      );
    }

    return ListView.builder(
      key: ValueKey('search_${state.query}_${suggestionCount}_$contentCount'),
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(
        left: AppSpacing.base,
        right: AppSpacing.base,
        bottom: AppSpacing.max,
      ),
      itemCount: totalCount,
      itemBuilder: (context, index) {
        if (index < suggestionCount) {
          final s = inlineSuggestions[index];
          return Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => onSuggestionTap?.call(s),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.base,
                  vertical: AppSpacing.xs,
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 54,
                      height: 54,
                      child: Center(
                        child: AppIcon(
                          icon: AppIcons.search,
                          color: AppColors.textMuted,
                          size: 24,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Text(
                        s,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: AppFontSize.base,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    AppIcon(
                      icon: AppIcons.arrowUpLeft,
                      color: AppColors.textMuted,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
          );
        }
        final resultIndex = index - suggestionCount;
        if (state.isLoading) {
          return const Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            child: _SkeletonResultTile(),
          );
        }
        final song = displayResults[resultIndex];
        return SongListTile(
          song: song,
          thumbnailSize: 54,
          onTap: () => onOpenPlayer(song),
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
                onPressedWithContext: (btnCtx) => showSongOptionsSheet(context,
                    song: song, ref: ref, buttonContext: btnCtx),
                iconSize: 20,
                size: 40,
              ),
            ],
          ),
        );
      },
    );
  }
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
                color: AppColors.textMuted,
                size: compact ? 18 : 20,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'Recent searches',
                  style: TextStyle(
                    color: AppColors.textPrimary,
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
                      color: AppColors.surfaceLight.withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(AppRadius.xl),
                      border: Border.all(
                        color: AppColors.textMuted.withValues(alpha: 0.2),
                        width: 1,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      query,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
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

class _SkeletonResultTile extends StatelessWidget {
  const _SkeletonResultTile();

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.surfaceLight,
      highlightColor: AppColors.surfaceHighlight,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.base,
          vertical: AppSpacing.xs,
        ),
        leading: Container(
          width: 54,
          height: 54,
          decoration: BoxDecoration(
            color: AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
        ),
        title: Container(
          height: 13,
          margin: const EdgeInsets.only(right: 60),
          decoration: BoxDecoration(
            color: AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(AppRadius.xs),
          ),
        ),
        subtitle: Container(
          height: 11,
          width: 80,
          margin: const EdgeInsets.only(top: 6),
          decoration: BoxDecoration(
            color: AppColors.surface,
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
      backgroundColor: AppColors.background,
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
                  const Padding(
                    padding: EdgeInsets.only(bottom: AppSpacing.md),
                    child: Text(
                      'Search',
                      style: TextStyle(
                        color: AppColors.textPrimary,
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
