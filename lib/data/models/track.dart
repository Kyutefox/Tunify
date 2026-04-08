import 'package:tunify/core/utils/duration_format.dart';

/// API/scrapper track type. Use [Song] in app code (queue, library, persistence).
/// Convert via [Song.fromTrack].
class Track {
  final String id;
  final String title;
  final String artist;
  final String thumbnailUrl;
  final Duration duration;
  final String? artistBrowseId;
  final String? albumBrowseId;
  final String? albumName;
  final bool isExplicit;

  const Track({
    required this.id,
    required this.title,
    required this.artist,
    required this.thumbnailUrl,
    required this.duration,
    this.artistBrowseId,
    this.albumBrowseId,
    this.albumName,
    this.isExplicit = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'artist': artist,
        'thumbnailUrl': thumbnailUrl,
        'duration': duration.inSeconds,
        'artistBrowseId': artistBrowseId,
        'albumBrowseId': albumBrowseId,
        'albumName': albumName,
        'isExplicit': isExplicit,
      };

  String get durationFormatted => duration.formattedMmSS;

  Track copyWith({
    String? id,
    String? title,
    String? artist,
    String? thumbnailUrl,
    Duration? duration,
    String? artistBrowseId,
    String? albumBrowseId,
    String? albumName,
    bool? isExplicit,
  }) {
    return Track(
      id: id ?? this.id,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      duration: duration ?? this.duration,
      artistBrowseId: artistBrowseId ?? this.artistBrowseId,
      albumBrowseId: albumBrowseId ?? this.albumBrowseId,
      albumName: albumName ?? this.albumName,
      isExplicit: isExplicit ?? this.isExplicit,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Track && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Track($id: $title by $artist)';
}
