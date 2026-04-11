/// A history entry for a track that was played, persisted to SQLite.
class RecentlyPlayedSong {
  final String id;
  final String title;
  final String artist;
  final String thumbnailUrl;
  final int durationSeconds;
  final DateTime lastPlayed;

  const RecentlyPlayedSong({
    required this.id,
    required this.title,
    required this.artist,
    required this.thumbnailUrl,
    required this.durationSeconds,
    required this.lastPlayed,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'artist': artist,
        'thumbnailUrl': thumbnailUrl,
        'durationSeconds': durationSeconds,
        'lastPlayed': lastPlayed.toIso8601String(),
      };

  factory RecentlyPlayedSong.fromJson(Map<String, dynamic> json) {
    return RecentlyPlayedSong(
      id: json['id'] as String,
      title: json['title'] as String,
      artist: json['artist'] as String,
      thumbnailUrl: json['thumbnailUrl'] as String,
      durationSeconds: json['durationSeconds'] as int,
      lastPlayed: DateTime.parse(json['lastPlayed'] as String),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RecentlyPlayedSong &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'RecentlyPlayedSong($id: $title)';
}
