import 'package:tunify/data/models/song.dart';

/// Audiobook model for audiobooks
class Audiobook {
  const Audiobook({
    required this.id,
    required this.title,
    this.description,
    this.thumbnailUrl,
    this.author,
    this.narrator,
    this.durationSeconds,
    this.chapters = const [],
    this.browseId,
    this.publishedDate,
    this.isPinned = false,
  });

  final String id;
  final String title;
  final String? description;
  final String? thumbnailUrl;
  final String? author;
  final String? narrator;
  final int? durationSeconds;
  final List<AudiobookChapter> chapters;
  final String? browseId;
  final String? publishedDate;
  final bool isPinned;

  factory Audiobook.fromJson(Map<String, dynamic> json) => Audiobook(
        id: json['id'] as String,
        title: json['title'] as String,
        description: json['description'] as String?,
        thumbnailUrl: json['thumbnailUrl'] as String?,
        author: json['author'] as String?,
        narrator: json['narrator'] as String?,
        durationSeconds: json['durationSeconds'] as int?,
        browseId: json['browseId'] as String?,
        publishedDate: json['publishedDate'] as String?,
        isPinned: json['isPinned'] as bool? ?? false,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        if (description != null) 'description': description,
        if (thumbnailUrl != null) 'thumbnailUrl': thumbnailUrl,
        if (author != null) 'author': author,
        if (narrator != null) 'narrator': narrator,
        if (durationSeconds != null) 'durationSeconds': durationSeconds,
        if (browseId != null) 'browseId': browseId,
        if (publishedDate != null) 'publishedDate': publishedDate,
        'isPinned': isPinned,
      };

  Audiobook copyWith({
    String? id,
    String? title,
    String? description,
    String? thumbnailUrl,
    String? author,
    String? narrator,
    int? durationSeconds,
    List<AudiobookChapter>? chapters,
    String? browseId,
    String? publishedDate,
    bool? isPinned,
  }) =>
      Audiobook(
        id: id ?? this.id,
        title: title ?? this.title,
        description: description ?? this.description,
        thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
        author: author ?? this.author,
        narrator: narrator ?? this.narrator,
        durationSeconds: durationSeconds ?? this.durationSeconds,
        chapters: chapters ?? this.chapters,
        browseId: browseId ?? this.browseId,
        publishedDate: publishedDate ?? this.publishedDate,
        isPinned: isPinned ?? this.isPinned,
      );
}

/// Audiobook chapter model
class AudiobookChapter {
  const AudiobookChapter({
    required this.id,
    required this.title,
    this.startTimeSeconds,
    this.durationSeconds,
    this.chapterNumber,
  });

  final String id;
  final String title;
  final int? startTimeSeconds;
  final int? durationSeconds;
  final int? chapterNumber;

  factory AudiobookChapter.fromJson(Map<String, dynamic> json) =>
      AudiobookChapter(
        id: json['id'] as String,
        title: json['title'] as String,
        startTimeSeconds: json['startTimeSeconds'] as int?,
        durationSeconds: json['durationSeconds'] as int?,
        chapterNumber: json['chapterNumber'] as int?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        if (startTimeSeconds != null) 'startTimeSeconds': startTimeSeconds,
        if (durationSeconds != null) 'durationSeconds': durationSeconds,
        if (chapterNumber != null) 'chapterNumber': chapterNumber,
      };

  AudiobookChapter copyWith({
    String? id,
    String? title,
    int? startTimeSeconds,
    int? durationSeconds,
    int? chapterNumber,
  }) =>
      AudiobookChapter(
        id: id ?? this.id,
        title: title ?? this.title,
        startTimeSeconds: startTimeSeconds ?? this.startTimeSeconds,
        durationSeconds: durationSeconds ?? this.durationSeconds,
        chapterNumber: chapterNumber ?? this.chapterNumber,
      );
}

extension AudiobookDuration on Audiobook {
  String get durationFormatted {
    if (durationSeconds == null) return '';
    final duration = Duration(seconds: durationSeconds!);
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${minutes}m';
    }
  }

  Song toSong() => Song(
        id: id,
        title: title,
        artist: author ?? 'Audiobook',
        thumbnailUrl: thumbnailUrl ?? '',
        duration: Duration(seconds: durationSeconds ?? 0),
      );
}
