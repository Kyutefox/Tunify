import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../config/app_icons.dart';
import '../../components/shared/components_shared.dart';
import '../../../models/artist.dart';
import '../../../models/playlist.dart';
import '../../../models/song.dart';
import '../../../shared/providers/home_state_provider.dart';
import '../../../shared/providers/player_state_provider.dart';
import '../../layout/shell_context.dart';
import '../../theme/app_colors.dart';
import '../../components/ui/widgets/section_header.dart';
import '../../theme/design_tokens.dart';
import 'home_sections.dart';
import 'home_skeletons.dart';

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

    return SliverList.list(
      children: [
        RepaintBoundary(child: RecentlyPlayedSection(onPlay: onPlay)),
        RepaintBoundary(child: _AnimatedFeedBlock(onPlay: onPlay)),
        const RepaintBoundary(child: MoodSection()),
      ],
    );
  }
}

/// Wraps Quick Picks + dynamic sections + Made For You + Artists in [AnimatedSwitcher]
/// keyed by [homeFeedVersionProvider] so when background refetch updates the feed,
/// new content fades in smoothly without a jarring swap.
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
      transitionBuilder: (Widget child, Animation<double> animation) {
        return FadeTransition(opacity: animation, child: child);
      },
      child: KeyedSubtree(
        key: ValueKey(feedVersion),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _QuickPicksSection(onPlay: onPlay),
            const RepaintBoundary(child: _DynamicSectionsSkeletonGate()),
            _DynamicSectionsSlice(onPlay: onPlay),
            _MadeForYouSection(),
            _ArtistsSection(),
          ],
        ),
      ),
    );
  }
}


class _QuickPicksSection extends ConsumerStatefulWidget {
  const _QuickPicksSection({required this.onPlay});
  final void Function(Song song) onPlay;

  @override
  ConsumerState<_QuickPicksSection> createState() => _QuickPicksSectionState();
}

class _QuickPicksSectionState extends ConsumerState<_QuickPicksSection> {
  final _pageCtrl = PageController();
  int _page = 0;

  @override
  void initState() {
    super.initState();
    _pageCtrl.addListener(() {
      final p = _pageCtrl.page?.round() ?? 0;
      if (p != _page) setState(() => _page = p);
    });
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(homeIsLoadingProvider);
    final quickPicks = ref.watch(quickPicksProvider);
    final isDesktop = ShellContext.isDesktopOf(context);
    final cols = isDesktop ? 5 : 2;
    final hasOverflow = quickPicks.length > cols * 4;

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
                  _NavButton(
                    icon: AppIcons.back,
                    enabled: _page > 0,
                    onTap: () => _pageCtrl.animateToPage(
                      0,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  _NavButton(
                    icon: AppIcons.forward,
                    enabled: _page == 0,
                    onTap: () => _pageCtrl.animateToPage(
                      1,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                ],
                GestureDetector(
                  onTap: () => ref.read(playerProvider.notifier).playSong(
                        quickPicks.first,
                        queue: quickPicks,
                      ),
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    width: 34,
                    height: 34,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: AppIcon(icon: AppIcons.play, size: 18, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
          QuickPicksRow(
            songs: quickPicks,
            onPlay: widget.onPlay,
            pageController: _pageCtrl,
          ),
          const SizedBox(height: AppSpacing.xxl),
        ],
      ),
      loadingChild: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionSkeleton(
            titleWidth: 120,
            subtitleWidth: 156,
            child: QuickPicksRowSkeleton(),
          ),
          SizedBox(height: AppSpacing.xxl),
        ],
      ),
    );
  }
}

/// Small prev/next arrow button used in section headers.
class _NavButton extends StatelessWidget {
  const _NavButton({required this.icon, required this.onTap, this.enabled = true});
  final List<List<dynamic>> icon;
  final VoidCallback onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: enabled ? AppColors.surfaceLight : AppColors.surfaceLight.withValues(alpha: 0.4),
          shape: BoxShape.circle,
        ),
        child: Center(
          child: AppIcon(
            icon: icon,
            size: 14,
            color: enabled ? AppColors.textPrimary : AppColors.textMuted,
          ),
        ),
      ),
    );
  }
}

class _DynamicSectionsSkeletonGate extends ConsumerWidget {
  const _DynamicSectionsSkeletonGate();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoading = ref.watch(homeIsLoadingProvider);
    final dynamicSections = ref.watch(homeDynamicSectionsProvider);

    if (!isLoading || dynamicSections.isNotEmpty) {
      return const SizedBox.shrink();
    }

    return const Column(
      children: [
        DynamicSectionsSkeleton(),
        SizedBox(height: AppSpacing.xxl),
      ],
    );
  }
}

class _DynamicSectionsSlice extends ConsumerStatefulWidget {
  const _DynamicSectionsSlice({required this.onPlay});
  final void Function(Song song) onPlay;

  @override
  ConsumerState<_DynamicSectionsSlice> createState() => _DynamicSectionsSliceState();
}

class _DynamicSectionsSliceState extends ConsumerState<_DynamicSectionsSlice> {
  final Map<int, PageController> _controllers = {};

  PageController _ctrlFor(int index) =>
      _controllers.putIfAbsent(index, () => PageController());

