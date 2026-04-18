import 'package:tunify/v2/features/home/domain/entities/home_block.dart';
import 'package:tunify/v2/features/home/domain/entities/home_feed.dart';

/// Maps `GET /v1/browse/home` JSON into v2 [HomeFeed] blocks — field-driven only (no reorder heuristics).
abstract final class HomeApiMapper {
  static HomeFeed fromHomePageJson(Map<String, dynamic> root) {
    final blocks = <HomeBlock>[];

    // Canonical backend contract field (provider-agnostic).
    // Keep legacy fallback only for backward compatibility during rollout.
    final qp = root['recommended_tracks'] ?? root['quick_picks'];
    if (qp is Map<String, dynamic>) {
      final block = _mapQuickPicksBlock(qp);
      if (block != null) {
        blocks.add(block);
      }
    }

    final rawSections = root['sections'];
    if (rawSections is List<dynamic>) {
      for (final entry in rawSections) {
        if (entry is! Map<String, dynamic>) {
          continue;
        }
        final mapped = _mapSection(entry);
        if (mapped != null) {
          blocks.add(mapped);
        }
      }
    }

    return HomeFeed(blocks: blocks);
  }

  static HomeQuickPicksBlock? _mapQuickPicksBlock(Map<String, dynamic> json) {
    final items = json['items'];
    if (items is! List<dynamic>) {
      return null;
    }
    final tiles = <HomeSlimTile>[];
    for (final raw in items.take(24)) {
      if (raw is! Map<String, dynamic>) {
        continue;
      }
      final tile = _slimTileFromFeedItemJson(raw);
      if (tile != null) {
        tiles.add(tile);
      }
    }
    if (tiles.isEmpty) {
      return null;
    }
    final cols = (json['visible_columns'] as num?)?.toInt().clamp(1, 4) ?? 2;
    final rows = (json['visible_rows'] as num?)?.toInt().clamp(1, 8) ?? 4;
    return HomeQuickPicksBlock(
      title: json['title'] as String? ?? 'Recommended tracks',
      subtitle: json['subtitle'] as String?,
      tiles: tiles,
      visibleColumns: cols,
      visibleRows: rows,
    );
  }

  static HomeSlimTile? _slimTileFromFeedItemJson(Map<String, dynamic> json) {
    final id = json['id'] as String?;
    final title = json['title'] as String?;
    if (id == null || id.isEmpty || title == null || title.isEmpty) {
      return null;
    }
    final key = id + title;
    return HomeSlimTile(
      id: id,
      title: title,
      thumbColors: _hashToTwoColors(key),
      artworkUrl: _artworkUrl(json),
      shelfKind: json['kind'] as String?,
    );
  }

  static HomeBlock? _mapSection(Map<String, dynamic> section) {
    final layout = section['layout'] as String?;
    final title = section['title'] as String? ?? '';
    final subtitle = section['subtitle'] as String?;
    final items = section['items'];
    if (items is! List<dynamic>) {
      return null;
    }
    switch (layout) {
      case 'grid':
        return _mapGrid(items);
      case 'hero':
        return _mapHero(title, subtitle, items);
      case 'track_shelf_promo':
        return _mapTrackShelfPromo(section, items);
      case 'playlist_shelf_promo':
        return _mapPlaylistShelfPromo(section, items);
      case 'horizontal_scroll':
      case 'vertical_list':
        return _mapCarousel(
          section,
          items,
          layout == 'vertical_list' && _shelfItemsAreAllArtists(items),
        );
      default:
        return _mapCarousel(section, items, false);
    }
  }

  /// YT `vertical_list` is only the tight title18 artist row when every shelf cell is an artist.
  static bool _shelfItemsAreAllArtists(List<dynamic> items) {
    var count = 0;
    for (final raw in items) {
      if (_shelfPayload(raw) == null) {
        continue;
      }
      if (_shelfKind(raw) != 'artist') {
        return false;
      }
      count++;
    }
    return count > 0;
  }

