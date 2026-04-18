enum SearchFilter {
  all,
  artists,
  albums,
  playlists,
  songs,
  podcasts,
}

enum SearchItemKind {
  artist,
  album,
  playlist,
  song,
  podcast,
  episode,
  audiobook,
  profile,
}

class SearchResultItem {
  const SearchResultItem({
    required this.id,
    required this.kind,
    required this.title,
    required this.subtitle,
    required this.imageUrl,
    this.trailingText,
    this.isVerified = false,
    this.videoId,
  });

  final String id;
  final SearchItemKind kind;
  final String title;
  final String subtitle;
  final String? imageUrl;
  final String? trailingText;
  final bool isVerified;
  final String? videoId;
}

class SearchResultsData {
  const SearchResultsData({
    required this.query,
    required this.selectedFilter,
    required this.topResult,
    required this.featuringItems,
    required this.items,
    this.continuation,
  });

  final String query;
  final SearchFilter selectedFilter;
  final SearchResultItem? topResult;
  final List<SearchResultItem> featuringItems;
  final List<SearchResultItem> items;
  final String? continuation;

  bool get hasMore => continuation != null && continuation!.isNotEmpty;

  SearchResultsData copyWith({
    String? query,
    SearchFilter? selectedFilter,
    SearchResultItem? topResult,
    bool clearTopResult = false,
    List<SearchResultItem>? featuringItems,
    List<SearchResultItem>? items,
    String? continuation,
    bool clearContinuation = false,
  }) {
    return SearchResultsData(
      query: query ?? this.query,
      selectedFilter: selectedFilter ?? this.selectedFilter,
      topResult: clearTopResult ? null : (topResult ?? this.topResult),
      featuringItems: featuringItems ?? this.featuringItems,
      items: items ?? this.items,
      continuation:
          clearContinuation ? null : (continuation ?? this.continuation),
    );
  }
}

class SearchTypingData {
  const SearchTypingData({
    required this.query,
    required this.suggestions,
    required this.items,
  });

  final String query;
  final List<String> suggestions;
  final List<SearchResultItem> items;
}