  @override
  void dispose() {
    for (final c in _controllers.values) c.dispose();
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
              pageController: filtered[idx].type != HomeSectionType.songs
                  ? _ctrlFor(idx)
                  : null,
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

class _SectionWithNavState extends ConsumerState<_SectionWithNav> {
  int _page = 0;

  @override
  void initState() {
    super.initState();
    widget.pageController?.addListener(_onScroll);
  }

  void _onScroll() {
    final p = widget.pageController?.page?.round() ?? 0;
    if (p != _page) setState(() => _page = p);
  }

  @override
  void dispose() {
    widget.pageController?.removeListener(_onScroll);
    super.dispose();
  }

  bool get _hasOverflow {
    final cols = widget.isDesktop ? 5 : 2;
    const rows = 1;
    final pageSize = cols * rows;
    if (widget.type == HomeSectionType.playlists) return widget.playlists.length > pageSize;
    if (widget.type == HomeSectionType.artists) return widget.artists.length > pageSize;
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = widget.pageController;
    final showNav = ctrl != null && _hasOverflow;

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
                _NavButton(
                  icon: AppIcons.back,
                  enabled: _page > 0,
                  onTap: () => ctrl.animateToPage(0,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut),
                ),
                const SizedBox(width: AppSpacing.xs),
                _NavButton(
                  icon: AppIcons.forward,
                  enabled: _page == 0,
                  onTap: () => ctrl.animateToPage(1,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut),
                ),
              ],
              if (widget.type == HomeSectionType.songs && widget.songs.isNotEmpty) ...[
                if (showNav) const SizedBox(width: AppSpacing.sm),
                GestureDetector(
                  onTap: () => ref.read(playerProvider.notifier).playSong(
                        widget.songs.first,
                        queue: widget.songs,
                      ),
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    width: 34,
                    height: 34,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: AppIcon(icon: AppIcons.play, size: 18, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        if (widget.type == HomeSectionType.songs)
          QuickPicksRow(songs: widget.songs, onPlay: widget.onPlay),
        if (widget.type == HomeSectionType.playlists)
          PlaylistsRow(playlists: widget.playlists, pageController: ctrl),
        if (widget.type == HomeSectionType.artists)
          ArtistsRow(artists: widget.artists, pageController: ctrl),
        const SizedBox(height: AppSpacing.xxl),
      ],
    );
  }
}

class _MadeForYouSection extends ConsumerStatefulWidget {
  const _MadeForYouSection();

  @override
  ConsumerState<_MadeForYouSection> createState() => _MadeForYouSectionState();
}

class _MadeForYouSectionState extends ConsumerState<_MadeForYouSection> {
  final _pageCtrl = PageController();
  int _page = 0;

  @override
  void initState() {
    super.initState();
    _pageCtrl.addListener(() {
      final p = _pageCtrl.page?.round() ?? 0;
      if (p != _page) setState(() => _page = p);
    });
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(homeIsLoadingProvider);
    final playlists = ref.watch(homePlaylistsProvider);
    final dynamicSections = ref.watch(homeDynamicSectionsProvider);
    final isDesktop = ShellContext.isDesktopOf(context);
    final hasDynamicPlaylists = dynamicSections.any((s) => s.type == HomeSectionType.playlists);
    final cols = isDesktop ? 5 : 2;
    final hasOverflow = playlists.length > cols;

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
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _NavButton(
                              icon: AppIcons.back,
                              enabled: _page > 0,
                              onTap: () => _pageCtrl.animateToPage(0,
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeInOut),
                            ),
                            const SizedBox(width: AppSpacing.xs),
                            _NavButton(
                              icon: AppIcons.forward,
                              enabled: _page == 0,
                              onTap: () => _pageCtrl.animateToPage(1,
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeInOut),
                            ),
                          ],
                        )
                      : null,
                ),
                PlaylistsRow(playlists: playlists, pageController: _pageCtrl),
                const SizedBox(height: AppSpacing.xxl),
              ],
            )
          : const SizedBox.shrink(),
      loadingChild: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionSkeleton(titleWidth: 120, child: PlaylistsRowSkeleton()),
          SizedBox(height: AppSpacing.xxl),
        ],
      ),
    );
  }
}

class _ArtistsSection extends ConsumerStatefulWidget {
  const _ArtistsSection();

  @override
  ConsumerState<_ArtistsSection> createState() => _ArtistsSectionState();
}

class _ArtistsSectionState extends ConsumerState<_ArtistsSection> {
  final _pageCtrl = PageController();
  int _page = 0;

  @override
  void initState() {
    super.initState();
    _pageCtrl.addListener(() {
      final p = _pageCtrl.page?.round() ?? 0;
      if (p != _page) setState(() => _page = p);
    });
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(homeIsLoadingProvider);
    final artists = ref.watch(homeArtistsProvider);
    final dynamicSections = ref.watch(homeDynamicSectionsProvider);
    final isDesktop = ShellContext.isDesktopOf(context);
    final hasDynamicArtists = dynamicSections.any((s) => s.type == HomeSectionType.artists);
    final cols = isDesktop ? 5 : 2;
    final hasOverflow = artists.length > cols;

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
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _NavButton(
                              icon: AppIcons.back,
                              enabled: _page > 0,
                              onTap: () => _pageCtrl.animateToPage(0,
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeInOut),
                            ),
                            const SizedBox(width: AppSpacing.xs),
                            _NavButton(
                              icon: AppIcons.forward,
                              enabled: _page == 0,
                              onTap: () => _pageCtrl.animateToPage(1,
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeInOut),
                            ),
                          ],
                        )
                      : null,
                ),
                ArtistsRow(artists: artists, pageController: _pageCtrl),
                const SizedBox(height: AppSpacing.xxl),
              ],
            )
          : const SizedBox.shrink(),
      loadingChild: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionSkeleton(titleWidth: 120, child: ArtistsRowSkeleton()),
          SizedBox(height: AppSpacing.xxl),
        ],
      ),
    );
  }
}
