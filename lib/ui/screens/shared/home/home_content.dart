import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tunify/core/constants/app_icons.dart';
import 'package:tunify/ui/widgets/common/mood_section.dart';
import 'package:tunify/ui/widgets/common/recently_played_section.dart';
import 'package:tunify/data/models/artist.dart';
import 'package:tunify/data/models/playlist.dart';
import 'package:tunify/data/models/song.dart';
import 'package:tunify/features/home/home_state_provider.dart';
import 'package:tunify/features/player/player_state_provider.dart';
import 'package:tunify/ui/shell/shell_context.dart';
import 'package:tunify/ui/widgets/common/section_header.dart';
import 'package:tunify/ui/theme/design_tokens.dart';
import 'package:tunify/ui/theme/desktop_tokens.dart';
import 'home_sections.dart';
import 'home_shared.dart';
import 'home_skeletons.dart';
import 'package:tunify/ui/theme/app_colors_scheme.dart';

class HomeContent extends ConsumerWidget {
  const HomeContent({super.key, required this.onPlay});
  final void Function(Song song) onPlay;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoading = ref.watch(homeIsLoadingProvider);
    final isLoaded = ref.watch(homeIsLoadedProvider);

    if (isLoading && !isLoaded) {
      return const SliverToBoxAdapter(child: HomePageSkeleton());
    }

    return SliverList(
      delegate: SliverChildListDelegate.fixed([
        RepaintBoundary(child: RecentlyPlayedSection(onPlay: onPlay)),
        RepaintBoundary(child: _AnimatedFeedBlock(onPlay: onPlay)),
        const RepaintBoundary(child: MoodSection()),
      ]),
    );
  }
}

/// Wraps Quick Picks + dynamic sections + Made For You + Artists in [AnimatedSwitcher]
/// keyed by [homeFeedVersionProvider] so background refetches fade in smoothly.
class _AnimatedFeedBlock extends ConsumerWidget {
  const _AnimatedFeedBlock({required this.onPlay});
  final void Function(Song song) onPlay;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feedVersion = ref.watch(homeFeedVersionProvider);
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      transitionBuilder: (child, animation) =>
          FadeTransition(opacity: animation, child: child),
      child: KeyedSubtree(
        key: ValueKey(feedVersion),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _QuickPicksSection(onPlay: onPlay),
            const RepaintBoundary(child: _DynamicSectionsSkeletonGate()),
            _DynamicSectionsSlice(onPlay: onPlay),
            const _MadeForYouSection(),
            const _ArtistsSection(),
          ],
        ),
      ),
    );
  }
}

// ─── Shared nav button pair ───────────────────────────────────────────────────

/// Prev/next arrow buttons used in every section header.
/// Extracted from the 3× duplicated inline Row in the original file.
class _NavButtonPair extends StatelessWidget {
  const _NavButtonPair({
    required this.pageCtrl,
    required this.currentPage,
    this.totalPages = 2,
  });
  final PageController pageCtrl;
  final int currentPage;
  final int totalPages;

  void _go(int page) => pageCtrl.animateToPage(
        page,
        duration: AppDuration.normal,
        curve: Curves.easeInOut,
      );

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _NavButton(
            icon: AppIcons.back,
            enabled: currentPage > 0,
            onTap: () => _go(currentPage - 1)),
        const SizedBox(width: AppSpacing.xs),
        _NavButton(
            icon: AppIcons.forward,
            enabled: currentPage < totalPages - 1,
            onTap: () => _go(currentPage + 1)),
      ],
    );
  }
}

/// Small circular prev/next arrow button.
class _NavButton extends StatelessWidget {
  const _NavButton(
      {required this.icon, required this.onTap, this.enabled = true});
  final List<List<dynamic>> icon;
  final VoidCallback onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final t = AppTokens.of(context);
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: t.spacing.xxl,
        height: t.spacing.xxl,
        decoration: BoxDecoration(
          color: enabled
              ? AppColorsScheme.of(context).surfaceLight
              : AppColorsScheme.of(context).surfaceLight.withValues(alpha: 0.4),
          shape: BoxShape.circle,
        ),
        child: Center(
          child: AppIcon(
            icon: icon,
            size: t.icon.xs,
            color: enabled ? AppColorsScheme.of(context).textPrimary : AppColorsScheme.of(context).textMuted,
          ),
        ),
      ),
    );
  }
}

