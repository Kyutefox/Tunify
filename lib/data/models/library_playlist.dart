import 'package:tunify/core/utils/json_string_mixin.dart';
import 'package:tunify/data/models/song.dart';

/// Sort order applied to the track list inside a [LibraryPlaylist].
enum PlaylistTrackSortOrder {
  /// User-defined drag-drop ordering (default).
  customOrder,
  /// Alphabetical by track title.
  title,
  /// Most recently added tracks first (reversal of insertion order).
  recentlyAdded,
}

/// Serialization helpers for [PlaylistTrackSortOrder].
extension PlaylistTrackSortOrderX on PlaylistTrackSortOrder {
  String get value {
    switch (this) {
      case PlaylistTrackSortOrder.customOrder:
        return 'customOrder';
      case PlaylistTrackSortOrder.title:
        return 'title';
      case PlaylistTrackSortOrder.recentlyAdded:
        return 'recentlyAdded';
    }
  }

  static PlaylistTrackSortOrder fromString(String? s) {
    switch (s) {
      case 'title':
        return PlaylistTrackSortOrder.title;
      case 'recentlyAdded':
        return PlaylistTrackSortOrder.recentlyAdded;
      default:
        return PlaylistTrackSortOrder.customOrder;
    }
  }
}

/// A user-created playlist stored in the local library.
///
/// Differs from the API [Playlist] type: carries ownership metadata
/// (createdAt, updatedAt, shuffle, pin) and is persisted to SQLite + Supabase.
class LibraryPlaylist {
  final String id;
  final String name;
  final String description;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<Song> songs;
  final PlaylistTrackSortOrder sortOrder;
  final bool shuffleEnabled;
  final bool isPinned;
  /// Custom cover image URL (user-selected); null uses first track art.
  final String? customImageUrl;
  /// True when this playlist was saved from a remote source (e.g. home page).
  /// Remote-saved playlists always re-fetch fresh data when opened and are not editable.
  final bool isImported;
  /// Browse ID used to re-fetch remote playlist data. Only set for [isImported] playlists.
  final String? browseId;
  /// Cached palette color (ARGB int) extracted from the cover image.
  /// Stored so the gradient shows instantly on re-open without re-extraction.
  final int? cachedPaletteColor;
  /// Track count from the remote API, stored at import time.
  /// Used as a fallback display value for imported playlists whose songs are
  /// not persisted locally (songs list stays empty between sessions).
  final int? remoteTrackCount;

  const LibraryPlaylist({
    required this.id,
    required this.name,
    this.description = '',
    required this.createdAt,
    required this.updatedAt,
    this.songs = const [],
    this.sortOrder = PlaylistTrackSortOrder.customOrder,
    this.shuffleEnabled = false,
    this.isPinned = false,
    this.customImageUrl,
    this.isImported = false,
    this.browseId,
    this.cachedPaletteColor,
    this.remoteTrackCount,
  });

  /// For imported playlists, songs are not persisted — fall back to the
  /// remote count stored at import time so the library tile shows a real number.
  int get trackCount => songs.isNotEmpty
      ? songs.length
      : (isImported ? (remoteTrackCount ?? 0) : 0);

  String get trackCountLabel =>
      trackCount == 1 ? '1 song' : '$trackCount songs';

  LibraryPlaylist copyWith({
    String? id,
    String? name,
    String? description,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<Song>? songs,
    PlaylistTrackSortOrder? sortOrder,
    bool? shuffleEnabled,
    bool? isPinned,
    String? customImageUrl,
    bool? isImported,
    String? browseId,
    int? cachedPaletteColor,
    int? remoteTrackCount,
  }) {
    return LibraryPlaylist(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      songs: songs ?? this.songs,
      sortOrder: sortOrder ?? this.sortOrder,
      shuffleEnabled: shuffleEnabled ?? this.shuffleEnabled,
      isPinned: isPinned ?? this.isPinned,
      customImageUrl: customImageUrl ?? this.customImageUrl,
      isImported: isImported ?? this.isImported,
      browseId: browseId ?? this.browseId,
      cachedPaletteColor: cachedPaletteColor ?? this.cachedPaletteColor,
      remoteTrackCount: remoteTrackCount ?? this.remoteTrackCount,
    );
  }

  /// Songs ordered according to [sortOrder].
  ///
  /// Always returns a new list — callers may mutate it without affecting [songs].
  List<Song> get sortedSongs {
    switch (sortOrder) {
      case PlaylistTrackSortOrder.title:
        final list = List<Song>.from(songs);
        list.sort(
            (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
        return list;
      case PlaylistTrackSortOrder.recentlyAdded:
        return songs.reversed.toList();
      case PlaylistTrackSortOrder.customOrder:
        return List<Song>.from(songs);
    }
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'songs': songs.map((s) => s.toJson()).toList(),
        'sortOrder': sortOrder.value,
        'shuffleEnabled': shuffleEnabled,
        'isPinned': isPinned,
        if (customImageUrl != null) 'customImageUrl': customImageUrl,
        'isImported': isImported,
        if (browseId != null) 'browseId': browseId,
        if (cachedPaletteColor != null) 'cachedPaletteColor': cachedPaletteColor,
        if (remoteTrackCount != null) 'remoteTrackCount': remoteTrackCount,
      };

  factory LibraryPlaylist.fromJson(Map<String, dynamic> json) {
    final songsList = json['songs'] as List<dynamic>?;
    final songs = songsList
            ?.map((e) => Song.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];
    return LibraryPlaylist(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      songs: songs,
      sortOrder:
          PlaylistTrackSortOrderX.fromString(json['sortOrder'] as String?),
      shuffleEnabled: json['shuffleEnabled'] as bool? ?? false,
      isPinned: json['isPinned'] as bool? ?? false,
      customImageUrl: json['customImageUrl'] as String?,
      isImported: json['isImported'] as bool? ?? false,
      browseId: json['browseId'] as String?,
      cachedPaletteColor: json['cachedPaletteColor'] as int?,
      remoteTrackCount: json['remoteTrackCount'] as int?,
    );
  }

  static LibraryPlaylist? fromJsonString(String? s) =>
      parseJsonString(s, LibraryPlaylist.fromJson);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LibraryPlaylist &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          songs.length == other.songs.length &&
          updatedAt == other.updatedAt &&
          sortOrder == other.sortOrder;

  @override
  int get hashCode => Object.hash(id, songs.length, updatedAt, sortOrder);

  @override
  String toString() => 'LibraryPlaylist($id: $name)';
}
