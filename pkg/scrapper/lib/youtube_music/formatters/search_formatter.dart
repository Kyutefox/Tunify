import 'package:scrapper/models/track.dart';
import 'package:scrapper/youtube_music/parsers/inner_tube_parsers.dart' as p;

/// Helpers for parsing YouTube Music search and suggestion responses.
///
/// This formatter hides the complexity of the nested `search` and
/// `get_search_suggestions` InnerTube payloads behind strongly‑typed
/// [Track] and `String` lists.
class SearchFormatter {
  /// Parses a `search` API response [data] into a de‑duplicated list of
  /// song [Track]s.
  ///
  /// Only results that can be resolved to a playable `videoId` are returned,
  /// and duplicate video IDs are filtered out.
  static List<Track> parseSearchResults(Map<String, dynamic> data) {
    final results = <Track>[];
    final seen = <String>{};

    final sections = _extractSearchSections(data);
    for (final section in sections) {
      final shelf = section['musicShelfRenderer'] as Map<String, dynamic>?;
      if (shelf == null) continue;

      final contents = shelf['contents'] as List<dynamic>?;
      if (contents == null) continue;

      for (final item in contents.whereType<Map<String, dynamic>>()) {
        final track = _parseSearchItem(item);
        if (track != null && seen.add(track.id)) {
          results.add(track);
        }
      }
    }
    return results;
  }

  /// Parses a `music/get_search_suggestions` response [data] into user‑visible
  /// suggestion strings.
  ///
  /// When the payload is malformed or empty, an empty list is returned
  /// instead of throwing.
  static List<String> parseSuggestions(Map<String, dynamic> data) {
    try {
      final contents = data['contents'] as List<dynamic>?;
      if (contents == null || contents.isEmpty) return [];

      final section = contents[0] as Map<String, dynamic>?;
      final sectionRenderer =
          section?['searchSuggestionsSectionRenderer'] as Map<String, dynamic>?;
      final items = sectionRenderer?['contents'] as List<dynamic>?;
      if (items == null) return [];

      final suggestions = <String>[];
      for (final item in items.whereType<Map<String, dynamic>>()) {
        final renderer = item['historySuggestionRenderer'] as Map<String, dynamic>? ??
            item['searchSuggestionRenderer'] as Map<String, dynamic>?;
        if (renderer == null) continue;

        final suggestion = p.extractRunsText(renderer['suggestion']) ?? 
                          p.extractRunsText(renderer['navigationEndpoint']?['searchEndpoint']?['query']);
        
        if (suggestion != null && suggestion.trim().isNotEmpty) {
          suggestions.add(suggestion.trim());
        }
      }
      return suggestions;
    } catch (_) {
      return [];
    }
  }

  /// Resolves artist and album browse IDs from a general `search` response.
  ///
  /// When [preferredArtistName] is provided, artist matches whose name equals
  /// [preferredArtistName] (case‑insensitive) are preferred. The returned map
  /// includes `artistBrowseId` and `albumBrowseId` keys which may be `null`
  /// when no match is found.
  static Map<String, String?> parseBrowseIds(Map<String, dynamic> data, {String? preferredArtistName}) {
    String? artistId;
    String? albumId;

    final sections = _extractSearchSections(data);
    for (final section in sections) {
      final cardShelf = section['musicCardShelfRenderer'] as Map<String, dynamic>?;
      if (cardShelf != null) {
        final mainBrowseId = cardShelf['title']?['runs']?[0]?['navigationEndpoint']?['browseEndpoint']?['browseId'] as String?;
        if (mainBrowseId != null) {
          if (mainBrowseId.startsWith('UC')) artistId ??= mainBrowseId;
          if (_isAlbumBrowseId(mainBrowseId)) albumId ??= mainBrowseId;
        }

        final buttons = cardShelf['buttons'] as List?;
        if (buttons != null) {
          for (final btn in buttons.whereType<Map>()) {
            final browseId = btn['buttonRenderer']?['navigationEndpoint']?['browseEndpoint']?['browseId'] as String?;
            if (browseId != null) {
              if (browseId.startsWith('UC')) artistId ??= browseId;
              if (_isAlbumBrowseId(browseId)) albumId ??= browseId;
            }
          }
        }
      }

      final shelf = section['musicShelfRenderer'] as Map<String, dynamic>?;
      if (shelf == null) continue;

      final items = shelf['contents'] as List<dynamic>?;
      if (items == null) continue;

      for (final item in items.whereType<Map<String, dynamic>>()) {
        final renderer = item['musicResponsiveListItemRenderer'] as Map<String, dynamic>?;
        if (renderer == null) continue;

        final flexColumns = renderer['flexColumns'] as List?;
        if (flexColumns == null) continue;

        for (final col in flexColumns.whereType<Map>()) {
          final metadata = p.extractTrackMetadata(col['musicResponsiveListItemFlexColumnRenderer']?['text']);
          if (metadata['artistBrowseId'] != null) {
            final aName = metadata['artist'] as String?;
            if (artistId == null || (preferredArtistName != null && aName?.toLowerCase() == preferredArtistName.toLowerCase())) {
              artistId = metadata['artistBrowseId'];
            }
          }
          if (metadata['albumBrowseId'] != null) {
            albumId ??= metadata['albumBrowseId'];
          }
        }

        if (preferredArtistName != null && artistId != null && albumId != null) break;
      }
      
      if (artistId != null && albumId != null) break;
    }

    return {
      'artistBrowseId': artistId,
      'albumBrowseId': albumId,
    };
  }