// ─── Quick Picks Section ──────────────────────────────────────────────────────

class _QuickPicksSection extends ConsumerStatefulWidget {
  const _QuickPicksSection({required this.onPlay});
  final void Function(Song song) onPlay;

  @override
  ConsumerState<_QuickPicksSection> createState() => _QuickPicksSectionState();
}

class _QuickPicksSectionState extends ConsumerState<_QuickPicksSection>
    with PagedSectionMixin {
  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(homeIsLoadingProvider);
    final quickPicks = ref.watch(quickPicksProvider);
    final isDesktop = ShellContext.isDesktopOf(context);
    final layout =
        ContentLayout.of(context, ref, itemWidth: 240, minCols: 1, maxCols: 3);
    const maxRows = 4;
    final pageSize = layout.cols * maxRows;
    final totalPages = (quickPicks.length / pageSize).ceil();
    final hasOverflow = totalPages > 1;

    return SectionAsyncSwap(
      isLoading: isLoading,
      hasData: quickPicks.isNotEmpty,
      loadedChild: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: 'Quick Picks',
            subtitle: 'Based on your taste',
            useCompactStyle: true,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (hasOverflow) ...[
                  _NavButtonPair(
                      pageCtrl: pageCtrl,
                      currentPage: currentPage,
                      totalPages: totalPages),
                  const SizedBox(width: AppSpacing.sm),
                ],
                PlayCircleButton(
                  onTap: () => ref.read(playerProvider.notifier).playSong(
                        quickPicks.first,
                        queue: quickPicks,
                      ),
                ),
              ],
            ),
          ),
          QuickPicksRow(
              songs: quickPicks,
              onPlay: widget.onPlay,
              pageController: pageCtrl),
          SizedBox(height: isDesktop ? DesktopSpacing.xxl : AppSpacing.xxl),
        ],
      ),
      loadingChild: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionSkeleton(
            titleWidth: 120,
            subtitleWidth: 156,
            child: QuickPicksRowSkeleton(),
          ),
          SizedBox(height: isDesktop ? DesktopSpacing.xxl : AppSpacing.xxl),
        ],
      ),
    );
  }
}

// ─── Dynamic Sections ─────────────────────────────────────────────────────────

class _DynamicSectionsSkeletonGate extends ConsumerWidget {
  const _DynamicSectionsSkeletonGate();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoading = ref.watch(homeIsLoadingProvider);
    final dynamicSections = ref.watch(homeDynamicSectionsProvider);
    if (!isLoading || dynamicSections.isNotEmpty) {
      return const SizedBox.shrink();
    }
    final isDesktop = ShellContext.isDesktopOf(context);
    return Column(
      children: [
        const DynamicSectionsSkeleton(),
        SizedBox(height: isDesktop ? DesktopSpacing.xxl : AppSpacing.xxl),
      ],
    );
  }
}

class _DynamicSectionsSlice extends ConsumerStatefulWidget {
  const _DynamicSectionsSlice({required this.onPlay});
  final void Function(Song song) onPlay;

  @override
  ConsumerState<_DynamicSectionsSlice> createState() =>
      _DynamicSectionsSliceState();
}

class _DynamicSectionsSliceState extends ConsumerState<_DynamicSectionsSlice> {
  final Map<int, PageController> _controllers = {};

  PageController _ctrlFor(int index) =>
      _controllers.putIfAbsent(index, () => PageController());

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dynamicSections = ref.watch(homeDynamicSectionsProvider);
    final isDesktop = ShellContext.isDesktopOf(context);

    final filtered = dynamicSections
        .where((s) => !s.titleLower.contains('quick pick'))
        .toList(growable: false);

    if (filtered.isEmpty) return const SizedBox.shrink();

