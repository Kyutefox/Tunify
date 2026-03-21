import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/song.dart';
import '../../shared/providers/content_settings_provider.dart';
import '../../shared/providers/home_state_provider.dart';
import '../../shared/providers/player_state_provider.dart';
import '../../shared/providers/recent_search_provider.dart';
import '../../shared/providers/search_provider.dart';
import 'player/song_options_sheet.dart';

import '../components/shared/components_shared.dart';
import '../components/ui/button.dart';
import '../components/ui/widgets/mini_player.dart';
import '../components/ui/widgets/mood_browse_sheet.dart';
import '../components/ui/widgets/song_list_tile.dart';
import '../layout/shell_context.dart';
import '../../config/app_icons.dart';
import '../theme/app_colors.dart';
import '../theme/design_tokens.dart';

class Debouncer {
  final Duration delay;
  VoidCallback? _action;
  bool _disposed = false;
  Timer? _timer;

  Debouncer(this.delay);

  void run(VoidCallback action) {
    _action = action;
    _timer?.cancel();
    _timer = Timer(delay, () {
      if (!_disposed) _action?.call();
    });
  }

  void dispose() {
    _timer?.cancel();
    _disposed = true;
  }
}

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
                        fontSize: 16,
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
                        fontSize: 13,
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

  Future<void> _fetchSuggestions(String query) async {
    if (query.isEmpty) {
      if (mounted) {
        setState(() {
          _suggestions = [];
          _suggestionsForQuery = '';
        });
      }
      return;
    }
    final forQuery = query;
    if (mounted) {
      setState(() {
        _suggestionsForQuery = forQuery;
      });
    }
    try {
      final list = await ref.read(streamManagerProvider).getSearchSuggestions(forQuery);
      if (mounted && _suggestionsForQuery == forQuery) {
        setState(() {
          _suggestions = list;
        });
      }
    } catch (_) {
      if (mounted && _suggestionsForQuery == forQuery) {
        setState(() {
          _suggestions = [];
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
        });
      },
      hintText: 'Search songs, artists, and more',
      autofocus: true,
      body: SearchResultsBody(
        onOpenPlayer: _openPlayer,
        inlineSuggestions: _suggestions.take(4).toList(),
        inlineSuggestionsForQuery: _suggestionsForQuery,
        onSuggestionTap: _onSuggestionTap,
        onRecentQueryTap: (q) {
          _controller.text = q;
          ref.read(searchProvider.notifier).search(q);
          setState(() {
            _suggestions = [];
            _suggestionsForQuery = '';
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
    required this.emptyStateIcon,
    required this.emptyStateHeading,
    required this.emptyStateSubheading,
  });

  final void Function(Song song) onOpenPlayer;
  final void Function(String query)? onRecentQueryTap;
  final List<String> inlineSuggestions;
  final String inlineSuggestionsForQuery;
  final void Function(String)? onSuggestionTap;
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

    final suggestionCount = showInlineSuggestions ? inlineSuggestions.length : 0;
    final contentCount = state.isLoading ? 8 : displayResults.length;
    final totalCount = suggestionCount + contentCount;
    final hasContent = state.isLoading || hasResults;

    if (!hasContent) {
      return const Center(
        child: Text(
          'No results found',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
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
                          fontSize: 14,
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
                  fontSize: 13,
                ),
              ),
              AppIconButton(
                icon: AppIcon(
                  icon: AppIcons.moreVert,
                  color: AppColors.textMuted,
                  size: 20,
                ),
                onPressedWithContext: (btnCtx) =>
                    showSongOptionsSheet(context, song: song, ref: ref, buttonContext: btnCtx),
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
        MaterialPageRoute<void>(
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
                    letterSpacing: -0.3,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () =>
                    ref.read(recentSearchProvider.notifier).clearAll(),
                child: ShaderMask(
                  shaderCallback: (bounds) =>
                      AppColors.primaryGradient.createShader(bounds),
                  child: const Text(
                    'Clear',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
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
                        fontSize: 14,
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
    return ListTile(
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
    ).animate(onPlay: (c) => c.repeat()).shimmer(
          duration: const Duration(milliseconds: 1400),
          color: AppColors.surfaceHighlight,
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
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.6,
                      ),
                    ),
                  ),
                  _SearchBarPlaceholder(
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
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
