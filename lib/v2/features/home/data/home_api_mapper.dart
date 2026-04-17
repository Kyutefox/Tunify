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
}
