import 'package:scrapper/constants/parser_constants.dart';
import 'package:scrapper/models/related_feed.dart';
import 'package:scrapper/models/track.dart';
import 'package:scrapper/youtube_music/parsers/inner_tube_parsers.dart' as p;

/// Helpers for turning raw YouTube Music `browse` responses into strongly
/// typed feed models such as [RelatedHomeFeed] and [MoodDetailResult].
class BrowseFormatter {

  /// Extracts a [Track] from a `musicResponsiveListItemRenderer` node.
  static Track? parseTrackFromResponsiveItem(Map<String, dynamic> item) {
    final nav = item['navigationEndpoint'] as Map<String, dynamic>?;
    final watch = nav?['watchEndpoint'] as Map<String, dynamic>?;
    final playlistData = item['playlistItemData'] as Map<String, dynamic>?;
    final videoId =
        (watch?['videoId'] as String?) ?? (playlistData?['videoId'] as String?);
    if (videoId == null || videoId.isEmpty) return null;

    final columns = item['flexColumns'] as List<dynamic>?;
    String? title;
    Map<String, dynamic> metadata = {};

    if (columns != null && columns.isNotEmpty) {
      title = p.extractColumnRunsText(columns, 0);
      
      // Collect all text from columns 1 and onwards (Artist, Album, etc.)
      final metadataRuns = <dynamic>[];
      for (var i = 1; i < columns.length; i++) {
        final col = (columns[i] as Map<String, dynamic>?)?['musicResponsiveListItemFlexColumnRenderer'];
        final text = col?['text'];
        if (text != null && text['runs'] != null) {
          metadataRuns.addAll(text['runs'] as List);
        }
      }
      metadata = p.extractTrackMetadata({'runs': metadataRuns});
    }

    final thumb = item['thumbnail'] as Map<String, dynamic>?;
    final thumbUrl = p.extractOrFallbackThumbnail(thumb, videoId);

    final fixedColumns = item['fixedColumns'] as List<dynamic>?;
    final durationText = p.extractFixedColumnText(fixedColumns, 0);
    final duration = p.parseDuration(durationText) ?? ParserConstants.defaultTrackDuration;

    final badges = item['badges'] as List<dynamic>?;
    bool isExplicit = p.extractIsExplicitFromBadges(badges);
    if (!isExplicit && columns != null && columns.length > 1) {
      final subtitle = p.extractColumnRunsText(columns, 1) ?? '';
      final norm = subtitle.trim();
      isExplicit = norm.endsWith(' E') || norm.endsWith('• E') ||
          norm.endsWith(' • E') || norm == 'E';
    }

    return Track(
      id: videoId,
      title: (title == null || title.isEmpty) ? 'Unknown title' : title,
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

  /// Extract a Track from a `musicTwoRowItemRenderer` node.
  static Track? parseTrackFromTwoRowItem(Map<String, dynamic> item) {
    final nav = item['navigationEndpoint'] as Map<String, dynamic>?;
    final watch = nav?['watchEndpoint'] as Map<String, dynamic>?;
    final videoId = watch?['videoId'] as String?;
    if (videoId == null || videoId.isEmpty) return null;

    final title = p.extractRunsText(item['title']) ?? 'Unknown title';
    final subtitle = p.extractRunsText(item['subtitle']) ?? '';
    final metadata = p.extractTrackMetadata(item['subtitle']);
    final rawThumb = p.extractThumbnailFromTwoRow(item) ??
        'https://i.ytimg.com/vi/$videoId/hqdefault.jpg';
    final thumbnail = p.upgradeThumbResolution(rawThumb, videoId);

    final badges = item['badges'] as List<dynamic>?;
    bool isExplicit = p.extractIsExplicitFromBadges(badges);
    if (!isExplicit && subtitle.isNotEmpty) {
      final norm = subtitle.trim();
      isExplicit = norm.endsWith(' E') || norm.endsWith('• E') ||
          norm.endsWith(' • E') || norm == 'E';
    }

    return Track(
      id: videoId,
      title: title,
      artist: metadata['artist'] ?? 'Unknown artist',
      artistBrowseId:
          metadata['artistBrowseId'] ?? p.extractMenuArtistId(item['menu']),
      albumName: metadata['albumName'],
      albumBrowseId: metadata['albumBrowseId'],
      thumbnailUrl: thumbnail,
      duration: ParserConstants.defaultTrackDuration, // TwoRow items generally don't show durations.
      isExplicit: isExplicit,
    );
  }

  /// Walk through browse data and extract tracks until maxResults is reached.
  static List<Track> extractTracksFromBrowseData(
    Map<String, dynamic> browseData, {
    String sourceVideoId = '',
    int maxResults = 5000,
  }) {
    final tracks = <Track>[];
    final seen = <String>{};

    void collect(Track? track) {
      if (track == null) return;
      if (track.id == sourceVideoId) return;
      if (!seen.add(track.id)) return;
      tracks.add(track);
    }

    void walk(dynamic node) {
      if (tracks.length >= maxResults) return;

      if (node is Map<String, dynamic>) {
        final responsive = node['musicResponsiveListItemRenderer'];
        if (responsive is Map<String, dynamic>) {
          collect(parseTrackFromResponsiveItem(responsive));
        }

        final twoRow = node['musicTwoRowItemRenderer'];
        if (twoRow is Map<String, dynamic>) {
          collect(parseTrackFromTwoRowItem(twoRow));
        }

        for (final value in node.values) {
          walk(value);
          if (tracks.length >= maxResults) return;
        }
      } else if (node is List) {
        for (final item in node) {
          walk(item);
          if (tracks.length >= maxResults) return;
        }
      }
    }

    walk(browseData);
    return tracks;
  }
  /// Parses the entire browse data into a unified `RelatedHomeFeed` payload.
  static RelatedHomeFeed parseRelatedFeed(
    Map<String, dynamic> browseData, {
    int maxTracks = 30,
    int maxPlaylists = 12,
    int maxArtists = 12,
    int maxMoodItems = 32,
  }) {
    final trackShelves = <RelatedTrackShelf>[];
    final playlistShelves = <RelatedPlaylistShelf>[];
    final artistShelves = <RelatedArtistShelf>[];
    final homeShelves = <RelatedHomeShelf>[];

    final shelves = extractShelves(browseData);

    for (final shelf in shelves) {
      final (shelfTitle, shelfSubtitle) = _extractShelfTitleAndSubtitle(shelf);
      // Always record the shelf metadata so callers can preserve the original
      // browse order even if a particular shelf ends up empty for a given
      // content type (tracks/playlists/artists).
      homeShelves.add(
        RelatedHomeShelf(
          title: shelfTitle,
          subtitle: shelfSubtitle,
        ),
      );
      final shelfTitleLower = shelfTitle.toLowerCase();

      final contents = shelf['contents'] as List<dynamic>?;
      if (contents == null || contents.isEmpty) continue;

      final currentShelfTracks = <Track>[];
      final currentShelfPlaylists = <RelatedPlaylist>[];
      final currentShelfArtists = <RelatedArtist>[];

      for (final item in contents.whereType<Map<String, dynamic>>()) {
        _processShelfItem(
          item,
          shelfTitleLower: shelfTitleLower,
          maxTracks: maxTracks,
          maxPlaylists: maxPlaylists,
          maxArtists: maxArtists,
          currentShelfTracks: currentShelfTracks,
          currentShelfPlaylists: currentShelfPlaylists,
          currentShelfArtists: currentShelfArtists,
        );
      }

      if (currentShelfTracks.isNotEmpty) {
        trackShelves.add(RelatedTrackShelf(
          title: shelfTitle,
          subtitle: shelfSubtitle,
          tracks: currentShelfTracks,
        ));
      }
      if (currentShelfPlaylists.isNotEmpty) {
        playlistShelves.add(RelatedPlaylistShelf(
          title: shelfTitle,
          subtitle: shelfSubtitle,
          playlists: currentShelfPlaylists,
        ));
      }
      if (currentShelfArtists.isNotEmpty) {
        artistShelves.add(RelatedArtistShelf(
          title: shelfTitle,
          subtitle: shelfSubtitle,
          artists: currentShelfArtists,
        ));
      }
    }

    final moodItems = extractMoodItems(browseData, maxItems: maxMoodItems);

    return RelatedHomeFeed(
      trackShelves: trackShelves,
      playlistShelves: playlistShelves,
      artistShelves: artistShelves,
      shelves: homeShelves,
      moodItems: moodItems,
    );
  }

  /// Extracts mood and genre items from browse response.
  /// Supports: chipCloudChipRenderer (home feed mood chips) and musicNavigationButtonRenderer.
  static List<RelatedMoodItem> extractMoodItems(
    Map<String, dynamic> browseData, {
    int maxItems = 32,
  }) {
    final items = <RelatedMoodItem>[];
    final seenKeys = <String>{};
    const sectionTitle = 'Moods & genres';

    void walk(dynamic node) {
      if (items.length >= maxItems) return;
      if (node is Map<String, dynamic>) {
        if (node.containsKey('chipCloudChipRenderer')) {
          final mood = _parseMoodFromChip(node['chipCloudChipRenderer']!, sectionTitle, seenKeys);
          if (mood != null) items.add(mood);
        }
        if (node.containsKey('musicNavigationButtonRenderer')) {
          final mood = _parseMoodFromNavButton(node, sectionTitle, seenKeys);
          if (mood != null) items.add(mood);
        }
        for (final value in node.values) {
          walk(value);
          if (items.length >= maxItems) return;
        }
      } else if (node is List) {
        for (final item in node) {
          walk(item);
          if (items.length >= maxItems) return;
        }
      }
    }

    walk(browseData);
    return items;
  }

  /// Mood chips in home feed use chipCloudChipRenderer with browseId FEmusic_home and params.
  static RelatedMoodItem? _parseMoodFromChip(
    Map<String, dynamic> chip,
    String sectionTitle,
    Set<String> seenKeys,
  ) {
    final nav = chip['navigationEndpoint'] as Map<String, dynamic>?;
    final browse = nav?['browseEndpoint'] as Map<String, dynamic>?;
    final browseId = browse?['browseId'] as String?;
    final params = browse?['params'] as String?;
    if (browseId == null || browseId.isEmpty) return null;

    final title = p.extractRunsText(chip['text']) ?? '';
    if (title.isEmpty) return null;

    // Chips with FEmusic_home + params are mood filters (Energize, Relax, Workout, etc.)
    final key = params != null && params.isNotEmpty ? '$browseId|$params' : title;
    if (!seenKeys.add(key)) return null;

    return RelatedMoodItem(
      title: title,
      browseId: browseId,
      params: params,
      sectionTitle: sectionTitle,
    );
  }

  static RelatedMoodItem? _parseMoodFromNavButton(
    Map<String, dynamic> item,
    String sectionTitle,
    Set<String> seenIds,
  ) {
    final navButton = item['musicNavigationButtonRenderer'] as Map<String, dynamic>?;
    if (navButton == null) return null;

    final nav = (navButton['navigationEndpoint'] ?? navButton['clickCommand']) as Map<String, dynamic>?;
    final browse = nav?['browseEndpoint'] as Map<String, dynamic>?;
    final browseId = browse?['browseId'] as String?;
    if (browseId == null || browseId.isEmpty) return null;

    final params = browse?['params'] as String?;
    final dedupKey = params != null && params.isNotEmpty ? '$browseId|$params' : browseId;
    if (!seenIds.add(dedupKey)) return null;

    // Skip main nav when no params (home/explore/library tabs)
    if (params == null || params.isEmpty) {
      if (browseId == 'FEmusic_home' ||
          browseId == 'FEmusic_explore' ||
          browseId == 'FEmusic_library' ||
          browseId.startsWith('SP')) {
        return null;
      }
    }

    final title = p.extractRunsText(navButton['title'] ?? navButton['buttonText']) ?? '';
    if (title.isEmpty) return null;

    // Never treat artist/playlist browse as mood/genre
    final pageType = p.extractBrowsePageType(browse);
    final isArtist = pageType == 'MUSIC_PAGE_TYPE_ARTIST';
    final isPlaylist = pageType == 'MUSIC_PAGE_TYPE_PLAYLIST' ||
        pageType == 'MUSIC_PAGE_TYPE_ALBUM' ||
        browseId.startsWith('VL');
    if (isArtist || isPlaylist) return null;

    return RelatedMoodItem(
      title: title,
      browseId: browseId,
      params: params,
      sectionTitle: sectionTitle,
    );
  }

  /// Parses a mood detail browse response into sub-categories (mood chips) and playlists.
  static MoodDetailResult parseMoodDetailResponse(Map<String, dynamic> browseData) {
    final subCategories = extractMoodItems(browseData, maxItems: 64);
    final playlists = extractPlaylistsFromBrowseData(browseData, maxItems: 50);
    return MoodDetailResult(subCategories: subCategories, playlists: playlists);
  }

  /// Extracts playlist entries (MoodPlaylist) from browse data (musicTwoRowItemRenderer with MPREb_/VL).
  static List<MoodPlaylist> extractPlaylistsFromBrowseData(
    Map<String, dynamic> browseData, {
    int maxItems = 50,
  }) {
    final list = <MoodPlaylist>[];
    final seen = <String>{};

    void walk(dynamic node) {
      if (list.length >= maxItems) return;
      if (node is Map<String, dynamic>) {
        final twoRow = node['musicTwoRowItemRenderer'] as Map<String, dynamic>?;
        if (twoRow != null) {
          final nav = twoRow['navigationEndpoint'] as Map<String, dynamic>?;
          final browse = nav?['browseEndpoint'] as Map<String, dynamic>?;
          final browseId = browse?['browseId'] as String?;
          if (browseId != null &&
              browseId.isNotEmpty &&
              (browseId.startsWith('MPREb_') || browseId.startsWith('VL')) &&
              seen.add(browseId)) {
            final title = p.extractRunsText(twoRow['title']) ?? '';
            if (title.isEmpty) return;
            final subtitle = p.extractRunsText(twoRow['subtitle']);
            final thumb = p.extractThumbnailFromTwoRow(twoRow) ??
                'https://i.ytimg.com/vi/$browseId/hqdefault.jpg';
            final thumbUrl = p.upgradeThumbResolution(thumb, browseId);
            list.add(MoodPlaylist(
              id: browseId,
              title: title,
              thumbnailUrl: thumbUrl,
              subtitle: subtitle,
            ));
          }
        }
        for (final value in node.values) {
          walk(value);
          if (list.length >= maxItems) return;
        }
      } else if (node is List) {
        for (final item in node) {
          walk(item);
          if (list.length >= maxItems) return;
        }
      }
    }

    walk(browseData);
    return list;
  }

  /// Extracts all shelf renderers from any response node.
  static List<Map<String, dynamic>> extractShelves(Map<String, dynamic> data) {
    final shelves = <Map<String, dynamic>>[];
    final seen = <String>{};

    void addShelf(dynamic shelf) {
      if (shelf is Map<String, dynamic>) {
        final title = p.extractRunsText(shelf['title']) ?? 
                     p.extractRunsText(shelf['header']?['musicCarouselShelfBasicHeaderRenderer']?['title']) ?? 
                     p.extractRunsText(shelf['header']?['musicShelfHeaderRenderer']?['title']) ?? 
                     '';
        final key = '$title|${(shelf['contents'] as List?)?.length ?? 0}';
        if (title.isNotEmpty && seen.add(key)) {
          shelves.add(shelf);
        }
      }
    }

    void walk(dynamic node) {
      if (node is Map<String, dynamic>) {
        if (node.containsKey('musicCarouselShelfRenderer')) addShelf(node['musicCarouselShelfRenderer']);
        if (node.containsKey('musicShelfRenderer')) addShelf(node['musicShelfRenderer']);
        if (node.containsKey('musicImmersiveCarouselShelfRenderer')) addShelf(node['musicImmersiveCarouselShelfRenderer']);
        if (node.containsKey('musicTastebuilderShelfRenderer')) addShelf(node['musicTastebuilderShelfRenderer']);

        node.forEach((key, value) {
          if (value is Map || value is List) walk(value);
        });
      } else if (node is List) {
        for (final item in node) {
          walk(item);
        }
      }
    }

    walk(data);
    return shelves;
  }

  /// Processes a single item from a shelf and adds it to the appropriate lists.
  static void _processShelfItem(
    Map<String, dynamic> item, {
    required String shelfTitleLower,
    required int maxTracks,
    required int maxPlaylists,
    required int maxArtists,
    required List<Track> currentShelfTracks,
    required List<RelatedPlaylist> currentShelfPlaylists,
    required List<RelatedArtist> currentShelfArtists,
  }) {
    // 1. Check for Track (Responsive Item)
    final responsive = item['musicResponsiveListItemRenderer'] as Map<String, dynamic>?;
    if (responsive != null) {
      final track = parseTrackFromResponsiveItem(responsive);
      if (track != null) {
        if (currentShelfTracks.length < maxTracks &&
            !currentShelfTracks.any((t) => t.id == track.id)) {
          currentShelfTracks.add(track);
        }
        return;
      }

      // Check for Artist/Playlist in Responsive Item
      final collection = _parseCollectionItem(responsive, shelfTitleLower);
      if (collection != null) {
        _dispatchCollection(
          collection,
          maxArtists: maxArtists,
          maxPlaylists: maxPlaylists,
          currentShelfArtists: currentShelfArtists,
          currentShelfPlaylists: currentShelfPlaylists,
        );
      }
      return;
    }

    // 2. Check for Track/Artist/Playlist (Two Row Item)
    final twoRow = item['musicTwoRowItemRenderer'] as Map<String, dynamic>?;
    if (twoRow != null) {
      final track = parseTrackFromTwoRowItem(twoRow);
      if (track != null) {
        if (currentShelfTracks.length < maxTracks &&
            !currentShelfTracks.any((t) => t.id == track.id)) {
          currentShelfTracks.add(track);
        }
        return;
      }

      final collection = _parseCollectionItem(twoRow, shelfTitleLower);
      if (collection != null) {
        _dispatchCollection(
          collection,
          maxArtists: maxArtists,
          maxPlaylists: maxPlaylists,
          currentShelfArtists: currentShelfArtists,
          currentShelfPlaylists: currentShelfPlaylists,
        );
      }
      return;
    }

    // 3. Check for Navigation Button (e.g., Moods)
    final navButton = item['musicNavigationButtonRenderer'] as Map<String, dynamic>?;
    if (navButton != null) {
      final collection = _parseCollectionItem(navButton, shelfTitleLower);
      if (collection != null) {
        _dispatchCollection(
          collection,
          maxArtists: maxArtists,
          maxPlaylists: maxPlaylists,
          currentShelfArtists: currentShelfArtists,
          currentShelfPlaylists: currentShelfPlaylists,
        );
      }
    }
  }

  /// Unified parser for collection items (Artists/Playlists) from various renderers.
  static (String, String, String?, String, bool)? _parseCollectionItem(
    Map<String, dynamic> item,
    String shelfTitleLower,
  ) {
    final nav = (item['navigationEndpoint'] ?? item['clickCommand']) as Map<String, dynamic>?;
    final browse = nav?['browseEndpoint'] as Map<String, dynamic>?;
    final browseId = browse?['browseId'] as String?;
    if (browseId == null || browseId.isEmpty) return null;

    final title = p.extractRunsText(item['title'] ?? item['buttonText']) ?? 
                 p.extractColumnRunsText(item['flexColumns'] as List?, 0) ?? 
                 'Unknown';
    final subtitle = p.extractRunsText(item['subtitle'] ?? item['secondaryText']) ?? 
                    p.extractColumnRunsText(item['flexColumns'] as List?, 1);
    
    final thumb = item['thumbnail'] as Map<String, dynamic>?;
    final rawThumb = p.extractThumbnailUrl(thumb) ?? 
                    p.extractThumbnailFromTwoRow(item) ??
                    'https://i.ytimg.com/vi/$browseId/hqdefault.jpg';
    final thumbnail = p.upgradeThumbResolution(rawThumb, browseId);

    final pageType = p.extractBrowsePageType(browse);
    final subtitleLower = (subtitle ?? '').toLowerCase();

    // "Albums for you" shelf: every item is an album (top-level nav = MPREb_). Artist links (UC)
    // only appear in subtitle.runs for the album's artists — we must not treat those as artist items.
    // So when the shelf title is album-only, treat every item as playlist/album.
    final shelfIsAlbumOnly = shelfTitleLower.contains('album') && !shelfTitleLower.contains('artist');

    final bool isArtist;
    final bool isPlaylist;
    if (shelfIsAlbumOnly) {
      isArtist = false;
      isPlaylist = browseId.startsWith('VL') ||
          browseId.startsWith('MPREb_') ||
          pageType == 'MUSIC_PAGE_TYPE_PLAYLIST' ||
          pageType == 'MUSIC_PAGE_TYPE_ALBUM' ||
          pageType == 'MUSIC_PAGE_TYPE_AUDIOBOOK';
    } else {
      // UC... = artist; MPREb_ / VL = playlist/album.
      isArtist = pageType == 'MUSIC_PAGE_TYPE_ARTIST' ||
          browseId.startsWith('UC') ||
          shelfTitleLower.contains('artist') ||
          subtitleLower.contains('artist');
      isPlaylist = pageType == 'MUSIC_PAGE_TYPE_PLAYLIST' ||
          pageType == 'MUSIC_PAGE_TYPE_ALBUM' ||
          pageType == 'MUSIC_PAGE_TYPE_AUDIOBOOK' ||
          browseId.startsWith('VL') ||
          browseId.startsWith('MPREb_') ||
          shelfTitleLower.contains('playlist') ||
          shelfTitleLower.contains('album');
    }

    if (!isArtist && !isPlaylist) return null;
    return (browseId, title, subtitle, thumbnail, isArtist);
  }

  static void _dispatchCollection(
    (String, String, String?, String, bool) item, {
    required int maxArtists,
    required int maxPlaylists,
    required List<RelatedArtist> currentShelfArtists,
    required List<RelatedPlaylist> currentShelfPlaylists,
  }) {
    final (id, name, sub, thumb, isArtist) = item;

    if (isArtist) {
      if (currentShelfArtists.length < maxArtists &&
          !currentShelfArtists.any((a) => a.id == id)) {
        final artist = RelatedArtist(
          id: id,
          name: name,
          thumbnailUrl: thumb,
          subtitle: sub,
        );
        currentShelfArtists.add(artist);
      }
    } else {
      if (currentShelfPlaylists.length < maxPlaylists &&
          !currentShelfPlaylists.any((pItem) => pItem.id == id)) {
        final playlist = RelatedPlaylist(
          id: id,
          title: name,
          thumbnailUrl: thumb,
          curatorName: sub,
          trackCount: p.extractTrackCount(sub),
        );
        currentShelfPlaylists.add(playlist);
      }
    }
  }

  static (String, String?) _extractShelfTitleAndSubtitle(Map<String, dynamic> shelf) {
    final header = shelf['header'] as Map<String, dynamic>?;

    final basic = header?['musicCarouselShelfBasicHeaderRenderer'] as Map<String, dynamic>?;
    final basicTitle = p.extractRunsText(basic?['title']);
    final basicSubtitle = p.extractRunsText(basic?['strapline']);
    if (basicTitle != null && basicTitle.isNotEmpty) {
      return (basicTitle, basicSubtitle);
    }

    final shelfHeader = header?['musicShelfHeaderRenderer'] as Map<String, dynamic>?;
    final shelfHeaderTitle = p.extractRunsText(shelfHeader?['title']) ??
        p.extractRunsText(shelf['title']);
    final shelfHeaderSubtitle = p.extractRunsText(shelfHeader?['subtitle']) ??
        p.extractRunsText(shelf['subtitle']);

    return (
      (shelfHeaderTitle == null || shelfHeaderTitle.isEmpty) ? 'Related' : shelfHeaderTitle,
      shelfHeaderSubtitle
    );
  }
}
