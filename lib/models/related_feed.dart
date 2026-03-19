import 'track.dart';

/// A titled group of related tracks from the home feed or "Next Up" API response.
class RelatedTrackShelf {
  final String title;
  final String? subtitle;
  final List<Track> tracks;

  const RelatedTrackShelf({
    required this.title,
    this.subtitle,
    this.tracks = const [],
  });

  Map<String, dynamic> toJson() => {
        'title': title,
        'subtitle': subtitle,
        'tracks': tracks.map((e) => e.toJson()).toList(),
      };
}

/// A titled group of related playlists from the home feed.
class RelatedPlaylistShelf {
  final String title;
  final String? subtitle;
  final List<RelatedPlaylist> playlists;

  const RelatedPlaylistShelf({
    required this.title,
    this.subtitle,
    this.playlists = const [],
  });

  Map<String, dynamic> toJson() => {
        'title': title,
        'subtitle': subtitle,
        'playlists': playlists.map((e) => e.toJson()).toList(),
      };
}

/// A titled group of related artists from the home feed.
class RelatedArtistShelf {
  final String title;
  final String? subtitle;
  final List<RelatedArtist> artists;

  const RelatedArtistShelf({
    required this.title,
    this.subtitle,
    this.artists = const [],
  });

  Map<String, dynamic> toJson() => {
        'title': title,
        'subtitle': subtitle,
        'artists': artists.map((e) => e.toJson()).toList(),
      };
}

/// Minimal playlist representation as returned inside a [RelatedPlaylistShelf].
class RelatedPlaylist {
  final String id;
  final String title;
  final String thumbnailUrl;
  final String? curatorName;
  final int? trackCount;

  const RelatedPlaylist({
    required this.id,
    required this.title,
    required this.thumbnailUrl,
    this.curatorName,
    this.trackCount,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'thumbnailUrl': thumbnailUrl,
        'curatorName': curatorName,
        'trackCount': trackCount,
      };
}

/// Minimal artist representation as returned inside a [RelatedArtistShelf].
class RelatedArtist {
  final String id;
  final String name;
  final String thumbnailUrl;
  final String? subtitle;

  const RelatedArtist({
    required this.id,
    required this.name,
    required this.thumbnailUrl,
    this.subtitle,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'thumbnailUrl': thumbnailUrl,
        'subtitle': subtitle,
      };
}

/// A generic browsable shelf from the home feed (title + optional [browseId]/[params] for navigation).
class RelatedHomeShelf {
  final String title;
  final String? subtitle;
  final String? browseId;
  final String? params;

  const RelatedHomeShelf({
    required this.title,
    this.subtitle,
    this.browseId,
    this.params,
  });

  Map<String, dynamic> toJson() => {
        'title': title,
        'subtitle': subtitle,
        'browseId': browseId,
        'params': params,
      };
}

/// A mood or genre category item from the YouTube Music mood shelf, with a browse ID for deeper navigation.
class RelatedMoodItem {
  final String title;
  final String browseId;
  final String? params;
  final String? sectionTitle;

  const RelatedMoodItem({
    required this.title,
    required this.browseId,
    this.params,
    this.sectionTitle,
  });

  Map<String, dynamic> toJson() => {
        'title': title,
        'browseId': browseId,
        'params': params,
        'sectionTitle': sectionTitle,
      };
}

/// Result of browsing a mood category: sub-categories and featured playlists.
class MoodDetailResult {
  final List<RelatedMoodItem> subCategories;
  final List<MoodPlaylist> playlists;

  const MoodDetailResult({
    this.subCategories = const [],
    this.playlists = const [],
  });

  Map<String, dynamic> toJson() => {
        'subCategories': subCategories.map((e) => e.toJson()).toList(),
        'playlists': playlists.map((e) => e.toJson()).toList(),
      };
}

/// A playlist displayed within a mood detail page.
class MoodPlaylist {
  final String id;
  final String title;
  final String thumbnailUrl;
  final String? subtitle;

  const MoodPlaylist({
    required this.id,
    required this.title,
    required this.thumbnailUrl,
    this.subtitle,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'thumbnailUrl': thumbnailUrl,
        'subtitle': subtitle,
      };
}

/// Aggregated home feed response containing track shelves, playlist shelves,
/// artist shelves, generic shelves, and mood items.
///
/// The convenience getters [tracks], [playlists], and [artists] flatten the
/// respective shelf lists for cases where shelf grouping is not needed.
class RelatedHomeFeed {
  final List<RelatedTrackShelf> trackShelves;
  final List<RelatedPlaylistShelf> playlistShelves;
  final List<RelatedArtistShelf> artistShelves;
  final List<RelatedHomeShelf> shelves;
  final List<RelatedMoodItem> moodItems;

  const RelatedHomeFeed({
    this.trackShelves = const [],
    this.playlistShelves = const [],
    this.artistShelves = const [],
    this.shelves = const [],
    this.moodItems = const [],
  });

  /// Flattened list of all tracks from track shelves.
  List<Track> get tracks =>
      trackShelves.expand((s) => s.tracks).toList();

  /// Flattened list of all playlists from playlist shelves.
  List<RelatedPlaylist> get playlists =>
      playlistShelves.expand((s) => s.playlists).toList();

  /// Flattened list of all artists from artist shelves.
  List<RelatedArtist> get artists =>
      artistShelves.expand((s) => s.artists).toList();

  Map<String, dynamic> toJson() => {
    'trackShelves': trackShelves.map((e) => e.toJson()).toList(),
    'playlistShelves': playlistShelves.map((e) => e.toJson()).toList(),
    'artistShelves': artistShelves.map((e) => e.toJson()).toList(),
    'shelves': shelves.map((e) => e.toJson()).toList(),
    'moodItems': moodItems.map((e) => e.toJson()).toList(),
  };
}