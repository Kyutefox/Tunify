import 'song.dart';

/// A YouTube Music playlist returned from the API (not a user-created library playlist).
///
/// For user-owned playlists see [LibraryPlaylist].
class Playlist {
  final String id;
  final String title;
  final String description;
  final String coverUrl;
  final String? curatorName;

  /// Channel / profile image URL when the API exposes it (often null).
  final String? curatorThumbnailUrl;
  final int trackCount;
  final Duration? totalDuration;
  final List<Song>? tracks;

  /// Up to four album art URLs used to render a mosaic cover when no single [coverUrl] is set.
  final List<String>? previewUrls;

  const Playlist({
    required this.id,
    required this.title,
    required this.description,
    required this.coverUrl,
    this.curatorName,
    this.curatorThumbnailUrl,
    this.trackCount = 0,
    this.totalDuration,
    this.tracks,
    this.previewUrls,
  });

  String get trackCountFormatted {
    if (trackCount == 1) return '1 song';
    return '$trackCount songs';
  }

  String get durationFormatted {
    if (totalDuration == null) return '';
    final hours = totalDuration!.inHours;
    final minutes = totalDuration!.inMinutes.remainder(60);
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '$minutes min';
  }

  Playlist copyWith({
    String? id,
    String? title,
    String? description,
    String? coverUrl,
    String? curatorName,
    String? curatorThumbnailUrl,
    int? trackCount,
    Duration? totalDuration,
    List<Song>? tracks,
    List<String>? previewUrls,
  }) {
    return Playlist(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      coverUrl: coverUrl ?? this.coverUrl,
      curatorName: curatorName ?? this.curatorName,
      curatorThumbnailUrl: curatorThumbnailUrl ?? this.curatorThumbnailUrl,
      trackCount: trackCount ?? this.trackCount,
      totalDuration: totalDuration ?? this.totalDuration,
      tracks: tracks ?? this.tracks,
      previewUrls: previewUrls ?? this.previewUrls,
    );
  }
}