  static HomeBlock _mapGrid(List<dynamic> items) {
    final tiles = <HomeSlimTile>[];
    for (final raw in items.take(12)) {
      final payload = _shelfPayload(raw);
      if (payload == null) {
        continue;
      }
      final label = _primaryLabel(payload);
      final key = label + (payload['id'] as String? ?? '');
      tiles.add(
        HomeSlimTile(
          id: payload['id'] as String? ?? key,
          title: label,
          thumbColors: _hashToTwoColors(key),
          artworkUrl: _artworkUrl(payload),
          shelfKind: _shelfKind(raw),
        ),
      );
    }
    if (tiles.isEmpty) {
      return HomeSlimGridBlock(
        tiles: [
          HomeSlimTile(
            id: 'placeholder',
            title: 'Tunify',
            thumbColors: _hashToTwoColors('placeholder'),
          ),
        ],
      );
    }
    return HomeSlimGridBlock(tiles: tiles);
  }

  static HomeBlock _mapHero(
    String title,
    String? subtitle,
    List<dynamic> items,
  ) {
    final first = items.isNotEmpty ? _shelfPayload(items.first) : null;
    final cardTitle = first != null ? _primaryLabel(first) : title;
    final cardSubtitle =
        first != null ? _secondaryLabel(first) : (subtitle ?? '');
    final key = '${first?['id'] ?? title}-hero';
    final colors = _hashToTwoColors(key);
    return HomeHeroRecommendedBlock(
      HomeHeroRecommended(
        sectionLabel: subtitle ?? 'For you',
        sectionTitle: title.isEmpty ? 'Home' : title,
        cardTitle: cardTitle,
        cardSubtitle: cardSubtitle.isEmpty ? ' ' : cardSubtitle,
        avatarColors: colors,
        squareArtColors: [colors[1], colors[0]],
      ),
    );
  }

  static HomeBlock _mapTrackShelfPromo(
    Map<String, dynamic> section,
    List<dynamic> items,
  ) {
    final raw = items.isNotEmpty ? items.first : null;
    final payload = raw is Map<String, dynamic> ? _shelfPayload(raw) : null;
    final sid = section['id'] as String? ?? 'track_shelf';
    final fromPayloadTitle = (payload?['title'] as String?)?.trim();
    final title = (fromPayloadTitle != null && fromPayloadTitle.isNotEmpty)
        ? fromPayloadTitle
        : (section['title'] as String? ?? 'Playlist');
    final m = payload?['mosaic_artwork_urls'];
    final mosaics = <String>[];
    if (m is List<dynamic>) {
      for (final e in m) {
        if (e is String) {
          final u = _artworkUrl({'artwork_url': e});
          if (u != null) {
            mosaics.add(u);
          }
        }
      }
    }
    final v = payload?['shelf_track_video_ids'];
    final ids = <String>[];
    if (v is List<dynamic>) {
      for (final e in v) {
        if (e is String && e.trim().isNotEmpty) {
          ids.add(e.trim());
        }
      }
    }
    final fromPayloadSub = (payload?['subtitle'] as String?)?.trim();
    final showSubtitle = (fromPayloadSub != null && fromPayloadSub.isNotEmpty)
        ? fromPayloadSub
        : (ids.isEmpty ? 'Playlist' : '${ids.length} tracks');
    final desc = ids.isEmpty
        ? 'Curated picks from your home feed.'
        : 'Made for you from your home feed.';
    final fromPayloadId = (payload?['id'] as String?)?.trim();

    final trackMetaById = _trackShelfMetaByVideoId(
      payload: payload,
      items: items,
      orderedVideoIds: ids,
    );
    final trackTitles = <String>[];
    final trackSubtitles = <String>[];
    for (final id in ids) {
      final entry = trackMetaById[id];
      trackTitles.add(
        entry != null && entry.$1.trim().isNotEmpty ? entry.$1.trim() : '',
      );
      trackSubtitles.add(
        entry != null && entry.$2.trim().isNotEmpty ? entry.$2.trim() : '',
      );
    }
    final creatorName = _trackShelfCreatorName(
      section: section,
      payload: payload,
      showSubtitle: showSubtitle,
      trackSubtitles: trackSubtitles,
    );

    return HomePodcastPromoBlock(
      HomePodcastPromo(
        id: (fromPayloadId != null && fromPayloadId.isNotEmpty)
            ? fromPayloadId
            : sid,
        title: title,
        showSubtitle: showSubtitle,
        episodeDescription: desc,
        coverColors: _hashToTwoColors(sid),
        backgroundColor: _hashToTwoColors('$sid-bg')[0],
        mosaicArtworkUrls: mosaics,
        trackVideoIds: ids,
        creatorName: creatorName,
        trackTitles: trackTitles,
        trackSubtitles: trackSubtitles,
      ),
    );
  }

