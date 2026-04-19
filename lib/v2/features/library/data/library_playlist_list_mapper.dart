import 'package:tunify/v2/features/library/domain/entities/library_item.dart';
import 'package:tunify/v2/features/library/domain/library_known_creators.dart';

/// Maps `GET /v1/library/playlists` payload into [LibraryItem] rows.
abstract final class LibraryPlaylistListMapper {
  LibraryPlaylistListMapper._();

  /// Root response: `folders` + `items`; folder view: `items` only.
  static List<LibraryItem> parseLibraryPayload(Map<String, dynamic> map) {
    final foldersRaw = map['folders'];
    final itemsRaw = map['items'];
    final out = <LibraryItem>[];
    if (foldersRaw is List<dynamic>) {
      for (final e in foldersRaw.whereType<Map<String, dynamic>>()) {
        out.add(folderFromJson(e));
      }
    }
    if (itemsRaw is List<dynamic>) {
      for (final e in itemsRaw.whereType<Map<String, dynamic>>()) {
        out.add(playlistFromJson(e));
      }
    }
    return out;
  }

  static LibraryItem folderFromJson(Map<String, dynamic> json) {
    final id = (json['id'] as String?)?.trim() ?? '';
    final name = (json['name'] as String?)?.trim() ?? 'Folder';
    final isPinned = json['is_pinned'] == true;
    final updatedAtMs = _asInt(json['updated_at_ms']);
    final n = _asInt(json['member_count']);
    final subtitle = n == 0
        ? 'Folder'
        : n == 1
            ? 'Folder · 1 playlist'
            : 'Folder · $n playlists';
    return LibraryItem(
      id: id,
      title: name,
      subtitle: subtitle,
      kind: LibraryItemKind.folder,
      isPinned: isPinned,
      isInServerLibrary: true,
      updatedAtMs: updatedAtMs,
    );
  }

  static LibraryItem playlistFromJson(Map<String, dynamic> json) {
    final kindStr = (json['playlist_kind'] as String?)?.trim() ?? 'user';
    final isRemote = json['is_remote_playlist'] == true;
    final isPinned = json['is_pinned'] == true;
    final updatedAtMs = _asInt(json['updated_at_ms']);
    final trackCount = _asInt(json['track_count']);
    final name = (json['name'] as String?)?.trim() ?? 'Untitled';
    final cover = json['cover'] as String?;
    final ytmBrowse = (json['ytm_browse_id'] as String?)?.trim();
    final id = (json['id'] as String?)?.trim() ?? '';

    switch (kindStr) {
      case 'liked':
        return LibraryItem(
          id: id,
          title: name,
          subtitle: _playlistSubtitle(trackCount),
          kind: LibraryItemKind.playlist,
          // Static system playlists stay pinned; server flag cannot unpinned them.
          isPinned: true,
          creatorName: LibraryKnownCreators.you,
          systemArtwork: SystemArtworkType.likedSongs,
          imageUrl: cover,
          isUserOwnedPlaylist: false,
          isRemoteCatalogPlaylist: false,
          isInServerLibrary: true,
          updatedAtMs: updatedAtMs,
        );
      case 'episode':
        return LibraryItem(
          id: id,
          title: name,
          subtitle: 'Saved & downloaded episodes',
          kind: LibraryItemKind.podcast,
          isPinned: true,
          systemArtwork: SystemArtworkType.yourEpisodes,
          imageUrl: cover,
          isUserOwnedPlaylist: false,
          isRemoteCatalogPlaylist: false,
          isInServerLibrary: true,
          updatedAtMs: updatedAtMs,
        );
      case 'album':
        return LibraryItem(
          id: id,
          title: name,
          subtitle: _albumSubtitle(trackCount),
          kind: LibraryItemKind.album,
          isPinned: isPinned,
          imageUrl: cover,
          ytmBrowseId: ytmBrowse,
          isUserOwnedPlaylist: false,
          isRemoteCatalogPlaylist: false,
          isInServerLibrary: true,
          updatedAtMs: updatedAtMs,
        );
      case 'artist':
        return LibraryItem(
          id: id,
          title: name,
          subtitle: 'Artist',
          kind: LibraryItemKind.artist,
          isPinned: isPinned,
          imageUrl: cover,
          ytmBrowseId: ytmBrowse,
          isUserOwnedPlaylist: false,
          isRemoteCatalogPlaylist: false,
          isInServerLibrary: true,
          updatedAtMs: updatedAtMs,
        );
      case 'podcast':
        return LibraryItem(
          id: id,
          title: name,
          subtitle: 'Podcast',
          kind: LibraryItemKind.podcast,
          isPinned: isPinned,
          imageUrl: cover,
          ytmBrowseId: ytmBrowse,
          isUserOwnedPlaylist: false,
          isRemoteCatalogPlaylist: true,
          isInServerLibrary: true,
          updatedAtMs: updatedAtMs,
        );
      case 'user':
      default:
        final userOwned = !isRemote;
        return LibraryItem(
          id: id,
          title: name,
          subtitle: _playlistSubtitle(trackCount),
          kind: LibraryItemKind.playlist,
          isPinned: isPinned,
          creatorName: userOwned
              ? LibraryKnownCreators.you
              : LibraryKnownCreators.spotify,
          imageUrl: cover,
          ytmBrowseId: ytmBrowse,
          isUserOwnedPlaylist: userOwned,
          isRemoteCatalogPlaylist: isRemote,
          isInServerLibrary: true,
          updatedAtMs: updatedAtMs,
        );
    }
  }

  static int _asInt(Object? v) {
    if (v is int) {
      return v;
    }
    if (v is num) {
      return v.toInt();
    }
    return 0;
  }

  static String _playlistSubtitle(int n) {
    if (n <= 0) {
      return 'Playlist';
    }
    return n == 1 ? 'Playlist · 1 song' : 'Playlist · $n songs';
  }

  static String _albumSubtitle(int n) {
    if (n <= 0) {
      return 'Album';
    }
    return n == 1 ? 'Album · 1 song' : 'Album · $n songs';
  }
}
