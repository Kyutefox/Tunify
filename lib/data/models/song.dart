import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:tunify/data/models/track.dart';
import 'package:tunify/core/utils/duration_format.dart';

part 'song.freezed.dart';

/// App model for a playable track (queue, library, persistence). Convert from
/// API [Track] via [Song.fromTrack].
@Freezed(fromJson: false, toJson: false)
abstract class Song with _$Song {
  const Song._();

  const factory Song({
    required String id,
    required String title,
    required String artist,
    required String thumbnailUrl,
    required Duration duration,
    String? artistBrowseId,
    String? albumBrowseId,
    String? albumName,
    @Default(false) bool isExplicit,
  }) = _Song;

  String get durationFormatted => duration.formattedMmSS;

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'artist': artist,
        'thumbnailUrl': thumbnailUrl,
        'durationMs': duration.inMilliseconds,
        if (artistBrowseId != null) 'artistBrowseId': artistBrowseId,
        if (albumBrowseId != null) 'albumBrowseId': albumBrowseId,
        if (albumName != null) 'albumName': albumName,
        'isExplicit': isExplicit,
      };

  factory Song.fromJson(Map<String, dynamic> json) => Song(
        id: json['id'] as String,
        title: json['title'] as String,
        artist: json['artist'] as String,
        thumbnailUrl: json['thumbnailUrl'] as String,
        duration: Duration(milliseconds: json['durationMs'] as int),
        artistBrowseId: json['artistBrowseId'] as String?,
        albumBrowseId: json['albumBrowseId'] as String?,
        albumName: json['albumName'] as String?,
        isExplicit: json['isExplicit'] as bool? ?? false,
      );

  factory Song.fromTrack(Track track) => Song(
        id: track.id,
        title: track.title,
        artist: track.artist,
        thumbnailUrl: track.thumbnailUrl,
        duration: track.duration,
        artistBrowseId: track.artistBrowseId,
        albumBrowseId: track.albumBrowseId,
        albumName: track.albumName,
        isExplicit: track.isExplicit,
      );
}
