import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tunify/core/constants/app_icons.dart';
import 'package:tunify/data/models/playlist.dart';
import 'package:tunify/features/podcast/podcast_provider.dart';
import 'package:tunify/ui/screens/shared/library/library_playlist_screen.dart';
import 'package:tunify/ui/screens/shared/podcast/podcast_options_sheet.dart';
import 'package:tunify/ui/screens/shared/search/search_page.dart';
import 'package:tunify/ui/theme/app_colors.dart';
import 'package:tunify/ui/theme/desktop_tokens.dart';
import 'package:tunify/ui/theme/app_colors_scheme.dart';
import 'package:tunify/ui/theme/design_tokens.dart';
import 'package:tunify/ui/widgets/library/library_item_tile.dart';

class PodcastSearchScreen extends ConsumerStatefulWidget {
  const PodcastSearchScreen({super.key});

  @override
  ConsumerState<PodcastSearchScreen> createState() =>
      _PodcastSearchScreenState();
}

class _PodcastSearchScreenState extends ConsumerState<PodcastSearchScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  late TabController _tabController;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _controller.addListener(() {
      final q = _controller.text.trim();
      if (q != _query) setState(() => _query = q);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SharedSearchPage(
      controller: _controller,
      focusNode: _focusNode,
      onBack: () => Navigator.of(context).pop(),
      hintText: 'Search podcasts & audiobooks',
      autofocus: true,
      onClear: () => setState(() => _query = ''),
      body: Column(
        children: [
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
              children: [
                _PodcastSearchResults(query: _query),
                _AudiobookSearchResults(query: _query),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Podcast search results ────────────────────────────────────────────────────

class _PodcastSearchResults extends ConsumerWidget {
  const _PodcastSearchResults({required this.query});
  final String query;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hPad = AppTokens.of(context).isDesktop
        ? DesktopSpacing.lg
        : AppSpacing.base;
    if (query.isEmpty) {
      return SearchPageEmptyState(
        icon: AppIcon(
            icon: AppIcons.podcast,
            size: 56,
            color: AppColorsScheme.of(context).textMuted),
        heading: 'Search Podcasts',
        subheading: 'Find podcast episodes, interviews & talks',
      );
    }

    final resultsAsync = ref.watch(podcastSearchResultsProvider(query));
    return resultsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => SearchPageEmptyState(
        icon: AppIcon(
            icon: AppIcons.search,
            size: 56,
            color: AppColorsScheme.of(context).textMuted),
        heading: 'Something went wrong',
        subheading: 'Could not load podcast results',
      ),
      data: (podcasts) {
        if (podcasts.isEmpty) {
          return SearchPageEmptyState(
            icon: AppIcon(
                icon: AppIcons.podcast,
                size: 56,
                color: AppColorsScheme.of(context).textMuted),
            heading: 'No podcasts found',
            subheading: 'Try a different search term',
          );
        }
        return ListView.builder(
          padding: EdgeInsets.only(bottom: 120, left: hPad, right: hPad),
          itemCount: podcasts.length,
          itemBuilder: (context, i) {
            final podcast = podcasts[i];
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
                  builder: (_) =>
                      LibraryPlaylistScreen.podcast(playlist: playlist),
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
      },
    );
  }
}

// ── Audiobook search results ──────────────────────────────────────────────────

class _AudiobookSearchResults extends ConsumerWidget {
  const _AudiobookSearchResults({required this.query});
  final String query;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hPad = AppTokens.of(context).isDesktop
        ? DesktopSpacing.lg
        : AppSpacing.base;
    if (query.isEmpty) {
      return SearchPageEmptyState(
        icon: AppIcon(
            icon: AppIcons.bookOpen,
            size: 56,
            color: AppColorsScheme.of(context).textMuted),
        heading: 'Search Audiobooks',
        subheading: 'Find audiobooks & long-form content',
      );
    }

    final resultsAsync = ref.watch(audiobookSearchResultsProvider(query));
    return resultsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => SearchPageEmptyState(
        icon: AppIcon(
            icon: AppIcons.search,
            size: 56,
            color: AppColorsScheme.of(context).textMuted),
        heading: 'Something went wrong',
        subheading: 'Could not load audiobook results',
      ),
      data: (audiobooks) {
        if (audiobooks.isEmpty) {
          return SearchPageEmptyState(
            icon: AppIcon(
                icon: AppIcons.bookOpen,
                size: 56,
                color: AppColorsScheme.of(context).textMuted),
            heading: 'No audiobooks found',
            subheading: 'Try a different search term',
          );
        }
        return ListView.builder(
          padding: EdgeInsets.only(bottom: 120, left: hPad, right: hPad),
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
                  builder: (_) =>
                      LibraryPlaylistScreen.podcast(playlist: playlist),
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
      },
    );
  }
}
