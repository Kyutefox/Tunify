import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'package:tunify/core/constants/app_icons.dart';
import 'package:tunify/data/models/audiobook.dart';
import 'package:tunify/data/models/playlist.dart';
import 'package:tunify/data/models/podcast.dart';
import 'package:tunify/features/library/library_provider.dart';
import 'package:tunify/features/podcast/podcast_provider.dart';
import 'package:tunify/ui/screens/shared/library/library_app_bar.dart';
import 'package:tunify/ui/screens/shared/library/library_playlist_screen.dart';
import 'package:tunify/ui/screens/shared/podcast/podcast_search_screen.dart';
import 'package:tunify/ui/screens/shared/podcast/podcast_options_sheet.dart';
import 'package:tunify/ui/theme/app_colors_scheme.dart';
import 'package:tunify/ui/theme/design_tokens.dart';
import 'package:tunify/ui/widgets/common/button.dart';
import 'package:tunify/ui/widgets/common/content_switcher.dart';
import 'package:tunify/ui/widgets/library/library_item_tile.dart';

class PodcastScreen extends ConsumerStatefulWidget {
  const PodcastScreen({super.key});

  @override
  ConsumerState<PodcastScreen> createState() => _PodcastScreenState();
}

class _PodcastScreenState extends ConsumerState<PodcastScreen>
    {
  LibraryFilter? _selectedFilter;
  LibraryViewMode _viewMode = LibraryViewMode.list;
  LibrarySortOrder _sortOrder = LibrarySortOrder.recent;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final overlayStyle = isDark
        ? SystemUiOverlayStyle.light
            .copyWith(statusBarColor: Colors.transparent)
        : SystemUiOverlayStyle.dark
            .copyWith(statusBarColor: Colors.transparent);

    final contentKey = ValueKey(
      '${_selectedFilter?.name ?? 'podcasts'}-${_viewMode.name}-${_sortOrder.name}',
    );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: overlayStyle,
      child: Scaffold(
        backgroundColor: AppColorsScheme.of(context).background,
        body: SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              LibraryAppBar(
                asSliver: false,
                title: 'Podcasts & Books',
                searchTooltip: 'Search podcasts',
                showDownloadQueueAction: false,
                showCreateAction: false,
                filters: const [LibraryFilter.albums],
                filterLabelBuilder: (f) => f == LibraryFilter.albums ? 'Audiobooks' : f.label,
                onSearchTap: _openSearch,
                onDownloadQueueTap: () {},
                onCreateTap: () {},
                selectedFilter: _selectedFilter,
                onFilterChanged: (f) => setState(() => _selectedFilter = f),
                sortOrder: _sortOrder,
                viewMode: _viewMode,
                onSortChanged: (order) => setState(() => _sortOrder = order),
                onViewModeChanged: (mode) => setState(() => _viewMode = mode),
              ),
              Expanded(
                child: AppContentSwitcher(
                  contentKey: contentKey,
                  child: _selectedFilter == LibraryFilter.albums
                      ? _AudiobooksTab(viewMode: _viewMode, sortOrder: _sortOrder)
                      : _PodcastsTab(viewMode: _viewMode, sortOrder: _sortOrder),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openSearch() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const PodcastSearchScreen(),
      ),
    );
  }
}

// ── Podcasts Tab ──────────────────────────────────────────────────────────────

class _PodcastsTab extends ConsumerWidget {
  const _PodcastsTab({required this.viewMode, required this.sortOrder});

  final LibraryViewMode viewMode;
  final LibrarySortOrder sortOrder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subscriptions = ref.watch(podcastSubscriptionsProvider);
    final episodesForLater =
        ref.watch(podcastProvider.select((s) => s.episodesForLater));
    final sortedSubscriptions = _sortPodcasts(subscriptions, sortOrder);

