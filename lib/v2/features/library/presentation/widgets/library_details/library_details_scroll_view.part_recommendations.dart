part of 'library_details_scroll_view.dart';

/// Reuses [HomeCarouselShelf] (same cards / spacing as home) for Tunify browse shelves.
class _BrowseRecommendationShelvesSection extends StatelessWidget {
  const _BrowseRecommendationShelvesSection({
    required this.shelves,
  });

  final List<LibraryBrowseRecommendationShelf> shelves;

  @override
  Widget build(BuildContext context) {
    if (shelves.isEmpty) {
      return const SizedBox.shrink();
    }
    final carousels = <Widget>[];
    for (final shelf in shelves) {
      final section =
          LibraryBrowseRecommendationCarouselMapper.toCarouselSection(shelf);
      if (section != null) {
        carousels.add(HomeCarouselShelf(section: section));
      }
    }
    if (carousels.isEmpty) {
      return const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        ...carousels,
      ],
    );
  }
}
