import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tunify/core/constants/app_icons.dart';
import 'package:tunify/data/models/audiobook.dart';
import 'package:tunify/data/models/podcast.dart';
import 'package:tunify/features/podcast/podcast_provider.dart';
import 'package:tunify/ui/screens/shared/podcast/podcast_detail_screen.dart';
import 'package:tunify/ui/screens/shared/podcast/audiobook_detail_screen.dart';
import 'package:tunify/ui/screens/shared/search/search_page.dart';
import 'package:tunify/ui/theme/app_colors.dart';
import 'package:tunify/ui/theme/app_colors_scheme.dart';
import 'package:tunify/ui/theme/design_tokens.dart';

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
    if (query.isEmpty) {
      return SearchPageEmptyState(
        icon: AppIcon(icon: AppIcons.podcast, size: 56, color: AppColorsScheme.of(context).textMuted),
        heading: 'Search Podcasts',
        subheading: 'Find podcast episodes, interviews & talks',
      );
    }

    final resultsAsync = ref.watch(podcastSearchResultsProvider(query));
    return resultsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => SearchPageEmptyState(
        icon: AppIcon(icon: AppIcons.search, size: 56, color: AppColorsScheme.of(context).textMuted),
        heading: 'Something went wrong',
        subheading: 'Could not load podcast results',
      ),
      data: (podcasts) {
        if (podcasts.isEmpty) {
          return SearchPageEmptyState(
            icon: AppIcon(icon: AppIcons.podcast, size: 56, color: AppColorsScheme.of(context).textMuted),
            heading: 'No podcasts found',
            subheading: 'Try a different search term',
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.only(bottom: 120),
          itemCount: podcasts.length,
          itemBuilder: (context, i) => _PodcastResultTile(
            podcast: podcasts[i],
            onTap: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => PodcastDetailScreen(podcast: podcasts[i]),
            )),
          ),
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
    if (query.isEmpty) {
      return SearchPageEmptyState(
        icon: AppIcon(icon: AppIcons.bookOpen, size: 56, color: AppColorsScheme.of(context).textMuted),
        heading: 'Search Audiobooks',
        subheading: 'Find audiobooks & long-form content',
      );
    }

    final resultsAsync = ref.watch(audiobookSearchResultsProvider(query));
    return resultsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => SearchPageEmptyState(
        icon: AppIcon(icon: AppIcons.search, size: 56, color: AppColorsScheme.of(context).textMuted),
        heading: 'Something went wrong',
        subheading: 'Could not load audiobook results',
      ),
      data: (audiobooks) {
        if (audiobooks.isEmpty) {
          return SearchPageEmptyState(
            icon: AppIcon(icon: AppIcons.bookOpen, size: 56, color: AppColorsScheme.of(context).textMuted),
            heading: 'No audiobooks found',
            subheading: 'Try a different search term',
          );
        }
        return GridView.builder(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.base, AppSpacing.sm, AppSpacing.base, 120),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.72,
            crossAxisSpacing: AppSpacing.sm,
            mainAxisSpacing: AppSpacing.sm,
          ),
          itemCount: audiobooks.length,
          itemBuilder: (context, i) => _AudiobookResultCard(
            audiobook: audiobooks[i],
            onTap: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => AudiobookDetailScreen(audiobook: audiobooks[i]),
            )),
          ),
        );
      },
    );
  }
}

// ── Result tiles ──────────────────────────────────────────────────────────────

class _PodcastResultTile extends ConsumerWidget {
  const _PodcastResultTile({required this.podcast, required this.onTap});
  final Podcast podcast;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSubscribed =
        ref.watch(podcastProvider.select((s) => s.isSubscribed(podcast.id)));

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.base, vertical: AppSpacing.xs),
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: podcast.thumbnailUrl != null
            ? CachedNetworkImage(
                imageUrl: podcast.thumbnailUrl!,
                width: 56,
                height: 56,
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) => _IconPlaceholder(
                    icon: AppIcons.podcast, size: 56),
              )
            : _IconPlaceholder(icon: AppIcons.podcast, size: 56),
      ),
      title: Text(
        podcast.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: AppColorsScheme.of(context).textPrimary,
          fontWeight: FontWeight.w600,
          fontSize: AppFontSize.md,
        ),
      ),
      subtitle: podcast.author != null
          ? Text(
              podcast.author!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  color: AppColorsScheme.of(context).textMuted,
                  fontSize: AppFontSize.sm),
            )
          : null,
      trailing: isSubscribed
          ? AppIcon(
              icon: AppIcons.checkCircle,
              size: 20,
              color: AppColors.primary,
            )
          : null,
      onTap: onTap,
    );
  }
}

class _AudiobookResultCard extends StatelessWidget {
  const _AudiobookResultCard(
      {required this.audiobook, required this.onTap});
  final Audiobook audiobook;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.md),
              child: audiobook.thumbnailUrl != null
                  ? CachedNetworkImage(
                      imageUrl: audiobook.thumbnailUrl!,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) =>
                          _IconPlaceholder(icon: AppIcons.bookOpen, size: 80),
                    )
                  : _IconPlaceholder(icon: AppIcons.bookOpen, size: 80),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            audiobook.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: AppColorsScheme.of(context).textPrimary,
              fontWeight: FontWeight.w600,
              fontSize: AppFontSize.sm,
            ),
          ),
          if (audiobook.author != null)
            Text(
              audiobook.author!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  color: AppColorsScheme.of(context).textMuted,
                  fontSize: AppFontSize.xs),
            ),
        ],
      ),
    );
  }
}

class _IconPlaceholder extends StatelessWidget {
  const _IconPlaceholder({required this.icon, required this.size});
  final List<List<dynamic>> icon;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      color: AppColorsScheme.of(context).surfaceHighlight,
      child: Center(
        child: AppIcon(
          icon: icon,
          size: size * 0.4,
          color: AppColorsScheme.of(context).textMuted,
        ),
      ),
    );
  }
}
