/// Lightweight playlist metadata — title, author, thumbnail, and track count.
///
/// Used when full track lists are not yet loaded (e.g., search results, sidebar).
class PlaylistInfo {
  final String id;
  final String title;
  final String author;
  final String description;
  final String thumbnailUrl;
  final int videoCount;

  const PlaylistInfo({
    required this.id,
    required this.title,
    required this.author,
    required this.description,
    required this.thumbnailUrl,
    required this.videoCount,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PlaylistInfo &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'PlaylistInfo($id: $title by $author)';
}