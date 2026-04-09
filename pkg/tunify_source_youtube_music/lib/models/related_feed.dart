import 'package:tunify_source_youtube_music/models/track.dart';

/// Group of tracks representing a single shelf on the YouTube Music home feed.
class RelatedTrackShelf {
  /// Shelf title as shown in the UI (for example `"Quick picks"`).
  final String title;

  /// Optional shelf subtitle or strapline.
  final String? subtitle;

  /// Tracks that belong to this shelf, in display order.
  final List<Track> tracks;

  /// Creates a new [RelatedTrackShelf] with the given [title], optional
  /// [subtitle] and list of [tracks].
  const RelatedTrackShelf({
    required this.title,
    this.subtitle,
    this.tracks = const [],
  });

  /// Serialises this shelf to a JSON‑compatible map.
  Map<String, dynamic> toJson() => {
        'title': title,
        'subtitle': subtitle,
        'tracks': tracks.map((e) => e.toJson()).toList(),
      };
}

/// Group of playlists representing a single shelf on the home feed.
class RelatedPlaylistShelf {
  /// Shelf title as shown in the UI.
  final String title;

  /// Optional shelf subtitle or strapline.
  final String? subtitle;

  /// Playlists that belong to this shelf.
  final List<RelatedPlaylist> playlists;

  /// Creates a new [RelatedPlaylistShelf] with the given [title], optional
  /// [subtitle] and list of [playlists].
  const RelatedPlaylistShelf({
    required this.title,
    this.subtitle,
    this.playlists = const [],
  });

  /// Serialises this shelf to a JSON‑compatible map.
  Map<String, dynamic> toJson() => {
        'title': title,
        'subtitle': subtitle,
        'playlists': playlists.map((e) => e.toJson()).toList(),
      };
}

/// Group of artists representing a single shelf on the home feed.
class RelatedArtistShelf {
  /// Shelf title as shown in the UI.
  final String title;

  /// Optional shelf subtitle or strapline.
  final String? subtitle;

  /// Artists that belong to this shelf.
  final List<RelatedArtist> artists;

  /// Creates a new [RelatedArtistShelf] with the given [title], optional
  /// [subtitle] and list of [artists].
  const RelatedArtistShelf({
    required this.title,
    this.subtitle,
    this.artists = const [],
  });

  /// Serialises this shelf to a JSON‑compatible map.
  Map<String, dynamic> toJson() => {
        'title': title,
        'subtitle': subtitle,
        'artists': artists.map((e) => e.toJson()).toList(),
      };
}

/// Lightweight playlist reference extracted from YouTube Music shelves.
class RelatedPlaylist {
  /// Playlist or album browse ID (for example `VL` or `MPREb_` prefixes).
  final String id;

  /// Playlist title.
  final String title;

  /// Thumbnail URL representing the playlist.
  final String thumbnailUrl;

  /// Optional curator/channel name associated with the playlist.
  final String? curatorName;

  /// Approximate number of tracks in the playlist, when known.
  final int? trackCount;

  /// Creates a new [RelatedPlaylist] summary.
  const RelatedPlaylist({
    required this.id,
    required this.title,
    required this.thumbnailUrl,
    this.curatorName,
    this.trackCount,
  });

  /// Serialises this playlist to a JSON‑compatible map.
  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'thumbnailUrl': thumbnailUrl,
        'curatorName': curatorName,
        'trackCount': trackCount,
      };
}

/// Lightweight artist reference extracted from YouTube Music shelves.
class RelatedArtist {
  /// Artist channel or browse ID.
  final String id;

  /// Display name of the artist.
  final String name;

  /// Thumbnail URL representing the artist.
  final String thumbnailUrl;

  /// Optional subtitle (for example `"Artist"` or `"Topic"`).
  final String? subtitle;

  /// Creates a new [RelatedArtist] summary.
  const RelatedArtist({
    required this.id,
    required this.name,
    required this.thumbnailUrl,
    this.subtitle,
  });

  /// Serialises this artist to a JSON‑compatible map.
  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'thumbnailUrl': thumbnailUrl,
        'subtitle': subtitle,
      };
}

/// Generic home shelf with optional browse ID and params for navigation.
class RelatedHomeShelf {
  /// Shelf title as shown in the UI.
  final String title;

