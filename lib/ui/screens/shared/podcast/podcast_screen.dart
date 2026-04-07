import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tunify/core/constants/app_icons.dart';
import 'package:tunify/data/models/playlist.dart';
import 'package:tunify/features/podcast/podcast_provider.dart';
import 'package:tunify/ui/screens/shared/library/library_playlist_screen.dart';
import 'package:tunify/ui/screens/shared/podcast/podcast_search_screen.dart';
import 'package:tunify/ui/theme/app_colors.dart';
import 'package:tunify/ui/theme/app_colors_scheme.dart';
import 'package:tunify/ui/theme/design_tokens.dart';
import 'package:tunify/ui/theme/desktop_tokens.dart';
import 'package:tunify/ui/widgets/common/button.dart';
import 'package:tunify/ui/widgets/library/library_item_tile.dart';

class PodcastScreen extends ConsumerStatefulWidget {
  const PodcastScreen({super.key});

  @override
  ConsumerState<PodcastScreen> createState() => _PodcastScreenState();
}

class _PodcastScreenState extends ConsumerState<PodcastScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final overlayStyle = isDark
        ? SystemUiOverlayStyle.light
            .copyWith(statusBarColor: Colors.transparent)
        : SystemUiOverlayStyle.dark
            .copyWith(statusBarColor: Colors.transparent);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: overlayStyle,
      child: Scaffold(
        backgroundColor: AppColorsScheme.of(context).background,
        body: SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _PodcastTopBar(onSearch: _openSearch),
              TabBar(
                controller: _tabController,
                labelColor: AppColors.primary,
                unselectedLabelColor: AppColorsScheme.of(context).textMuted,
                indicatorColor: AppColors.primary,
                indicatorSize: TabBarIndicatorSize.label,
                labelStyle: const TextStyle(
                  fontSize: AppFontSize.md,
                  fontWeight: FontWeight.w600,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontSize: AppFontSize.md,
                  fontWeight: FontWeight.normal,
                ),
                tabs: const [
                  Tab(text: 'Podcasts'),
                  Tab(text: 'Audiobooks'),
                ],
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: const [
                    _PodcastsTab(),
                    _AudiobooksTab(),
                  ],
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

// ── Top Bar ───────────────────────────────────────────────────────────────────

class _PodcastTopBar extends StatelessWidget {
  const _PodcastTopBar({required this.onSearch});
  final VoidCallback onSearch;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.base, AppSpacing.sm, AppSpacing.sm, AppSpacing.xs),
      child: Row(
        children: [
          Text(
            'Podcasts & Books',
            style: TextStyle(
              fontSize: AppFontSize.xl,
              fontWeight: FontWeight.w700,
              color: AppColorsScheme.of(context).textPrimary,
            ),
          ),
          const Spacer(),
          AppIconButton(
            icon: AppIcon(
              icon: AppIcons.search,
              size: 24,
              color: AppColorsScheme.of(context).textPrimary,
            ),
            onPressed: onSearch,
            size: 44,
            iconSize: 24,
          ),
        ],
      ),
    );
  }
}

// ── Podcasts Tab ──────────────────────────────────────────────────────────────

class _PodcastsTab extends ConsumerWidget {
  const _PodcastsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hPad = AppTokens.of(context).isDesktop
        ? DesktopSpacing.lg
        : AppSpacing.base;
    final subscriptions = ref.watch(podcastSubscriptionsProvider);
    final episodesForLater =
        ref.watch(podcastProvider.select((s) => s.episodesForLater));

    if (subscriptions.isEmpty) {
      // Show Episodes For Later even when no subscriptions
      return Column(
        children: [
          Padding(
            padding: EdgeInsets.only(
              top: AppSpacing.sm,
              left: hPad,
              right: hPad,
            ),
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
                    builder: (_) =>
                        LibraryPlaylistScreen.podcast(playlist: playlist),
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
          ),
          Expanded(
            child: _EmptyState(
              icon: AppIcons.podcast,
              title: 'No subscriptions yet',
              subtitle: 'Search for podcasts and subscribe to them here.',
            ),
          ),
        ],
      );
    }

    return ListView.builder(
      padding: EdgeInsets.only(
          top: AppSpacing.sm,
          left: hPad,
          right: hPad,
          bottom: AppSpacing.xxl + 80),
      itemCount: subscriptions.length + 1, // Always show Episodes For Later
      itemBuilder: (context, i) {
        // Episodes For Later tile (always first)
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
                    builder: (_) =>
                        LibraryPlaylistScreen.podcast(playlist: playlist),
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

        // Adjust index for podcast subscriptions
        final podcastIndex = i - 1;
        final podcast = subscriptions[podcastIndex];
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
        );
      },
    );
  }
}

// ── Audiobooks Tab ────────────────────────────────────────────────────────────

class _AudiobooksTab extends ConsumerWidget {
  const _AudiobooksTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hPad = AppTokens.of(context).isDesktop
        ? DesktopSpacing.lg
        : AppSpacing.base;
    final audiobooks = ref.watch(savedAudiobooksProvider);

    if (audiobooks.isEmpty) {
      return _EmptyState(
        icon: AppIcons.bookOpen,
        title: 'No saved audiobooks',
        subtitle: 'Search for audiobooks and save them here.',
      );
    }

    return ListView.builder(
      padding: EdgeInsets.only(
          top: AppSpacing.sm,
          left: hPad,
          right: hPad,
          bottom: AppSpacing.xxl + 80),
      itemCount: audiobooks.length,
      itemBuilder: (context, i) {
        final audiobook = audiobooks[i];
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
        );
      },
    );
  }
}

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