    return Column(
      children: [
        for (var idx = 0; idx < filtered.length; idx++)
          RepaintBoundary(
            child: _SectionWithNav(
              key: ValueKey(filtered[idx].title),
              title: filtered[idx].title,
              subtitle: filtered[idx].subtitle,
              type: filtered[idx].type,
              songs: filtered[idx].songs,
              playlists: filtered[idx].playlists,
              artists: filtered[idx].artists,
              onPlay: widget.onPlay,
              pageController: _ctrlFor(idx),
              isDesktop: isDesktop,
            ),
          ),
      ],
    );
  }
}

class _SectionWithNav extends ConsumerStatefulWidget {
  const _SectionWithNav({
    super.key,
    required this.title,
    this.subtitle,
    required this.type,
    required this.songs,
    required this.playlists,
    required this.artists,
    required this.onPlay,
    this.pageController,
    required this.isDesktop,
  });
  final String title;
  final String? subtitle;
  final HomeSectionType type;
  final List<Song> songs;
  final List<Playlist> playlists;
  final List<Artist> artists;
  final void Function(Song song) onPlay;
  final PageController? pageController;
  final bool isDesktop;

  @override
  ConsumerState<_SectionWithNav> createState() => _SectionWithNavState();
}

class _SectionWithNavState extends ConsumerState<_SectionWithNav>
    with PagedSectionMixin {
  PageController get _ctrl => widget.pageController ?? pageCtrl;

  void _onExternalScroll() {
    final p = _ctrl.page?.round() ?? 0;
    if (p != currentPage) setState(() => currentPage = p);
  }

  @override
  void initState() {
    super.initState();
    widget.pageController?.addListener(_onExternalScroll);
  }

  @override
  void dispose() {
    widget.pageController?.removeListener(_onExternalScroll);
    super.dispose();
  }

  bool _hasOverflow(ContentLayout layout) {
    if (widget.type == HomeSectionType.songs) {
      return widget.songs.length > layout.cols * 4;
    }
    if (widget.type == HomeSectionType.playlists) {
      return widget.playlists.length > layout.cols;
    }
    if (widget.type == HomeSectionType.artists) {
      return widget.artists.length > layout.cols;
    }
    return false;
  }

  int _getTotalPages(ContentLayout layout) {
    if (widget.type == HomeSectionType.songs) {
      const maxRows = 4;
      final pageSize = layout.cols * maxRows;
      return (widget.songs.length / pageSize).ceil();
    }
    if (widget.type == HomeSectionType.playlists) {
      return (widget.playlists.length / layout.cols).ceil();
    }
    if (widget.type == HomeSectionType.artists) {
      return (widget.artists.length / layout.cols).ceil();
    }
    return 1;
  }

  @override
  Widget build(BuildContext context) {
    // Use itemWidth: 240 for songs to match QuickPicksRow's column calculation exactly.
    final layout = widget.type == HomeSectionType.songs
        ? ContentLayout.of(context, ref, itemWidth: 240, minCols: 1, maxCols: 3)
        : ContentLayout.of(context, ref, itemWidth: 200, maxCols: 6);
    final showNav = _hasOverflow(layout);
    final totalPages = _getTotalPages(layout);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: widget.title,
          subtitle: widget.subtitle,
          useCompactStyle: true,
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (showNav) ...[
                _NavButtonPair(
                    pageCtrl: _ctrl,
                    currentPage: currentPage,
                    totalPages: totalPages),
              ],
              if (widget.type == HomeSectionType.songs &&
                  widget.songs.isNotEmpty) ...[
                if (showNav) const SizedBox(width: AppSpacing.sm),
                PlayCircleButton(
                  onTap: () => ref.read(playerProvider.notifier).playSong(
                        widget.songs.first,
                        queue: widget.songs,
                      ),
                ),
              ],
            ],
          ),
        ),
        if (widget.type == HomeSectionType.songs)
          QuickPicksRow(
              songs: widget.songs,
              onPlay: widget.onPlay,
              pageController: _ctrl),
        if (widget.type == HomeSectionType.playlists)
          PlaylistsRow(playlists: widget.playlists, pageController: _ctrl),
        if (widget.type == HomeSectionType.artists)
          ArtistsRow(artists: widget.artists, pageController: _ctrl),
        SizedBox(
            height: widget.isDesktop ? DesktopSpacing.xxl : AppSpacing.xxl),
      ],
    );
  }
}

