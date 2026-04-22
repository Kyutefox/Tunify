/// A track returned from a Tunify `/v1/browse` collection response.
class BrowseTrack {
  const BrowseTrack({
    required this.id,
    required this.title,
    required this.artist,
    required this.thumbnailUrl,
    required this.duration,
    this.isExplicit = false,
    this.description,
    this.durationText,
    this.artistBrowseId,
    this.artistBrowseIds = const [],
    this.albumBrowseId,
    this.albumName,
    this.primaryArtistName,
  });

  final String id;
  final String title;
  final String artist;
  final String thumbnailUrl;
  final Duration duration;
  final bool isExplicit;
  final String? description;
  final String? durationText;
  final String? artistBrowseId;
  final List<String> artistBrowseIds;
  final String? albumBrowseId;
  final String? albumName;
  final String? primaryArtistName;

  String get durationFormatted {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    if (duration.inHours > 0) {
      return '${duration.inHours}:$minutes:$seconds';
    }
    return '$minutes:$seconds';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BrowseTrack &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
