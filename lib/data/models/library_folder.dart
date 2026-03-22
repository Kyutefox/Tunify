import 'dart:convert';

/// A named folder that groups [LibraryPlaylist] IDs for organizational purposes.
class LibraryFolder {
  final String id;
  final String name;
  final List<String> playlistIds;
  final DateTime createdAt;
  final bool isPinned;

  const LibraryFolder({
    required this.id,
    required this.name,
    this.playlistIds = const [],
    required this.createdAt,
    this.isPinned = false,
  });

  int get playlistCount => playlistIds.length;

  LibraryFolder copyWith({
    String? id,
    String? name,
    List<String>? playlistIds,
    DateTime? createdAt,
    bool? isPinned,
  }) {
    return LibraryFolder(
      id: id ?? this.id,
      name: name ?? this.name,
      playlistIds: playlistIds ?? this.playlistIds,
      createdAt: createdAt ?? this.createdAt,
      isPinned: isPinned ?? this.isPinned,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LibraryFolder &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          playlistIds == other.playlistIds;

  @override
  int get hashCode => Object.hash(id, name, playlistIds);

  @override
  String toString() => 'LibraryFolder($id: $name)';

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'playlistIds': playlistIds,
        'createdAt': createdAt.toIso8601String(),
        'isPinned': isPinned,
      };

  factory LibraryFolder.fromJson(Map<String, dynamic> json) {
    final ids = json['playlistIds'] as List<dynamic>?;
    return LibraryFolder(
      id: json['id'] as String,
      name: json['name'] as String,
      playlistIds: ids?.map((e) => e as String).toList() ?? [],
      createdAt: DateTime.parse(json['createdAt'] as String),
      isPinned: json['isPinned'] as bool? ?? false,
    );
  }

  static LibraryFolder? fromJsonString(String? s) {
    if (s == null || s.isEmpty) return null;
    try {
      return LibraryFolder.fromJson(jsonDecode(s) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }
}
