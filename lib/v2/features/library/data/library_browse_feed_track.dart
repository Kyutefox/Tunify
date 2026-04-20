import 'package:tunify/v2/features/library/domain/entities/browse_track.dart';

/// Maps Tunify Rust `FeedItem` JSON (from `/v1/browse` `parsed.primary_tracks`) to [BrowseTrack].
BrowseTrack trackFromBrowseFeedJson(Map<String, dynamic> json) {
  final id = (json['id'] as String?)?.trim() ?? '';
  final title = (json['title'] as String?)?.trim() ?? '';
  final subtitle = (json['subtitle'] as String?)?.trim();
  final description = (json['description'] as String?)?.trim();
  final durationText = (json['duration_text'] as String?)?.trim();
  final artists = json['artists'] as List<dynamic>? ?? const [];
  final firstArtist = artists.isEmpty
      ? null
      : artists.first as Map<String, dynamic>?;
  final artistName =
      (firstArtist?['name'] as String?)?.trim() ?? '';
  final ms = (json['duration_ms'] as num?)?.toInt() ?? 0;
  final thumb = (json['artwork_url'] as String?)?.trim() ?? '';
  return BrowseTrack(
    id: id,
    title: title,
    artist: (subtitle != null && subtitle.isNotEmpty) ? subtitle : artistName,
    thumbnailUrl: thumb,
    duration: Duration(milliseconds: ms),
    isExplicit: json['is_explicit'] as bool? ?? false,
    description: description,
    durationText: durationText,
  );
}

List<BrowseTrack> tracksFromBrowseParsed(Map<String, dynamic> parsed) {
  final list = parsed['primary_tracks'] as List<dynamic>? ?? const [];
  return list
      .whereType<Map<String, dynamic>>()
      .map(trackFromBrowseFeedJson)
      .where((t) => t.id.isNotEmpty)
      .toList(growable: false);
}
