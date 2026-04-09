import 'package:tunify_source_youtube_music/constants/parser_constants.dart';
import 'package:tunify_source_youtube_music/models/track.dart';
import 'package:tunify_source_youtube_music/youtube_music/parsers/inner_tube_parsers.dart' as p;

/// Helpers for parsing YouTube Music `next` endpoint responses.
class NextFormatter {
  /// Main entry point to parse the `next` API response.
  ///
  /// Only parses `playlistPanelVideoRenderer` items; preview items rendered
  /// via `automixPreviewVideoRenderer` are skipped and should instead be
  /// requested through [extractAutomixEndpoint] followed by a second `next`
  /// call for the full automix queue.
  static List<Track> parseNextResponse(Map<String, dynamic> data) {
    final tracks = <Track>[];

    final contents = _extractPlaylistPanelContents(data);
    if (contents == null) return tracks;

    for (final item in contents.whereType<Map<String, dynamic>>()) {
      final renderer = _extractPanelVideoRenderer(item);
      // Only add real tracks; skip automixPreviewVideoRenderer (handled via automix request).
      if (renderer != null) {
        final track = parsePlaylistPanelVideo(renderer);
        if (track != null) tracks.add(track);
      }
    }

    return tracks;
  }

  /// Extracts watchPlaylistEndpoint or watchEndpoint from the last content item if it's
  /// an automix preview. Used to request the full "Mix" queue with a second next call.
  static Map<String, dynamic>? extractAutomixEndpoint(List<dynamic>? contents) {
    if (contents == null || contents.isEmpty) return null;
    final last = contents.last;
    if (last is! Map<String, dynamic>) return null;

    final automix =
        last['automixPreviewVideoRenderer'] as Map<String, dynamic>?;
    if (automix == null) return null;

    final content = automix['content'] as Map<String, dynamic>?;
    final automixRenderer =
        content?['automixPlaylistVideoRenderer'] as Map<String, dynamic>?;
    final navEndpoint =
        automixRenderer?['navigationEndpoint'] as Map<String, dynamic>?;

    final watchPlaylist =
        navEndpoint?['watchPlaylistEndpoint'] as Map<String, dynamic>?;
    if (watchPlaylist != null) return watchPlaylist;

    return navEndpoint?['watchEndpoint'] as Map<String, dynamic>?;
  }

  /// Extracts a `Track` from an `automixPreviewVideoRenderer` node (preview item in queue).
  static Track? parseAutomixPreviewVideo(Map<String, dynamic>? item) {
    if (item == null) return null;
    String? videoId = item['videoId'] as String?;
    if (videoId == null || videoId.isEmpty) {
      final endpoint = item['navigationEndpoint'] as Map<String, dynamic>?;
      final watch = endpoint?['watchEndpoint'] as Map<String, dynamic>?;
      videoId = watch?['videoId'] as String?;
    }
    if (videoId == null || videoId.isEmpty) return null;

    final titleRuns = item['title'] as Map<String, dynamic>?;
    final title = p.extractRunsText(titleRuns) ?? 'Unknown title';

    final longByline = item['longBylineText'] as Map<String, dynamic>?;
    final metadata = longByline != null
        ? p.extractTrackMetadata(longByline)
        : <String, String?>{};

    final thumb = item['thumbnail'] as Map<String, dynamic>?;
    final thumbUrl = p.extractOrFallbackThumbnail(thumb, videoId);

    final lengthRuns = item['lengthText'] as Map<String, dynamic>?;
    final lengthText = p.extractRunsText(lengthRuns);
    final duration =
        p.parseDuration(lengthText) ?? ParserConstants.defaultTrackDuration;

    return Track(
      id: videoId,
      title: title,
      artist: metadata['artist'] ?? 'Unknown artist',
      artistBrowseId: metadata['artistBrowseId'],
      albumName: metadata['albumName'],
      albumBrowseId: metadata['albumBrowseId'],
      thumbnailUrl: thumbUrl,
      duration: duration,
      isExplicit:
          p.extractIsExplicitFromBadges(item['badges'] as List<dynamic>?),
    );
  }