// ─── Made For You Section ─────────────────────────────────────────────────────

class _MadeForYouSection extends ConsumerStatefulWidget {
  const _MadeForYouSection();

  @override
  ConsumerState<_MadeForYouSection> createState() => _MadeForYouSectionState();
}

class _MadeForYouSectionState extends ConsumerState<_MadeForYouSection>
    with PagedSectionMixin {
  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(homeIsLoadingProvider);
    final playlists = ref.watch(homePlaylistsProvider);
    final dynamicSections = ref.watch(homeDynamicSectionsProvider);
    final isDesktop = ShellContext.isDesktopOf(context);
    final layout = ContentLayout.of(context, ref);
    final hasDynamicPlaylists =
        dynamicSections.any((s) => s.type == HomeSectionType.playlists);
    final totalPages = (playlists.length / layout.cols).ceil();
    final hasOverflow = totalPages > 1;

    return SectionAsyncSwap(
      isLoading: isLoading,
      hasData: playlists.isNotEmpty || hasDynamicPlaylists,
      loadedChild: playlists.isNotEmpty && !hasDynamicPlaylists
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SectionHeader(
                  title: 'Made For You',
                  useCompactStyle: true,
                  trailing: hasOverflow
                      ? _NavButtonPair(
                          pageCtrl: pageCtrl,
                          currentPage: currentPage,
                          totalPages: totalPages)
                      : null,
                ),
                PlaylistsRow(playlists: playlists, pageController: pageCtrl),
                SizedBox(
                    height: isDesktop ? DesktopSpacing.xxl : AppSpacing.xxl),
              ],
            )
          : const SizedBox.shrink(),
      loadingChild: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionSkeleton(titleWidth: 120, child: PlaylistsRowSkeleton()),
          SizedBox(height: isDesktop ? DesktopSpacing.xxl : AppSpacing.xxl),
        ],
      ),
    );
  }
}

// ─── Artists Section ──────────────────────────────────────────────────────────

class _ArtistsSection extends ConsumerStatefulWidget {
  const _ArtistsSection();

  @override
  ConsumerState<_ArtistsSection> createState() => _ArtistsSectionState();
}

class _ArtistsSectionState extends ConsumerState<_ArtistsSection>
    with PagedSectionMixin {
  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(homeIsLoadingProvider);
    final artists = ref.watch(homeArtistsProvider);
    final dynamicSections = ref.watch(homeDynamicSectionsProvider);
    final isDesktop = ShellContext.isDesktopOf(context);
    final layout = ContentLayout.of(context, ref);
    final hasDynamicArtists =
        dynamicSections.any((s) => s.type == HomeSectionType.artists);
    final totalPages = (artists.length / layout.cols).ceil();
    final hasOverflow = totalPages > 1;

    return SectionAsyncSwap(
      isLoading: isLoading,
      hasData: artists.isNotEmpty || hasDynamicArtists,
      loadedChild: artists.isNotEmpty && !hasDynamicArtists
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SectionHeader(
                  title: 'Popular Artists',
                  useCompactStyle: true,
                  trailing: hasOverflow
                      ? _NavButtonPair(
                          pageCtrl: pageCtrl,
                          currentPage: currentPage,
                          totalPages: totalPages)
                      : null,
                ),
                ArtistsRow(artists: artists, pageController: pageCtrl),
                SizedBox(
                    height: isDesktop ? DesktopSpacing.xxl : AppSpacing.xxl),
              ],
            )
          : const SizedBox.shrink(),
      loadingChild: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionSkeleton(titleWidth: 120, child: ArtistsRowSkeleton()),
          SizedBox(height: isDesktop ? DesktopSpacing.xxl : AppSpacing.xxl),
        ],
      ),
    );
  }
}
