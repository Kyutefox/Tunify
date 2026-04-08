import 'package:scrapper/models/track.dart';
import 'package:scrapper/youtube_music/parsers/inner_tube_parsers.dart' as p;

/// Helpers for parsing YouTube player API responses into [Track] metadata.
///
/// The formatter normalises thumbnail URLs, duration, loudness values and
/// additional metadata so the rest of the codebase does not need to know
/// about the nested InnerTube JSON structure.
class PlayerFormatter {
  /// Parses the raw `player` API [data] into a map containing a [Track] and
  /// a `metadata` map.
  ///
  /// The returned map always has a `track` key when a valid `videoId` is
  /// present, and a `metadata` key with optional fields such as
  /// `viewCount`, `publishDate`, `category`, `description` and loudness
  /// values discovered anywhere in the payload.
  ///
  /// Returns an empty map when [data] does not describe a playable video.
  static Map<String, dynamic> parsePlayerResponse(Map<String, dynamic> data) {
    final videoDetails = data['videoDetails'] as Map<String, dynamic>? ?? {};
    final microformat = data['microformat']?['microformatDataRenderer']
            as Map<String, dynamic>? ??
        {};

    final videoId = videoDetails['videoId'] as String?;
    if (videoId == null) return {};

    final author = videoDetails['author'] as String? ?? 'Unknown Artist';
    final title = videoDetails['title'] as String? ?? 'Unknown Title';
    final durationSeconds =
        int.tryParse(videoDetails['lengthSeconds']?.toString() ?? '0') ?? 0;

    final thumbnails = videoDetails['thumbnail']?['thumbnails'] as List?;
    String? thumbUrl;
    if (thumbnails != null && thumbnails.isNotEmpty) {
      thumbUrl = thumbnails.last['url'] as String?;
    }
    thumbUrl = p.upgradeThumbResolution(
        thumbUrl ?? 'https://i.ytimg.com/vi/$videoId/hqdefault.jpg', videoId);

    final track = Track(
      id: videoId,
      title: title,
      artist: author,
      duration: Duration(seconds: durationSeconds),
      thumbnailUrl: thumbUrl,
      artistBrowseId: videoDetails['channelId'] as String?,
      albumBrowseId: _extractAlbumId(data),
      albumName: null,
      isExplicit: false,
    );

    return {
      'track': track,
      'metadata': {
        'viewCount': microformat['viewCount'] as String?,
        'publishDate': microformat['publishDate'] as String?,
        'category': microformat['category'] as String?,
        'description': microformat['description'] as String?,
        ..._extractLoudness(data),
      },
    };
  }

  static Map<String, dynamic> _extractLoudness(Map<String, dynamic> data) {
    final Map<String, dynamic> loudnessData = {};

    final playerConfig = data['playerConfig'] as Map<String, dynamic>?;
    final audioConfig = playerConfig?['audioConfig'] as Map<String, dynamic>?;
    if (audioConfig != null) {
      loudnessData.addAll(_readAllLoudnessValues(audioConfig));
    }

    final streamingData = data['streamingData'] as Map<String, dynamic>?;
    final adaptiveFormats = streamingData?['adaptiveFormats'] as List?;
    if (adaptiveFormats != null && loudnessData.isEmpty) {
      for (final format in adaptiveFormats) {
        if (format is Map<String, dynamic>) {
          final values = _readAllLoudnessValues(format);
          if (values.isNotEmpty) {
            loudnessData.addAll(values);
            break;
          }
        }
      }
    }

    if (loudnessData.isEmpty) {
      _findLoudnessRecursively(data, loudnessData);
    }

    return loudnessData;
  }

  static Map<String, dynamic> _readAllLoudnessValues(Map<String, dynamic> map) {
    final Map<String, dynamic> result = {};
    const keys = [
      'trackAbsoluteLoudnessLkfs',
      'perceptualLoudnessDb',
      'loudnessDb',
      'loudnessTargetLkfs',
      'relativeLoudness'
    ];

    for (final key in keys) {
      final value = map[key];
      if (value != null) {
        if (value is num) {
          result[key] = value.toDouble();
        } else if (value is String) {
          result[key] = double.tryParse(value);
        }
      }
    }
    return result;
  }

  static void _findLoudnessRecursively(dynamic node, Map<String, dynamic> out) {
    if (node is Map<String, dynamic>) {
      final direct = _readAllLoudnessValues(node);
      if (direct.isNotEmpty) {
        out.addAll(direct);
        return;
      }
      for (final value in node.values) {
        _findLoudnessRecursively(value, out);
        if (out.isNotEmpty) return;
      }
    } else if (node is List) {
      for (final element in node) {
        _findLoudnessRecursively(element, out);
        if (out.isNotEmpty) return;
      }
    }
  }

  static String? _extractAlbumId(Map<String, dynamic> data) {
    final microformat = data['microformat']?['microformatDataRenderer']
        as Map<String, dynamic>?;

    // Primary: urlCanonical contains list= param (e.g. OLAK5uy_...)
    final url = microformat?['urlCanonical'] as String?;
    if (url != null && url.contains('list=')) {
      final uri = Uri.parse(url);
      final listId = uri.queryParameters['list'];
      if (listId != null && listId.isNotEmpty) return listId;
    }

    // Fallback: embed iframeUrl also sometimes carries the list param
    final embedUrl = microformat?['embed']?['iframeUrl'] as String?;
    if (embedUrl != null && embedUrl.contains('list=')) {
      final uri = Uri.parse(embedUrl);
      final listId = uri.queryParameters['list'];
      if (listId != null && listId.isNotEmpty) return listId;
    }

    return null;
  }
}
