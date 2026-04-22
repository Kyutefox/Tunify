import 'package:tunify/v2/features/library/domain/entities/browse_track.dart';

/// Maps Tunify Rust `FeedItem` JSON (from `/v1/browse` `parsed.primary_tracks`) to [BrowseTrack].
String? _primaryArtistFallbackFromSubtitle(String? subtitle) {
  final raw = subtitle?.trim();
  if (raw == null || raw.isEmpty) {
    return null;
  }
  final split = raw.split(RegExp(r',|•|&'));
  if (split.isEmpty) {
    return null;
  }
  final first = split.first.trim();
  return first.isEmpty ? null : first;
}

BrowseTrack trackFromBrowseFeedJson(Map<String, dynamic> json) {
  final id = (json['id'] as String?)?.trim() ?? '';
  final title = (json['title'] as String?)?.trim() ?? '';
  final subtitle = (json['subtitle'] as String?)?.trim();
  final description = (json['description'] as String?)?.trim();
  final durationText = (json['duration_text'] as String?)?.trim();
  final artists = json['artists'] as List<dynamic>? ?? const [];
  final firstArtist =
      artists.isEmpty ? null : artists.first as Map<String, dynamic>?;
  final artistName = (firstArtist?['name'] as String?)?.trim() ?? '';
  final browseRefs = json['browse_refs'] as List<dynamic>? ?? const [];
  final artistBrowseIds = <String>[];
  String? artistBrowseId;
  String? albumBrowseId;
  for (final entry in browseRefs.whereType<Map<String, dynamic>>()) {
    final kind = (entry['ref_kind'] as String?)?.trim();
    final id = (entry['browse_id'] as String?)?.trim();
    if (id == null || id.isEmpty) {
      continue;
    }
    if (kind == 'artist' && artistBrowseId == null) {
      artistBrowseId = id;
    }
    if (kind == 'artist' && !artistBrowseIds.contains(id)) {
      artistBrowseIds.add(id);
    } else if (kind == 'album' && albumBrowseId == null) {
      albumBrowseId = id;
    }
    if (artistBrowseId != null && albumBrowseId != null) {
      break;
    }
  }
  // Legacy fallback: some payloads expose artist id only in artists[].
  if (artistBrowseId == null) {
    final candidate = (firstArtist?['id'] as String?)?.trim();
    if (candidate != null &&
        candidate.isNotEmpty &&
        candidate.toUpperCase().startsWith('UC')) {
      artistBrowseId = candidate;
      if (!artistBrowseIds.contains(candidate)) {
        artistBrowseIds.add(candidate);
      }
    }
  }
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
    artistBrowseId: artistBrowseId,
    artistBrowseIds: artistBrowseIds,
    albumBrowseId: albumBrowseId,
    primaryArtistName: artistName.isNotEmpty
        ? artistName
        : _primaryArtistFallbackFromSubtitle(subtitle),
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
