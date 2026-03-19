library;

/// Returns the concatenated text from a `runs` array inside an InnerTube node.
///
/// When [node] does not contain a `runs` array, or when all entries are empty,
/// this method returns `null`.
String? extractRunsText(dynamic node) {
  if (node is! Map<String, dynamic>) return null;
  final runs = node['runs'];
  if (runs is! List || runs.isEmpty) return null;
  return runs
      .whereType<Map<String, dynamic>>()
      .map((e) => e['text'] as String?)
      .whereType<String>()
      .join('')
      .trim();
}

/// Extracts the last thumbnail URL from a `thumbnails` array inside [node],
/// falling back to `null` when no valid URL can be found.
String? extractThumbnailUrl(dynamic node) {
  if (node is! Map<String, dynamic>) return null;

  var thumbs = node['thumbnails'] as List<dynamic>?;

  if (thumbs == null || thumbs.isEmpty) {
    final musicThumb =
        node['musicThumbnailRenderer'] as Map<String, dynamic>?;
    final inner = musicThumb?['thumbnail'] as Map<String, dynamic>?;
    thumbs = inner?['thumbnails'] as List<dynamic>?;
  }

  if (thumbs == null || thumbs.isEmpty) return null;
  final last = thumbs.last;
  if (last is! Map<String, dynamic>) return null;
  return last['url'] as String?;
}

/// Parses a `hh:mm:ss` or `mm:ss` duration string into a [Duration].
Duration? parseDuration(String? text) {
  if (text == null || text.isEmpty) return null;
  final parts = text.trim().split(':').map(int.tryParse).toList();
  if (parts.any((v) => v == null)) return null;

  if (parts.length == 2) {
    return Duration(minutes: parts[0]!, seconds: parts[1]!);
  }
  if (parts.length == 3) {
    return Duration(
      hours: parts[0]!,
      minutes: parts[1]!,
      seconds: parts[2]!,
    );
  }
  return null;
}

/// Extracts text from a flex column at [index] in a
/// `musicResponsiveListItemRenderer` node.
String? extractColumnRunsText(List<dynamic>? columns, int index) {
  if (columns == null || columns.length <= index) return null;
  final col = columns[index] as Map<String, dynamic>?;
  final renderer = col?['musicResponsiveListItemFlexColumnRenderer']
      as Map<String, dynamic>?;
  final text = renderer?['text'];
  return extractRunsText(text);
}

/// Extracts text from a fixed column at [index] in the `fixedColumns` array of
/// a `musicResponsiveListItemRenderer` node.
String? extractFixedColumnText(List<dynamic>? columns, int index) {
  if (columns == null || columns.length <= index) return null;
  final col = columns[index] as Map<String, dynamic>?;
  final renderer = col?['musicResponsiveListItemFixedColumnRenderer']
      as Map<String, dynamic>?;
  final text = renderer?['text'];
  return extractRunsText(text);
}

/// Parses a track count from subtitle strings such as `"25 songs"`.
int? extractTrackCount(String? subtitle) {
  if (subtitle == null || subtitle.isEmpty) return null;
  final match = RegExp(r'(\d{1,4})\s+songs?', caseSensitive: false)
      .firstMatch(subtitle);
  if (match == null) return null;
  return int.tryParse(match.group(1)!);
}

/// Returns the InnerTube music page type for a browse endpoint, if present.
String? extractBrowsePageType(Map<String, dynamic>? browseEndpoint) {
  if (browseEndpoint == null) return null;
  final cfg = browseEndpoint['browseEndpointContextSupportedConfigs']
      as Map<String, dynamic>?;
  final musicCfg =
      cfg?['browseEndpointContextMusicConfig'] as Map<String, dynamic>?;
  return musicCfg?['pageType'] as String?;
}

/// Extracts a thumbnail URL from a `musicTwoRowItemRenderer`.
String? extractThumbnailFromTwoRow(Map<String, dynamic> twoRow) {
  final thumbRenderer = twoRow['thumbnailRenderer'] as Map<String, dynamic>?;
  final musicThumb =
      thumbRenderer?['musicThumbnailRenderer'] as Map<String, dynamic>?;
  final thumb = musicThumb?['thumbnail'] as Map<String, dynamic>?;
  return extractThumbnailUrl(thumb);
}

/// Resolves a thumbnail URL from [thumbnailNode], falling back to a standard
/// `hqdefault` URL for [videoId] and then upgrading the resolution where
/// possible.
String extractOrFallbackThumbnail(dynamic thumbnailNode, String videoId) {
  final raw = extractThumbnailUrl(thumbnailNode) ??
      'https://i.ytimg.com/vi/$videoId/hqdefault.jpg';
  return upgradeThumbResolution(raw, videoId);
}