  /// Extracts the continuation token from an initial or continuation `search`
  /// response [data], if present.
  ///
  /// The token can be supplied back to the `search` endpoint as the
  /// `continuation` field to request additional pages of results.
  static String? extractContinuationToken(Map<String, dynamic> data) {
    final sections = _extractSearchSections(data);
    for (final section in sections) {
      final shelf = section['musicShelfRenderer'] as Map<String, dynamic>?;
      final continuations = shelf?['continuations'] as List?;
      if (continuations != null && continuations.isNotEmpty) {
        return continuations[0]?['nextContinuationData']?['continuation'] as String?;
      }
    }

    final contShelf = data['continuationContents']?['musicShelfContinuation'];
    final conts = contShelf?['continuations'] as List?;
    if (conts != null && conts.isNotEmpty) {
      return conts[0]?['nextContinuationData']?['continuation'] as String?;
    }

    return null;
  }

  /// Returns true for any known YouTube Music album browse ID prefix.
  /// YouTube returns both `MPREb_` (canonical album) and `OLAK5uy_` (playlist
  /// alias for an album) depending on context. Both are accepted by the browse
  /// endpoint and by [BrowseFormatter.extractTracksFromBrowseData].
  static bool _isAlbumBrowseId(String id) =>
      id.startsWith('MPREb_') || id.startsWith('OLAK5uy_');

  static List<Map<String, dynamic>> _extractSearchSections(Map<String, dynamic> data) {
    final sections = <Map<String, dynamic>>[];
    
    final tabs = data['contents']?['tabbedSearchResultsRenderer']?['tabs'] as List?;
    if (tabs != null) {
      for (final tab in tabs.whereType<Map>()) {
        final sectionList = tab['tabRenderer']?['content']?['sectionListRenderer'];
        final contents = sectionList?['contents'] as List?;
        if (contents != null) {
          sections.addAll(contents.whereType<Map<String, dynamic>>());
        }
      }
    }

    final directContents = data['contents']?['sectionListRenderer']?['contents'] as List?;
    if (directContents != null) {
      sections.addAll(directContents.whereType<Map<String, dynamic>>());
    }

    final contShelf = data['continuationContents']?['musicShelfContinuation'];
    if (contShelf != null) {
      sections.add({'musicShelfRenderer': contShelf});
    }

    return sections;
  }

  static Track? _parseSearchItem(Map<String, dynamic> item) {
    final renderer = item['musicResponsiveListItemRenderer'] as Map<String, dynamic>?;
    if (renderer == null) return null;

    final flexColumns = renderer['flexColumns'] as List<dynamic>?;
    if (flexColumns == null) return null;

    final videoId = _extractVideoId(renderer);
    if (videoId == null) return null;

    final title = p.extractColumnRunsText(flexColumns, 0) ?? 'Unknown Title';
    final metadata = p.extractTrackMetadata(flexColumns[1]['musicResponsiveListItemFlexColumnRenderer']?['text']);
    
    // Fallback for duration if not in fixedColumns
    Duration? duration = p.parseDuration(p.extractFixedColumnText(renderer['fixedColumns'] as List?, 0));
    if (duration == null) {
      // Sometimes duration is in the second column runs
      final runs = (flexColumns[1]['musicResponsiveListItemFlexColumnRenderer']?['text']?['runs'] as List?);
      if (runs != null) {
        for (final run in runs) {
          final text = run['text'] as String?;
          final directDur = p.parseDuration(text);
          if (directDur != null) {
            duration = directDur;
            break;
          }
        }
      }
    }

    return Track(
      id: videoId,
      title: title,
      artist: metadata['artist'] ?? 'Unknown Artist',
      artistBrowseId: (metadata['artistBrowseId'] as String?) ?? p.extractMenuArtistId(renderer['menu']),
      albumName: metadata['albumName'] as String?,
      albumBrowseId: metadata['albumBrowseId'] as String?,
      thumbnailUrl: p.extractOrFallbackThumbnail(renderer['thumbnail'], videoId),
      duration: duration ?? Duration.zero,
      isExplicit: p.extractIsExplicitFromBadges(renderer['badges'] as List?),
    );
  }

  static String? _extractVideoId(Map<String, dynamic> renderer) {
    // 1. From overlay (play button)
    final playNav = renderer['overlay']?['musicItemThumbnailOverlayRenderer']?['content']?['musicPlayButtonRenderer']?['playNavigationEndpoint'];
    final vid1 = playNav?['watchEndpoint']?['videoId'] as String?;
    if (vid1 != null) return vid1;

    // 2. From navigation endpoint
    final vid2 = renderer['navigationEndpoint']?['watchEndpoint']?['videoId'] as String?;
    if (vid2 != null) return vid2;

    // 3. From playlistItemData
    final vid3 = renderer['playlistItemData']?['videoId'] as String?;
    if (vid3 != null) return vid3;

    return null;
  }
}
