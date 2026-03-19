/// Browse IDs resolved from a search query — used to navigate to artist or album pages.
///
/// Both fields are nullable; the resolution is best-effort and may return nulls.
class SearchBrowseIdsResult {
  const SearchBrowseIdsResult({
    this.artistBrowseId,
    this.albumBrowseId,
  });
  final String? artistBrowseId;
  final String? albumBrowseId;
}