/// Normalises or upgrades thumbnail URLs to a higher resolution where possible.
String upgradeThumbResolution(String url, String videoId) {
  if (url.contains('lh3.googleusercontent.com') ||
      url.contains('yt3.ggpht.com')) {
    return url.replaceAllMapped(
      RegExp(r'=w\d+-h\d+'),
      (_) => '=w544-h544',
    );
  }
  if (url.contains('i.ytimg.com')) {
    if (url.contains('/default.') ||
        url.contains('/mqdefault.') ||
        url.contains('/sddefault.')) {
      return 'https://i.ytimg.com/vi/$videoId/hqdefault.jpg';
    }
  }
  return url;
}

/// Inspects badge renderers to determine whether an item is marked explicit.
bool extractIsExplicitFromBadges(dynamic badges) {
  if (badges is! List || badges.isEmpty) return false;
  for (final item in badges) {
    if (item is! Map<String, dynamic>) continue;
    final renderer = item['musicInlineBadgeRenderer'] as Map<String, dynamic>?;
    if (renderer == null) continue;
    if (_badgeLabelIsExplicit(renderer)) return true;
    final accData = renderer['accessibilityData'] as Map<String, dynamic>?;
    final label = accData?['label'] as String?;
    if (_isExplicitLabel(label)) return true;
    final acc = renderer['accessibility'] as Map<String, dynamic>?;
    final inner = acc?['accessibilityData'] as Map<String, dynamic>?;
    if (_isExplicitLabel(inner?['label'] as String?)) return true;
    final iconType = (renderer['icon'] as Map<String, dynamic>?)?['iconType'] as String?;
    if (iconType != null &&
        (iconType.toUpperCase().contains('EXPLICIT') || iconType == 'E')) {
      return true;
    }
  }
  return false;
}

/// Extracts artist and album metadata from a subtitle node.
Map<String, dynamic> extractTrackMetadata(dynamic node) {
  final result = <String, dynamic>{
    'artist': null,
    'artistBrowseId': null,
    'albumName': null,
    'albumBrowseId': null,
  };

  if (node is! Map<String, dynamic>) return result;
  final runs = node['runs'];
  if (runs is! List || runs.isEmpty) return result;

  final artistParts = <String>[];
  bool hitAlbum = false;

  for (final run in runs.whereType<Map<String, dynamic>>()) {
    final text = run['text'] as String?;
    if (text == null || text.trim().isEmpty) continue;

    final nav = run['navigationEndpoint'] as Map<String, dynamic>?;
    final browse = nav?['browseEndpoint'] as Map<String, dynamic>?;
    final browseId = browse?['browseId'] as String?;
    final pageType = extractBrowsePageType(browse);

    if (text.trim() == '•') {
      hitAlbum = true;
      continue;
    }

    if (text.contains('plays') || text.contains('views')) continue;

    final isArtist = pageType == 'MUSIC_PAGE_TYPE_ARTIST' ||
        pageType == 'MUSIC_PAGE_TYPE_USER_CHANNEL';
    final isAlbum = pageType == 'MUSIC_PAGE_TYPE_ALBUM';

    if (isAlbum) {
      result['albumName'] ??= text;
      result['albumBrowseId'] ??= browseId;
      hitAlbum = true;
    } else if (isArtist) {
      artistParts.add(text);
      result['artistBrowseId'] ??= browseId;
    } else {
      if (!hitAlbum) {
        artistParts.add(text);
        if (browseId != null) {
          result['artistBrowseId'] ??= browseId;
        }
      } else {
        if (result['albumName'] == null) {
          result['albumName'] = text;
        }
      }
    }
  }

  if (artistParts.isNotEmpty) {
    result['artist'] = artistParts.join('').trim();
  }

  return result;
}

/// Extracts the artist browse ID from a `menuRenderer`, if present.
String? extractMenuArtistId(Map<String, dynamic>? menu) {
  if (menu == null) return null;
  final menuRenderer = menu['menuRenderer'] as Map<String, dynamic>?;
  if (menuRenderer == null) return null;
  final items = menuRenderer['items'] as List<dynamic>?;
  if (items == null) return null;

  for (final item in items) {
    final nav = item['menuNavigationItemRenderer'] as Map<String, dynamic>?;
    final icon = nav?['icon']?['iconType'] as String?;
    if (icon == 'ARTIST') {
      final browse = nav?['navigationEndpoint']?['browseEndpoint'] as Map<String, dynamic>?;
      return browse?['browseId'] as String?;
    }
  }
  return null;
}

bool _isExplicitLabel(String? label) {
  if (label == null || label.isEmpty) return false;
  final lower = label.trim().toLowerCase();
  return lower == 'e' || lower == 'explicit';
}

bool _badgeLabelIsExplicit(Map<String, dynamic> renderer) {
  String? label = renderer['label'] as String?;
  if (_isExplicitLabel(label)) return true;
  final text = renderer['text'] as Map<String, dynamic>?;
  final runs = text?['runs'] as List<dynamic>?;
  if (runs != null) {
    for (final r in runs) {
      if (r is Map<String, dynamic>) {
        if (_isExplicitLabel(r['text'] as String?)) return true;
      }
    }
  }
  return false;
}