  /// Browse-backed playlist in promo layout (e.g. folded Charts shelf).
  static HomeBlock _mapPlaylistShelfPromo(
    Map<String, dynamic> section,
    List<dynamic> items,
  ) {
    final raw = items.isNotEmpty ? items.first : null;
    final payload = raw is Map<String, dynamic> ? _shelfPayload(raw) : null;
    final sid = section['id'] as String? ?? 'playlist_shelf';
    final fromPayloadTitle = (payload?['title'] as String?)?.trim();
    final title = (fromPayloadTitle != null && fromPayloadTitle.isNotEmpty)
        ? fromPayloadTitle
        : (section['title'] as String? ?? 'Playlist');
    final m = payload?['mosaic_artwork_urls'];
    final mosaics = <String>[];
    if (m is List<dynamic>) {
      for (final e in m) {
        if (e is String) {
          final u = _artworkUrl({'artwork_url': e});
          if (u != null) {
            mosaics.add(u);
          }
        }
      }
    }
    final fromPayloadSub = (payload?['subtitle'] as String?)?.trim();
    final showSubtitle = (fromPayloadSub != null && fromPayloadSub.isNotEmpty)
        ? fromPayloadSub
        : 'Playlist';
    final desc = (payload?['description'] as String?)?.trim() ?? '';
    final fromPayloadId = (payload?['id'] as String?)?.trim();
    final browseId = (fromPayloadId != null && fromPayloadId.isNotEmpty)
        ? fromPayloadId
        : sid;
    final creatorName = _trackShelfCreatorName(
      section: section,
      payload: payload,
      showSubtitle: showSubtitle,
      trackSubtitles: const [],
    );
    return HomePodcastPromoBlock(
      HomePodcastPromo(
        id: browseId,
        title: title,
        showSubtitle: showSubtitle,
        episodeDescription: desc.isEmpty ? ' ' : desc,
        coverColors: _hashToTwoColors(sid),
        backgroundColor: _hashToTwoColors('$sid-bg')[0],
        mosaicArtworkUrls: mosaics,
        creatorName: creatorName,
      ),
    );
  }

  /// Comma-separated artist names from a home [FeedItem]-shaped JSON map.
  static String _artistNamesFromFeedItemJson(Map<String, dynamic> e) {
    final artists = e['artists'];
    if (artists is! List<dynamic> || artists.isEmpty) {
      return '';
    }
    final names = <String>[];
    for (final a in artists) {
      if (a is Map<String, dynamic>) {
        final n = (a['name'] as String?)?.trim();
        if (n != null && n.isNotEmpty) {
          names.add(n);
        }
      }
    }
    return names.join(', ');
  }

