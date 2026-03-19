import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../config/app_icons.dart';
import '../../components/shared/components_shared.dart';
import '../../../models/song.dart';
import '../../../shared/providers/home_state_provider.dart';
import '../../../shared/providers/player_state_provider.dart';
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
            RepaintBoundary(child: _QuickPicksSection(onPlay: onPlay)),
            const RepaintBoundary(child: _DynamicSectionsSkeletonGate()),
            _DynamicSectionsSlice(onPlay: onPlay),
            const RepaintBoundary(child: _MadeForYouSection()),
            const RepaintBoundary(child: _ArtistsSection()),
          ],
        ),
      ),
    );
  }
}


class _QuickPicksSection extends ConsumerWidget {
  const _QuickPicksSection({required this.onPlay});
  final void Function(Song song) onPlay;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoading = ref.watch(homeIsLoadingProvider);
    final quickPicks = ref.watch(quickPicksProvider);

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
            trailing: GestureDetector(
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
                  child: AppIcon(
                    icon: AppIcons.play,
                    size: 18,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
          QuickPicksRow(songs: quickPicks, onPlay: onPlay),
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

class _DynamicSectionsSlice extends ConsumerWidget {
  const _DynamicSectionsSlice({required this.onPlay});
  final void Function(Song song) onPlay;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dynamicSections = ref.watch(homeDynamicSectionsProvider);

    // Use pre-lowercased titleLower (computed once per HomeSongSection instance)
    // to avoid repeated String.toLowerCase() allocations on every build.
    final filtered = dynamicSections
        .where((s) => !s.titleLower.contains('quick pick'))
        .toList(growable: false);

    if (filtered.isEmpty) return const SizedBox.shrink();

    return Column(
      children: [
        for (final section in filtered)
          RepaintBoundary(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SectionHeader(
                  title: section.title,
                  subtitle: section.subtitle,
                  useCompactStyle: true,
                ),
                if (section.type == HomeSectionType.songs)
                  QuickPicksRow(songs: section.songs, onPlay: onPlay),
                if (section.type == HomeSectionType.playlists)
                  PlaylistsRow(playlists: section.playlists),
                if (section.type == HomeSectionType.artists)
                  ArtistsRow(artists: section.artists),
                const SizedBox(height: AppSpacing.xxl),
              ],
            ),
          ),
      ],
    );
  }
}

class _MadeForYouSection extends ConsumerWidget {
  const _MadeForYouSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoading = ref.watch(homeIsLoadingProvider);
    final playlists = ref.watch(homePlaylistsProvider);
    final dynamicSections = ref.watch(homeDynamicSectionsProvider);

    // Hoist repeated .any() O(n) scans to a single local variable.
    final hasDynamicPlaylists =
        dynamicSections.any((s) => s.type == HomeSectionType.playlists);

    return SectionAsyncSwap(
      isLoading: isLoading,
      hasData: playlists.isNotEmpty || hasDynamicPlaylists,
      loadedChild: playlists.isNotEmpty && !hasDynamicPlaylists
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SectionHeader(
                  title: 'Made For You',
                  onSeeAll: () {},
                  seeAllLabel: 'See all',
                  useCompactStyle: true,
                ),
                PlaylistsRow(playlists: playlists),
                const SizedBox(height: AppSpacing.xxl),
              ],
            )
          : const SizedBox.shrink(),
      loadingChild: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionSkeleton(
            titleWidth: 120,
            child: PlaylistsRowSkeleton(),
          ),
          SizedBox(height: AppSpacing.xxl),
        ],
      ),
    );
  }
}

class _ArtistsSection extends ConsumerWidget {
  const _ArtistsSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoading = ref.watch(homeIsLoadingProvider);
    final artists = ref.watch(homeArtistsProvider);
    final dynamicSections = ref.watch(homeDynamicSectionsProvider);

    // Hoist repeated .any() O(n) scans to a single local variable.
    final hasDynamicArtists =
        dynamicSections.any((s) => s.type == HomeSectionType.artists);

    return SectionAsyncSwap(
      isLoading: isLoading,
      hasData: artists.isNotEmpty || hasDynamicArtists,
      loadedChild: artists.isNotEmpty && !hasDynamicArtists
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SectionHeader(
                  title: 'Popular Artists',
                  onSeeAll: () {},
                  seeAllLabel: 'See all',
                  useCompactStyle: true,
                ),
                ArtistsRow(artists: artists),
                const SizedBox(height: AppSpacing.xxl),
              ],
            )
          : const SizedBox.shrink(),
      loadingChild: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionSkeleton(
            titleWidth: 120,
            child: ArtistsRowSkeleton(),
          ),
          SizedBox(height: AppSpacing.xxl),
        ],
      ),
    );
  }
}
