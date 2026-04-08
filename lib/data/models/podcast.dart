import 'package:tunify/data/models/song.dart';

/// A podcast show with episodes that can be subscribed to and played.
///
/// Podcasts differ from regular playlists in that episodes are released
/// periodically and playback positions are tracked individually.
class Podcast {
  const Podcast({
    required this.id,
    required this.title,
    this.description,
    this.thumbnailUrl,
    this.author,
    this.episodes = const [],
    this.totalEpisodes,
    this.browseId,
    this.isPinned = false,
  });

  final String id;
  final String title;
  final String? description;
  final String? thumbnailUrl;
  final String? author;
  final List<Episode> episodes;
  final int? totalEpisodes;
  final String? browseId;
  final bool isPinned;

  factory Podcast.fromJson(Map<String, dynamic> json) => Podcast(
        id: json['id'] as String,
        title: json['title'] as String,
        description: json['description'] as String?,
        thumbnailUrl: json['thumbnailUrl'] as String?,
        author: json['author'] as String?,
        browseId: json['browseId'] as String?,
        isPinned: json['isPinned'] as bool? ?? false,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        if (description != null) 'description': description,
        if (thumbnailUrl != null) 'thumbnailUrl': thumbnailUrl,
        if (author != null) 'author': author,
        if (browseId != null) 'browseId': browseId,
        'isPinned': isPinned,
      };

  Podcast copyWith({
    String? id,
    String? title,
    String? description,
    String? thumbnailUrl,
    String? author,
    List<Episode>? episodes,
    int? totalEpisodes,
    String? browseId,
    bool? isPinned,
  }) =>
      Podcast(
        id: id ?? this.id,
        title: title ?? this.title,
        description: description ?? this.description,
        thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
        author: author ?? this.author,
        episodes: episodes ?? this.episodes,
        totalEpisodes: totalEpisodes ?? this.totalEpisodes,
        browseId: browseId ?? this.browseId,
        isPinned: isPinned ?? this.isPinned,
      );
}

/// A single episode within a [Podcast].
///
/// Episodes support resumable listening via [PlaybackPosition] tracking
/// and can be converted to [Song] for playback in the standard queue.
class Episode {
  const Episode({
    required this.id,
    required this.title,
    this.description,
    this.thumbnailUrl,
    this.podcastTitle,
    this.podcastId,
    this.durationSeconds,
    this.publishedDate,
    this.browseId,
    this.episodeNumber,
  });

  final String id;
  final String title;
  final String? description;
  final String? thumbnailUrl;
  final String? podcastTitle;
  final String? podcastId;
  final int? durationSeconds;
  final String? publishedDate;
  final String? browseId;
  final int? episodeNumber;

  factory Episode.fromJson(Map<String, dynamic> json) => Episode(
        id: json['id'] as String,
        title: json['title'] as String,
        description: json['description'] as String?,
        thumbnailUrl: json['thumbnailUrl'] as String?,
        podcastTitle: json['podcastTitle'] as String?,
        podcastId: json['podcastId'] as String?,
        durationSeconds: json['durationSeconds'] as int?,
        publishedDate: json['publishedDate'] as String?,
        browseId: json['browseId'] as String?,
        episodeNumber: json['episodeNumber'] as int?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        if (description != null) 'description': description,
        if (thumbnailUrl != null) 'thumbnailUrl': thumbnailUrl,
        if (podcastTitle != null) 'podcastTitle': podcastTitle,
        if (podcastId != null) 'podcastId': podcastId,
        if (durationSeconds != null) 'durationSeconds': durationSeconds,
        if (publishedDate != null) 'publishedDate': publishedDate,
        if (browseId != null) 'browseId': browseId,
        if (episodeNumber != null) 'episodeNumber': episodeNumber,
      };

  Episode copyWith({
    String? id,
    String? title,
    String? description,
    String? thumbnailUrl,
    String? podcastTitle,
    String? podcastId,
    int? durationSeconds,
    String? publishedDate,
    String? browseId,
    int? episodeNumber,
  }) =>
      Episode(
        id: id ?? this.id,
        title: title ?? this.title,
        description: description ?? this.description,
        thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
        podcastTitle: podcastTitle ?? this.podcastTitle,
        podcastId: podcastId ?? this.podcastId,
        durationSeconds: durationSeconds ?? this.durationSeconds,
        publishedDate: publishedDate ?? this.publishedDate,
        browseId: browseId ?? this.browseId,
        episodeNumber: episodeNumber ?? this.episodeNumber,
      );
}

extension EpisodeDuration on Episode {
  String get durationFormatted {
    if (durationSeconds == null) return '';
    final duration = Duration(seconds: durationSeconds!);
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    } else {
      return '${seconds}s';
    }
  }

  Song toSong() => Song(
        id: id,
        title: title,
        artist: podcastTitle ?? 'Podcast',
        thumbnailUrl: thumbnailUrl ?? '',
        duration: Duration(seconds: durationSeconds ?? 0),
      );
}

extension PodcastToSong on Podcast {
  Song toSong() => Song(
        id: id,
        title: title,
        artist: author ?? 'Podcast',
        thumbnailUrl: thumbnailUrl ?? '',
        duration: Duration.zero,
      );
}
