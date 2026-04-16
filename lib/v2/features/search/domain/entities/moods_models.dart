class SearchMoodTile {
  const SearchMoodTile({
    required this.browseId,
    required this.title,
    this.params,
  });

  final String browseId;
  final String title;
  final String? params;
}