    if (viewMode == LibraryViewMode.grid) {
      final itemCount = sortedSubscriptions.length + 1;
      return GridView.builder(
        padding: const EdgeInsets.only(
          top: AppSpacing.sm,
          left: AppSpacing.base,
          right: AppSpacing.base,
          bottom: AppSpacing.xxl + 80,
        ),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.85,
          crossAxisSpacing: AppSpacing.sm,
          mainAxisSpacing: AppSpacing.sm,
        ),
        itemCount: itemCount,
        itemBuilder: (context, i) {
          if (i == 0) {
            return _PodcastGridCard(
              title: 'Episodes For Later',
              subtitle:
                  '${episodesForLater.length} ${episodesForLater.length == 1 ? 'episode' : 'episodes'}',
              thumbnailUrl: null,
              placeholderIcon: AppIcons.bookmark,
              placeholderIconColor: Colors.white,
              placeholderGradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF9333EA), Color(0xFF7C3AED)],
              ),
              onTap: () {
                final playlist = Playlist(
                  id: 'episodesForLater',
                  title: 'Episodes For Later',
                  description: 'Your saved podcast episodes',
                  coverUrl: '',
                  trackCount: episodesForLater.length,
                );
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => LibraryPlaylistScreen.podcast(playlist: playlist),
                ));
              },
            );
          }

          final podcastIndex = i - 1;
          final podcast = sortedSubscriptions[podcastIndex];
          return _PodcastGridCard(
            title: podcast.title,
            subtitle: podcast.author ?? 'Podcast',
            thumbnailUrl: podcast.thumbnailUrl,
            placeholderIcon: AppIcons.podcast,
            showPinIndicator: podcast.isPinned,
            onTap: () {
              final playlist = Playlist(
                id: podcast.browseId ?? podcast.id,
                title: podcast.title,
                description: podcast.author ?? '',
                coverUrl: podcast.thumbnailUrl ?? '',
                trackCount: 0,
              );
              Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => LibraryPlaylistScreen.podcast(playlist: playlist),
              ));
            },
            onOptions: (rect) => showPodcastOptionsSheet(
              context,
              podcast: podcast,
              ref: ref,
              anchorRect: rect,
            ),
          );
        },
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(
          top: AppSpacing.sm,
          left: AppSpacing.base,
          right: AppSpacing.base,
          bottom: AppSpacing.xxl + 80),
      itemCount: sortedSubscriptions.length + 1,
      itemBuilder: (context, i) {
        if (i == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.xs),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  final playlist = Playlist(
                    id: 'episodesForLater',
                    title: 'Episodes For Later',
                    description: 'Your saved podcast episodes',
                    coverUrl: '',
                    trackCount: episodesForLater.length,
                  );
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => LibraryPlaylistScreen.podcast(playlist: playlist),
                  ));
                },
                borderRadius: BorderRadius.circular(AppRadius.sm),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                  child: Row(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFF9333EA), Color(0xFF7C3AED)],
                          ),
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                        ),
                        child: Center(
                          child: AppIcon(
                            icon: AppIcons.bookmark,
                            size: 28,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Episodes For Later',
                              style: TextStyle(
                                color: AppColorsScheme.of(context).textPrimary,
                                fontSize: AppFontSize.lg,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              '${episodesForLater.length} ${episodesForLater.length == 1 ? 'episode' : 'episodes'}',
                              style: TextStyle(
                                color: AppColorsScheme.of(context).textMuted,
                                fontSize: AppFontSize.md,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }

        final podcastIndex = i - 1;
        final podcast = sortedSubscriptions[podcastIndex];
        return LibraryItemTile(
          title: podcast.title,
          subtitle: podcast.author ?? 'Podcast',
          thumbnailUrl: podcast.thumbnailUrl,
          placeholderIcon: AppIcons.podcast,
          showPinIndicator: podcast.isPinned,
          onTap: () {
            final playlist = Playlist(
              id: podcast.browseId ?? podcast.id,
              title: podcast.title,
              description: podcast.author ?? '',
              coverUrl: podcast.thumbnailUrl ?? '',
              trackCount: 0,
            );
            Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => LibraryPlaylistScreen.podcast(playlist: playlist),
            ));
          },
          onOptions: (rect) => showPodcastOptionsSheet(
            context,
            podcast: podcast,
            ref: ref,
            anchorRect: rect,
          ),
        );
      },
    );
  }
}