  /// Optional shelf subtitle or strapline.
  final String? subtitle;

  /// Optional browse ID that can be used to navigate back to this shelf.
  final String? browseId;

  /// Optional additional parameters required to reproduce the shelf.
  final String? params;

  /// Creates a new [RelatedHomeShelf] descriptor.
  const RelatedHomeShelf({
    required this.title,
    this.subtitle,
    this.browseId,
    this.params,
  });

  /// Serialises this shelf descriptor to a JSON‑compatible map.
  Map<String, dynamic> toJson() => {
        'title': title,
        'subtitle': subtitle,
        'browseId': browseId,
        'params': params,
      };
}

/// Mood or genre chip used to filter the home feed or explore page.
class RelatedMoodItem {
  /// Display title of the mood/genre (for example `"Workout"`).
  final String title;

  /// Browse ID that should be used when navigating to this mood or genre.
  final String browseId;

  /// Optional additional parameters required for the browse request.
  final String? params;

  /// Optional section label this chip belongs to (for example `"Moods & genres"`).
  final String? sectionTitle;

  /// Creates a new [RelatedMoodItem] descriptor.
  const RelatedMoodItem({
    required this.title,
    required this.browseId,
    this.params,
    this.sectionTitle,
  });

  /// Serialises this mood/genre item to a JSON‑compatible map.
  Map<String, dynamic> toJson() => {
        'title': title,
        'browseId': browseId,
        'params': params,
        'sectionTitle': sectionTitle,
      };
}

/// Result of fetching a mood or genre detail page.
class MoodDetailResult {
  /// Sub‑categories (chips) that refine the selected mood or genre.
  final List<RelatedMoodItem> subCategories;

  /// Playlists associated with the selected mood or genre.
  final List<MoodPlaylist> playlists;

  /// Creates a new [MoodDetailResult] with optional [subCategories] and
  /// [playlists].
  const MoodDetailResult({
    this.subCategories = const [],
    this.playlists = const [],
  });

  /// Serialises this result to a JSON‑compatible map.
  Map<String, dynamic> toJson() => {
        'subCategories': subCategories.map((e) => e.toJson()).toList(),
        'playlists': playlists.map((e) => e.toJson()).toList(),
      };
}

/// Playlist entry shown on a mood or genre detail page.
class MoodPlaylist {
  /// Playlist or album browse ID.
  final String id;

  /// Playlist title.
  final String title;

  /// Thumbnail URL representing the playlist.
  final String thumbnailUrl;

  /// Optional subtitle, typically describing curator or track count.
  final String? subtitle;

  /// Creates a new [MoodPlaylist] summary.
  const MoodPlaylist({
    required this.id,
    required this.title,
    required this.thumbnailUrl,
    this.subtitle,
  });

  /// Serialises this playlist to a JSON‑compatible map.
  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'thumbnailUrl': thumbnailUrl,
        'subtitle': subtitle,
      };
}

/// Aggregated home feed payload combining tracks, playlists, artists and moods.
class RelatedHomeFeed {
  /// Track shelves available on the home feed.
  final List<RelatedTrackShelf> trackShelves;

  /// Playlist shelves available on the home feed.
  final List<RelatedPlaylistShelf> playlistShelves;

  /// Artist shelves available on the home feed.
  final List<RelatedArtistShelf> artistShelves;

  /// Generic shelves that do not fall into track/playlist/artist categories.
  final List<RelatedHomeShelf> shelves;

  /// Mood and genre items associated with the feed.
  final List<RelatedMoodItem> moodItems;

  /// Creates a new [RelatedHomeFeed] aggregate.
  const RelatedHomeFeed({
    this.trackShelves = const [],
    this.playlistShelves = const [],
    this.artistShelves = const [],
    this.shelves = const [],
    this.moodItems = const [],
  });

  /// Serialises this feed to a JSON‑compatible map.
  Map<String, dynamic> toJson() => {
        'trackShelves': trackShelves.map((e) => e.toJson()).toList(),
        'playlistShelves': playlistShelves.map((e) => e.toJson()).toList(),
        'artistShelves': artistShelves.map((e) => e.toJson()).toList(),
        'shelves': shelves.map((e) => e.toJson()).toList(),
        'moodItems': moodItems.map((e) => e.toJson()).toList(),
      };
}
