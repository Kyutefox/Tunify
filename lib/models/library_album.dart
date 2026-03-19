/// A followed album entry stored in the user's library.
class LibraryAlbum {
  final String id;
  final String title;
  final String artistName;
  final String thumbnailUrl;
  final String? browseId;
  final DateTime followedAt;

  const LibraryAlbum({
    required this.id,
    required this.title,
    required this.artistName,
    required this.thumbnailUrl,
    this.browseId,
    required this.followedAt,
  });

  factory LibraryAlbum.fromJson(Map<String, dynamic> json) {
    return LibraryAlbum(
      id: json['id'] as String,
      title: json['title'] as String? ?? '',
      artistName: json['artistName'] as String? ?? '',
      thumbnailUrl: json['thumbnailUrl'] as String? ?? '',
      browseId: json['browseId'] as String?,
      followedAt: json['followedAt'] != null
          ? DateTime.tryParse(json['followedAt'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'artistName': artistName,
        'thumbnailUrl': thumbnailUrl,
        'browseId': browseId,
        'followedAt': followedAt.toUtc().toIso8601String(),
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is LibraryAlbum && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
