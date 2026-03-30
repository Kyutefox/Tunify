import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tunify/core/constants/app_icons.dart';
import 'package:tunify/data/models/audiobook.dart';
import 'package:tunify/data/models/podcast.dart';
import 'package:tunify/features/podcast/podcast_provider.dart';
import 'package:tunify/ui/screens/shared/podcast/podcast_detail_screen.dart';
import 'package:tunify/ui/screens/shared/podcast/audiobook_detail_screen.dart';
import 'package:tunify/ui/screens/shared/podcast/podcast_search_screen.dart';
import 'package:tunify/ui/screens/shared/podcast/podcast_options_sheet.dart';
import 'package:tunify/ui/theme/app_colors.dart';
import 'package:tunify/ui/theme/app_colors_scheme.dart';
import 'package:tunify/ui/theme/design_tokens.dart';
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
    final subscriptions = ref.watch(podcastSubscriptionsProvider);

    if (subscriptions.isEmpty) {
      return _EmptyState(
        icon: AppIcons.podcast,
        title: 'No subscriptions yet',
        subtitle: 'Search for podcasts and subscribe to them here.',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(
          top: AppSpacing.sm, left: AppSpacing.base, right: AppSpacing.base, bottom: AppSpacing.xxl + 80),
      itemCount: subscriptions.length,
      itemBuilder: (context, i) {
        final podcast = subscriptions[i];
        return LibraryItemTile(
          title: podcast.title,
          subtitle: podcast.author ?? 'Podcast',
          thumbnailUrl: podcast.thumbnailUrl,
          placeholderIcon: AppIcons.podcast,
          showPinIndicator: podcast.isPinned,
          onTap: () => Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => PodcastDetailScreen(podcast: podcast),
          )),
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
  const _AudiobooksTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final audiobooks = ref.watch(savedAudiobooksProvider);

    if (audiobooks.isEmpty) {
      return _EmptyState(
        icon: AppIcons.bookOpen,
        title: 'No saved audiobooks',
        subtitle: 'Search for audiobooks and save them here.',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(
          top: AppSpacing.sm, left: AppSpacing.base, right: AppSpacing.base, bottom: AppSpacing.xxl + 80),
      itemCount: audiobooks.length,
      itemBuilder: (context, i) {
        final audiobook = audiobooks[i];
        return LibraryItemTile(
          title: audiobook.title,
          subtitle: audiobook.author ?? 'Audiobook',
          thumbnailUrl: audiobook.thumbnailUrl,
          placeholderIcon: AppIcons.bookOpen,
          showPinIndicator: audiobook.isPinned,
          onTap: () => Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => AudiobookDetailScreen(audiobook: audiobook),
          )),
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
            AppIcon(icon: icon, size: 56, color: AppColorsScheme.of(context).textMuted),
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