  /// Extracts a `Track` from a `playlistPanelVideoRenderer` node.
  static Track? parsePlaylistPanelVideo(Map<String, dynamic>? item) {
    if (item == null) return null;

    final videoId = item['videoId'] as String?;
    if (videoId == null || videoId.isEmpty) return null;

    final titleRuns = item['title'] as Map<String, dynamic>?;
    final title = p.extractRunsText(titleRuns) ?? 'Unknown title';

    final longByline = item['longBylineText'] as Map<String, dynamic>?;
    final metadata = p.extractTrackMetadata(longByline);

    final thumb = item['thumbnail'] as Map<String, dynamic>?;
    final thumbUrl = p.extractOrFallbackThumbnail(thumb, videoId);

    final lengthRuns = item['lengthText'] as Map<String, dynamic>?;
    final lengthText = p.extractRunsText(lengthRuns);
    final duration =
        p.parseDuration(lengthText) ?? ParserConstants.defaultTrackDuration;

    final badges = item['badges'] as List<dynamic>?;
    final isExplicit = p.extractIsExplicitFromBadges(badges);

    return Track(
      id: videoId,
      title: title,
      artist: metadata['artist'] ?? 'Unknown artist',
      artistBrowseId:
          metadata['artistBrowseId'] ?? p.extractMenuArtistId(item['menu']),
      albumName: metadata['albumName'],
      albumBrowseId: metadata['albumBrowseId'],
      thumbnailUrl: thumbUrl,
      duration: duration,
      isExplicit: isExplicit,
    );
  }

  /// Returns the playlistPanelRenderer map from a next response (for continuations).
  static Map<String, dynamic>? extractPlaylistPanel(Map<String, dynamic> data) {
    try {
      final panel = data['contents']
                      ?['singleColumnMusicWatchNextResultsRenderer']
                  ?['tabbedRenderer']?['watchNextTabbedResultsRenderer']
              ?['tabs']?[0]?['tabRenderer']?['content']?['musicQueueRenderer']
          ?['content']?['playlistPanelRenderer'];
      return panel is Map<String, dynamic> ? panel : null;
    } catch (_) {
      return null;
    }
  }

  /// Reads continuation token from a playlistPanelRenderer (or continuation panel).
  /// Handles both nextContinuationData and nextRadioContinuationData.
  static String? getContinuationToken(Map<String, dynamic> panel) {
    final continuations = panel['continuations'] as List<dynamic>?;
    if (continuations == null || continuations.isEmpty) return null;
    final first = continuations.first as Map<String, dynamic>?;
    if (first == null) return null;
    final nextData = first['nextContinuationData'] as Map<String, dynamic>?;
    if (nextData != null) return nextData['continuation'] as String?;
    final radioData =
        first['nextRadioContinuationData'] as Map<String, dynamic>?;
    return radioData?['continuation'] as String?;
  }

  /// Result of parsing a continuation response (playlistPanelContinuation).
  static ContinuationResult? parseContinuationResponse(
      Map<String, dynamic> data) {
    final panel = data['continuationContents']?['playlistPanelContinuation']
        as Map<String, dynamic>?;
    if (panel == null) return null;
    final contents = panel['contents'] as List<dynamic>? ?? [];
    final tracks = <Track>[];
    for (final item in contents.whereType<Map<String, dynamic>>()) {
      Track? track = parsePlaylistPanelVideo(_extractPanelVideoRenderer(item));
      if (track == null) {
        final automix =
            item['automixPreviewVideoRenderer'] as Map<String, dynamic>?;
        track = parseAutomixPreviewVideo(automix);
      }
      if (track != null) tracks.add(track);
    }
    return ContinuationResult(tracks: tracks, panel: panel);
  }

  /// Resolves a playlistPanelVideoRenderer from a panel content item,
  /// handling both direct and wrapper variants.
  static Map<String, dynamic>? _extractPanelVideoRenderer(
      Map<String, dynamic> item) {
    final wrapper =
        item['playlistPanelVideoWrapperRenderer'] as Map<String, dynamic>?;
    final renderer =
        item['playlistPanelVideoRenderer'] as Map<String, dynamic>? ??
            wrapper?['primaryRenderer'] as Map<String, dynamic>? ??
            wrapper?['primary'] as Map<String, dynamic>?;
    if (renderer != null) return renderer;
    final content = item['content'] as Map<String, dynamic>?;
    return content?['playlistPanelVideoRenderer'] as Map<String, dynamic>?;
  }

  /// Queue is always at: contents.singleColumnMusicWatchNextResultsRenderer
  /// .tabbedRenderer.watchNextTabbedResultsRenderer.tabs[0].tabRenderer.content
  /// .musicQueueRenderer.content.playlistPanelRenderer.contents
  /// (per next API response; no fallbacks — other panels can be single-item.)
  static List<dynamic>? _extractPlaylistPanelContents(
      Map<String, dynamic> data) {
    try {
      final contents = data['contents']
                      ?['singleColumnMusicWatchNextResultsRenderer']
                  ?['tabbedRenderer']?['watchNextTabbedResultsRenderer']
              ?['tabs']?[0]?['tabRenderer']?['content']?['musicQueueRenderer']
          ?['content']?['playlistPanelRenderer']?['contents'];

      if (contents is List) return contents;
      return null;
    } catch (_) {
      return null;
    }
  }
}

/// Result of parsing a next continuation response.
class ContinuationResult {
  final List<Track> tracks;
  final Map<String, dynamic> panel;

  ContinuationResult({required this.tracks, required this.panel});
}
