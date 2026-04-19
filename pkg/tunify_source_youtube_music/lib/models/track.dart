/// Lightweight track model returned by this package.
///
/// This model has no dependency on the main app and is safe to use in
/// isolates, background processes and other packages.
class Track {
  /// Stable identifier for the track, typically a YouTube video ID.
  final String id;

  /// User‑visible track title.
  final String title;

  /// Primary artist name for display.
  final String artist;

  /// URL of a thumbnail image representing the track.
  final String thumbnailUrl;

  /// Track duration as reported by YouTube.
  final Duration duration;

  /// Browse ID that can be used to open the artist page, when available.
  final String? artistBrowseId;

  /// Browse ID that can be used to open the album or playlist, when available.
  final String? albumBrowseId;

  /// Name of the album the track belongs to, if known.
  final String? albumName;

  /// Whether the track is marked explicit by YouTube.
  final bool isExplicit;

  /// Episode description (for podcasts). Null for regular tracks.
  final String? description;

  /// Duration text (e.g., "1 hr 29 min") from the API response. Null for regular tracks.
  final String? durationText;

  /// Creates an immutable [Track] instance describing a YouTube Music item.
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
    this.description,
    this.durationText,
  });

  /// Serialises this track to a JSON‑compatible map.
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
        'description': description,
        'durationText': durationText,
      };

  /// Human‑readable duration string in `mm:ss` or `h:mm:ss` format.
  String get durationFormatted {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    if (duration.inHours > 0) {
      return '${duration.inHours}:$minutes:$seconds';
    }
    return '$minutes:$seconds';
  }

  /// Returns a copy of this [Track] with the given fields replaced.
  ///
  /// Only non‑null parameters override the existing values.
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
    String? description,
    String? durationText,
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
      description: description ?? this.description,
      durationText: durationText ?? this.durationText,
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