// ── Audiobooks Tab ────────────────────────────────────────────────────────────

class _AudiobooksTab extends ConsumerWidget {
  const _AudiobooksTab({required this.viewMode, required this.sortOrder});

  final LibraryViewMode viewMode;
  final LibrarySortOrder sortOrder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final audiobooks = ref.watch(savedAudiobooksProvider);
    final sortedAudiobooks = _sortAudiobooks(audiobooks, sortOrder);

    if (sortedAudiobooks.isEmpty) {
      return _EmptyState(
        icon: AppIcons.bookOpen,
        title: 'No saved audiobooks',
        subtitle: 'Search for audiobooks and save them here.',
      );
    }

    if (viewMode == LibraryViewMode.grid) {
      return GridView.builder(
        padding: const EdgeInsets.only(
          top: AppSpacing.sm,
          left: AppSpacing.base,
          right: AppSpacing.base,
          bottom: AppSpacing.xxl + 80,
        ),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.85,
          crossAxisSpacing: AppSpacing.sm,
          mainAxisSpacing: AppSpacing.sm,
        ),
        itemCount: sortedAudiobooks.length,
        itemBuilder: (context, i) {
          final audiobook = sortedAudiobooks[i];
          return _PodcastGridCard(
            title: audiobook.title,
            subtitle: audiobook.author ?? 'Audiobook',
            thumbnailUrl: audiobook.thumbnailUrl,
            placeholderIcon: AppIcons.bookOpen,
            showPinIndicator: audiobook.isPinned,
            onTap: () {
              final playlist = Playlist(
                id: audiobook.browseId ?? audiobook.id,
                title: audiobook.title,
                description: audiobook.author ?? '',
                coverUrl: audiobook.thumbnailUrl ?? '',
                trackCount: 0,
              );
              Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => LibraryPlaylistScreen.podcast(playlist: playlist),
              ));
            },
            onOptions: (rect) => showAudiobookOptionsSheet(
              context,
              audiobook: audiobook,
              ref: ref,
              anchorRect: rect,
            ),
          );
        },
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(
          top: AppSpacing.sm,
          left: AppSpacing.base,
          right: AppSpacing.base,
          bottom: AppSpacing.xxl + 80),
      itemCount: sortedAudiobooks.length,
      itemBuilder: (context, i) {
        final audiobook = sortedAudiobooks[i];
        return LibraryItemTile(
          title: audiobook.title,
          subtitle: audiobook.author ?? 'Audiobook',
          thumbnailUrl: audiobook.thumbnailUrl,
          placeholderIcon: AppIcons.bookOpen,
          showPinIndicator: audiobook.isPinned,
          onTap: () {
            final playlist = Playlist(
              id: audiobook.browseId ?? audiobook.id,
              title: audiobook.title,
              description: audiobook.author ?? '',
              coverUrl: audiobook.thumbnailUrl ?? '',
              trackCount: 0,
            );
            Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => LibraryPlaylistScreen.podcast(playlist: playlist),
            ));
          },
          onOptions: (rect) => showAudiobookOptionsSheet(
            context,
            audiobook: audiobook,
            ref: ref,
            anchorRect: rect,
          ),
        );
      },
    );
  }
}

class _PodcastGridCard extends StatelessWidget {
  const _PodcastGridCard({
    required this.title,
    required this.subtitle,
    required this.thumbnailUrl,
    required this.placeholderIcon,
    required this.onTap,
    this.onOptions,
    this.showPinIndicator = false,
    this.placeholderGradient,
    this.placeholderIconColor,
  });

