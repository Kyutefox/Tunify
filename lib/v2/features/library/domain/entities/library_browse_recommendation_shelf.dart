import 'package:flutter/foundation.dart';

@immutable
class BrowseRecPlaylist {
  const BrowseRecPlaylist({
    required this.id,
    required this.title,
    this.subtitle,
    this.artworkUrl,
  });

  final String id;
  final String title;
  final String? subtitle;
  final String? artworkUrl;

  factory BrowseRecPlaylist.fromJson(Map<String, dynamic> json) {
    return BrowseRecPlaylist(
      id: (json['id'] as String?)?.trim() ?? '',
      title: (json['title'] as String?)?.trim() ?? '',
      subtitle: (json['subtitle'] as String?)?.trim(),
      artworkUrl: (json['artwork_url'] as String?)?.trim(),
    );
  }
}

@immutable
class BrowseRecArtist {
  const BrowseRecArtist({
    required this.id,
    required this.name,
    this.artworkUrl,
  });

  final String id;
  final String name;
  final String? artworkUrl;

  factory BrowseRecArtist.fromJson(Map<String, dynamic> json) {
    return BrowseRecArtist(
      id: (json['id'] as String?)?.trim() ?? '',
      name: (json['name'] as String?)?.trim() ?? '',
      artworkUrl: (json['artwork_url'] as String?)?.trim(),
    );
  }
}

@immutable
class BrowseRecAlbum {
  const BrowseRecAlbum({
    required this.id,
    required this.title,
    this.subtitle,
    this.artworkUrl,
  });

  final String id;
  final String title;
  final String? subtitle;
  final String? artworkUrl;

  factory BrowseRecAlbum.fromJson(Map<String, dynamic> json) {
    return BrowseRecAlbum(
      id: (json['id'] as String?)?.trim() ?? '',
      title: (json['title'] as String?)?.trim() ?? '',
      subtitle: (json['subtitle'] as String?)?.trim(),
      artworkUrl: (json['artwork_url'] as String?)?.trim(),
    );
  }
}

/// One recommendation carousel from Tunify `POST /v1/browse` `parsed.recommendation_shelves`.
///
/// Payload matches Rust [CollectionRecommendationShelf] (`tracks` are [FeedItem]s; we map
/// playlists / artists / albums through [HomeCarouselShelf] like home carousels).
@immutable
class LibraryBrowseRecommendationShelf {
  const LibraryBrowseRecommendationShelf({
    required this.title,
    this.subtitle,
    this.playlists = const [],
    this.artists = const [],
    this.albums = const [],
  });

  final String title;
  final String? subtitle;
  final List<BrowseRecPlaylist> playlists;
  final List<BrowseRecArtist> artists;
  final List<BrowseRecAlbum> albums;

  bool get isEmptyForCarousel =>
      playlists.isEmpty && artists.isEmpty && albums.isEmpty;

  factory LibraryBrowseRecommendationShelf.fromJson(Map<String, dynamic> json) {
    final playlists = (json['playlists'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(BrowseRecPlaylist.fromJson)
        .where((p) => p.id.isNotEmpty && p.title.isNotEmpty)
        .toList(growable: false);
    final artists = (json['artists'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(BrowseRecArtist.fromJson)
        .where((a) => a.id.isNotEmpty && a.name.isNotEmpty)
        .toList(growable: false);
    final albums = (json['albums'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(BrowseRecAlbum.fromJson)
        .where((a) => a.id.isNotEmpty && a.title.isNotEmpty)
        .toList(growable: false);
    return LibraryBrowseRecommendationShelf(
      title: (json['title'] as String?)?.trim() ?? '',
      subtitle: (json['subtitle'] as String?)?.trim(),
      playlists: playlists,
      artists: artists,
      albums: albums,
    );
  }
}