  /// `(title, subtitle)` per YouTube video id for folded track-shelf promos.
  static Map<String, (String, String)> _trackShelfMetaByVideoId({
    required Map<String, dynamic>? payload,
    required List<dynamic> items,
    required List<String> orderedVideoIds,
  }) {
    final out = <String, (String, String)>{};

    void put(String id, String title, String subtitle) {
      final t = title.trim();
      final s = subtitle.trim();
      if (t.isEmpty && s.isEmpty) {
        return;
      }
      out[id] = (t, s);
    }

    for (final raw in items) {
      final p = _shelfPayload(raw);
      if (p == null) {
        continue;
      }
      final id = (p['id'] as String?)?.trim();
      if (id == null || id.isEmpty) {
        continue;
      }
      final kind = _shelfKind(raw);
      final inferred = _inferKind(p);
      if (kind != 'track' && inferred != 'track') {
        continue;
      }
      final title = _primaryLabel(p).trim();
      var sub = (_optionalSubtitle(p, kind ?? inferred) ?? _secondaryLabel(p))
          .trim();
      if (sub.isEmpty) {
        sub = _artistNamesFromFeedItemJson(p);
      }
      put(id, title, sub);
    }

    if (payload != null) {
      for (final key in ['shelf_tracks', 'tracks', 'shelf_track_items']) {
        final list = payload[key];
        if (list is! List<dynamic>) {
          continue;
        }
        for (final e in list) {
          if (e is! Map<String, dynamic>) {
            continue;
          }
          final id = (e['video_id'] as String?)?.trim() ??
              (e['id'] as String?)?.trim();
          if (id == null || id.isEmpty) {
            continue;
          }
          final title = (e['title'] as String?)?.trim() ??
              (e['name'] as String?)?.trim() ??
              '';
          var sub = (e['subtitle'] as String?)?.trim() ??
              (e['artist'] as String?)?.trim() ??
              '';
          if (sub.isEmpty) {
            sub = _artistNamesFromFeedItemJson(e);
          }
          put(id, title, sub);
        }
      }

      final titles = payload['shelf_track_titles'];
      final subs = payload['shelf_track_subtitles'] ?? payload['shelf_track_artists'];
      if (titles is List<dynamic>) {
        for (var i = 0; i < orderedVideoIds.length && i < titles.length; i++) {
          final id = orderedVideoIds[i];
          final ti = (titles[i] as String?)?.trim() ?? '';
          var su = '';
          if (subs is List<dynamic> && i < subs.length) {
            su = (subs[i] as String?)?.trim() ?? '';
          }
          if (ti.isNotEmpty || su.isNotEmpty) {
            put(id, ti, su);
          }
        }
      }
    }

    return out;
  }

  static bool _looksLikeTrackCountLine(String s) {
    final t = s.trim().toLowerCase();
    return RegExp(r'^\d+\s+(tracks?|songs?)$').hasMatch(t);
  }

  static String? _trackShelfCreatorName({
    required Map<String, dynamic> section,
    required Map<String, dynamic>? payload,
    required String showSubtitle,
    required List<String> trackSubtitles,
  }) {
    String? pick(String? s) {
      final t = s?.trim();
      return (t == null || t.isEmpty) ? null : t;
    }

    final fromPayload = pick(payload?['author'] as String?) ??
        pick(payload?['owner'] as String?) ??
        pick(payload?['curator'] as String?) ??
        pick(payload?['menu_title'] as String?) ??
        pick(payload?['short_byline'] as String?) ??
        pick(payload?['byline'] as String?);

    if (fromPayload != null) {
      return fromPayload;
    }

    final sectionSub = pick(section['subtitle'] as String?);
    if (sectionSub != null &&
        sectionSub != showSubtitle &&
        !_looksLikeTrackCountLine(sectionSub)) {
      return sectionSub;
    }

    final nonEmptySubs =
        trackSubtitles.map((e) => e.trim()).where((e) => e.isNotEmpty).toSet();
    if (nonEmptySubs.length == 1) {
      return nonEmptySubs.first;
    }
    return null;
  }

