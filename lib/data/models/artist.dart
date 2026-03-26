/// Artist metadata returned from the YouTube Music API.
class Artist {
  final String id;
  final String name;
  final String avatarUrl;
  final String? genre;
  final int? monthlyListeners;
  final bool isVerified;
  final String? latestRelease;

  const Artist({
    required this.id,
    required this.name,
    required this.avatarUrl,
    this.genre,
    this.monthlyListeners,
    this.isVerified = false,
    this.latestRelease,
  });

  /// Monthly listener count formatted as "1.2M listeners", "500K listeners", or
  /// an exact count. Returns an empty string when [monthlyListeners] is null.
  String get listenersFormatted {
    if (monthlyListeners == null) return '';
    if (monthlyListeners! >= 1000000) {
      return '${(monthlyListeners! / 1000000).toStringAsFixed(1)}M listeners';
    }
    if (monthlyListeners! >= 1000) {
      return '${(monthlyListeners! / 1000).toStringAsFixed(0)}K listeners';
    }
    return '$monthlyListeners listeners';
  }

  Artist copyWith({
    String? id,
    String? name,
    String? avatarUrl,
    String? genre,
    int? monthlyListeners,
    bool? isVerified,
    String? latestRelease,
  }) {
    return Artist(
      id: id ?? this.id,
      name: name ?? this.name,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      genre: genre ?? this.genre,
      monthlyListeners: monthlyListeners ?? this.monthlyListeners,
      isVerified: isVerified ?? this.isVerified,
      latestRelease: latestRelease ?? this.latestRelease,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Artist && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Artist($id: $name)';
}
