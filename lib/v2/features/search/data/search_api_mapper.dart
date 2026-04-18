import 'package:tunify/v2/features/search/domain/entities/search_models.dart';

abstract final class SearchApiMapper {
  static List<SearchResultItem> fromItems(List<dynamic> rawItems) {
    final items = <SearchResultItem>[];
    for (final raw in rawItems) {
      if (raw is! Map<String, dynamic>) {
        continue;
      }
      final mapped = _fromSingle(raw);
      if (mapped != null) {
        items.add(mapped);
      }
    }
    return items;
  }

  static SearchResultItem? _fromSingle(Map<String, dynamic> raw) {
    final kind = raw['kind'] as String?;
    final value = raw['value'];
    if (kind == null || value is! Map<String, dynamic>) {
      return null;
    }

    return switch (kind) {
      'artist' => _artistFromJson(value),
      'album' => _albumFromJson(value),
      'playlist' => _playlistFromJson(value),
      'track' => _trackFromJson(value),
      'podcast' => _podcastFromJson(value),
      'episode' => _episodeFromJson(value),
      'audiobook' => _audiobookFromJson(value),
      'profile' => _profileFromJson(value),
      _ => null,
    };
  }

  static SearchResultItem? _artistFromJson(Map<String, dynamic> json) {
    final id = json['id'] as String?;
    final name = json['name'] as String?;
    if (id == null || id.isEmpty || name == null || name.isEmpty) {
      return null;
    }

    return SearchResultItem(
      id: id,
      kind: SearchItemKind.artist,
      title: name,
      subtitle: json['subscriber_line'] as String? ?? 'Artist',
      imageUrl: _safeImage(json['artwork_url']),
      trailingText: 'Following',
      isVerified: true,
    );
  }

  static SearchResultItem? _albumFromJson(Map<String, dynamic> json) {
    final id = json['id'] as String?;
    final title = json['title'] as String?;
    if (id == null || id.isEmpty || title == null || title.isEmpty) {
      return null;
    }
    final artist = (json['artist'] as String?)?.trim();
    final subtitle =
        artist == null || artist.isEmpty ? 'Album' : 'Album • $artist';
    return SearchResultItem(
      id: id,
      kind: SearchItemKind.album,
      title: title,
      subtitle: subtitle,
      imageUrl: _safeImage(json['artwork_url']),
    );
  }

  static SearchResultItem? _playlistFromJson(Map<String, dynamic> json) {
    final id = json['id'] as String?;
    final title = json['title'] as String?;
    if (id == null || id.isEmpty || title == null || title.isEmpty) {
      return null;
    }
    final author = (json['author'] as String?)?.trim();
    final subtitle =
        author == null || author.isEmpty ? 'Playlist' : 'Playlist • $author';
    return SearchResultItem(
      id: id,
      kind: SearchItemKind.playlist,
      title: title,
      subtitle: subtitle,
      imageUrl: _safeImage(json['artwork_url']),
    );
  }

  static SearchResultItem? _trackFromJson(Map<String, dynamic> json) {
    final id = json['id'] as String?;
    final title = json['title'] as String?;
    if (id == null || id.isEmpty || title == null || title.isEmpty) {
      return null;
    }
    final subtitle = (json['subtitle'] as String?)?.trim();
    final artists = json['artists'];
    String artistLine = '';
    if (artists is List<dynamic> && artists.isNotEmpty) {
      final names = <String>[];
      for (final rawArtist in artists) {
        if (rawArtist is! Map<String, dynamic>) continue;
        final name = rawArtist['name'] as String?;
        if (name != null && name.isNotEmpty) {
          names.add(name);
        }
      }
      artistLine = names.join(', ');
    }
    final normalizedSubtitle = subtitle != null && subtitle.isNotEmpty
        ? subtitle
        : (artistLine.isEmpty ? 'Song' : 'Song • $artistLine');
    return SearchResultItem(
      id: id,
      kind: SearchItemKind.song,
      title: title,
      subtitle: normalizedSubtitle,
      imageUrl: _safeImage(json['artwork_url']),
      videoId: id, // For tracks, id is the videoId
    );
  }

  static SearchResultItem? _podcastFromJson(Map<String, dynamic> json) {
    final id = json['id'] as String?;
    final title = json['title'] as String?;
    if (id == null || id.isEmpty || title == null || title.isEmpty) {
      return null;
    }
    final author = (json['author'] as String?)?.trim();
    final subtitle =
        author == null || author.isEmpty ? 'Podcast' : 'Podcast • $author';
    return SearchResultItem(
      id: id,
      kind: SearchItemKind.podcast,
      title: title,
      subtitle: subtitle,
      imageUrl: _safeImage(json['thumbnail_url']),
    );
  }

  static SearchResultItem? _episodeFromJson(Map<String, dynamic> json) {
    final id = json['id'] as String?;
    final title = json['title'] as String?;
    if (id == null || id.isEmpty || title == null || title.isEmpty) {
      return null;
    }
    final podcastTitle = (json['podcast_title'] as String?)?.trim();
    final subtitle = podcastTitle == null || podcastTitle.isEmpty
        ? 'Episode'
        : 'Episode • $podcastTitle';
    return SearchResultItem(
      id: id,
      kind: SearchItemKind.episode,
      title: title,
      subtitle: subtitle,
      imageUrl: _safeImage(json['thumbnail_url']),
    );
  }

  static SearchResultItem? _audiobookFromJson(Map<String, dynamic> json) {
    final id = json['id'] as String?;
    final title = json['title'] as String?;
    if (id == null || id.isEmpty || title == null || title.isEmpty) {
      return null;
    }
    final author = (json['author'] as String?)?.trim();
    final subtitle =
        author == null || author.isEmpty ? 'Audiobook' : 'Audiobook • $author';
    return SearchResultItem(
      id: id,
      kind: SearchItemKind.audiobook,
      title: title,
      subtitle: subtitle,
      imageUrl: _safeImage(json['thumbnail_url']),
    );
  }

  static SearchResultItem? _profileFromJson(Map<String, dynamic> json) {
    final id = json['id'] as String?;
    final name = json['name'] as String?;
    if (id == null || id.isEmpty || name == null || name.isEmpty) {
      return null;
    }
    final handle = (json['handle'] as String?)?.trim();
    return SearchResultItem(
      id: id,
      kind: SearchItemKind.profile,
      title: name,
      subtitle: handle == null || handle.isEmpty ? 'Profile' : handle,
      imageUrl: _safeImage(json['artwork_url']),
    );
  }

  static String? _safeImage(dynamic raw) {
    if (raw is! String) {
      return null;
    }
    final trimmed = raw.trim();
    if (trimmed.isEmpty) {
      return null;
    }
    if (trimmed.startsWith('//')) {
      return 'https:$trimmed';
    }
    return trimmed;
  }
}
