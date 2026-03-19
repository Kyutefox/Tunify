import 'track.dart';

/// Semantic type tag used to select the rendering widget for a [HomeSection].
enum SectionType {
  quickPicks,
  trending,
  fromCommunity,
  moodGenre,
  recentlyPlayed,
}

/// A single feed section on the home screen, containing a list of [Track]s.
class HomeSection {
  final String title;
  final SectionType type;
  final List<Track> tracks;
  final String? subtitle;

  const HomeSection({
    required this.title,
    required this.type,
    required this.tracks,
    this.subtitle,
  });

  bool get isEmpty => tracks.isEmpty;
  bool get isNotEmpty => tracks.isNotEmpty;
}