  final String title;
  final String subtitle;
  final String? thumbnailUrl;
  final List<List<dynamic>> placeholderIcon;
  final VoidCallback onTap;
  final void Function(Rect?)? onOptions;
  final bool showPinIndicator;
  final Gradient? placeholderGradient;
  final Color? placeholderIconColor;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Stack(
              children: [
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: placeholderGradient == null
                        ? AppColorsScheme.of(context).surfaceLight
                        : null,
                    gradient: placeholderGradient,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    child: thumbnailUrl != null && thumbnailUrl!.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: thumbnailUrl!,
                            fit: BoxFit.cover,
                            errorWidget: (_, __, ___) => Center(
                              child: AppIcon(
                                icon: placeholderIcon,
                                color: placeholderIconColor ??
                                    AppColorsScheme.of(context).textMuted,
                                size: 36,
                              ),
                            ),
                          )
                        : Center(
                            child: AppIcon(
                              icon: placeholderIcon,
                              color: placeholderIconColor ??
                                  AppColorsScheme.of(context).textMuted,
                              size: 36,
                            ),
                          ),
                  ),
                ),
                if (showPinIndicator)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.35),
                        shape: BoxShape.circle,
                      ),
                      child: AppIcon(
                        icon: AppIcons.pin,
                        size: 12,
                        color: Colors.white,
                      ),
                    ),
                  ),
                if (onOptions != null)
                  Positioned(
                    top: 2,
                    right: 2,
                    child: Builder(
                      builder: (btnCtx) => AppIconButton(
                        icon: AppIcon(
                          icon: AppIcons.moreVert,
                          size: 18,
                          color: Colors.white,
                        ),
                        size: 34,
                        iconSize: 18,
                        onPressedWithContext: (ctx) {
                          final box = ctx.findRenderObject() as RenderBox?;
                          onOptions!(box != null && box.hasSize
                              ? box.localToGlobal(Offset.zero) & box.size
                              : null);
                        },
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            title,
            style: TextStyle(
              color: AppColorsScheme.of(context).textPrimary,
              fontSize: AppFontSize.md,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            subtitle,
            style: TextStyle(
              color: AppColorsScheme.of(context).textMuted,
              fontSize: AppFontSize.xs,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

List<T> _sortPinnedFirst<T>(
  List<T> items,
  bool Function(T item) isPinned,
  int Function(T a, T b) compareWithin,
) {
  final list = List<T>.from(items);
  list.sort((a, b) {
    if (isPinned(a) && !isPinned(b)) return -1;
    if (!isPinned(a) && isPinned(b)) return 1;
    return compareWithin(a, b);
  });
  return list;
}

List<T> _sortByMode<T>(
  List<T> items,
  LibrarySortOrder sortOrder,
  bool Function(T item) isPinned,
  String Function(T item) title,
) {
  if (sortOrder == LibrarySortOrder.alphabetical) {
    return _sortPinnedFirst<T>(
      items,
      isPinned,
      (a, b) => title(a).toLowerCase().compareTo(title(b).toLowerCase()),
    );
  }

  // Recent/recentlyAdded keep provider order while still honoring pinned first.
  return _sortPinnedFirst<T>(items, isPinned, (_, __) => 0);
}

List<Podcast> _sortPodcasts(List<Podcast> items, LibrarySortOrder sortOrder) =>
    _sortByMode(
      items,
      sortOrder,
      (p) => p.isPinned,
      (p) => p.title,
    );

List<Audiobook> _sortAudiobooks(List<Audiobook> items, LibrarySortOrder sortOrder) =>
    _sortByMode(
      items,
      sortOrder,
      (a) => a.isPinned,
      (a) => a.title,
    );

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
  });
  final List<List<dynamic>> icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppIcon(
              icon: icon,
              size: 56,
              color: AppColorsScheme.of(context).textMuted,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColorsScheme.of(context).textPrimary,
                fontSize: AppFontSize.lg,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: AppColorsScheme.of(context).textMuted,
                  fontSize: AppFontSize.md),
            ),
          ],
        ),
      ),
    );
  }
}