  static HomeBlock _mapCarousel(
    Map<String, dynamic> section,
    List<dynamic> items,
    bool tightSpacing,
  ) {
    final id = section['id'] as String? ?? 'carousel';
    final title = section['title'] as String? ?? '';
    final carouselItems = <HomeCarouselItem>[];
    var useCircles = false;
    for (final raw in items) {
      final payload = _shelfPayload(raw);
      if (payload == null) {
        continue;
      }
      final kind = _shelfKind(raw);
      if (kind == 'artist') {
        useCircles = true;
      }
      carouselItems.add(
        HomeCarouselItem(
          id: payload['id'] as String? ?? '${payload['title']}-item',
          title: _primaryLabel(payload),
          subtitle: _optionalSubtitle(payload, kind),
          imageColors: _hashToTwoColors(
            payload['id'] as String? ?? _primaryLabel(payload),
          ),
          imageBorderRadius: kind == 'artist' ? 9999 : 8,
          artworkUrl: _artworkUrl(payload),
          shelfKind: kind,
        ),
      );
    }
    if (carouselItems.isEmpty) {
      carouselItems.add(
        HomeCarouselItem(
          id: '$id-empty',
          title: title.isEmpty ? 'Browse' : title,
          imageColors: _hashToTwoColors(id),
        ),
      );
    }
    final titleSize = tightSpacing
        ? HomeCarouselTitleSize.title18
        : HomeCarouselTitleSize.title22;
    return HomeCarouselBlock(
      HomeCarouselSection(
        id: id,
        title: title.isEmpty ? 'Discover' : title,
        titleSize: titleSize,
        thumbKind: useCircles
            ? HomeCarouselThumbKind.circle94
            : HomeCarouselThumbKind.square147,
        items: carouselItems,
      ),
    );
  }

  static String? _artworkUrl(Map<String, dynamic> payload) {
    final u = payload['artwork_url'];
    if (u is! String) {
      return null;
    }
    final t = u.trim();
    if (t.isEmpty) {
      return null;
    }
    if (t.startsWith('//')) {
      return 'https:$t';
    }
    return t;
  }

  static Map<String, dynamic>? _shelfPayload(dynamic raw) {
    if (raw is! Map<String, dynamic>) {
      return null;
    }
    final value = raw['value'];
    if (value is Map<String, dynamic>) {
      return value;
    }
    return null;
  }

  static String? _shelfKind(dynamic raw) {
    if (raw is! Map<String, dynamic>) {
      return null;
    }
    return raw['kind'] as String?;
  }

  static String _primaryLabel(Map<String, dynamic> payload) {
    final name = payload['name'] as String?;
    if (name != null && name.isNotEmpty) {
      return name;
    }
    final title = payload['title'] as String?;
    if (title != null && title.isNotEmpty) {
      return title;
    }
    return 'Item';
  }

  static String? _optionalSubtitle(
    Map<String, dynamic> payload,
    String? kind,
  ) {
    final sub = payload['subtitle'] as String?;
    if (sub != null && sub.isNotEmpty) {
      return sub;
    }
    if (kind == 'track') {
      final artists = payload['artists'];
      if (artists is List && artists.isNotEmpty) {
        final first = artists.first;
        if (first is Map<String, dynamic>) {
          final n = first['name'] as String?;
          if (n != null && n.isNotEmpty) {
            return n;
          }
        }
      }
    }
    return null;
  }

  static String _secondaryLabel(Map<String, dynamic> payload) {
    return _optionalSubtitle(payload, _inferKind(payload)) ?? '';
  }

  static String _inferKind(Map<String, dynamic> payload) {
    if (payload.containsKey('name') && !payload.containsKey('title')) {
      return 'artist';
    }
    return 'track';
  }

  static List<int> _hashToTwoColors(String input) {
    var h = 0;
    for (final unit in input.codeUnits) {
      h = (h * 31 + unit) & 0x7fffffff;
    }
    final a = 0xFF000000 | (h & 0xffffff);
    final b = 0xFF000000 | ((h ^ (h >> 12) ^ (h >> 24)) & 0xffffff);
    return [a, b];
  }

  /// Builds a [HomeCarouselSection] from the same `kind` + `value` entries as home `sections[].items`.
  ///
  /// Used by library browse recommendations so shelves reuse [HomeCarouselShelf] / card layout.
  static HomeCarouselSection? carouselSectionFromKindValueItems({
    required String id,
    required String title,
    required List<Map<String, dynamic>> items,
  }) {
    if (items.isEmpty) {
      return null;
    }
    final block = _mapCarousel(
      {'id': id, 'title': title},
      items,
      _shelfItemsAreAllArtists(items),
    );
    return switch (block) {
      HomeCarouselBlock(:final section) => section,
      _ => null,
    };
  }
}
