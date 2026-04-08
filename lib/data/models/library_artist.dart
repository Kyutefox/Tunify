/// A followed artist entry stored in the user's library.
class LibraryArtist {
  final String id;
  final String name;
  final String thumbnailUrl;
  final String? browseId;
  final DateTime followedAt;
  final int? cachedPaletteColor;
  final bool isPinned;

  const LibraryArtist({
    required this.id,
    required this.name,
    required this.thumbnailUrl,
    this.browseId,
    required this.followedAt,
    this.cachedPaletteColor,
    this.isPinned = false,
  });

  factory LibraryArtist.fromJson(Map<String, dynamic> json) {
    return LibraryArtist(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      thumbnailUrl: json['thumbnailUrl'] as String? ?? '',
      browseId: json['browseId'] as String?,
      followedAt: json['followedAt'] != null
          ? DateTime.tryParse(json['followedAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      cachedPaletteColor: json['cachedPaletteColor'] as int?,
      isPinned: json['isPinned'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'thumbnailUrl': thumbnailUrl,
        'browseId': browseId,
        'followedAt': followedAt.toUtc().toIso8601String(),
        if (cachedPaletteColor != null)
          'cachedPaletteColor': cachedPaletteColor,
        'isPinned': isPinned,
      };

  LibraryArtist copyWith({
    String? name,
    String? thumbnailUrl,
    int? cachedPaletteColor,
    bool? isPinned,
  }) =>
      LibraryArtist(
        id: id,
        name: name ?? this.name,
        thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
        browseId: browseId,
        followedAt: followedAt,
        cachedPaletteColor: cachedPaletteColor ?? this.cachedPaletteColor,
        isPinned: isPinned ?? this.isPinned,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is LibraryArtist && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
