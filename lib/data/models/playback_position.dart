/// Tracks playback position for podcasts and audiobooks
class PlaybackPosition {
  const PlaybackPosition({
    required this.contentId,
    required this.contentType,
    required this.positionSeconds,
    required this.durationSeconds,
    required this.lastPlayedAt,
    this.completed,
  });

  final String contentId;
  final PlaybackContentType contentType;
  final int positionSeconds;
  final int durationSeconds;
  final DateTime lastPlayedAt;
  final bool? completed;

  factory PlaybackPosition.fromJson(Map<String, dynamic> json) =>
      PlaybackPosition(
        contentId: json['contentId'] as String,
        contentType: PlaybackContentType.values
            .firstWhere((e) => e.name == json['contentType']),
        positionSeconds: json['positionSeconds'] as int,
        durationSeconds: json['durationSeconds'] as int,
        lastPlayedAt: DateTime.parse(json['lastPlayedAt'] as String),
        completed: json['completed'] as bool?,
      );

  Map<String, dynamic> toJson() => {
        'contentId': contentId,
        'contentType': contentType.name,
        'positionSeconds': positionSeconds,
        'durationSeconds': durationSeconds,
        'lastPlayedAt': lastPlayedAt.toIso8601String(),
        if (completed != null) 'completed': completed,
      };

  PlaybackPosition copyWith({
    String? contentId,
    PlaybackContentType? contentType,
    int? positionSeconds,
    int? durationSeconds,
    DateTime? lastPlayedAt,
    bool? completed,
  }) =>
      PlaybackPosition(
        contentId: contentId ?? this.contentId,
        contentType: contentType ?? this.contentType,
        positionSeconds: positionSeconds ?? this.positionSeconds,
        durationSeconds: durationSeconds ?? this.durationSeconds,
        lastPlayedAt: lastPlayedAt ?? this.lastPlayedAt,
        completed: completed ?? this.completed,
      );
}

enum PlaybackContentType {
  episode,
  audiobook,
}

extension PlaybackPositionProgress on PlaybackPosition {
  double get progress {
    if (durationSeconds == 0) return 0.0;
    return (positionSeconds / durationSeconds).clamp(0.0, 1.0);
  }

  bool get isNearlyComplete => progress >= 0.95;
  
  String get timeRemaining {
    final remaining = durationSeconds - positionSeconds;
    if (remaining <= 0) return 'Completed';
    
    final duration = Duration(seconds: remaining);
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    
    if (hours > 0) {
      return '$hours hr $minutes min left';
    } else {
      return '$minutes min left';
    }
  }
}
