import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tunify/v2/core/constants/app_border_radius.dart';
import 'package:tunify/v2/core/constants/app_colors.dart';
import 'package:tunify/v2/core/constants/app_icons.dart';
import 'package:tunify/v2/core/constants/app_spacing.dart';
import 'package:tunify/v2/core/theme/app_text_styles.dart';
import 'package:tunify/v2/core/widgets/art/artwork_or_gradient.dart';
import 'package:tunify/v2/features/library/presentation/navigation/open_library_detail.dart';
import 'package:tunify/v2/features/search/domain/entities/search_models.dart';
import 'package:tunify/v2/features/search/presentation/providers/search_providers.dart';

class SearchResultBody extends StatelessWidget {
  const SearchResultBody({
    super.key,
    required this.results,
    required this.isLoadingMore,
    required this.onLoadMore,
  });

  final SearchResultsData results;
  final bool isLoadingMore;
  final Future<void> Function() onLoadMore;

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (!results.hasMore || isLoadingMore) {
          return false;
        }
        if (notification.metrics.pixels >=
            notification.metrics.maxScrollExtent - 280) {
          onLoadMore();
        }
        return false;
      },
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg, AppSpacing.md, AppSpacing.lg, 120),
        children: [
          if (results.selectedFilter == SearchFilter.all &&
              results.topResult != null) ...[
            _TopResultItem(item: results.topResult!),
            const SizedBox(height: AppSpacing.xl),
          ],
          if (results.selectedFilter == SearchFilter.all &&
              results.featuringItems.isNotEmpty) ...[
            Text(
              'Featuring ${results.query}',
              style: AppTextStyles.featureHeading
                  .copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              height: 166,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemBuilder: (_, index) =>
                    _FeaturingCard(item: results.featuringItems[index]),
                separatorBuilder: (_, __) =>
                    const SizedBox(width: AppSpacing.lg),
                itemCount: results.featuringItems.length,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          ...results.items.map((item) => _ResultListItem(item: item)),
          if (isLoadingMore) ...[
            const SizedBox(height: AppSpacing.md),
            const Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.white,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class SearchRecentBody extends ConsumerWidget {
  const SearchRecentBody({super.key, required this.items});

  final List<SearchResultItem> items;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(searchRecentItemsProvider.notifier);
    return ListView(
      padding: const EdgeInsets.only(top: AppSpacing.md),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Text('Recent searches',
              style: AppTextStyles.featureHeading),
        ),
        const SizedBox(height: AppSpacing.md),
        ...items.map(
          (item) => InkWell(
            onTap: () => pushLibraryDetailFromSearch(context, item),
            child: SizedBox(
              height: item.kind == SearchItemKind.artist ? 74 : 64,
              child: Row(
                children: [
                  const SizedBox(width: AppSpacing.lg),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(
                      item.kind == SearchItemKind.artist
                          ? AppBorderRadius.fullPill
                          : AppBorderRadius.subtle,
                    ),
                    child: SizedBox(
                      width: 48,
                      height: 48,
                      child: ArtworkOrGradient(imageUrl: item.imageUrl),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.smMd),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                item.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyles.listItemTitle,
                              ),
                            ),
                            if (item.isVerified) ...[
                              const SizedBox(width: AppSpacing.sm),
                              AppIcon(
                                  icon: AppIcons.verified,
                                  color: AppColors.announcementBlue,
                                  size: 12),
                            ],
                          ],
                        ),
                        Text(item.subtitle, style: AppTextStyles.small),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: AppIcon(
                        icon: AppIcons.close,
                        size: 20,
                        color: AppColors.silver),
                    onPressed: () => notifier.remove(item.id),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class SearchSuggestionBody extends StatelessWidget {
  const SearchSuggestionBody({
    super.key,
    required this.suggestions,
    required this.simpleItems,
    required this.onSuggestionTap,
  });

  final List<String> suggestions;
  final List<SearchResultItem> simpleItems;
  final ValueChanged<String> onSuggestionTap;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.only(top: AppSpacing.md),
      children: [
        ...suggestions.map(
          (text) => InkWell(
            onTap: () => onSuggestionTap(text),
            child: SizedBox(
              height: 56,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: Row(
                  children: [
                    AppIcon(
                        icon: AppIcons.search,
                        color: AppColors.white,
                        size: 18),
                    const SizedBox(width: AppSpacing.lg),
                    Expanded(
                      child: Text(
                        text,
                        style: AppTextStyles.listItemTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    AppIcon(
                        icon: AppIcons.northWest,
                        size: 16,
                        color: AppColors.silver),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (simpleItems.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          ...simpleItems.take(8).map(
                (item) => Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                  child: _ResultListItem(item: item),
                ),
              ),
        ],
      ],
    );
  }
}

class SearchFocusEmptyBody extends StatelessWidget {
  const SearchFocusEmptyBody({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Play what you love',
            style: AppTextStyles.sectionTitle,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Search for artist, song, podcast and more.',
            style: AppTextStyles.small,
          ),
        ],
      ),
    );
  }
}

class SearchErrorBody extends StatelessWidget {
  const SearchErrorBody({
    super.key,
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message,
                style: AppTextStyles.small, textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.lg),
            OutlinedButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}

class _TopResultItem extends StatelessWidget {
  const _TopResultItem({required this.item});

  final SearchResultItem item;

  void _openDetail(BuildContext context) {
    pushLibraryDetailFromSearch(context, item);
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _openDetail(context),
      child: SizedBox(
        height: 64,
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(AppBorderRadius.fullPill),
              child: SizedBox(
                  width: 48,
                  height: 48,
                  child: ArtworkOrGradient(imageUrl: item.imageUrl)),
            ),
            const SizedBox(width: AppSpacing.smMd),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          item.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.listItemTitle,
                        ),
                      ),
                      if (item.isVerified) ...[
                        const SizedBox(width: 4),
                        AppIcon(
                            icon: AppIcons.verified,
                            color: AppColors.announcementBlue,
                            size: 12),
                      ],
                    ],
                  ),
                  Text(item.subtitle, style: AppTextStyles.small),
                ],
              ),
            ),
            OutlinedButton(
              onPressed: () => _openDetail(context),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.white),
                shape: const StadiumBorder(),
                minimumSize: const Size(0, 32),
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              ),
              child: Text(item.trailingText ?? 'Following',
                  style: AppTextStyles.smallBold),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeaturingCard extends StatelessWidget {
  const _FeaturingCard({required this.item});

  final SearchResultItem item;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => pushLibraryDetailFromSearch(context, item),
      child: SizedBox(
        width: 113,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
                width: 113,
                height: 113,
                child: ArtworkOrGradient(imageUrl: item.imageUrl)),
            const SizedBox(height: AppSpacing.md),
            Text(
              item.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style:
                  AppTextStyles.smallBold.copyWith(fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}

class _ResultListItem extends StatelessWidget {
  const _ResultListItem({required this.item});

  final SearchResultItem item;

  @override
  Widget build(BuildContext context) {
    final isArtist = item.kind == SearchItemKind.artist;
    return InkWell(
      onTap: () => pushLibraryDetailFromSearch(context, item),
      child: SizedBox(
        height: 64,
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(
                  isArtist ? AppBorderRadius.fullPill : AppBorderRadius.subtle),
              child: SizedBox(
                  width: 48,
                  height: 48,
                  child: ArtworkOrGradient(imageUrl: item.imageUrl)),
            ),
            const SizedBox(width: AppSpacing.smMd),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.listItemTitle,
                  ),
                  Text(
                    item.subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.small,
                  ),
                ],
              ),
            ),
            AppIcon(icon: AppIcons.chevronRight, color: AppColors.silver),
          ],
        ),
      ),
    );
  }
}
